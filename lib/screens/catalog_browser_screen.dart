import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../theme/theme.dart';
import 'reader_screen.dart';

/// Interactive OPDS & Atom Catalog Browser Screen.
/// Allows browsing book hierarchies, searching within feeds, viewing cover artwork,
/// and streaming EPUB downloads directly into the local library.
class CatalogBrowserScreen extends StatefulWidget {
  final Catalog? catalog;
  final String? initialFeedUrl;
  final String? title;
  final String? openLibraryQuery;
  final VoidCallback? onBookImported;

  const CatalogBrowserScreen({
    super.key,
    this.catalog,
    this.initialFeedUrl,
    this.title,
    this.openLibraryQuery,
    this.onBookImported,
  });

  @override
  State<CatalogBrowserScreen> createState() => _CatalogBrowserScreenState();
}

class _CatalogBrowserScreenState extends State<CatalogBrowserScreen> {
  final OpdsService _opdsService = OpdsService.instance;
  final DownloadService _downloadService = DownloadService.instance;
  final StorageService _storageService = StorageService.instance;

  late String _currentUrl;
  bool _isLoading = true;
  String? _errorMessage;
  OpdsFeed? _feed;
  List<Book> _localBooks = [];

  final TextEditingController _filterController = TextEditingController();
  String _filterQuery = '';

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialFeedUrl ?? widget.catalog?.url ?? '';
    _loadLocalLibrary();
    _fetchFeed();
    _filterController.addListener(() {
      setState(() {
        _filterQuery = _filterController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalLibrary() async {
    final books = await _storageService.getBooks();
    if (mounted) {
      setState(() => _localBooks = books);
    }
  }

  Future<void> _fetchFeed() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (widget.openLibraryQuery != null && widget.openLibraryQuery!.isNotEmpty) {
      try {
        final results = await _opdsService.searchOpenLibrary(widget.openLibraryQuery!);
        if (mounted) {
          setState(() {
            _feed = OpdsFeed(
              title: 'Open Library: "${widget.openLibraryQuery}"',
              subtitle: '${results.length} public domain results found',
              entries: results,
            );
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = e.toString().replaceFirst('Exception: ', '');
          });
        }
      }
      return;
    }

    if (_currentUrl.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No catalog feed URL specified';
      });
      return;
    }

    try {
      final feed = await _opdsService.fetchFeed(_currentUrl);
      if (mounted) {
        setState(() {
          _feed = feed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Book? _findMatchingLocalBook(CatalogBook catalogBook) {
    final cleanTitle = catalogBook.title.trim().toLowerCase();
    final cleanAuthor = catalogBook.author.trim().toLowerCase();

    for (final b in _localBooks) {
      if (b.title.trim().toLowerCase() == cleanTitle) {
        if (cleanAuthor.isEmpty ||
            cleanAuthor == 'unknown author' ||
            b.author.trim().toLowerCase() == cleanAuthor ||
            b.author.toLowerCase().contains(cleanAuthor) ||
            cleanAuthor.contains(b.author.toLowerCase())) {
          return b;
        }
      }
    }
    return null;
  }

  List<CatalogBook> get _filteredBooks {
    if (_feed == null) return const [];
    final books = _feed!.books;
    if (_filterQuery.isEmpty) return books;
    return books.where((b) {
      return b.title.toLowerCase().contains(_filterQuery) ||
          b.author.toLowerCase().contains(_filterQuery) ||
          b.summary.toLowerCase().contains(_filterQuery) ||
          b.categories.any((c) => c.toLowerCase().contains(_filterQuery));
    }).toList();
  }

  List<CatalogBook> get _filteredSubsections {
    if (_feed == null) return const [];
    final subs = _feed!.subsections;
    if (_filterQuery.isEmpty) return subs;
    return subs.where((s) {
      return s.title.toLowerCase().contains(_filterQuery) ||
          s.summary.toLowerCase().contains(_filterQuery);
    }).toList();
  }

  Future<void> _startDownload(CatalogBook book) async {
    if (!book.hasDownload) return;

    try {
      final importedBook = await _downloadService.downloadAndImportBook(
        book: book,
      );

      await _loadLocalLibrary();
      widget.onBookImported?.call();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${importedBook.title}" to Your Library'),
          action: SnackBarAction(
            label: 'Read',
            onPressed: () => _openReader(importedBook),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _openReader(Book book) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReaderScreen(book: book),
      ),
    );
    _loadLocalLibrary();
  }

  void _navigateToSubFeed(CatalogBook sub) {
    if (sub.navigationUrl == null || sub.navigationUrl!.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => CatalogBrowserScreen(
          catalog: widget.catalog,
          initialFeedUrl: sub.navigationUrl!,
          title: sub.title,
          onBookImported: widget.onBookImported,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final primaryAccent = Theme.of(context).colorScheme.primary;

    final screenTitle = widget.title ?? _feed?.title ?? widget.catalog?.name ?? 'Catalog';

    return Scaffold(
      backgroundColor: colors.windowBackground,
      appBar: AppBar(
        backgroundColor: colors.surfaceCard,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              screenTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.catalog?.name != null && screenTitle != widget.catalog!.name)
              Text(
                widget.catalog!.name,
                style: TextStyle(fontSize: 11, color: colors.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: colors.border, height: 1),
        ),
      ),
      body: _buildBody(colors, primaryAccent),
    );
  }

  Widget _buildBody(FoliateThemeColors colors, Color primaryAccent) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading catalog feed...',
              style: TextStyle(fontSize: 14, color: colors.textMuted),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 52, color: Colors.redAccent),
              const SizedBox(height: 14),
              const Text(
                'Unable to Load Feed',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: colors.textMuted),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                onPressed: _fetchFeed,
              ),
            ],
          ),
        ),
      );
    }

    final books = _filteredBooks;
    final subsections = _filteredSubsections;

    return RefreshIndicator(
      color: primaryAccent,
      onRefresh: _fetchFeed,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // In-feed filter search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                child: TextField(
                  controller: _filterController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Filter titles, authors, or genres...',
                    hintStyle: TextStyle(fontSize: 12, color: colors.textMuted),
                    prefixIcon: Icon(Icons.search_rounded, size: 18, color: colors.textMuted),
                    suffixIcon: _filterQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () => _filterController.clear(),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ),
          ),

          // Subsections horizontal chip list
          if (subsections.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Text(
                      'SECTIONS & CATEGORIES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: subsections.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final sub = subsections[index];
                        return ActionChip(
                          avatar: const Icon(Icons.folder_open_rounded, size: 16),
                          label: Text(
                            sub.title,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: colors.surfaceCard,
                          side: BorderSide(color: colors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onPressed: () => _navigateToSubFeed(sub),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

          // Books Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Titles (${books.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Books List
          if (books.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off_rounded, size: 44, color: colors.textMuted),
                    const SizedBox(height: 10),
                    Text(
                      _filterQuery.isNotEmpty
                          ? 'No books matching "$_filterQuery"'
                          : 'No books found in this section',
                      style: TextStyle(fontSize: 13, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final book = books[index];
                    final existingBook = _findMatchingLocalBook(book);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildBookItemCard(
                        book: book,
                        existingBook: existingBook,
                        colors: colors,
                        primaryAccent: primaryAccent,
                      ),
                    );
                  },
                  childCount: books.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookItemCard({
    required CatalogBook book,
    required Book? existingBook,
    required FoliateThemeColors colors,
    required Color primaryAccent,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Thumbnail with tactile spine depth
          _buildCover(book, colors, primaryAccent),

          const SizedBox(width: 12),

          // Details & Action Row
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  book.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),

                // Author
                Text(
                  book.author,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Categories / Tags
                if (book.categories.isNotEmpty) ...[
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: book.categories.take(2).map((cat) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.activePill.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(fontSize: 10, color: colors.textMuted),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],

                // Short summary
                if (book.summary.isNotEmpty)
                  Text(
                    book.summary,
                    style: TextStyle(fontSize: 11, color: colors.textMuted, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 10),

                // Action Button (Read Now vs Download vs Progress)
                _buildActionButton(
                  book: book,
                  existingBook: existingBook,
                  colors: colors,
                  primaryAccent: primaryAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover(
    CatalogBook book,
    FoliateThemeColors colors,
    Color primaryAccent,
  ) {
    return Container(
      width: 58,
      height: 84,
      decoration: BoxDecoration(
        color: colors.inputBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(3),
          bottomLeft: Radius.circular(3),
          topRight: Radius.circular(7),
          bottomRight: Radius.circular(7),
        ),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (book.coverUrl != null && book.coverUrl!.isNotEmpty)
            Image.network(
              book.coverUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildFallbackCover(book, primaryAccent),
            )
          else
            _buildFallbackCover(book, primaryAccent),

          // Tactile spine crease
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackCover(CatalogBook book, Color primaryAccent) {
    return Container(
      color: primaryAccent.withValues(alpha: 0.12),
      padding: const EdgeInsets.all(4),
      child: Center(
        child: Icon(Icons.auto_stories_rounded, size: 24, color: primaryAccent),
      ),
    );
  }

  Widget _buildActionButton({
    required CatalogBook book,
    required Book? existingBook,
    required FoliateThemeColors colors,
    required Color primaryAccent,
  }) {
    // 1. If already in library
    if (existingBook != null) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.menu_book_rounded, size: 15),
        label: const Text('Read', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        onPressed: () => _openReader(existingBook),
      );
    }

    // 2. If actively downloading
    return ValueListenableBuilder<Map<String, double>>(
      valueListenable: _downloadService.downloadProgressNotifier,
      builder: (context, activeDownloads, _) {
        final progress = activeDownloads[book.id];
        final isDownloading = progress != null;

        if (isDownloading) {
          final pct = (progress * 100).toStringAsFixed(0);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  value: progress > 0 ? progress : null,
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: primaryAccent,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                tooltip: 'Cancel download',
                onPressed: () => _downloadService.cancelDownload(book.id),
              ),
            ],
          );
        }

        // 3. Ready to download
        if (book.hasDownload) {
          final sizeLabel = book.formattedSize;
          final buttonText = sizeLabel.isNotEmpty ? 'Download ($sizeLabel)' : 'Download';

          return OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryAccent,
              side: BorderSide(color: primaryAccent.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.download_rounded, size: 15),
            label: Text(
              buttonText,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            onPressed: () => _startDownload(book),
          );
        }

        // 4. No download link available
        return Text(
          'Read Online Only',
          style: TextStyle(fontSize: 11, color: colors.textMuted),
        );
      },
    );
  }
}
