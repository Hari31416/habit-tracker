import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/engines/subday_slot_engine.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_log.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/domain/models/time_window.dart';
import 'package:uuid/uuid.dart';

void main() {
  const uuid = Uuid();

  Habit createHabit({
    TimeWindow? timeWindow,
    int? intervalHours,
    int? timesPerDay,
  }) {
    final now = DateTime.now().toUtc();
    return Habit(
      id: 'slot-habit-1',
      title: 'Hydration Slots',
      color: '#3b82f6',
      frequencyType: HabitFrequencyType.subdayInterval,
      targetType: HabitTargetType.boolean,
      timeWindow: timeWindow,
      intervalHours: intervalHours,
      timesPerDay: timesPerDay,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('generateSlots_withTimeWindowAndInterval_generatesExpectedSlots', () {
    final habit = createHabit(
      timeWindow: const TimeWindow(startTime: '08:00', endTime: '14:00'),
      intervalHours: 2,
    );

    final slots = SubdaySlotEngine.generateSlots(habit);

    // 08:00, 10:00, 12:00, 14:00 -> 4 slots
    expect(slots.length, 4);
    expect(slots.map((s) => s.timeLabel).toList(), ['08:00', '10:00', '12:00', '14:00']);
    expect(slots.map((s) => s.index).toList(), [0, 1, 2, 3]);
  });

  test('generateSlots_withLogs_mapsCompletionStatusCorrectly', () {
    final habit = createHabit(
      timeWindow: const TimeWindow(startTime: '08:00', endTime: '12:00'),
      intervalHours: 2,
    );
    final now = DateTime.now().toUtc();
    final logs = [
      HabitLog(
        id: uuid.v4(),
        habitId: habit.id,
        date: '2026-08-17',
        timestamp: now,
        completed: true,
        intervalIndex: 1, // 10:00 completed
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final slots = SubdaySlotEngine.generateSlots(habit, logs);

    // 08:00 (index 0 - false), 10:00 (index 1 - true), 12:00 (index 2 - false)
    expect(slots.length, 3);
    expect(slots[0].completed, isFalse);
    expect(slots[1].completed, isTrue);
    expect(slots[2].completed, isFalse);
  });

  test('generateSlots_withoutTimeWindow_generatesNumberedSlots', () {
    final habit = createHabit(timesPerDay: 3);

    final slots = SubdaySlotEngine.generateSlots(habit);

    expect(slots.length, 3);
    expect(slots.map((s) => s.timeLabel).toList(), ['#1', '#2', '#3']);
  });
}
