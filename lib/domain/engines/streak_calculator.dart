import 'dart:math';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../models/habit_frequency_type.dart';
import '../models/habit_log.dart';
import '../models/habit_shield.dart';
import '../models/habit_target_type.dart';
import '../models/habit_tier.dart';

class StreakResult {
  final int currentStreak;
  final int bestStreak;
  final int completionRate30Days;
  final int totalCompletions; // day-level completions; for WEEKLY also exposes week meets
  final int totalShieldedDays; // protected days within evaluated history

  const StreakResult({
    required this.currentStreak,
    required this.bestStreak,
    required this.completionRate30Days,
    required this.totalCompletions,
    this.totalShieldedDays = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreakResult &&
          runtimeType == other.runtimeType &&
          currentStreak == other.currentStreak &&
          bestStreak == other.bestStreak &&
          completionRate30Days == other.completionRate30Days &&
          totalCompletions == other.totalCompletions &&
          totalShieldedDays == other.totalShieldedDays;

  @override
  int get hashCode =>
      currentStreak.hashCode ^
      bestStreak.hashCode ^
      completionRate30Days.hashCode ^
      totalCompletions.hashCode ^
      totalShieldedDays.hashCode;

  @override
  String toString() =>
      'StreakResult(currentStreak: $currentStreak, bestStreak: $bestStreak, completionRate30Days: $completionRate30Days%, totalCompletions: $totalCompletions, shielded: $totalShieldedDays)';
}

class StreakCalculator {
  static final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');

  /// Fast ISO-8601 date string generation (yyyy-MM-dd) avoiding DateFormat overhead.
  static String formatIsoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime isoWeekStart(DateTime date) {
    // In Dart, DateTime.weekday: 1 = Monday, ..., 7 = Sunday
    final daysToSubtract = date.weekday - DateTime.monday;
    final monday = date.subtract(Duration(days: daysToSubtract));
    return DateTime(monday.year, monday.month, monday.day);
  }

  static bool isHabitScheduledOnDate(
    Habit habit,
    DateTime date, [
    DateTime? referenceDate,
  ]) {
    if (habit.isNegative) {
      final cleanStart = habit.cleanSince ?? habit.createdAt;
      final cleanStartDate =
          DateTime(cleanStart.year, cleanStart.month, cleanStart.day);
      final evalDate = DateTime(date.year, date.month, date.day);
      final ref = referenceDate ?? DateTime.now();
      final todayDate = DateTime(ref.year, ref.month, ref.day);
      if (evalDate.isBefore(cleanStartDate) || evalDate.isAfter(todayDate)) {
        return false;
      }
      return true;
    }

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

  static HabitTier resolveAchievedTier(Habit habit, List<HabitLog> logs) {
    if (logs.isEmpty) return HabitTier.none;

    // Check if any log explicitly specifies a tier
    HabitTier explicitTier = HabitTier.none;
    for (final log in logs) {
      if (log.completed && log.targetTier != null) {
        if (log.targetTier!.index > explicitTier.index) {
          explicitTier = log.targetTier!;
        }
      }
    }

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
            if (completedSlots >= requiredSlots) {
              return explicitTier.index > HabitTier.base.index ? explicitTier : HabitTier.base;
            } else if (completedSlots > 0 && habit.miniTargetValue != null && habit.miniTargetValue! <= 1.0) {
              return explicitTier.index > HabitTier.mini.index ? explicitTier : HabitTier.mini;
            }
            return explicitTier != HabitTier.none ? explicitTier : HabitTier.none;
          default:
            final hasCompleted = logs.any((l) => l.completed);
            if (hasCompleted) {
              return explicitTier != HabitTier.none ? explicitTier : HabitTier.base;
            }
            return HabitTier.none;
        }

      case HabitTargetType.numeric:
        final defaultTarget = habit.targetValue ?? 1.0;
        final totalValue = logs.fold<double>(
          0.0,
          (sum, log) => sum + (log.value ?? (log.completed ? defaultTarget : 0.0)),
        );
        final evaluatedTier = habit.evaluateTierForValue(totalValue);
        return explicitTier.index > evaluatedTier.index ? explicitTier : evaluatedTier;

      case HabitTargetType.timer:
        final defaultMinutes = habit.targetValue ?? 25.0;
        final totalMinutes = logs.fold<double>(
          0.0,
          (sum, log) {
            if (log.durationSeconds != null && log.durationSeconds! > 0) {
              return sum + (log.durationSeconds! / 60.0);
            } else {
              return sum + (log.value ?? (log.completed ? defaultMinutes : 0.0));
            }
          },
        );
        final evaluatedTier = habit.evaluateTierForValue(totalMinutes);
        return explicitTier.index > evaluatedTier.index ? explicitTier : evaluatedTier;
    }
  }

  static bool isHabitCompletedOnDate(
    Habit habit,
    List<HabitLog> logs, [
    DateTime? date,
    DateTime? referenceDate,
  ]) {
    if (habit.isNegative) {
      if (date != null) {
        final cleanStart = habit.cleanSince ?? habit.createdAt;
        final cleanStartDate =
            DateTime(cleanStart.year, cleanStart.month, cleanStart.day);
        final evalDate = DateTime(date.year, date.month, date.day);
        final ref = referenceDate ?? DateTime.now();
        final todayDate = DateTime(ref.year, ref.month, ref.day);

        // Days prior to sobriety start or in the future cannot be clean
        if (evalDate.isBefore(cleanStartDate) || evalDate.isAfter(todayDate)) {
          return false;
        }
      }
      if (logs.any((l) => !l.completed)) return false;
      return true;
    }

    if (logs.isEmpty) return false;

    if (habit.hasElasticTiers) {
      // Reaching at least the Mini target preserves streak continuity on difficult days
      return resolveAchievedTier(habit, logs) != HabitTier.none;
    }

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

  /// Evaluates whether a habit step within a routine/stack has received progress on the date.
  /// In habit stacking, a routine step is satisfied if any valid increment, slot check-in,
  /// or timer session has been logged, without requiring full whole-day quota completion.
  static bool isHabitStepSatisfiedForRoutine(
    Habit habit,
    List<HabitLog> logs, [
    DateTime? date,
    DateTime? referenceDate,
  ]) {
    if (habit.isNegative) {
      return isHabitCompletedOnDate(habit, logs, date, referenceDate);
    }

    if (logs.isEmpty) return false;

    switch (habit.targetType) {
      case HabitTargetType.boolean:
        return logs.any((l) => l.completed);

      case HabitTargetType.numeric:
        final totalValue = logs.fold<double>(
          0.0,
          (sum, log) => sum + (log.value ?? (log.completed ? (habit.targetValue ?? 1.0) : 0.0)),
        );
        return totalValue > 0 || logs.any((l) => l.completed);

      case HabitTargetType.timer:
        final totalSeconds = logs.fold<int>(
          0,
          (sum, log) =>
              sum +
              (log.durationSeconds ??
                  (log.completed ? ((habit.targetValue ?? 25.0) * 60).round() : 0)),
        );
        final totalMinutes = logs.fold<double>(
          0.0,
          (sum, log) => sum + (log.value ?? 0.0),
        );
        return totalSeconds > 0 || totalMinutes > 0 || logs.any((l) => l.completed);
    }
  }

  static bool isBaseCompletedOnDate(Habit habit, List<HabitLog> logs) {
    return resolveAchievedTier(habit, logs).isAtLeast(HabitTier.base);
  }

  static bool isWeeklyTargetMet(
    Habit habit,
    Map<String, List<HabitLog>> logsByDate,
    DateTime weekStart, [
    Set<String>? shieldedDates,
  ]) {
    final required = habit.targetCountPerWeek ?? 1;
    var completedOrShieldedDays = 0;
    for (var offset = 0; offset < 7; offset++) {
      final date = weekStart.add(Duration(days: offset));
      final dateStr = formatIsoDate(date);
      final dayLogs = logsByDate[dateStr] ?? const [];
      final isCompleted = isHabitCompletedOnDate(habit, dayLogs);
      final isShielded = shieldedDates?.contains(dateStr) == true;

      if (isCompleted || isShielded) {
        completedOrShieldedDays++;
      }
    }
    return completedOrShieldedDays >= required;
  }

  static StreakResult calculateStreak(
    Habit habit,
    List<HabitLog> allLogs, [
    DateTime? referenceDate,
    List<HabitShield>? shields,
  ]) {
    final ref = referenceDate ?? DateTime.now();
    final refDate = DateTime(ref.year, ref.month, ref.day);

    final logsByDate = <String, List<HabitLog>>{};
    for (final log in allLogs) {
      if (log.habitId == habit.id) {
        logsByDate.putIfAbsent(log.date, () => []).add(log);
      }
    }

    final shieldedDates = <String>{};
    if (shields != null) {
      for (final shield in shields) {
        if (shield.habitId == habit.id) {
          shieldedDates.add(shield.date);
        }
      }
    }

    if (habit.isNegative) {
      return calculateNegativeStreak(habit, logsByDate, refDate, shields);
    }

    if (habit.frequencyType == HabitFrequencyType.weekly) {
      return calculateWeeklyStreak(habit, logsByDate, refDate, shieldedDates);
    }

    var currentStreak = 0;
    var bestStreak = 0;
    var tempStreak = 0;
    var totalCompletions = 0;
    var totalShieldedDays = 0;

    var scheduledDaysIn30 = 0;
    var completedDaysIn30 = 0;

    for (var i = 0; i < 30; i++) {
      final checkDate = refDate.subtract(Duration(days: i));
      final dateStr = formatIsoDate(checkDate);
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

    final refDateStr = formatIsoDate(refDate);
    final refLogs = logsByDate[refDateStr] ?? const [];
    final refCompleted = isHabitCompletedOnDate(habit, refLogs);
    final refShielded = shieldedDates.contains(refDateStr);

    // In-progress preservation: If today is not completed, not shielded, but is scheduled,
    // start evaluating streak chain from yesterday.
    if (!refCompleted && !refShielded && isHabitScheduledOnDate(habit, refDate)) {
      checkDate = refDate.subtract(const Duration(days: 1));
    }

    for (var i = 0; i < 365; i++) {
      final dateStr = formatIsoDate(checkDate);
      final isScheduled = isHabitScheduledOnDate(habit, checkDate);

      if (isScheduled) {
        final dayLogs = logsByDate[dateStr] ?? const [];
        final completed = isHabitCompletedOnDate(habit, dayLogs);
        final isShielded = shieldedDates.contains(dateStr);

        if (completed) {
          totalCompletions++;
          tempStreak++;
          if (isCurrentStreakChain) {
            currentStreak++;
          }
          if (tempStreak > bestStreak) {
            bestStreak = tempStreak;
          }
        } else if (isShielded) {
          totalShieldedDays++;
          // Streak freeze / grace day: Keep current streak chain intact without breaking it
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
      totalShieldedDays: totalShieldedDays,
    );
  }

  static StreakResult calculateWeeklyStreak(
    Habit habit,
    Map<String, List<HabitLog>> logsByDate,
    DateTime referenceDate, [
    Set<String>? shieldedDates,
  ]) {
    var currentStreak = 0;
    var bestStreak = 0;
    var tempStreak = 0;
    var totalCompletions = 0;
    var totalShieldedDays = 0;

    final windowStart = referenceDate.subtract(const Duration(days: 29));
    final weeksInWindow = <DateTime>{};
    var cursor = windowStart;
    while (!cursor.isAfter(referenceDate)) {
      weeksInWindow.add(isoWeekStart(cursor));
      cursor = cursor.add(const Duration(days: 1));
    }

    final metWeeksInWindow = weeksInWindow
        .where((week) => isWeeklyTargetMet(habit, logsByDate, week, shieldedDates))
        .length;
    final completionRate30Days = weeksInWindow.isNotEmpty
        ? ((metWeeksInWindow / weeksInWindow.length) * 100).round()
        : 0;

    var weekStart = isoWeekStart(referenceDate);
    var isCurrentStreakChain = true;
    final currentWeekMet =
        isWeeklyTargetMet(habit, logsByDate, weekStart, shieldedDates);
    if (!currentWeekMet) {
      // In-progress week: do not break streak until the week ends unmet
      weekStart = weekStart.subtract(const Duration(days: 7));
    }

    for (var i = 0; i < 52; i++) {
      final met = isWeeklyTargetMet(habit, logsByDate, weekStart, shieldedDates);
      // Count day-level completions and shields inside the week
      for (var offset = 0; offset < 7; offset++) {
        final dateStr = formatIsoDate(weekStart.add(Duration(days: offset)));
        final dayLogs = logsByDate[dateStr] ?? const [];
        if (isHabitCompletedOnDate(habit, dayLogs)) {
          totalCompletions++;
        }
        if (shieldedDates?.contains(dateStr) == true) {
          totalShieldedDays++;
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
      totalShieldedDays: totalShieldedDays,
    );
  }

  static StreakResult calculateNegativeStreak(
    Habit habit,
    Map<String, List<HabitLog>> logsByDate,
    DateTime referenceDate, [
    List<HabitShield>? shields,
  ]) {
    final cleanStart = habit.cleanSince ?? habit.createdAt;
    final cleanStartDate =
        DateTime(cleanStart.year, cleanStart.month, cleanStart.day);

    var currentStreak = 0;
    var bestStreak = 0;
    var tempStreak = 0;
    var totalCompletions = 0;
    var totalRelapseDays30 = 0;

    for (var i = 0; i < 30; i++) {
      final checkDate = referenceDate.subtract(Duration(days: i));
      if (checkDate.isBefore(cleanStartDate)) break;
      final dateStr = formatIsoDate(checkDate);
      final dayLogs = logsByDate[dateStr] ?? const [];
      final hasRelapse = dayLogs.any((l) => !l.completed);
      if (hasRelapse) {
        totalRelapseDays30++;
      }
    }

    final evaluatedDays30 =
        min(30, max(1, referenceDate.difference(cleanStartDate).inDays + 1));
    final completionRate30Days = evaluatedDays30 > 0
        ? (((evaluatedDays30 - totalRelapseDays30) / evaluatedDays30) * 100)
            .round()
            .clamp(0, 100)
        : 100;

    var checkDate = referenceDate;
    var isCurrentStreakChain = true;

    for (var i = 0; i < 365; i++) {
      if (checkDate.isBefore(cleanStartDate)) break;
      final dateStr = formatIsoDate(checkDate);
      final dayLogs = logsByDate[dateStr] ?? const [];
      final hasRelapse = dayLogs.any((l) => !l.completed);

      if (!hasRelapse) {
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
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return StreakResult(
      currentStreak: currentStreak,
      bestStreak: max(bestStreak, currentStreak),
      completionRate30Days: completionRate30Days,
      totalCompletions: totalCompletions,
      totalShieldedDays: 0,
    );
  }
}
