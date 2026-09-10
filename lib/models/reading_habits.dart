import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Encapsulates reading habits, daily goals, streaks, and annual reading challenge metrics.
@immutable
class ReadingHabits {
  final int dailyGoalMinutes;
  final int currentStreak;
  final int longestStreak;
  final String? lastActiveDate;
  final Map<String, int> dailyHistory; // YYYY-MM-DD -> minutes read
  final int yearlyGoalBooks;
  final List<String> booksFinishedThisYear; // Book SHA-256 hashes
  final Map<String, List<String>> yearlyFinishedBooks; // Year -> List of Book SHA-256 hashes
  final int totalReadingSeconds;
  final int totalSessions;

  const ReadingHabits({
    this.dailyGoalMinutes = 15,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.dailyHistory = const {},
    this.yearlyGoalBooks = 12,
    this.booksFinishedThisYear = const [],
    this.yearlyFinishedBooks = const {},
    this.totalReadingSeconds = 0,
    this.totalSessions = 0,
  });

  /// Formats a DateTime into canonical YYYY-MM-DD string
  static String formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Minutes read on a given date (defaults to today)
  int getMinutesForDate([DateTime? date]) {
    final key = formatDate(date ?? DateTime.now());
    return dailyHistory[key] ?? 0;
  }

  /// Minutes read today
  int get todayMinutesRead => getMinutesForDate(DateTime.now());

  /// Whether today's reading goal was achieved
  bool get isDailyGoalAchieved => todayMinutesRead >= dailyGoalMinutes;

  /// Progress towards daily goal (0.0 to 1.0+)
  double get dailyGoalFraction {
    if (dailyGoalMinutes <= 0) return 1.0;
    return (todayMinutesRead / dailyGoalMinutes).clamp(0.0, 1.0);
  }

  /// Annual challenge progress fraction (0.0 to 1.0)
  double get yearlyProgressFraction {
    if (yearlyGoalBooks <= 0) return 1.0;
    return (booksFinishedThisYear.length / yearlyGoalBooks).clamp(0.0, 1.0);
  }

  /// Calculates whether each day of the current week (Monday=1..Sunday=7) was active
  Map<int, bool> getWeekActivityMap([DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime.now();
    // In Dart, weekday: 1 = Monday, 7 = Sunday
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final activity = <int, bool>{};

    for (int i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      final dateKey = formatDate(day);
      final minutes = dailyHistory[dateKey] ?? 0;
      activity[i + 1] = minutes > 0;
    }
    return activity;
  }

  /// Records reading time in seconds and returns updated ReadingHabits
  ReadingHabits recordSession(int durationSeconds, {DateTime? now}) {
    if (durationSeconds <= 0) return this;

    final currentDt = now ?? DateTime.now();
    final todayKey = formatDate(currentDt);
    final previousMinutes = dailyHistory[todayKey] ?? 0;
    final additionalMinutes = (durationSeconds / 60).ceil();
    final newTodayMinutes = previousMinutes + additionalMinutes;

    final updatedHistory = Map<String, int>.from(dailyHistory);
    updatedHistory[todayKey] = newTodayMinutes;

    // Calculate streak
    int newStreak = currentStreak;
    int newLongest = longestStreak;

    if (lastActiveDate == null) {
      newStreak = 1;
    } else if (lastActiveDate == todayKey) {
      // Already read today, maintain streak
      newStreak = currentStreak == 0 ? 1 : currentStreak;
    } else {
      final yesterday = currentDt.subtract(const Duration(days: 1));
      final yesterdayKey = formatDate(yesterday);

      if (lastActiveDate == yesterdayKey) {
        // Read yesterday -> increment consecutive streak
        newStreak = currentStreak + 1;
      } else {
        // Missed one or more days -> reset streak to 1
        newStreak = 1;
      }
    }

    if (newStreak > newLongest) {
      newLongest = newStreak;
    }

    return copyWith(
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastActiveDate: todayKey,
      dailyHistory: updatedHistory,
      totalReadingSeconds: totalReadingSeconds + durationSeconds,
      totalSessions: totalSessions + 1,
    );
  }

  /// Marks a book as completed in the annual reading challenge for a given year
  ReadingHabits markBookFinished(String bookHash, {int? year}) {
    final targetYear = (year ?? DateTime.now().year).toString();
    final baseList = yearlyFinishedBooks[targetYear] ??
        (targetYear == DateTime.now().year.toString()
            ? booksFinishedThisYear
            : const <String>[]);

    if (baseList.contains(bookHash)) {
      return this;
    }

    final yearList = List<String>.from(baseList)..add(bookHash);
    final updatedYearly = Map<String, List<String>>.from(yearlyFinishedBooks);
    updatedYearly[targetYear] = yearList;

    final updatedThisYear = targetYear == DateTime.now().year.toString()
        ? yearList
        : (booksFinishedThisYear.contains(bookHash)
            ? booksFinishedThisYear
            : (List<String>.from(booksFinishedThisYear)..add(bookHash)));

    return copyWith(
      yearlyFinishedBooks: updatedYearly,
      booksFinishedThisYear: updatedThisYear,
    );
  }

  /// Returns the finished book hashes for a specific year
  List<String> getFinishedBooksForYear(int year) {
    final yearKey = year.toString();
    if (yearlyFinishedBooks.containsKey(yearKey)) {
      return yearlyFinishedBooks[yearKey] ?? const [];
    }
    if (year == DateTime.now().year) {
      return booksFinishedThisYear;
    }
    return const [];
  }

  ReadingHabits copyWith({
    int? dailyGoalMinutes,
    int? currentStreak,
    int? longestStreak,
    String? lastActiveDate,
    Map<String, int>? dailyHistory,
    int? yearlyGoalBooks,
    List<String>? booksFinishedThisYear,
    Map<String, List<String>>? yearlyFinishedBooks,
    int? totalReadingSeconds,
    int? totalSessions,
  }) {
    return ReadingHabits(
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      dailyHistory: dailyHistory ?? this.dailyHistory,
      yearlyGoalBooks: yearlyGoalBooks ?? this.yearlyGoalBooks,
      booksFinishedThisYear:
          booksFinishedThisYear ?? this.booksFinishedThisYear,
      yearlyFinishedBooks:
          yearlyFinishedBooks ?? this.yearlyFinishedBooks,
      totalReadingSeconds: totalReadingSeconds ?? this.totalReadingSeconds,
      totalSessions: totalSessions ?? this.totalSessions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dailyGoalMinutes': dailyGoalMinutes,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActiveDate': lastActiveDate,
      'dailyHistory': dailyHistory,
      'yearlyGoalBooks': yearlyGoalBooks,
      'booksFinishedThisYear': booksFinishedThisYear,
      'yearlyFinishedBooks': yearlyFinishedBooks,
      'totalReadingSeconds': totalReadingSeconds,
      'totalSessions': totalSessions,
    };
  }

  factory ReadingHabits.fromMap(Map<String, dynamic> map) {
    final rawThisYear = (map['booksFinishedThisYear'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];

    final rawYearly = map['yearlyFinishedBooks'];
    final Map<String, List<String>> parsedYearly = {};
    if (rawYearly is Map) {
      rawYearly.forEach((k, v) {
        if (v is List) {
          parsedYearly[k.toString()] =
              v.map((e) => e.toString()).toList();
        }
      });
    }

    // Ensure current year is populated if booksFinishedThisYear exists
    final currentYearKey = DateTime.now().year.toString();
    if (parsedYearly[currentYearKey] == null && rawThisYear.isNotEmpty) {
      parsedYearly[currentYearKey] = List<String>.from(rawThisYear);
    }

    return ReadingHabits(
      dailyGoalMinutes: (map['dailyGoalMinutes'] as num?)?.toInt() ?? 15,
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (map['longestStreak'] as num?)?.toInt() ?? 0,
      lastActiveDate: map['lastActiveDate'] as String?,
      dailyHistory: map['dailyHistory'] != null
          ? Map<String, int>.from(
              (map['dailyHistory'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num).toInt()),
              ),
            )
          : const {},
      yearlyGoalBooks: (map['yearlyGoalBooks'] as num?)?.toInt() ?? 12,
      booksFinishedThisYear: rawThisYear,
      yearlyFinishedBooks: parsedYearly,
      totalReadingSeconds:
          (map['totalReadingSeconds'] as num?)?.toInt() ?? 0,
      totalSessions: (map['totalSessions'] as num?)?.toInt() ?? 0,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ReadingHabits.fromJson(String source) =>
      ReadingHabits.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
