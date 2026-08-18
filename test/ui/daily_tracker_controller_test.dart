import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/engines/streak_calculator.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_category.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_log.dart';
import 'package:habit_tracker/domain/models/habit_shield.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/domain/repositories/habit_repository.dart';
import 'package:habit_tracker/ui/daily/controllers/daily_tracker_controller.dart';

class FakeHabitRepository implements HabitRepository {
  final List<Habit> _habits = [];
  final List<HabitLog> _logs = [];
  final List<HabitShield> _shields = [];
  final List<HabitCategory> _categories = [];

  final _habitsController = StreamController<List<Habit>>.broadcast();
  final _logsController = StreamController<List<HabitLog>>.broadcast();
  final _shieldsController = StreamController<List<HabitShield>>.broadcast();
  final _categoriesController =
      StreamController<List<HabitCategory>>.broadcast();

  FakeHabitRepository({
    List<Habit>? initialHabits,
    List<HabitLog>? initialLogs,
    List<HabitShield>? initialShields,
    List<HabitCategory>? initialCategories,
  }) {
    if (initialHabits != null) _habits.addAll(initialHabits);
    if (initialLogs != null) _logs.addAll(initialLogs);
    if (initialShields != null) _shields.addAll(initialShields);
    if (initialCategories != null) _categories.addAll(initialCategories);
  }

  void _notify() {
    _habitsController.add(List.unmodifiable(_habits));
    _logsController.add(List.unmodifiable(_logs));
    _shieldsController.add(List.unmodifiable(_shields));
    _categoriesController.add(List.unmodifiable(_categories));
  }

  @override
  Stream<List<Habit>> getAllHabits() {
    Future.microtask(() => _habitsController.add(List.unmodifiable(_habits)));
    return _habitsController.stream;
  }

  @override
  Stream<List<HabitLog>> getAllLogs() {
    Future.microtask(() => _logsController.add(List.unmodifiable(_logs)));
    return _logsController.stream;
  }

  @override
  Stream<List<HabitCategory>> getAllCategories() {
    Future.microtask(
        () => _categoriesController.add(List.unmodifiable(_categories)));
    return _categoriesController.stream;
  }

  @override
  Future<void> upsertHabit(Habit habit) async {
    _habits.removeWhere((h) => h.id == habit.id);
    _habits.add(habit);
    _notify();
  }

  @override
  Future<void> setPinned(String id, bool pinned) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      _habits[index] = _habits[index].copyWith(pinned: pinned);
      _notify();
    }
  }

  @override
  Future<void> setArchived(String id, bool archived) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      _habits[index] = _habits[index].copyWith(archived: archived);
      _notify();
    }
  }

  @override
  Future<void> toggleBooleanCheckIn(String habitId, DateTime date) async {
    final dateStr = StreakCalculator.dateFormatter.format(date);
    final existingIdx =
        _logs.indexWhere((l) => l.habitId == habitId && l.date == dateStr);
    final now = DateTime.now();
    if (existingIdx != -1) {
      final existing = _logs[existingIdx];
      if (existing.completed) {
        _logs.removeAt(existingIdx);
      } else {
        _logs[existingIdx] = existing.copyWith(
          completed: true,
          updatedAt: now,
        );
      }
    } else {
      _logs.add(HabitLog(
        id: 'log-${now.millisecondsSinceEpoch}',
        habitId: habitId,
        date: dateStr,
        timestamp: now,
        completed: true,
        createdAt: now,
        updatedAt: now,
      ));
    }
    _notify();
  }

  @override
  Future<void> updateNumericValue(
      String habitId, DateTime date, double value) async {
    final dateStr = StreakCalculator.dateFormatter.format(date);
    final existingIdx =
        _logs.indexWhere((l) => l.habitId == habitId && l.date == dateStr);
    final now = DateTime.now();
    if (existingIdx != -1) {
      _logs[existingIdx] = _logs[existingIdx].copyWith(
        value: value,
        completed: value >= 1.0,
        updatedAt: now,
      );
    } else {
      _logs.add(HabitLog(
        id: 'log-${now.millisecondsSinceEpoch}',
        habitId: habitId,
        date: dateStr,
        timestamp: now,
        completed: value >= 1.0,
        value: value,
        createdAt: now,
        updatedAt: now,
      ));
    }
    _notify();
  }

  @override
  Future<void> addNumericDelta(
      String habitId, DateTime date, double delta) async {
    final dateStr = StreakCalculator.dateFormatter.format(date);
    final existing =
        _logs.where((l) => l.habitId == habitId && l.date == dateStr).toList();
    final cur = existing.fold<double>(0.0, (s, l) => s + (l.value ?? 0.0));
    await updateNumericValue(habitId, date, cur + delta);
  }

  @override
  Future<void> toggleSlotCheckIn(
      String habitId, DateTime date, int slotIndex) async {
    final dateStr = StreakCalculator.dateFormatter.format(date);
    final existingIdx = _logs.indexWhere((l) =>
        l.habitId == habitId &&
        l.date == dateStr &&
        l.intervalIndex == slotIndex);
    final now = DateTime.now();
    if (existingIdx != -1) {
      _logs.removeAt(existingIdx);
    } else {
      _logs.add(HabitLog(
        id: 'log-slot-${now.millisecondsSinceEpoch}',
        habitId: habitId,
        date: dateStr,
        timestamp: now,
        completed: true,
        intervalIndex: slotIndex,
        createdAt: now,
        updatedAt: now,
      ));
    }
    _notify();
  }

  @override
  Future<void> deleteHabit(Habit habit) async {
    _habits.removeWhere((h) => h.id == habit.id);
    _logs.removeWhere((l) => l.habitId == habit.id);
    _notify();
  }

  @override
  Stream<List<Habit>> getActiveHabits() => getAllHabits();
  @override
  Stream<List<Habit>> getArchivedHabits() => getAllHabits();
  @override
  Stream<List<Habit>> getPinnedHabits() => getAllHabits();
  @override
  Stream<Habit?> getHabitById(String id) =>
      Stream.value(_habits.where((h) => h.id == id).firstOrNull);
  @override
  Future<Habit?> getHabitByIdOnce(String id) async =>
      _habits.where((h) => h.id == id).firstOrNull;
  Future<List<Habit>> getAllActiveHabitsOnce() async =>
      _habits.where((h) => !h.archived).toList();
  @override
  Stream<List<Habit>> getHabitsByCategory(String categoryId) => getAllHabits();
  @override
  Stream<List<HabitLog>> getLogsForHabit(String habitId) => getAllLogs();
  @override
  Future<List<HabitLog>> getLogsForHabitOnce(String habitId) async => _logs;
  @override
  Stream<List<HabitLog>> getLogsForDate(DateTime date) => getAllLogs();
  @override
  Future<List<HabitLog>> getLogsForDateOnce(DateTime date) async => _logs;
  @override
  Stream<List<HabitLog>> getLogsForHabitAndDate(
          String habitId, DateTime date) =>
      getAllLogs();
  @override
  Stream<List<HabitLog>> getLogsForDateRange(
          DateTime startDate, DateTime endDate) =>
      getAllLogs();
  @override
  Future<List<HabitLog>> getLogsForDateRangeOnce(
          DateTime startDate, DateTime endDate) async =>
      _logs;
  @override
  Future<List<HabitLog>> getAllLogsOnce() async => _logs;
  @override
  Future<void> logCheckIn({
    required String habitId,
    required DateTime date,
    required bool completed,
    double? value,
    int? durationSeconds,
    int? intervalIndex,
    String? note,
  }) async {}
  @override
  Future<void> deleteLogsForHabitAndDate(
      String habitId, DateTime date) async {}
  @override
  Future<List<HabitCategory>> getAllCategoriesOnce() async => _categories;
  @override
  Stream<HabitCategory?> getCategoryById(String id) => Stream.value(null);
  @override
  Future<void> upsertCategory(HabitCategory category) async {}
  @override
  Future<void> deleteCategory(HabitCategory category) async {}

  @override
  Stream<List<HabitShield>> getAllShields() {
    Future.microtask(() => _shieldsController.add(List.unmodifiable(_shields)));
    return _shieldsController.stream;
  }

  @override
  Future<List<HabitShield>> getAllShieldsOnce() async => _shields;

  @override
  Stream<List<HabitShield>> getShieldsForHabit(String habitId) =>
      getAllShields().map((s) => s.where((item) => item.habitId == habitId).toList());

  @override
  Future<List<HabitShield>> getShieldsForHabitOnce(String habitId) async =>
      _shields.where((item) => item.habitId == habitId).toList();

  @override
  Stream<List<HabitShield>> getShieldsForDate(DateTime date) {
    final dateStr = StreakCalculator.dateFormatter.format(date);
    return getAllShields().map((s) => s.where((item) => item.date == dateStr).toList());
  }

  @override
  Future<List<HabitShield>> getShieldsForDateOnce(DateTime date) async {
    final dateStr = StreakCalculator.dateFormatter.format(date);
    return _shields.where((item) => item.date == dateStr).toList();
  }

  @override
  Stream<List<HabitShield>> getShieldsForDateRange(DateTime startDate, DateTime endDate) =>
      getAllShields();

  @override
  Future<List<HabitShield>> getShieldsForDateRangeOnce(DateTime startDate, DateTime endDate) async =>
      _shields;

  @override
  Future<void> applyShield({
    required String habitId,
    required DateTime date,
    bool autoApplied = false,
  }) async {
    final dateStr = StreakCalculator.dateFormatter.format(date);
    _shields.removeWhere((s) => s.habitId == habitId && s.date == dateStr);
    _shields.add(HabitShield(
      id: 'shield-${DateTime.now().millisecondsSinceEpoch}',
      habitId: habitId,
      date: dateStr,
      autoApplied: autoApplied,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    _notify();
  }

  @override
  Future<void> removeShield(String habitId, DateTime date) async {
    final dateStr = StreakCalculator.dateFormatter.format(date);
    _shields.removeWhere((s) => s.habitId == habitId && s.date == dateStr);
    _notify();
  }

  @override
  Future<void> toggleShield(String habitId, DateTime date) async {
    final dateStr = StreakCalculator.dateFormatter.format(date);
    final exists = _shields.any((s) => s.habitId == habitId && s.date == dateStr);
    if (exists) {
      await removeShield(habitId, date);
    } else {
      await applyShield(habitId: habitId, date: date);
    }
  }

  @override
  Future<bool> isDateShielded(String habitId, DateTime date) async {
    final dateStr = StreakCalculator.dateFormatter.format(date);
    return _shields.any((s) => s.habitId == habitId && s.date == dateStr);
  }

  @override
  Future<int> autoProtectMissedDays(DateTime date) async => 0;
}

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

    controller.selectCategory('cat-1');
    expect(controller.state.selectedCategoryId, 'cat-1');
    expect(controller.state.habits.length, 1);
    expect(controller.state.habits.first.habit.title, 'Drink Water');

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
