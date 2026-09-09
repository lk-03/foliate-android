import 'package:flutter/material.dart';
import '../models/curated_book.dart';
import '../theme/theme.dart';

/// Card component for Open Library Gems and Explore Horizons sections.
class CuratedBookCard extends StatefulWidget {
  final CuratedBook book;
  final bool isCompact;
  final VoidCallback? onBookmark;

  const CuratedBookCard({
    super.key,
    required this.book,
    this.isCompact = false,
    this.onBookmark,
  });

  @override
  State<CuratedBookCard> createState() => _CuratedBookCardState();
}

class _CuratedBookCardState extends State<CuratedBookCard> {
  bool _isSaved = false;

  void _showBookDetails(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final primaryAccent = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: colors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header Row: Title, Author, Tag
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: primaryAccent.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  widget.book.tag.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: primaryAccent,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.book.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.book.author,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Rating Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.inputBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: colors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: AdwaitaColors.amberStreak,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.book.rating}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Metadata Badges Row
                    Row(
                      children: [
                        _buildMetaBadge(
                          colors,
                          Icons.menu_book_rounded,
                          '${widget.book.pageCount} pages',
                        ),
                        const SizedBox(width: 8),
                        _buildMetaBadge(
                          colors,
                          Icons.schedule_rounded,
                          widget.book.readTimeEstimate,
                        ),
                        const SizedBox(width: 8),
                        _buildMetaBadge(
                          colors,
                          Icons.public_rounded,
                          widget.book.catalogSource,
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Editorial Quote
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.inputBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        '“${widget.book.quoteSnippet}”',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Synopsis
                    Text(
                      widget.book.synopsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Action Button: Save to Wishlist / Library
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                        icon: Icon(
                          _isSaved
                              ? Icons.bookmark_added_rounded
                              : Icons.bookmark_add_outlined,
                          size: 20,
                        ),
                        label: Text(
                          _isSaved ? 'Saved to Wishlist' : 'Want to Read',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          setState(() {
                            _isSaved = !_isSaved;
                          });
                          setSheetState(() {});
                          widget.onBookmark?.call();
                          if (_isSaved) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added "${widget.book.title}" to reading wishlist'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetaBadge(FoliateThemeColors colors, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.inputBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colors.textMuted),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, color: colors.textMuted),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final primaryAccent = Theme.of(context).colorScheme.primary;

    if (widget.isCompact) {
      return _buildCompactCard(context, colors);
    }

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
      ),
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: () => _showBookDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Box (fixed height 135)
            SizedBox(
              height: 135,
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.inputBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
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
                          Icons.menu_book_rounded,
                          size: 36,
                          color: primaryAccent,
                        ),
                      ),
                    ),
                    // Left Spine Crease
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Tag Pill
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.book.tag.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
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
              widget.book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 1),

            // Author
            Text(
              widget.book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: colors.textMuted,
              ),
            ),

            const SizedBox(height: 4),

            // Star Rating Row
            Row(
              children: [
                for (int i = 0; i < 5; i++)
                  Icon(
                    i < widget.book.rating.floor()
                        ? Icons.star_rounded
                        : Icons.star_half_rounded,
                    size: 13,
                    color: AdwaitaColors.amberStreak,
                  ),
                const SizedBox(width: 4),
                Text(
                  '${widget.book.rating}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Editorial Quote Snippet
            Text(
              '“${widget.book.quoteSnippet}”',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: colors.textSecondary,
                height: 1.3,
              ),
            ),

            const Spacer(),

            // Want to Read / Bookmark Pill Button
            SizedBox(
              width: double.infinity,
              height: 30,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  side: BorderSide(
                    color: _isSaved ? primaryAccent : colors.border,
                  ),
                  backgroundColor: _isSaved
                      ? primaryAccent.withValues(alpha: 0.1)
                      : colors.inputBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(
                  _isSaved
                      ? Icons.bookmark_added_rounded
                      : Icons.bookmark_add_outlined,
                  size: 13,
                  color: _isSaved
                      ? primaryAccent
                      : colors.textPrimary,
                ),
                label: Text(
                  _isSaved ? 'Saved' : 'Want to Read',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _isSaved
                        ? primaryAccent
                        : colors.textPrimary,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _isSaved = !_isSaved;
                  });
                  widget.onBookmark?.call();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context, FoliateThemeColors colors) {
    final primaryAccent = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
      ),
      padding: const EdgeInsets.all(10),
      child: InkWell(
        onTap: () => _showBookDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Box (Expanded to fill grid space)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colors.inputBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
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
                          Icons.menu_book_rounded,
                          size: 32,
                          color: primaryAccent,
                        ),
                      ),
                    ),
                    // Left spine crease
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
                    // Tag Badge
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.book.tag.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (int i = 0; i < 5; i++)
                  Icon(
                    i < widget.book.rating.floor()
                        ? Icons.star_rounded
                        : Icons.star_half_rounded,
                    size: 12,
                    color: AdwaitaColors.amberStreak,
                  ),
                const SizedBox(width: 4),
                Text(
                  '${widget.book.rating}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '${widget.book.pageCount} pages • ${widget.book.readTimeEstimate}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: primaryAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
