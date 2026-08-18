import 'dart:math';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../models/habit_frequency_type.dart';
import '../models/habit_log.dart';
import '../models/habit_target_type.dart';

class StreakResult {
  final int currentStreak;
  final int bestStreak;
  final int completionRate30Days;
  final int totalCompletions; // day-level completions; for WEEKLY also exposes week meets

  const StreakResult({
    required this.currentStreak,
    required this.bestStreak,
    required this.completionRate30Days,
    required this.totalCompletions,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreakResult &&
          runtimeType == other.runtimeType &&
          currentStreak == other.currentStreak &&
          bestStreak == other.bestStreak &&
          completionRate30Days == other.completionRate30Days &&
          totalCompletions == other.totalCompletions;

  @override
  int get hashCode =>
      currentStreak.hashCode ^
      bestStreak.hashCode ^
      completionRate30Days.hashCode ^
      totalCompletions.hashCode;

  @override
  String toString() =>
      'StreakResult(currentStreak: $currentStreak, bestStreak: $bestStreak, completionRate30Days: $completionRate30Days%, totalCompletions: $totalCompletions)';
}

class StreakCalculator {
  static final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');

  static DateTime isoWeekStart(DateTime date) {
    // In Dart, DateTime.weekday: 1 = Monday, ..., 7 = Sunday
    final daysToSubtract = date.weekday - DateTime.monday;
    final monday = date.subtract(Duration(days: daysToSubtract));
    return DateTime(monday.year, monday.month, monday.day);
  }

  static bool isHabitScheduledOnDate(Habit habit, DateTime date) {
    switch (habit.frequencyType) {
      case HabitFrequencyType.daily:
        return true;
      case HabitFrequencyType.customDays:
        // 0 = Sunday, 1 = Monday, ... 6 = Saturday
        final dayOfWeek = date.weekday == DateTime.sunday ? 0 : date.weekday;
        return habit.targetDaysOfWeek?.contains(dayOfWeek) == true;
      case HabitFrequencyType.weekly:
        return true; // loggable any day; week success uses targetCountPerWeek
      case HabitFrequencyType.subdayInterval:
      case HabitFrequencyType.timesPerDay:
        return true;
    }
  }

  static bool isHabitCompletedOnDate(Habit habit, List<HabitLog> logs) {
    if (logs.isEmpty) return false;

    switch (habit.targetType) {
      case HabitTargetType.boolean:
        switch (habit.frequencyType) {
          case HabitFrequencyType.subdayInterval:
          case HabitFrequencyType.timesPerDay:
            final requiredSlots = habit.timesPerDay ?? habit.targetValue?.toInt() ?? 1;
            final completedSlots = logs
                .where((l) => l.completed)
                .map((l) => l.intervalIndex)
                .where((idx) => idx != null)
                .toSet()
                .length;
            return completedSlots >= requiredSlots;
          default:
            return logs.any((l) => l.completed);
        }

      case HabitTargetType.numeric:
        final target = habit.targetValue ?? 1.0;
        final totalValue = logs.fold<double>(
          0.0,
          (sum, log) => sum + (log.value ?? (log.completed ? target : 0.0)),
        );
        return totalValue >= target;

      case HabitTargetType.timer:
        final targetMinutes = habit.targetValue ?? 25.0;
        final totalMinutes = logs.fold<double>(
          0.0,
          (sum, log) {
            if (log.durationSeconds != null && log.durationSeconds! > 0) {
              return sum + (log.durationSeconds! / 60.0);
            } else {
              return sum + (log.value ?? (log.completed ? targetMinutes : 0.0));
            }
          },
        );
        return totalMinutes >= targetMinutes;
    }
  }

  static bool isWeeklyTargetMet(
    Habit habit,
    Map<String, List<HabitLog>> logsByDate,
    DateTime weekStart,
  ) {
    final required = habit.targetCountPerWeek ?? 1;
    var completedDays = 0;
    for (var offset = 0; offset < 7; offset++) {
      final date = weekStart.add(Duration(days: offset));
      final dateStr = dateFormatter.format(date);
      final dayLogs = logsByDate[dateStr] ?? const [];
      if (isHabitCompletedOnDate(habit, dayLogs)) {
        completedDays++;
      }
    }
    return completedDays >= required;
  }

  static StreakResult calculateStreak(
    Habit habit,
    List<HabitLog> allLogs, [
    DateTime? referenceDate,
  ]) {
    final ref = referenceDate ?? DateTime.now();
    final refDate = DateTime(ref.year, ref.month, ref.day);

    final logsByDate = <String, List<HabitLog>>{};
    for (final log in allLogs) {
      if (log.habitId == habit.id) {
        logsByDate.putIfAbsent(log.date, () => []).add(log);
      }
    }

    if (habit.frequencyType == HabitFrequencyType.weekly) {
      return calculateWeeklyStreak(habit, logsByDate, refDate);
    }

    var currentStreak = 0;
    var bestStreak = 0;
    var tempStreak = 0;
    var totalCompletions = 0;

    var scheduledDaysIn30 = 0;
    var completedDaysIn30 = 0;

    for (var i = 0; i < 30; i++) {
      final checkDate = refDate.subtract(Duration(days: i));
      final dateStr = dateFormatter.format(checkDate);
      final isScheduled = isHabitScheduledOnDate(habit, checkDate);

      if (isScheduled) {
        scheduledDaysIn30++;
        final dayLogs = logsByDate[dateStr] ?? const [];
        if (isHabitCompletedOnDate(habit, dayLogs)) {
          completedDaysIn30++;
        }
      }
    }

    final completionRate30Days = scheduledDaysIn30 > 0
        ? ((completedDaysIn30 / scheduledDaysIn30) * 100).round()
        : 0;

    var checkDate = refDate;
    var isCurrentStreakChain = true;

    final refDateStr = dateFormatter.format(refDate);
    final refLogs = logsByDate[refDateStr] ?? const [];
    final refCompleted = isHabitCompletedOnDate(habit, refLogs);

    // In-progress preservation: If today is not completed but is scheduled, start evaluating streak from yesterday
    if (!refCompleted && isHabitScheduledOnDate(habit, refDate)) {
      checkDate = refDate.subtract(const Duration(days: 1));
    }

    for (var i = 0; i < 365; i++) {
      final dateStr = dateFormatter.format(checkDate);
      final isScheduled = isHabitScheduledOnDate(habit, checkDate);

      if (isScheduled) {
        final dayLogs = logsByDate[dateStr] ?? const [];
        final completed = isHabitCompletedOnDate(habit, dayLogs);

        if (completed) {
          totalCompletions++;
          tempStreak++;
          if (isCurrentStreakChain) {
            currentStreak++;
          }
          if (tempStreak > bestStreak) {
            bestStreak = tempStreak;
          }
        } else {
          isCurrentStreakChain = false;
          tempStreak = 0;
        }
      }
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return StreakResult(
      currentStreak: currentStreak,
      bestStreak: max(bestStreak, currentStreak),
      completionRate30Days: completionRate30Days,
      totalCompletions: totalCompletions,
    );
  }

  static StreakResult calculateWeeklyStreak(
    Habit habit,
    Map<String, List<HabitLog>> logsByDate,
    DateTime referenceDate,
  ) {
    var currentStreak = 0;
    var bestStreak = 0;
    var tempStreak = 0;
    var totalCompletions = 0;

    final windowStart = referenceDate.subtract(const Duration(days: 29));
    final weeksInWindow = <DateTime>{};
    var cursor = windowStart;
    while (!cursor.isAfter(referenceDate)) {
      weeksInWindow.add(isoWeekStart(cursor));
      cursor = cursor.add(const Duration(days: 1));
    }

    final metWeeksInWindow = weeksInWindow.where((week) => isWeeklyTargetMet(habit, logsByDate, week)).length;
    final completionRate30Days = weeksInWindow.isNotEmpty
        ? ((metWeeksInWindow / weeksInWindow.length) * 100).round()
        : 0;

    var weekStart = isoWeekStart(referenceDate);
    var isCurrentStreakChain = true;
    final currentWeekMet = isWeeklyTargetMet(habit, logsByDate, weekStart);
    if (!currentWeekMet) {
      // In-progress week: do not break streak until the week ends unmet
      weekStart = weekStart.subtract(const Duration(days: 7));
    }

    for (var i = 0; i < 52; i++) {
      final met = isWeeklyTargetMet(habit, logsByDate, weekStart);
      // Count day-level completions inside the week for totalCompletions
      for (var offset = 0; offset < 7; offset++) {
        final dateStr = dateFormatter.format(weekStart.add(Duration(days: offset)));
        final dayLogs = logsByDate[dateStr] ?? const [];
        if (isHabitCompletedOnDate(habit, dayLogs)) {
          totalCompletions++;
        }
      }

      if (met) {
        tempStreak++;
        if (isCurrentStreakChain) {
          currentStreak++;
        }
        if (tempStreak > bestStreak) {
          bestStreak = tempStreak;
        }
      } else {
        isCurrentStreakChain = false;
        tempStreak = 0;
      }
      weekStart = weekStart.subtract(const Duration(days: 7));
    }

    return StreakResult(
      currentStreak: currentStreak,
      bestStreak: max(bestStreak, currentStreak),
      completionRate30Days: completionRate30Days,
      totalCompletions: totalCompletions,
    );
  }
}
