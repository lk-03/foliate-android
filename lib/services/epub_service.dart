import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:xml/xml.dart';
import '../models/book.dart';
import '../models/toc_item.dart';

/// Pure Dart service to inspect EPUB files, calculate content hashes,
/// extract Dublin Core metadata, and cache cover images without web engine overhead.
class EpubService {
  /// Computes SHA-256 hash of raw file bytes.
  static String computeHash(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }

  /// Parses an EPUB from raw bytes and saves cover image to [coversDir].
  static Future<Book> parseEpubBytes({
    required Uint8List bytes,
    String? sourceFilePath,
    required Directory coversDir,
  }) async {
    final hash = computeHash(bytes);
    String title = '';
    String author = 'Unknown Author';
    String? coverPath;

    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      // 1. Locate the package .opf path from META-INF/container.xml
      String? opfPath;
      final containerFile = _findFileInArchive(archive, 'META-INF/container.xml');
      if (containerFile != null) {
        final containerContent = utf8.decode(containerFile.content as List<int>, allowMalformed: true);
        final containerXml = XmlDocument.parse(containerContent);
        final rootfile = containerXml.findAllElements('rootfile').firstOrNull;
        opfPath = rootfile?.getAttribute('full-path');
      }

      // Fallback: search archive for any .opf file
      if (opfPath == null || opfPath.isEmpty) {
        for (final file in archive) {
          if (file.name.toLowerCase().endsWith('.opf')) {
            opfPath = file.name;
            break;
          }
        }
      }

      if (opfPath != null) {
        final opfFile = _findFileInArchive(archive, opfPath);
        if (opfFile != null) {
          final opfContent = utf8.decode(opfFile.content as List<int>, allowMalformed: true);
          final opfXml = XmlDocument.parse(opfContent);

          // 2. Parse Dublin Core Metadata
          final titleElem = opfXml.findAllElements('dc:title').firstOrNull;
          if (titleElem != null && titleElem.innerText.trim().isNotEmpty) {
            title = titleElem.innerText.trim();
          }

          final creatorElem = opfXml.findAllElements('dc:creator').firstOrNull;
          if (creatorElem != null && creatorElem.innerText.trim().isNotEmpty) {
            author = creatorElem.innerText.trim();
          }

          // 3. Locate Cover Image
          final coverHref = _extractCoverHref(opfXml);
          if (coverHref != null) {
            // Resolve relative to OPF directory
            final opfDir = opfPath.contains('/') ? opfPath.substring(0, opfPath.lastIndexOf('/') + 1) : '';
            final resolvedCoverPath = _normalizePath(opfDir + Uri.decodeComponent(coverHref));

            final coverArchiveFile = _findFileInArchive(archive, resolvedCoverPath);
            if (coverArchiveFile != null) {
              if (!coversDir.existsSync()) {
                coversDir.createSync(recursive: true);
              }
              final ext = resolvedCoverPath.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
              final targetFile = File('${coversDir.path}/$hash.$ext');
              await targetFile.writeAsBytes(coverArchiveFile.content as List<int>);
              coverPath = targetFile.path;
            }
          }
        }
      }
    } catch (_) {
      // Fallback gracefully on parsing errors
    }

    if (title.isEmpty) {
      if (sourceFilePath != null && sourceFilePath.isNotEmpty) {
        final name = sourceFilePath.split(Platform.pathSeparator).last;
        title = name.replaceAll(RegExp(r'\.epub$', caseSensitive: false), '');
      } else {
        title = 'Untitled Book';
      }
    }

    return Book(
      hash: hash,
      title: title,
      author: author,
      coverUri: coverPath,
      filePath: sourceFilePath,
      percentage: 0.0,
      addedAt: DateTime.now().millisecondsSinceEpoch,
      fileSize: bytes.length,
    );
  }

  /// Parses an EPUB file directly from disk.
  static Future<Book> parseEpubFile(
    File file, {
    required Directory coversDir,
  }) async {
    final bytes = await file.readAsBytes();
    return parseEpubBytes(
      bytes: bytes,
      sourceFilePath: file.path,
      coversDir: coversDir,
    );
  }

  static ArchiveFile? _findFileInArchive(Archive archive, String targetPath) {
    final normalized = targetPath.toLowerCase().replaceAll('\\', '/');
    for (final file in archive) {
      if (file.name.toLowerCase().replaceAll('\\', '/') == normalized) {
        return file;
      }
    }
    return null;
  }

  static String? _extractCoverHref(XmlDocument opfXml) {
    final manifest = opfXml.findAllElements('manifest').firstOrNull;
    if (manifest == null) return null;

    // A. EPUB 3: Check properties="cover-image"
    for (final item in manifest.findAllElements('item')) {
      final properties = item.getAttribute('properties');
      if (properties != null && properties.split(' ').contains('cover-image')) {
        return item.getAttribute('href');
      }
    }

    // B. EPUB 2: Check meta name="cover" content="item_id"
    for (final meta in opfXml.findAllElements('meta')) {
      if (meta.getAttribute('name')?.toLowerCase() == 'cover') {
        final coverId = meta.getAttribute('content');
        if (coverId != null) {
          for (final item in manifest.findAllElements('item')) {
            if (item.getAttribute('id') == coverId) {
              return item.getAttribute('href');
            }
          }
        }
      }
    }

    // C. Heuristic: item id contains "cover" and media-type is an image
    for (final item in manifest.findAllElements('item')) {
      final id = item.getAttribute('id')?.toLowerCase() ?? '';
      final mediaType = item.getAttribute('media-type')?.toLowerCase() ?? '';
      if ((id == 'cover' || id.contains('cover-image') || id.contains('cover_image')) &&
          mediaType.startsWith('image/')) {
        return item.getAttribute('href');
      }
    }

    // D. Heuristic: href contains "cover" and media-type is an image
    for (final item in manifest.findAllElements('item')) {
      final href = item.getAttribute('href')?.toLowerCase() ?? '';
      final mediaType = item.getAttribute('media-type')?.toLowerCase() ?? '';
      if (href.contains('cover') && mediaType.startsWith('image/')) {
        return item.getAttribute('href');
      }
    }

    return null;
  }

  static String _normalizePath(String raw) {
    final parts = raw.replaceAll('\\', '/').split('/');
    final stack = <String>[];
    for (final part in parts) {
      if (part == '' || part == '.') continue;
      if (part == '..') {
        if (stack.isNotEmpty) stack.removeLast();
      } else {
        stack.add(part);
      }
    }
    return stack.join('/');
  }

  /// Extracts Table of Contents from NCX (EPUB 2) or NAV (EPUB 3).
  static List<TOCItem> extractToc(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final (opfDoc, opfDir) = _getOpfDoc(archive);
      if (opfDoc == null) return const [];

      return _extractTocInternal(archive, opfDoc, opfDir);
    } catch (_) {
      return const [];
    }
  }

  /// Extracts both readable chapters and complete Table of Contents.
  static ({List<EpubChapter> chapters, List<TOCItem> toc}) extractBookContent(Uint8List bytes) {
    final chapters = <EpubChapter>[];
    var toc = <TOCItem>[];

    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final (opfDoc, opfDir) = _getOpfDoc(archive);
      if (opfDoc == null) return (chapters: chapters, toc: toc);

      toc = _extractTocInternal(archive, opfDoc, opfDir);

      // Build quick lookup map: normalizedHref -> TOC label
      final tocMap = <String, String>{};
      for (final item in toc) {
        if (item.href != null && item.href!.isNotEmpty) {
          final cleanHref = item.href!.split('#').first.replaceAll('\\', '/').toLowerCase();
          tocMap.putIfAbsent(cleanHref, () => item.label);
        }
        for (final sub in item.subitems) {
          if (sub.href != null && sub.href!.isNotEmpty) {
            final cleanSub = sub.href!.split('#').first.replaceAll('\\', '/').toLowerCase();
            tocMap.putIfAbsent(cleanSub, () => sub.label);
          }
        }
      }

      // Build id -> href map from manifest
      final manifestMap = <String, String>{};
      final manifest = opfDoc.findAllElements('manifest').firstOrNull;
      if (manifest != null) {
        for (final item in manifest.findAllElements('item')) {
          final id = item.getAttribute('id');
          final href = item.getAttribute('href');
          if (id != null && href != null) {
            manifestMap[id] = href;
          }
        }
      }

      // Follow spine in reading order
      final spine = opfDoc.findAllElements('spine').firstOrNull;
      if (spine != null) {
        int chapterIndex = 1;
        for (final itemref in spine.findAllElements('itemref')) {
          final idref = itemref.getAttribute('idref');
          if (idref == null) continue;
          final href = manifestMap[idref];
          if (href == null) continue;

          final resolvedPath = _normalizePath(opfDir + Uri.decodeComponent(href));
          final chapterFile = _findFileInArchive(archive, resolvedPath);
          if (chapterFile == null) continue;

          final cleanHref = href.split('#').first.replaceAll('\\', '/').toLowerCase();
          final defaultTitle = tocMap[cleanHref] ?? 'Chapter $chapterIndex';

          final rawHtml =
              utf8.decode(chapterFile.content as List<int>, allowMalformed: true);
          final parsed = _parseChapterContent(
            rawHtml,
            defaultTitle: defaultTitle,
          );
          if (parsed.paragraphs.isNotEmpty) {
            chapters.add(EpubChapter(
              id: idref,
              title: parsed.title,
              href: href,
              paragraphs: parsed.paragraphs,
            ));
            chapterIndex++;
          }
        }
      }
    } catch (_) {}

    return (chapters: chapters, toc: toc);
  }

  /// Extracts all readable chapters in spine reading order using pure Dart.
  static List<EpubChapter> extractChapters(Uint8List bytes) {
    return extractBookContent(bytes).chapters;
  }

  static (XmlDocument? opfDoc, String opfDir) _getOpfDoc(Archive archive) {
    String? opfPath;
    final containerFile = _findFileInArchive(archive, 'META-INF/container.xml');
    if (containerFile != null) {
      final containerContent =
          utf8.decode(containerFile.content as List<int>, allowMalformed: true);
      final containerXml = XmlDocument.parse(containerContent);
      final rootfile = containerXml.findAllElements('rootfile').firstOrNull;
      opfPath = rootfile?.getAttribute('full-path');
    }

    if (opfPath == null || opfPath.isEmpty) {
      for (final file in archive) {
        if (file.name.toLowerCase().endsWith('.opf')) {
          opfPath = file.name;
          break;
        }
      }
    }

    if (opfPath == null) return (null, '');

    final opfFile = _findFileInArchive(archive, opfPath);
    if (opfFile == null) return (null, '');

    final opfContent =
        utf8.decode(opfFile.content as List<int>, allowMalformed: true);
    final opfXml = XmlDocument.parse(opfContent);
    final opfDir = opfPath.contains('/')
        ? opfPath.substring(0, opfPath.lastIndexOf('/') + 1)
        : '';
    return (opfXml, opfDir);
  }

  static List<TOCItem> _extractTocInternal(
    Archive archive,
    XmlDocument opfDoc,
    String opfDir,
  ) {
    String? ncxHref;
    String? navHref;

    for (final item in opfDoc.findAllElements('item')) {
      final href = item.getAttribute('href');
      final mediaType = item.getAttribute('media-type');
      final props = item.getAttribute('properties') ?? '';

      if (mediaType == 'application/x-dtbncx+xml') {
        ncxHref = href;
      }
      if (props.split(' ').contains('nav')) {
        navHref = href;
      }
    }

    // 1. Try EPUB 3 Nav
    if (navHref != null) {
      final resolvedNav = _normalizePath(opfDir + Uri.decodeComponent(navHref));
      final navFile = _findFileInArchive(archive, resolvedNav);
      if (navFile != null) {
        try {
          final content = utf8.decode(navFile.content as List<int>, allowMalformed: true);
          final doc = XmlDocument.parse(content);
          final items = <TOCItem>[];
          for (final a in doc.findAllElements('a')) {
            final text = _decodeHtmlEntities(a.innerText.trim());
            final href = a.getAttribute('href');
            if (text.isNotEmpty && href != null) {
              items.add(TOCItem(label: text, href: href));
            }
          }
          if (items.isNotEmpty) return items;
        } catch (_) {}
      }
    }

    // 2. Try EPUB 2 NCX
    if (ncxHref != null) {
      final resolvedNcx = _normalizePath(opfDir + Uri.decodeComponent(ncxHref));
      final ncxFile = _findFileInArchive(archive, resolvedNcx);
      if (ncxFile != null) {
        try {
          final content = utf8.decode(ncxFile.content as List<int>, allowMalformed: true);
          final doc = XmlDocument.parse(content);
          final items = <TOCItem>[];
          final navMap = doc.findAllElements('navMap').firstOrNull;
          if (navMap != null) {
            for (final np in navMap.findElements('navPoint')) {
              final label = np.findElements('navLabel').firstOrNull?.findElements('text').firstOrNull?.innerText.trim();
              final src = np.findElements('content').firstOrNull?.getAttribute('src');
              if (label != null && label.isNotEmpty && src != null) {
                final subitems = <TOCItem>[];
                for (final child in np.findElements('navPoint')) {
                  final subLabel = child.findElements('navLabel').firstOrNull?.findElements('text').firstOrNull?.innerText.trim();
                  final subSrc = child.findElements('content').firstOrNull?.getAttribute('src');
                  if (subLabel != null && subLabel.isNotEmpty && subSrc != null) {
                    subitems.add(TOCItem(
                      label: _decodeHtmlEntities(subLabel),
                      href: subSrc,
                    ));
                  }
                }
                items.add(TOCItem(
                  label: _decodeHtmlEntities(label),
                  href: src,
                  subitems: subitems,
                ));
              }
            }
          }
          if (items.isNotEmpty) return items;
        } catch (_) {}
      }
    }

    return const [];
  }

  static String _decodeHtmlEntities(String raw) {
    return raw
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&ldquo;', '“')
        .replaceAll('&rdquo;', '”')
        .replaceAll('&lsquo;', '‘')
        .replaceAll('&rsquo;', '’')
        .replaceAll('&hellip;', '…')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }

  static ({String title, List<String> paragraphs}) _parseChapterContent(
    String rawHtml, {
    required String defaultTitle,
  }) {
    String title = defaultTitle;
    final paragraphs = <String>[];

    try {
      final doc = XmlDocument.parse(rawHtml);
      final titleElem = doc.findAllElements('title').firstOrNull;
      if (titleElem != null && titleElem.innerText.trim().isNotEmpty) {
        title = _decodeHtmlEntities(titleElem.innerText.trim());
      } else {
        final heading = doc.findAllElements('h1').firstOrNull ??
            doc.findAllElements('h2').firstOrNull ??
            doc.findAllElements('h3').firstOrNull;
        if (heading != null && heading.innerText.trim().isNotEmpty) {
          title = _decodeHtmlEntities(heading.innerText.trim());
        }
      }

      for (final el in doc.descendants.whereType<XmlElement>()) {
        final tag = el.name.local.toLowerCase();
        if (['p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'blockquote', 'li']
            .contains(tag)) {
          final text = _decodeHtmlEntities(el.innerText.trim());
          if (text.isNotEmpty && !paragraphs.contains(text)) {
            paragraphs.add(text);
          }
        }
      }
    } catch (_) {
      final cleaned = rawHtml
          .replaceAll(
            RegExp(
              r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>',
              caseSensitive: false,
            ),
            '',
          )
          .replaceAll(
            RegExp(
              r'<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>',
              caseSensitive: false,
            ),
            '',
          );
      final pMatches = RegExp(
        r'<(?:p|h[1-6]|li|blockquote)[^>]*>(.*?)<\/(?:p|h[1-6]|li|blockquote)>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(cleaned);
      for (final match in pMatches) {
        final content = match.group(1);
        if (content != null) {
          final text = _decodeHtmlEntities(
            content.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
          );
          if (text.isNotEmpty && !paragraphs.contains(text)) {
            paragraphs.add(text);
          }
        }
      }
      if (paragraphs.isEmpty) {
        final stripped = cleaned.replaceAll(RegExp(r'<[^>]*>'), ' ').trim();
        final lines = stripped
            .split(RegExp(r'\n+'))
            .map((l) => _decodeHtmlEntities(l.trim()))
            .where((l) => l.isNotEmpty)
            .toList();
        paragraphs.addAll(lines);
      }
    }

    return (title: title, paragraphs: paragraphs);
  }
}

/// Extracted EPUB chapter model for pure Dart reading support
class EpubChapter {
  final String id;
  final String title;
  final String href;
  final List<String> paragraphs;

  const EpubChapter({
    required this.id,
    required this.title,
    required this.href,
    required this.paragraphs,
  });

  String get plainText => paragraphs.join('\n\n');
}
