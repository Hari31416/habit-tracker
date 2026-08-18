import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/local/app_database.dart';
import 'package:habit_tracker/data/repositories/habit_repository_impl.dart';
import 'package:habit_tracker/data/schedulers/no_op_habit_reminder_scheduler.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_category.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';

void main() {
  late AppDatabase db;
  late HabitRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = HabitRepositoryImpl(
      habitDao: db.habitDao,
      habitLogDao: db.habitLogDao,
      habitShieldDao: db.habitShieldDao,
      habitCategoryDao: db.habitCategoryDao,
      reminderScheduler: const NoOpHabitReminderScheduler(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('upsertHabit and getActiveHabits stores and retrieves habit', () async {
    final now = DateTime.now().toUtc();
    final habit = Habit(
      id: 'test-h1',
      title: 'Workout',
      color: '#10B981',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      createdAt: now,
      updatedAt: now,
    );

    await repository.upsertHabit(habit);
    final active = await repository.getActiveHabits().first;

    expect(active.length, 6); // 5 seed habits + 1 new habit
    expect(active.any((h) => h.id == 'test-h1'), isTrue);
    final found = active.firstWhere((h) => h.id == 'test-h1');
    expect(found.title, 'Workout');
  });

  test('toggleBooleanCheckIn toggles habit completion on date', () async {
    final now = DateTime.now().toUtc();
    final today = DateTime(2026, 8, 18);
    final habit = Habit(
      id: 'test-h2',
      title: 'Meditation',
      color: '#8B5CF6',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      createdAt: now,
      updatedAt: now,
    );

    await repository.upsertHabit(habit);

    // Initial state: 0 logs
    var logs = await repository.getLogsForDateOnce(today);
    expect(logs.isEmpty, isTrue);

    // Toggle check-in -> should insert completed log
    await repository.toggleBooleanCheckIn(habit.id, today);
    logs = await repository.getLogsForDateOnce(today);
    expect(logs.length, 1);
    expect(logs.first.completed, isTrue);

    // Toggle again -> should delete completed log (uncheck)
    await repository.toggleBooleanCheckIn(habit.id, today);
    logs = await repository.getLogsForDateOnce(today);
    expect(logs.isEmpty, isTrue);
  });

  test('updateNumericValue and addNumericDelta updates numeric habit logs', () async {
    final now = DateTime.now().toUtc();
    final today = DateTime(2026, 8, 18);
    final habit = Habit(
      id: 'test-h3',
      title: 'Water Intake',
      color: '#0EA5E9',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.numeric,
      targetValue: 2000.0,
      unit: 'ml',
      createdAt: now,
      updatedAt: now,
    );

    await repository.upsertHabit(habit);

    await repository.updateNumericValue(habit.id, today, 500.0);
    var logs = await repository.getLogsForDateOnce(today);
    expect(logs.length, 1);
    expect(logs.first.value, 500.0);
    expect(logs.first.completed, isFalse);

    await repository.addNumericDelta(habit.id, today, 1500.0);
    logs = await repository.getLogsForDateOnce(today);
    expect(logs.length, 1);
    expect(logs.first.value, 2000.0);
    expect(logs.first.completed, isTrue);
  });

  test('toggleSlotCheckIn independently toggles slot intervals', () async {
    final now = DateTime.now().toUtc();
    final today = DateTime(2026, 8, 18);
    final habit = Habit(
      id: 'test-h4',
      title: 'Hydration Slots',
      color: '#0EA5E9',
      frequencyType: HabitFrequencyType.timesPerDay,
      timesPerDay: 3,
      targetType: HabitTargetType.boolean,
      createdAt: now,
      updatedAt: now,
    );

    await repository.upsertHabit(habit);

    await repository.toggleSlotCheckIn(habit.id, today, 0);
    await repository.toggleSlotCheckIn(habit.id, today, 2);

    var logs = await repository.getLogsForDateOnce(today);
    expect(logs.length, 2);
    expect(logs.map((l) => l.intervalIndex).toSet(), {0, 2});

    // Toggle slot 0 off
    await repository.toggleSlotCheckIn(habit.id, today, 0);
    logs = await repository.getLogsForDateOnce(today);
    expect(logs.length, 1);
    expect(logs.first.intervalIndex, 2);
  });

  test('category operations work as expected', () async {
    const category = HabitCategory(
      id: 'cat_custom',
      name: 'Art & Creativity',
      color: '#EC4899',
      icon: 'palette',
    );

    await repository.upsertCategory(category);
    final retrieved = await repository.getCategoryById('cat_custom').first;
    expect(retrieved?.name, 'Art & Creativity');

    final all = await repository.getAllCategoriesOnce();
    expect(all.any((c) => c.id == 'cat_custom'), isTrue);

    await repository.deleteCategory(category);
    final afterDelete = await repository.getCategoryById('cat_custom').first;
    expect(afterDelete, isNull);
  });

  test('shield operations apply, retrieve, and toggle shields properly', () async {
    final now = DateTime.now().toUtc();
    final today = DateTime(2026, 8, 18);
    final habit = Habit(
      id: 'test-shield-habit',
      title: 'Workout',
      color: '#10B981',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      createdAt: now,
      updatedAt: now,
    );

    await repository.upsertHabit(habit);

    // Apply shield
    await repository.applyShield(habitId: habit.id, date: today);
    expect(await repository.isDateShielded(habit.id, today), isTrue);

    final shields = await repository.getShieldsForHabitOnce(habit.id);
    expect(shields.length, 1);
    expect(shields.first.date, '2026-08-18');

    // Toggle off
    await repository.toggleShield(habit.id, today);
    expect(await repository.isDateShielded(habit.id, today), isFalse);

    // Toggle back on
    await repository.toggleShield(habit.id, today);
    expect(await repository.isDateShielded(habit.id, today), isTrue);

    // Remove shield
    await repository.removeShield(habit.id, today);
    expect(await repository.isDateShielded(habit.id, today), isFalse);
  });
}
