import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/engines/streak_calculator.dart';
import 'package:habit_tracker/domain/gamification/gamification_engine.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_log.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/domain/models/habit_tier.dart';
import 'package:uuid/uuid.dart';

void main() {
  const uuid = Uuid();
  final now = DateTime(2026, 8, 21);

  group('HabitTier & Model Evaluation', () {
    test('HabitTier enum has expected properties and comparison', () {
      expect(HabitTier.mini.baseXp, 5);
      expect(HabitTier.base.baseXp, 20);
      expect(HabitTier.elite.baseXp, 35);
      expect(HabitTier.none.baseXp, 0);

      expect(HabitTier.mini.isAtLeast(HabitTier.none), isTrue);
      expect(HabitTier.mini.isAtLeast(HabitTier.mini), isTrue);
      expect(HabitTier.mini.isAtLeast(HabitTier.base), isFalse);

      expect(HabitTier.base.isAtLeast(HabitTier.mini), isTrue);
      expect(HabitTier.elite.isAtLeast(HabitTier.base), isTrue);
    });

    test('Habit evaluateTierForValue evaluates Mini, Base, and Elite thresholds accurately', () {
      final habit = Habit(
        id: 'reading-1',
        title: 'Reading',
        color: '#10B981',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.numeric,
        targetValue: 20.0,
        miniTargetValue: 1.0,
        eliteTargetValue: 50.0,
        unit: 'pages',
        createdAt: now,
        updatedAt: now,
      );

      expect(habit.hasElasticTiers, isTrue);
      expect(habit.evaluateTierForValue(0.0), HabitTier.none);
      expect(habit.evaluateTierForValue(0.5), HabitTier.none);
      expect(habit.evaluateTierForValue(1.0), HabitTier.mini);
      expect(habit.evaluateTierForValue(10.0), HabitTier.mini);
      expect(habit.evaluateTierForValue(20.0), HabitTier.base);
      expect(habit.evaluateTierForValue(35.0), HabitTier.base);
      expect(habit.evaluateTierForValue(50.0), HabitTier.elite);
      expect(habit.evaluateTierForValue(100.0), HabitTier.elite);
    });
  });

  group('Momentum Preservation in StreakCalculator', () {
    test('Completing Mini target preserves streak continuity on difficult days', () {
      final habit = Habit(
        id: 'reading-1',
        title: 'Reading',
        color: '#10B981',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.numeric,
        targetValue: 20.0,
        miniTargetValue: 1.0,
        eliteTargetValue: 50.0,
        unit: 'pages',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now,
      );

      // Day 1: Base target (20 pages)
      // Day 2: Mini target (1 page on bad day)
      // Day 3: Elite target (50 pages on high-energy day)
      final logs = [
        HabitLog(
          id: uuid.v4(),
          habitId: habit.id,
          date: '2026-08-19',
          timestamp: DateTime(2026, 8, 19, 10, 0),
          completed: true,
          value: 20.0,
          createdAt: now,
          updatedAt: now,
        ),
        HabitLog(
          id: uuid.v4(),
          habitId: habit.id,
          date: '2026-08-20',
          timestamp: DateTime(2026, 8, 20, 10, 0),
          completed: true,
          value: 1.0, // Mini target
          createdAt: now,
          updatedAt: now,
        ),
        HabitLog(
          id: uuid.v4(),
          habitId: habit.id,
          date: '2026-08-21',
          timestamp: DateTime(2026, 8, 21, 10, 0),
          completed: true,
          value: 50.0, // Elite target
          createdAt: now,
          updatedAt: now,
        ),
      ];

      expect(
        StreakCalculator.isHabitCompletedOnDate(habit, [logs[0]]),
        isTrue,
      );
      expect(
        StreakCalculator.resolveAchievedTier(habit, [logs[0]]),
        HabitTier.base,
      );

      // Mini day preservation
      expect(
        StreakCalculator.isHabitCompletedOnDate(habit, [logs[1]]),
        isTrue,
      );
      expect(
        StreakCalculator.resolveAchievedTier(habit, [logs[1]]),
        HabitTier.mini,
      );

      // Elite day
      expect(
        StreakCalculator.isHabitCompletedOnDate(habit, [logs[2]]),
        isTrue,
      );
      expect(
        StreakCalculator.resolveAchievedTier(habit, [logs[2]]),
        HabitTier.elite,
      );

      final streakResult = StreakCalculator.calculateStreak(
        habit,
        logs,
        DateTime(2026, 8, 21),
      );

      // Unbroken 3-day streak preserved by Mini target on bad day
      expect(streakResult.currentStreak, 3);
      expect(streakResult.bestStreak, 3);
    });

    test('Explicit tier check-in preserves streak even for boolean habits', () {
      final habit = Habit(
        id: 'workout-1',
        title: 'Workout',
        color: '#3B82F6',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.boolean,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now,
      );

      final logs = [
        HabitLog(
          id: uuid.v4(),
          habitId: habit.id,
          date: '2026-08-21',
          timestamp: DateTime(2026, 8, 21, 9, 0),
          completed: true,
          targetTier: HabitTier.mini,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      expect(StreakCalculator.resolveAchievedTier(habit, logs), HabitTier.mini);
      expect(StreakCalculator.isHabitCompletedOnDate(habit, logs), isTrue);
    });
  });

  group('Tiered XP Scaling in GamificationEngine', () {
    test('calculateHabitDayBaseXp awards 5 XP for Mini, 20 XP for Base, and 35 XP for Elite', () {
      final habit = Habit(
        id: 'reading-1',
        title: 'Reading',
        color: '#10B981',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.numeric,
        targetValue: 20.0,
        miniTargetValue: 1.0,
        eliteTargetValue: 50.0,
        unit: 'pages',
        createdAt: now,
        updatedAt: now,
      );

      final miniLog = [
        HabitLog(
          id: uuid.v4(),
          habitId: habit.id,
          date: '2026-08-21',
          timestamp: now,
          completed: true,
          value: 1.0,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final baseLog = [
        HabitLog(
          id: uuid.v4(),
          habitId: habit.id,
          date: '2026-08-21',
          timestamp: now,
          completed: true,
          value: 20.0,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final eliteLog = [
        HabitLog(
          id: uuid.v4(),
          habitId: habit.id,
          date: '2026-08-21',
          timestamp: now,
          completed: true,
          value: 50.0,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      expect(GamificationEngine.calculateHabitDayBaseXp(habit, miniLog, true), 5);
      expect(GamificationEngine.calculateHabitDayBaseXp(habit, baseLog, true), 20);
      expect(GamificationEngine.calculateHabitDayBaseXp(habit, eliteLog, true), 35);
    });

    test('Tiered XP multiplies accurately with active streak multiplier', () {
      final habit = Habit(
        id: 'reading-1',
        title: 'Reading',
        color: '#10B981',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.numeric,
        targetValue: 20.0,
        miniTargetValue: 1.0,
        eliteTargetValue: 50.0,
        createdAt: now,
        updatedAt: now,
      );

      final miniLog = [
        HabitLog(
          id: uuid.v4(),
          habitId: habit.id,
          date: '2026-08-21',
          timestamp: now,
          completed: true,
          value: 1.0,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final miniBaseXp = GamificationEngine.calculateHabitDayBaseXp(habit, miniLog, true);
      expect(miniBaseXp, 5);

      // Streak < 7 days (1.0x) -> 5 XP
      expect(GamificationEngine.applyMultiplier(miniBaseXp, 1.0), 5);

      // Streak 7..13 days (1.25x) -> 6 XP
      expect(GamificationEngine.applyMultiplier(miniBaseXp, 1.25), 6);

      // Streak 14..29 days (1.5x) -> 8 XP
      expect(GamificationEngine.applyMultiplier(miniBaseXp, 1.5), 8);

      // Streak 30+ days (2.0x) -> 10 XP
      expect(GamificationEngine.applyMultiplier(miniBaseXp, 2.0), 10);
    });
  });
}
