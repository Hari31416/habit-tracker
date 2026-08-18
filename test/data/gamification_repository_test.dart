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

void main() {
  late AppDatabase db;
  late HabitRepositoryImpl habitRepository;
  late GamificationRepositoryImpl gamificationRepository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    habitRepository = HabitRepositoryImpl(
      habitDao: db.habitDao,
      habitLogDao: db.habitLogDao,
      habitCategoryDao: db.habitCategoryDao,
      reminderScheduler: const NoOpHabitReminderScheduler(),
    );
    gamificationRepository = GamificationRepositoryImpl(
      habitDao: db.habitDao,
      habitLogDao: db.habitLogDao,
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
    expect(progression.level, 1);
    expect(progression.title, PlayerTitle.novice);

    final achievements = await gamificationRepository.getAchievements().first;
    final vol1 = achievements.firstWhere((a) => a.definition.id == 'vol_1');
    expect(vol1.isUnlocked, isTrue);
  });
}
