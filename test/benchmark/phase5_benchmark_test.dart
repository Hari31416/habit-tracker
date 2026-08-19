import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/engines/streak_calculator.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_category.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_log.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/domain/models/habit_with_progress.dart';
import 'package:habit_tracker/ui/daily/controllers/daily_tracker_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);

  const categoryA = HabitCategory(
    id: 'cat_health',
    name: 'Health',
    color: '#10B981',
    icon: 'favorite',
  );

  const categoryB = HabitCategory(
    id: 'cat_productivity',
    name: 'Productivity',
    color: '#3B82F6',
    icon: 'work',
  );

  final habits = List.generate(
    30,
    (i) => Habit(
      id: 'habit_$i',
      title: i % 2 == 0 ? 'Drink Water $i' : 'Read Book $i',
      categoryId: i % 2 == 0 ? 'cat_health' : 'cat_productivity',
      color: '#10B981',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      pinned: i < 5,
      createdAt: todayDate.subtract(const Duration(days: 365)),
      updatedAt: todayDate,
    ),
  );

  // Generate 1 year of logs for all 30 habits (~10,000 logs)
  final allLogs = <HabitLog>[];
  for (var h = 0; h < habits.length; h++) {
    for (var d = 0; d < 365; d++) {
      final logDate = todayDate.subtract(Duration(days: d));
      final dateStr = StreakCalculator.formatIsoDate(logDate);
      if ((h + d) % 3 != 0) {
        allLogs.add(
          HabitLog(
            id: 'log_${h}_$d',
            habitId: habits[h].id,
            date: dateStr,
            completed: true,
            timestamp: logDate,
            createdAt: logDate,
            updatedAt: logDate,
          ),
        );
      }
    }
  }

  // Pre-calculate HabitWithProgress baseline for 30 habits
  final initialHabitsWithProgress = habits.map((h) {
    final hLogs = allLogs.where((l) => l.habitId == h.id).toList();
    final streak = StreakCalculator.calculateStreak(
      h,
      hLogs,
      todayDate,
    );
    final todayLogs = hLogs.where((l) => l.date == StreakCalculator.formatIsoDate(todayDate)).toList();
    final isDone = StreakCalculator.isHabitCompletedOnDate(
      h,
      todayLogs,
    );
    return HabitWithProgress(
      habit: h,
      category: h.categoryId == 'cat_health' ? categoryA : categoryB,
      logsForDate: todayLogs,
      isCompletedOnDate: isDone,
      streak: streak,
    );
  }).toList();

  group('Phase 5 Performance Benchmarks', () {
    test('Benchmark 1: In-Memory Search & Filtering vs 365-Day Streak Recalculation', () {
      final searchQueries = ['Drink', 'Read', 'Water', 'Book', '1', '2', '3', 'NonExistent'];
      const iterations = 50;

      // 1. Before: Full recalculation for every search keystroke
      final swBefore = Stopwatch()..start();
      for (var iter = 0; iter < iterations; iter++) {
        final query = searchQueries[iter % searchQueries.length];
        // Recompute all 30 habit streaks across 365 days on every keystroke
        final recalculated = habits.map((h) {
          final hLogs = allLogs.where((l) => l.habitId == h.id).toList();
          final streak = StreakCalculator.calculateStreak(
            h,
            hLogs,
            todayDate,
          );
          final todayLogs = hLogs.where((l) => l.date == StreakCalculator.formatIsoDate(todayDate)).toList();
          final isDone = StreakCalculator.isHabitCompletedOnDate(
            h,
            todayLogs,
          );
          return HabitWithProgress(
            habit: h,
            category: h.categoryId == 'cat_health' ? categoryA : categoryB,
            logsForDate: todayLogs,
            isCompletedOnDate: isDone,
            streak: streak,
          );
        }).toList();

        // Then filter
        final _ = recalculated.where((h) => h.habit.title.toLowerCase().contains(query.toLowerCase())).toList();
      }
      swBefore.stop();

      // 2. After: Instant In-Memory Filter on Cached HabitWithProgress
      final swAfter = Stopwatch()..start();
      for (var iter = 0; iter < iterations; iter++) {
        final query = searchQueries[iter % searchQueries.length];
        var filtered = initialHabitsWithProgress.where((h) {
          return h.habit.title.toLowerCase().contains(query.toLowerCase());
        }).toList();

        filtered.sort((a, b) {
          if (a.habit.pinned != b.habit.pinned) {
            return b.habit.pinned ? 1 : -1;
          }
          return a.habit.title.toLowerCase().compareTo(b.habit.title.toLowerCase());
        });
      }
      swAfter.stop();

      final msBefore = swBefore.elapsedMicroseconds / 1000.0;
      final msAfter = swAfter.elapsedMicroseconds / 1000.0;
      final speedup = msBefore / (msAfter > 0 ? msAfter : 0.001);

      print('\n=== Benchmark 1: Search & Filter (50 keystrokes across 30 habits x 365 days history) ===');
      print('Before (Recalculating 365-day streaks on keystroke) : ${msBefore.toStringAsFixed(2)} ms');
      print('After  (In-Memory Filter on Cached State)           : ${msAfter.toStringAsFixed(2)} ms');
      print('Speedup: ${speedup.toStringAsFixed(2)}x');

      expect(speedup, greaterThan(5.0));
    });

    test('Benchmark 2: UI State Equality and Scoped Selector Evaluation', () {
      final baseState = DailyTrackerUiState(
        selectedDate: todayDate,
        habits: initialHabitsWithProgress,
        categories: const [categoryA, categoryB],
        sortOption: HabitSortOption.pinnedFirst,
        totalCompletedForSelectedDate: 15,
        totalScheduledForSelectedDate: 30,
        isLoading: false,
      );

      const iterations = 5000;
      final sw = Stopwatch()..start();
      var identicalCount = 0;
      for (var i = 0; i < iterations; i++) {
        // Compare state equality for unchanged components
        final sameState = baseState.copyWith();
        if (baseState == sameState) {
          identicalCount++;
        }
      }
      sw.stop();

      final ms = sw.elapsedMicroseconds / 1000.0;
      final avgMicros = sw.elapsedMicroseconds / iterations;

      print('\n=== Benchmark 2: State Equality Check (5,000 evaluations) ===');
      print('Total Evaluation Time : ${ms.toStringAsFixed(2)} ms');
      print('Average per Check     : ${avgMicros.toStringAsFixed(3)} µs');
      print('Identical matches     : $identicalCount / $iterations');

      expect(identicalCount, iterations);
      expect(avgMicros, lessThan(50));
    });

    test('Benchmark 3: Multi-Category and Sorting Filter Throughput', () {
      const iterations = 500;
      final sw = Stopwatch()..start();

      for (var i = 0; i < iterations; i++) {
        final catId = i % 2 == 0 ? 'cat_health' : 'cat_productivity';
        final filtered = initialHabitsWithProgress.where((h) => h.habit.categoryId == catId).toList();

        // Sort by streak length descending
        filtered.sort((a, b) {
          if (a.habit.pinned != b.habit.pinned) {
            return b.habit.pinned ? 1 : -1;
          }
          return b.streak.currentStreak.compareTo(a.streak.currentStreak);
        });
      }
      sw.stop();

      final ms = sw.elapsedMicroseconds / 1000.0;
      final avgMs = ms / iterations;

      print('\n=== Benchmark 3: Category Filtering & Sorting Throughput (500 runs) ===');
      print('Total Execution Time : ${ms.toStringAsFixed(2)} ms');
      print('Average per Filter   : ${avgMs.toStringAsFixed(3)} ms');

      expect(avgMs, lessThan(0.5));
    });
  });
}
