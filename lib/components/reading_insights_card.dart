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
                    selectedColor: AdwaitaColors.terracottaAccent,
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
                    selectedColor: AdwaitaColors.terracottaAccent,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR PROGRESS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AdwaitaColors.amberStreak,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Reading Insights',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded, size: 20),
                tooltip: 'Configure Reading Goals',
                onPressed: () => _showDailyGoalDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2-Column Progress Grid (Daily Goal + Day Streak)
          Row(
            children: [
              // Left: Daily Goal Ring Card
              Expanded(
                child: InkWell(
                  onTap: () => _showDailyGoalDialog(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.inputBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        // Circular Ring
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
                                  progressColor: habits.isDailyGoalAchieved
                                      ? AdwaitaColors.foliateGreen
                                      : AdwaitaColors.terracottaAccent,
                                ),
                              ),
                              Icon(
                                habits.isDailyGoalAchieved
                                    ? Icons.check_rounded
                                    : Icons.timer_outlined,
                                size: 18,
                                color: habits.isDailyGoalAchieved
                                    ? AdwaitaColors.foliateGreen
                                    : AdwaitaColors.terracottaAccent,
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
                            color: AdwaitaColors.terracottaAccent,
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
                          color: AdwaitaColors.terracottaAccent,
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
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AdwaitaColors.amberStreak,
                                AdwaitaColors.terracottaAccent,
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
                              ? AdwaitaColors.foliateGreen
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
  }) {
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
                ? AdwaitaColors.terracottaAccent
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
