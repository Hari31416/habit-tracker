import 'dart:async';
import 'package:habit_tracker/domain/engines/streak_calculator.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_category.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_log.dart';
import 'package:habit_tracker/domain/models/habit_shield.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/domain/models/habit_tier.dart';
import 'package:habit_tracker/domain/models/health/health_metric_type.dart';
import 'package:habit_tracker/domain/models/time_window.dart';
import 'package:habit_tracker/domain/repositories/habit_repository.dart';

Habit createTestHabit({
  String id = 'test-habit-1',
  String title = 'Test Habit',
  String? description,
  String color = '#10B981',
  String icon = 'check',
  String? categoryId,
  HabitFrequencyType frequencyType = HabitFrequencyType.daily,
  List<int> targetDaysOfWeek = const [],
  int targetCountPerWeek = 3,
  int intervalHours = 4,
  int timesPerDay = 1,
  TimeWindow? timeWindow,
  HabitTargetType targetType = HabitTargetType.boolean,
  double targetValue = 1.0,
  double? miniTargetValue,
  double? eliteTargetValue,
  String unit = 'times',
  bool pinned = false,
  List<String> reminderTimes = const [],
  String? motivationNotes,
  bool archived = false,
  bool promptReflection = false,
  HealthMetricType? healthMetric,
  bool healthSyncEnabled = false,
  bool isDeleted = false,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime.now();
  return Habit(
    id: id,
    title: title,
    description: description,
    color: color,
    icon: icon,
    categoryId: categoryId,
    frequencyType: frequencyType,
    targetDaysOfWeek: targetDaysOfWeek,
    targetCountPerWeek: targetCountPerWeek,
    intervalHours: intervalHours,
    timesPerDay: timesPerDay,
    timeWindow: timeWindow,
    targetType: targetType,
    targetValue: targetValue,
    miniTargetValue: miniTargetValue,
    eliteTargetValue: eliteTargetValue,
    unit: unit,
    pinned: pinned,
    reminderTimes: reminderTimes,
    motivationNotes: motivationNotes,
    archived: archived,
    promptReflection: promptReflection,
    healthMetric: healthMetric,
    healthSyncEnabled: healthSyncEnabled,
    isDeleted: isDeleted,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
  );
}

HabitLog createTestHabitLog({
  String id = 'test-log-1',
  String habitId = 'test-habit-1',
  String? date,
  DateTime? timestamp,
  int? intervalIndex,
  bool completed = true,
  double? value,
  int? durationSeconds,
  HabitTier? targetTier,
  String? note,
  int? energyLevel,
  String? mood,
  bool isDeleted = false,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime.now();
  return HabitLog(
    id: id,
    habitId: habitId,
    date: date ?? StreakCalculator.dateFormatter.format(now),
    timestamp: timestamp ?? now,
    intervalIndex: intervalIndex,
    completed: completed,
    value: value,
    durationSeconds: durationSeconds,
    targetTier: targetTier,
    note: note,
    energyLevel: energyLevel,
    mood: mood,
    isDeleted: isDeleted,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
  );
}

HabitCategory createTestHabitCategory({
  String id = 'test-category-1',
  String name = 'Test Category',
  String color = '#3B82F6',
  String icon = 'folder',
  bool isDeleted = false,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime.now();
  return HabitCategory(
    id: id,
    name: name,
    color: color,
    icon: icon,
    isDeleted: isDeleted,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
  );
}

HabitShield createTestHabitShield({
  String id = 'test-shield-1',
  String habitId = 'test-habit-1',
  String? date,
  bool autoApplied = false,
  bool isDeleted = false,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime.now();
  return HabitShield(
    id: id,
    habitId: habitId,
    date: date ?? StreakCalculator.dateFormatter.format(now),
    autoApplied: autoApplied,
    isDeleted: isDeleted,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
  );
}

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
  Stream<List<Habit>> getActiveHabits() {
    Future.microtask(() => _habitsController.add(List.unmodifiable(_habits)));
    return _habitsController.stream
        .map((list) => list.where((h) => !h.archived && !h.isDeleted).toList());
  }

  @override
  Future<List<Habit>> getAllActiveHabitsOnce() async =>
      _habits.where((h) => !h.archived && !h.isDeleted).toList();

  @override
  Future<List<Habit>> getAllHabitsOnce() async => List.unmodifiable(_habits);

  @override
  Stream<List<Habit>> getArchivedHabits() {
    Future.microtask(() => _habitsController.add(List.unmodifiable(_habits)));
    return _habitsController.stream
        .map((list) => list.where((h) => h.archived && !h.isDeleted).toList());
  }

  @override
  Stream<List<Habit>> getPinnedHabits() {
    Future.microtask(() => _habitsController.add(List.unmodifiable(_habits)));
    return _habitsController.stream
        .map((list) => list.where((h) => h.pinned && !h.isDeleted).toList());
  }

  @override
  Stream<Habit?> getHabitById(String id) {
    Future.microtask(() => _habitsController.add(List.unmodifiable(_habits)));
    return _habitsController.stream
        .map((list) => list.where((h) => h.id == id).firstOrNull);
  }

  @override
  Future<Habit?> getHabitByIdOnce(String id) async =>
      _habits.where((h) => h.id == id).firstOrNull;

  @override
  Stream<List<Habit>> getHabitsByCategory(String categoryId) {
    Future.microtask(() => _habitsController.add(List.unmodifiable(_habits)));
    return _habitsController.stream.map(
        (list) => list.where((h) => h.categoryId == categoryId).toList());
  }

  @override
  Stream<List<HabitLog>> getAllLogs() {
    Future.microtask(() => _logsController.add(List.unmodifiable(_logs)));
    return _logsController.stream;
  }

  @override
  Future<List<HabitLog>> getAllLogsOnce() async => List.unmodifiable(_logs);

  @override
  Stream<List<HabitLog>> getLogsForDate(DateTime date) {
    final dateStr = StreakCalculator.dateFormatter.format(date);
    Future.microtask(() => _logsController.add(List.unmodifiable(_logs)));
    return _logsController.stream
        .map((list) => list.where((l) => l.date == dateStr).toList());
  }

  @override
  Future<List<HabitLog>> getLogsForDateOnce(DateTime date) async {
    final dateStr = StreakCalculator.dateFormatter.format(date);
    return _logs.where((l) => l.date == dateStr).toList();
  }

  @override
  Stream<List<HabitLog>> getLogsForHabit(String habitId) {
    Future.microtask(() => _logsController.add(List.unmodifiable(_logs)));
    return _logsController.stream
        .map((list) => list.where((l) => l.habitId == habitId).toList());
  }

  @override
  Future<List<HabitLog>> getLogsForHabitOnce(String habitId) async =>
      _logs.where((l) => l.habitId == habitId).toList();

  @override
  Stream<List<HabitLog>> getLogsForHabitAndDate(
      String habitId, DateTime date) {
    final dateStr = StreakCalculator.dateFormatter.format(date);
    Future.microtask(() => _logsController.add(List.unmodifiable(_logs)));
    return _logsController.stream.map((list) =>
        list.where((l) => l.habitId == habitId && l.date == dateStr).toList());
  }

  @override
  Stream<List<HabitLog>> getLogsForDateRange(
      DateTime startDate, DateTime endDate) {
    final startStr = StreakCalculator.dateFormatter.format(startDate);
    final endStr = StreakCalculator.dateFormatter.format(endDate);
    Future.microtask(() => _logsController.add(List.unmodifiable(_logs)));
    return _logsController.stream.map((list) => list
        .where((l) =>
            l.date.compareTo(startStr) >= 0 && l.date.compareTo(endStr) <= 0)
        .toList());
  }

  @override
  Future<List<HabitLog>> getLogsForDateRangeOnce(
      DateTime startDate, DateTime endDate) async {
    final startStr = StreakCalculator.dateFormatter.format(startDate);
    final endStr = StreakCalculator.dateFormatter.format(endDate);
    return _logs
        .where((l) =>
            l.date.compareTo(startStr) >= 0 && l.date.compareTo(endStr) <= 0)
        .toList();
  }

  @override
  Stream<List<HabitShield>> getAllShields() {
    Future.microtask(() => _shieldsController.add(List.unmodifiable(_shields)));
    return _shieldsController.stream;
  }

  @override
  Future<List<HabitShield>> getAllShieldsOnce() async =>
      List.unmodifiable(_shields);

  @override
  Stream<List<HabitShield>> getShieldsForHabit(String habitId) {
    Future.microtask(() => _shieldsController.add(List.unmodifiable(_shields)));
    return _shieldsController.stream
        .map((list) => list.where((s) => s.habitId == habitId).toList());
  }

  @override
  Future<List<HabitShield>> getShieldsForHabitOnce(String habitId) async =>
      _shields.where((s) => s.habitId == habitId).toList();

  @override
  Stream<List<HabitShield>> getShieldsForDate(DateTime date) {
    final dateStr = StreakCalculator.dateFormatter.format(date);
    Future.microtask(() => _shieldsController.add(List.unmodifiable(_shields)));
    return _shieldsController.stream
        .map((list) => list.where((s) => s.date == dateStr).toList());
  }

  @override
  Future<List<HabitShield>> getShieldsForDateOnce(DateTime date) async {
    final dateStr = StreakCalculator.dateFormatter.format(date);
    return _shields.where((s) => s.date == dateStr).toList();
  }

  @override
  Stream<List<HabitShield>> getShieldsForDateRange(
      DateTime startDate, DateTime endDate) {
    final startStr = StreakCalculator.dateFormatter.format(startDate);
    final endStr = StreakCalculator.dateFormatter.format(endDate);
    Future.microtask(() => _shieldsController.add(List.unmodifiable(_shields)));
    return _shieldsController.stream.map((list) => list
        .where((s) =>
            s.date.compareTo(startStr) >= 0 && s.date.compareTo(endStr) <= 0)
        .toList());
  }

  @override
  Future<List<HabitShield>> getShieldsForDateRangeOnce(
      DateTime startDate, DateTime endDate) async {
    final startStr = StreakCalculator.dateFormatter.format(startDate);
    final endStr = StreakCalculator.dateFormatter.format(endDate);
    return _shields
        .where((s) =>
            s.date.compareTo(startStr) >= 0 && s.date.compareTo(endStr) <= 0)
        .toList();
  }

  @override
  Stream<List<HabitCategory>> getAllCategories() {
    Future.microtask(
        () => _categoriesController.add(List.unmodifiable(_categories)));
    return _categoriesController.stream;
  }

  @override
  Future<List<HabitCategory>> getAllCategoriesOnce() async => _categories;

  @override
  Stream<HabitCategory?> getCategoryById(String id) {
    return _categoriesController.stream
        .map((list) => list.where((c) => c.id == id).firstOrNull);
  }

  @override
  Future<void> upsertHabit(Habit habit) async {
    _habits.removeWhere((h) => h.id == habit.id);
    _habits.add(habit);
    _notify();
  }

  @override
  Future<void> deleteHabit(Habit habit) async {
    _habits.removeWhere((h) => h.id == habit.id);
    _logs.removeWhere((l) => l.habitId == habit.id);
    _shields.removeWhere((s) => s.habitId == habit.id);
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
  Future<void> seedDemoHabits() async {
    final now = DateTime.now();
    _habits.add(
      createTestHabit(
        id: 'seed_demo',
        title: 'Demo Habit',
        color: '#10B981',
        icon: 'check',
        createdAt: now,
        updatedAt: now,
      ),
    );
    _notify();
  }

  @override
  Future<void> logCheckIn({
    required String habitId,
    required DateTime date,
    required bool completed,
    double? value,
    int? durationSeconds,
    int? intervalIndex,
    HabitTier? targetTier,
    String? note,
    int? energyLevel,
    String? mood,
  }) async {
    final dateStr = StreakCalculator.dateFormatter.format(date);
    final now = DateTime.now();
    _logs.removeWhere((l) =>
        l.habitId == habitId &&
        l.date == dateStr &&
        l.intervalIndex == intervalIndex);
    _logs.add(
      HabitLog(
        id: 'log_${now.millisecondsSinceEpoch}_${intervalIndex ?? 0}',
        habitId: habitId,
        date: dateStr,
        timestamp: now,
        intervalIndex: intervalIndex,
        completed: completed,
        value: value,
        durationSeconds: durationSeconds,
        targetTier: targetTier,
        note: note,
        energyLevel: energyLevel,
        mood: mood,
        createdAt: now,
        updatedAt: now,
      ),
    );
    _notify();
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
    final index = _logs.indexWhere((l) => l.habitId == habitId && l.date == dateStr);
    if (index != -1) {
      final existing = _logs[index];
      _logs[index] = existing.copyWith(
        energyLevel: energyLevel,
        mood: mood,
        note: note,
        updatedAt: now,
      );
      _notify();
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
      _notify();
    }
  }

  @override
  Future<void> toggleBooleanCheckIn(String habitId, DateTime date) async {
    final dateStr = StreakCalculator.dateFormatter.format(date);
    final habit = _habits.where((h) => h.id == habitId).firstOrNull;
    final existingLogs =
        _logs.where((l) => l.habitId == habitId && l.date == dateStr).toList();
    final wasCompleted = habit != null
        ? StreakCalculator.isHabitCompletedOnDate(habit, existingLogs)
        : existingLogs.any((l) => l.completed);

    final now = DateTime.now();
    _logs.removeWhere((l) => l.habitId == habitId && l.date == dateStr);

    if (!wasCompleted) {
      _logs.add(HabitLog(
        id: 'log-${now.millisecondsSinceEpoch}',
        habitId: habitId,
        date: dateStr,
        timestamp: now,
        completed: true,
        value: habit?.targetValue ?? 1.0,
        durationSeconds: habit?.targetType == HabitTargetType.timer
            ? ((habit?.targetValue ?? 25.0).toInt() * 60)
            : null,
        createdAt: now,
        updatedAt: now,
      ));
    }
    _notify();
  }

  @override
  Future<void> logTierCheckIn(
      String habitId, DateTime date, HabitTier tier) async {
    final habit = await getHabitByIdOnce(habitId);
    double? val;
    int? duration;
    if (habit != null) {
      final double baseVal = habit.targetValue ?? 1.0;
      final double miniVal = habit.miniTargetValue ?? (baseVal > 1 ? baseVal / 2 : 1.0);
      final double eliteVal = habit.eliteTargetValue ?? (baseVal * 1.5);
      final double target = tier == HabitTier.elite
          ? eliteVal
          : (tier == HabitTier.mini ? miniVal : baseVal);
      if (habit.targetType == HabitTargetType.numeric) {
        val = target;
      } else if (habit.targetType == HabitTargetType.timer) {
        duration = (target * 60).round();
      }
    }
    await logCheckIn(
      habitId: habitId,
      date: date,
      completed: true,
      value: val,
      durationSeconds: duration,
      targetTier: tier,
    );
  }

  @override
  Future<void> updateNumericValue(
      String habitId, DateTime date, double value) async {
    final dateStr = StreakCalculator.dateFormatter.format(date);
    final habit = _habits.where((h) => h.id == habitId).firstOrNull;
    final target = habit?.targetValue ?? 1.0;
    final existingIdx =
        _logs.indexWhere((l) => l.habitId == habitId && l.date == dateStr);
    final now = DateTime.now();
    if (existingIdx != -1) {
      _logs[existingIdx] = _logs[existingIdx].copyWith(
        value: value,
        completed: value >= target,
        updatedAt: now,
      );
    } else {
      _logs.add(HabitLog(
        id: 'log-${now.millisecondsSinceEpoch}',
        habitId: habitId,
        date: dateStr,
        timestamp: now,
        completed: value >= target,
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
  Future<void> deleteLogsForHabitAndDate(
      String habitId, DateTime date) async {
    final dateStr = StreakCalculator.dateFormatter.format(date);
    _logs.removeWhere((l) => l.habitId == habitId && l.date == dateStr);
    _notify();
  }

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
    final exists =
        _shields.any((s) => s.habitId == habitId && s.date == dateStr);
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

  @override
  Future<void> upsertCategory(HabitCategory category) async {
    _categories.removeWhere((c) => c.id == category.id);
    _categories.add(category);
    _notify();
  }

  @override
  Future<void> deleteCategory(HabitCategory category) async {
    _categories.removeWhere((c) => c.id == category.id);
    _notify();
  }
}
