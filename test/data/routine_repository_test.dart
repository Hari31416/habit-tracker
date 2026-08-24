import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/local/app_database.dart';
import 'package:habit_tracker/data/repositories/habit_repository_impl.dart';
import 'package:habit_tracker/data/repositories/routine_repository_impl.dart';
import 'package:habit_tracker/data/schedulers/no_op_habit_reminder_scheduler.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_routine.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/domain/models/time_window.dart';

void main() {
  late AppDatabase db;
  late HabitRepositoryImpl habitRepository;
  late RoutineRepositoryImpl routineRepository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    habitRepository = HabitRepositoryImpl(
      habitDao: db.habitDao,
      habitLogDao: db.habitLogDao,
      habitShieldDao: db.habitShieldDao,
      habitCategoryDao: db.habitCategoryDao,
      reminderScheduler: const NoOpHabitReminderScheduler(),
    );
    routineRepository = RoutineRepositoryImpl(
      routineDao: db.routineDao,
      gamificationDao: db.gamificationDao,
      habitDao: db.habitDao,
      habitLogDao: db.habitLogDao,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('upsertRoutine creates and retrieves habit routines', () async {
    final now = DateTime.utc(2026, 8, 21);
    final routine = HabitRoutine(
      id: 'routine_morning',
      title: 'Morning Flow',
      description: 'Start the day energized',
      color: '#3B82F6',
      icon: 'sun',
      targetTimeWindow: const TimeWindow(startTime: '06:00', endTime: '09:00'),
      habitIds: const ['h1', 'h2', 'h3'],
      bonusXp: 40,
      createdAt: now,
      updatedAt: now,
    );

    await routineRepository.upsertRoutine(routine);

    final activeRoutines = await routineRepository.getActiveRoutinesOnce();
    expect(activeRoutines.length, 1);
    expect(activeRoutines.first.id, 'routine_morning');
    expect(activeRoutines.first.title, 'Morning Flow');
    expect(activeRoutines.first.habitIds, ['h1', 'h2', 'h3']);
    expect(activeRoutines.first.bonusXp, 40);

    final single = await routineRepository.getRoutineById('routine_morning');
    expect(single, isNotNull);
    expect(single!.targetTimeWindow?.startTime, '06:00');
  });

  test('reorderHabitsInRoutine modifies sequential chain order', () async {
    final now = DateTime.utc(2026, 8, 21);
    final routine = HabitRoutine(
      id: 'routine_workday',
      title: 'Workday Routine',
      color: '#8B5CF6',
      habitIds: const ['h1', 'h2', 'h3'],
      createdAt: now,
      updatedAt: now,
    );

    await routineRepository.upsertRoutine(routine);
    await routineRepository.reorderHabitsInRoutine('routine_workday', const ['h3', 'h1', 'h2']);

    final updated = await routineRepository.getRoutineById('routine_workday');
    expect(updated?.habitIds, ['h3', 'h1', 'h2']);
  });

  test('deleteRoutine marks routine as deleted and excludes from active query', () async {
    final now = DateTime.utc(2026, 8, 21);
    final routine = HabitRoutine(
      id: 'routine_evening',
      title: 'Evening Wind-Down',
      color: '#10B981',
      habitIds: const ['h1', 'h2'],
      createdAt: now,
      updatedAt: now,
    );

    await routineRepository.upsertRoutine(routine);
    var active = await routineRepository.getActiveRoutinesOnce();
    expect(active.length, 1);

    await routineRepository.deleteRoutine('routine_evening');
    active = await routineRepository.getActiveRoutinesOnce();
    expect(active, isEmpty);

    final all = await routineRepository.getAllRoutinesOnce();
    expect(all.length, 1);
    expect(all.first.isDeleted, isTrue);
  });

  test('completeRoutine logs completion and awards scaled bonus XP based on streak', () async {
    final now = DateTime.utc(2026, 8, 21);
    final todayStr = '2026-08-21';

    // Create 2 habits
    final h1 = Habit(
      id: 'h1',
      title: 'Hydration',
      color: '#3B82F6',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      createdAt: now,
      updatedAt: now,
    );
    final h2 = Habit(
      id: 'h2',
      title: 'Meditation',
      color: '#8B5CF6',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      createdAt: now,
      updatedAt: now,
    );
    await habitRepository.upsertHabit(h1);
    await habitRepository.upsertHabit(h2);

    final routine = HabitRoutine(
      id: 'routine_flow',
      title: 'Morning Routine',
      color: '#3B82F6',
      habitIds: const ['h1', 'h2'],
      bonusXp: 30,
      createdAt: now,
      updatedAt: now,
    );
    await routineRepository.upsertRoutine(routine);

    final routineLog = await routineRepository.completeRoutine(
      routineId: 'routine_flow',
      date: todayStr,
      completedHabitIds: const ['h1', 'h2'],
    );

    expect(routineLog.routineId, 'routine_flow');
    expect(routineLog.date, todayStr);
    expect(routineLog.completedHabitIds, ['h1', 'h2']);
    expect(routineLog.xpEarned, 30); // 1.0x multiplier

    final logsForDate = await routineRepository.getRoutineLogsForDateOnce(todayStr);
    expect(logsForDate.length, 1);
    expect(logsForDate.first.xpEarned, 30);
  });
}
