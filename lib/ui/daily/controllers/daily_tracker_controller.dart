import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../di/providers.dart';
import '../../../domain/engines/streak_calculator.dart';
import '../../../domain/models/habit.dart';
import '../../../domain/models/habit_category.dart';
import '../../../domain/models/habit_frequency_type.dart';
import '../../../domain/models/habit_log.dart';
import '../../../domain/models/habit_shield.dart';
import '../../../domain/models/habit_target_type.dart';
import '../../../domain/models/habit_with_progress.dart';
import '../../../domain/repositories/habit_repository.dart';
import '../../../services/widget_sync_service.dart';

enum HabitSortOption {
  pinnedFirst('Pinned First'),
  streakDesc('Longest Streak'),
  alphabetical('Alphabetical'),
  category('Category');

  final String displayName;
  const HabitSortOption(this.displayName);
}

class DailyTrackerUiState {
  final DateTime selectedDate;
  final bool isToday;
  final String searchQuery;
  final String? selectedCategoryId;
  final HabitSortOption sortOption;
  final bool showArchived;
  final List<HabitCategory> categories;
  final List<HabitWithProgress> habits;
  final Map<DateTime, int> weekLogs;
  final int totalScheduledForSelectedDate;
  final int totalCompletedForSelectedDate;
  final int totalShieldedForSelectedDate;
  final bool isLoading;

  const DailyTrackerUiState({
    required this.selectedDate,
    this.isToday = true,
    this.searchQuery = '',
    this.selectedCategoryId,
    this.sortOption = HabitSortOption.pinnedFirst,
    this.showArchived = false,
    this.categories = const [],
    this.habits = const [],
    this.weekLogs = const {},
    this.totalScheduledForSelectedDate = 0,
    this.totalCompletedForSelectedDate = 0,
    this.totalShieldedForSelectedDate = 0,
    this.isLoading = false,
  });

  DailyTrackerUiState copyWith({
    DateTime? selectedDate,
    bool? isToday,
    String? searchQuery,
    String? selectedCategoryId,
    bool clearSelectedCategory = false,
    HabitSortOption? sortOption,
    bool? showArchived,
    List<HabitCategory>? categories,
    List<HabitWithProgress>? habits,
    Map<DateTime, int>? weekLogs,
    int? totalScheduledForSelectedDate,
    int? totalCompletedForSelectedDate,
    int? totalShieldedForSelectedDate,
    bool? isLoading,
  }) {
    return DailyTrackerUiState(
      selectedDate: selectedDate ?? this.selectedDate,
      isToday: isToday ?? this.isToday,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: clearSelectedCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      sortOption: sortOption ?? this.sortOption,
      showArchived: showArchived ?? this.showArchived,
      categories: categories ?? this.categories,
      habits: habits ?? this.habits,
      weekLogs: weekLogs ?? this.weekLogs,
      totalScheduledForSelectedDate:
          totalScheduledForSelectedDate ?? this.totalScheduledForSelectedDate,
      totalCompletedForSelectedDate:
          totalCompletedForSelectedDate ?? this.totalCompletedForSelectedDate,
      totalShieldedForSelectedDate:
          totalShieldedForSelectedDate ?? this.totalShieldedForSelectedDate,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyTrackerUiState &&
          runtimeType == other.runtimeType &&
          selectedDate == other.selectedDate &&
          isToday == other.isToday &&
          searchQuery == other.searchQuery &&
          selectedCategoryId == other.selectedCategoryId &&
          sortOption == other.sortOption &&
          showArchived == other.showArchived &&
          listEquals(categories, other.categories) &&
          listEquals(habits, other.habits) &&
          mapEquals(weekLogs, other.weekLogs) &&
          totalScheduledForSelectedDate == other.totalScheduledForSelectedDate &&
          totalCompletedForSelectedDate == other.totalCompletedForSelectedDate &&
          totalShieldedForSelectedDate == other.totalShieldedForSelectedDate &&
          isLoading == other.isLoading;

  @override
  int get hashCode =>
      selectedDate.hashCode ^
      isToday.hashCode ^
      searchQuery.hashCode ^
      selectedCategoryId.hashCode ^
      sortOption.hashCode ^
      showArchived.hashCode ^
      Object.hashAll(categories) ^
      Object.hashAll(habits) ^
      totalScheduledForSelectedDate.hashCode ^
      totalCompletedForSelectedDate.hashCode ^
      totalShieldedForSelectedDate.hashCode ^
      isLoading.hashCode;
}

class DailyTrackerController extends StateNotifier<DailyTrackerUiState> {
  final HabitRepository _repository;
  final WidgetSyncService? _widgetSyncService;
  StreamSubscription<List<Habit>>? _habitsSubscription;
  StreamSubscription<List<HabitLog>>? _logsSubscription;
  StreamSubscription<List<HabitShield>>? _shieldsSubscription;
  StreamSubscription<List<HabitCategory>>? _categoriesSubscription;

  List<Habit> _allHabits = [];
  List<HabitLog> _allLogs = [];
  List<HabitShield> _allShields = [];
  List<HabitCategory> _allCategories = [];
  List<HabitWithProgress> _unfilteredHabitsWithProgress = [];
  bool _recomputeScheduled = false;

  DailyTrackerController(
    this._repository, [
    this._widgetSyncService,
  ]) : super(DailyTrackerUiState(
          selectedDate: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ),
          isLoading: true,
        )) {
    _initSubscriptions();
  }

  void _initSubscriptions() {
    _categoriesSubscription = _repository.getAllCategories().listen((categories) {
      _allCategories = categories;
      _scheduleRecompute();
    });

    _habitsSubscription = _repository.getAllHabits().listen((habits) {
      _allHabits = habits;
      _scheduleRecompute();
    });

    _logsSubscription = _repository.getAllLogs().listen((logs) {
      _allLogs = logs;
      _scheduleRecompute();
    });

    _shieldsSubscription = _repository.getAllShields().listen((shields) {
      _allShields = shields;
      _scheduleRecompute();
    });
  }

  void _scheduleRecompute() {
    if (_recomputeScheduled) return;
    _recomputeScheduled = true;
    scheduleMicrotask(() {
      _recomputeScheduled = false;
      if (mounted) {
        _recomputeState();
      }
    });
  }

  void _recomputeState() {
    final date = state.selectedDate;
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final dateStr = StreakCalculator.formatIsoDate(date);
    final categoryMap = {for (final c in _allCategories) c.id: c};

    final logsByHabit = <String, List<HabitLog>>{};
    final logsByHabitDate = <String, Map<String, List<HabitLog>>>{};
    for (final log in _allLogs) {
      logsByHabit.putIfAbsent(log.habitId, () => []).add(log);
      logsByHabitDate
          .putIfAbsent(log.habitId, () => {})
          .putIfAbsent(log.date, () => [])
          .add(log);
    }

    final shieldsByHabit = <String, List<HabitShield>>{};
    final shieldsByHabitDate = <String, Set<String>>{};
    for (final s in _allShields) {
      shieldsByHabit.putIfAbsent(s.habitId, () => []).add(s);
      shieldsByHabitDate.putIfAbsent(s.habitId, () => {}).add(s.date);
    }

    final scheduledHabits = _allHabits.where((habit) {
      return StreakCalculator.isHabitScheduledOnDate(habit, date);
    }).toList();

    _unfilteredHabitsWithProgress = scheduledHabits.map((habit) {
      final habitLogs = logsByHabit[habit.id] ?? const [];
      final habitShields = shieldsByHabit[habit.id] ?? const [];
      final logsOnDate = logsByHabitDate[habit.id]?[dateStr] ?? const [];
      final isCompleted =
          StreakCalculator.isHabitCompletedOnDate(habit, logsOnDate);
      final isShielded = shieldsByHabitDate[habit.id]?.contains(dateStr) == true;

      double currentValue;
      switch (habit.targetType) {
        case HabitTargetType.boolean:
          currentValue = isCompleted ? 1.0 : 0.0;
          break;
        case HabitTargetType.numeric:
          currentValue = logsOnDate.fold<double>(
            0.0,
            (sum, log) =>
                sum + (log.value ?? (log.completed ? (habit.targetValue ?? 1.0) : 0.0)),
          );
          break;
        case HabitTargetType.timer:
          currentValue = logsOnDate.fold<double>(
            0.0,
            (sum, log) {
              if (log.durationSeconds != null && log.durationSeconds! > 0) {
                return sum + (log.durationSeconds! / 60.0);
              } else {
                return sum +
                    (log.value ?? (log.completed ? (habit.targetValue ?? 25.0) : 0.0));
              }
            },
          );
          break;
      }

      final currentDurationSeconds = logsOnDate.fold<int>(
        0,
        (sum, log) =>
            sum +
            (log.durationSeconds ?? (((log.value ?? 0.0) * 60).round())),
      );

      final streak = StreakCalculator.calculateStreak(
        habit,
        habitLogs,
        date,
        habitShields,
      );

      return HabitWithProgress(
        habit: habit,
        category: habit.categoryId != null ? categoryMap[habit.categoryId] : null,
        logsForDate: logsOnDate,
        isCompletedOnDate: isCompleted,
        isShieldedOnDate: isShielded,
        currentValueOnDate: currentValue,
        currentDurationSecondsOnDate: currentDurationSeconds,
        streak: streak,
      );
    }).toList();

    final weekLogsMap = <DateTime, int>{};
    for (var offset = -3; offset <= 3; offset++) {
      final d = date.add(Duration(days: offset));
      final dClean = DateTime(d.year, d.month, d.day);
      final dStr = StreakCalculator.formatIsoDate(dClean);
      final completedCount = _allHabits.where((h) {
        if (h.archived) return false;
        if (!StreakCalculator.isHabitScheduledOnDate(h, dClean)) return false;
        final hLogs = logsByHabitDate[h.id]?[dStr] ?? const [];
        return StreakCalculator.isHabitCompletedOnDate(h, hLogs);
      }).length;
      weekLogsMap[dClean] = completedCount;
    }

    state = state.copyWith(
      selectedDate: date,
      isToday: isToday,
      categories: _allCategories,
      weekLogs: weekLogsMap,
      isLoading: false,
    );

    _applyFilterAndSort();
  }

  void _applyFilterAndSort() {
    final query = state.searchQuery.trim().toLowerCase();
    final filteredHabits = _unfilteredHabitsWithProgress.where((item) {
      final habit = item.habit;
      final matchArchived = state.showArchived ? true : !habit.archived;
      final matchCategory = state.selectedCategoryId == null ||
          habit.categoryId == state.selectedCategoryId;
      final matchSearch = query.isEmpty ||
          habit.title.toLowerCase().contains(query) ||
          (habit.description != null &&
              habit.description!.toLowerCase().contains(query));

      return matchArchived && matchCategory && matchSearch;
    }).toList();

    filteredHabits.sort((a, b) {
      // Pinned always comes first
      if (a.habit.pinned != b.habit.pinned) {
        return a.habit.pinned ? -1 : 1;
      }

      switch (state.sortOption) {
        case HabitSortOption.pinnedFirst:
          if (a.isCompletedOnDate != b.isCompletedOnDate) {
            return a.isCompletedOnDate ? 1 : -1;
          }
          return a.habit.title.toLowerCase().compareTo(b.habit.title.toLowerCase());

        case HabitSortOption.streakDesc:
          if (a.streak.currentStreak != b.streak.currentStreak) {
            return b.streak.currentStreak.compareTo(a.streak.currentStreak);
          }
          return a.habit.title.toLowerCase().compareTo(b.habit.title.toLowerCase());

        case HabitSortOption.alphabetical:
          return a.habit.title.toLowerCase().compareTo(b.habit.title.toLowerCase());

        case HabitSortOption.category:
          final catA = a.category?.name ?? 'ZZZ';
          final catB = b.category?.name ?? 'ZZZ';
          final catComp = catA.compareTo(catB);
          if (catComp != 0) return catComp;
          return a.habit.title.toLowerCase().compareTo(b.habit.title.toLowerCase());
      }
    });

    final totalScheduled = filteredHabits.length;
    final totalCompleted =
        filteredHabits.where((h) => h.isCompletedOnDate).length;
    final totalShielded =
        filteredHabits.where((h) => h.isShieldedOnDate).length;

    state = state.copyWith(
      habits: filteredHabits,
      totalScheduledForSelectedDate: totalScheduled,
      totalCompletedForSelectedDate: totalCompleted,
      totalShieldedForSelectedDate: totalShielded,
    );
  }

  void selectDate(DateTime date) {
    final cleanDate = DateTime(date.year, date.month, date.day);
    state = state.copyWith(selectedDate: cleanDate);
    _recomputeState();
  }

  void nextDay() {
    selectDate(state.selectedDate.add(const Duration(days: 1)));
  }

  void previousDay() {
    selectDate(state.selectedDate.subtract(const Duration(days: 1)));
  }

  void selectToday() {
    final now = DateTime.now();
    selectDate(DateTime(now.year, now.month, now.day));
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilterAndSort();
  }

  void selectCategory(String? categoryId) {
    if (state.selectedCategoryId == categoryId) {
      state = state.copyWith(clearSelectedCategory: true);
    } else {
      state = state.copyWith(selectedCategoryId: categoryId);
    }
    _applyFilterAndSort();
  }

  void setSortOption(HabitSortOption option) {
    state = state.copyWith(sortOption: option);
    _applyFilterAndSort();
  }

  void setShowArchived(bool show) {
    state = state.copyWith(showArchived: show);
    _applyFilterAndSort();
  }


  Future<void> toggleCheckIn(Habit habit) async {
    await _repository.toggleBooleanCheckIn(habit.id, state.selectedDate);
    _widgetSyncService?.syncAllWidgets(state.selectedDate);
  }

  Future<bool> toggleShield(Habit habit) async {
    final success = await _repository.toggleShield(habit.id, state.selectedDate);
    _widgetSyncService?.syncAllWidgets(state.selectedDate);
    return success;
  }

  Future<void> updateNumericValue(String habitId, double value) async {
    await _repository.updateNumericValue(habitId, state.selectedDate, value);
    _widgetSyncService?.syncAllWidgets(state.selectedDate);
  }

  Future<void> addNumericDelta(String habitId, double delta) async {
    await _repository.addNumericDelta(habitId, state.selectedDate, delta);
    _widgetSyncService?.syncAllWidgets(state.selectedDate);
  }

  Future<void> toggleSlot(String habitId, int slotIndex) async {
    await _repository.toggleSlotCheckIn(habitId, state.selectedDate, slotIndex);
    _widgetSyncService?.syncAllWidgets(state.selectedDate);
  }

  Future<void> togglePinned(Habit habit) async {
    await _repository.setPinned(habit.id, !habit.pinned);
    _widgetSyncService?.syncAllWidgets(state.selectedDate);
  }

  Future<void> quickAddHabit(String title, String? categoryId) async {
    if (title.trim().isEmpty) return;
    final now = DateTime.now();
    final habit = Habit(
      id: const Uuid().v4(),
      title: title.trim(),
      description: null,
      color: '#10B981',
      icon: 'check',
      categoryId: categoryId,
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.upsertHabit(habit);
    _widgetSyncService?.syncAllWidgets(state.selectedDate);
  }

  Future<void> loadDemoHabits() async {
    await _repository.seedDemoHabits();
    _widgetSyncService?.syncAllWidgets(state.selectedDate);
  }

  @override
  void dispose() {
    _habitsSubscription?.cancel();
    _logsSubscription?.cancel();
    _shieldsSubscription?.cancel();
    _categoriesSubscription?.cancel();
    super.dispose();
  }
}

final dailyTrackerControllerProvider =
    StateNotifierProvider<DailyTrackerController, DailyTrackerUiState>((ref) {
  final repository = ref.watch(habitRepositoryProvider);
  final widgetSync = ref.watch(widgetSyncServiceProvider);
  return DailyTrackerController(repository, widgetSync);
});
