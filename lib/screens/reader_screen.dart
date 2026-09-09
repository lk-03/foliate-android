import 'dart:async';
import 'dart:convert';
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

  @override
  void initState() {
    super.initState();
    _setupBridgeListeners();
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
    if (percentage >= 0.995 && !_hasShownCompletionCeremony) {
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
    }
  }

  @override
  void dispose() {
    _readingHeartbeatTimer?.cancel();
    _flushReadingTime();
    _hideControlsTimer?.cancel();
    _searchSectionsNotifier.dispose();
    _isSearchingNotifier.dispose();
    _totalMatchesNotifier.dispose();
    SystemChrome.setPreferredOrientations([]);
    super.dispose();
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

  void _setupBridgeListeners() {
    _bridge.onReady = () {
      if (mounted) {
        setState(() => _isReady = true);
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

    _bridge.onToggleControls = () {
      if (mounted) _toggleControls();
    };

    _bridge.onError = (error) {
      if (mounted) {
        _isSearchingNotifier.value = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reader error: $error')),
        );
      }
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
    final effectiveSide = (screenWidth * base.margin).clamp(16.0, 60.0);

    return base.copyWith(
      paddingTop: effectiveTop,
      paddingBottom: effectiveBottom,
      marginSide: effectiveSide,
    );
  }

  void _applySettings(ReaderSettings newSettings) {
    setState(() => _settings = newSettings);
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

  Future<void> _loadBook() async {
    final savedSettings =
        await StorageService.instance.getBookSettings(widget.book.hash);
    if (mounted) {
      setState(() => _settings = savedSettings);
      final effective = _computeEffectiveSettings(savedSettings);
      await _bridge.applyReaderSettings(effective);
    }
    final bytes = await StorageService.instance.getBookBytes(widget.book);
    final targetCfi = widget.initialCfi ?? widget.book.cfi;
    if (bytes != null && bytes.isNotEmpty) {
      final base64String = base64Encode(bytes);
      await _bridge.openBook(base64String, initialCfi: targetCfi);
    } else if (targetCfi != null) {
      await _bridge.goToHref(targetCfi);
    }
    final annotations =
        await StorageService.instance.getAnnotations(widget.book.hash);
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
      if (mounted) setState(() => _isBookmarked = false);
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
      if (mounted) setState(() => _isBookmarked = true);
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
        onUpdate: (updated) async {
          await StorageService.instance.saveAnnotation(updated);
          await _bridge.addAnnotation(updated.cfi, updated.color);
        },
        onDelete: () async {
          await StorageService.instance
              .deleteAnnotation(widget.book.hash, cfi);
          await _bridge.deleteAnnotation(cfi);
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReaderTOCSheet(
        toc: _tableOfContents,
        bookmarks: bookmarks,
        onChapterSelected: (href) => _bridge.goToHref(href),
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
                _showTOCSheet();
              },
              onOpenSearch: () {
                Navigator.of(ctx).pop();
                _showSearchSheet();
              },
              onOpenLayout: () {
                Navigator.of(ctx).pop();
                _showLayoutSheet();
              },
              onOpenThemeCustomize: () {
                Navigator.of(ctx).pop();
                _showThemeCustomizeSheet();
              },
              onOpenAppearance: () {
                Navigator.of(ctx).pop();
                _showLayoutSheet();
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
    Navigator.of(context).pop();
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

    return Scaffold(
      backgroundColor: AdwaitaColors.darkWindowBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Underlying Foliate WebView with Page-Turn Animation & Gesture Overlay
          Positioned.fill(
            child: PageCurlOverlay(
              settings: _settings,
              backgroundColor: AdwaitaColors.getReaderBgColor(
                _settings.theme.id,
                _settings.isDarkMode,
              ),
              textColor: AdwaitaColors.getReaderFgColor(
                _settings.theme.id,
                _settings.isDarkMode,
              ),
              onNextPage: () {
                _resetInactivityTimer();
                _bridge.goNext();
              },
              onPrevPage: () {
                _resetInactivityTimer();
                _bridge.goPrev();
              },
              onToggleHUD: () {
                _toggleControls();
              },
              child: ReaderWebView(bridge: _bridge),
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

          // Top Center Chapter Title (when controls are hidden - Reference Image 1)
          if (!_showControls && !_isSearchActive)
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
                    color: colors.textSecondary.withValues(alpha: 0.6),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),

          // Minimal Reading Page Number (Bottom Center when controls are hidden - Reference Image 1)
          if (!_showControls && !_isSearchActive)
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
                    color: colors.textSecondary.withValues(alpha: 0.65),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),

          // Chapter / Book Progress Metric in Top Center (when controls are visible - Reference Image 2)
          if (_showControls && !_isSearchActive)
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

          // Top Right Close Button (X mark - Reference Image 2)
          if (_showControls && !_isSearchActive)
            ReaderCloseButton(
              onClose: () => Navigator.of(context).pop(),
              accentColor: themeAccent,
            ),

          // Animated Silk Ribbon Bookmark (Top Right when bookmarked & controls hidden)
          if (!_showControls && _isBookmarked)
            SilkRibbonBookmark(
              isBookmarked: _isBookmarked,
              onToggle: _toggleBookmark,
            ),

          // Bottom Center Page Metric (when controls are visible - Reference Image 2: "74 of 709")
          if (_showControls && !_isSearchActive)
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
                    color: colors.textSecondary.withValues(alpha: 0.8),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),

          // Floating Bottom Page Scrubber Slider (when enabled in settings)
          if (_showControls && !_isSearchActive && _settings.showPageSlider)
            ReaderPageSliderBar(
              progressPercentage: (_currentLocation?.percentage ?? widget.book.percentage),
              location: _currentLocation,
              accentColor: themeAccent,
              onScrubPercentage: (val) {
                _resetInactivityTimer();
                _bridge.goToPercentage(val);
              },
              onPrevPage: () {
                _resetInactivityTimer();
                _bridge.goPrev();
              },
              onNextPage: () {
                _resetInactivityTimer();
                _bridge.goNext();
              },
            ),

          // Floating Action Capsule (Bottom Right)
          if (_showControls && !_isSearchActive && _selectedText == null)
            Positioned(
              bottom: 12 + MediaQuery.of(context).padding.bottom,
              right: 18,
              child: FloatingReaderCapsule(
                accentColor: themeAccent,
                onTap: _showReaderMenuSheet,
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
                  await _bridge.addAnnotation(cfi, color);
                  if (mounted) {
                    setState(() {
                      _selectedText = null;
                      _selectedCfi = null;
                    });
                  }
                },
                onDismiss: () => setState(() {
                  _selectedText = null;
                  _selectedCfi = null;
                }),
              ),
            ),

          // Full-screen Loading Overlay
          if (!_isReady)
            Container(
              color: AdwaitaColors.darkWindowBg,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AdwaitaColors.foliateGreen,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Opening book...',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
