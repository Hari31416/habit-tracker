import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/schedulers/local_notifications_scheduler.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';

import '../ui/habit_detail_controller_test.dart' show FakeHabitRepository;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final habit1 = Habit(
    id: 'notif_habit_1',
    title: 'Daily Morning Walk',
    color: '#10B981',
    frequencyType: HabitFrequencyType.daily,
    targetType: HabitTargetType.boolean,
    reminderTimes: const ['07:30', '18:00'],
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
  );

  final customDaysHabit = Habit(
    id: 'notif_habit_2',
    title: 'Weekend Reading',
    color: '#6366F1',
    frequencyType: HabitFrequencyType.customDays,
    targetDaysOfWeek: const [6, 0], // Saturday and Sunday (0=Sun, 6=Sat)
    targetType: HabitTargetType.boolean,
    reminderTimes: const ['10:00'],
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
  );

  late FakeHabitRepository fakeRepo;
  late LocalNotificationsScheduler scheduler;

  setUp(() {
    fakeRepo = FakeHabitRepository(
      initialHabits: [habit1, customDaysHabit],
    );
    scheduler = LocalNotificationsScheduler(fakeRepo);
  });

  test(
      'calculateNextOccurrence for daily habit when reminder time is in future today',
      () {
    // Reference time: 06:00 AM on Monday, August 17, 2026
    final refTime = DateTime(2026, 8, 17, 6, 0);
    final reminderTime = DateTime(2026, 8, 17, 7, 30);

    final next = scheduler.calculateNextOccurrence(habit1, reminderTime, refTime);

    expect(next.year, 2026);
    expect(next.month, 8);
    expect(next.day, 17);
    expect(next.hour, 7);
    expect(next.minute, 30);
  });

  test(
      'calculateNextOccurrence for daily habit when reminder time has passed advances to tomorrow',
      () {
    // Reference time: 08:00 AM on Monday, August 17, 2026 (past 07:30)
    final refTime = DateTime(2026, 8, 17, 8, 0);
    final reminderTime = DateTime(2026, 8, 17, 7, 30);

    final next = scheduler.calculateNextOccurrence(habit1, reminderTime, refTime);

    expect(next.year, 2026);
    expect(next.month, 8);
    expect(next.day, 18);
    expect(next.hour, 7);
    expect(next.minute, 30);
  });

  test(
      'calculateNextOccurrence keeps today when reminder is the current minute',
      () {
    final refTime = DateTime(2026, 8, 17, 7, 30, 45);
    final reminderTime = DateTime(2026, 8, 17, 7, 30);

    final next = scheduler.calculateNextOccurrence(habit1, reminderTime, refTime);

    expect(next.year, 2026);
    expect(next.month, 8);
    expect(next.day, 17);
    expect(next.hour, 7);
    expect(next.minute, 30);
  });

  test(
      'calculateNextOccurrence for customDays habit skips non-scheduled days',
      () {
    // Reference: Monday, August 17, 2026 (weekday=1)
    // Custom days are Sat (6) and Sun (0)
    // Next occurrence should be Saturday, August 22, 2026
    final refTime = DateTime(2026, 8, 17, 9, 0);
    final reminderTime = DateTime(2026, 8, 17, 10, 0);

    final next = scheduler.calculateNextOccurrence(
      customDaysHabit,
      reminderTime,
      refTime,
    );

    expect(next.year, 2026);
    expect(next.month, 8);
    expect(next.day, 22); // Saturday
    expect(next.hour, 10);
    expect(next.minute, 0);
  });

  test('schedule creates expected notification items for active habit', () async {
    await scheduler.schedule(habit1);

    final items = scheduler.scheduledItems[habit1.id];
    expect(items, isNotNull);
    expect(items!.length, 2);
    expect(items[0].reminderIndex, 0);
    expect(items[0].requestCode, scheduler.generateRequestCode(habit1.id, 0));
    expect(items[1].reminderIndex, 1);
    expect(items[1].requestCode, scheduler.generateRequestCode(habit1.id, 1));
  });

  test('cancel removes scheduled items for habit', () async {
    await scheduler.schedule(habit1);
    expect(scheduler.scheduledItems[habit1.id]?.isNotEmpty, isTrue);

    scheduler.cancel(habit1.id);
    expect(scheduler.scheduledItems[habit1.id], isNull);
  });

  test('rescheduleAll schedules reminders for all active habits', () async {
    await scheduler.rescheduleAll();

    expect(scheduler.scheduledItems.containsKey(habit1.id), isTrue);
    expect(scheduler.scheduledItems.containsKey(customDaysHabit.id), isTrue);
  });
}
