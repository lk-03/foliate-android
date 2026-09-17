import 'dart:io';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/theme.dart';

/// Horizontal card displaying a recently opened or favorite book with reading progress
class RecentBookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;

  const RecentBookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;

    final primaryAccent = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border.withValues(alpha: 0.8)),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Cover Thumbnail
              _buildCover(colors, primaryAccent),
              const SizedBox(width: 14),

              // Book Details & Progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Author
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Progress Text & Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${book.percentage.round()}% completed',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: colors.textMuted,
                          ),
                        ),
                        if (book.isPinned)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: primaryAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'PINNED',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: primaryAccent,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Two-Tone Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (book.percentage / 100).clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: colors.border.withValues(alpha: 0.5),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          primaryAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Actions (Favorite & Pin)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      book.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 20,
                      color: book.isFavorite
                          ? AdwaitaColors.libadwaitaRed
                          : colors.textMuted,
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: book.isFavorite ? 'Unfavorite' : 'Favorite',
                    onPressed: onToggleFavorite,
                  ),
                  IconButton(
                    icon: Icon(
                      book.isPinned
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      size: 19,
                      color: book.isPinned
                          ? primaryAccent
                          : colors.textMuted,
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: book.isPinned ? 'Unpin' : 'Pin',
                    onPressed: onTogglePin,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover(FoliateThemeColors colors, Color primaryAccent) {
    return Container(
      width: 52,
      height: 74,
      decoration: BoxDecoration(
        color: colors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(1, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: book.coverUri != null && File(book.coverUri!).existsSync()
          ? Image.file(
              File(book.coverUri!),
              fit: BoxFit.cover,
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 22,
                      color: primaryAccent,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.title.isNotEmpty ? book.title[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AdwaitaColors.darkTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
