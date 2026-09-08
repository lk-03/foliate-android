import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/models.dart';

/// Callback signatures for reader events
typedef OnReadyCallback = void Function();
typedef OnRelocateCallback = void Function(ReadingLocation location);
typedef OnProgressUpdateCallback = void Function(
  double percentage,
  ReadingLocation location,
);
typedef OnTOCCallback = void Function(List<TOCItem> toc);
typedef OnSearchResultCallback = void Function(SearchSection section);
typedef OnSearchDoneCallback = void Function();
typedef OnTextSelectedCallback = void Function(String text, String? cfi);
typedef OnSelectionClearedCallback = void Function();
typedef OnAnnotationClickedCallback = void Function(String cfi);
typedef OnTTSTextCallback = void Function(List<String> paragraphs);
typedef OnToggleControlsCallback = void Function();
typedef OnReaderErrorCallback = void Function(String error);

/// Typed IPC bridge communicating with `foliate-js` inside WebView
class ReaderBridge {
  WebViewController? _controller;
  bool _isWebViewReady = false;

  // Event Listeners
  OnReadyCallback? onReady;
  OnRelocateCallback? onRelocate;
  OnProgressUpdateCallback? onProgressUpdate;
  OnTOCCallback? onTOCReady;
  OnSearchResultCallback? onSearchResult;
  OnSearchDoneCallback? onSearchDone;
  OnTextSelectedCallback? onTextSelected;
  OnSelectionClearedCallback? onSelectionCleared;
  OnAnnotationClickedCallback? onAnnotationClicked;
  OnTTSTextCallback? onTTSText;
  OnToggleControlsCallback? onToggleControls;
  OnReaderErrorCallback? onError;

  bool get isReady => _isWebViewReady;

  /// Attach the WebViewController to this bridge
  void attachController(WebViewController controller) {
    _controller = controller;
  }

  /// Detach the WebViewController
  void detachController() {
    _controller = null;
    _isWebViewReady = false;
  }

  /// Handles incoming JSON messages dispatched from reader.html
  void handleMessage(String message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message);
      final String? type = data['type'];
      final dynamic payload = data['payload'];

      switch (type) {
        case 'WEBVIEW_READY':
          _isWebViewReady = true;
          onReady?.call();
          break;

        case 'RELOCATE':
        case 'PROGRESS_UPDATE':
          if (payload is Map<String, dynamic>) {
            final location = _parseReadingLocation(payload);
            onRelocate?.call(location);
            if (type == 'PROGRESS_UPDATE') {
              final pct = (payload['percentage'] as num?)?.toDouble() ?? 0.0;
              onProgressUpdate?.call(pct, location);
            }
          }
          break;

        case 'TOC_READY':
          if (payload is List) {
            final toc = payload
                .whereType<Map<String, dynamic>>()
                .map((m) => TOCItem.fromMap(m))
                .toList();
            onTOCReady?.call(toc);
          } else {
            onTOCReady?.call(const []);
          }
          break;

        case 'SEARCH_RESULT':
          if (payload is Map<String, dynamic>) {
            final section = SearchSection.fromMap(payload);
            onSearchResult?.call(section);
          } else if (payload is Map) {
            final section = SearchSection.fromMap(Map<String, dynamic>.from(payload));
            onSearchResult?.call(section);
          }
          break;

        case 'SEARCH_DONE':
          onSearchDone?.call();
          break;

        case 'TEXT_SELECTED':
          if (payload is Map<String, dynamic>) {
            final text = payload['text'] as String? ?? '';
            final cfi = payload['cfi'] as String?;
            onTextSelected?.call(text, cfi);
          }
          break;

        case 'SELECTION_CLEARED':
          onSelectionCleared?.call();
          break;

        case 'ANNOTATION_CLICKED':
          if (payload is Map<String, dynamic>) {
            final cfi = payload['cfi'] as String? ?? '';
            if (cfi.isNotEmpty) onAnnotationClicked?.call(cfi);
          } else if (payload is String && payload.isNotEmpty) {
            onAnnotationClicked?.call(payload);
          }
          break;

        case 'TTS_TEXT':
          if (payload is Map<String, dynamic>) {
            final paragraphs = (payload['paragraphs'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                const [];
            onTTSText?.call(paragraphs);
          }
          break;

        case 'TOGGLE_CONTROLS':
          onToggleControls?.call();
          break;

        case 'ERROR':
          final errorMsg = payload?.toString() ?? 'Unknown reader error';
          debugPrint('ReaderBridge Error: $errorMsg');
          onError?.call(errorMsg);
          break;

        default:
          debugPrint('ReaderBridge: Unhandled message type: $type');
      }
    } catch (e, st) {
      debugPrint('ReaderBridge message decode exception: $e\n$st');
    }
  }

  ReadingLocation _parseReadingLocation(Map<String, dynamic> data) {
    final locationMap = data['location'] as Map<String, dynamic>?;
    final chapterMap = data['chapterLocation'] as Map<String, dynamic>?;
    final sectionData = data['section'];
    final sectionMap = sectionData is Map<String, dynamic> ? sectionData : null;
    final cfi = (data['cfi'] ?? data['locationCfi'])?.toString() ?? '';
    final fraction = (data['fraction'] as num?)?.toDouble() ?? 0.0;
    final percentage = (data['percentage'] as num?)?.toDouble() ?? (fraction * 100);

    return ReadingLocation(
      cfi: cfi,
      fraction: fraction,
      percentage: percentage,
      currentLocation: (locationMap?['current'] as num?)?.toInt(),
      totalLocations: (locationMap?['total'] as num?)?.toInt(),
      currentSection: (sectionMap?['current'] as num?)?.toInt() ?? (sectionData as num?)?.toInt(),
      totalSections: (sectionMap?['total'] as num?)?.toInt() ?? (data['totalSections'] as num?)?.toInt(),
      sectionTitle: data['sectionTitle'] as String?,
      excerpt: data['excerpt'] as String?,
      chapterCurrentPage: (chapterMap?['current'] as num?)?.toInt(),
      chapterTotalPages: (chapterMap?['total'] as num?)?.toInt(),
      pagesLeftInChapter: (chapterMap?['pagesLeft'] as num?)?.toInt(),
      timeLeftSectionSeconds: (data['timeLeftSectionSeconds'] as num?)?.toInt(),
      timeLeftBookSeconds: (data['timeLeftBookSeconds'] as num?)?.toInt(),
    );
  }

  // --- Outgoing JavaScript Calls ---

  /// Opens an EPUB given its Base64-encoded string and optional starting CFI
  Future<void> openBook(String base64Epub, {String? initialCfi}) async {
    final cfiParam = initialCfi != null ? jsonEncode(initialCfi) : 'null';
    await _controller?.runJavaScript('window.openBook(${jsonEncode(base64Epub)}, $cfiParam);');
  }

  int _lastNavTime = 0;

  /// Advances reader to the next page or scroll increment (debounced to prevent double skips)
  Future<void> goNext() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastNavTime < 250) return;
    _lastNavTime = now;
    await _controller?.runJavaScript('window.goNext();');
  }

  /// Moves reader to the previous page or scroll increment (debounced to prevent double skips)
  Future<void> goPrev() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastNavTime < 250) return;
    _lastNavTime = now;
    await _controller?.runJavaScript('window.goPrev();');
  }

  /// Navigates to a fractional location in the book (0 to 100)
  Future<void> goToPercentage(double percentage) async {
    await _controller?.runJavaScript('window.goToPercentage($percentage);');
  }

  /// Navigates to a specific EPUB spine href or CFI string
  Future<void> goToHref(String href) async {
    await _controller?.runJavaScript('window.goToHref(${jsonEncode(href)});');
  }

  /// Applies reader typography and appearance settings
  Future<void> applyReaderSettings(ReaderSettings settings) async {
    final jsonString = jsonEncode(settings.toMap());
    await _controller?.runJavaScript('window.applyReaderSettings($jsonString);');
  }

  /// Starts async full-text search across chapters
  Future<void> searchBook(String query, {bool matchCase = false}) async {
    await _controller?.runJavaScript(
      'window.searchBook(${jsonEncode(query)}, $matchCase);',
    );
  }

  /// Clears active in-text search highlights
  Future<void> clearSearch() async {
    await _controller?.runJavaScript('window.clearSearch();');
  }

  /// Renders a permanent color highlight over a CFI range
  Future<void> addAnnotation(String cfi, String color) async {
    await _controller?.runJavaScript(
      'window.addAnnotation(${jsonEncode(cfi)}, ${jsonEncode(color)});',
    );
  }

  /// Deletes an annotation highlight
  Future<void> deleteAnnotation(String cfi) async {
    await _controller?.runJavaScript('window.deleteAnnotation(${jsonEncode(cfi)});');
  }

  /// Bulk hydrates saved annotations into the WebView reader engine
  Future<void> loadAnnotations(List<Annotation> annotations) async {
    final payload = jsonEncode(
      annotations.map((a) => {'cfi': a.cfi, 'color': a.color}).toList(),
    );
    await _controller?.runJavaScript(
      'if (window.loadAnnotations) window.loadAnnotations($payload);',
    );
  }

  /// Extracts body text of the active chapter for Text-to-Speech narration
  Future<void> getChapterText() async {
    await _controller?.runJavaScript('window.getChapterText();');
  }

  /// Probes the WebView to check if it's already booted
  Future<void> checkReady() async {
    await _controller?.runJavaScript('if (window.checkReady) window.checkReady();');
  }

  /// Returns text of the current visible page or section
  Future<String?> getCurrentPageText() async {
    try {
      final res = await _controller?.runJavaScriptReturningResult(
        'window.getCurrentPageText ? window.getCurrentPageText() : ""',
      );
      if (res is String && res.isNotEmpty && res != '""') {
        final clean = res.startsWith('"') && res.endsWith('"')
            ? jsonDecode(res) as String
            : res;
        return clean.trim();
      }
    } catch (_) {}
    return null;
  }
}
