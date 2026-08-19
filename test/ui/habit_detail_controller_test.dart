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
import 'package:habit_tracker/ui/detail/controllers/habit_detail_controller.dart';

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
  Stream<Habit?> getHabitById(String id) {
    Future.microtask(() => _habitsController.add(List.unmodifiable(_habits)));
    return _habitsController.stream.map((list) => list.where((h) => h.id == id).firstOrNull);
  }

  @override
  Future<Habit?> getHabitByIdOnce(String id) async =>
      _habits.where((h) => h.id == id).firstOrNull;

  @override
  Stream<List<HabitLog>> getLogsForHabit(String habitId) {
    Future.microtask(() => _logsController.add(List.unmodifiable(_logs)));
    return _logsController.stream.map((list) => list.where((l) => l.habitId == habitId).toList());
  }

  @override
  Future<List<HabitLog>> getLogsForHabitOnce(String habitId) async =>
      _logs.where((l) => l.habitId == habitId).toList();


  @override
  Future<List<HabitCategory>> getAllCategoriesOnce() async => _categories;

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
  Future<void> updateNumericValue(
      String habitId, DateTime date, double value) async {
    final dateStr = StreakCalculator.dateFormatter.format(date);
    final existingIdx =
        _logs.indexWhere((l) => l.habitId == habitId && l.date == dateStr);
    final now = DateTime.now();
    if (existingIdx != -1) {
      _logs[existingIdx] = _logs[existingIdx].copyWith(
        value: value,
        completed: value >= 30.0,
        updatedAt: now,
      );
    } else {
      _logs.add(HabitLog(
        id: 'log-${now.millisecondsSinceEpoch}',
        habitId: habitId,
        date: dateStr,
        timestamp: now,
        completed: value >= 30.0,
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
  Future<void> toggleBooleanCheckIn(String habitId, DateTime date) async {
    final dateStr = StreakCalculator.dateFormatter.format(date);
    final existingIdx =
        _logs.indexWhere((l) => l.habitId == habitId && l.date == dateStr);
    final now = DateTime.now();
    if (existingIdx != -1) {
      _logs.removeAt(existingIdx);
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
  Future<void> toggleSlotCheckIn(
      String habitId, DateTime date, int slotIndex) async {}

  @override
  Future<void> deleteHabit(Habit habit) async {
    _habits.removeWhere((h) => h.id == habit.id);
    _logs.removeWhere((l) => l.habitId == habit.id);
    _notify();
  }

  @override
  Stream<List<Habit>> getAllHabits() {
    Future.microtask(() => _habitsController.add(List.unmodifiable(_habits)));
    return _habitsController.stream;
  }

  @override
  Stream<List<Habit>> getActiveHabits() {
    Future.microtask(() => _habitsController.add(List.unmodifiable(_habits)));
    return _habitsController.stream
        .map((list) => list.where((h) => !h.archived).toList());
  }

  @override
  Stream<List<Habit>> getArchivedHabits() {
    Future.microtask(() => _habitsController.add(List.unmodifiable(_habits)));
    return _habitsController.stream
        .map((list) => list.where((h) => h.archived).toList());
  }

  @override
  Stream<List<Habit>> getPinnedHabits() {
    Future.microtask(() => _habitsController.add(List.unmodifiable(_habits)));
    return _habitsController.stream
        .map((list) => list.where((h) => h.pinned).toList());
  }

  @override
  Stream<List<Habit>> getHabitsByCategory(String categoryId) {
    Future.microtask(() => _habitsController.add(List.unmodifiable(_habits)));
    return _habitsController.stream
        .map((list) => list.where((h) => h.categoryId == categoryId).toList());
  }

  @override
  Stream<List<HabitLog>> getAllLogs() {
    Future.microtask(() => _logsController.add(List.unmodifiable(_logs)));
    return _logsController.stream;
  }

  @override
  Future<List<HabitLog>> getAllLogsOnce() async => _logs;

  @override
  Stream<List<HabitLog>> getLogsForDate(DateTime date) => _logsController.stream;

  @override
  Future<List<HabitLog>> getLogsForDateOnce(DateTime date) async => _logs;

  @override
  Stream<List<HabitLog>> getLogsForHabitAndDate(
          String habitId, DateTime date) =>
      _logsController.stream;

  @override
  Stream<List<HabitCategory>> getAllCategories() {
    Future.microtask(
        () => _categoriesController.add(List.unmodifiable(_categories)));
    return _categoriesController.stream;
  }

  @override
  Stream<List<HabitLog>> getLogsForDateRange(
          DateTime startDate, DateTime endDate) =>
      _logsController.stream;

  @override
  Future<List<HabitLog>> getLogsForDateRangeOnce(
          DateTime startDate, DateTime endDate) async =>
      _logs;

  @override
  Future<void> logCheckIn({
    required String habitId,
    required DateTime date,
    required bool completed,
    double? value,
    int? durationSeconds,
    int? intervalIndex,
    String? note,
    int? energyLevel,
    String? mood,
  }) async {
    final dateStr = StreakCalculator.dateFormatter.format(date);
    final now = DateTime.now();
    _logs.removeWhere((l) => l.habitId == habitId && l.date == dateStr);
    _logs.add(HabitLog(
      id: 'log-${now.millisecondsSinceEpoch}',
      habitId: habitId,
      date: dateStr,
      timestamp: now,
      completed: completed,
      value: value,
      durationSeconds: durationSeconds,
      intervalIndex: intervalIndex,
      note: note,
      energyLevel: energyLevel,
      mood: mood,
      createdAt: now,
      updatedAt: now,
    ));
    _logsController.add(List.unmodifiable(_logs));
  }

  @override
  Future<void> updateReflection({
    required String habitId,
    required DateTime date,
    int? energyLevel,
    String? mood,
    String? note,
  }) async {
    final dateStr = StreakCalculator.dateFormatter.format(date);
    final now = DateTime.now();
    final existing = _logs.where((l) => l.habitId == habitId && l.date == dateStr).firstOrNull;
    if (existing != null) {
      _logs.removeWhere((l) => l.habitId == habitId && l.date == dateStr);
      _logs.add(existing.copyWith(
        energyLevel: energyLevel,
        mood: mood,
        note: note,
        updatedAt: now,
      ));
    } else {
      _logs.add(HabitLog(
        id: 'log-${now.millisecondsSinceEpoch}',
        habitId: habitId,
        date: dateStr,
        timestamp: now,
        completed: true,
        energyLevel: energyLevel,
        mood: mood,
        note: note,
        createdAt: now,
        updatedAt: now,
      ));
    }
    _logsController.add(List.unmodifiable(_logs));
  }
  @override
  Future<void> deleteLogsForHabitAndDate(
      String habitId, DateTime date) async {}
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
  Future<bool> applyShield({
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
    return true;
  }

  @override
  Future<void> removeShield(String habitId, DateTime date) async {
    final dateStr = StreakCalculator.dateFormatter.format(date);
    _shields.removeWhere((s) => s.habitId == habitId && s.date == dateStr);
    _notify();
  }

  @override
  Future<bool> toggleShield(String habitId, DateTime date) async {
    final dateStr = StreakCalculator.dateFormatter.format(date);
    final exists = _shields.any((s) => s.habitId == habitId && s.date == dateStr);
    if (exists) {
      await removeShield(habitId, date);
      return true;
    } else {
      return await applyShield(habitId: habitId, date: date);
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
