import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/engines/streak_calculator.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_log.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

void main() {
  final formatter = DateFormat('yyyy-MM-dd');
  const uuid = Uuid();

  Habit createHabit({
    String id = 'test-habit-1',
    String title = 'Daily Reading',
    HabitFrequencyType frequencyType = HabitFrequencyType.daily,
    HabitTargetType targetType = HabitTargetType.boolean,
    List<int>? targetDaysOfWeek,
    int? targetCountPerWeek,
    double? targetValue,
    int? timesPerDay,
  }) {
    final now = DateTime.now().toUtc();
    return Habit(
      id: id,
      title: title,
      color: '#10b981',
      frequencyType: frequencyType,
      targetType: targetType,
      targetDaysOfWeek: targetDaysOfWeek,
      targetCountPerWeek: targetCountPerWeek,
      targetValue: targetValue,
      timesPerDay: timesPerDay,
      createdAt: now,
      updatedAt: now,
    );
  }

  HabitLog createLog({
    required String habitId,
    required DateTime date,
    bool completed = true,
    double? value,
    int? durationSeconds,
    int? intervalIndex,
  }) {
    final now = DateTime.now().toUtc();
    return HabitLog(
      id: uuid.v4(),
      habitId: habitId,
      date: formatter.format(date),
      timestamp: now,
      completed: completed,
      value: value,
      durationSeconds: durationSeconds,
      intervalIndex: intervalIndex,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('calculateStreak_dailyHabit_consecutiveDays_returnsCorrectStreak', () {
    final habit = createHabit();
    final today = DateTime(2026, 8, 17); // Monday
    final logs = [
      createLog(habitId: habit.id, date: today),
      createLog(habitId: habit.id, date: today.subtract(const Duration(days: 1))),
      createLog(habitId: habit.id, date: today.subtract(const Duration(days: 2))),
      createLog(habitId: habit.id, date: today.subtract(const Duration(days: 3))),
      createLog(habitId: habit.id, date: today.subtract(const Duration(days: 4))),
    ];

    final result = StreakCalculator.calculateStreak(habit, logs, today);

    expect(result.currentStreak, 5);
    expect(result.bestStreak, 5);
    expect(result.totalCompletions, 5);
  });

  test('Daily Habits: unlogged current day preserves in-progress streak chain', () {
    final habit = createHabit();
    final today = DateTime(2026, 8, 17);
    final logs = [
      // Today is not logged yet
      createLog(habitId: habit.id, date: today.subtract(const Duration(days: 1))),
      createLog(habitId: habit.id, date: today.subtract(const Duration(days: 2))),
      createLog(habitId: habit.id, date: today.subtract(const Duration(days: 3))),
    ];

    final result = StreakCalculator.calculateStreak(habit, logs, today);

    // Current streak should still be 3 because today is not over yet
    expect(result.currentStreak, 3);
    expect(result.bestStreak, 3);
  });

  test('calculateStreak_dailyHabit_gapYesterday_resetsCurrentStreak', () {
    final habit = createHabit();
    final today = DateTime(2026, 8, 17);
    final logs = [
      createLog(habitId: habit.id, date: today),
      // Yesterday (subtract 1 day) is missing!
      createLog(habitId: habit.id, date: today.subtract(const Duration(days: 2))),
      createLog(habitId: habit.id, date: today.subtract(const Duration(days: 3))),
      createLog(habitId: habit.id, date: today.subtract(const Duration(days: 4))),
    ];

    final result = StreakCalculator.calculateStreak(habit, logs, today);

    expect(result.currentStreak, 1);
    expect(result.bestStreak, 3);
  });

  test('Custom Days: non-scheduled days are skipped without breaking streak chains', () {
    // Mon (1), Wed (3), Fri (5)
    final habit = createHabit(
      frequencyType: HabitFrequencyType.customDays,
      targetDaysOfWeek: [1, 3, 5],
    );
    final monday = DateTime(2026, 8, 17); // Monday
    final friday = monday.subtract(const Duration(days: 3)); // Friday 2026-08-14
    final wednesday = monday.subtract(const Duration(days: 5)); // Wednesday 2026-08-12

    final logs = [
      createLog(habitId: habit.id, date: monday),
      createLog(habitId: habit.id, date: friday),
      createLog(habitId: habit.id, date: wednesday),
    ];

    final result = StreakCalculator.calculateStreak(habit, logs, monday);

    expect(result.currentStreak, 3);
    expect(result.bestStreak, 3);
  });

  test('Weekly Habits: ISO week target met when distinct days >= targetCountPerWeek; streak unit is weeks', () {
    // Target: 3 times per week
    final habit = createHabit(
      frequencyType: HabitFrequencyType.weekly,
      targetCountPerWeek: 3,
    );

    // Today is Monday 2026-08-17 (start of current week)
    final refDate = DateTime(2026, 8, 17);

    // Current week (starting Aug 17): 3 completions on Mon, Tue, Wed
    final currentWeekLogs = [
      createLog(habitId: habit.id, date: DateTime(2026, 8, 17)),
      createLog(habitId: habit.id, date: DateTime(2026, 8, 18)),
      createLog(habitId: habit.id, date: DateTime(2026, 8, 19)),
    ];

    // Previous week 1 (Aug 10 - Aug 16): 3 completions
    final prevWeek1Logs = [
      createLog(habitId: habit.id, date: DateTime(2026, 8, 10)),
      createLog(habitId: habit.id, date: DateTime(2026, 8, 12)),
      createLog(habitId: habit.id, date: DateTime(2026, 8, 14)),
    ];

    // Previous week 2 (Aug 03 - Aug 09): 3 completions
    final prevWeek2Logs = [
      createLog(habitId: habit.id, date: DateTime(2026, 8, 4)),
      createLog(habitId: habit.id, date: DateTime(2026, 8, 5)),
      createLog(habitId: habit.id, date: DateTime(2026, 8, 6)),
    ];

    // Previous week 3 (Jul 27 - Aug 02): only 2 completions (unmet!)
    final prevWeek3Logs = [
      createLog(habitId: habit.id, date: DateTime(2026, 7, 28)),
      createLog(habitId: habit.id, date: DateTime(2026, 7, 30)),
    ];

    final allLogs = currentWeekLogs + prevWeek1Logs + prevWeek2Logs + prevWeek3Logs;

    final result = StreakCalculator.calculateStreak(habit, allLogs, refDate);

    // Streak unit is weeks: current week + prev week 1 + prev week 2 = 3 consecutive met weeks
    expect(result.currentStreak, 3);
    expect(result.bestStreak, 3);
    // Day level completions total = 3 + 3 + 3 + 2 = 11
    expect(result.totalCompletions, 11);
  });

  test('calculateWeeklyStreak_inProgressCurrentWeek_preservesStreak', () {
    final habit = createHabit(
      frequencyType: HabitFrequencyType.weekly,
      targetCountPerWeek: 3,
    );

    // Reference date is Tuesday Aug 18. Current week has only 1 completion so far (not yet met, but in-progress)
    final refDate = DateTime(2026, 8, 18);
    final currentWeekLogs = [
      createLog(habitId: habit.id, date: DateTime(2026, 8, 17)),
    ];

    // Previous week 1 (Aug 10 - Aug 16): 3 completions (met)
    final prevWeek1Logs = [
      createLog(habitId: habit.id, date: DateTime(2026, 8, 10)),
      createLog(habitId: habit.id, date: DateTime(2026, 8, 12)),
      createLog(habitId: habit.id, date: DateTime(2026, 8, 14)),
    ];

    // Previous week 2 (Aug 03 - Aug 09): 3 completions (met)
    final prevWeek2Logs = [
      createLog(habitId: habit.id, date: DateTime(2026, 8, 4)),
      createLog(habitId: habit.id, date: DateTime(2026, 8, 5)),
      createLog(habitId: habit.id, date: DateTime(2026, 8, 6)),
    ];

    final allLogs = currentWeekLogs + prevWeek1Logs + prevWeek2Logs;

    final result = StreakCalculator.calculateStreak(habit, allLogs, refDate);

    // Because current week is in-progress and not over, streak is preserved from previous weeks (2 weeks)
    expect(result.currentStreak, 2);
    expect(result.bestStreak, 2);
  });

  test('calculateStreak_numericTarget_requiresSumToReachTarget', () {
    final habit = createHabit(
      targetType: HabitTargetType.numeric,
      targetValue: 2000.0, // e.g. 2000 ml water
    );
    final today = DateTime(2026, 8, 17);

    // Day 1 (today): 1000 + 1000 = 2000 (Complete)
    final logsToday = [
      createLog(habitId: habit.id, date: today, value: 1000.0),
      createLog(habitId: habit.id, date: today, value: 1000.0),
    ];

    // Day 2 (yesterday): 500 + 500 = 1000 (Incomplete, target is 2000)
    final logsYesterday = [
      createLog(habitId: habit.id, date: today.subtract(const Duration(days: 1)), value: 500.0),
      createLog(habitId: habit.id, date: today.subtract(const Duration(days: 1)), value: 500.0),
    ];

    final result = StreakCalculator.calculateStreak(habit, logsToday + logsYesterday, today);

    expect(result.currentStreak, 1);
  });

  test('calculateStreak_timerTarget_convertsSecondsToMinutes', () {
    final habit = createHabit(
      targetType: HabitTargetType.timer,
      targetValue: 30.0, // 30 minutes
    );
    final today = DateTime(2026, 8, 17);

    // 1800 seconds = 30 minutes
    final logsToday = [
      createLog(habitId: habit.id, date: today, durationSeconds: 1800),
    ];

    final result = StreakCalculator.calculateStreak(habit, logsToday, today);

    expect(result.currentStreak, 1);
  });

  test('calculateStreak_subdaySlots_requiresAllSlotsCompleted', () {
    final habit = createHabit(
      frequencyType: HabitFrequencyType.timesPerDay,
      targetType: HabitTargetType.boolean,
      timesPerDay: 3,
    );
    final today = DateTime(2026, 8, 17);

    // Slot 0, Slot 1, Slot 2 completed
    final logsToday = [
      createLog(habitId: habit.id, date: today, intervalIndex: 0),
      createLog(habitId: habit.id, date: today, intervalIndex: 1),
      createLog(habitId: habit.id, date: today, intervalIndex: 2),
    ];

    // Yesterday: only slot 0 and slot 1 completed (missing slot 2)
    final logsYesterday = [
      createLog(habitId: habit.id, date: today.subtract(const Duration(days: 1)), intervalIndex: 0),
      createLog(habitId: habit.id, date: today.subtract(const Duration(days: 1)), intervalIndex: 1),
    ];

    final result = StreakCalculator.calculateStreak(habit, logsToday + logsYesterday, today);

    expect(result.currentStreak, 1);
  });
}
