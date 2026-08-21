import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/engines/streak_calculator.dart';
import 'package:habit_tracker/domain/gamification/gamification_engine.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/domain/models/habit_tier.dart';
import 'package:habit_tracker/domain/repositories/backup_repository.dart';
import 'package:intl/intl.dart';

import 'journey_harness.dart';

void main() {
  late JourneyHarness harness;
  final dateFmt = DateFormat('yyyy-MM-dd');

  setUp(() async {
    harness = JourneyHarness();
    await harness.setUp();
  });

  tearDown(() async {
    await harness.tearDown();
  });

  test('check-in → streak → XP: unlogged today keeps chain; multiplier from currentStreak',
      () async {
    final today = JourneyHarness.day(DateTime.now());
    final created = today.subtract(const Duration(days: 14));
    const habitId = 'journey_boolean_streak';

    await harness.habits.upsertHabit(
      Habit(
        id: habitId,
        title: 'Journey Boolean',
        color: '#10B981',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.boolean,
        createdAt: created,
        updatedAt: created,
      ),
    );

    // Seven completed days ending yesterday; today unlogged.
    for (var i = 1; i <= 7; i++) {
      await harness.habits.logCheckIn(
        habitId: habitId,
        date: today.subtract(Duration(days: i)),
        completed: true,
      );
    }

    final habit = await harness.habits.getHabitByIdOnce(habitId);
    final logs = await harness.habits.getLogsForHabitOnce(habitId);
    final streak = StreakCalculator.calculateStreak(habit!, logs, today);
    expect(streak.currentStreak, 7);
    expect(streak.bestStreak, 7);

    final progression = await harness.gamification.getPlayerProgression().first;
    expect(progression.totalXp, greaterThan(0));
    expect(progression.longestActiveStreak, 7);
    expect(
      progression.activeStreakMultiplier,
      GamificationEngine.calculateStreakMultiplier(streak.currentStreak),
    );
    expect(progression.activeStreakMultiplier, 1.25);
  });

  test('elastic mini-target: mini-tier log preserves streak via real repos', () async {
    final today = JourneyHarness.day(DateTime.now());
    final created = today.subtract(const Duration(days: 5));
    const habitId = 'journey_elastic_mini';

    await harness.habits.upsertHabit(
      Habit(
        id: habitId,
        title: 'Journey Reading',
        color: '#3B82F6',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.numeric,
        targetValue: 20.0,
        miniTargetValue: 1.0,
        eliteTargetValue: 50.0,
        unit: 'pages',
        createdAt: created,
        updatedAt: created,
      ),
    );

    await harness.habits.logTierCheckIn(
      habitId,
      today.subtract(const Duration(days: 2)),
      HabitTier.base,
    );
    await harness.habits.logTierCheckIn(
      habitId,
      today.subtract(const Duration(days: 1)),
      HabitTier.mini,
    );

    final habit = await harness.habits.getHabitByIdOnce(habitId);
    final logs = await harness.habits.getLogsForHabitOnce(habitId);
    final streak = StreakCalculator.calculateStreak(habit!, logs, today);
    expect(streak.currentStreak, 2);

    final yesterdayKey = dateFmt.format(today.subtract(const Duration(days: 1)));
    final miniLog = logs.firstWhere((l) => l.date == yesterdayKey);
    expect(miniLog.targetTier, HabitTier.mini);
  });

  test('backup restore: overwrite import keeps streak and XP', () async {
    final today = JourneyHarness.day(DateTime.now());
    final created = today.subtract(const Duration(days: 10));
    const habitId = 'journey_backup_habit';

    await harness.habits.upsertHabit(
      Habit(
        id: habitId,
        title: 'Backup Journey',
        color: '#F59E0B',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.boolean,
        createdAt: created,
        updatedAt: created,
      ),
    );
    for (var i = 1; i <= 3; i++) {
      await harness.habits.logCheckIn(
        habitId: habitId,
        date: today.subtract(Duration(days: i)),
        completed: true,
      );
    }

    final habitBefore = await harness.habits.getHabitByIdOnce(habitId);
    final logsBefore = await harness.habits.getLogsForHabitOnce(habitId);
    final streakBefore =
        StreakCalculator.calculateStreak(habitBefore!, logsBefore, today);
    final xpBefore =
        (await harness.gamification.getPlayerProgression().first).totalXp;
    expect(streakBefore.currentStreak, 3);
    expect(xpBefore, greaterThan(0));

    final exported = await harness.backup.exportBackupJson(
      deviceId: 'journey_device',
    );

    await harness.backup.executeImport(exported, mode: ImportMode.overwrite);

    final habitAfter = await harness.habits.getHabitByIdOnce(habitId);
    final logsAfter = await harness.habits.getLogsForHabitOnce(habitId);
    final streakAfter =
        StreakCalculator.calculateStreak(habitAfter!, logsAfter, today);
    final xpAfter =
        (await harness.gamification.getPlayerProgression().first).totalXp;

    expect(streakAfter.currentStreak, streakBefore.currentStreak);
    expect(xpAfter, xpBefore);
  });

  test('archive vs delete: archive hides from active; delete soft-removes', () async {
    final now = DateTime.now().toUtc();
    const archiveId = 'journey_archive_me';
    const deleteId = 'journey_delete_me';

    await harness.habits.upsertHabit(
      Habit(
        id: archiveId,
        title: 'To Archive',
        color: '#10B981',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.boolean,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await harness.habits.upsertHabit(
      Habit(
        id: deleteId,
        title: 'To Delete',
        color: '#EF4444',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.boolean,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await harness.habits.setArchived(archiveId, true);
    final activeAfterArchive = await harness.habits.getActiveHabits().first;
    final archived = await harness.habits.getArchivedHabits().first;
    expect(activeAfterArchive.map((h) => h.id), isNot(contains(archiveId)));
    expect(archived.map((h) => h.id), contains(archiveId));
    expect(activeAfterArchive.map((h) => h.id), contains(deleteId));

    final toDelete = await harness.habits.getHabitByIdOnce(deleteId);
    await harness.habits.deleteHabit(toDelete!);

    final activeAfterDelete = await harness.habits.getActiveHabits().first;
    final archivedAfterDelete = await harness.habits.getArchivedHabits().first;
    expect(activeAfterDelete.map((h) => h.id), isNot(contains(deleteId)));
    expect(archivedAfterDelete.map((h) => h.id), isNot(contains(deleteId)));
    expect(await harness.habits.getHabitByIdOnce(deleteId), isNull);
  });
}
