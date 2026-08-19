import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/local/app_database.dart';
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

  test('FlutterHabitReminderScheduler schedules future reminders when permission granted', () async {
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
}
