import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/local/app_database.dart';
import 'package:habit_tracker/data/repositories/gamification_repository_impl.dart';
import 'package:habit_tracker/data/repositories/habit_repository_impl.dart';
import 'package:habit_tracker/data/schedulers/no_op_habit_reminder_scheduler.dart';
import 'package:habit_tracker/domain/gamification/player_title.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/domain/models/habit_tier.dart';

void main() {
  late AppDatabase db;
  late HabitRepositoryImpl habitRepository;
  late GamificationRepositoryImpl gamificationRepository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    habitRepository = HabitRepositoryImpl(
      habitDao: db.habitDao,
      habitLogDao: db.habitLogDao,
      habitShieldDao: db.habitShieldDao,
      habitCategoryDao: db.habitCategoryDao,
      reminderScheduler: const NoOpHabitReminderScheduler(),
    );
    gamificationRepository = GamificationRepositoryImpl(
      habitDao: db.habitDao,
      habitLogDao: db.habitLogDao,
      habitShieldDao: db.habitShieldDao,
      habitCategoryDao: db.habitCategoryDao,
      gamificationDao: db.gamificationDao,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('gamificationRepository calculates progression and unlocks achievements', () async {
    final now = DateTime.now().toUtc();
    final today = DateTime(2026, 8, 18);
    final habit = Habit(
      id: 'test-h1',
      title: 'Workout',
      color: '#10B981',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      createdAt: now,
      updatedAt: now,
    );

    await habitRepository.upsertHabit(habit);
    await habitRepository.toggleBooleanCheckIn(habit.id, today);

    final progression = await gamificationRepository.getPlayerProgression().first;
    expect(progression.level, 2);
    expect(progression.title, PlayerTitle.novice);

    final achievements = await gamificationRepository.getAchievements().first;
    final vol1 = achievements.firstWhere((a) => a.definition.id == 'vol_1');
    expect(vol1.isUnlocked, isTrue);
  });

  test('gamificationRepository computes shield bank state and updates shield settings', () async {
    final bankState = await gamificationRepository.getShieldBankState().first;
    expect(bankState.totalShieldsEarned, 1);
    expect(bankState.availableShields, 1);
    expect(bankState.maxCapacity, 3);
    expect(bankState.autoConsumeEnabled, true);

    await gamificationRepository.updateShieldSettings(
      maxCapacity: 5,
      autoConsume: false,
    );

    final updated = await gamificationRepository.getShieldBankState().first;
    expect(updated.maxCapacity, 5);
    expect(updated.autoConsumeEnabled, false);
  });

  test('gamificationRepository converges level-dependent mastery achievements', () async {
    final now = DateTime.utc(2026, 8, 20, 10, 0, 0);
    // Create habits and logs to generate enough XP for level >= 10
    final habit = Habit(
      id: 'h_mastery',
      title: 'Mastery Habit',
      color: '#3B82F6',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.numeric,
      targetValue: 100.0,
      eliteTargetValue: 100.0,
      createdAt: now,
      updatedAt: now,
    );
    await habitRepository.upsertHabit(habit);

    // Add 100 days of completions
    for (int i = 0; i < 100; i++) {
      final date = DateTime.utc(2026, 1, 1).add(Duration(days: i));
      await habitRepository.logTierCheckIn(
        habit.id,
        date,
        HabitTier.elite,
      );
    }

    final progression = await gamificationRepository.getPlayerProgression().first;
    expect(progression.level, greaterThanOrEqualTo(10));

    final achievements = await gamificationRepository.getAchievements().first;
    final lvl5 = achievements.firstWhere((a) => a.definition.id == 'mastery_lvl_5');
    final lvl10 = achievements.firstWhere((a) => a.definition.id == 'mastery_lvl_10');

    expect(lvl5.isUnlocked, isTrue);
    expect(lvl10.isUnlocked, isTrue);
    expect(lvl10.currentProgress, 10);
  });
}
