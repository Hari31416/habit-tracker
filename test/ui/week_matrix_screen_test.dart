import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/di/providers.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/ui/matrix/controllers/week_matrix_controller.dart';
import 'package:habit_tracker/ui/matrix/habit_week_matrix_screen.dart';
import 'package:habit_tracker/ui/matrix/widgets/week_matrix_grid.dart';

import 'habit_detail_controller_test.dart' show FakeHabitRepository;

void main() {
  final now = DateTime.now();

  final habit1 = Habit(
    id: 'h1',
    title: 'Morning Yoga',
    color: '#10B981',
    frequencyType: HabitFrequencyType.daily,
    targetType: HabitTargetType.boolean,
    createdAt: now,
    updatedAt: now,
  );

  testWidgets('WeekMatrixGrid renders header and habit row with 7 cells',
      (tester) async {
    final cells = List.generate(
      7,
      (i) => MatrixCell(
        date: DateTime(2026, 8, 17 + i),
        status: i == 0
            ? MatrixCellStatus.completed
            : MatrixCellStatus.scheduledIncomplete,
        isToday: i == 1,
      ),
    );

    final row = MatrixRow(
      habit: habit1,
      cells: cells,
      completedCountThisWeek: 1,
      targetCountThisWeek: 7,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeekMatrixGrid(
            rows: [row],
            onToggleCell: (id, d) {},
            onHabitClick: (id) {},
          ),
        ),
      ),
    );

    expect(find.text('Habits'), findsOneWidget);
    expect(find.text('Morning Yoga'), findsOneWidget);
    expect(find.text('1/7 • Daily'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('HabitWeekMatrixScreen renders stepper, adherence, grid, and chart',
      (tester) async {
    final fakeRepo = FakeHabitRepository(
      initialHabits: [habit1],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: HabitWeekMatrixScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Week Matrix'), findsOneWidget);
    expect(find.text('Adherence'), findsOneWidget);
    expect(find.text('Check-ins'), findsOneWidget);
    expect(find.text('Active Habits'), findsOneWidget);
    expect(find.text('Daily Completions'), findsOneWidget);
    expect(find.text('Morning Yoga'), findsOneWidget);
  });
}
