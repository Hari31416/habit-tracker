import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/background/day_rollover_task.dart';
import 'package:habit_tracker/data/local/app_database.dart';
import 'package:habit_tracker/data/repositories/gamification_repository_impl.dart';
import 'package:habit_tracker/data/repositories/habit_repository_impl.dart';
import 'package:habit_tracker/data/schedulers/no_op_habit_reminder_scheduler.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/services/widget_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ui/habit_detail_controller_test.dart' show FakeHabitRepository;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('calculateDelayToNextMidnight calculates positive delay until 00:01', () {
    // 23:30 on August 17 -> 31 minutes until 00:01 on August 18
    final ref = DateTime(2026, 8, 17, 23, 30);
    final delay = DayRolloverTask.calculateDelayToNextMidnight(ref);

    expect(delay.inMinutes, 31);
  });

  test('calculateDelayToNextMidnight handles 00:00 correctly', () {
    final ref = DateTime(2026, 8, 17, 0, 0);
    final delay = DayRolloverTask.calculateDelayToNextMidnight(ref);

    // 24 hours + 1 minute
    expect(delay.inMinutes, 24 * 60 + 1);
  });

  test('executeRollover synchronizes widgets and writes last_rollover_date', () async {
    final habit = Habit(
      id: 'rollover_h1',
      title: 'Workout',
      color: '#10B981',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final repo = FakeHabitRepository(initialHabits: [habit]);
    final widgetSync = WidgetSyncService(repo);
    final prefs = await SharedPreferences.getInstance();
    final rolloverTask = DayRolloverTask(widgetSync, repo, prefs);

    final today = DateTime(2026, 8, 19);
    final success = await rolloverTask.executeRollover(today);

    expect(success, isTrue);
    expect(widgetSync.lastDailyFocus, isNotNull);
    expect(widgetSync.lastDailyFocus!.totalScheduled, 1);
    expect(prefs.getString(DayRolloverTask.lastRolloverDateKey), '2026-08-19');
  });

  test('executeRollover is idempotent and does not repeat on the same date', () async {
    SharedPreferences.setMockInitialValues({
      DayRolloverTask.lastRolloverDateKey: '2026-08-19',
    });
    final prefs = await SharedPreferences.getInstance();

    var autoProtectCalled = false;
    final habit = Habit(
      id: 'rollover_h1',
      title: 'Workout',
      color: '#10B981',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final repo = FakeHabitRepository(initialHabits: [habit]);
    final widgetSync = WidgetSyncService(repo);
    final rolloverTask = DayRolloverTask(widgetSync, repo, prefs);

    // Running rollover for 2026-08-19 when last_rollover_date is already 2026-08-19
    final success = await rolloverTask.executeRollover(DateTime(2026, 8, 19));
    expect(success, isTrue);
    expect(autoProtectCalled, isFalse);
  });

  test('executeRollover auto-protects missed day with real database', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final habitRepo = HabitRepositoryImpl(
      habitDao: db.habitDao,
      habitLogDao: db.habitLogDao,
      habitShieldDao: db.habitShieldDao,
      habitCategoryDao: db.habitCategoryDao,
      gamificationDao: db.gamificationDao,
      reminderScheduler: const NoOpHabitReminderScheduler(),
    );
    final gamificationRepo = GamificationRepositoryImpl(
      gamificationDao: db.gamificationDao,
      habitDao: db.habitDao,
      habitLogDao: db.habitLogDao,
      habitShieldDao: db.habitShieldDao,
      habitCategoryDao: db.habitCategoryDao,
    );
    final widgetSync = WidgetSyncService(habitRepo, gamificationRepo);
    final prefs = await SharedPreferences.getInstance();
    final rolloverTask = DayRolloverTask(widgetSync, habitRepo, prefs);

    final habit = Habit(
      id: 'h_streak',
      title: 'Meditation',
      color: '#10B981',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    );
    await habitRepo.upsertHabit(habit);

    // Build a 7-day streak ending on August 17 so we earn a banked shield (milestone: 7 days)
    for (int day = 11; day <= 17; day++) {
      await habitRepo.logCheckIn(
        habitId: habit.id,
        date: DateTime(2026, 8, day),
        completed: true,
      );
    }

    // August 18 was missed (no log)
    // Rollover runs on August 19
    final today = DateTime(2026, 8, 19);
    final success = await rolloverTask.executeRollover(today);
    expect(success, isTrue);

    // Verify August 18 received an auto-applied shield
    final shields = await habitRepo.getShieldsForDateOnce(DateTime(2026, 8, 18));
    expect(shields.isNotEmpty, isTrue);
    expect(shields.first.habitId, habit.id);
    expect(shields.first.autoApplied, isTrue);

    await db.close();
  });
}
