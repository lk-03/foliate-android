import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/theme.dart';

/// Flat reading insights section combining a circular chronometer gauge
/// for daily reading goals with a 7-day streak consistency tracker and
/// annual reading challenge bar.
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

  String _getChallengePaceStatus(int done, int target) {
    if (done >= target) return 'Goal reached!';
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    final expected = (dayOfYear / 365.0) * target;
    final diff = done - expected;
    if (diff >= 0.75) {
      return 'On track (+${diff.round()} ahead)';
    } else if (diff <= -0.75) {
      return '${(-diff).round()} behind pace';
    } else {
      return 'On track';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FoliateThemeColors>() ??
        FoliateThemeColors.dark;
    final primaryAccent = Theme.of(context).colorScheme.primary;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysSinceSunday = today.weekday % 7;
    final sunday = today.subtract(Duration(days: daysSinceSunday));
    const weekLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    final currentYear = now.year;
    final booksDone = habits.booksFinishedThisYear.length;
    final targetBooks = habits.yearlyGoalBooks;
    final remainingMinutes = habits.dailyGoalMinutes - habits.todayMinutesRead;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Row: Category Badge + Title & Adjust Goal Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'READING VELOCITY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Reading Insights',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'serif',
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showDailyGoalDialog(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.inputBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.border.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 13,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Adjust Goal',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 2. Circle Tracker Row (Circular Gauge + Stats + Resume Chapter Button)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular Gauge with Today's Minutes inside
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(96, 96),
                      painter: _CircleTrackerPainter(
                        fraction: habits.dailyGoalFraction,
                        trackColor: const Color(0xFF222634),
                        progressColor: primaryAccent,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${habits.todayMinutesRead}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            height: 1.05,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'MIN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: primaryAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Stats and Action Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TODAY'S READING",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${(habits.dailyGoalFraction * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'of ${habits.dailyGoalMinutes}m daily goal',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.hourglass_empty_rounded,
                          size: 13,
                          color: primaryAccent,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            remainingMinutes > 0
                                ? '$remainingMinutes mins left to complete'
                                : 'Daily goal completed!',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Orange Solid Pill Action Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onKeepReading,
                        borderRadius: BorderRadius.circular(19),
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: primaryAccent,
                            borderRadius: BorderRadius.circular(19),
                            boxShadow: [
                              BoxShadow(
                                color: primaryAccent.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_stories_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                activeBook != null ? 'Resume Chapter' : 'Keep Reading',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 3. Keep Reading Strip (from Bar Version reference)
          if (activeBook != null) ...[
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onKeepReading,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: colors.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.border.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: primaryAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Keep Reading: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textMuted,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          activeBook!.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Jump in',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primaryAccent,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: primaryAccent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 18),

          // 4. Day Streak Section (S M T W T F S with Checkmarks and Streak Flame)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showDailyGoalDialog(context),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  children: [
                    // Weekday Letters & Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (int i = 0; i < 7; i++) ...[
                          _buildDayItem(
                            letter: weekLetters[i],
                            dayDate: sunday.add(Duration(days: i)),
                            today: today,
                            dailyHistory: habits.dailyHistory,
                            accentColor: primaryAccent,
                            colors: colors,
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Streak Flame & Record Summary Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              size: 16,
                              color: Color(0xFFFF7A18),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              habits.currentStreak > 0
                                  ? '${habits.currentStreak}-day streak active'
                                  : 'Start a new streak',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'Best ',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textMuted,
                              ),
                            ),
                            Text(
                              '${habits.longestStreak}d',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primaryAccent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 5. Annual Reading Challenge Section
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showYearlyGoalDialog(context),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
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
                              size: 15,
                              color: primaryAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$currentYear Challenge',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
                    const SizedBox(height: 9),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Container(
                        height: 5,
                        color: colors.border.withValues(alpha: 0.25),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: habits.yearlyProgressFraction,
                          child: Container(
                            decoration: BoxDecoration(
                              color: primaryAccent,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(habits.yearlyProgressFraction * 100).round()}% of annual goal',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textMuted,
                          ),
                        ),
                        Text(
                          _getChallengePaceStatus(booksDone, targetBooks),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: primaryAccent,
                          ),
                        ),
                      ],
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

  Widget _buildDayItem({
    required String letter,
    required DateTime dayDate,
    required DateTime today,
    required Map<String, int> dailyHistory,
    required Color accentColor,
    required FoliateThemeColors colors,
  }) {
    final dateKey = ReadingHabits.formatDate(dayDate);
    final isToday = dayDate.isAtSameMomentAs(today);
    final isPast = dayDate.isBefore(today);
    final minutes = dailyHistory[dateKey] ?? 0;
    final hasRead = minutes > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          letter,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
            color: isToday ? accentColor : colors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: hasRead
                ? accentColor
                : const Color(0xFF1D222E),
            shape: BoxShape.circle,
            border: isToday && !hasRead
                ? Border.all(color: accentColor, width: 1.5)
                : Border.all(
                    color: hasRead
                        ? accentColor
                        : colors.border.withValues(alpha: 0.2),
                    width: 1.0,
                  ),
          ),
          child: Center(
            child: hasRead
                ? const Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: Colors.white,
                  )
                : isPast
                    ? Text(
                        '-',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                          color: colors.textMuted,
                        ),
                      )
                    : isToday
                        ? Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                          )
                        : Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colors.textMuted.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                          ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter rendering a circular chronometer gauge with an indicator dot.
class _CircleTrackerPainter extends CustomPainter {
  final double fraction;
  final Color trackColor;
  final Color progressColor;

  _CircleTrackerPainter({
    required this.fraction,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 7.5;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track circle (360 degrees)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    final clampedFraction = fraction.clamp(0.0, 1.0);
    if (clampedFraction > 0) {
      const startAngle = -math.pi / 2; // 12 o'clock position
      final sweepAngle = 2 * math.pi * clampedFraction;

      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);

      // Tip indicator dot matching the reference chronometer
      final endAngle = startAngle + sweepAngle;
      final tipCenter = Offset(
        center.dx + radius * math.cos(endAngle),
        center.dy + radius * math.sin(endAngle),
      );

      // Outer glow circle
      final glowPaint = Paint()
        ..color = progressColor.withValues(alpha: 0.45)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(tipCenter, 5.5, glowPaint);

      // Inner solid dot
      final dotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(tipCenter, 3.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircleTrackerPainter oldDelegate) {
    return oldDelegate.fraction != fraction ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
