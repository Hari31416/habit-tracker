import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/di/providers.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/ui/daily/dialogs/routine_builder_sheet.dart';
import '../helpers/test_factories.dart';

void main() {
  testWidgets('RoutineBuilderSheet creates routine with title and sequential habit selection', (tester) async {
    final now = DateTime.utc(2026, 8, 21);

    final habit1 = Habit(
      id: 'h1',
      title: 'Water',
      color: '#3B82F6',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      createdAt: now,
      updatedAt: now,
    );
    final habit2 = Habit(
      id: 'h2',
      title: 'Journaling',
      color: '#10B981',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      createdAt: now,
      updatedAt: now,
    );

    final mockRoutineRepo = MockRoutineRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routineRepositoryProvider.overrideWithValue(mockRoutineRepo),
          activeHabitsStreamProvider.overrideWith((ref) => Stream.value([habit1, habit2])),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => RoutineBuilderSheet.show(ctx),
                child: const Text('Open Builder'),
              ),
            ),
          ),
        ),
      ),
    );

    // Open sheet
    await tester.tap(find.text('Open Builder'));
    await tester.pumpAndSettle();

    expect(find.text('Create Habit Stack'), findsOneWidget);

    // Enter title
    await tester.enterText(find.byType(TextField).first, 'Evening Stack');
    await tester.pump();

    // Add Step
    await tester.ensureVisible(find.text('Add Step'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Step'));
    await tester.pumpAndSettle();

    expect(find.text('Add Habit to Stack'), findsOneWidget);
    await tester.tap(find.text('Water'));
    await tester.pumpAndSettle();

    // Add second Step
    await tester.ensureVisible(find.text('Add Step'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Step'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Journaling'));
    await tester.pumpAndSettle();

    // Verify 2 steps in chain
    expect(find.text('Water'), findsOneWidget);
    expect(find.text('Journaling'), findsOneWidget);

    // Tap Create Stack
    await tester.ensureVisible(find.text('Create Stack'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Stack'));
    await tester.pumpAndSettle();

    final saved = await mockRoutineRepo.getActiveRoutinesOnce();
    expect(saved.length, 1);
    expect(saved.first.title, 'Evening Stack');
    expect(saved.first.habitIds, ['h1', 'h2']);
  });
}
