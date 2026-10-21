import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/theme.dart';

/// Available side panel modes when running on wide/desktop displays
enum ReaderSidePanelType {
  none,
  toc,
  search,
  appearance,
  annotations,
}

/// Docked Libadwaita Sidebar Panel for desktop and tablet displays
class ReaderSidebarPanel extends StatelessWidget {
  final ReaderSidePanelType panelType;
  final VoidCallback onClose;
  final Book book;
  final List<TOCItem> toc;
  final List<Bookmark> bookmarks;
  final ReadingLocation? currentLocation;
  final ValueChanged<String> onChapterSelected;
  final ValueChanged<Bookmark>? onSelectBookmark;
  final ValueChanged<Bookmark>? onDeleteBookmark;

  // Search parameters
  final ValueNotifier<List<SearchSection>> searchSectionsNotifier;
  final ValueNotifier<bool> isSearchingNotifier;
  final ValueNotifier<int> totalMatchesNotifier;
  final void Function(String query, bool matchCase) onSearch;
  final VoidCallback onClearSearch;
  final void Function(SearchResultItem match, int globalIndex) onSelectSearchMatch;

  // Appearance parameters
  final ReaderSettings settings;
  final ValueChanged<ReaderSettings> onSettingsChanged;

  // Annotations
  final List<Annotation> annotations;
  final ValueChanged<Annotation>? onDeleteAnnotation;
  final ValueChanged<Annotation>? onSelectAnnotation;

  const ReaderSidebarPanel({
    super.key,
    required this.panelType,
    required this.onClose,
    required this.book,
    required this.toc,
    this.bookmarks = const [],
    this.currentLocation,
    required this.onChapterSelected,
    this.onSelectBookmark,
    this.onDeleteBookmark,
    required this.searchSectionsNotifier,
    required this.isSearchingNotifier,
    required this.totalMatchesNotifier,
    required this.onSearch,
    required this.onClearSearch,
    required this.onSelectSearchMatch,
    required this.settings,
    required this.onSettingsChanged,
    this.annotations = const [],
    this.onDeleteAnnotation,
    this.onSelectAnnotation,
  });

  String get _title {
    switch (panelType) {
      case ReaderSidePanelType.toc:
        return 'Contents & Bookmarks';
      case ReaderSidePanelType.search:
        return 'Search in Book';
      case ReaderSidePanelType.appearance:
        return 'Appearance & Layout';
      case ReaderSidePanelType.annotations:
        return 'Highlights & Notes';
      case ReaderSidePanelType.none:
        return '';
    }
  }

  IconData get _icon {
    switch (panelType) {
      case ReaderSidePanelType.toc:
        return Icons.format_list_bulleted_rounded;
      case ReaderSidePanelType.search:
        return Icons.search_rounded;
      case ReaderSidePanelType.appearance:
        return Icons.tune_rounded;
      case ReaderSidePanelType.annotations:
        return Icons.bookmarks_rounded;
      case ReaderSidePanelType.none:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final primaryAccent = Theme.of(context).colorScheme.primary;

    return Container(
      width: 360,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: colors.border),
        ),
      ),
      child: Material(
        color: colors.headerBar,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.border)),
              ),
              child: Row(
                children: [
                  Icon(_icon, size: 20, color: primaryAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Close panel (Esc)',
                    onPressed: onClose,
                  ),
                ],
              ),
            ),

            // Content Body
            Expanded(
              child: _buildBody(context, colors, primaryAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    FoliateThemeColors colors,
    Color primaryAccent,
  ) {
    switch (panelType) {
      case ReaderSidePanelType.toc:
        return _buildTOCView(colors, primaryAccent);
      case ReaderSidePanelType.search:
        return _buildSearchView(colors, primaryAccent);
      case ReaderSidePanelType.appearance:
        return _buildAppearanceView(colors, primaryAccent);
      case ReaderSidePanelType.annotations:
        return _buildAnnotationsView(colors, primaryAccent);
      case ReaderSidePanelType.none:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTOCView(FoliateThemeColors colors, Color primaryAccent) {
    if (toc.isEmpty && bookmarks.isEmpty) {
      return Center(
        child: Text(
          'No table of contents or bookmarks',
          style: TextStyle(color: colors.textMuted),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (bookmarks.isNotEmpty)
          ExpansionTile(
            initiallyExpanded: true,
            leading: Icon(Icons.bookmark_rounded, size: 18, color: primaryAccent),
            title: Text(
              'Bookmarks (${bookmarks.length})',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            children: bookmarks.map((b) {
              return ListTile(
                dense: true,
                title: Text(
                  b.chapterTitle ?? 'Page ${b.pageNumber ?? ""}',
                  style: const TextStyle(fontSize: 12),
                ),
                subtitle: Text(
                  '${b.percentage.round()}%',
                  style: TextStyle(fontSize: 10, color: colors.textMuted),
                ),
                trailing: onDeleteBookmark != null
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 16),
                        onPressed: () => onDeleteBookmark!(b),
                      )
                    : null,
                onTap: () => onSelectBookmark?.call(b),
              );
            }).toList(),
          ),
        ...toc.map((item) => _buildTOCItemTile(item, 0, colors, primaryAccent)),
      ],
    );
  }

  Widget _buildTOCItemTile(
    TOCItem item,
    int depth,
    FoliateThemeColors colors,
    Color primaryAccent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.only(
            left: 16.0 + (depth * 14.0),
            right: 14.0,
          ),
          title: Text(
            item.label.trim(),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          trailing: item.pageNumber != null
              ? Text(
                  '${item.pageNumber}',
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                )
              : null,
          onTap: () {
            if (item.href != null && item.href!.isNotEmpty) {
              onChapterSelected(item.href!);
            }
          },
        ),
        if (item.subitems.isNotEmpty)
          ...item.subitems.map(
            (sub) => _buildTOCItemTile(sub, depth + 1, colors, primaryAccent),
          ),
      ],
    );
  }

  Widget _buildSearchView(FoliateThemeColors colors, Color primaryAccent) {
    return _SidebarSearchWidget(
      sectionsNotifier: searchSectionsNotifier,
      isSearchingNotifier: isSearchingNotifier,
      totalMatchesNotifier: totalMatchesNotifier,
      onSearch: onSearch,
      onClear: onClearSearch,
      onSelectMatch: onSelectSearchMatch,
      colors: colors,
      primaryAccent: primaryAccent,
    );
  }

  Widget _buildAppearanceView(FoliateThemeColors colors, Color primaryAccent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Two-page spread toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Two-page spread', style: TextStyle(fontSize: 14)),
            subtitle: Text(
              'Show two pages side by side on wide screens',
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
            value: settings.twoPagesLandscape,
            activeThumbColor: primaryAccent,
            onChanged: (val) {
              onSettingsChanged(settings.copyWith(twoPagesLandscape: val));
            },
          ),
          const SizedBox(height: 12),

          // Font family selection
          const Text('Font Family', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFontChip('Serif', 'serif', primaryAccent),
              _buildFontChip('Sans-Serif', 'sans', primaryAccent),
              _buildFontChip('Literata', 'literata', primaryAccent),
              _buildFontChip('Garamond', 'ebgaramond', primaryAccent),
              _buildFontChip('Monospace', 'monospace', primaryAccent),
            ],
          ),
          const SizedBox(height: 16),

          // Font size stepper
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Font Size', style: TextStyle(fontSize: 14)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_rounded, size: 18),
                    onPressed: () {
                      if (settings.fontSize > 10) {
                        onSettingsChanged(settings.copyWith(fontSize: settings.fontSize - 1));
                      }
                    },
                  ),
                  Text('${settings.fontSize.toInt()} pt', style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    onPressed: () {
                      if (settings.fontSize < 36) {
                        onSettingsChanged(settings.copyWith(fontSize: settings.fontSize + 1));
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Line height stepper
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Line Height', style: TextStyle(fontSize: 14)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_rounded, size: 18),
                    onPressed: () {
                      if (settings.lineHeight > 1.1) {
                        onSettingsChanged(settings.copyWith(lineHeight: settings.lineHeight - 0.1));
                      }
                    },
                  ),
                  Text(settings.lineHeight.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    onPressed: () {
                      if (settings.lineHeight < 2.5) {
                        onSettingsChanged(settings.copyWith(lineHeight: settings.lineHeight + 0.1));
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Hyphenation toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hyphenation', style: TextStyle(fontSize: 14)),
            value: settings.hyphenation,
            activeThumbColor: primaryAccent,
            onChanged: (val) {
              onSettingsChanged(settings.copyWith(hyphenation: val));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFontChip(String label, String value, Color primaryAccent) {
    final isSelected = settings.fontFamily == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      selectedColor: primaryAccent.withValues(alpha: 0.2),
      onSelected: (_) {
        onSettingsChanged(settings.copyWith(fontFamily: value));
      },
    );
  }

  Widget _buildAnnotationsView(FoliateThemeColors colors, Color primaryAccent) {
    if (annotations.isEmpty) {
      return Center(
        child: Text(
          'No highlights or notes in this book',
          style: TextStyle(color: colors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: annotations.length,
      itemBuilder: (context, index) {
        final ann = annotations[index];
        return Card(
          color: colors.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(int.tryParse(ann.color.replaceFirst('#', '0xFF')) ?? 0xFFFFE066),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ann.note?.isNotEmpty == true ? ann.note! : 'Highlight',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onDeleteAnnotation != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Delete',
                        onPressed: () => onDeleteAnnotation!(ann),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => onSelectAnnotation?.call(ann),
                  child: Text(
                    ann.text,
                    style: TextStyle(fontSize: 12, color: colors.textMuted, fontStyle: FontStyle.italic),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SidebarSearchWidget extends StatefulWidget {
  final ValueNotifier<List<SearchSection>> sectionsNotifier;
  final ValueNotifier<bool> isSearchingNotifier;
  final ValueNotifier<int> totalMatchesNotifier;
  final void Function(String query, bool matchCase) onSearch;
  final VoidCallback onClear;
  final void Function(SearchResultItem match, int globalIndex) onSelectMatch;
  final FoliateThemeColors colors;
  final Color primaryAccent;

  const _SidebarSearchWidget({
    required this.sectionsNotifier,
    required this.isSearchingNotifier,
    required this.totalMatchesNotifier,
    required this.onSearch,
    required this.onClear,
    required this.onSelectMatch,
    required this.colors,
    required this.primaryAccent,
  });

  @override
  State<_SidebarSearchWidget> createState() => _SidebarSearchWidgetState();
}

class _SidebarSearchWidgetState extends State<_SidebarSearchWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _matchCase = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      widget.onSearch(query, _matchCase);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Input bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'Search in book...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: () {
                        _controller.clear();
                        widget.onClear();
                        setState(() {});
                      },
                    ),
                  IconButton(
                    icon: Icon(
                      Icons.format_size_rounded,
                      size: 18,
                      color: _matchCase ? widget.primaryAccent : widget.colors.textMuted,
                    ),
                    tooltip: 'Match case',
                    onPressed: () {
                      setState(() => _matchCase = !_matchCase);
                      _submit();
                    },
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: widget.colors.border),
              ),
            ),
          ),
        ),

        // Result count or progress
        ValueListenableBuilder<bool>(
          valueListenable: widget.isSearchingNotifier,
          builder: (context, isSearching, _) {
            if (isSearching) {
              return const LinearProgressIndicator();
            }
            return ValueListenableBuilder<int>(
              valueListenable: widget.totalMatchesNotifier,
              builder: (context, totalMatches, _) {
                if (totalMatches == 0 && _controller.text.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('No matches found', style: TextStyle(fontSize: 12, color: widget.colors.textMuted)),
                  );
                } else if (totalMatches > 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$totalMatches match${totalMatches == 1 ? '' : 'es'} found',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: widget.primaryAccent),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            );
          },
        ),

        // Matches list
        Expanded(
          child: ValueListenableBuilder<List<SearchSection>>(
            valueListenable: widget.sectionsNotifier,
            builder: (context, sections, _) {
              if (sections.isEmpty) {
                return Center(
                  child: Text(
                    'Type and press Enter to search',
                    style: TextStyle(fontSize: 12, color: widget.colors.textMuted),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                itemCount: sections.length,
                itemBuilder: (context, sIndex) {
                  final section = sections[sIndex];
                  int startIndex = 0;
                  for (int i = 0; i < sIndex; i++) {
                    startIndex += sections[i].subitems.length;
                  }

                  return ExpansionTile(
                    initiallyExpanded: true,
                    title: Text(
                      section.label,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${section.subitems.length} match${section.subitems.length == 1 ? '' : 'es'}',
                      style: TextStyle(fontSize: 11, color: widget.colors.textMuted),
                    ),
                    children: section.subitems.asMap().entries.map((entry) {
                      final itemIdx = startIndex + entry.key;
                      final match = entry.value;
                      return ListTile(
                        dense: true,
                        title: RichText(
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: TextStyle(fontSize: 12, color: widget.colors.textPrimary),
                            children: [
                              TextSpan(text: match.excerpt.pre),
                              TextSpan(
                                text: match.excerpt.match,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: widget.primaryAccent,
                                  backgroundColor: widget.primaryAccent.withValues(alpha: 0.15),
                                ),
                              ),
                              TextSpan(text: match.excerpt.post),
                            ],
                          ),
                        ),
                        onTap: () => widget.onSelectMatch(match, itemIdx),
                      );
                    }).toList(),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
