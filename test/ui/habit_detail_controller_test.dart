import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_category.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/ui/detail/controllers/habit_detail_controller.dart';
import '../helpers/test_factories.dart';
export '../helpers/test_factories.dart';

void main() {
  late FakeHabitRepository repository;
  late HabitDetailController controller;

  final now = DateTime.now();
  final sampleCategory = const HabitCategory(
    id: 'cat_reading',
    name: 'Reading',
    color: '#8B5CF6',
    icon: 'book-open',
  );

  final sampleHabit = Habit(
    id: 'habit_detail_1',
    title: 'Daily Reading',
    description: 'Read 30 mins every day',
    color: '#8B5CF6',
    icon: 'book-open',
    categoryId: 'cat_reading',
    frequencyType: HabitFrequencyType.daily,
    targetType: HabitTargetType.numeric,
    targetValue: 30.0,
    unit: 'pages',
    reminderTimes: const ['20:00', '22:00'],
    pinned: false,
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    repository = FakeHabitRepository(
      initialHabits: [sampleHabit],
      initialCategories: [sampleCategory],
    );
    controller = HabitDetailController(
      habitId: 'habit_detail_1',
      repository: repository,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  test('initial state loads habit and computed metrics', () async {
    await Future.delayed(const Duration(milliseconds: 50));
    final state = controller.state;

    expect(state.isLoading, isFalse);
    expect(state.habit?.id, 'habit_detail_1');
    expect(state.category?.name, 'Reading');
    expect(state.selectedDate.day, now.day);
    expect(state.currentMonth.month, now.month);
    expect(state.isDeleted, isFalse);
  });

  test('month navigation steps backwards and forwards', () async {
    final currentMonth = controller.state.currentMonth;

    controller.previousMonth();
    expect(
      controller.state.currentMonth.month,
      currentMonth.month == 1 ? 12 : currentMonth.month - 1,
    );

    controller.nextMonth();
    expect(controller.state.currentMonth.month, currentMonth.month);
  });

  test('set10DotProgress updates repository with calculated target value',
      () async {
    await Future.delayed(const Duration(milliseconds: 50));

    await controller.set10DotProgress(15.0);
    await Future.delayed(const Duration(milliseconds: 50));

    final logs = await repository.getLogsForHabitOnce('habit_detail_1');
    expect(logs, isNotEmpty);
    expect(logs.first.value, 15.0);
    expect(logs.first.completed, isFalse);

    // Set to full target
    await controller.set10DotProgress(30.0);
    await Future.delayed(const Duration(milliseconds: 50));

    final updatedLogs = await repository.getLogsForHabitOnce('habit_detail_1');
    expect(updatedLogs.first.value, 30.0);
    expect(updatedLogs.first.completed, isTrue);
  });

  test('setPinned and setArchived updates habit flags in repository', () async {
    await Future.delayed(const Duration(milliseconds: 50));

    await controller.setPinned(true);
    await Future.delayed(const Duration(milliseconds: 50));

    var habit = await repository.getHabitByIdOnce('habit_detail_1');
    expect(habit?.pinned, isTrue);

    await controller.setArchived(true);
    await Future.delayed(const Duration(milliseconds: 50));

    habit = await repository.getHabitByIdOnce('habit_detail_1');
    expect(habit?.archived, isTrue);
  });

  test('deleteHabit removes habit from repository and emits navigateBackEvent',
      () async {
    await Future.delayed(const Duration(milliseconds: 50));

    var emitted = false;
    final sub = controller.navigateBackEvent.listen((_) {
      emitted = true;
    });

    await controller.deleteHabit();
    await Future.delayed(const Duration(milliseconds: 50));

    expect(emitted, isTrue);
    final habit = await repository.getHabitByIdOnce('habit_detail_1');
    expect(habit, isNull);

    await sub.cancel();
  });

  test('toggleReminder adds or removes reminder time', () async {
    await Future.delayed(const Duration(milliseconds: 50));

    await controller.toggleReminder('09:00'); // add
    await Future.delayed(const Duration(milliseconds: 50));

    var habit = await repository.getHabitByIdOnce('habit_detail_1');
    expect(habit?.reminderTimes, contains('09:00'));

    await controller.toggleReminder('20:00'); // remove
    await Future.delayed(const Duration(milliseconds: 50));

    habit = await repository.getHabitByIdOnce('habit_detail_1');
    expect(habit?.reminderTimes.contains('20:00'), isFalse);
  });
}
