import 'package:flutter/material.dart';
import '../components/components.dart';
import '../models/models.dart';
import '../theme/theme.dart';
import 'reader_screen.dart';

/// Mobile Home Dashboard: Continue Reading list + Horizontal Library Carousel
class HomeScreen extends StatelessWidget {
  final List<Book> books;
  final VoidCallback onNavigateToLibrary;
  final VoidCallback? onBooksChanged;

  const HomeScreen({
    super.key,
    required this.books,
    required this.onNavigateToLibrary,
    this.onBooksChanged,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final primaryAccent = Theme.of(context).colorScheme.primary;

    if (books.isEmpty) {
      return _buildEmptyState(colors, primaryAccent);
    }

    // Sort: Pinned first, then by percentage / last read
    final sortedBooks = List<Book>.from(books)
      ..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return (b.lastReadAt ?? 0).compareTo(a.lastReadAt ?? 0);
      });

    final recentBooks = sortedBooks.take(4).toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // Friendly Greeting Banner
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              AppLogo(
                size: 38,
                accentColor: primaryAccent,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${books.length} book${books.length == 1 ? '' : 's'} in your library',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Continue Reading Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Continue Reading',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '${recentBooks.length} active',
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Recent Books List (Pinned First)
        for (final book in recentBooks) ...[
          RecentBookCard(
            book: book,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ReaderScreen(book: book),
                ),
              );
              onBooksChanged?.call();
            },
          ),
          const SizedBox(height: 10),
        ],

        const SizedBox(height: 20),

        // Horizontal Library Carousel Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Library',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            TextButton(
              onPressed: onNavigateToLibrary,
              child: const Row(
                children: [
                  Text('See All'),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Horizontal Carousel
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final book = books[index];
              return SizedBox(
                width: 105,
                child: BookCard(
                  book: book,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ReaderScreen(book: book),
                      ),
                    );
                    onBooksChanged?.call();
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(FoliateThemeColors colors, Color primaryAccent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppLogo(
              size: 64,
              accentColor: primaryAccent,
            ),
            const SizedBox(height: 20),
            const Text(
              'No Books in Library',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to import an EPUB file from your device and start reading.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colors.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
