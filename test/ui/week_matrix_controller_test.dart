import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/engines/streak_calculator.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/ui/matrix/controllers/week_matrix_controller.dart';

import 'habit_detail_controller_test.dart' show FakeHabitRepository;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final isoMonday = StreakCalculator.isoWeekStart(today);

  final habit1 = Habit(
    id: 'matrix_habit_1',
    title: 'Morning Workout',
    color: '#10B981',
    frequencyType: HabitFrequencyType.daily,
    targetType: HabitTargetType.boolean,
    createdAt: now,
    updatedAt: now,
  );

  final habit2 = Habit(
    id: 'matrix_habit_2',
    title: 'Weekly Review',
    color: '#6366F1',
    frequencyType: HabitFrequencyType.weekly,
    targetCountPerWeek: 2,
    targetType: HabitTargetType.boolean,
    createdAt: now,
    updatedAt: now,
  );

  late FakeHabitRepository fakeRepository;
  late WeekMatrixController controller;

  setUp(() {
    fakeRepository = FakeHabitRepository(
      initialHabits: [habit1, habit2],
    );
    controller = WeekMatrixController(fakeRepository);
  });

  tearDown(() {
    controller.dispose();
  });

  test('initial state loads ISO Monday to Sunday date range and habit rows',
      () async {
    await Future.delayed(const Duration(milliseconds: 50));
    final state = controller.state;

    expect(state.isLoading, isFalse);
    expect(state.weekStart.year, isoMonday.year);
    expect(state.weekStart.month, isoMonday.month);
    expect(state.weekStart.day, isoMonday.day);
    expect(state.isCurrentWeek, isTrue);
    expect(state.rows.length, 2);
    expect(state.rows.first.cells.length, 7);
  });

  test('week navigation steps backward and forward by weeks', () async {
    await Future.delayed(const Duration(milliseconds: 50));

    controller.previousWeek();
    expect(
      controller.currentWeekStart,
      isoMonday.subtract(const Duration(days: 7)),
    );

    controller.nextWeek();
    expect(controller.currentWeekStart, isoMonday);

    controller.previousWeek();
    controller.currentWeek();
    expect(controller.currentWeekStart, isoMonday);
  });

  test('toggleCell creates and removes completion log in repository', () async {
    await Future.delayed(const Duration(milliseconds: 50));

    await controller.toggleCell('matrix_habit_1', isoMonday);
    await Future.delayed(const Duration(milliseconds: 50));

    var logs = await fakeRepository.getLogsForHabit('matrix_habit_1').first;
    expect(logs.isNotEmpty, isTrue);
    expect(logs.first.completed, isTrue);

    // Toggle again to un-complete
    await controller.toggleCell('matrix_habit_1', isoMonday);
    await Future.delayed(const Duration(milliseconds: 50));

    logs = await fakeRepository.getLogsForHabit('matrix_habit_1').first;
    expect(logs.isEmpty, isTrue);
  });
}
