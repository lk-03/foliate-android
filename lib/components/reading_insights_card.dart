import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/theme.dart';

/// Reading habits dashboard card displaying daily goal ring, streak counter,
/// weekly consistency bubbles, and annual reading challenge progress.
class ReadingInsightsCard extends StatelessWidget {
  final ReadingHabits habits;
  final ValueChanged<int>? onDailyGoalChanged;
  final ValueChanged<int>? onYearlyGoalChanged;

  const ReadingInsightsCard({
    super.key,
    required this.habits,
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
          title: Text('${DateTime.now().year} Reading Challenge', style: const TextStyle(fontSize: 16)),
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
    final weekLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final currentYear = DateTime.now().year;

    final booksDone = habits.booksFinishedThisYear.length;
    final targetBooks = habits.yearlyGoalBooks;
    final yearlyPercent = (habits.yearlyProgressFraction * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header: Reading Insights Title & Flame Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.insights_rounded,
                    size: 18,
                    color: primaryAccent,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Reading Insights',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              // Day Streak Flame Counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AdwaitaColors.amberStreak.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
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
                      '${habits.currentStreak} Day Streak',
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

          const SizedBox(height: 18),

          // Daily Goal & Streak Summary Cards (2-Columns)
          Row(
            children: [
              // 1. Daily Reading Goal Card
              Expanded(
                child: InkWell(
                  onTap: () => _showDailyGoalDialog(context),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.inputBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        // Circular Progress Ring
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(44, 44),
                                painter: _GoalRingPainter(
                                  fraction: habits.dailyGoalFraction,
                                  trackColor: colors.border,
                                  progressColor: primaryAccent,
                                ),
                              ),
                              Icon(
                                habits.isDailyGoalAchieved
                                    ? Icons.check_rounded
                                    : Icons.timer_outlined,
                                size: 18,
                                color: primaryAccent,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  text: '${habits.todayMinutesRead}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '/${habits.dailyGoalMinutes}m',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.normal,
                                        color: colors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Daily Goal',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Right: Day Streak Flame Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AdwaitaColors.amberStreak.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.local_fire_department_rounded,
                            size: 24,
                            color: AdwaitaColors.amberStreak,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${habits.currentStreak}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Day streak',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Weekly Consistency Checkmark Bubbles (M, T, W, T, F, S, S)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.inputBackground.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (int i = 0; i < 7; i++) ...[
                  _buildDayBubble(
                    colors: colors,
                    letter: weekLetters[i],
                    isActive: weekActivity[i + 1] ?? false,
                    accentColor: primaryAccent,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Annual Reading Challenge Card
          InkWell(
            onTap: () => _showYearlyGoalDialog(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.inputBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border.withValues(alpha: 0.5)),
              ),
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
                            size: 16,
                            color: primaryAccent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$currentYear Challenge',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
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
                  const SizedBox(height: 8),

                  // Gradient Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 6,
                      color: colors.border,
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: habits.yearlyProgressFraction,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryAccent.withValues(alpha: 0.65),
                                primaryAccent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Status Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$yearlyPercent% of annual goal',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textMuted,
                        ),
                      ),
                      Text(
                        booksDone >= targetBooks ? 'Goal achieved!' : 'Keep reading',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: booksDone >= targetBooks
                              ? primaryAccent
                              : colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayBubble({
    required FoliateThemeColors colors,
    required String letter,
    required bool isActive,
    required Color accentColor,
  }) {
    final activeColor = accentColor;

    return Column(
      children: [
        Text(
          letter,
          style: TextStyle(
            fontSize: 11,
            color: colors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isActive
                ? activeColor
                : colors.border.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive
                ? const Text(
                    '✓',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

/// Custom painter rendering smooth circular daily progress ring
class _GoalRingPainter extends CustomPainter {
  final double fraction;
  final Color trackColor;
  final Color progressColor;

  _GoalRingPainter({
    required this.fraction,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 3.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    canvas.drawCircle(center, radius, trackPaint);

    final sweepAngle = 2 * math.pi * fraction.clamp(0.0, 1.0);
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GoalRingPainter oldDelegate) {
    return oldDelegate.fraction != fraction ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
