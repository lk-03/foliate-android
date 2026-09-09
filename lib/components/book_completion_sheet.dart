import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/theme.dart';

/// Celebratory modal sheet displayed when a user reaches 100% progress in a book.
class BookCompletionSheet extends StatelessWidget {
  final Book book;
  final VoidCallback onMarkFinished;
  final VoidCallback onClose;

  const BookCompletionSheet({
    super.key,
    required this.book,
    required this.onMarkFinished,
    required this.onClose,
  });

  String _formatDuration(int ms) {
    if (ms <= 0) return '< 1 hour';
    final minutes = ms ~/ (1000 * 60);
    if (minutes < 60) return '$minutes mins';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    return rem > 0 ? '${hours}h ${rem}m' : '${hours}h';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Celebratory Trophy Badge
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AdwaitaColors.amberStreak,
                    AdwaitaColors.terracottaAccent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AdwaitaColors.terracottaAccent.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.emoji_events_rounded,
                  size: 38,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Book Finished!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),

            Text(
              book.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),

            Text(
              'by ${book.author}',
              style: TextStyle(
                fontSize: 13,
                color: colors.textMuted,
              ),
            ),

            const SizedBox(height: 20),

            // Reading Duration Stat Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.inputBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 18,
                    color: AdwaitaColors.foliateGreen,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total Reading Time: ${_formatDuration(book.totalReadingTimeMs)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Primary Action: Mark Finished in Annual Challenge
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdwaitaColors.terracottaAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: const Text(
                  'Record in Annual Challenge',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  onMarkFinished();
                  Navigator.of(context).pop();
                },
              ),
            ),

            const SizedBox(height: 10),

            // Close Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () {
                  onClose();
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
