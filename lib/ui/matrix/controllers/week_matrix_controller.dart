import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../di/providers.dart';
import '../../../domain/engines/streak_calculator.dart';
import '../../../domain/models/habit.dart';
import '../../../domain/models/habit_category.dart';
import '../../../domain/models/habit_frequency_type.dart';
import '../../../domain/models/habit_log.dart';
import '../../../domain/models/habit_shield.dart';
import '../../../domain/repositories/habit_repository.dart';

enum MatrixCellStatus {
  completed,
  shielded,
  scheduledIncomplete,
  notScheduled,
}

class MatrixCell {
  final DateTime date;
  final MatrixCellStatus status;
  final bool isToday;

  const MatrixCell({
    required this.date,
    required this.status,
    required this.isToday,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatrixCell &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          status == other.status &&
          isToday == other.isToday;

  @override
  int get hashCode => date.hashCode ^ status.hashCode ^ isToday.hashCode;
}

class MatrixRow {
  final Habit habit;
  final HabitCategory? category;
  final List<MatrixCell> cells;
  final int completedCountThisWeek;
  final int shieldedCountThisWeek;
  final int targetCountThisWeek;

  const MatrixRow({
    required this.habit,
    this.category,
    required this.cells,
    required this.completedCountThisWeek,
    this.shieldedCountThisWeek = 0,
    required this.targetCountThisWeek,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatrixRow &&
          runtimeType == other.runtimeType &&
          habit == other.habit &&
          category == other.category &&
          completedCountThisWeek == other.completedCountThisWeek &&
          shieldedCountThisWeek == other.shieldedCountThisWeek &&
          targetCountThisWeek == other.targetCountThisWeek;

  @override
  int get hashCode =>
      habit.hashCode ^
      category.hashCode ^
      completedCountThisWeek.hashCode ^
      shieldedCountThisWeek.hashCode ^
      targetCountThisWeek.hashCode;
}

class DailyCompletionStat {
  final DateTime date;
  final String dayLabel;
  final int completedCount;
  final int shieldedCount;
  final int scheduledCount;

  const DailyCompletionStat({
    required this.date,
    required this.dayLabel,
    required this.completedCount,
    this.shieldedCount = 0,
    required this.scheduledCount,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyCompletionStat &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          dayLabel == other.dayLabel &&
          completedCount == other.completedCount &&
          shieldedCount == other.shieldedCount &&
          scheduledCount == other.scheduledCount;

  @override
  int get hashCode =>
      date.hashCode ^
      dayLabel.hashCode ^
      completedCount.hashCode ^
      shieldedCount.hashCode ^
      scheduledCount.hashCode;
}

class WeekMatrixUiState {
  final DateTime weekStart;
  final DateTime weekEnd;
  final bool isCurrentWeek;
  final List<MatrixRow> rows;
  final List<DailyCompletionStat> dailyStats;
  final int totalCompleted;
  final int totalShielded;
  final int totalScheduled;
  final int adherencePercentage;
  final bool isLoading;

  WeekMatrixUiState({
    DateTime? weekStart,
    DateTime? weekEnd,
    this.isCurrentWeek = true,
    this.rows = const [],
    this.dailyStats = const [],
    this.totalCompleted = 0,
    this.totalShielded = 0,
    this.totalScheduled = 0,
    this.adherencePercentage = 0,
    this.isLoading = false,
  })  : weekStart = weekStart ?? StreakCalculator.isoWeekStart(DateTime.now()),
        weekEnd = weekEnd ??
            StreakCalculator.isoWeekStart(DateTime.now()).add(
              const Duration(days: 6),
            );

  WeekMatrixUiState copyWith({
    DateTime? weekStart,
    DateTime? weekEnd,
    bool? isCurrentWeek,
    List<MatrixRow>? rows,
    List<DailyCompletionStat>? dailyStats,
    int? totalCompleted,
    int? totalShielded,
    int? totalScheduled,
    int? adherencePercentage,
    bool? isLoading,
  }) {
    return WeekMatrixUiState(
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
      isCurrentWeek: isCurrentWeek ?? this.isCurrentWeek,
      rows: rows ?? this.rows,
      dailyStats: dailyStats ?? this.dailyStats,
      totalCompleted: totalCompleted ?? this.totalCompleted,
      totalShielded: totalShielded ?? this.totalShielded,
      totalScheduled: totalScheduled ?? this.totalScheduled,
      adherencePercentage: adherencePercentage ?? this.adherencePercentage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final weekMatrixControllerProvider = StateNotifierProvider.autoDispose<
    WeekMatrixController, WeekMatrixUiState>((ref) {
  final repository = ref.watch(habitRepositoryProvider);
  return WeekMatrixController(repository);
});

class WeekMatrixController extends StateNotifier<WeekMatrixUiState> {
  final HabitRepository _repository;

  DateTime _weekStart = StreakCalculator.isoWeekStart(DateTime.now());
  List<Habit> _habits = [];
  List<HabitLog> _logs = [];
  List<HabitShield> _shields = [];
  List<HabitCategory> _categories = [];
  bool _recalculateScheduled = false;

  StreamSubscription? _habitsSub;
  StreamSubscription? _logsSub;
  StreamSubscription? _shieldsSub;
  StreamSubscription? _categoriesSub;

  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');

  WeekMatrixController(this._repository)
      : super(WeekMatrixUiState(isLoading: true)) {
    _init();
  }

  void _init() {
    _habitsSub = _repository.getActiveHabits().listen((habits) {
      _habits = habits;
      _scheduleRecalculate();
    });

    _categoriesSub = _repository.getAllCategories().listen((categories) {
      _categories = categories;
      _scheduleRecalculate();
    });

    _subscribeWeekData();
  }

  void _subscribeWeekData() {
    _logsSub?.cancel();
    _shieldsSub?.cancel();

    final weekEnd = _weekStart.add(const Duration(days: 6));
    _logsSub = _repository.getLogsForDateRange(_weekStart, weekEnd).listen((logs) {
      _logs = logs;
      _scheduleRecalculate();
    });

    _shieldsSub = _repository.getShieldsForDateRange(_weekStart, weekEnd).listen((shields) {
      _shields = shields;
      _scheduleRecalculate();
    });
  }

  void _scheduleRecalculate() {
    if (_recalculateScheduled) return;
    _recalculateScheduled = true;
    scheduleMicrotask(() {
      _recalculateScheduled = false;
      if (mounted) {
        _recalculate();
      }
    });
  }

  DateTime get currentWeekStart => _weekStart;

  void _recalculate() {
    final start = _weekStart;
    final weekEnd = start.add(const Duration(days: 6));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentIsoMonday = StreakCalculator.isoWeekStart(today);
    final isCurrentWeek =
        start.year == currentIsoMonday.year &&
        start.month == currentIsoMonday.month &&
        start.day == currentIsoMonday.day;

    final categoryMap = {for (var c in _categories) c.id: c};
    final logsByHabitDate = <String, Map<String, List<HabitLog>>>{};
    for (final log in _logs) {
      logsByHabitDate
          .putIfAbsent(log.habitId, () => {})
          .putIfAbsent(log.date, () => [])
          .add(log);
    }

    final shieldsByHabitDate = <String, Set<String>>{};
    for (final s in _shields) {
      shieldsByHabitDate.putIfAbsent(s.habitId, () => {}).add(s.date);
    }

    final weekDays = List.generate(7, (i) => start.add(Duration(days: i)));

    final rows = _habits.map((habit) {
      final logsByDate = logsByHabitDate[habit.id] ?? const {};
      final shieldedDates = shieldsByHabitDate[habit.id] ?? const {};

      int completedDaysCount = 0;
      int shieldedDaysCount = 0;
      final cells = weekDays.map((date) {
        final isToday =
            date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
        final isScheduled = StreakCalculator.isHabitScheduledOnDate(habit, date);
        final dateStr = StreakCalculator.formatIsoDate(date);
        final dayLogs = logsByDate[dateStr] ?? const [];
        final isCompleted =
            StreakCalculator.isHabitCompletedOnDate(habit, dayLogs);
        final isShielded = shieldedDates.contains(dateStr);

        if (isCompleted) {
          completedDaysCount++;
        } else if (isShielded) {
          shieldedDaysCount++;
        }

        final MatrixCellStatus status;
        if (isCompleted) {
          status = MatrixCellStatus.completed;
        } else if (isShielded) {
          status = MatrixCellStatus.shielded;
        } else if (isScheduled) {
          status = MatrixCellStatus.scheduledIncomplete;
        } else {
          status = MatrixCellStatus.notScheduled;
        }

        return MatrixCell(date: date, status: status, isToday: isToday);
      }).toList();

      final int targetCountThisWeek;
      switch (habit.frequencyType) {
        case HabitFrequencyType.daily:
          targetCountThisWeek = 7;
          break;
        case HabitFrequencyType.weekly:
          targetCountThisWeek = habit.targetCountPerWeek ?? 1;
          break;
        case HabitFrequencyType.customDays:
          targetCountThisWeek = habit.targetDaysOfWeek?.length ?? 7;
          break;
        case HabitFrequencyType.subdayInterval:
        case HabitFrequencyType.timesPerDay:
          targetCountThisWeek = 7;
          break;
      }

      return MatrixRow(
        habit: habit,
        category: habit.categoryId != null ? categoryMap[habit.categoryId] : null,
        cells: cells,
        completedCountThisWeek: completedDaysCount,
        shieldedCountThisWeek: shieldedDaysCount,
        targetCountThisWeek: targetCountThisWeek,
      );
    }).toList();

    // Sort pinned first, then title lowercase
    rows.sort((a, b) {
      if (a.habit.pinned != b.habit.pinned) {
        return a.habit.pinned ? -1 : 1;
      }
      return a.habit.title.toLowerCase().compareTo(b.habit.title.toLowerCase());
    });

    // Daily completion stats for the bar chart
    final dailyStats = weekDays.map((date) {
      final dateStr = StreakCalculator.formatIsoDate(date);
      final dayLabel = DateFormat('EEE').format(date).substring(0, 3);

      int scheduled = 0;
      int completed = 0;
      int shielded = 0;

      for (final habit in _habits) {
        final isScheduled = StreakCalculator.isHabitScheduledOnDate(habit, date);
        if (isScheduled) {
          scheduled++;
          final dayLogs = logsByHabitDate[habit.id]?[dateStr] ?? const [];
          if (StreakCalculator.isHabitCompletedOnDate(habit, dayLogs)) {
            completed++;
          } else {
            if (shieldsByHabitDate[habit.id]?.contains(dateStr) == true) {
              shielded++;
            }
          }
        }
      }

      return DailyCompletionStat(
        date: date,
        dayLabel: dayLabel,
        completedCount: completed,
        shieldedCount: shielded,
        scheduledCount: scheduled,
      );
    }).toList();

    final totalScheduled = rows.fold<int>(
      0,
      (sum, row) => sum + row.targetCountThisWeek,
    );
    final totalCompleted = rows.fold<int>(
      0,
      (sum, row) =>
          sum +
          (row.completedCountThisWeek < row.targetCountThisWeek
              ? row.completedCountThisWeek
              : row.targetCountThisWeek),
    );
    final totalShielded = rows.fold<int>(
      0,
      (sum, row) => sum + row.shieldedCountThisWeek,
    );

    final adherence = totalScheduled > 0
        ? ((totalCompleted / totalScheduled) * 100).round()
        : 0;

    state = WeekMatrixUiState(
      weekStart: start,
      weekEnd: weekEnd,
      isCurrentWeek: isCurrentWeek,
      rows: rows,
      dailyStats: dailyStats,
      totalCompleted: totalCompleted,
      totalShielded: totalShielded,
      totalScheduled: totalScheduled,
      adherencePercentage: adherence,
      isLoading: false,
    );
  }

  void previousWeek() {
    _weekStart = _weekStart.subtract(const Duration(days: 7));
    _subscribeWeekData();
  }

  void nextWeek() {
    _weekStart = _weekStart.add(const Duration(days: 7));
    _subscribeWeekData();
  }

  void currentWeek() {
    _weekStart = StreakCalculator.isoWeekStart(DateTime.now());
    _subscribeWeekData();
  }

  Future<void> toggleCell(String habitId, DateTime date) async {
    await _repository.toggleBooleanCheckIn(habitId, date);
  }

  Future<bool> toggleShieldCell(String habitId, DateTime date) async {
    return await _repository.toggleShield(habitId, date);
  }

  @override
  void dispose() {
    _habitsSub?.cancel();
    _logsSub?.cancel();
    _shieldsSub?.cancel();
    _categoriesSub?.cancel();
    super.dispose();
  }
}
