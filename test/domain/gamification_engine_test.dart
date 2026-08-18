import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/gamification/gamification_engine.dart';
import 'package:habit_tracker/domain/gamification/player_title.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_log.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:uuid/uuid.dart';

void main() {
  const uuid = Uuid();

  test('calculateStreakMultiplier_returnsCorrectMultiplierForStreakLengths', () {
    expect(GamificationEngine.calculateStreakMultiplier(0), 1.0);
    expect(GamificationEngine.calculateStreakMultiplier(6), 1.0);
    expect(GamificationEngine.calculateStreakMultiplier(7), 1.25);
    expect(GamificationEngine.calculateStreakMultiplier(13), 1.25);
    expect(GamificationEngine.calculateStreakMultiplier(14), 1.5);
    expect(GamificationEngine.calculateStreakMultiplier(29), 1.5);
    expect(GamificationEngine.calculateStreakMultiplier(30), 2.0);
    expect(GamificationEngine.calculateStreakMultiplier(100), 2.0);
  });

  test('xpThresholdForLevel_quadraticCurveProgression', () {
    expect(GamificationEngine.xpThresholdForLevel(1), 0);
    expect(GamificationEngine.xpThresholdForLevel(2), 100);
    expect(GamificationEngine.xpThresholdForLevel(3), 250);
    expect(GamificationEngine.xpThresholdForLevel(4), 450);
    expect(GamificationEngine.xpThresholdForLevel(5), 700);
    expect(GamificationEngine.xpThresholdForLevel(10), 2700);
    expect(GamificationEngine.xpThresholdForLevel(20), 10450);
  });

  test('calculateProgression_resolvesLevelTitlesAndProgressFractions', () {
    // Level 1: 0 XP
    final prog1 = GamificationEngine.calculateProgression(totalXp: 0);
    expect(prog1.level, 1);
    expect(prog1.title, PlayerTitle.novice);
    expect(prog1.currentLevelBaseXp, 0);
    expect(prog1.nextLevelTargetXp, 100);
    expect(prog1.progressFraction, 0.0);

    // Level 1: 50 XP (halfway to Lv 2)
    final progHalf = GamificationEngine.calculateProgression(totalXp: 50);
    expect(progHalf.level, 1);
    expect(progHalf.progressFraction, 0.5);

    // Level 5: 700 XP (Apprentice)
    final prog5 = GamificationEngine.calculateProgression(totalXp: 700, longestActiveStreak: 14);
    expect(prog5.level, 5);
    expect(prog5.title, PlayerTitle.apprentice);
    expect(prog5.activeStreakMultiplier, 1.5);

    // Level 10: 2700 XP (Pathfinder)
    final prog10 = GamificationEngine.calculateProgression(totalXp: 2700, longestActiveStreak: 30);
    expect(prog10.level, 10);
    expect(prog10.title, PlayerTitle.pathfinder);
    expect(prog10.activeStreakMultiplier, 2.0);

    // Level 20: 10450 XP (Grandmaster)
    final prog20 = GamificationEngine.calculateProgression(totalXp: 10450);
    expect(prog20.level, 20);
    expect(prog20.title, PlayerTitle.grandmaster);
  });

  test('calculateHabitDayBaseXp_booleanHabit', () {
    final now = DateTime.now().toUtc();
    final habit = Habit(
      id: 'h1',
      title: 'Drink Water',
      color: '#000000',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      createdAt: now,
      updatedAt: now,
    );
    final log = HabitLog(
      id: uuid.v4(),
      habitId: 'h1',
      date: '2026-08-17',
      timestamp: now,
      completed: true,
      createdAt: now,
      updatedAt: now,
    );

    final xpCompleted = GamificationEngine.calculateHabitDayBaseXp(habit, [log], true);
    expect(xpCompleted, GamificationEngine.baseBooleanXp);

    final xpNotCompleted = GamificationEngine.calculateHabitDayBaseXp(habit, [], false);
    expect(xpNotCompleted, 0);
  });

  test('calculateHabitDayBaseXp_timerHabit', () {
    final now = DateTime.now().toUtc();
    final habit = Habit(
      id: 'h2',
      title: 'Deep Work',
      color: '#000000',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.timer,
      targetValue: 25.0,
      createdAt: now,
      updatedAt: now,
    );
    final log = HabitLog(
      id: uuid.v4(),
      habitId: 'h2',
      date: '2026-08-17',
      timestamp: now,
      completed: true,
      durationSeconds: 1500, // 25 minutes
      createdAt: now,
      updatedAt: now,
    );

    final xp = GamificationEngine.calculateHabitDayBaseXp(habit, [log], true);
    // 25 mins (25 XP) + 10 XP bonus
    expect(xp, 35);
  });

  test('calculateHabitDayBaseXp_slotsHabit', () {
    final now = DateTime.now().toUtc();
    final habit = Habit(
      id: 'h3',
      title: 'Walks',
      color: '#000000',
      frequencyType: HabitFrequencyType.timesPerDay,
      timesPerDay: 3,
      targetType: HabitTargetType.boolean,
      createdAt: now,
      updatedAt: now,
    );
    final logs = List.generate(3, (slot) {
      return HabitLog(
        id: uuid.v4(),
        habitId: 'h3',
        date: '2026-08-17',
        timestamp: now,
        intervalIndex: slot,
        completed: true,
        createdAt: now,
        updatedAt: now,
      );
    });

    final xp = GamificationEngine.calculateHabitDayBaseXp(habit, logs, true);
    // 3 slots * 10 XP + 15 XP bonus = 45 XP
    expect(xp, 45);
  });

  test('applyMultiplier_scalesXpCorrectly', () {
    expect(GamificationEngine.applyMultiplier(20, 1.0), 20);
    expect(GamificationEngine.applyMultiplier(20, 1.25), 25);
    expect(GamificationEngine.applyMultiplier(20, 1.5), 30);
    expect(GamificationEngine.applyMultiplier(20, 2.0), 40);
  });
}
