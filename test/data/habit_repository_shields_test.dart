import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/local/app_database.dart';
import 'package:habit_tracker/data/repositories/gamification_repository_impl.dart';
import 'package:habit_tracker/data/repositories/habit_repository_impl.dart';
import 'package:habit_tracker/data/schedulers/no_op_habit_reminder_scheduler.dart';
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
      habitShieldDao: db.habitShieldDao,
      habitCategoryDao: db.habitCategoryDao,
      gamificationDao: db.gamificationDao,
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

  test('toggleShield and applyShield respect shield bank available balance', () async {
    final now = DateTime.now().toUtc();
    final day1 = DateTime(2026, 8, 17);
    final day2 = DateTime(2026, 8, 18);

    final habit = Habit(
      id: 'test-shield-balance-habit',
      title: 'Deep Work',
      color: '#3B82F6',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      createdAt: now,
      updatedAt: now,
    );

    await habitRepository.upsertHabit(habit);

    // Initial state: 1 starter shield available (0 used)
    var bankState = await gamificationRepository.getShieldBankState().first;
    expect(bankState.availableShields, 1);
    expect(bankState.usedShieldsCount, 0);

    // 1. First shield application succeeds
    final firstApply = await habitRepository.applyShield(habitId: habit.id, date: day1);
    expect(firstApply, isTrue);

    bankState = await gamificationRepository.getShieldBankState().first;
    expect(bankState.availableShields, 0);
    expect(bankState.usedShieldsCount, 1);

    // 2. Second shield application fails because availableShields == 0
    final secondApply = await habitRepository.toggleShield(habit.id, day2);
    expect(secondApply, isFalse);

    // Ensure 2nd shield was NOT created in DB
    final isDay2Shielded = await habitRepository.isDateShielded(habit.id, day2);
    expect(isDay2Shielded, isFalse);

    bankState = await gamificationRepository.getShieldBankState().first;
    expect(bankState.availableShields, 0);
    expect(bankState.usedShieldsCount, 1);

    // 3. Removing the first shield restores available balance
    final removeResult = await habitRepository.toggleShield(habit.id, day1);
    expect(removeResult, isTrue);

    bankState = await gamificationRepository.getShieldBankState().first;
    expect(bankState.availableShields, 1);
    expect(bankState.usedShieldsCount, 0);

    // 4. Now day 2 can be shielded
    final day2Success = await habitRepository.toggleShield(habit.id, day2);
    expect(day2Success, isTrue);
    expect(await habitRepository.isDateShielded(habit.id, day2), isTrue);
  });
}
