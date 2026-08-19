import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/engines/streak_calculator.dart';
import 'package:habit_tracker/domain/engines/wellbeing_correlation_engine.dart';
import 'package:habit_tracker/domain/gamification/achievement_evaluator.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_category.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_log.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

void main() {
  const uuid = Uuid();

  group('Phase 3 Performance Benchmarks', () {
    test('Benchmark 1: Fast ISO Date Formatting vs DateFormat.format (10,000 dates)', () {
      final dates = List.generate(
        10000,
        (i) => DateTime(2026, 1, 1).add(Duration(days: i % 365, hours: i % 24)),
      );

      final dateFormatter = DateFormat('yyyy-MM-dd');

      // 1. Unoptimized: DateFormat.format()
      final swDateFormat = Stopwatch()..start();
      final resultsDateFormat = <String>[];
      for (final d in dates) {
        resultsDateFormat.add(dateFormatter.format(d));
      }
      swDateFormat.stop();

      // 2. Optimized: StreakCalculator.formatIsoDate()
      final swFastIso = Stopwatch()..start();
      final resultsFastIso = <String>[];
      for (final d in dates) {
        resultsFastIso.add(StreakCalculator.formatIsoDate(d));
      }
      swFastIso.stop();

      expect(resultsFastIso, equals(resultsDateFormat));

      final msDateFormat = swDateFormat.elapsedMicroseconds / 1000;
      final msFastIso = swFastIso.elapsedMicroseconds / 1000;
      final speedup = swDateFormat.elapsedMicroseconds / swFastIso.elapsedMicroseconds;

      print('\n=== Benchmark 1: ISO Date Formatting (10,000 iterations) ===');
      print('Before (DateFormat.format)               : ${msDateFormat.toStringAsFixed(2)} ms');
      print('After  (StreakCalculator.formatIsoDate) : ${msFastIso.toStringAsFixed(2)} ms');
      print('Speedup: ${speedup.toStringAsFixed(2)}x');
    });

    test('Benchmark 2: Indexed Log Lookups vs Quadratic .where Scans (20 habits x 365 days x 5,000 logs)', () {
      final now = DateTime.now().toUtc();
      final today = DateTime(2026, 8, 19);
      const habitCount = 20;
      const historyDays = 365;

      final habits = List.generate(
        habitCount,
        (i) => Habit(
          id: 'bench-h-$i',
          title: 'Daily Habit $i',
          color: '#10B981',
          frequencyType: HabitFrequencyType.daily,
          targetType: HabitTargetType.boolean,
          categoryId: 'cat-health',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final logs = <HabitLog>[];
      for (var d = 0; d < historyDays; d++) {
        final date = today.subtract(Duration(days: d));
        final dateStr = StreakCalculator.formatIsoDate(date);
        for (final habit in habits) {
          if ((d + habit.id.hashCode) % 3 != 0) {
            logs.add(HabitLog(
              id: uuid.v4(),
              habitId: habit.id,
              date: dateStr,
              timestamp: date,
              completed: true,
              createdAt: date,
              updatedAt: date,
            ));
          }
        }
      }

      final logsByHabit = <String, List<HabitLog>>{};
      for (final l in logs) {
        logsByHabit.putIfAbsent(l.habitId, () => []).add(l);
      }

      const iterations = 30;

      // 1. Unoptimized: Repeated linear .where((l) => l.date == dateStr) scans
      final swUnoptimized = Stopwatch()..start();
      var unoptimizedMatchCount = 0;
      for (var iter = 0; iter < iterations; iter++) {
        for (var d = 0; d < 60; d++) {
          final date = today.subtract(Duration(days: d));
          final dateStr = StreakCalculator.formatIsoDate(date);
          for (final habit in habits) {
            final habitLogs = logsByHabit[habit.id] ?? const [];
            final dayLogs = habitLogs.where((l) => l.date == dateStr).toList();
            if (dayLogs.any((l) => l.completed)) {
              unoptimizedMatchCount++;
            }
          }
        }
      }
      swUnoptimized.stop();

      // 2. Optimized: Pre-indexed O(1) lookups via Map<String, Map<String, List<HabitLog>>>
      final swOptimized = Stopwatch()..start();
      var optimizedMatchCount = 0;
      for (var iter = 0; iter < iterations; iter++) {
        final logsByHabitDate = <String, Map<String, List<HabitLog>>>{};
        for (final l in logs) {
          logsByHabitDate
              .putIfAbsent(l.habitId, () => {})
              .putIfAbsent(l.date, () => [])
              .add(l);
        }

        for (var d = 0; d < 60; d++) {
          final date = today.subtract(Duration(days: d));
          final dateStr = StreakCalculator.formatIsoDate(date);
          for (final habit in habits) {
            final dayLogs = logsByHabitDate[habit.id]?[dateStr] ?? const [];
            if (dayLogs.any((l) => l.completed)) {
              optimizedMatchCount++;
            }
          }
        }
      }
      swOptimized.stop();

      expect(optimizedMatchCount, equals(unoptimizedMatchCount));

      final msUnoptimized = swUnoptimized.elapsedMicroseconds / 1000;
      final msOptimized = swOptimized.elapsedMicroseconds / 1000;
      final speedup = swUnoptimized.elapsedMicroseconds / swOptimized.elapsedMicroseconds;

      print('\n=== Benchmark 2: Log Lookup (30 runs x 60 days x 20 habits on ${logs.length} logs) ===');
      print('Before (Linear .where scans per habit/day) : ${msUnoptimized.toStringAsFixed(2)} ms');
      print('After  (Pre-indexed O(1) Map lookups)     : ${msOptimized.toStringAsFixed(2)} ms');
      print('Speedup: ${speedup.toStringAsFixed(2)}x');
    });

    test('Benchmark 3: Wellbeing Correlation and Achievement Pipeline Throughput', () {
      final now = DateTime.now().toUtc();
      final today = DateTime(2026, 8, 19);
      const habitCount = 15;
      const historyDays = 90;

      final habits = List.generate(
        habitCount,
        (i) => Habit(
          id: 'wellbeing-h-$i',
          title: 'Habit $i',
          color: '#3B82F6',
          frequencyType: HabitFrequencyType.daily,
          targetType: HabitTargetType.boolean,
          categoryId: 'cat-mind',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final categories = [
        const HabitCategory(id: 'cat-mind', name: 'Mindfulness', color: '#8B5CF6', icon: 'brain'),
      ];

      final logs = <HabitLog>[];
      for (var d = 0; d < historyDays; d++) {
        final date = today.subtract(Duration(days: d));
        final dateStr = StreakCalculator.formatIsoDate(date);
        for (final habit in habits) {
          final isDone = (d + habit.id.hashCode) % 2 == 0;
          logs.add(HabitLog(
            id: uuid.v4(),
            habitId: habit.id,
            date: dateStr,
            timestamp: date,
            completed: isDone,
            energyLevel: isDone ? 4 : 2,
            mood: isDone ? 'Energized' : 'Tired',
            createdAt: date,
            updatedAt: date,
          ));
        }
      }

      const runs = 50;

      final swPipeline = Stopwatch()..start();
      for (var r = 0; r < runs; r++) {
        final correlation = WellbeingCorrelationEngine.calculateCorrelation(
          habits: habits,
          logs: logs,
          referenceDate: today,
          daysCount: 30,
        );

        final evalContext = EvaluationContext(
          habits: habits,
          allLogs: logs,
          categories: categories,
          referenceDate: today,
        );
        final achievements = AchievementEvaluator.evaluateAll(evalContext);

        expect(correlation.timelinePoints.length, 30);
        expect(achievements.isNotEmpty, isTrue);
      }
      swPipeline.stop();

      final totalMs = swPipeline.elapsedMicroseconds / 1000;
      final avgMs = totalMs / runs;

      print('\n=== Benchmark 3: Analytics & Wellbeing Engine Pipeline ($runs runs on 15 habits x 90 days) ===');
      print('Total execution time : ${totalMs.toStringAsFixed(2)} ms');
      print('Average time per run : ${avgMs.toStringAsFixed(2)} ms\n');
    });
  });
}
