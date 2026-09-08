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

  const ReaderScreen({
    super.key,
    required this.book,
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

  @override
  void initState() {
    super.initState();
    _setupBridgeListeners();
    _resetInactivityTimer();
    _loadInitialSettings();
  }

  Future<void> _loadInitialSettings() async {
    final s = await StorageService.instance.getBookSettings(widget.book.hash);
    if (mounted) {
      setState(() => _settings = s);
    }
  }

  @override
  void dispose() {
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
        setState(() => _currentLocation = location);
        _checkBookmarkStatus();
        // Persist reading progress to local storage
        StorageService.instance.updateBookProgress(
          widget.book.hash,
          percentage: location.percentage,
          cfi: location.cfi,
        );
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

  Future<void> _loadBook() async {
    final savedSettings =
        await StorageService.instance.getBookSettings(widget.book.hash);
    if (mounted) {
      setState(() => _settings = savedSettings);
      await _bridge.applyReaderSettings(_settings);
    }
    final bytes = await StorageService.instance.getBookBytes(widget.book);
    if (bytes != null && bytes.isNotEmpty) {
      final base64String = base64Encode(bytes);
      await _bridge.openBook(base64String, initialCfi: widget.book.cfi);
    } else if (widget.book.cfi != null) {
      await _bridge.goToHref(widget.book.cfi!);
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

  void _showAppearanceSheet() {
    _hideControlsTimer?.cancel();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReaderAppearanceSheet(
        settings: _settings,
        onSettingsChanged: (newSettings) {
          setState(() => _settings = newSettings);
          _bridge.applyReaderSettings(newSettings);
          StorageService.instance.saveBookSettings(widget.book.hash, newSettings);
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
              currentFontSize: _settings.fontSize,
              accentColor: themeAccent,
              onFontSizeChanged: (newSize) {
                setSheetState(() {});
                setState(() => _settings = _settings.copyWith(fontSize: newSize));
                _bridge.applyReaderSettings(_settings);
                StorageService.instance.saveBookSettings(widget.book.hash, _settings);
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
              onOpenAppearance: () {
                Navigator.of(ctx).pop();
                _showAppearanceSheet();
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
                setState(() => _settings = _settings.copyWith(
                  theme: newTheme,
                  isDarkMode: isDark,
                ));
                _bridge.applyReaderSettings(_settings);
                StorageService.instance.saveBookSettings(widget.book.hash, _settings);
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
          // Underlying Foliate WebView
          Positioned.fill(
            child: ReaderWebView(bridge: _bridge),
          ),

          // Tap Zones for Navigation and HUD (Left 28% Prev, Right 28% Next, Center 44% Toggle HUD)
          Positioned.fill(
            child: Row(
              children: [
                // Left 28% -> Previous Page
                Expanded(
                  flex: 28,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      _resetInactivityTimer();
                      _bridge.goPrev();
                    },
                  ),
                ),
                // Center 44% -> Toggle HUD
                Expanded(
                  flex: 44,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      _toggleControls();
                    },
                  ),
                ),
                // Right 28% -> Next Page
                Expanded(
                  flex: 28,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      _resetInactivityTimer();
                      _bridge.goNext();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Minimal Reading Page Number (Bottom Center when controls are hidden)
          if (!_showControls && !_isSearchActive)
            Positioned(
              bottom: 12 + MediaQuery.of(context).padding.bottom,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.headerBar.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.border.withValues(alpha: 0.5),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    _currentLocation != null &&
                            _currentLocation!.currentLocation != null &&
                            _currentLocation!.totalLocations != null &&
                            _currentLocation!.totalLocations! > 0
                        ? 'Page ${_currentLocation!.currentLocation} of ${_currentLocation!.totalLocations}'
                        : '${(_currentLocation?.percentage ?? widget.book.percentage).round()}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary.withValues(alpha: 0.8),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ),

          // Chapter / Book Progress Metric in Top Center (when controls are visible)
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

          // Top Left Close Button (X mark)
          if (_showControls && !_isSearchActive)
            ReaderCloseButton(
              onClose: () => Navigator.of(context).pop(),
              accentColor: themeAccent,
            ),

          // Animated Silk Ribbon Bookmark (Top Right)
          SilkRibbonBookmark(
            isBookmarked: _isBookmarked,
            onToggle: _toggleBookmark,
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

          // Three-Dot Floating Action Capsule (Bottom Right)
          if (_showControls && !_isSearchActive && _selectedText == null)
            Positioned(
              bottom: 16 + MediaQuery.of(context).padding.bottom,
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
