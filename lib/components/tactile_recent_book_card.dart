import 'dart:io';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/theme.dart';

/// Tactile, editorial 2:3 aspect ratio book card replicating Apple Books & stitch design.
/// Features ambient spine shadows, asymmetrical rounding, frosted progress badge,
/// and flush bottom progress groove.
class TactileRecentBookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const TactileRecentBookCard({
    super.key,
    required this.book,
    required this.onTap,
  });

  String _formatReadingTime(int totalReadingTimeMs) {
    if (totalReadingTimeMs <= 0) {
      final pct = (book.percentage * 100).toInt();
      if (pct > 0) return '$pct% finished';
      return 'New book';
    }
    final minutes = totalReadingTimeMs ~/ (1000 * 60);
    if (minutes < 60) return '$minutes mins read';
    final hours = minutes ~/ 60;
    final remMin = minutes % 60;
    return remMin > 0 ? '${hours}h ${remMin}m read' : '${hours}h read';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final percent = (book.percentage * 100).round();

    return SizedBox(
      width: 154,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 2:3 Tactile Cover Artwork Container
              AspectRatio(
                aspectRatio: 2 / 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceCard,
                    // Asymmetrical rounding: spine edge tight (3px), page edge soft (10px)
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(3),
                      bottomLeft: Radius.circular(3),
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    border: Border.all(color: colors.border.withValues(alpha: 0.6)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 10,
                        offset: const Offset(2, 5),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Cover Image or Fallback Palette
                      if (book.coverUri != null && File(book.coverUri!).existsSync())
                        Image.file(
                          File(book.coverUri!),
                          fit: BoxFit.cover,
                        )
                      else
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
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.auto_stories_rounded,
                                size: 30,
                                color: AdwaitaColors.foliateGreen.withValues(alpha: 0.8),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                book.title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Realistic Vertical Spine Crease & Shadow Overlay (left edge)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withValues(alpha: 0.45),
                                Colors.white.withValues(alpha: 0.15),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Top-Right Frosted Percentage Badge
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            '$percent%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),

                      // Flush Bottom Progress Bar
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          height: 4,
                          color: Colors.black.withValues(alpha: 0.35),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: book.percentage.clamp(0.0, 1.0),
                            child: Container(
                              color: AdwaitaColors.terracottaAccent,
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
                book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),

              // Author
              Text(
                book.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textMuted,
                ),
              ),
              const SizedBox(height: 3),

              // Reading Time / Progress
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 12,
                    color: colors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _formatReadingTime(book.totalReadingTimeMs),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
