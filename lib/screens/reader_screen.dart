import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../components/components.dart';
import '../models/models.dart';
import '../reader/reader.dart';
import '../services/services.dart';
import '../theme/theme.dart';

/// Full-screen immersive mobile reader interface
class ReaderScreen extends StatefulWidget {
  final Book book;
  final String? initialCfi;

  const ReaderScreen({
    super.key,
    required this.book,
    this.initialCfi,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final ReaderBridge _bridge = ReaderBridge();
  bool _isReady = false;
  ReadingLocation? _currentLocation;
  List<TOCItem> _tableOfContents = const [];
  ReaderSettings _settings = const ReaderSettings();

  // Controls Visibility & Inactivity Timer
  bool _showControls = true;
  Timer? _hideControlsTimer;

  // Selected Text Annotation State
  String? _selectedText;
  String? _selectedCfi;

  // In-Book Search State (Phase 3)
  final ValueNotifier<List<SearchSection>> _searchSectionsNotifier = ValueNotifier([]);
  final ValueNotifier<bool> _isSearchingNotifier = ValueNotifier(false);
  final ValueNotifier<int> _totalMatchesNotifier = ValueNotifier(0);
  final List<SearchResultItem> _allSearchMatches = [];
  int _currentSearchMatchIndex = -1;
  String _currentSearchQuery = '';
  bool _matchCase = false;
  bool _isSearchActive = false;
  // Bookmark & Orientation State (Reader HUD controls)
  bool _isBookmarked = false;
  bool _isOrientationLocked = false;
  double _brightness = 1.0;
  String? _currentPageExcerpt;
  DateTime? _lastReadingFlushTime;
  Timer? _readingHeartbeatTimer;
  bool _hasShownCompletionCeremony = false;

  // TTS State (Phase 4)
  final TtsService _ttsService = TtsService();
  bool _isTtsActive = false;

  // Desktop Side Panel & Shortcuts State (Phase 6)
  ReaderSidePanelType _activeSidePanel = ReaderSidePanelType.none;
  List<Bookmark> _bookmarks = const [];
  List<Annotation> _annotations = const [];
  bool _isHoveringBottom = false;
  bool _isScrubberPopoverOpen = false;

  // Desktop Native Reader Fallback & Watchdog State
  Timer? _watchdogTimer;
  String? _engineError;
  bool _isFallbackMode = false;
  List<EpubChapter> _fallbackChapters = const [];
  int _fallbackChapterIndex = 0;
  final ScrollController _fallbackScrollController = ScrollController();
  List<TwoPageSpread> _desktopSpreads = const [];
  int _currentSpreadIndex = 0;
  PageController? _desktopPageController;
  List<MobilePage> _mobilePages = const [];
  int _currentMobilePageIndex = 0;
  PageController? _mobilePageController;

  @override
  void initState() {
    super.initState();
    if (kIsWeb || Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      _activeSidePanel = ReaderSidePanelType.toc;
    }
    _startWatchdogTimer();
    _setupBridgeListeners();
    _setupTtsListeners();
    _resetInactivityTimer();
    _loadInitialSettings();
    _startReadingTrackerTimer();
  }

  void _startReadingTrackerTimer() {
    _lastReadingFlushTime = DateTime.now();
    _readingHeartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _flushReadingTime();
    });
  }

  void _flushReadingTime() {
    if (_lastReadingFlushTime == null) return;
    final now = DateTime.now();
    final elapsedSeconds = now.difference(_lastReadingFlushTime!).inSeconds;
    _lastReadingFlushTime = now;
    if (elapsedSeconds > 2) {
      StorageService.instance.recordReadingTime(
        elapsedSeconds,
        bookHash: widget.book.hash,
      );
    }
  }

  void _checkAndShowCompletionCeremony(double percentage) {
    if (percentage >= 99.5 && !_hasShownCompletionCeremony) {
      _hasShownCompletionCeremony = true;
      showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => BookCompletionSheet(
          book: widget.book,
          onMarkFinished: () {
            StorageService.instance.markBookFinished(widget.book.hash);
          },
          onClose: () {},
        ),
      );
    }
  }

  Future<void> _loadInitialSettings() async {
    final s = await StorageService.instance.getBookSettings(widget.book.hash);
    if (mounted) {
      setState(() => _settings = s);
      if (s.stayAwake) {
        ScreenAwakeService.instance.setKeepScreenOn(true);
      }
    }
  }

  void _toggleStayAwake() {
    final nextState = !_settings.stayAwake;
    _applySettings(_settings.copyWith(stayAwake: nextState));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nextState ? 'Stay Awake enabled' : 'Stay Awake disabled',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _watchdogTimer?.cancel();
    _fallbackScrollController.dispose();
    _desktopPageController?.dispose();
    _mobilePageController?.dispose();
    _ttsService.dispose();
    _bridge.clearTtsHighlight();
    _readingHeartbeatTimer?.cancel();
    _flushReadingTime();
    _hideControlsTimer?.cancel();
    _searchSectionsNotifier.dispose();
    _isSearchingNotifier.dispose();
    _totalMatchesNotifier.dispose();
    SystemChrome.setPreferredOrientations([]);
    ScreenAwakeService.instance.setKeepScreenOn(false);
    super.dispose();
  }

  void _setupTtsListeners() {
    _ttsService.onParagraphChanged = (index, text) {
      if (mounted) {
        setState(() {});
        _bridge.highlightTtsParagraph(index);
      }
    };

    _ttsService.onStateChanged = (state) {
      if (mounted) setState(() {});
    };

    _ttsService.onChapterFinished = () {
      if (mounted && _isTtsActive) {
        _bridge.goNext().then((_) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted && _isTtsActive) {
              _bridge.getChapterText();
            }
          });
        });
      }
    };
  }

  void _startTts() {
    setState(() {
      _isTtsActive = true;
      _showControls = false;
    });
    _bridge.getChapterText();
  }

  void _stopTts() {
    _ttsService.stop();
    _bridge.clearTtsHighlight();
    if (mounted) {
      setState(() {
        _isTtsActive = false;
      });
    }
  }

  void _resetInactivityTimer() {
    _hideControlsTimer?.cancel();
    if (_showControls) {
      _hideControlsTimer = Timer(const Duration(milliseconds: 4500), () {
        if (mounted && _showControls && _selectedText == null) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _resetInactivityTimer();
    }
  }

  void _startWatchdogTimer() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(const Duration(seconds: 7), () {
      if (mounted && !_isReady && _engineError == null) {
        _onEngineFailed(
          'Reader initialization timed out. The system WebView did not respond.',
        );
      }
    });
  }

  Future<void> _onEngineFailed(String error) async {
    _watchdogTimer?.cancel();
    if (!mounted) return;

    // Check if we can extract chapters from EPUB bytes for pure Dart reading
    try {
      final bytes = await StorageService.instance.getBookBytes(widget.book);
      if (bytes != null && bytes.isNotEmpty) {
        final content = EpubService.extractBookContent(bytes);
        final chapters = content.chapters;
        final toc = content.toc;
        if (chapters.isNotEmpty && mounted) {
          final spreads = DesktopSpreadPaginator.paginate(chapters: chapters);
          final mobilePages = MobilePagePaginator.paginate(chapters: chapters);
          int initialSpread = 0;
          int initialMobilePage = 0;
          final targetCfi = widget.initialCfi ?? widget.book.cfi;
          if (targetCfi != null && targetCfi.isNotEmpty) {
            initialSpread = DesktopSpreadPaginator.findSpreadIndexForHref(spreads, targetCfi);
            initialMobilePage = MobilePagePaginator.findPageIndexForHref(mobilePages, targetCfi);
          } else if (widget.book.percentage > 0) {
            if (spreads.isNotEmpty) {
              initialSpread = ((widget.book.percentage / 100.0) * (spreads.length - 1)).round().clamp(0, spreads.length - 1);
            }
            if (mobilePages.isNotEmpty) {
              initialMobilePage = ((widget.book.percentage / 100.0) * (mobilePages.length - 1)).round().clamp(0, mobilePages.length - 1);
            }
          }
          final spread = spreads.isNotEmpty ? spreads[initialSpread] : null;
          final mobilePage = mobilePages.isNotEmpty ? mobilePages[initialMobilePage] : null;

          _desktopPageController?.dispose();
          _desktopPageController = PageController(initialPage: initialSpread);
          _mobilePageController?.dispose();
          _mobilePageController = PageController(initialPage: initialMobilePage);

          final isWide = MediaQuery.of(context).size.width >= 850;

          setState(() {
            _isFallbackMode = true;
            _fallbackChapters = chapters;
            _desktopSpreads = spreads;
            _mobilePages = mobilePages;
            _currentSpreadIndex = initialSpread;
            _currentMobilePageIndex = initialMobilePage;
            _fallbackChapterIndex = isWide ? (spread?.chapterIndex ?? 0) : (mobilePage?.chapterIndex ?? 0);
            _isReady = true;
            _engineError = null;
            _tableOfContents = toc.isNotEmpty
                ? toc
                : chapters.map((c) => TOCItem(label: c.title, href: c.id)).toList();
            if (isWide && spreads.isNotEmpty) {
              final safeTotal = spreads.length > 1 ? spreads.length - 1 : 1;
              _currentLocation = ReadingLocation(
                currentLocation: spread?.leftLoc ?? 1,
                totalLocations: spread?.totalLocs ?? (chapters.length * 100),
                cfi: spread?.cfi ?? chapters.first.id,
                fraction: spreads.isNotEmpty ? initialSpread / safeTotal : 0.0,
                percentage: spreads.isNotEmpty ? (initialSpread / safeTotal) * 100.0 : widget.book.percentage,
                currentSection: (spread?.chapterIndex ?? 0) + 1,
                totalSections: chapters.length,
                sectionTitle: spread?.chapterTitle ?? chapters.first.title,
              );
            } else if (mobilePages.isNotEmpty) {
              final safeTotal = mobilePages.length > 1 ? mobilePages.length - 1 : 1;
              _currentLocation = ReadingLocation(
                currentLocation: mobilePage?.loc ?? 1,
                totalLocations: mobilePage?.totalLocs ?? (chapters.length * 100),
                cfi: mobilePage?.cfi ?? chapters.first.id,
                fraction: initialMobilePage / safeTotal,
                percentage: (initialMobilePage / safeTotal) * 100.0,
                currentSection: (mobilePage?.chapterIndex ?? 0) + 1,
                totalSections: chapters.length,
                sectionTitle: mobilePage?.chapterTitle ?? chapters.first.title,
              );
            }
          });
          return;
        }
      }
    } catch (e, st) {
      debugPrint('Pure Dart reader fallback failed: $e\n$st');
    }

    if (mounted) {
      setState(() {
        _engineError = error;
      });
    }
  }

  void _onSpreadChanged(int index) {
    if (index < 0 || index >= _desktopSpreads.length) return;
    final spread = _desktopSpreads[index];
    final total = _desktopSpreads.length > 1 ? _desktopSpreads.length - 1 : 1;
    final pct = (index / total) * 100.0;
    if (_mobilePages.isNotEmpty) {
      _currentMobilePageIndex = MobilePagePaginator.findPageIndexForLoc(_mobilePages, spread.leftLoc);
    }
    setState(() {
      _currentSpreadIndex = index;
      _fallbackChapterIndex = spread.chapterIndex;
      _currentLocation = ReadingLocation(
        currentLocation: spread.leftLoc,
        totalLocations: spread.totalLocs,
        fraction: index / total,
        percentage: pct,
        currentSection: spread.chapterIndex + 1,
        totalSections: _fallbackChapters.length,
        sectionTitle: spread.chapterTitle,
        cfi: spread.cfi,
      );
    });
    StorageService.instance.updateBookProgress(
      widget.book.hash,
      percentage: pct,
      cfi: spread.cfi,
    );
  }

  void _desktopPrevSpread() {
    if (_desktopPageController != null && _currentSpreadIndex > 0) {
      _desktopPageController!.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _desktopNextSpread() {
    if (_desktopPageController != null && _currentSpreadIndex < _desktopSpreads.length - 1) {
      _desktopPageController!.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _onMobilePageChanged(int index) {
    if (index < 0 || index >= _mobilePages.length) return;
    final page = _mobilePages[index];
    final safeTotal = _mobilePages.length > 1 ? _mobilePages.length - 1 : 1;
    final pct = (index / safeTotal) * 100.0;
    if (_desktopSpreads.isNotEmpty) {
      _currentSpreadIndex = DesktopSpreadPaginator.findSpreadIndexForLoc(_desktopSpreads, page.loc);
    }
    setState(() {
      _currentMobilePageIndex = index;
      _fallbackChapterIndex = page.chapterIndex;
      _currentLocation = ReadingLocation(
        currentLocation: page.loc,
        totalLocations: page.totalLocs,
        fraction: index / safeTotal,
        percentage: pct,
        currentSection: page.chapterIndex + 1,
        totalSections: _fallbackChapters.length,
        sectionTitle: page.chapterTitle,
        cfi: page.cfi,
      );
    });
    StorageService.instance.updateBookProgress(
      widget.book.hash,
      percentage: pct,
      cfi: page.cfi,
    );
    _checkBookmarkStatus();
  }

  void _mobilePrevPage() {
    if (_mobilePageController == null || !_mobilePageController!.hasClients) return;
    final currentPage = _mobilePageController!.page?.round() ?? _currentMobilePageIndex;
    if (currentPage > 0) {
      _mobilePageController!.animateToPage(
        currentPage - 1,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _mobileNextPage() {
    if (_mobilePageController == null || !_mobilePageController!.hasClients) return;
    final currentPage = _mobilePageController!.page?.round() ?? _currentMobilePageIndex;
    if (currentPage < _mobilePages.length - 1) {
      _mobilePageController!.animateToPage(
        currentPage + 1,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onDesktopScrubberSliderChanged(double percentage) {
    if (_desktopSpreads.isNotEmpty) {
      final spreadIdx = ((percentage / 100.0) * (_desktopSpreads.length - 1))
          .round()
          .clamp(0, _desktopSpreads.length - 1);
      _desktopPageController?.jumpToPage(spreadIdx);
      _onSpreadChanged(spreadIdx);
    } else {
      _fallbackScrubToPercentage(percentage);
    }
  }

  void _onDesktopLocationSubmitted(int loc) {
    final isWide = MediaQuery.of(context).size.width >= 850;
    if (isWide && _desktopSpreads.isNotEmpty) {
      final spreadIdx = DesktopSpreadPaginator.findSpreadIndexForLoc(_desktopSpreads, loc);
      _desktopPageController?.jumpToPage(spreadIdx);
      _onSpreadChanged(spreadIdx);
    } else if (_mobilePages.isNotEmpty) {
      final pageIdx = MobilePagePaginator.findPageIndexForLoc(_mobilePages, loc);
      _mobilePageController?.jumpToPage(pageIdx);
      _onMobilePageChanged(pageIdx);
    }
  }

  void _goToFallbackChapter(int index) {
    if (index < 0 || index >= _fallbackChapters.length) return;
    if (_desktopSpreads.isNotEmpty) {
      final spreadIdx = DesktopSpreadPaginator.findSpreadIndexForChapter(_desktopSpreads, index);
      _desktopPageController?.jumpToPage(spreadIdx);
      _onSpreadChanged(spreadIdx);
      return;
    }
    setState(() {
      _fallbackChapterIndex = index;
      final ch = _fallbackChapters[index];
      final pct = ((index + 1) / _fallbackChapters.length) * 100.0;
      _currentLocation = ReadingLocation(
        cfi: ch.id,
        fraction: (index + 1) / _fallbackChapters.length,
        percentage: pct,
        currentSection: index + 1,
        totalSections: _fallbackChapters.length,
        sectionTitle: ch.title,
      );
    });
    if (_fallbackScrollController.hasClients) {
      _fallbackScrollController.jumpTo(0.0);
    }
    StorageService.instance.updateBookProgress(
      widget.book.hash,
      percentage: ((index + 1) / _fallbackChapters.length) * 100.0,
      cfi: _fallbackChapters[index].id,
    );
  }

  void _fallbackPrevChapter() {
    final isWide = MediaQuery.of(context).size.width >= 850;
    if (isWide && _desktopSpreads.isNotEmpty) {
      _desktopPrevSpread();
    } else if (_mobilePages.isNotEmpty) {
      _mobilePrevPage();
    } else if (_fallbackChapterIndex > 0) {
      _goToFallbackChapter(_fallbackChapterIndex - 1);
    }
  }

  void _fallbackNextChapter() {
    final isWide = MediaQuery.of(context).size.width >= 850;
    if (isWide && _desktopSpreads.isNotEmpty) {
      _desktopNextSpread();
    } else if (_mobilePages.isNotEmpty) {
      _mobileNextPage();
    } else if (_fallbackChapterIndex < _fallbackChapters.length - 1) {
      _goToFallbackChapter(_fallbackChapterIndex + 1);
    }
  }

  void _fallbackScrubToPercentage(double percentage) {
    final isWide = MediaQuery.of(context).size.width >= 850;
    if (isWide && _desktopSpreads.isNotEmpty) {
      _onDesktopScrubberSliderChanged(percentage);
      return;
    }
    if (_mobilePages.isNotEmpty) {
      final pageIdx = ((percentage / 100.0) * (_mobilePages.length - 1))
          .round()
          .clamp(0, _mobilePages.length - 1);
      _mobilePageController?.jumpToPage(pageIdx);
      _onMobilePageChanged(pageIdx);
      return;
    }
    if (_fallbackChapters.isEmpty) return;
    final targetIdx = ((percentage / 100.0) * (_fallbackChapters.length - 1))
        .round()
        .clamp(0, _fallbackChapters.length - 1);
    if (targetIdx != _fallbackChapterIndex) {
      _goToFallbackChapter(targetIdx);
    }
  }

  void _navigateToHref(String href) {
    if (_isFallbackMode) {
      final isWide = MediaQuery.of(context).size.width >= 850;
      if (isWide && _desktopSpreads.isNotEmpty) {
        final spreadIdx = DesktopSpreadPaginator.findSpreadIndexForHref(_desktopSpreads, href);
        _desktopPageController?.jumpToPage(spreadIdx);
        _onSpreadChanged(spreadIdx);
        return;
      }
      if (_mobilePages.isNotEmpty) {
        final pageIdx = MobilePagePaginator.findPageIndexForHref(_mobilePages, href);
        _mobilePageController?.jumpToPage(pageIdx);
        _onMobilePageChanged(pageIdx);
        return;
      }
      final index = _fallbackChapters.indexWhere(
        (c) =>
            c.id == href ||
            c.href == href ||
            href.contains(c.href) ||
            href.contains(c.id),
      );
      if (index >= 0) {
        _goToFallbackChapter(index);
      }
      return;
    }
    _bridge.goToHref(href);
  }

  void _goNext() {
    if (_isFallbackMode) {
      final isWide = MediaQuery.of(context).size.width >= 850;
      if (isWide && _desktopSpreads.isNotEmpty) {
        _desktopNextSpread();
      } else if (_mobilePages.isNotEmpty) {
        _mobileNextPage();
      } else {
        _fallbackNextChapter();
      }
    } else {
      _bridge.goNext();
    }
  }

  void _goPrev() {
    if (_isFallbackMode) {
      final isWide = MediaQuery.of(context).size.width >= 850;
      if (isWide && _desktopSpreads.isNotEmpty) {
        _desktopPrevSpread();
      } else if (_mobilePages.isNotEmpty) {
        _mobilePrevPage();
      } else {
        _fallbackPrevChapter();
      }
    } else {
      _bridge.goPrev();
    }
  }

  void _navigateSection(int delta) {
    if (_isFallbackMode) {
      final isWide = MediaQuery.of(context).size.width >= 850;
      final nextIdx = (_fallbackChapterIndex + delta).clamp(0, _fallbackChapters.length - 1);
      if (isWide && _desktopSpreads.isNotEmpty) {
        final spreadIdx = DesktopSpreadPaginator.findSpreadIndexForChapter(_desktopSpreads, nextIdx);
        _desktopPageController?.jumpToPage(spreadIdx);
        _onSpreadChanged(spreadIdx);
      } else if (_mobilePages.isNotEmpty) {
        final pageIdx = MobilePagePaginator.findPageIndexForChapter(_mobilePages, nextIdx);
        _mobilePageController?.jumpToPage(pageIdx);
        _onMobilePageChanged(pageIdx);
      } else if (nextIdx != _fallbackChapterIndex) {
        _goToFallbackChapter(nextIdx);
      }
    } else if (_tableOfContents.isNotEmpty) {
      final currentSec = _currentLocation?.currentSection ?? 0;
      final nextSec = (currentSec + delta).clamp(0, _tableOfContents.length - 1);
      if (nextSec != currentSec) {
        final href = _tableOfContents[nextSec].href;
        if (href != null && href.isNotEmpty) {
          _navigateToHref(href);
        }
      }
    }
  }

  void _navigateToFirstSection() {
    if (_isFallbackMode) {
      final isWide = MediaQuery.of(context).size.width >= 850;
      if (isWide && _desktopSpreads.isNotEmpty) {
        _desktopPageController?.jumpToPage(0);
        _onSpreadChanged(0);
      } else if (_mobilePages.isNotEmpty) {
        _mobilePageController?.jumpToPage(0);
        _onMobilePageChanged(0);
      } else if (_fallbackChapters.isNotEmpty) {
        _goToFallbackChapter(0);
      }
    } else if (_tableOfContents.isNotEmpty) {
      final href = _tableOfContents.first.href;
      if (href != null && href.isNotEmpty) {
        _navigateToHref(href);
      }
    }
  }

  void _navigateToLastSection() {
    if (_isFallbackMode) {
      final isWide = MediaQuery.of(context).size.width >= 850;
      if (isWide && _desktopSpreads.isNotEmpty) {
        final lastChapter = _fallbackChapters.length - 1;
        final spreadIdx = DesktopSpreadPaginator.findSpreadIndexForChapter(_desktopSpreads, lastChapter);
        _desktopPageController?.jumpToPage(spreadIdx);
        _onSpreadChanged(spreadIdx);
      } else if (_mobilePages.isNotEmpty) {
        final lastPage = _mobilePages.length - 1;
        _mobilePageController?.jumpToPage(lastPage);
        _onMobilePageChanged(lastPage);
      } else if (_fallbackChapters.isNotEmpty) {
        _goToFallbackChapter(_fallbackChapters.length - 1);
      }
    } else if (_tableOfContents.isNotEmpty) {
      final href = _tableOfContents.last.href;
      if (href != null && href.isNotEmpty) {
        _navigateToHref(href);
      }
    }
  }


  void _toggleTts() {
    if (_isTtsActive) {
      _stopTts();
    } else {
      _startTts();
    }
  }

  void _setupBridgeListeners() {
    _bridge.onReady = () {
      _watchdogTimer?.cancel();
      if (mounted) {
        setState(() {
          _isReady = true;
          _engineError = null;
        });
        _loadBook();
      }
    };

    _bridge.onRelocate = (location) {
      if (mounted) {
        setState(() {
          _currentLocation = location;
          if (location.excerpt != null && location.excerpt!.isNotEmpty) {
            _currentPageExcerpt = location.excerpt;
          }
        });
        _checkBookmarkStatus();
        // Persist reading progress to local storage
        StorageService.instance.updateBookProgress(
          widget.book.hash,
          percentage: location.percentage,
          cfi: location.cfi,
        );
        _checkAndShowCompletionCeremony(location.percentage);
      }
    };

    _bridge.onProgressUpdate = (percentage, location) {
      if (mounted) {
        setState(() => _currentLocation = location);
        _checkBookmarkStatus();
      }
    };

    _bridge.onTOCReady = (toc) {
      if (mounted) {
        setState(() => _tableOfContents = toc);
      }
    };

    _bridge.onSearchResult = (section) {
      if (mounted) {
        final currentSections = List<SearchSection>.from(_searchSectionsNotifier.value);
        currentSections.add(section);
        _searchSectionsNotifier.value = currentSections;

        _allSearchMatches.addAll(section.subitems);
        _totalMatchesNotifier.value = _allSearchMatches.length;
      }
    };

    _bridge.onSearchDone = () {
      if (mounted) {
        _isSearchingNotifier.value = false;
      }
    };

    _bridge.onTextSelected = (text, cfi) {
      if (mounted && text.isNotEmpty) {
        setState(() {
          _selectedText = text;
          _selectedCfi = cfi;
          _showControls = false;
        });
      }
    };

    _bridge.onSelectionCleared = () {
      if (mounted && _selectedText != null) {
        setState(() {
          _selectedText = null;
          _selectedCfi = null;
        });
      }
    };

    _bridge.onAnnotationClicked = (cfi) {
      if (mounted) {
        _showAnnotationEditSheet(cfi);
      }
    };

    _bridge.onTTSText = (paragraphs) {
      if (mounted && _isTtsActive) {
        _ttsService.startNarration(paragraphs: paragraphs);
      }
    };

    _bridge.onToggleControls = () {
      if (mounted) _toggleControls();
    };

    _bridge.onError = (error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _isSearchingNotifier.value = false;
        if (!_isReady) {
          _onEngineFailed(error);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Reader error: $error')),
          );
        }
      });
    };
  }

  ReaderSettings _computeEffectiveSettings(ReaderSettings base) {
    if (!mounted) return base;
    final mediaQuery = MediaQuery.of(context);
    final topSafe = mediaQuery.padding.top;
    final bottomSafe = mediaQuery.padding.bottom;
    final screenWidth = mediaQuery.size.width;

    final effectiveTop = (topSafe + 60.0).clamp(96.0, 160.0);
    final effectiveBottom = (bottomSafe + 64.0).clamp(80.0, 140.0);
    final effectiveSide = (screenWidth * base.margin).clamp(28.0, 72.0);

    final isWide = screenWidth >= 850;
    final shouldTwoPage = base.twoPagesLandscape || (isWide && screenWidth > mediaQuery.size.height);

    return base.copyWith(
      paddingTop: effectiveTop,
      paddingBottom: effectiveBottom,
      marginSide: effectiveSide,
      twoPagesLandscape: shouldTwoPage,
    );
  }

  void _applySettings(ReaderSettings newSettings) {
    final prevAwake = _settings.stayAwake;
    setState(() => _settings = newSettings);
    if (prevAwake != newSettings.stayAwake) {
      ScreenAwakeService.instance.setKeepScreenOn(newSettings.stayAwake);
    }
    final effective = _computeEffectiveSettings(newSettings);
    _bridge.applyReaderSettings(effective);
    StorageService.instance.saveBookSettings(widget.book.hash, newSettings);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isReady) {
      final effective = _computeEffectiveSettings(_settings);
      _bridge.applyReaderSettings(effective);
    }
  }

  Future<void> _reloadAnnotations() async {
    final loaded = await StorageService.instance.getAnnotations(widget.book.hash);
    if (mounted) {
      setState(() => _annotations = loaded);
    }
  }

  Future<void> _reloadBookmarks() async {
    final loaded = await StorageService.instance.getBookmarks(widget.book.hash);
    if (mounted) {
      setState(() => _bookmarks = loaded);
    }
  }

  void _openTOC() {
    if (MediaQuery.of(context).size.width >= 850) {
      setState(() {
        _activeSidePanel = _activeSidePanel == ReaderSidePanelType.toc
            ? ReaderSidePanelType.none
            : ReaderSidePanelType.toc;
      });
    } else {
      _showTOCSheet();
    }
  }

  void _openSearch() {
    if (MediaQuery.of(context).size.width >= 850) {
      setState(() {
        _activeSidePanel = _activeSidePanel == ReaderSidePanelType.search
            ? ReaderSidePanelType.none
            : ReaderSidePanelType.search;
      });
    } else {
      _showSearchSheet();
    }
  }

  void _openAppearance() {
    if (MediaQuery.of(context).size.width >= 850) {
      setState(() {
        _activeSidePanel = _activeSidePanel == ReaderSidePanelType.appearance
            ? ReaderSidePanelType.none
            : ReaderSidePanelType.appearance;
      });
    } else {
      _showThemeCustomizeSheet();
    }
  }

  Future<void> _loadBook() async {
    final savedSettings =
        await StorageService.instance.getBookSettings(widget.book.hash);
    if (mounted) {
      setState(() => _settings = savedSettings);
      final effective = _computeEffectiveSettings(savedSettings);
      await _bridge.applyReaderSettings(effective);
    }
    final bytes = await StorageService.instance.getBookBytes(widget.book);
    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        setState(() {
          _engineError = 'Book file could not be found at path: ${widget.book.filePath ?? 'internal storage'}';
        });
      }
      return;
    }
    final targetCfi = widget.initialCfi ?? widget.book.cfi;
    final base64String = base64Encode(bytes);
    await _bridge.openBook(base64String, initialCfi: targetCfi);
    final annotations =
        await StorageService.instance.getAnnotations(widget.book.hash);
    final bookmarks =
        await StorageService.instance.getBookmarks(widget.book.hash);
    if (mounted) {
      setState(() {
        _annotations = annotations;
        _bookmarks = bookmarks;
      });
    }
    if (annotations.isNotEmpty) {
      await _bridge.loadAnnotations(annotations);
    }
    await _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    if (_currentLocation?.cfi == null) return;
    final bookmarked = await StorageService.instance.isBookmarked(
      widget.book.hash,
      _currentLocation!.cfi,
    );
    if (mounted && bookmarked != _isBookmarked) {
      setState(() => _isBookmarked = bookmarked);
    }
  }

  Future<void> _toggleBookmark() async {
    if (_currentLocation?.cfi == null) return;
    final cfi = _currentLocation!.cfi;
    final isCurrently =
        await StorageService.instance.isBookmarked(widget.book.hash, cfi);

    if (isCurrently) {
      await StorageService.instance.deleteBookmark(widget.book.hash, cfi);
      if (mounted) {
        setState(() => _isBookmarked = false);
        _reloadBookmarks();
      }
    } else {
      final bookmark = Bookmark(
        id: const Uuid().v4(),
        bookHash: widget.book.hash,
        cfi: cfi,
        chapterTitle: _getCurrentChapterTitle(),
        percentage: _currentLocation?.percentage ?? widget.book.percentage,
        pageNumber: _currentLocation?.currentLocation,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      await StorageService.instance.saveBookmark(bookmark);
      if (mounted) {
        setState(() => _isBookmarked = true);
        _reloadBookmarks();
      }
    }
  }

  String? _getCurrentChapterTitle() {
    if (_tableOfContents.isEmpty || _currentLocation?.cfi == null) return null;
    if (_currentLocation!.currentSection != null &&
        _currentLocation!.currentSection! < _tableOfContents.length) {
      return _tableOfContents[_currentLocation!.currentSection!].label;
    }
    return null;
  }

  String _formatHeaderTitle() {
    // 1. Try chapter or section title first
    final ch = _getCurrentChapterTitle() ?? _currentLocation?.sectionTitle;
    if (ch != null && ch.trim().isNotEmpty) {
      final clean = ch.trim();
      final chapterMatch = RegExp(
        r'^(chapter|ch\.|act|part|section|book|scene)\s*([0-9ivxlcdm]+|\w+)',
        caseSensitive: false,
      ).firstMatch(clean);
      if (chapterMatch != null) {
        final word = chapterMatch.group(1)!;
        final num = chapterMatch.group(2)!;
        return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()} $num';
      }
      if (clean.length <= 20) {
        return clean;
      }
      final stripped = clean.split(RegExp(r'[:\-—|]')).first.trim();
      if (stripped.isNotEmpty && stripped.length <= 20) {
        return stripped;
      }
      if (_currentLocation?.currentSection != null) {
        return 'Chapter ${_currentLocation!.currentSection! + 1}';
      }
      final words = clean.split(RegExp(r'\s+'));
      return words.take(2).join(' ');
    }

    // 2. Fallback to book title: strip subtitles and shorten to main part
    final rawTitle = widget.book.title.trim();
    final stripped = rawTitle.split(RegExp(r'[:\-—|(\[]')).first.trim();
    if (stripped.isNotEmpty && stripped.length <= 22) {
      return stripped;
    }
    if (_currentLocation?.currentSection != null) {
      return 'Chapter ${_currentLocation!.currentSection! + 1}';
    }
    final words = (stripped.isNotEmpty ? stripped : rawTitle).split(RegExp(r'\s+'));
    return words.take(2).join(' ');
  }

  void _toggleOrientationLock() {
    setState(() => _isOrientationLocked = !_isOrientationLocked);
    if (_isOrientationLocked) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } else {
      SystemChrome.setPreferredOrientations([]);
    }
  }

  Future<void> _showAnnotationEditSheet(String cfi) async {
    _hideControlsTimer?.cancel();
    final annotations =
        await StorageService.instance.getAnnotations(widget.book.hash);
    final index = annotations.indexWhere((a) => a.cfi == cfi);
    final annotation = index != -1
        ? annotations[index]
        : Annotation(
            id: const Uuid().v4(),
            bookHash: widget.book.hash,
            cfi: cfi,
            text: '',
            createdAt: DateTime.now().millisecondsSinceEpoch,
          );

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AnnotationEditSheet(
        annotation: annotation,
        bookTitle: widget.book.title,
        author: widget.book.author,
        coverUri: widget.book.coverUri,
        onUpdate: (updated) async {
          await StorageService.instance.saveAnnotation(updated);
          await _bridge.addAnnotation(updated.cfi, updated.color, note: updated.note);
          _reloadAnnotations();
        },
        onDelete: () async {
          await StorageService.instance
              .deleteAnnotation(widget.book.hash, cfi);
          await _bridge.deleteAnnotation(cfi);
          _reloadAnnotations();
        },
      ),
    ).then((_) => _resetInactivityTimer());
  }

  void _showLayoutSheet() {
    _hideControlsTimer?.cancel();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReaderLayoutSheet(
        settings: _settings,
        accentColor: AdwaitaColors.getThemeAccent(
          _settings.theme.id,
          _settings.isDarkMode,
        ),
        onSettingsChanged: (newSettings) {
          _applySettings(newSettings);
        },
      ),
    ).then((_) => _resetInactivityTimer());
  }

  Future<void> _showThemeCustomizeSheet() async {
    _hideControlsTimer?.cancel();
    if (_currentPageExcerpt == null || _currentPageExcerpt!.isEmpty) {
      final liveText = await _bridge.getCurrentPageText();
      if (liveText != null && liveText.isNotEmpty) {
        _currentPageExcerpt = liveText;
      }
    }
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReaderThemeCustomizeSheet(
        settings: _settings,
        sampleExcerpt: _currentPageExcerpt ??
            (_currentLocation?.sectionTitle != null
                ? 'Section: ${_currentLocation!.sectionTitle}\n\nHe sighed. \u201cBel, you have known your whole life that you cannot remain in Tyre.\u201d \u201cI am not a child,\u201d I hissed, heat rising in my cheeks...'
                : null),
        accentColor: AdwaitaColors.getThemeAccent(
          _settings.theme.id,
          _settings.isDarkMode,
        ),
        onSettingsChanged: (newSettings) {
          _applySettings(newSettings);
        },
      ),
    ).then((_) => _resetInactivityTimer());
  }

  Future<void> _showTOCSheet() async {
    _hideControlsTimer?.cancel();
    final bookmarks =
        await StorageService.instance.getBookmarks(widget.book.hash);
    if (!mounted) return;

    final themeAccent = AdwaitaColors.getThemeAccent(
      _settings.theme.id,
      _settings.isDarkMode,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReaderTOCSheet(
        book: widget.book,
        toc: _tableOfContents,
        bookmarks: bookmarks,
        currentLocation: _currentLocation,
        accentColor: themeAccent,
        pageNumberSource: _settings.pageNumberSource,
        onPageNumberSourceChanged: (source) {
          _applySettings(_settings.copyWith(pageNumberSource: source));
        },
        onChapterSelected: (href) => _navigateToHref(href),
        onDeleteBookmark: (b) async {
          await StorageService.instance.deleteBookmark(widget.book.hash, b.cfi);
          _checkBookmarkStatus();
        },
      ),
    ).then((_) => _resetInactivityTimer());
  }

  void _showReaderMenuSheet() {
    _hideControlsTimer?.cancel();
    final themeAccent = AdwaitaColors.getThemeAccent(
      _settings.theme.id,
      _settings.isDarkMode,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            return FloatingReaderMenu(
              brightness: _brightness,
              onBrightnessChanged: (val) {
                setSheetState(() {});
                setState(() => _brightness = val);
              },
              currentFontSize: _settings.fontSize,
              accentColor: themeAccent,
              onFontSizeChanged: (newSize) {
                setSheetState(() {});
                _applySettings(_settings.copyWith(fontSize: newSize));
              },
              isStayAwake: _settings.stayAwake,
              onToggleStayAwake: () {
                setSheetState(() {});
                _toggleStayAwake();
              },
              progressPercentage: (_currentLocation?.percentage ?? widget.book.percentage),
              progressLabel: _currentLocation != null
                  ? (_currentLocation!.totalLocations != null &&
                          _currentLocation!.totalLocations! > 0
                      ? 'Page ${_currentLocation!.currentLocation ?? 1} of ${_currentLocation!.totalLocations}  •  ${_currentLocation!.percentage.round()}%'
                      : '${_currentLocation!.percentage.round()}%')
                  : '${widget.book.percentage.round()}%',
              onScrubPercentage: (val) {
                _bridge.goToPercentage(val);
              },
              onPrevPage: () {
                _bridge.goPrev();
              },
              onNextPage: () {
                _bridge.goNext();
              },
              onClose: () {
                Navigator.of(ctx).pop();
              },
              onOpenTOC: () {
                Navigator.of(ctx).pop();
                _openTOC();
              },
              onOpenSearch: () {
                Navigator.of(ctx).pop();
                _openSearch();
              },
              onStartTTS: () {
                Navigator.of(ctx).pop();
                _startTts();
              },
              onOpenLayout: () {
                Navigator.of(ctx).pop();
                _showLayoutSheet();
              },
              onOpenThemeCustomize: () {
                Navigator.of(ctx).pop();
                _openAppearance();
              },
              onOpenAppearance: () {
                Navigator.of(ctx).pop();
                _openAppearance();
              },
              isOrientationLocked: _isOrientationLocked,
              onToggleOrientation: () {
                setSheetState(() {});
                _toggleOrientationLock();
              },
              progressDisplayType: _settings.progressDisplayType,
              onProgressDisplayTypeChanged: (type) {
                setSheetState(() {});
                setState(() => _settings = _settings.copyWith(progressDisplayType: type));
                StorageService.instance.saveBookSettings(widget.book.hash, _settings);
              },
              progressDisplayLocation: _settings.progressDisplayLocation,
              onProgressDisplayLocationChanged: (loc) {
                setSheetState(() {});
                setState(() => _settings = _settings.copyWith(progressDisplayLocation: loc));
                StorageService.instance.saveBookSettings(widget.book.hash, _settings);
              },
              currentTheme: _settings.theme,
              isDarkMode: _settings.isDarkMode,
              onThemeChanged: (newTheme, isDark) {
                setSheetState(() {});
                _applySettings(_settings.copyWith(
                  theme: newTheme,
                  isDarkMode: isDark,
                ));
              },
              currentFontFamily: _settings.fontFamily,
              onFontFamilyChanged: (fam) {
                setSheetState(() {});
                _applySettings(_settings.copyWith(fontFamily: fam));
              },
              overridePublisherFont: _settings.overridePublisherFont,
              onOverridePublisherFontChanged: (val) {
                setSheetState(() {});
                _applySettings(_settings.copyWith(overridePublisherFont: val));
              },
              fontWeight: _settings.fontWeight,
              onFontWeightChanged: (w) {
                setSheetState(() {});
                _applySettings(_settings.copyWith(fontWeight: w));
              },
              lineHeight: _settings.lineHeight,
              onLineHeightChanged: (lh) {
                setSheetState(() {});
                _applySettings(_settings.copyWith(lineHeight: lh));
              },
              fullJustification: _settings.fullJustification,
              onFullJustificationChanged: (just) {
                setSheetState(() {});
                _applySettings(_settings.copyWith(fullJustification: just));
              },
              hyphenation: _settings.hyphenation,
              onHyphenationChanged: (hyph) {
                setSheetState(() {});
                _applySettings(_settings.copyWith(hyphenation: hyph));
              },
              pageFlipping: _settings.pageFlipping,
              onPageFlippingChanged: (flip) {
                setSheetState(() {});
                _applySettings(_settings.copyWith(pageFlipping: flip));
              },
              showPageSlider: _settings.showPageSlider,
              onShowPageSliderChanged: (val) {
                setSheetState(() {});
                setState(() => _settings = _settings.copyWith(showPageSlider: val));
                StorageService.instance.saveBookSettings(widget.book.hash, _settings);
              },
              quickActionsBar: _settings.quickActionsBar,
              onQuickActionsBarChanged: (val) {
                setSheetState(() {});
                setState(() => _settings = _settings.copyWith(quickActionsBar: val));
                StorageService.instance.saveBookSettings(widget.book.hash, _settings);
              },
            );
          },
        ),
      ),
    ).then((_) => _resetInactivityTimer());
  }

  void _performSearch(String query, bool matchCase) {
    _searchSectionsNotifier.value = [];
    _allSearchMatches.clear();
    _totalMatchesNotifier.value = 0;
    _currentSearchMatchIndex = -1;
    _currentSearchQuery = query;
    _matchCase = matchCase;
    _isSearchingNotifier.value = true;
    _bridge.searchBook(query, matchCase: matchCase);
  }

  void _clearSearch() {
    _searchSectionsNotifier.value = [];
    _allSearchMatches.clear();
    _totalMatchesNotifier.value = 0;
    _currentSearchMatchIndex = -1;
    _currentSearchQuery = '';
    _isSearchingNotifier.value = false;
    _bridge.clearSearch();
  }

  void _exitSearch() {
    _clearSearch();
    setState(() {
      _isSearchActive = false;
      _showControls = true;
    });
    _resetInactivityTimer();
  }

  void _onSelectSearchMatch(SearchResultItem match, int globalIndex) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    setState(() {
      _currentSearchMatchIndex = globalIndex;
      _isSearchActive = true;
      _showControls = false;
    });
    _bridge.goToHref(match.cfi);
  }

  void _goToPrevSearchMatch() {
    if (_allSearchMatches.isEmpty) return;
    int newIdx = _currentSearchMatchIndex - 1;
    if (newIdx < 0) newIdx = _allSearchMatches.length - 1;
    setState(() => _currentSearchMatchIndex = newIdx);
    _bridge.goToHref(_allSearchMatches[newIdx].cfi);
  }

  void _goToNextSearchMatch() {
    if (_allSearchMatches.isEmpty) return;
    int newIdx = _currentSearchMatchIndex + 1;
    if (newIdx >= _allSearchMatches.length) newIdx = 0;
    setState(() => _currentSearchMatchIndex = newIdx);
    _bridge.goToHref(_allSearchMatches[newIdx].cfi);
  }

  void _showSearchSheet() {
    _hideControlsTimer?.cancel();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReaderSearchSheet(
        initialQuery: _currentSearchQuery,
        initialMatchCase: _matchCase,
        sectionsNotifier: _searchSectionsNotifier,
        isSearchingNotifier: _isSearchingNotifier,
        totalMatchesNotifier: _totalMatchesNotifier,
        onSearch: _performSearch,
        onClear: _clearSearch,
        onSelectMatch: _onSelectSearchMatch,
      ),
    ).then((_) => _resetInactivityTimer());
  }

  Widget _buildFloatingSearchBar(FoliateThemeColors colors) {
    final hasMatches = _allSearchMatches.isNotEmpty;
    final matchLabel = hasMatches
        ? 'Match ${_currentSearchMatchIndex + 1} of ${_allSearchMatches.length}'
        : (_isSearchingNotifier.value ? 'Searching...' : 'No matches');

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(24),
      color: colors.headerBar.withValues(alpha: 0.96),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            // Close search
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              tooltip: 'Exit search',
              onPressed: _exitSearch,
            ),
            const SizedBox(width: 4),

            // Match count label
            Expanded(
              child: Text(
                matchLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Previous match
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 22),
              tooltip: 'Previous match',
              onPressed: hasMatches ? _goToPrevSearchMatch : null,
            ),

            // Next match
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 22),
              tooltip: 'Next match',
              onPressed: hasMatches ? _goToNextSearchMatch : null,
            ),

            // Open full results list
            IconButton(
              icon: const Icon(Icons.list_rounded, size: 20),
              tooltip: 'All results',
              onPressed: _showSearchSheet,
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final themeAccent = AdwaitaColors.getThemeAccent(
      _settings.theme.id,
      _settings.isDarkMode,
    );
    final readerBg = AdwaitaColors.getReaderBgColor(
      _settings.theme.id,
      _settings.isDarkMode,
    );
    final readerFg = AdwaitaColors.getReaderFgColor(
      _settings.theme.id,
      _settings.isDarkMode,
    );

    final isWide = MediaQuery.of(context).size.width >= 850;
    final showSidePanel = isWide && _activeSidePanel != ReaderSidePanelType.none;

    final readerStack = Stack(
      fit: StackFit.expand,
      children: [
        // Underlying Reader View: Native pure-Dart fallback on desktop or Foliate WebView
        Positioned.fill(
          child: _isFallbackMode
              ? _buildFallbackReaderBody(
                  readerBg,
                  readerFg,
                  themeAccent,
                  isWide: isWide,
                )
              : PageCurlOverlay(
                  enabled: true,
                  settings: _settings,
                  backgroundColor: readerBg,
                  textColor: readerFg,
                  onNextPage: () {
                    _resetInactivityTimer();
                    _goNext();
                  },
                  onPrevPage: () {
                    _resetInactivityTimer();
                    _goPrev();
                  },
                  onToggleHUD: () {
                    _toggleControls();
                  },
                  child: ReaderWebView(bridge: _bridge),
                ),
        ),

        // Desktop Open Sidebar Button when sidebar is collapsed
        if (isWide && !showSidePanel)
          Positioned(
            top: 12 + MediaQuery.of(context).padding.top,
            left: 16,
            child: IconButton(
              icon: Icon(
                Icons.menu_rounded,
                color: readerFg.withValues(alpha: 0.75),
                size: 22,
              ),
              tooltip: 'Sidebar (Ctrl+T)',
              onPressed: () {
                setState(() => _activeSidePanel = ReaderSidePanelType.toc);
              },
            ),
          ),

          // In-App Software Brightness Dimming Overlay
          if (_brightness < 1.0)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withValues(
                    alpha: ((1.0 - _brightness) * 0.85).clamp(0.0, 0.9),
                  ),
                ),
              ),
            ),

          // Top Center Chapter Title (Mobile only when controls are hidden)
          if (!isWide && !_showControls && !_isSearchActive)
            Positioned(
              top: 14 + MediaQuery.of(context).padding.top,
              left: 28,
              right: 28,
              child: Center(
                child: Text(
                  _formatHeaderTitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: readerFg.withValues(alpha: 0.65),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),

          // Minimal Reading Page Number (Mobile only when controls are hidden)
          if (!isWide && !_showControls && !_isSearchActive && !_isTtsActive)
            Positioned(
              bottom: 12 + MediaQuery.of(context).padding.bottom,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  _currentLocation?.currentLocation != null
                      ? '${_currentLocation!.currentLocation}'
                      : '${(_currentLocation?.percentage ?? widget.book.percentage).round()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: readerFg.withValues(alpha: 0.7),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),

          // Chapter / Book Progress Metric in Top Center (Mobile only when controls are visible)
          if (!isWide && _showControls && !_isSearchActive)
            ReaderProgressIndicator(
              location: _currentLocation,
              percentage: _currentLocation?.percentage ?? widget.book.percentage,
              displayType: _settings.progressDisplayType == ProgressDisplayType.pageNumber
                  ? ProgressDisplayType.pagesLeftInChapter
                  : _settings.progressDisplayType,
              displayLocation: ProgressDisplayLocation.topCenter,
              accentColor: themeAccent,
              onCycleDisplayType: () {
                final nextType = _settings.progressDisplayType.next();
                setState(() => _settings = _settings.copyWith(progressDisplayType: nextType));
                StorageService.instance.saveBookSettings(widget.book.hash, _settings);
              },
            ),

          // Floating In-Reader Search Stepper Bar (Active search match session)
          if (_isSearchActive)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: _buildFloatingSearchBar(colors),
            ),

          // Top Right Close Button (Mobile only)
          if (!isWide && _showControls && !_isSearchActive)
            ReaderCloseButton(
              onClose: () => Navigator.of(context).pop(),
              accentColor: themeAccent,
            ),

          // Animated Silk Ribbon Bookmark (Mobile only when bookmarked & controls hidden)
          if (!isWide && !_showControls && _isBookmarked)
            SilkRibbonBookmark(
              isBookmarked: _isBookmarked,
              onToggle: _toggleBookmark,
            ),

          // Bottom Center Page Metric (Mobile only when controls are visible)
          if (!isWide && _showControls && !_isSearchActive && !_isTtsActive)
            Positioned(
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              left: 64,
              right: 64,
              child: Center(
                child: Text(
                  _currentLocation != null &&
                          _currentLocation!.currentLocation != null &&
                          _currentLocation!.totalLocations != null &&
                          _currentLocation!.totalLocations! > 0
                      ? '${_currentLocation!.currentLocation} of ${_currentLocation!.totalLocations}'
                      : '${(_currentLocation?.percentage ?? widget.book.percentage).round()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: readerFg.withValues(alpha: 0.85),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),

          // Floating Bottom Page Scrubber Slider (Mobile only)
          if (!isWide && _showControls && !_isSearchActive && _settings.showPageSlider && !_isTtsActive)
            ReaderPageSliderBar(
              progressPercentage: (_currentLocation?.percentage ?? widget.book.percentage),
              location: _currentLocation,
              toc: _tableOfContents,
              accentColor: themeAccent,
              onScrubPercentage: (val) {
                _resetInactivityTimer();
                _bridge.goToPercentage(val);
              },
              onPrevPage: () {
                _resetInactivityTimer();
                _goPrev();
              },
              onNextPage: () {
                _resetInactivityTimer();
                _goNext();
              },
            ),

          // Floating Action Capsule (Mobile only)
          if (!isWide && _showControls && !_isSearchActive && _selectedText == null && !_isTtsActive)
            Positioned(
              bottom: 12 + MediaQuery.of(context).padding.bottom,
              right: 18,
              child: FloatingReaderCapsule(
                accentColor: themeAccent,
                onTap: _showReaderMenuSheet,
              ),
            ),

          // Desktop Foliate Bottom Reading Scrubber (Image 2 & 3)
          if (isWide)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSlide(
                offset: (_isHoveringBottom || _isScrubberPopoverOpen)
                    ? Offset.zero
                    : const Offset(0, 1.05),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: DesktopReadingScrubber(
                  location: _currentLocation,
                  percentage: _currentLocation?.percentage ?? widget.book.percentage,
                  toc: _tableOfContents,
                  accentColor: themeAccent,
                  readerFg: readerFg,
                  readerBg: readerBg,
                  isTtsActive: _isTtsActive,
                  onPrevPage: () {
                    _resetInactivityTimer();
                    _goPrev();
                  },
                  onNextPage: () {
                    _resetInactivityTimer();
                    _goNext();
                  },
                  onUndo: () {
                    _bridge.historyBack();
                  },
                  onRedo: () {
                    _bridge.historyForward();
                  },
                  onScrubPercentage: (val) {
                    _resetInactivityTimer();
                    if (_isFallbackMode) {
                      _fallbackScrubToPercentage(val);
                    } else {
                      _bridge.goToPercentage(val);
                    }
                  },
                  onToggleTts: _toggleTts,
                  onFirstSection: _navigateToFirstSection,
                  onPrevSection: () => _navigateSection(-1),
                  onNextSection: () => _navigateSection(1),
                  onLastSection: _navigateToLastSection,
                  onLocationSubmitted: (loc) {
                    if (_isFallbackMode) {
                      _onDesktopLocationSubmitted(loc);
                    } else {
                      _bridge.goToLocation(loc);
                    }
                  },
                  onPopoverVisibilityChanged: (isOpen) {
                    setState(() => _isScrubberPopoverOpen = isOpen);
                  },
                ),
              ),
            ),

          // Floating Audio Control Bar (TTS Narration)
          if (_isTtsActive)
            Positioned(
              bottom: 12 + MediaQuery.of(context).padding.bottom,
              left: 12,
              right: 12,
              child: TtsFloatingBar(
                state: _ttsService.state,
                currentIndex: _ttsService.currentIndex,
                totalParagraphs: _ttsService.totalParagraphs,
                speechRate: _ttsService.speechRate,
                chapterTitle: _currentLocation?.sectionTitle,
                accentColor: themeAccent,
                isDarkMode: _settings.isDarkMode,
                onPlayPause: () {
                  if (_ttsService.isPlaying) {
                    _ttsService.pause();
                  } else {
                    _ttsService.play();
                  }
                },
                onPrevious: () => _ttsService.previousParagraph(),
                onNext: () => _ttsService.nextParagraph(),
                onCycleSpeed: () => _ttsService.cycleSpeechRate(),
                onClose: _stopTts,
              ),
            ),

          // Contextual Selection Annotation Bar
          if (_selectedText != null)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: ReaderAnnotationBar(
                selectedText: _selectedText!,
                cfi: _selectedCfi,
                bookTitle: widget.book.title,
                author: widget.book.author,
                coverUri: widget.book.coverUri,
                onBeforeAction: () {
                  _bridge.clearSelection();
                  if (mounted) {
                    setState(() {
                      _selectedText = null;
                      _selectedCfi = null;
                    });
                  }
                },
                onSave: (cfi, color, note) async {
                  final annotation = Annotation(
                    id: const Uuid().v4(),
                    bookHash: widget.book.hash,
                    cfi: cfi,
                    text: _selectedText!,
                    note: note,
                    color: color,
                    createdAt: DateTime.now().millisecondsSinceEpoch,
                  );
                  await StorageService.instance.saveAnnotation(annotation);
                  await _bridge.addAnnotation(cfi, color, note: note);
                  await _bridge.clearSelection();
                  if (mounted) {
                    setState(() {
                      _selectedText = null;
                      _selectedCfi = null;
                    });
                    _reloadAnnotations();
                  }
                },
                onDismiss: () {
                  _bridge.clearSelection();
                  if (mounted) {
                    setState(() {
                      _selectedText = null;
                      _selectedCfi = null;
                    });
                  }
                },
              ),
            ),

          // Engine Error View
          if (_engineError != null)
            _buildEngineErrorView(colors, readerBg, readerFg, themeAccent),

          // Full-screen Loading Overlay
          if (!_isReady && _engineError == null)
            Container(
              color: readerBg,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        themeAccent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Opening book...',
                      style: TextStyle(
                        fontSize: 13,
                        color: readerFg.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );

    final body = showSidePanel
        ? Row(
            children: [
              ReaderSidebarPanel(
                panelType: _activeSidePanel,
                book: widget.book,
                toc: _tableOfContents,
                currentLocation: _currentLocation,
                onChapterSelected: (href) {
                  _resetInactivityTimer();
                  _navigateToHref(href);
                },
                searchSectionsNotifier: _searchSectionsNotifier,
                isSearchingNotifier: _isSearchingNotifier,
                totalMatchesNotifier: _totalMatchesNotifier,
                onSearch: _performSearch,
                onClearSearch: _clearSearch,
                onSelectSearchMatch: _onSelectSearchMatch,
                settings: _settings,
                onSettingsChanged: _applySettings,
                bookmarks: _bookmarks,
                onSelectBookmark: (b) {
                  _resetInactivityTimer();
                  _bridge.goToHref(b.cfi);
                },
                onDeleteBookmark: (b) async {
                  await StorageService.instance.deleteBookmark(widget.book.hash, b.cfi);
                  _reloadBookmarks();
                  _checkBookmarkStatus();
                },
                annotations: _annotations,
                onSelectAnnotation: (ann) {
                  _resetInactivityTimer();
                  _bridge.goToHref(ann.cfi);
                },
                onDeleteAnnotation: (ann) async {
                  await StorageService.instance.deleteAnnotation(widget.book.hash, ann.cfi);
                  await _bridge.deleteAnnotation(ann.cfi);
                  _reloadAnnotations();
                },
                onClose: () {
                  setState(() => _activeSidePanel = ReaderSidePanelType.none);
                },
                onBackToLibrary: () => Navigator.of(context).pop(),
                onPanelTypeChanged: (type) {
                  setState(() => _activeSidePanel = type);
                },
              ),
              Expanded(child: readerStack),
            ],
          )
        : readerStack;

    final interactiveBody = MouseRegion(
      onHover: (event) {
        if (!isWide) return;
        final screenHeight = MediaQuery.of(context).size.height;
        final isNearBottom = (screenHeight - event.position.dy) <= 75;
        if (isNearBottom != _isHoveringBottom) {
          setState(() => _isHoveringBottom = isNearBottom);
        }
      },
      onExit: (_) {
        if (_isHoveringBottom) {
          setState(() => _isHoveringBottom = false);
        }
      },
      child: body,
    );

    return Shortcuts(
      shortcuts: FoliateShortcuts.readerShortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          PageForwardIntent: CallbackAction<PageForwardIntent>(
            onInvoke: (_) {
              _resetInactivityTimer();
              _goNext();
              return null;
            },
          ),
          PageBackwardIntent: CallbackAction<PageBackwardIntent>(
            onInvoke: (_) {
              _resetInactivityTimer();
              _goPrev();
              return null;
            },
          ),
          OpenSearchIntent: CallbackAction<OpenSearchIntent>(
            onInvoke: (_) {
              _openSearch();
              return null;
            },
          ),
          OpenTOCIntent: CallbackAction<OpenTOCIntent>(
            onInvoke: (_) {
              _openTOC();
              return null;
            },
          ),
          ToggleBookmarkIntent: CallbackAction<ToggleBookmarkIntent>(
            onInvoke: (_) {
              _toggleBookmark();
              return null;
            },
          ),
          OpenAppearanceIntent: CallbackAction<OpenAppearanceIntent>(
            onInvoke: (_) {
              _openAppearance();
              return null;
            },
          ),
          IncreaseFontSizeIntent: CallbackAction<IncreaseFontSizeIntent>(
            onInvoke: (_) {
              final nextSize = (_settings.fontSize + 1.0).clamp(10.0, 48.0);
              _applySettings(_settings.copyWith(fontSize: nextSize));
              return null;
            },
          ),
          DecreaseFontSizeIntent: CallbackAction<DecreaseFontSizeIntent>(
            onInvoke: (_) {
              final nextSize = (_settings.fontSize - 1.0).clamp(10.0, 48.0);
              _applySettings(_settings.copyWith(fontSize: nextSize));
              return null;
            },
          ),
          DismissOrEscapeIntent: CallbackAction<DismissOrEscapeIntent>(
            onInvoke: (_) {
              if (_activeSidePanel != ReaderSidePanelType.none) {
                setState(() => _activeSidePanel = ReaderSidePanelType.none);
              } else if (_isSearchActive) {
                _exitSearch();
              } else if (_showControls) {
                setState(() => _showControls = false);
              } else {
                Navigator.of(context).pop();
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: readerBg,
            body: interactiveBody,
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackReaderBody(
    Color readerBg,
    Color readerFg,
    Color themeAccent, {
    bool isWide = false,
  }) {
    if (_fallbackChapters.isEmpty && _desktopSpreads.isEmpty) {
      return Center(
        child: Text(
          'No readable text found in this book.',
          style: TextStyle(color: readerFg),
        ),
      );
    }

    final fontFamily = _settings.fontFamily;
    final fontSize = _settings.fontSize;
    final lineHeight = _settings.lineHeight;

    TextAlign align;
    switch (_settings.textAlign.toLowerCase()) {
      case 'left':
        align = TextAlign.left;
        break;
      case 'center':
        align = TextAlign.center;
        break;
      case 'right':
        align = TextAlign.right;
        break;
      case 'justify':
      default:
        align = TextAlign.justify;
        break;
    }

    final effectiveFontFamily = (fontFamily.isEmpty || fontFamily.toLowerCase() == 'serif')
        ? 'Georgia'
        : fontFamily;
    const fontFallbacks = [
      'Georgia',
      'Garamond',
      'Palatino Linotype',
      'Palatino',
      'Liberation Serif',
      'Times New Roman',
      'serif',
    ];

    // Desktop Two-Page Spread Horizontal Paged Reader (Foliate Linux UX)
    if (isWide && _desktopSpreads.isNotEmpty) {
      return Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.pageUp) {
              _desktopPrevSpread();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.logicalKey == LogicalKeyboardKey.pageDown ||
                event.logicalKey == LogicalKeyboardKey.space) {
              _desktopNextSpread();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Container(
          color: readerBg,
          child: Stack(
            children: [
              PageView.builder(
                controller: _desktopPageController,
                itemCount: _desktopSpreads.length,
                onPageChanged: _onSpreadChanged,
                physics: const ClampingScrollPhysics(),
                itemBuilder: (context, index) {
                  final spread = _desktopSpreads[index];
                  return _buildDesktopSpreadView(
                    spread: spread,
                    effectiveFontFamily: effectiveFontFamily,
                    fontFallbacks: fontFallbacks,
                    fontSize: fontSize,
                    lineHeight: lineHeight,
                    align: align,
                    readerFg: readerFg,
                    readerBg: readerBg,
                  );
                },
              ),
              // Horizontal click navigation zones (margins)
              Positioned.fill(
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _desktopPrevSpread,
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _toggleControls,
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _desktopNextSpread,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mobile Single-Page Horizontal Swipeable Reader with Vertical Space
    if (_mobilePages.isNotEmpty) {
      final edgeZoneWidth = (MediaQuery.of(context).size.width * 0.22).clamp(50.0, 96.0);
      return Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.pageUp) {
              _mobilePrevPage();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.logicalKey == LogicalKeyboardKey.pageDown ||
                event.logicalKey == LogicalKeyboardKey.space) {
              _mobileNextPage();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Container(
          color: readerBg,
          child: Stack(
            children: [
              PageView.builder(
                controller: _mobilePageController,
                itemCount: _mobilePages.length,
                onPageChanged: _onMobilePageChanged,
                physics: const ClampingScrollPhysics(),
                itemBuilder: (context, index) {
                  final page = _mobilePages[index];
                  return _buildMobilePageView(
                    page: page,
                    effectiveFontFamily: effectiveFontFamily,
                    fontFallbacks: fontFallbacks,
                    fontSize: fontSize,
                    lineHeight: lineHeight,
                    align: align,
                    readerFg: readerFg,
                    readerBg: readerBg,
                  );
                },
              ),
              // Mobile click navigation zones: left -> prev, center -> HUD toggle, right -> next
              Positioned.fill(
                child: Row(
                  children: [
                    SizedBox(
                      width: edgeZoneWidth,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _mobilePrevPage,
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _toggleControls,
                      ),
                    ),
                    SizedBox(
                      width: edgeZoneWidth,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _mobileNextPage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mobile fallback column layout
    final currentChapter = _fallbackChapters.isNotEmpty
        ? _fallbackChapters[_fallbackChapterIndex.clamp(0, _fallbackChapters.length - 1)]
        : null;

    final horizontalPadding = (_settings.margin * 300.0).clamp(20.0, 120.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleControls,
      child: Container(
        color: readerBg,
        child: SafeArea(
          child: Column(
            children: [
              if (currentChapter != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          currentChapter.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: readerFg.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _fallbackScrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 24.0,
                  ),
                  child: SelectionArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (currentChapter != null) ...[
                          Text(
                            currentChapter.title,
                            style: TextStyle(
                              fontFamily: effectiveFontFamily,
                              fontFamilyFallback: fontFallbacks,
                              fontSize: fontSize * 1.35,
                              fontWeight: FontWeight.bold,
                              color: readerFg,
                              height: 1.3,
                            ),
                            textAlign: align,
                          ),
                          const SizedBox(height: 24),
                          ...currentChapter.paragraphs.map(
                            (paragraph) => Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text(
                                paragraph,
                                textAlign: align,
                                style: TextStyle(
                                  fontFamily: effectiveFontFamily,
                                  fontFamilyFallback: fontFallbacks,
                                  fontSize: fontSize,
                                  height: lineHeight,
                                  color: readerFg,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 36),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: _fallbackChapterIndex > 0
                                  ? _fallbackPrevChapter
                                  : null,
                              icon: const Icon(Icons.arrow_back_rounded, size: 18),
                              label: const Text('Previous Chapter'),
                              style: TextButton.styleFrom(
                                foregroundColor: themeAccent,
                                disabledForegroundColor:
                                    readerFg.withValues(alpha: 0.3),
                              ),
                            ),
                            Text(
                              '${_fallbackChapterIndex + 1} of ${_fallbackChapters.length}',
                              style: TextStyle(
                                fontSize: 12,
                                color: readerFg.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _fallbackChapterIndex <
                                      _fallbackChapters.length - 1
                                  ? _fallbackNextChapter
                                  : null,
                              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                              label: const Text('Next Chapter'),
                              style: TextButton.styleFrom(
                                foregroundColor: themeAccent,
                                disabledForegroundColor:
                                    readerFg.withValues(alpha: 0.3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopSpreadView({
    required TwoPageSpread spread,
    required String effectiveFontFamily,
    required List<String> fontFallbacks,
    required double fontSize,
    required double lineHeight,
    required TextAlign align,
    required Color readerFg,
    required Color readerBg,
  }) {
    return Container(
      color: readerBg,
      child: Center(
        child: SelectionArea(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1350),
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Page
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (spread.isChapterStart && spread.chapterTitle != null && spread.chapterTitle!.isNotEmpty) ...[
                        Text(
                          spread.chapterTitle!,
                          style: TextStyle(
                            fontFamily: effectiveFontFamily,
                            fontFamilyFallback: fontFallbacks,
                            fontSize: fontSize * 1.35,
                            fontWeight: FontWeight.bold,
                            color: readerFg,
                            height: 1.3,
                          ),
                          textAlign: align == TextAlign.justify ? TextAlign.left : align,
                        ),
                        const SizedBox(height: 24),
                      ] else ...[
                        const SizedBox(height: 16),
                      ],
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: spread.leftParagraphs.map(
                              (p) => Padding(
                                padding: const EdgeInsets.only(bottom: 14.0),
                                child: Text(
                                  p,
                                  textAlign: align,
                                  style: TextStyle(
                                    fontFamily: effectiveFontFamily,
                                    fontFamilyFallback: fontFallbacks,
                                    fontSize: fontSize,
                                    height: lineHeight,
                                    color: readerFg,
                                  ),
                                ),
                              ),
                            ).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Loc. ${spread.leftLoc} of ${spread.totalLocs}',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: effectiveFontFamily,
                            fontFamilyFallback: fontFallbacks,
                            color: readerFg.withValues(alpha: 0.5),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Center Gutter (central spine of the book)
                const SizedBox(width: 56),

                // Right Page
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: spread.rightParagraphs.map(
                              (p) => Padding(
                                padding: const EdgeInsets.only(bottom: 14.0),
                                child: Text(
                                  p,
                                  textAlign: align,
                                  style: TextStyle(
                                    fontFamily: effectiveFontFamily,
                                    fontFamilyFallback: fontFallbacks,
                                    fontSize: fontSize,
                                    height: lineHeight,
                                    color: readerFg,
                                  ),
                                ),
                              ),
                            ).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Loc. ${spread.rightLoc} of ${spread.totalLocs}',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: effectiveFontFamily,
                            fontFamilyFallback: fontFallbacks,
                            color: readerFg.withValues(alpha: 0.5),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobilePageView({
    required MobilePage page,
    required String effectiveFontFamily,
    required List<String> fontFallbacks,
    required double fontSize,
    required double lineHeight,
    required TextAlign align,
    required Color readerFg,
    required Color readerBg,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final topSafe = mediaQuery.padding.top;
    final bottomSafe = mediaQuery.padding.bottom;

    // Ample vertical space for separate pages during swipe animation:
    // Ensures clean breathing room above and below the page content,
    // keeping it clear of the top header title and bottom indicators.
    final topVerticalSpace = topSafe + 56.0;
    final bottomVerticalSpace = bottomSafe + 60.0;
    final horizontalPadding = (_settings.margin * 240.0).clamp(24.0, 56.0);

    return Container(
      color: readerBg,
      padding: EdgeInsets.only(
        top: topVerticalSpace,
        bottom: bottomVerticalSpace,
        left: horizontalPadding,
        right: horizontalPadding,
      ),
      child: Center(
        child: SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (page.isChapterStart && page.chapterTitle != null && page.chapterTitle!.isNotEmpty) ...[
                Text(
                  page.chapterTitle!,
                  style: TextStyle(
                    fontFamily: effectiveFontFamily,
                    fontFamilyFallback: fontFallbacks,
                    fontSize: fontSize * 1.3,
                    fontWeight: FontWeight.bold,
                    color: readerFg,
                    height: 1.3,
                  ),
                  textAlign: align == TextAlign.justify ? TextAlign.left : align,
                ),
                const SizedBox(height: 20),
              ] else ...[
                const SizedBox(height: 8),
              ],
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: page.paragraphs.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: Text(
                          p,
                          textAlign: align,
                          style: TextStyle(
                            fontFamily: effectiveFontFamily,
                            fontFamilyFallback: fontFallbacks,
                            fontSize: fontSize,
                            height: lineHeight,
                            color: readerFg,
                          ),
                        ),
                      ),
                    ).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.center,
                child: Text(
                  'Loc. ${page.loc} of ${page.totalLocs}',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: effectiveFontFamily,
                    fontFamilyFallback: fontFallbacks,
                    color: readerFg.withValues(alpha: 0.5),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEngineErrorView(
    FoliateThemeColors colors,
    Color readerBg,
    Color readerFg,
    Color themeAccent,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: readerBg,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Card(
              color: scheme.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: scheme.error.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        color: scheme.error,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Unable to Open Book',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _engineError ?? 'Unknown reader error.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: () {
                            setState(() {
                              _engineError = null;
                              _isReady = false;
                            });
                            _startWatchdogTimer();
                            _loadBook();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
