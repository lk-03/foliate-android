import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/components.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../theme/theme.dart';
import 'open_libraries_screen.dart';
import 'reader_screen.dart';

enum LibraryCategory {
  all('All'),
  reading('Reading'),
  favorites('Favorites'),
  pinned('Pinned'),
  finished('Finished');

  final String label;
  const LibraryCategory(this.label);
}

/// Mobile Library Catalog Screen with 3-column grid, filter pills, pull-to-refresh,
/// segmented Discover tab, and batch file / folder linking options.
class LibraryScreen extends StatefulWidget {
  final List<Book> books;
  final VoidCallback? onAddBook;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onBooksChanged;

  const LibraryScreen({
    super.key,
    required this.books,
    this.onAddBook,
    this.onRefresh,
    this.onBooksChanged,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with AutomaticKeepAliveClientMixin {
  int _libraryTab = 0; // 0: My Books, 1: Discover
  LibraryCategory _selectedCategory = LibraryCategory.all;
  bool _isImporting = false;
  ImportProgress? _currentProgress;

  @override
  bool get wantKeepAlive => true;

  List<Book> get _filteredBooks {
    switch (_selectedCategory) {
      case LibraryCategory.reading:
        return widget.books
            .where((b) => b.percentage > 0 && b.percentage < 100)
            .toList();
      case LibraryCategory.favorites:
        return widget.books.where((b) => b.isFavorite).toList();
      case LibraryCategory.pinned:
        return widget.books.where((b) => b.isPinned).toList();
      case LibraryCategory.finished:
        return widget.books.where((b) => b.percentage >= 100).toList();
      case LibraryCategory.all:
        return widget.books;
    }
  }

  void _showImportOptions(BuildContext context, FoliateThemeColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: colors.headerBar,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: colors.border),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colors.textMuted.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Add to Library',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Material(
                  color: colors.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.activePill,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.file_present_rounded, color: Colors.white, size: 22),
                    ),
                    title: const Text('Add File(s)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text('Pick single or multiple .epub files', style: TextStyle(fontSize: 12, color: colors.textMuted)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _importFiles();
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  color: colors.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.activePill,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.folder_open_rounded, color: Colors.white, size: 22),
                    ),
                    title: const Text('Link Library Folder', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text('Auto-syncs new books on app launch & refresh', style: TextStyle(fontSize: 12, color: colors.textMuted)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _importFolder();
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  color: colors.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.activePill,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.public_rounded, color: Colors.white, size: 22),
                    ),
                    title: const Text('Browse Open Libraries', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text('Free books from Gutenberg, Standard Ebooks & more', style: TextStyle(fontSize: 12, color: colors.textMuted)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _libraryTab = 1);
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _importFiles() async {
    setState(() => _isImporting = true);
    final imported = await FolderSyncService.instance.pickAndImportFiles(
      onProgress: (p) {
        if (mounted) setState(() => _currentProgress = p);
      },
    );
    if (mounted) {
      setState(() {
        _isImporting = false;
        _currentProgress = null;
      });
      if (imported.isNotEmpty) {
        widget.onBooksChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported ${imported.length} new book${imported.length == 1 ? '' : 's'}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _importFolder() async {
    final hasPerm = await StoragePermissionService.ensurePermission(context);
    if (!hasPerm) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage access is required to link and scan folders'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isImporting = true);
    final imported = await FolderSyncService.instance.pickAndLinkFolder(
      onProgress: (p) {
        if (mounted) setState(() => _currentProgress = p);
      },
    );
    if (mounted) {
      setState(() {
        _isImporting = false;
        _currentProgress = null;
      });
      widget.onBooksChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(imported.isNotEmpty
              ? 'Linked folder: added ${imported.length} book${imported.length == 1 ? '' : 's'}'
              : 'Folder linked (all books up to date or already added)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final primaryAccent = Theme.of(context).colorScheme.primary;
    final filtered = _filteredBooks;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Segmented Switcher: My Books | Discover
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: BorderRadius.circular(21),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _libraryTab = 0);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: _libraryTab == 0
                              ? primaryAccent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(19),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_stories_rounded,
                              size: 16,
                              color: _libraryTab == 0
                                  ? Colors.white
                                  : colors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'My Books (${widget.books.length})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _libraryTab == 0
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: _libraryTab == 0
                                    ? Colors.white
                                    : colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _libraryTab = 1);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: _libraryTab == 1
                              ? primaryAccent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(19),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.public_rounded,
                              size: 16,
                              color: _libraryTab == 1
                                  ? Colors.white
                                  : colors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Discover',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _libraryTab == 1
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: _libraryTab == 1
                                    ? Colors.white
                                    : colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_libraryTab == 1)
            const Expanded(child: OpenLibrariesScreen())
          else ...[
            // Filter Category Pills
            SizedBox(
              height: 48,
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: LibraryCategory.values.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = LibraryCategory.values[index];
                  final isSelected = _selectedCategory == cat;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryAccent.withValues(alpha: 0.18)
                            : colors.surfaceCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? primaryAccent : colors.border,
                          width: isSelected ? 1.4 : 1.0,
                        ),
                      ),
                      child: Text(
                        cat.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? primaryAccent
                              : colors.textMuted,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Import Progress Indicator (if active)
          if (_isImporting && _currentProgress != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Importing ${_currentProgress!.current} of ${_currentProgress!.total}...',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_currentProgress!.importedCount} added',
                          style: TextStyle(fontSize: 11, color: colors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: _currentProgress!.total > 0
                          ? _currentProgress!.current / _currentProgress!.total
                          : null,
                      backgroundColor: colors.inputBackground,
                      valueColor: AlwaysStoppedAnimation(primaryAccent),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentProgress!.currentTitle,
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

          // 3-Column Books Grid with Pull-to-Refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (widget.onRefresh != null) {
                  await widget.onRefresh!();
                }
              },
              color: primaryAccent,
              backgroundColor: colors.surfaceCard,
              child: filtered.isEmpty
                  ? ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: Center(
                            child: Text(
                              'No books in ${_selectedCategory.label}',
                              style: TextStyle(color: colors.textMuted),
                            ),
                          ),
                        ),
                      ],
                    )
                  : GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.52,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final book = filtered[index];
                        return BookCard(
                          book: book,
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ReaderScreen(book: book),
                              ),
                            );
                            widget.onBooksChanged?.call();
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ],
    ),
    floatingActionButton: _libraryTab == 0
        ? FloatingActionButton.extended(
            backgroundColor: primaryAccent,
            foregroundColor: Colors.white,
            onPressed: widget.onAddBook ?? () => _showImportOptions(context, colors),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Book'),
          )
        : null,
  );
}
}
