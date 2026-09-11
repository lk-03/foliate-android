import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/components.dart';
import '../models/models.dart';
import '../services/annotation_export_service.dart';
import '../services/storage_service.dart';
import '../theme/theme.dart';
import 'reader_screen.dart';

/// Central repository screen displaying all highlights and notes across books.
/// Features book-grouped accordions, full-text search, color filtering, and Markdown/JSON export.
class AnnotationsScreen extends StatefulWidget {
  final List<Annotation>? annotations;
  final Map<String, Book>? booksMap;
  final void Function(Annotation annotation, Book? book)? onAnnotationTap;
  final VoidCallback? onAnnotationsChanged;

  const AnnotationsScreen({
    super.key,
    this.annotations,
    this.booksMap,
    this.onAnnotationTap,
    this.onAnnotationsChanged,
  });

  @override
  State<AnnotationsScreen> createState() => _AnnotationsScreenState();
}

class _AnnotationsScreenState extends State<AnnotationsScreen> {
  List<Annotation> _annotations = [];
  Map<String, Book> _booksMap = {};
  bool _isLoading = true;

  // Search & Filter state
  bool _isSearchOpen = false;
  String _searchQuery = '';
  String? _selectedColorFilter; // null = all, or hex string
  bool _notesOnlyFilter = false;

  // Track expanded state for each bookHash (default expanded)
  final Set<String> _collapsedBookHashes = {};

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant AnnotationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.annotations != null && widget.annotations != oldWidget.annotations) {
      _annotations = List.from(widget.annotations!);
    }
    if (widget.booksMap != null && widget.booksMap != oldWidget.booksMap) {
      _booksMap = Map.from(widget.booksMap!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final books = await StorageService.instance.getBooks();
      final booksMap = {for (final b in books) b.hash: b};
      if (widget.booksMap != null) {
        booksMap.addAll(widget.booksMap!);
      }

      final annotations = widget.annotations ??
          await StorageService.instance.getAllAnnotations();

      if (mounted) {
        setState(() {
          _booksMap = booksMap;
          _annotations = annotations;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAnnotation(Annotation annotation) async {
    final deleted = annotation;
    await StorageService.instance
        .deleteAnnotation(annotation.bookHash, annotation.cfi);

    setState(() {
      _annotations.removeWhere((a) => a.id == annotation.id);
    });
    widget.onAnnotationsChanged?.call();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Highlight deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await StorageService.instance.saveAnnotation(deleted);
            if (mounted) {
              setState(() {
                _annotations.add(deleted);
                _annotations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              });
              widget.onAnnotationsChanged?.call();
            }
          },
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _editAnnotation(Annotation annotation) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AnnotationEditSheet(
        annotation: annotation,
        onUpdate: (updated) async {
          await StorageService.instance.saveAnnotation(updated);
          if (mounted) {
            setState(() {
              final idx = _annotations.indexWhere((a) => a.id == updated.id);
              if (idx >= 0) {
                _annotations[idx] = updated;
              }
            });
            widget.onAnnotationsChanged?.call();
          }
        },
        onDelete: () => _deleteAnnotation(annotation),
      ),
    );
  }

  void _handleAnnotationTap(Annotation annotation, Book? book) {
    if (widget.onAnnotationTap != null) {
      widget.onAnnotationTap!(annotation, book);
    } else if (book != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReaderScreen(
            book: book,
            initialCfi: annotation.cfi,
          ),
        ),
      ).then((_) => _loadData());
    }
  }

  void _showExportPreviewDialog({
    required String title,
    required String content,
    required String formatName,
  }) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;

    final primaryAccent = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              formatName == 'Markdown'
                  ? Icons.text_snippet_outlined
                  : Icons.code_rounded,
              size: 20,
              color: primaryAccent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.inputBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                content,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close', style: TextStyle(color: colors.textMuted)),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: primaryAccent,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy to Clipboard'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$formatName copied to clipboard'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _exportAll(String format) {
    final filtered = _getFilteredAnnotations();
    if (filtered.isEmpty) return;

    if (format == 'markdown') {
      final md = AnnotationExportService.exportToMarkdown(filtered, _booksMap);
      _showExportPreviewDialog(
        title: 'Export Highlights (Markdown)',
        content: md,
        formatName: 'Markdown',
      );
    } else {
      final jsonStr = AnnotationExportService.exportToJson(filtered, _booksMap);
      _showExportPreviewDialog(
        title: 'Export Highlights (JSON)',
        content: jsonStr,
        formatName: 'JSON',
      );
    }
  }

  void _exportBook(String bookHash, String format) {
    final bookAnnotations = _annotations
        .where((a) => a.bookHash == bookHash)
        .toList();
    final book = _booksMap[bookHash];
    final title = book?.title ?? 'Book';

    if (format == 'markdown') {
      final md = AnnotationExportService.exportToMarkdown(
        bookAnnotations,
        _booksMap,
      );
      _showExportPreviewDialog(
        title: '$title (Markdown)',
        content: md,
        formatName: 'Markdown',
      );
    } else {
      final jsonStr = AnnotationExportService.exportToJson(
        bookAnnotations,
        _booksMap,
      );
      _showExportPreviewDialog(
        title: '$title (JSON)',
        content: jsonStr,
        formatName: 'JSON',
      );
    }
  }

  List<Annotation> _getFilteredAnnotations() {
    return _annotations.where((a) {
      // Color filter
      if (_selectedColorFilter != null &&
          !a.color.toLowerCase().contains(_selectedColorFilter!.toLowerCase())) {
        return false;
      }
      // Notes only filter
      if (_notesOnlyFilter && (a.note == null || a.note!.trim().isEmpty)) {
        return false;
      }
      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final textMatch = a.text.toLowerCase().contains(q);
        final noteMatch = (a.note ?? '').toLowerCase().contains(q);
        final bookTitle = (_booksMap[a.bookHash]?.title ?? '').toLowerCase();
        final titleMatch = bookTitle.contains(q);
        if (!textMatch && !noteMatch && !titleMatch) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final primaryAccent = Theme.of(context).colorScheme.primary;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: primaryAccent),
      );
    }

    final filteredAnnotations = _getFilteredAnnotations();

    // Group filtered annotations by bookHash
    final grouped = <String, List<Annotation>>{};
    for (final a in filteredAnnotations) {
      grouped.putIfAbsent(a.bookHash, () => []).add(a);
    }

    return Scaffold(
      backgroundColor: colors.windowBackground,
      appBar: AppBar(
        backgroundColor: colors.headerBar,
        elevation: 0,
        title: const Text(
          'Annotations',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
              size: 20,
            ),
            tooltip: _isSearchOpen ? 'Close Search' : 'Search Annotations',
            onPressed: () {
              setState(() {
                _isSearchOpen = !_isSearchOpen;
                if (!_isSearchOpen) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.ios_share_rounded, size: 20),
            tooltip: 'Export Highlights',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            color: colors.surfaceCard,
            onSelected: (val) => _exportAll(val),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'markdown',
                child: Row(
                  children: [
                    Icon(Icons.text_snippet_outlined, size: 18),
                    SizedBox(width: 8),
                    Expanded(child: Text('Export as Markdown (.md)')),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'json',
                child: Row(
                  children: [
                    Icon(Icons.code_rounded, size: 18),
                    SizedBox(width: 8),
                    Expanded(child: Text('Export as JSON (.json)')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Row
          Container(
            color: colors.headerBar,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isSearchOpen) ...[
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search quotes, notes, or books...',
                      hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                      prefixIcon: Icon(Icons.search, size: 18, color: colors.textMuted),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: colors.inputBackground,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: colors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: colors.border),
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  ),
                  const SizedBox(height: 10),
                ],

                // Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'All (${_annotations.length})',
                        isSelected: _selectedColorFilter == null && !_notesOnlyFilter,
                        onSelected: () => setState(() {
                          _selectedColorFilter = null;
                          _notesOnlyFilter = false;
                        }),
                        colors: colors,
                      ),
                      const SizedBox(width: 6),
                      _buildColorDotChip(
                        label: 'Yellow',
                        hexColor: '#FFE066',
                        dotColor: const Color(0xFFFFE066),
                        colors: colors,
                      ),
                      const SizedBox(width: 6),
                      _buildColorDotChip(
                        label: 'Green',
                        hexColor: '#B8E986',
                        dotColor: const Color(0xFFB8E986),
                        colors: colors,
                      ),
                      const SizedBox(width: 6),
                      _buildColorDotChip(
                        label: 'Blue',
                        hexColor: '#80D8FF',
                        dotColor: const Color(0xFF80D8FF),
                        colors: colors,
                      ),
                      const SizedBox(width: 6),
                      _buildColorDotChip(
                        label: 'Pink',
                        hexColor: '#FFB6C1',
                        dotColor: const Color(0xFFFFB6C1),
                        colors: colors,
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'With Notes',
                        isSelected: _notesOnlyFilter,
                        onSelected: () => setState(() {
                          _notesOnlyFilter = !_notesOnlyFilter;
                        }),
                        colors: colors,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body: Accordion List or Empty State
          Expanded(
            child: filteredAnnotations.isEmpty
                ? _buildEmptyState(colors)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final bookHash = grouped.keys.elementAt(index);
                      final bookAnnotations = grouped[bookHash]!;
                      final book = _booksMap[bookHash];
                      final isCollapsed = _collapsedBookHashes.contains(bookHash);

                      return _buildBookAccordionSection(
                        bookHash: bookHash,
                        book: book,
                        annotations: bookAnnotations,
                        isCollapsed: isCollapsed,
                        colors: colors,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required FoliateThemeColors colors,
  }) {
    final primaryAccent = Theme.of(context).colorScheme.primary;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: colors.surfaceCard,
      selectedColor: primaryAccent.withValues(alpha: 0.22),
      checkmarkColor: primaryAccent,
      labelStyle: TextStyle(
        color: isSelected ? primaryAccent : colors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? primaryAccent : colors.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildColorDotChip({
    required String label,
    required String hexColor,
    required Color dotColor,
    required FoliateThemeColors colors,
  }) {
    final isSelected = _selectedColorFilter == hexColor;

    return FilterChip(
      avatar: CircleAvatar(
        backgroundColor: dotColor,
        radius: 5,
      ),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          if (isSelected) {
            _selectedColorFilter = null;
          } else {
            _selectedColorFilter = hexColor;
          }
        });
      },
      backgroundColor: colors.surfaceCard,
      selectedColor: dotColor.withValues(alpha: 0.25),
      checkmarkColor: colors.textPrimary,
      labelStyle: TextStyle(
        color: colors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? dotColor : colors.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildBookAccordionSection({
    required String bookHash,
    required Book? book,
    required List<Annotation> annotations,
    required bool isCollapsed,
    required FoliateThemeColors colors,
  }) {
    final title = book?.title ?? 'Unknown Book';
    final author = book?.author ?? 'Unknown Author';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsible Header
          InkWell(
            onTap: () {
              setState(() {
                if (isCollapsed) {
                  _collapsedBookHashes.remove(bookHash);
                } else {
                  _collapsedBookHashes.add(bookHash);
                }
              });
            },
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(14),
              bottom: isCollapsed ? const Radius.circular(14) : Radius.zero,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Book Cover Thumbnail
                  Container(
                    width: 38,
                    height: 52,
                    decoration: BoxDecoration(
                      color: colors.inputBackground,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: colors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: book?.coverUri != null &&
                            File(book!.coverUri!).existsSync()
                        ? Image.file(
                            File(book.coverUri!),
                            fit: BoxFit.cover,
                          )
                        : Icon(
                            Icons.auto_stories_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                  ),
                  const SizedBox(width: 12),

                  // Title & Author
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Count Pill Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.inputBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(
                      '${annotations.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),

                  // Per-Book Export Action
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, size: 18, color: colors.textMuted),
                    tooltip: 'Export book notes',
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    color: colors.surfaceCard,
                    onSelected: (format) => _exportBook(bookHash, format),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'markdown',
                        child: Row(
                          children: [
                            Icon(Icons.text_snippet_outlined, size: 16),
                            SizedBox(width: 8),
                            Expanded(child: Text('Export Book (.md)')),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'json',
                        child: Row(
                          children: [
                            Icon(Icons.code_rounded, size: 16),
                            SizedBox(width: 8),
                            Expanded(child: Text('Export Book (.json)')),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Expand/Collapse Chevron
                  Icon(
                    isCollapsed
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    size: 20,
                    color: colors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          // Cards List (when expanded)
          if (!isCollapsed) ...[
            Divider(height: 1, color: colors.border),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: annotations.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final item = annotations[idx];
                return AnnotationCard(
                  annotation: item,
                  bookTitle: title,
                  onTap: () => _handleAnnotationTap(item, book),
                  onEdit: () => _editAnnotation(item),
                  onDelete: () => _deleteAnnotation(item),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(FoliateThemeColors colors) {
    final isFiltered = _searchQuery.isNotEmpty ||
        _selectedColorFilter != null ||
        _notesOnlyFilter;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                shape: BoxShape.circle,
                border: Border.all(color: colors.border),
              ),
              child: Icon(
                isFiltered
                    ? Icons.search_off_rounded
                    : Icons.bookmarks_outlined,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isFiltered ? 'No Matches Found' : 'No Annotations Yet',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Try changing your search keywords or clearing the active color filters.'
                  : 'Select any text while reading to highlight passages, save personal notes, and export your quotes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.textMuted, height: 1.4),
            ),
            if (isFiltered) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.border),
                ),
                icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                label: const Text('Clear Filters'),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                    _selectedColorFilter = null;
                    _notesOnlyFilter = false;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
