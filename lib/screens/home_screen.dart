import 'dart:io';
import 'package:flutter/material.dart';
import '../components/components.dart';
import '../models/models.dart';
import '../theme/theme.dart';
import 'reader_screen.dart';

/// Reinvented Apple Books & Stitch inspired Home Dashboard.
/// Features:
/// 1. Hero greeting with live streak flame and "Currently Reading" card with 1-tap Resume.
/// 2. Continue Reading horizontal carousel of 3-5 active books with tactile 2:3 covers.
/// 3. Open Library Gems horizontal carousel with public domain classics.
/// 4. Explore Horizons interactive genre recommendation row.
/// 5. Reading Insights tracker: daily goal ring, day streak, weekly consistency, and annual challenge.
class HomeScreen extends StatefulWidget {
  final List<Book> books;
  final ReadingHabits? readingHabits;
  final VoidCallback onNavigateToLibrary;
  final VoidCallback? onBooksChanged;
  final ValueChanged<int>? onDailyGoalChanged;
  final ValueChanged<int>? onYearlyGoalChanged;

  const HomeScreen({
    super.key,
    required this.books,
    this.readingHabits,
    required this.onNavigateToLibrary,
    this.onBooksChanged,
    this.onDailyGoalChanged,
    this.onYearlyGoalChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedGenre = 'All';

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dayName = days[now.weekday - 1];
    final monthName = months[now.month - 1];
    return '$dayName, $monthName ${now.day}';
  }

  List<CuratedBook> _getFilteredHorizons() {
    if (_selectedGenre == 'All') {
      return CuratedBook.exploreHorizons;
    }
    return CuratedBook.exploreHorizons
        .where((b) => b.genre.toLowerCase().contains(_selectedGenre.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;

    final habits = widget.readingHabits ?? const ReadingHabits();

    // Sort books: Pinned first, then by lastReadAt or percentage
    final sortedBooks = List<Book>.from(widget.books)
      ..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return (b.lastReadAt ?? 0).compareTo(a.lastReadAt ?? 0);
      });

    final recentBooks = sortedBooks.take(5).toList();
    final currentBook = recentBooks.isNotEmpty ? recentBooks.first : null;

    final genres = [
      'All',
      'Solarpunk',
      'Philosophy',
      'Sci-Fi',
      'Magical Realism',
    ];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // 1. Top Header: Date, Greeting, and Streak Flame Pill
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getFormattedDate().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AdwaitaColors.terracottaAccent,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_getGreeting()}, Reader',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),

            // Streak Flame Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AdwaitaColors.amberStreak.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AdwaitaColors.amberStreak.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    size: 16,
                    color: AdwaitaColors.amberStreak,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${habits.currentStreak} Days',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AdwaitaColors.amberStreak,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 2. Currently Reading Hero Card (if active book exists)
        if (currentBook != null) ...[
          _buildCurrentlyReadingHero(currentBook, colors),
          const SizedBox(height: 24),
        ] else ...[
          _buildWelcomeBanner(colors),
          const SizedBox(height: 24),
        ],

        // 3. Section: Continue Reading Horizontal Carousel
        _buildSectionHeader(
          title: 'Continue Reading',
          subtitle: '${recentBooks.length} books in Your Library',
          actionText: 'Your Library',
          onAction: widget.onNavigateToLibrary,
          colors: colors,
        ),
        const SizedBox(height: 12),

        if (recentBooks.isNotEmpty)
          SizedBox(
            height: 300,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: recentBooks.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, idx) {
                final b = recentBooks[idx];
                return TactileRecentBookCard(
                  book: b,
                  onTap: () => _openBook(b),
                );
              },
            ),
          )
        else
          _buildEmptyLibraryPrompt(colors),

        const SizedBox(height: 28),

        // 4. Section: Open Library Gems (Popular books from Open Libraries)
        _buildSectionHeader(
          icon: Icons.public_rounded,
          title: 'Open Library Gems',
          subtitle: 'Curated classics free of copyright restrictions',
          colors: colors,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 330,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: CuratedBook.openLibraryGems.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, idx) {
              final gem = CuratedBook.openLibraryGems[idx];
              return CuratedBookCard(book: gem);
            },
          ),
        ),

        const SizedBox(height: 28),

        // 5. Section: Explore Horizons (Recommending new tastes by genre)
        _buildSectionHeader(
          title: 'Explore Horizons',
          subtitle: 'Selected genres based on your evolving tastes',
          colors: colors,
        ),
        const SizedBox(height: 10),

        // Genre Filter Chips Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: genres.map((g) {
              final isSelected = _selectedGenre == g;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(g),
                  selected: isSelected,
                  showCheckmark: false,
                  backgroundColor: colors.surfaceCard,
                  selectedColor: AdwaitaColors.terracottaAccent,
                  side: BorderSide(
                    color: isSelected
                        ? AdwaitaColors.terracottaAccent
                        : colors.border,
                  ),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : colors.textPrimary,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedGenre = g;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 14),

        // Curated Horizons Cards Grid (2-Columns)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _getFilteredHorizons().length,
          itemBuilder: (context, idx) {
            final book = _getFilteredHorizons()[idx];
            return CuratedBookCard(
              book: book,
              isCompact: true,
            );
          },
        ),

        const SizedBox(height: 28),

        // 6. Section: Reading Insights & Habits Tracker
        ReadingInsightsCard(
          habits: habits,
          onDailyGoalChanged: widget.onDailyGoalChanged,
          onYearlyGoalChanged: widget.onYearlyGoalChanged,
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    IconData? icon,
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
    required FoliateThemeColors colors,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: AdwaitaColors.terracottaAccent),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: colors.textMuted),
              ),
            ],
          ),
        ),
        if (actionText != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AdwaitaColors.terracottaAccent,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AdwaitaColors.terracottaAccent,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentlyReadingHero(Book book, FoliateThemeColors colors) {
    final percent = (book.percentage * 100).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cover Thumbnail with tactile spine depth
          Container(
            width: 56,
            height: 80,
            decoration: BoxDecoration(
              color: colors.inputBackground,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                bottomLeft: Radius.circular(3),
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              border: Border.all(color: colors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (book.coverUri != null && File(book.coverUri!).existsSync())
                  Image.file(File(book.coverUri!), fit: BoxFit.cover)
                else
                  const Center(
                    child: Icon(
                      Icons.auto_stories_rounded,
                      size: 24,
                      color: AdwaitaColors.foliateGreen,
                    ),
                  ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Title, Status, and Resume Button
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AdwaitaColors.foliateGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'CURRENTLY READING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$percent% completed • ${book.author}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Terracotta Resume Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdwaitaColors.terracottaAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text(
              'Resume',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            onPressed: () => _openBook(book),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(FoliateThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AdwaitaColors.foliateGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 26,
              color: AdwaitaColors.foliateGreen,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to Foliate',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'Import an EPUB or explore curated public domain classics below.',
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLibraryPrompt(FoliateThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Center(
        child: Text(
          'No books in your library yet. Tap + to import or browse recommendations.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: colors.textMuted),
        ),
      ),
    );
  }

  Future<void> _openBook(Book book) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReaderScreen(book: book),
      ),
    );
    widget.onBooksChanged?.call();
  }
}
