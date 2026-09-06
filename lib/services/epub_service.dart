import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:xml/xml.dart';
import '../models/book.dart';

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
    } catch (e) {
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
}
