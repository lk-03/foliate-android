import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';
import '../models/catalog_book.dart';
import '../models/opds_feed.dart';

/// Service for fetching and parsing OPDS 1.2 and Atom catalog feeds,
/// as well as querying the Open Library search API.
class OpdsService {
  static OpdsService? _instance;
  static OpdsService get instance => _instance ??= OpdsService._();

  final Dio _dio;

  OpdsService._({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
                headers: {
                  'User-Agent':
                      'Foliate/1.0.0 (Android; +https://github.com/lk-03/foliate-android)',
                  'Accept':
                      'application/atom+xml,application/xml,text/xml,application/json,*/*',
                },
                followRedirects: true,
                maxRedirects: 5,
              ),
            );

  /// Test constructor for dependency injection
  @visibleForTesting
  OpdsService.withDio(Dio dio) : _dio = dio;

  /// Fetches and parses an OPDS or Atom catalog feed from [url].
  Future<OpdsFeed> fetchFeed(String url) async {
    try {
      final response = await _dio.get<String>(
        url,
        options: Options(responseType: ResponseType.plain),
      );

      final xmlString = response.data;
      if (xmlString == null || xmlString.trim().isEmpty) {
        throw Exception('Empty response from catalog feed');
      }

      return parseFeedXml(xmlString, baseUrl: url);
    } catch (e) {
      if (e is DioException) {
        throw Exception('Network error fetching catalog: ${e.message}');
      }
      rethrow;
    }
  }

  /// Parses raw OPDS/Atom XML text into an [OpdsFeed] object.
  OpdsFeed parseFeedXml(String xmlString, {required String baseUrl}) {
    final baseUri = Uri.parse(baseUrl);
    final document = XmlDocument.parse(xmlString);

    // Feed root element
    final feedEl = document.findAllElements('feed').firstOrNull ?? document.rootElement;

    // Feed metadata
    final feedTitle = _extractText(feedEl, 'title') ?? 'Catalog';
    final feedSubtitle = _extractText(feedEl, 'subtitle') ?? '';
    final feedId = _extractText(feedEl, 'id');
    final iconEl = feedEl.findElements('icon').firstOrNull;
    final iconUrl = iconEl != null ? _resolveUrl(baseUri, iconEl.innerText.trim()) : null;

    String? nextPageUrl;
    String? searchUrl;

    // Process top-level links
    for (final link in feedEl.findElements('link')) {
      final rel = link.getAttribute('rel')?.toLowerCase() ?? '';
      final href = link.getAttribute('href');
      final type = link.getAttribute('type')?.toLowerCase() ?? '';

      if (href == null || href.isEmpty) continue;

      if (rel == 'next') {
        nextPageUrl = _resolveUrl(baseUri, href);
      } else if (rel == 'search' || type.contains('opensearchdescription')) {
        searchUrl = _resolveUrl(baseUri, href);
      }
    }

    // Process entries
    final entries = <CatalogBook>[];
    for (final entry in feedEl.findElements('entry')) {
      final parsed = _parseEntry(entry, baseUri, feedTitle);
      if (parsed != null) {
        entries.add(parsed);
      }
    }

    return OpdsFeed(
      title: feedTitle,
      subtitle: feedSubtitle,
      id: feedId,
      iconUrl: iconUrl,
      nextPageUrl: nextPageUrl,
      searchUrl: searchUrl,
      entries: entries,
    );
  }

  CatalogBook? _parseEntry(XmlElement entry, Uri baseUri, String sourceCatalog) {
    final id = _extractText(entry, 'id') ?? '';
    final title = _extractText(entry, 'title') ?? 'Untitled';

    // Extract author: <author><name> or <dc:creator>
    String author = 'Unknown Author';
    final authorEl = entry.findElements('author').firstOrNull;
    if (authorEl != null) {
      final nameEl = authorEl.findElements('name').firstOrNull;
      if (nameEl != null && nameEl.innerText.trim().isNotEmpty) {
        author = nameEl.innerText.trim();
      } else if (authorEl.innerText.trim().isNotEmpty) {
        author = authorEl.innerText.trim();
      }
    } else {
      final dcCreator = entry.findElements('dc:creator').firstOrNull;
      if (dcCreator != null && dcCreator.innerText.trim().isNotEmpty) {
        author = dcCreator.innerText.trim();
      }
    }

    // Extract summary or content
    String summary = '';
    final summaryEl = entry.findElements('summary').firstOrNull;
    if (summaryEl != null) {
      summary = _stripHtml(summaryEl.innerText.trim());
    } else {
      final contentEl = entry.findElements('content').firstOrNull;
      if (contentEl != null) {
        summary = _stripHtml(contentEl.innerText.trim());
      }
    }

    // Extract categories
    final categories = <String>[];
    for (final cat in entry.findElements('category')) {
      final term = cat.getAttribute('term')?.trim();
      final label = cat.getAttribute('label')?.trim();
      final text = label?.isNotEmpty == true ? label! : (term ?? '');
      if (text.isNotEmpty && !categories.contains(text)) {
        categories.add(text);
      }
    }

    // Extract links
    String? coverUrl;
    String? downloadUrl;
    int? downloadSize;
    bool isNavigation = false;
    String? navigationUrl;

    // Check media:thumbnail first (common in Standard Ebooks & Yahoo media RSS)
    for (final mediaThumb in entry.findElements('media:thumbnail')) {
      final url = mediaThumb.getAttribute('url');
      if (url != null && url.isNotEmpty) {
        coverUrl = _resolveUrl(baseUri, url);
        break;
      }
    }

    for (final link in entry.findElements('link')) {
      final rel = link.getAttribute('rel')?.toLowerCase() ?? '';
      final type = link.getAttribute('type')?.toLowerCase() ?? '';
      final href = link.getAttribute('href');

      if (href == null || href.isEmpty) continue;
      final resolvedHref = _resolveUrl(baseUri, href);

      // 1. Cover artwork
      if (coverUrl == null) {
        if (rel.contains('image') || rel.contains('thumbnail')) {
          coverUrl = resolvedHref;
        }
      }

      // 2. EPUB acquisition / download link
      final isEpubType = type.contains('application/epub+zip') ||
          type.contains('application/epub') ||
          href.endsWith('.epub') ||
          href.contains('.epub?');

      final isAcquisitionRel = rel.contains('acquisition') ||
          rel == 'enclosure' ||
          rel.contains('http://opds-spec.org/acquisition');

      if (isEpubType && (isAcquisitionRel || downloadUrl == null)) {
        downloadUrl = resolvedHref;
        final lengthStr = link.getAttribute('length');
        if (lengthStr != null) {
          downloadSize = int.tryParse(lengthStr);
        }
      }

      // 3. Navigation subsection
      if (rel.contains('subsection') ||
          (type.contains('profile=opds-catalog') && !isEpubType) ||
          (type.contains('application/atom+xml') && !isEpubType && downloadUrl == null)) {
        isNavigation = true;
        navigationUrl = resolvedHref;
      }
    }

    // If an entry only has a navigation subsection and no direct download, mark as navigation
    if (navigationUrl != null && downloadUrl == null) {
      isNavigation = true;
    }

    return CatalogBook(
      id: id.isNotEmpty ? id : title,
      title: title,
      author: author,
      summary: summary,
      coverUrl: coverUrl,
      downloadUrl: downloadUrl,
      downloadSize: downloadSize,
      isNavigation: isNavigation,
      navigationUrl: navigationUrl,
      categories: categories,
      sourceCatalog: sourceCatalog,
    );
  }

  /// Searches the Open Library REST API for public domain books.
  Future<List<CatalogBook>> searchOpenLibrary(String query, {int page = 1}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return const [];

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://openlibrary.org/search.json',
        queryParameters: {
          'q': cleanQuery,
          'page': page,
          'limit': 20,
          'mode': 'everything',
        },
      );

      final data = response.data;
      if (data == null) return const [];

      final docs = data['docs'] as List<dynamic>? ?? const [];
      final results = <CatalogBook>[];

      for (final doc in docs) {
        if (doc is! Map<String, dynamic>) continue;

        final title = doc['title'] as String? ?? 'Untitled';
        final authorsList = doc['author_name'] as List<dynamic>?;
        final author = authorsList != null && authorsList.isNotEmpty
            ? authorsList.first.toString()
            : 'Unknown Author';

        final coverId = doc['cover_i'];
        final coverUrl = coverId != null
            ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
            : null;

        // Internet Archive ID for public domain scans
        final iaList = doc['ia'] as List<dynamic>?;
        final publicScan = doc['public_scan_b'] as bool? ?? false;
        final hasFullText = doc['has_fulltext'] as bool? ?? false;

        String? downloadUrl;
        if (iaList != null && iaList.isNotEmpty && (publicScan || hasFullText)) {
          final iaId = iaList.first.toString();
          downloadUrl = 'https://archive.org/download/$iaId/$iaId.epub';
        }

        final subjects = (doc['subject'] as List<dynamic>?)
                ?.take(4)
                .map((e) => e.toString())
                .toList() ??
            const [];

        final firstPublishYear = doc['first_publish_year'];
        final summary = firstPublishYear != null
            ? 'First published in $firstPublishYear.'
            : '';

        results.add(CatalogBook(
          id: doc['key'] as String? ?? title,
          title: title,
          author: author,
          summary: summary,
          coverUrl: coverUrl,
          downloadUrl: downloadUrl,
          categories: subjects,
          sourceCatalog: 'Open Library',
        ));
      }

      return results;
    } catch (e) {
      if (e is DioException) {
        throw Exception('Open Library search failed: ${e.message}');
      }
      rethrow;
    }
  }

  String? _extractText(XmlElement parent, String tagName) {
    final el = parent.findElements(tagName).firstOrNull;
    if (el == null) return null;
    final text = el.innerText.trim();
    return text.isNotEmpty ? text : null;
  }

  String _resolveUrl(Uri baseUri, String relativeOrAbsolute) {
    try {
      final parsed = Uri.parse(relativeOrAbsolute);
      if (parsed.hasScheme) return relativeOrAbsolute;
      return baseUri.resolve(relativeOrAbsolute).toString();
    } catch (_) {
      return relativeOrAbsolute;
    }
  }

  String _stripHtml(String html) {
    if (!html.contains('<') && !html.contains('&')) return html;
    var result = html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return result;
  }
}
