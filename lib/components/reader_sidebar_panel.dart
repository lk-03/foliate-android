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
  bookmarks,
}

/// Left-docked Libadwaita Sidebar Panel for desktop and tablet displays,
/// matching the original desktop Foliate interface.
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
  final VoidCallback? onBackToLibrary;
  final ValueChanged<ReaderSidePanelType>? onPanelTypeChanged;

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
    this.onBackToLibrary,
    this.onPanelTypeChanged,
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final primaryAccent = Theme.of(context).colorScheme.primary;

    return Container(
      width: 310,
      decoration: BoxDecoration(
        color: colors.headerBar,
        border: Border(
          right: BorderSide(color: colors.border, width: 1.0),
        ),
      ),
      child: Material(
        color: colors.headerBar,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Top Action Bar (Reference Image 1)
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    tooltip: 'Back to Library',
                    onPressed: onBackToLibrary ?? onClose,
                  ),
                  IconButton(
                    icon: Icon(
                      settings.twoPagesLandscape
                          ? Icons.auto_stories_rounded
                          : Icons.book_outlined,
                      size: 20,
                    ),
                    tooltip: 'Toggle Two-Page Spread',
                    onPressed: () {
                      onSettingsChanged(
                        settings.copyWith(
                          twoPagesLandscape: !settings.twoPagesLandscape,
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: panelType == ReaderSidePanelType.search
                          ? primaryAccent
                          : colors.textSecondary,
                    ),
                    tooltip: 'Search in Book (Ctrl+F)',
                    onPressed: () {
                      onPanelTypeChanged?.call(
                        panelType == ReaderSidePanelType.search
                            ? ReaderSidePanelType.toc
                            : ReaderSidePanelType.search,
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.palette_outlined,
                      size: 20,
                      color: panelType == ReaderSidePanelType.appearance
                          ? primaryAccent
                          : colors.textSecondary,
                    ),
                    tooltip: 'Appearance & Themes',
                    onPressed: () {
                      onPanelTypeChanged?.call(
                        panelType == ReaderSidePanelType.appearance
                            ? ReaderSidePanelType.toc
                            : ReaderSidePanelType.appearance,
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: panelType == ReaderSidePanelType.annotations
                          ? primaryAccent
                          : colors.textSecondary,
                    ),
                    tooltip: 'Annotations & Notes',
                    onPressed: () {
                      onPanelTypeChanged?.call(
                        panelType == ReaderSidePanelType.annotations
                            ? ReaderSidePanelType.toc
                            : ReaderSidePanelType.annotations,
                      );
                    },
                  ),
                ],
              ),
            ),

            // 2. Book Metadata Header (Image 1: Cover, Title, Author)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.border)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: 34,
                      height: 48,
                      color: colors.activePill,
                      child: book.coverUri != null && book.coverUri!.isNotEmpty
                          ? Image.asset(
                              book.coverUri!,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Icon(
                                Icons.menu_book_rounded,
                                size: 18,
                                color: colors.textSecondary,
                              ),
                            )
                          : Icon(
                              Icons.menu_book_rounded,
                              size: 18,
                              color: colors.textSecondary,
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          book.author.isNotEmpty ? book.author : 'Unknown Author',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. Body View
            Expanded(
              child: _buildBody(context, colors, primaryAccent),
            ),

            // 4. Bottom Segmented Control Bar (Image 1: Chapters, Annotations, Bookmarks)
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: Row(
                children: [
                  _buildBottomTabItem(
                    icon: Icons.format_list_bulleted_rounded,
                    tooltip: 'Table of Contents',
                    isActive: panelType == ReaderSidePanelType.toc,
                    onTap: () => onPanelTypeChanged?.call(ReaderSidePanelType.toc),
                    colors: colors,
                    accentColor: primaryAccent,
                  ),
                  const SizedBox(width: 6),
                  _buildBottomTabItem(
                    icon: Icons.edit_note_rounded,
                    tooltip: 'Annotations',
                    isActive: panelType == ReaderSidePanelType.annotations,
                    onTap: () => onPanelTypeChanged?.call(ReaderSidePanelType.annotations),
                    colors: colors,
                    accentColor: primaryAccent,
                  ),
                  const SizedBox(width: 6),
                  _buildBottomTabItem(
                    icon: Icons.bookmark_outline_rounded,
                    tooltip: 'Bookmarks',
                    isActive: panelType == ReaderSidePanelType.bookmarks,
                    onTap: () => onPanelTypeChanged?.call(ReaderSidePanelType.bookmarks),
                    colors: colors,
                    accentColor: primaryAccent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomTabItem({
    required IconData icon,
    required String tooltip,
    required bool isActive,
    required VoidCallback onTap,
    required FoliateThemeColors colors,
    required Color accentColor,
  }) {
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              color: isActive
                  ? accentColor.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 18,
              color: isActive ? accentColor : colors.textSecondary,
            ),
          ),
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
      case ReaderSidePanelType.bookmarks:
        return _buildBookmarksView(colors, primaryAccent);
      case ReaderSidePanelType.none:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTOCView(FoliateThemeColors colors, Color primaryAccent) {
    if (toc.isEmpty) {
      return Center(
        child: Text(
          'No table of contents',
          style: TextStyle(color: colors.textMuted, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: toc.length,
      itemBuilder: (context, index) {
        final item = toc[index];
        final isSelected = (currentLocation?.sectionTitle != null &&
                currentLocation!.sectionTitle == item.label) ||
            (currentLocation?.cfi != null &&
                item.href != null &&
                currentLocation!.cfi.contains(item.href!));

        return _buildTOCItemTile(item, 0, colors, primaryAccent, isSelected);
      },
    );
  }

  Widget _buildTOCItemTile(
    TOCItem item,
    int depth,
    FoliateThemeColors colors,
    Color primaryAccent,
    bool isSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: Material(
            color: isSelected
                ? AdwaitaColors.foliateGreen.withValues(alpha: 0.22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            contentPadding: EdgeInsets.only(
              left: 10.0 + (depth * 12.0),
              right: 10.0,
            ),
            leading: Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: isSelected ? AdwaitaColors.foliateGreen : colors.textMuted,
            ),
            title: Text(
              item.label.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? colors.textPrimary : colors.textSecondary,
              ),
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
        ),
      ),
        if (item.subitems.isNotEmpty)
          ...item.subitems.map(
            (sub) => _buildTOCItemTile(sub, depth + 1, colors, primaryAccent, false),
          ),
      ],
    );
  }

  Widget _buildBookmarksView(FoliateThemeColors colors, Color primaryAccent) {
    if (bookmarks.isEmpty) {
      return Center(
        child: Text(
          'No bookmarks added yet',
          style: TextStyle(color: colors.textMuted, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final b = bookmarks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          child: Material(
            color: colors.inputBackground,
            borderRadius: BorderRadius.circular(8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: colors.border),
            ),
            child: ListTile(
            dense: true,
            leading: Icon(Icons.bookmark_rounded, size: 16, color: primaryAccent),
            title: Text(
              b.chapterTitle ?? 'Page ${b.pageNumber ?? ""}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${b.percentage.round()}%',
              style: TextStyle(fontSize: 11, color: colors.textMuted),
            ),
            trailing: onDeleteBookmark != null
                ? IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    onPressed: () => onDeleteBookmark!(b),
                  )
                : null,
            onTap: () => onSelectBookmark?.call(b),
          ),
        ),
      );
      },
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Appearance & Layout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          // Two-page spread toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Two-page spread', style: TextStyle(fontSize: 13)),
            subtitle: Text(
              'Show two pages side by side on wide screens',
              style: TextStyle(fontSize: 11, color: colors.textMuted),
            ),
            value: settings.twoPagesLandscape,
            activeThumbColor: primaryAccent,
            onChanged: (val) {
              onSettingsChanged(settings.copyWith(twoPagesLandscape: val));
            },
          ),
          const SizedBox(height: 12),

          // Font family selection
          const Text('Font Family', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildFontChip('serif', 'Serif', colors, primaryAccent),
              _buildFontChip('sans', 'Sans', colors, primaryAccent),
              _buildFontChip('monospace', 'Mono', colors, primaryAccent),
            ],
          ),
          const SizedBox(height: 14),

          // Font size stepper
          const Text('Font Size', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_rounded, size: 18),
                onPressed: settings.fontSize > 10
                    ? () => onSettingsChanged(settings.copyWith(fontSize: settings.fontSize - 1))
                    : null,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${settings.fontSize.toInt()} pt',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded, size: 18),
                onPressed: settings.fontSize < 36
                    ? () => onSettingsChanged(settings.copyWith(fontSize: settings.fontSize + 1))
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Margins slider
          const Text('Margins', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Slider(
            value: settings.margin.clamp(0.02, 0.20),
            min: 0.02,
            max: 0.20,
            activeColor: primaryAccent,
            onChanged: (val) {
              onSettingsChanged(settings.copyWith(margin: val));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFontChip(
    String fontId,
    String label,
    FoliateThemeColors colors,
    Color primaryAccent,
  ) {
    final isSelected = settings.fontFamily.toLowerCase() == fontId;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      selectedColor: primaryAccent.withValues(alpha: 0.2),
      onSelected: (_) {
        onSettingsChanged(settings.copyWith(fontFamily: fontId));
      },
    );
  }

  Widget _buildAnnotationsView(FoliateThemeColors colors, Color primaryAccent) {
    if (annotations.isEmpty) {
      return Center(
        child: Text(
          'No annotations or highlights yet',
          style: TextStyle(color: colors.textMuted, fontSize: 13),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: Text(
            'Highlights & Notes',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      itemCount: annotations.length,
      itemBuilder: (context, index) {
        final ann = annotations[index];
        final highlightColor = Color(int.tryParse(ann.color) ?? 0xFFFFEB3B);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.inputBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border(left: BorderSide(color: highlightColor, width: 3.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ann.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
              if (ann.note != null && ann.note!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  ann.note!,
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    ),
  ),
],
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
  final _controller = TextEditingController();
  bool _matchCase = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitSearch() {
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      widget.onSearch(query, _matchCase);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Input
        Padding(
          padding: const EdgeInsets.all(10),
          child: TextField(
            controller: _controller,
            style: const TextStyle(fontSize: 13),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _submitSearch(),
            decoration: InputDecoration(
              hintText: 'Search in book...',
              isDense: true,
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.format_size_rounded,
                      size: 16,
                      color: _matchCase ? widget.primaryAccent : widget.colors.textMuted,
                    ),
                    tooltip: 'Match case',
                    onPressed: () {
                      setState(() => _matchCase = !_matchCase);
                      _submitSearch();
                    },
                  ),
                  if (_controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      onPressed: () {
                        _controller.clear();
                        widget.onClear();
                      },
                    ),
                ],
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: widget.colors.border),
              ),
            ),
          ),
        ),

        // Progress or count
        ValueListenableBuilder<bool>(
          valueListenable: widget.isSearchingNotifier,
          builder: (context, isSearching, _) {
            if (isSearching) {
              return const LinearProgressIndicator(minHeight: 2);
            }
            return ValueListenableBuilder<int>(
              valueListenable: widget.totalMatchesNotifier,
              builder: (context, totalMatches, _) {
                if (totalMatches > 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$totalMatches matches found',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: widget.primaryAccent,
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            );
          },
        ),

        // Results
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemCount: sections.length,
                itemBuilder: (context, sIndex) {
                  final section = sections[sIndex];
                  return ExpansionTile(
                    initiallyExpanded: true,
                    title: Text(
                      section.label,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    children: section.subitems.map((match) {
                      return ListTile(
                        dense: true,
                        title: RichText(
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: TextStyle(fontSize: 11, color: widget.colors.textPrimary),
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
                        onTap: () => widget.onSelectMatch(match, 0),
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
