import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/schedulers/notification_action_handler.dart';
import 'package:habit_tracker/data/schedulers/notification_channel_handler.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';

import '../ui/habit_detail_controller_test.dart' show FakeHabitRepository;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final today = DateTime.now();

  final boolHabit = Habit(
    id: 'h_bool',
    title: 'Floss Teeth',
    color: '#10B981',
    frequencyType: HabitFrequencyType.daily,
    targetType: HabitTargetType.boolean,
    createdAt: today,
    updatedAt: today,
  );

  final numHabit = Habit(
    id: 'h_num',
    title: 'Drink Water',
    color: '#06B6D4',
    frequencyType: HabitFrequencyType.daily,
    targetType: HabitTargetType.numeric,
    targetValue: 2000.0,
    unit: 'ml',
    createdAt: today,
    updatedAt: today,
  );

  final timerHabit = Habit(
    id: 'h_timer',
    title: 'Meditation',
    color: '#8B5CF6',
    frequencyType: HabitFrequencyType.daily,
    targetType: HabitTargetType.timer,
    targetValue: 20.0,
    createdAt: today,
    updatedAt: today,
  );

  test('NotificationPayload builds appropriate actions for boolean habit', () {
    final payload = NotificationPayload.buildNotification(boolHabit, 0);

    expect(payload.title, 'Floss Teeth');
    expect(payload.body, 'Ready for your daily check-in?');
    expect(payload.deepLinkUri, 'app://habits/detail/h_bool');
    expect(payload.actions.length, 2);
    expect(payload.actions[0].actionId, NotificationPayload.actionMarkDone);
    expect(payload.actions[0].label, 'Check-In');
    expect(payload.actions[1].actionId, NotificationPayload.actionViewHabit);
  });

  test('NotificationPayload builds step delta action for numeric habit', () {
    final payload = NotificationPayload.buildNotification(numHabit, 0);

    expect(payload.title, 'Drink Water');
    expect(payload.body.contains('Log progress'), isTrue);
    expect(payload.actions.length, 3);
    expect(payload.actions[0].label, 'Mark Done');
    expect(payload.actions[1].actionId, NotificationPayload.actionAddDelta);
    expect(payload.actions[1].delta, isNotNull);
  });

  test('NotificationPayload builds step delta action for timer habit', () {
    final payload = NotificationPayload.buildNotification(timerHabit, 0);

    expect(payload.title, 'Meditation');
    expect(payload.actions.length, 3);
    expect(payload.actions[1].actionId, NotificationPayload.actionAddDelta);
  });

  test('NotificationActionHandler handles ACTION_MARK_DONE for boolean habit',
      () async {
    final repo = FakeHabitRepository(initialHabits: [boolHabit]);
    final handler = NotificationActionHandler(repo);

    await handler.handleAction(
      action: NotificationPayload.actionMarkDone,
      habitId: boolHabit.id,
      date: today,
    );

    final logs = await repo.getLogsForHabitOnce(boolHabit.id);
    expect(logs.isNotEmpty, isTrue);
    expect(logs.first.completed, isTrue);
  });

  test('NotificationActionHandler handles ACTION_ADD_DELTA for numeric habit',
      () async {
    final repo = FakeHabitRepository(initialHabits: [numHabit]);
    final handler = NotificationActionHandler(repo);

    await handler.handleAction(
      action: NotificationPayload.actionAddDelta,
      habitId: numHabit.id,
      delta: 250.0,
      date: today,
    );

    final logs = await repo.getLogsForHabitOnce(numHabit.id);
    expect(logs.isNotEmpty, isTrue);
    expect(logs.first.value, 250.0);
  });
}
