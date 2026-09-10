import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/theme.dart';

/// Apple Books inspired unboxed Reading Goals overview.
/// Features a semicircular arch gauge, today's minutes read, daily goal trigger,
/// "Keep Reading" pill button for active book, 7-day consistency ring tracker,
/// streak record summary, and annual challenge progress.
class ReadingInsightsCard extends StatelessWidget {
  final ReadingHabits habits;
  final Book? activeBook;
  final VoidCallback? onKeepReading;
  final ValueChanged<int>? onDailyGoalChanged;
  final ValueChanged<int>? onYearlyGoalChanged;

  const ReadingInsightsCard({
    super.key,
    required this.habits,
    this.activeBook,
    this.onKeepReading,
    this.onDailyGoalChanged,
    this.onYearlyGoalChanged,
  });

  void _showDailyGoalDialog(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final primaryAccent = Theme.of(context).colorScheme.primary;

    const options = [5, 10, 15, 20, 30, 45, 60];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Daily Reading Target', style: TextStyle(fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How many minutes do you want to read each day?',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((mins) {
                  final isSelected = habits.dailyGoalMinutes == mins;
                  return ChoiceChip(
                    label: Text('$mins mins'),
                    selected: isSelected,
                    selectedColor: primaryAccent,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        Navigator.of(ctx).pop();
                        onDailyGoalChanged?.call(mins);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showYearlyGoalDialog(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final primaryAccent = Theme.of(context).colorScheme.primary;

    const options = [5, 10, 12, 15, 20, 25, 30, 50];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            '${DateTime.now().year} Reading Challenge',
            style: const TextStyle(fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Set your annual reading goal in completed books:',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((target) {
                  final isSelected = habits.yearlyGoalBooks == target;
                  return ChoiceChip(
                    label: Text('$target books'),
                    selected: isSelected,
                    selectedColor: primaryAccent,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        Navigator.of(ctx).pop();
                        onYearlyGoalChanged?.call(target);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final primaryAccent = Theme.of(context).colorScheme.primary;

    final weekActivity = habits.getWeekActivityMap();
    // Week letters matching Apple Books: Sunday to Saturday (S M T W T F S)
    const weekLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final todayWeekday = DateTime.now().weekday; // 1=Mon ... 7=Sun
    final todayIndex = todayWeekday % 7; // Sun=0, Mon=1, Tue=2, Wed=3, Thu=4, Fri=5, Sat=6

    final currentYear = DateTime.now().year;
    final booksDone = habits.booksFinishedThisYear.length;
    final targetBooks = habits.yearlyGoalBooks;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Reading Goals Title & Subtitle (Apple Books Serif style)
          Text(
            'Reading Goals',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              fontFamily: 'serif',
              letterSpacing: -0.4,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Read every day, see your stats soar and finish\nmore books.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: colors.textMuted,
            ),
          ),

          const SizedBox(height: 24),

          // 2. Semicircular Arch Gauge with Today's Reading stats
          SizedBox(
            width: 270,
            height: 145,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Arch Custom Painter
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ArchGaugePainter(
                      fraction: habits.dailyGoalFraction,
                      trackColor: colors.border.withValues(alpha: 0.35),
                      progressColor: primaryAccent,
                    ),
                  ),
                ),

                // Center Statistics Column
                Positioned(
                  top: 22,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Today's Reading",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'serif',
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${habits.todayMinutesRead}',
                        style: TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.normal,
                          fontFamily: 'serif',
                          height: 1.05,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showDailyGoalDialog(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'of your ${habits.dailyGoalMinutes}-minute goal',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 14,
                                    color: colors.textMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. Apple Books "Keep Reading" Pill Action Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onKeepReading,
              borderRadius: BorderRadius.circular(28),
              child: Container(
                constraints: const BoxConstraints(minWidth: 230, maxWidth: 280),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF24262E),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: colors.border.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Keep Reading',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activeBook != null ? activeBook!.title : 'Explore Library',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 4. 7-Day Consistency Circles (S M T W T F S)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < 7; i++) ...[
                _buildDayBubble(
                  letter: weekLetters[i],
                  isToday: i == todayIndex,
                  hasRead: weekActivity[i == 0 ? 7 : i] ?? false,
                  accentColor: primaryAccent,
                  colors: colors,
                ),
                if (i < 6) const SizedBox(width: 10),
              ],
            ],
          ),

          const SizedBox(height: 18),

          // 5. Streak & Record Summary (Matching Apple Books)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showDailyGoalDialog(context),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          habits.currentStreak > 0
                              ? '${habits.currentStreak} Day Streak'
                              : 'Start a new streak.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 15,
                          color: colors.textMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      habits.longestStreak > 0
                          ? 'Your record is ${habits.longestStreak} days.'
                          : 'Read daily to set your personal record.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 22),

          // 6. Annual Reading Challenge (Clean unboxed progress bar)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showYearlyGoalDialog(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_stories_rounded,
                              size: 14,
                              color: primaryAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$currentYear Challenge',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$booksDone of $targetBooks completed',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Container(
                        height: 4,
                        color: colors.border.withValues(alpha: 0.35),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: habits.yearlyProgressFraction,
                          child: Container(
                            color: primaryAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayBubble({
    required String letter,
    required bool isToday,
    required bool hasRead,
    required Color accentColor,
    required FoliateThemeColors colors,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: hasRead
            ? accentColor.withValues(alpha: 0.25)
            : const Color(0xFF1E2027),
        shape: BoxShape.circle,
        border: isToday
            ? Border.all(color: accentColor, width: 2.0)
            : Border.all(
                color: hasRead
                    ? accentColor.withValues(alpha: 0.6)
                    : colors.border.withValues(alpha: 0.3),
                width: 1.0,
              ),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isToday || hasRead ? FontWeight.bold : FontWeight.w500,
            color: isToday
                ? Colors.white
                : (hasRead ? accentColor : colors.textMuted),
          ),
        ),
      ),
    );
  }
}

/// Custom painter rendering a semicircular arch gauge matching Apple Books.
/// Arc spans 180 degrees over the top, from PI (9 o'clock) clockwise to 2*PI (3 o'clock).
class _ArchGaugePainter extends CustomPainter {
  final double fraction;
  final Color trackColor;
  final Color progressColor;

  _ArchGaugePainter({
    required this.fraction,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 7.5;
    // Radius of the arch
    final radius = (size.width / 2) - strokeWidth;
    // Center is horizontally centered, and vertically at the base of the arc
    final center = Offset(size.width / 2, size.height - strokeWidth);

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track arc: 180 degrees over the top
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(rect, math.pi, math.pi, false, trackPaint);

    // Progress arc: clockwise from PI
    final clampedFraction = fraction.clamp(0.0, 1.0);
    if (clampedFraction > 0) {
      final sweepAngle = math.pi * clampedFraction;
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      canvas.drawArc(rect, math.pi, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArchGaugePainter oldDelegate) {
    return oldDelegate.fraction != fraction ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
