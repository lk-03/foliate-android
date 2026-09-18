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

class _CoverTheme {
  final List<Color> gradient;
  final Color accent;
  final IconData emblem;
  final String category;

  const _CoverTheme({
    required this.gradient,
    required this.accent,
    required this.emblem,
    required this.category,
  });
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

  _CoverTheme _getCoverTheme(CuratedBook book) {
    switch (book.id) {
      case 'gem-frankenstein':
        return const _CoverTheme(
          gradient: [Color(0xFF0B2014), Color(0xFF183B2B)],
          accent: Color(0xFF86EFAC),
          emblem: Icons.bolt_rounded,
          category: 'GOTHIC CLASSIC',
        );
      case 'gem-pride-prejudice':
        return const _CoverTheme(
          gradient: [Color(0xFF38141C), Color(0xFF56212D)],
          accent: Color(0xFFFDE047),
          emblem: Icons.auto_stories_rounded,
          category: 'REGENCY CLASSIC',
        );
      case 'gem-dorian-gray':
        return const _CoverTheme(
          gradient: [Color(0xFF1D0E26), Color(0xFF351743)],
          accent: Color(0xFFFBBF24),
          emblem: Icons.portrait_rounded,
          category: 'VICTORIAN PARABLE',
        );
      case 'gem-metamorphosis':
        return const _CoverTheme(
          gradient: [Color(0xFF261A0F), Color(0xFF3F2B19)],
          accent: Color(0xFFFDBA74),
          emblem: Icons.psychology_outlined,
          category: 'EXISTENTIAL NOVELLA',
        );
      case 'gem-moby-dick':
        return const _CoverTheme(
          gradient: [Color(0xFF09192E), Color(0xFF132C4D)],
          accent: Color(0xFF93C5FD),
          emblem: Icons.sailing_rounded,
          category: 'NAUTICAL EPIC',
        );
      case 'hor-solarpunk':
        return const _CoverTheme(
          gradient: [Color(0xFF13281B), Color(0xFF21422C)],
          accent: Color(0xFFA3E635),
          emblem: Icons.park_rounded,
          category: 'COZY SOLARPUNK',
        );
      case 'hor-philosophy':
        return const _CoverTheme(
          gradient: [Color(0xFF221F1C), Color(0xFF3B3631)],
          accent: Color(0xFFFDBA74),
          emblem: Icons.public_rounded,
          category: 'UTOPIAN FICTION',
        );
      case 'hor-nonfiction':
        return const _CoverTheme(
          gradient: [Color(0xFF330F15), Color(0xFF4C1820)],
          accent: Color(0xFFFDE68A),
          emblem: Icons.account_balance_rounded,
          category: 'STOIC PHILOSOPHY',
        );
      case 'hor-magical-realism':
        return const _CoverTheme(
          gradient: [Color(0xFF1B122E), Color(0xFF2F1F4F)],
          accent: Color(0xFFD8B4FE),
          emblem: Icons.flare_rounded,
          category: 'MAGICAL REALISM',
        );
      case 'hor-classic-scifi':
        return const _CoverTheme(
          gradient: [Color(0xFF0C1F30), Color(0xFF173857)],
          accent: Color(0xFF7DD3FC),
          emblem: Icons.ac_unit_rounded,
          category: 'CLASSIC SCI-FI',
        );
      default:
        return const _CoverTheme(
          gradient: [Color(0xFF1A2332), Color(0xFF2B3A52)],
          accent: Color(0xFFE2E8F0),
          emblem: Icons.menu_book_rounded,
          category: 'OPEN LIBRARY',
        );
    }
  }

  Widget _buildCoverArtwork(
    FoliateThemeColors colors, {
    required bool isCompact,
  }) {
    final theme = _getCoverTheme(widget.book);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.gradient,
        ),
        borderRadius: BorderRadius.circular(isCompact ? 8 : 10),
        border: Border.all(
          color: theme.accent.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background ambient circular glow
          Positioned(
            right: -25,
            bottom: -25,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.accent.withValues(alpha: 0.06),
                  width: 18,
                ),
              ),
            ),
          ),

          // Left 3D Spine Crease & Shadow
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 7,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 7,
            top: 0,
            bottom: 0,
            width: 0.8,
            child: Container(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),

          // Classical Inner Decorative Border
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 8 : 10,
              vertical: isCompact ? 7 : 8,
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.accent.withValues(alpha: 0.32),
                  width: 0.8,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 6 : 8,
                vertical: isCompact ? 5 : 6,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Publisher / Category Label
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 0.8,
                        color: theme.accent.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          theme.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isCompact ? 6.5 : 7.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: theme.accent.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 8,
                        height: 0.8,
                        color: theme.accent.withValues(alpha: 0.4),
                      ),
                    ],
                  ),

                  // Center: Thematic Emblem & Serif Title
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(isCompact ? 4 : 5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.accent.withValues(alpha: 0.12),
                            ),
                            child: Icon(
                              theme.emblem,
                              size: isCompact ? 16 : 19,
                              color: theme.accent,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            widget.book.title.toUpperCase(),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Noto Serif',
                              fontSize: isCompact ? 9.5 : 11.0,
                              fontWeight: FontWeight.bold,
                              height: 1.15,
                              color: Colors.white,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom: Author Attribution
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 18,
                        height: 0.8,
                        color: theme.accent.withValues(alpha: 0.35),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.book.author.toUpperCase(),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isCompact ? 6.5 : 7.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: theme.accent.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Tag Pill Badge in Top Right
          Positioned(
            top: 5,
            right: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: theme.accent.withValues(alpha: 0.35),
                  width: 0.5,
                ),
              ),
              child: Text(
                widget.book.tag.toUpperCase(),
                style: TextStyle(
                  fontSize: 7.0,
                  fontWeight: FontWeight.bold,
                  color: theme.accent,
                  letterSpacing: 0.2,
                ),
              ),
            ),
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
      width: 176,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: InkWell(
        onTap: () => _showBookDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Box (fixed height 140)
            SizedBox(
              height: 140,
              width: double.infinity,
              child: _buildCoverArtwork(colors, isCompact: false),
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
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      padding: const EdgeInsets.all(4),
      child: InkWell(
        onTap: () => _showBookDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Box (Expanded to fill grid space)
            Expanded(
              child: _buildCoverArtwork(colors, isCompact: true),
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
