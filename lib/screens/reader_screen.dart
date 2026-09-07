import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
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

  void _showTOCSheet() {
    _hideControlsTimer?.cancel();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReaderTOCSheet(
        toc: _tableOfContents,
        onChapterSelected: (href) => _bridge.goToHref(href),
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

          // Subtle Blended Page Counter (x / n) when HUD is hidden
          Positioned(
            bottom: 12,
            right: 18,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: (!_showControls && _isReady) ? 0.55 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _currentLocation != null &&
                          _currentLocation!.totalLocations != null &&
                          _currentLocation!.totalLocations! > 0
                      ? '${_currentLocation!.currentLocation ?? 1} / ${_currentLocation!.totalLocations}'
                      : (_currentLocation != null
                          ? '${_currentLocation!.percentage.round()}%'
                          : '${widget.book.percentage.round()}%'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    fontFamily: 'Noto Serif',
                    color: ReaderThemeColors.forMode(
                      _settings.theme,
                      isDark: _settings.isDarkMode,
                    ).text,
                  ),
                ),
              ),
            ),
          ),

          // Floating In-Reader Search Stepper Bar (Active search match session)
          if (_isSearchActive)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: _buildFloatingSearchBar(colors),
            ),

          // Floating Translucent Back Button (Top Left)
          if (_showControls && !_isSearchActive)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.headerBar.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.border),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios_new_rounded, size: 13),
                        SizedBox(width: 6),
                        Text(
                          'Library',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Top Header Action Icons (Top Right)
          if (_showControls && !_isSearchActive)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.headerBar.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.search_rounded, size: 18),
                      tooltip: 'Search',
                      onPressed: _showSearchSheet,
                    ),
                    IconButton(
                      icon: const Icon(Icons.text_fields_rounded, size: 19),
                      tooltip: 'Appearance',
                      onPressed: _showAppearanceSheet,
                    ),
                    IconButton(
                      icon: const Icon(Icons.list_rounded, size: 20),
                      tooltip: 'Contents',
                      onPressed: _showTOCSheet,
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Controls HUD Bar
          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.headerBar.withValues(alpha: 0.95),
                  border: Border(top: BorderSide(color: colors.border)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Scrubber Slider
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded, size: 24),
                            onPressed: () {
                              _resetInactivityTimer();
                              _bridge.goPrev();
                            },
                          ),
                          Expanded(
                            child: Slider(
                              value: (_currentLocation?.percentage ??
                                      widget.book.percentage)
                                  .clamp(0.0, 100.0),
                              min: 0.0,
                              max: 100.0,
                              activeColor: AdwaitaColors.foliateGreen,
                              inactiveColor: colors.border,
                              onChanged: (val) {
                                _resetInactivityTimer();
                                _bridge.goToPercentage(val);
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded, size: 24),
                            onPressed: () {
                              _resetInactivityTimer();
                              _bridge.goNext();
                            },
                          ),
                        ],
                      ),

                      // Location & Progress Label
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _currentLocation?.formattedTimeLeftBook != null
                                ? '${_currentLocation!.formattedTimeLeftBook} left'
                                : '',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textMuted,
                            ),
                          ),
                          Text(
                            _currentLocation != null
                                ? (_currentLocation!.totalLocations != null &&
                                        _currentLocation!.totalLocations! > 0
                                    ? 'Page ${_currentLocation!.currentLocation ?? 1} / ${_currentLocation!.totalLocations}  •  ${_currentLocation!.percentage.round()}%'
                                    : '${_currentLocation!.percentage.round()}%')
                                : '${widget.book.percentage.round()}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
