import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/local/app_database.dart';
import 'package:habit_tracker/data/repositories/habit_repository_impl.dart';
import 'package:habit_tracker/data/schedulers/no_op_habit_reminder_scheduler.dart';
import 'package:habit_tracker/domain/models/habit.dart';
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

  test('logCheckIn with energyLevel, mood, and note stores reflection accurately', () async {
    final now = DateTime.now().toUtc();
    final today = DateTime(2026, 8, 18);
    final habit = Habit(
      id: 'h-reflect-1',
      title: 'Morning Yoga',
      color: '#10B981',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      createdAt: now,
      updatedAt: now,
    );

    await repository.upsertHabit(habit);
    await repository.logCheckIn(
      habitId: habit.id,
      date: today,
      completed: true,
      energyLevel: 5,
      mood: 'energized',
      note: 'Deep breathing practice felt refreshing',
    );

    final logs = await repository.getLogsForHabitOnce(habit.id);
    expect(logs.length, 1);
    expect(logs.first.completed, isTrue);
    expect(logs.first.energyLevel, 5);
    expect(logs.first.mood, 'energized');
    expect(logs.first.note, 'Deep breathing practice felt refreshing');
  });

  test('updateReflection updates existing log reflection fields', () async {
    final now = DateTime.now().toUtc();
    final today = DateTime(2026, 8, 18);
    final habit = Habit(
      id: 'h-reflect-2',
      title: 'Reading',
      color: '#3B82F6',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      createdAt: now,
      updatedAt: now,
    );

    await repository.upsertHabit(habit);
    await repository.toggleBooleanCheckIn(habit.id, today);

    // Initial log created by check-in has null reflection
    var logs = await repository.getLogsForHabitOnce(habit.id);
    expect(logs.length, 1);
    expect(logs.first.energyLevel, isNull);

    // Update reflection
    await repository.updateReflection(
      habitId: habit.id,
      date: today,
      energyLevel: 4,
      mood: 'focused',
      note: 'Finished chapter 4',
    );

    logs = await repository.getLogsForHabitOnce(habit.id);
    expect(logs.length, 1);
    expect(logs.first.energyLevel, 4);
    expect(logs.first.mood, 'focused');
    expect(logs.first.note, 'Finished chapter 4');
  });
}
