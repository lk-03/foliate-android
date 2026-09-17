import 'dart:io';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/theme.dart';

/// 3-column mobile grid book card with aspect ratio ~0.68
class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;

  const BookCard({
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Artwork Container (Aspect Ratio ~ 0.68)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Artwork or Fallback
                    if (book.coverUri != null && File(book.coverUri!).existsSync())
                      Image.file(
                        File(book.coverUri!),
                        fit: BoxFit.cover,
                      )
                    else
                      Container(
                        color: colors.inputBackground,
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.book_rounded,
                              size: 28,
                              color: Theme.of(context).colorScheme.primary,
                            ),

                            const SizedBox(height: 6),
                            Text(
                              book.title,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Top Quick Action Overlay (Favorite / Pin)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (book.isPinned)
                            Container(
                              padding: const EdgeInsets.all(3),
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.push_pin_rounded,
                                size: 12,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          if (book.isFavorite)
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                size: 12,
                                color: AdwaitaColors.libadwaitaRed,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Bottom Progress Pill Overlay
                    if (book.percentage > 0)
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${book.percentage.round()}%',
                            style: const TextStyle(
                              fontSize: 10,
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
            const SizedBox(height: 6),

            // Title
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),

            // Author
            Text(
              book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
