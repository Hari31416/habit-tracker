import 'package:drift/native.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/local/app_database.dart';
import 'package:habit_tracker/data/repositories/habit_repository_impl.dart';
import 'package:habit_tracker/data/schedulers/flutter_habit_reminder_scheduler.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();

  late AppDatabase db;
  late FlutterHabitReminderScheduler scheduler;

  setUp(() {
    NotificationService.mockMode = true;
    NotificationService.resetMockData();

    db = AppDatabase(NativeDatabase.memory());
    scheduler = FlutterHabitReminderScheduler(db.habitDao);
  });

  tearDown(() async {
    await db.close();
    NotificationService.mockMode = false;
  });

  test('FlutterHabitReminderScheduler gracefully handles archived habits', () async {
    final archivedHabit = Habit(
      id: 'archived_1',
      title: 'Old Habit',
      color: '#10B981',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      reminderTimes: const ['08:00'],
      archived: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Scheduling an archived habit should cancel and return without errors
    await scheduler.schedule(archivedHabit);
    expect(NotificationService.mockCancelledIds.length, 10);
    expect(NotificationService.mockScheduledNotifications.isEmpty, isTrue);
  });

  test('FlutterHabitReminderScheduler gracefully handles habits with empty reminders', () async {
    final noReminderHabit = Habit(
      id: 'no_remind_1',
      title: 'No Reminders',
      color: '#10B981',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      reminderTimes: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await scheduler.schedule(noReminderHabit);
    expect(NotificationService.mockCancelledIds.length, 10);
    expect(NotificationService.mockScheduledNotifications.isEmpty, isTrue);
  });

  test('FlutterHabitReminderScheduler schedules future reminders when permission granted with repeating components', () async {
    final activeHabit = Habit(
      id: 'active_1',
      title: 'Read Book',
      color: '#3B82F6',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      reminderTimes: const ['23:59'], // Far enough in future today
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await scheduler.schedule(activeHabit);
    expect(NotificationService.mockCancelledIds.length, 10);
    expect(NotificationService.mockScheduledNotifications.length, 1);
    expect(NotificationService.mockScheduledNotifications.first['id'], isNotNull);
    expect(
      NotificationService.mockScheduledNotifications.first['matchDateTimeComponents'],
      DateTimeComponents.time,
    );
  });

  test('FlutterHabitReminderScheduler schedules weekly habit with repeating time components', () async {
    final weeklyHabit = Habit(
      id: 'weekly_1',
      title: 'Weekly Review',
      color: '#3B82F6',
      frequencyType: HabitFrequencyType.weekly,
      targetCountPerWeek: 3,
      targetType: HabitTargetType.boolean,
      reminderTimes: const ['18:00'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await scheduler.schedule(weeklyHabit);
    expect(NotificationService.mockScheduledNotifications.length, 1);
    expect(
      NotificationService.mockScheduledNotifications.first['matchDateTimeComponents'],
      DateTimeComponents.time,
    );
  });

  test('FlutterHabitReminderScheduler schedules customDays habit with matchDateTimeComponents null', () async {
    final customDaysHabit = Habit(
      id: 'custom_1',
      title: 'Workout',
      color: '#EF4444',
      frequencyType: HabitFrequencyType.customDays,
      targetDaysOfWeek: const [1, 3, 5], // Mon, Wed, Fri
      targetType: HabitTargetType.boolean,
      reminderTimes: const ['07:00'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await scheduler.schedule(customDaysHabit);
    expect(NotificationService.mockScheduledNotifications.length, 1);
    expect(
      NotificationService.mockScheduledNotifications.first['matchDateTimeComponents'],
      isNull,
    );
  });

  test('calculateNextOccurrence advances to tomorrow if reminder time passed today for daily habit', () {
    final dailyHabit = Habit(
      id: 'daily_past',
      title: 'Morning Yoga',
      color: '#10B981',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      reminderTimes: const ['06:00'],
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    );

    final refTime = DateTime(2026, 8, 19, 10, 0); // 10:00 AM (past 06:00 AM)
    final reminderTime = DateTime(2026, 8, 19, 6, 0);

    final next = scheduler.calculateNextOccurrence(dailyHabit, reminderTime, refTime);
    expect(next.year, 2026);
    expect(next.month, 8);
    expect(next.day, 20);
    expect(next.hour, 6);
    expect(next.minute, 0);
  });

  test('calculateNextOccurrence finds next valid custom day if reminder time passed today', () {
    final customHabit = Habit(
      id: 'custom_past',
      title: 'Weekend Project',
      color: '#10B981',
      frequencyType: HabitFrequencyType.customDays,
      targetDaysOfWeek: const [6, 0], // Sat and Sun (0=Sun, 6=Sat)
      targetType: HabitTargetType.boolean,
      reminderTimes: const ['09:00'],
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    );

    // Reference: Sunday, August 23, 2026 at 11:00 AM (already past 09:00 AM)
    final refTime = DateTime(2026, 8, 23, 11, 0);
    final reminderTime = DateTime(2026, 8, 23, 9, 0);

    final next = scheduler.calculateNextOccurrence(customHabit, reminderTime, refTime);
    // Next occurrence should be Saturday, August 29, 2026
    expect(next.year, 2026);
    expect(next.month, 8);
    expect(next.day, 29);
    expect(next.hour, 9);
    expect(next.minute, 0);
  });

  test('FlutterHabitReminderScheduler schedules current-minute reminders', () async {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final activeHabit = Habit(
      id: 'current_minute_1',
      title: 'Deep Work Session',
      color: '#3B82F6',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.timer,
      reminderTimes: [timeStr],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await scheduler.schedule(activeHabit, catchUpIfDue: true);

    expect(NotificationService.mockScheduledNotifications.length, 1);
    final scheduledDate =
        NotificationService.mockScheduledNotifications.first['scheduledDate']
            as tz.TZDateTime;
    expect(scheduledDate.isAfter(tz.TZDateTime.now(tz.local).subtract(const Duration(seconds: 2))), isTrue);
  });

  test('FlutterHabitReminderScheduler cancel completes successfully', () async {
    await scheduler.cancel('test_habit_id');
    expect(NotificationService.mockCancelledIds.length, 10);
  });

  test('FlutterHabitReminderScheduler rescheduleAll completes with empty DB', () async {
    await scheduler.rescheduleAll();
  });

  test('HabitRepository check-in reschedules reminders for active habit', () async {
    final repo = HabitRepositoryImpl(
      habitDao: db.habitDao,
      habitLogDao: db.habitLogDao,
      habitShieldDao: db.habitShieldDao,
      habitCategoryDao: db.habitCategoryDao,
      reminderScheduler: scheduler,
    );

    final habit = Habit(
      id: 'repo_remind_habit',
      title: 'Workout',
      color: '#10B981',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      reminderTimes: const ['20:00'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await repo.upsertHabit(habit);
    NotificationService.resetMockData();

    await repo.logCheckIn(
      habitId: habit.id,
      date: DateTime.now(),
      completed: true,
    );

    expect(NotificationService.mockScheduledNotifications.isNotEmpty, isTrue);
    expect(
      NotificationService.mockScheduledNotifications.last['matchDateTimeComponents'],
      DateTimeComponents.time,
    );
  });
}
