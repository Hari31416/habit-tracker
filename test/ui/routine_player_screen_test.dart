import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/di/providers.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_routine.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/ui/routines/routine_player_screen.dart';
import '../helpers/test_factories.dart';

void main() {
  testWidgets('RoutinePlayerScreen guides user through sequential habit steps and finishes routine', (tester) async {
    final now = DateTime.utc(2026, 8, 21);

    final habit1 = Habit(
      id: 'h1',
      title: 'Deep Breathing',
      color: '#3B82F6',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      createdAt: now,
      updatedAt: now,
    );
    final habit2 = Habit(
      id: 'h2',
      title: 'Pushups',
      color: '#EF4444',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.numeric,
      targetValue: 20.0,
      unit: 'reps',
      createdAt: now,
      updatedAt: now,
    );

    final routine = HabitRoutine(
      id: 'routine_morning',
      title: 'Morning Flow',
      color: '#3B82F6',
      habitIds: const ['h1', 'h2'],
      bonusXp: 30,
      createdAt: now,
      updatedAt: now,
    );

    final mockHabitRepo = FakeHabitRepository(
      initialHabits: [habit1, habit2],
    );
    final mockRoutineRepo = MockRoutineRepository(
      initialRoutines: [routine],
    );

    var backCalled = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitRepositoryProvider.overrideWithValue(mockHabitRepo),
          routineRepositoryProvider.overrideWithValue(mockRoutineRepo),
          activeHabitsStreamProvider.overrideWith((ref) => Stream.value([habit1, habit2])),
          activeRoutinesStreamProvider.overrideWith((ref) => Stream.value([routine])),
        ],
        child: MaterialApp(
          home: RoutinePlayerScreen(
            routineId: 'routine_morning',
            onBack: () {
              backCalled = true;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Step 1
    expect(find.text('Deep Breathing'), findsOneWidget);
    expect(find.text('Step 1 of 2'), findsOneWidget);
    expect(find.text('Done & Next'), findsOneWidget);

    // Complete Step 1
    await tester.tap(find.text('Done & Next'));
    await tester.pump();

    // Verify Step transition countdown
    expect(find.text('Step Complete!'), findsOneWidget);
    expect(find.textContaining('Up next in the chain: Pushups'), findsOneWidget);

    // Tap continue to advance to Step 2
    await tester.tap(find.textContaining('Continue'));
    await tester.pumpAndSettle();

    // Verify Step 2
    expect(find.text('Pushups'), findsOneWidget);
    expect(find.text('Step 2 of 2'), findsOneWidget);
    expect(find.text('Complete Stack'), findsOneWidget);

    // Complete final step
    await tester.tap(find.text('Complete Stack'));
    await tester.pumpAndSettle();

    // Verify Celebration Screen
    expect(find.text('Stack Completed!'), findsOneWidget);
    expect(find.textContaining('+30 XP Bonus'), findsOneWidget);
    expect(find.text('Back to Dashboard'), findsOneWidget);

    await tester.tap(find.text('Back to Dashboard'));
    await tester.pump();

    expect(backCalled, isTrue);
  });

  testWidgets('RoutinePlayerScreen marks timesPerDay habit slots completed', (tester) async {
    final now = DateTime.utc(2026, 8, 21);

    final waterHabit = Habit(
      id: 'seed_habit_water',
      title: 'Hydration Intake',
      color: '#0EA5E9',
      frequencyType: HabitFrequencyType.timesPerDay,
      timesPerDay: 4,
      targetType: HabitTargetType.boolean,
      createdAt: now,
      updatedAt: now,
    );

    final routine = HabitRoutine(
      id: 'routine_hydration',
      title: 'Hydration Stack',
      color: '#0EA5E9',
      habitIds: const ['seed_habit_water'],
      bonusXp: 20,
      createdAt: now,
      updatedAt: now,
    );

    final mockHabitRepo = FakeHabitRepository(
      initialHabits: [waterHabit],
    );
    final mockRoutineRepo = MockRoutineRepository(
      initialRoutines: [routine],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitRepositoryProvider.overrideWithValue(mockHabitRepo),
          routineRepositoryProvider.overrideWithValue(mockRoutineRepo),
          activeHabitsStreamProvider.overrideWith((ref) => Stream.value([waterHabit])),
          activeRoutinesStreamProvider.overrideWith((ref) => Stream.value([routine])),
        ],
        child: MaterialApp(
          home: RoutinePlayerScreen(
            routineId: 'routine_hydration',
            onBack: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Hydration Intake'), findsOneWidget);
    expect(find.text('Daily Target: 4 check-ins'), findsOneWidget);

    // Tap Complete Stack
    await tester.tap(find.text('Complete Stack'));
    await tester.pumpAndSettle();

    // Verify all 4 interval slots were logged in repository
    final logs = await mockHabitRepo.getLogsForDateOnce(now);
    final waterLogs = logs.where((l) => l.habitId == 'seed_habit_water').toList();
    expect(waterLogs.length, 4);
    expect(waterLogs.every((l) => l.completed), isTrue);
    expect(waterLogs.map((l) => l.intervalIndex).toSet(), {0, 1, 2, 3});
  });
}
