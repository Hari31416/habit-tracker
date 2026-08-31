import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_category.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/ui/daily/controllers/daily_tracker_controller.dart';
import '../helpers/test_factories.dart';
export '../helpers/test_factories.dart';

void main() {
  late FakeHabitRepository repository;
  late DailyTrackerController controller;

  final catHealth = const HabitCategory(
    id: 'cat-1',
    name: 'Health',
    color: '#10B981',
    icon: 'heart',
  );

  final habit1 = Habit(
    id: 'h-1',
    title: 'Drink Water',
    description: '8 glasses',
    color: '#10B981',
    icon: 'droplet',
    categoryId: 'cat-1',
    frequencyType: HabitFrequencyType.daily,
    targetType: HabitTargetType.boolean,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final habit2 = Habit(
    id: 'h-2',
    title: 'Meditation',
    description: 'Mindfulness session',
    color: '#6366F1',
    icon: 'brain',
    frequencyType: HabitFrequencyType.daily,
    targetType: HabitTargetType.boolean,
    pinned: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    repository = FakeHabitRepository(
      initialHabits: [habit1, habit2],
      initialCategories: [catHealth],
    );
    controller = DailyTrackerController(repository);
  });

  tearDown(() {
    controller.dispose();
  });

  test('Initial state loads habits and categories with pinned habit first',
      () async {
    await Future.delayed(const Duration(milliseconds: 50));

    final state = controller.state;
    expect(state.isLoading, isFalse);
    expect(state.habits.length, 2);
    // Pinned habit (Meditation) should come first
    expect(state.habits.first.habit.title, 'Meditation');
    expect(state.categories.length, 1);
  });

  test('Date navigation updates selectedDate correctly', () async {
    final initialDate = controller.state.selectedDate;

    controller.nextDay();
    expect(
        controller.state.selectedDate, initialDate.add(const Duration(days: 1)));
    expect(controller.state.isToday, isFalse);

    controller.previousDay();
    expect(controller.state.selectedDate, initialDate);
    expect(controller.state.isToday, isTrue);

    controller.selectDate(DateTime(2025, 1, 1));
    expect(controller.state.selectedDate, DateTime(2025, 1, 1));

    controller.selectToday();
    expect(controller.state.isToday, isTrue);
  });

  test('Search filter filters habits by title and description', () async {
    await Future.delayed(const Duration(milliseconds: 50));

    controller.setSearchQuery('Water');
    expect(controller.state.habits.length, 1);
    expect(controller.state.habits.first.habit.title, 'Drink Water');

    controller.setSearchQuery('Mindfulness');
    expect(controller.state.habits.length, 1);
    expect(controller.state.habits.first.habit.title, 'Meditation');

    controller.setSearchQuery('NonExistent');
    expect(controller.state.habits.isEmpty, isTrue);

    controller.setSearchQuery('');
    expect(controller.state.habits.length, 2);
  });

  test('Category selection filters and toggles correctly', () async {
    await Future.delayed(const Duration(milliseconds: 50));

    // Initially total scheduled is 2, and cat-1 count is 1
    expect(controller.state.totalScheduledForSelectedDate, 2);
    expect(controller.state.categoryHabitCounts['cat-1'], 1);

    controller.selectCategory('cat-1');
    expect(controller.state.selectedCategoryId, 'cat-1');
    expect(controller.state.habits.length, 1);
    expect(controller.state.habits.first.habit.title, 'Drink Water');
    // Total scheduled for the day remains 2 even when filtered
    expect(controller.state.totalScheduledForSelectedDate, 2);
    expect(controller.state.categoryHabitCounts['cat-1'], 1);

    // Selecting null (All chip) resets category selection
    controller.selectCategory(null);
    expect(controller.state.selectedCategoryId, isNull);
    expect(controller.state.habits.length, 2);
    expect(controller.state.totalScheduledForSelectedDate, 2);

    // Selecting category again
    controller.selectCategory('cat-1');
    expect(controller.state.selectedCategoryId, 'cat-1');

    // Selecting same category deselects it
    controller.selectCategory('cat-1');
    expect(controller.state.selectedCategoryId, isNull);
    expect(controller.state.habits.length, 2);
  });

  test('Toggle check in updates progress and completions', () async {
    await Future.delayed(const Duration(milliseconds: 50));

    expect(controller.state.totalCompletedForSelectedDate, 0);

    await controller.toggleCheckIn(habit1);
    await Future.delayed(const Duration(milliseconds: 50));

    expect(controller.state.totalCompletedForSelectedDate, 1);
    final updatedHabit1 =
        controller.state.habits.firstWhere((h) => h.habit.id == 'h-1');
    expect(updatedHabit1.isCompletedOnDate, isTrue);
  });

  test('Quick add habit creates and inserts a new daily boolean habit',
      () async {
    await Future.delayed(const Duration(milliseconds: 50));

    await controller.quickAddHabit('Read Books', null);
    await Future.delayed(const Duration(milliseconds: 50));

    expect(controller.state.habits.length, 3);
    expect(
      controller.state.habits.any((h) => h.habit.title == 'Read Books'),
      isTrue,
    );
  });
}
