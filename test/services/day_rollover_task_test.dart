import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/background/day_rollover_task.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/services/widget_sync_service.dart';

import '../ui/habit_detail_controller_test.dart' show FakeHabitRepository;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('calculateDelayToNextMidnight calculates positive delay until 00:01', () {
    // 23:30 on August 17 -> 31 minutes until 00:01 on August 18
    final ref = DateTime(2026, 8, 17, 23, 30);
    final delay = DayRolloverTask.calculateDelayToNextMidnight(ref);

    expect(delay.inMinutes, 31);
  });

  test('executeRollover synchronizes widgets successfully', () async {
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
    final rolloverTask = DayRolloverTask(widgetSync);

    final success = await rolloverTask.executeRollover();

    expect(success, isTrue);
    expect(widgetSync.lastDailyFocus, isNotNull);
    expect(widgetSync.lastDailyFocus!.totalScheduled, 1);
  });
}
