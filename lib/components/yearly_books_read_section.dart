import 'dart:io';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/theme.dart';

/// Apple Books inspired flat section displaying books finished in a selected year.
/// Includes year navigation controls (< and >) allowing the user to browse back
/// to their account creation year.
class YearlyBooksReadSection extends StatefulWidget {
  final List<Book> books;
  final ReadingHabits habits;
  final int accountCreationYear;
  final ValueChanged<Book> onBookTap;

  const YearlyBooksReadSection({
    super.key,
    required this.books,
    required this.habits,
    this.accountCreationYear = 2024,
    required this.onBookTap,
  });

  @override
  State<YearlyBooksReadSection> createState() => _YearlyBooksReadSectionState();
}

class _YearlyBooksReadSectionState extends State<YearlyBooksReadSection> {
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
  }

  int get _currentYear => DateTime.now().year;

  int get _minYear {
    final creationYear = widget.accountCreationYear;
    return creationYear <= _currentYear ? creationYear : _currentYear;
  }

  bool get _canGoBack => _selectedYear > _minYear;
  bool get _canGoForward => _selectedYear < _currentYear;

  void _previousYear() {
    if (_canGoBack) {
      setState(() {
        _selectedYear--;
      });
    }
  }

  void _nextYear() {
    if (_canGoForward) {
      setState(() {
        _selectedYear++;
      });
    }
  }

  List<Book> _getFinishedBooks() {
    final hashes = widget.habits.getFinishedBooksForYear(_selectedYear);
    final result = <Book>[];

    // 1. Add books matching hashes explicitly recorded in ReadingHabits
    for (final hash in hashes) {
      final book = widget.books.where((b) => b.hash == hash).firstOrNull;
      if (book != null && !result.any((b) => b.hash == book.hash)) {
        result.add(book);
      }
    }

    // 2. Also include any book in the library completed (>= 99%) whose read date matches _selectedYear
    for (final b in widget.books) {
      if (b.progressFraction >= 0.99 && !result.any((r) => r.hash == b.hash)) {
        final timestamp = (b.lastReadAt != null && b.lastReadAt! > 0)
            ? b.lastReadAt!
            : b.addedAt;
        if (timestamp > 0) {
          final bookYear = DateTime.fromMillisecondsSinceEpoch(timestamp).year;
          if (bookYear == _selectedYear) {
            result.add(b);
          }
        }
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final primaryAccent = Theme.of(context).colorScheme.primary;

    final finishedBooks = _getFinishedBooks();
    final isCurrent = _selectedYear == _currentYear;
    final sectionTitle =
        isCurrent ? 'Books Read This Year' : 'Books Read in $_selectedYear';
    final countSubtitle =
        '${finishedBooks.length} ${finishedBooks.length == 1 ? 'book' : 'books'} finished';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: Title & Subtitle on left, Year Navigation (< [Year] >) on right
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sectionTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    countSubtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Year Navigation Controls: [<] 2026 [>]
            Container(
              decoration: BoxDecoration(
                color: colors.inputBackground.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colors.border.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Previous Year Button
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    splashRadius: 18,
                    tooltip: _canGoBack ? 'Previous year' : null,
                    color: _canGoBack
                        ? colors.textPrimary
                        : colors.textMuted.withValues(alpha: 0.25),
                    onPressed: _canGoBack ? _previousYear : null,
                  ),

                  // Selected Year Label with smooth transition
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                    child: Text(
                      '$_selectedYear',
                      key: ValueKey<int>(_selectedYear),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),

                  // Next Year Button
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    splashRadius: 18,
                    tooltip: _canGoForward ? 'Next year' : null,
                    color: _canGoForward
                        ? colors.textPrimary
                        : colors.textMuted.withValues(alpha: 0.25),
                    onPressed: _canGoForward ? _nextYear : null,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Body: Finished Books Carousel or Apple Books-Style Clean Empty State
        if (finishedBooks.isNotEmpty)
          SizedBox(
            height: 236,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: finishedBooks.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, idx) {
                final book = finishedBooks[idx];
                return _buildFinishedBookCard(book, colors, primaryAccent);
              },
            ),
          )
        else
          _buildEmptyState(colors),
      ],
    );
  }

  Widget _buildFinishedBookCard(
    Book book,
    FoliateThemeColors colors,
    Color primaryAccent,
  ) {
    return SizedBox(
      width: 120,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onBookTap(book),
          borderRadius: BorderRadius.circular(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tactile 2:3 Cover with Finished Checkmark Badge
              AspectRatio(
                aspectRatio: 2 / 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceCard,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(3),
                      bottomLeft: Radius.circular(3),
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    border: Border.all(
                      color: colors.border.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 8,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Book Cover Image or Fallback Gradient
                      if (book.coverUri != null &&
                          File(book.coverUri!).existsSync())
                        Image.file(
                          File(book.coverUri!),
                          fit: BoxFit.cover,
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colors.surfaceCard,
                                colors.inputBackground,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.auto_stories_rounded,
                              size: 28,
                              color: primaryAccent.withValues(alpha: 0.6),
                            ),
                          ),
                        ),

                      // Spine Shadow Overlay
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: 12,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withValues(alpha: 0.35),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Completed Badge (top-right checkmark circle)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Title
              Text(
                book.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 2),

              // Author
              Text(
                book.author,
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textMuted,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(FoliateThemeColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 36,
            color: colors.textMuted.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 10),
          Text(
            'No Books Finished in $_selectedYear',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Books you finish will appear here.',
            style: TextStyle(
              fontSize: 12,
              color: colors.textMuted.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
