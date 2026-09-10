import 'package:flutter_test/flutter_test.dart';
import 'package:foliate/models/models.dart';
import 'package:foliate/services/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReadingHabits Model Unit Tests', () {
    test('ReadingHabits serialization round-trip', () {
      final habits = ReadingHabits(
        dailyGoalMinutes: 30,
        currentStreak: 5,
        longestStreak: 12,
        lastActiveDate: '2026-09-09',
        dailyHistory: const {
          '2026-09-08': 25,
          '2026-09-09': 35,
        },
        yearlyGoalBooks: 20,
        booksFinishedThisYear: const ['hash-book-1', 'hash-book-2'],
        totalReadingSeconds: 3600,
        totalSessions: 8,
      );

      final jsonStr = habits.toJson();
      final restored = ReadingHabits.fromJson(jsonStr);

      expect(restored.dailyGoalMinutes, equals(30));
      expect(restored.currentStreak, equals(5));
      expect(restored.longestStreak, equals(12));
      expect(restored.lastActiveDate, equals('2026-09-09'));
      expect(restored.dailyHistory['2026-09-09'], equals(35));
      expect(restored.yearlyGoalBooks, equals(20));
      expect(restored.booksFinishedThisYear.length, equals(2));
      expect(restored.totalReadingSeconds, equals(3600));
      expect(restored.totalSessions, equals(8));
    });

    test('Streak increments correctly across consecutive dates', () {
      const initial = ReadingHabits();
      final day1 = DateTime(2026, 9, 1);
      final day2 = DateTime(2026, 9, 2);
      final day3 = DateTime(2026, 9, 3);
      final day5 = DateTime(2026, 9, 5); // Missed day 4

      // Day 1: First session
      final session1 = initial.recordSession(600, now: day1); // 10 mins
      expect(session1.currentStreak, equals(1));
      expect(session1.longestStreak, equals(1));
      expect(session1.lastActiveDate, equals('2026-09-01'));
      expect(session1.getMinutesForDate(day1), equals(10));

      // Day 1: Second session on same day maintains streak
      final session1b = session1.recordSession(600, now: day1);
      expect(session1b.currentStreak, equals(1));
      expect(session1b.getMinutesForDate(day1), equals(20));

      // Day 2: Consecutive day reading increments streak to 2
      final session2 = session1b.recordSession(900, now: day2);
      expect(session2.currentStreak, equals(2));
      expect(session2.longestStreak, equals(2));
      expect(session2.lastActiveDate, equals('2026-09-02'));

      // Day 3: Consecutive day reading increments streak to 3
      final session3 = session2.recordSession(1200, now: day3);
      expect(session3.currentStreak, equals(3));
      expect(session3.longestStreak, equals(3));

      // Day 5: Missed Day 4 -> Streak resets to 1, longest remains 3
      final session5 = session3.recordSession(600, now: day5);
      expect(session5.currentStreak, equals(1));
      expect(session5.longestStreak, equals(3));
      expect(session5.lastActiveDate, equals('2026-09-05'));
    });

    test('Daily goal progress and achievement evaluation', () {
      final date = DateTime.now();
      final dateStr = ReadingHabits.formatDate(date);
      final habits = ReadingHabits(
        dailyGoalMinutes: 15,
        dailyHistory: {
          dateStr: 10,
        },
      );

      expect(habits.getMinutesForDate(date), equals(10));
      expect(habits.dailyGoalFraction, closeTo(0.66, 0.02));

      // Record 5 more minutes (300 seconds)
      final updated = habits.recordSession(300, now: date);
      expect(updated.getMinutesForDate(date), equals(15));
      expect(updated.dailyGoalFraction, equals(1.0));
      expect(updated.isDailyGoalAchieved, isTrue);
    });

    test('Annual challenge books tracking', () {
      const habits = ReadingHabits(
        yearlyGoalBooks: 10,
        booksFinishedThisYear: ['book-1', 'book-2'],
      );

      expect(habits.yearlyProgressFraction, closeTo(0.2, 0.01));

      final updated = habits.markBookFinished('book-3');
      expect(updated.booksFinishedThisYear.length, equals(3));
      expect(updated.yearlyProgressFraction, closeTo(0.3, 0.01));

      // Duplicate mark does not add duplicate
      final duplicate = updated.markBookFinished('book-3');
      expect(duplicate.booksFinishedThisYear.length, equals(3));
    });

    test('Week activity map reports active reading days', () {
      final wednesday = DateTime(2026, 9, 9); // Wednesday (weekday 3)
      final habits = ReadingHabits(
        dailyHistory: {
          '2026-09-07': 15, // Monday (weekday 1)
          '2026-09-09': 20, // Wednesday (weekday 3)
        },
      );

      final weekMap = habits.getWeekActivityMap(wednesday);
      expect(weekMap[1], isTrue); // Monday
      expect(weekMap[2], isFalse); // Tuesday
      expect(weekMap[3], isTrue); // Wednesday
      expect(weekMap[4], isFalse); // Thursday
    });
  });

  group('StorageService Habits Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('StorageService persists and retrieves reading habits', () async {
      final habits = await StorageService.instance.getReadingHabits();
      expect(habits.dailyGoalMinutes, equals(15));
      expect(habits.currentStreak, equals(0));

      final recorded = await StorageService.instance.recordReadingTime(180); // 3 mins
      expect(recorded.totalReadingSeconds, equals(180));
      expect(recorded.currentStreak, equals(1));

      final updatedDaily = await StorageService.instance.updateDailyReadingGoal(30);
      expect(updatedDaily.dailyGoalMinutes, equals(30));

      final updatedYearly = await StorageService.instance.updateYearlyReadingGoal(15);
      expect(updatedYearly.yearlyGoalBooks, equals(15));

      final finished = await StorageService.instance.markBookFinished('hash-finished-1');
      expect(finished.booksFinishedThisYear, contains('hash-finished-1'));
    });
  });
}
