import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_log.dart';
import 'package:habit_tracker/domain/models/habit_routine.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/domain/models/time_window.dart';
import 'package:habit_tracker/ui/daily/widgets/routine_chain_card.dart';

void main() {
  testWidgets('RoutineChainCard renders title, time window, bonus badge, and habit step chips', (tester) async {
    final now = DateTime.utc(2026, 8, 21);
    final todayStr = '2026-08-21';

    final habit1 = Habit(
      id: 'h1',
      title: 'Morning Water',
      color: '#3B82F6',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      createdAt: now,
      updatedAt: now,
    );
    final habit2 = Habit(
      id: 'h2',
      title: 'Stretching',
      color: '#10B981',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      createdAt: now,
      updatedAt: now,
    );

    final routine = HabitRoutine(
      id: 'routine_1',
      title: 'Morning Launch',
      description: 'Kickstart your day',
      color: '#3B82F6',
      icon: 'sun',
      targetTimeWindow: const TimeWindow(startTime: '06:00', endTime: '08:30'),
      habitIds: const ['h1', 'h2'],
      bonusXp: 35,
      createdAt: now,
      updatedAt: now,
    );

    final todayLogs = [
      HabitLog(
        id: 'log_1',
        habitId: 'h1',
        date: todayStr,
        timestamp: now,
        completed: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    var startRoutineCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoutineChainCard(
            routine: routine,
            allHabits: [habit1, habit2],
            todayLogs: todayLogs,
            onStartRoutine: (r) {
              startRoutineCalled = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Morning Launch'), findsOneWidget);
    expect(find.text('06:00 - 08:30'), findsOneWidget);
    expect(find.text('+35 XP'), findsOneWidget);
    expect(find.text('Morning Water'), findsOneWidget);
    expect(find.text('Stretching'), findsOneWidget);
    expect(find.text('1 of 2 Done'), findsOneWidget);

    await tester.tap(find.text('Resume'));
    await tester.pump();

    expect(startRoutineCalled, isTrue);
  });

  testWidgets('RoutineChainCard recognizes partial multi-slot check-in and partial numeric progress as satisfied steps', (tester) async {
    final now = DateTime.utc(2026, 8, 21);
    final todayStr = '2026-08-21';

    final hydration = Habit(
      id: 'water',
      title: 'Hydration Intake',
      color: '#0EA5E9',
      frequencyType: HabitFrequencyType.timesPerDay,
      timesPerDay: 4,
      targetType: HabitTargetType.boolean,
      createdAt: now,
      updatedAt: now,
    );
    final reading = Habit(
      id: 'reading',
      title: 'Read 20 Pages',
      color: '#10B981',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.numeric,
      targetValue: 20.0,
      unit: 'pages',
      createdAt: now,
      updatedAt: now,
    );

    final routine = HabitRoutine(
      id: 'routine_morning',
      title: 'Morning Momentum',
      color: '#3B82F6',
      habitIds: const ['water', 'reading'],
      bonusXp: 30,
      createdAt: now,
      updatedAt: now,
    );

    // Only 1 of 4 slots for water, and 5 of 20 pages for reading
    final partialLogs = [
      HabitLog(
        id: 'log_w',
        habitId: 'water',
        date: todayStr,
        timestamp: now,
        completed: true,
        intervalIndex: 0,
        createdAt: now,
        updatedAt: now,
      ),
      HabitLog(
        id: 'log_r',
        habitId: 'reading',
        date: todayStr,
        timestamp: now,
        completed: false,
        value: 5.0,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoutineChainCard(
            routine: routine,
            allHabits: [hydration, reading],
            todayLogs: partialLogs,
            onStartRoutine: (_) {},
          ),
        ),
      ),
    );

    // Both steps should be satisfied for the routine chain
    expect(find.text('Stack Complete!'), findsOneWidget);
    expect(find.text('Replay'), findsOneWidget);
  });
}
