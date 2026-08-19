import 'dart:async';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/local/app_database.dart';
import 'package:habit_tracker/data/repositories/gamification_repository_impl.dart';
import 'package:habit_tracker/domain/engines/shield_banking_engine.dart';
import 'package:habit_tracker/domain/engines/streak_calculator.dart';
import 'package:habit_tracker/domain/gamification/achievement_evaluator.dart';
import 'package:habit_tracker/domain/gamification/gamification_engine.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_category.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_log.dart';
import 'package:habit_tracker/domain/models/habit_shield.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:uuid/uuid.dart';

void main() {
  const uuid = Uuid();

  group('Phase 2 Performance Benchmarks', () {
    test('Benchmark 1: Single-Pass vs 4-Pass Streak Evaluation in Gamification Pipeline', () async {
      final now = DateTime.now().toUtc();
      final today = DateTime(2026, 8, 19);

      const habitCount = 20;
      const historyDays = 60;

      final habits = List.generate(
        habitCount,
        (i) => Habit(
          id: 'habit-$i',
          title: 'Daily Habit $i',
          color: '#10B981',
          frequencyType: HabitFrequencyType.daily,
          targetType: HabitTargetType.boolean,
          categoryId: i < 5 ? 'cat-health' : (i < 10 ? 'cat-work' : 'cat-mind'),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final categories = [
        const HabitCategory(id: 'cat-health', name: 'Health & Fitness', color: '#10B981', icon: 'heart'),
        const HabitCategory(id: 'cat-work', name: 'Work & Productivity', color: '#3B82F6', icon: 'briefcase'),
        const HabitCategory(id: 'cat-mind', name: 'Mindfulness', color: '#8B5CF6', icon: 'brain'),
      ];

      final logs = <HabitLog>[];
      final shields = <HabitShield>[];

      for (var d = 0; d < historyDays; d++) {
        final date = today.subtract(Duration(days: d));
        final dateStr = StreakCalculator.dateFormatter.format(date);
        for (final habit in habits) {
          // 80% completion rate simulation
          if ((d + habit.id.hashCode) % 5 != 0) {
            logs.add(HabitLog(
              id: uuid.v4(),
              habitId: habit.id,
              date: dateStr,
              timestamp: date,
              completed: true,
              createdAt: date,
              updatedAt: date,
            ));
          } else if (d == 5) {
            shields.add(HabitShield(
              id: uuid.v4(),
              habitId: habit.id,
              date: dateStr,
              autoApplied: true,
              createdAt: date,
              updatedAt: date,
            ));
          }
        }
      }

      final logsByHabit = <String, List<HabitLog>>{};
      final shieldsByHabit = <String, List<HabitShield>>{};
      for (final l in logs) {
        logsByHabit.putIfAbsent(l.habitId, () => []).add(l);
      }
      for (final s in shields) {
        shieldsByHabit.putIfAbsent(s.habitId, () => []).add(s);
      }

      const iterations = 50;

      // 1. Unoptimized simulation: 4 distinct full-streak passes across all habits
      final swUnoptimized = Stopwatch()..start();
      for (var iter = 0; iter < iterations; iter++) {
        // Pass 1: Longest active streak
        var longestStreak = 0;
        for (final h in habits) {
          final hLogs = logsByHabit[h.id] ?? const [];
          final hShields = shieldsByHabit[h.id] ?? const [];
          final s = StreakCalculator.calculateStreak(h, hLogs, today, hShields);
          longestStreak = max(longestStreak, max(s.currentStreak, s.bestStreak));
        }

        // Pass 2: Base check-in XP multipliers
        var habitCheckInXp = 0;
        for (final h in habits) {
          final hLogs = logsByHabit[h.id] ?? const [];
          final hShields = shieldsByHabit[h.id] ?? const [];
          final s = StreakCalculator.calculateStreak(h, hLogs, today, hShields);
          final mult = GamificationEngine.calculateStreakMultiplier(s.currentStreak);
          habitCheckInXp += GamificationEngine.applyMultiplier(10, mult);
        }

        // Pass 3: Achievement Evaluator (recomputes streaks internally)
        final evalContext = EvaluationContext(
          habits: habits,
          allLogs: logs,
          categories: categories,
          currentLevel: 1,
          referenceDate: today,
        );
        final achievements = AchievementEvaluator.evaluateAll(evalContext);

        // Pass 4: ShieldBankingEngine (recomputes streaks internally)
        final bankState = ShieldBankingEngine.calculateBankState(
          habits: habits,
          logs: logs,
          shields: shields,
          referenceDate: today,
        );

        expect(longestStreak, greaterThan(0));
        expect(habitCheckInXp, greaterThan(0));
        expect(achievements.isNotEmpty, isTrue);
        expect(bankState.maxCapacity, 3);
      }
      swUnoptimized.stop();

      // 2. Optimized: Single-pass streak calculation reused across all steps
      final swOptimized = Stopwatch()..start();
      for (var iter = 0; iter < iterations; iter++) {
        // Single pass: Precalculate streaks once
        final streakByHabit = <String, StreakResult>{};
        var longestStreak = 0;
        for (final h in habits) {
          final hLogs = logsByHabit[h.id] ?? const [];
          final hShields = shieldsByHabit[h.id] ?? const [];
          final s = StreakCalculator.calculateStreak(h, hLogs, today, hShields);
          streakByHabit[h.id] = s;
          longestStreak = max(longestStreak, max(s.currentStreak, s.bestStreak));
        }

        // Reuse precalculated streak in Pass 2
        var habitCheckInXp = 0;
        for (final h in habits) {
          final currentStreak = streakByHabit[h.id]?.currentStreak ?? 0;
          final mult = GamificationEngine.calculateStreakMultiplier(currentStreak);
          habitCheckInXp += GamificationEngine.applyMultiplier(10, mult);
        }

        // Pass 3: Achievement Evaluator with precomputedStreaks
        final evalContext = EvaluationContext(
          habits: habits,
          allLogs: logs,
          categories: categories,
          currentLevel: 1,
          referenceDate: today,
          precomputedStreaks: streakByHabit,
        );
        final achievements = AchievementEvaluator.evaluateAll(evalContext);

        // Pass 4: ShieldBankingEngine with precomputedStreaks
        final bankState = ShieldBankingEngine.calculateBankState(
          habits: habits,
          logs: logs,
          shields: shields,
          referenceDate: today,
          precomputedStreaks: streakByHabit,
        );

        expect(longestStreak, greaterThan(0));
        expect(habitCheckInXp, greaterThan(0));
        expect(achievements.isNotEmpty, isTrue);
        expect(bankState.maxCapacity, 3);
      }
      swOptimized.stop();

      print('\n=== Benchmark 1: Gamification Pipeline Streaks (50 runs on 20 habits x 60 days) ===');
      print('Before (4 redundant streak calculation passes) : ${(swUnoptimized.elapsedMicroseconds / 1000).toStringAsFixed(2)} ms');
      print('After  (Single-pass precomputed streak map)    : ${(swOptimized.elapsedMicroseconds / 1000).toStringAsFixed(2)} ms');
      print('Speedup: ${(swUnoptimized.elapsedMicroseconds / swOptimized.elapsedMicroseconds).toStringAsFixed(2)}x');
    });

    test('Benchmark 2: Microtask Coalescing under Multi-Table Stream Emission Bursts', () async {
      const iterations = 500;

      // Simulation of uncoalesced multi-stream triggering:
      // When 4 tables emit in rapid succession, recomputing 4 consecutive times
      var uncoalescedExecutionCount = 0;
      final swUncoalesced = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        // 4 consecutive stream events
        uncoalescedExecutionCount++;
        uncoalescedExecutionCount++;
        uncoalescedExecutionCount++;
        uncoalescedExecutionCount++;
      }
      swUncoalesced.stop();

      // Simulation of coalesced triggering:
      var coalescedExecutionCount = 0;
      final swCoalesced = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        var scheduled = false;
        void trigger() {
          if (!scheduled) {
            scheduled = true;
            // Coalesced into 1 invocation
            coalescedExecutionCount++;
          }
        }
        // 4 table emissions in the same turn
        trigger();
        trigger();
        trigger();
        trigger();
      }
      swCoalesced.stop();

      print('\n=== Benchmark 2: Stream Event Coalescing (500 bursts of 4 table emissions) ===');
      print('Before (4 recomputes per burst = $uncoalescedExecutionCount evaluations)');
      print('After  (1 recompute per burst  = $coalescedExecutionCount evaluations)');
      print('Evaluation count reduction: ${(uncoalescedExecutionCount / coalescedExecutionCount).toStringAsFixed(2)}x (75.0% fewer computations)');
    });

    test('Benchmark 3: Shared Gamification Stream Controller Pipeline', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = GamificationRepositoryImpl(
        habitDao: db.habitDao,
        habitLogDao: db.habitLogDao,
        habitShieldDao: db.habitShieldDao,
        habitCategoryDao: db.habitCategoryDao,
        gamificationDao: db.gamificationDao,
      );

      final now = DateTime.now().toUtc();
      for (var i = 0; i < 5; i++) {
        await db.habitDao.upsertHabit(
          HabitsCompanion(
            id: Value('bench-g-$i'),
            title: Value('Habit $i'),
            color: const Value('#10B981'),
            frequencyType: const Value(HabitFrequencyType.daily),
            targetType: const Value(HabitTargetType.boolean),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      }

      // Concurrently listen to all 4 gamification slices
      final progSub = repo.getPlayerProgression().listen((_) {});
      final achSub = repo.getAchievements().listen((_) {});
      final celSub = repo.getPendingCelebration().listen((_) {});
      final shieldSub = repo.getShieldBankState().listen((_) {});

      // Wait for initial emission
      await Future.delayed(const Duration(milliseconds: 50));

      const logWrites = 25;
      final swWrites = Stopwatch()..start();
      for (var i = 0; i < logWrites; i++) {
        await db.habitLogDao.upsertLog(
          HabitLogsCompanion(
            id: Value(uuid.v4()),
            habitId: const Value('bench-g-0'),
            date: Value('2026-08-${(i + 1).toString().padLeft(2, '0')}'),
            timestamp: Value(now),
            completed: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      }
      // Allow microtask stream emissions to complete
      await Future.delayed(const Duration(milliseconds: 100));
      swWrites.stop();

      print('\n=== Benchmark 3: Shared Gamification Stream Pipeline ($logWrites log writes with 4 active listeners) ===');
      print('Total execution time for $logWrites writes across 4 active stream subscribers: ${(swWrites.elapsedMicroseconds / 1000).toStringAsFixed(2)} ms');
      print('Average time per write: ${((swWrites.elapsedMicroseconds / 1000) / logWrites).toStringAsFixed(2)} ms\n');

      await progSub.cancel();
      await achSub.cancel();
      await celSub.cancel();
      await shieldSub.cancel();
      await db.close();
    });
  });
}
