import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../di/providers.dart';
import '../../../domain/engines/streak_calculator.dart';
import '../../../domain/models/habit.dart';
import '../../../domain/models/habit_category.dart';
import '../../../domain/models/habit_frequency_type.dart';
import '../../../domain/models/habit_log.dart';
import '../../../domain/repositories/habit_repository.dart';

import '../../../domain/engines/wellbeing_correlation_engine.dart';

class LeaderboardItem {
  final Habit habit;
  final HabitCategory? category;
  final int currentStreak;
  final int bestStreak;
  final String unitLabel;

  const LeaderboardItem({
    required this.habit,
    this.category,
    required this.currentStreak,
    required this.bestStreak,
    required this.unitLabel,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardItem &&
          runtimeType == other.runtimeType &&
          habit == other.habit &&
          category == other.category &&
          currentStreak == other.currentStreak &&
          bestStreak == other.bestStreak &&
          unitLabel == other.unitLabel;

  @override
  int get hashCode =>
      habit.hashCode ^
      category.hashCode ^
      currentStreak.hashCode ^
      bestStreak.hashCode ^
      unitLabel.hashCode;
}

class AdherenceDataPoint {
  final DateTime date;
  final String label;
  final int adherencePercent;

  const AdherenceDataPoint({
    required this.date,
    required this.label,
    required this.adherencePercent,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdherenceDataPoint &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          label == other.label &&
          adherencePercent == other.adherencePercent;

  @override
  int get hashCode =>
      date.hashCode ^ label.hashCode ^ adherencePercent.hashCode;
}

enum TrendRange {
  sevenDays('7 Days', 7),
  thirtyDays('30 Days', 30);

  final String label;
  final int days;
  const TrendRange(this.label, this.days);
}

class HeatmapDayData {
  final DateTime date;
  final int completedCount;
  final int scheduledCount;
  final int ratePercent;

  const HeatmapDayData({
    required this.date,
    required this.completedCount,
    required this.scheduledCount,
    required this.ratePercent,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapDayData &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          completedCount == other.completedCount &&
          scheduledCount == other.scheduledCount &&
          ratePercent == other.ratePercent;

  @override
  int get hashCode =>
      date.hashCode ^
      completedCount.hashCode ^
      scheduledCount.hashCode ^
      ratePercent.hashCode;
}

class AnalyticsUiState {
  final int consistency30Days;
  final int consistencyDelta30Days;
  final int bestStreakRecord;
  final String bestStreakHabitTitle;
  final String bestStreakUnit;
  final int completedTodayCount;
  final int scheduledTodayCount;
  final List<LeaderboardItem> leaderboard;
  final TrendRange trendRange;
  final List<AdherenceDataPoint> trendDataPoints;
  final DateTime heatmapMonth;
  final Map<DateTime, HeatmapDayData> heatmapData;
  final WellbeingSummary wellbeingSummary;
  final bool isLoading;

  AnalyticsUiState({
    this.consistency30Days = 0,
    this.consistencyDelta30Days = 0,
    this.bestStreakRecord = 0,
    this.bestStreakHabitTitle = 'None',
    this.bestStreakUnit = 'days',
    this.completedTodayCount = 0,
    this.scheduledTodayCount = 0,
    this.leaderboard = const [],
    this.trendRange = TrendRange.sevenDays,
    this.trendDataPoints = const [],
    DateTime? heatmapMonth,
    this.heatmapData = const {},
    this.wellbeingSummary = WellbeingSummary.empty,
    this.isLoading = false,
  }) : heatmapMonth = heatmapMonth ??
            DateTime(DateTime.now().year, DateTime.now().month, 1);

  AnalyticsUiState copyWith({
    int? consistency30Days,
    int? consistencyDelta30Days,
    int? bestStreakRecord,
    String? bestStreakHabitTitle,
    String? bestStreakUnit,
    int? completedTodayCount,
    int? scheduledTodayCount,
    List<LeaderboardItem>? leaderboard,
    TrendRange? trendRange,
    List<AdherenceDataPoint>? trendDataPoints,
    DateTime? heatmapMonth,
    Map<DateTime, HeatmapDayData>? heatmapData,
    WellbeingSummary? wellbeingSummary,
    bool? isLoading,
  }) {
    return AnalyticsUiState(
      consistency30Days: consistency30Days ?? this.consistency30Days,
      consistencyDelta30Days:
          consistencyDelta30Days ?? this.consistencyDelta30Days,
      bestStreakRecord: bestStreakRecord ?? this.bestStreakRecord,
      bestStreakHabitTitle:
          bestStreakHabitTitle ?? this.bestStreakHabitTitle,
      bestStreakUnit: bestStreakUnit ?? this.bestStreakUnit,
      completedTodayCount: completedTodayCount ?? this.completedTodayCount,
      scheduledTodayCount: scheduledTodayCount ?? this.scheduledTodayCount,
      leaderboard: leaderboard ?? this.leaderboard,
      trendRange: trendRange ?? this.trendRange,
      trendDataPoints: trendDataPoints ?? this.trendDataPoints,
      heatmapMonth: heatmapMonth ?? this.heatmapMonth,
      heatmapData: heatmapData ?? this.heatmapData,
      wellbeingSummary: wellbeingSummary ?? this.wellbeingSummary,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final analyticsControllerProvider = StateNotifierProvider.autoDispose<
    AnalyticsController, AnalyticsUiState>((ref) {
  final repository = ref.watch(habitRepositoryProvider);
  return AnalyticsController(repository);
});

class AnalyticsController extends StateNotifier<AnalyticsUiState> {
  final HabitRepository _repository;

  TrendRange _trendRange = TrendRange.sevenDays;
  DateTime _heatmapMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);

  List<Habit> _habits = [];
  List<HabitLog> _logs = [];
  List<HabitCategory> _categories = [];

  StreamSubscription? _habitsSub;
  StreamSubscription? _logsSub;
  StreamSubscription? _categoriesSub;

  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');

  AnalyticsController(this._repository)
      : super(AnalyticsUiState(isLoading: true)) {
    _init();
  }

  void _init() {
    _habitsSub = _repository.getActiveHabits().listen((habits) {
      _habits = habits;
      _recalculate();
    });

    _logsSub = _repository.getAllLogs().listen((logs) {
      _logs = logs;
      _recalculate();
    });

    _categoriesSub = _repository.getAllCategories().listen((categories) {
      _categories = categories;
      _recalculate();
    });
  }

  TrendRange get trendRange => _trendRange;
  DateTime get heatmapMonth => _heatmapMonth;

  void _recalculate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = _dateFormatter.format(today);
    final categoryMap = {for (var c in _categories) c.id: c};

    final logsByHabit = <String, List<HabitLog>>{};
    for (final log in _logs) {
      logsByHabit.putIfAbsent(log.habitId, () => []).add(log);
    }

    // 1. Top KPIs: 30-Day consistency & Completed Today
    int totalScheduled30d = 0;
    int totalCompleted30d = 0;

    int scheduledToday = 0;
    int completedToday = 0;

    for (int i = 0; i < 30; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final dateStr = _dateFormatter.format(checkDate);

      for (final habit in _habits) {
        if (StreakCalculator.isHabitScheduledOnDate(habit, checkDate)) {
          totalScheduled30d++;
          final habitLogs = logsByHabit[habit.id] ?? const [];
          final dayLogs = habitLogs.where((l) => l.date == dateStr).toList();
          if (StreakCalculator.isHabitCompletedOnDate(habit, dayLogs)) {
            totalCompleted30d++;
          }
        }
      }
    }

    // Previous 30-Day window (days 30 to 59)
    int totalScheduledPrev30d = 0;
    int totalCompletedPrev30d = 0;

    for (int i = 30; i < 60; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final dateStr = _dateFormatter.format(checkDate);

      for (final habit in _habits) {
        if (StreakCalculator.isHabitScheduledOnDate(habit, checkDate)) {
          totalScheduledPrev30d++;
          final habitLogs = logsByHabit[habit.id] ?? const [];
          final dayLogs = habitLogs.where((l) => l.date == dateStr).toList();
          if (StreakCalculator.isHabitCompletedOnDate(habit, dayLogs)) {
            totalCompletedPrev30d++;
          }
        }
      }
    }

    for (final habit in _habits) {
      if (StreakCalculator.isHabitScheduledOnDate(habit, today)) {
        scheduledToday++;
        final habitLogs = logsByHabit[habit.id] ?? const [];
        final dayLogs = habitLogs.where((l) => l.date == todayStr).toList();
        if (StreakCalculator.isHabitCompletedOnDate(habit, dayLogs)) {
          completedToday++;
        }
      }
    }

    final consistency30 = totalScheduled30d > 0
        ? ((totalCompleted30d / totalScheduled30d) * 100).round()
        : 0;

    final prevConsistency30 = totalScheduledPrev30d > 0
        ? ((totalCompletedPrev30d / totalScheduledPrev30d) * 100).round()
        : 0;

    final delta30 = consistency30 - prevConsistency30;

    // 2. Streaks Leaderboard & Best Overall Record
    final habitStreaks = _habits.map((habit) {
      final habitLogs = logsByHabit[habit.id] ?? const [];
      final streak = StreakCalculator.calculateStreak(habit, habitLogs, today);
      final unit =
          habit.frequencyType == HabitFrequencyType.weekly ? 'weeks' : 'days';
      return LeaderboardItem(
        habit: habit,
        category: habit.categoryId != null ? categoryMap[habit.categoryId] : null,
        currentStreak: streak.currentStreak,
        bestStreak: streak.bestStreak,
        unitLabel: unit,
      );
    }).toList();

    habitStreaks.sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
    final leaderboard = habitStreaks.take(5).toList();

    LeaderboardItem? bestOverall;
    if (habitStreaks.isNotEmpty) {
      bestOverall = habitStreaks.reduce(
        (max, item) => item.bestStreak > max.bestStreak ? item : max,
      );
    }

    // 3. Trend Data Points (7 or 30 days)
    final trendPoints = List.generate(_trendRange.days, (i) {
      final offset = _trendRange.days - 1 - i;
      final date = today.subtract(Duration(days: offset));
      final dateStr = _dateFormatter.format(date);

      int dayScheduled = 0;
      int dayCompleted = 0;

      for (final habit in _habits) {
        if (StreakCalculator.isHabitScheduledOnDate(habit, date)) {
          dayScheduled++;
          final habitLogs = logsByHabit[habit.id] ?? const [];
          final dayLogs = habitLogs.where((l) => l.date == dateStr).toList();
          if (StreakCalculator.isHabitCompletedOnDate(habit, dayLogs)) {
            dayCompleted++;
          }
        }
      }

      final adherence = dayScheduled > 0
          ? ((dayCompleted / dayScheduled) * 100).round()
          : 0;

      final String label;
      if (_trendRange == TrendRange.sevenDays) {
        label = DateFormat('EEE').format(date);
      } else {
        label = DateFormat('d MMM').format(date);
      }

      return AdherenceDataPoint(
        date: date,
        label: label,
        adherencePercent: adherence,
      );
    });

    // 4. Heatmap Month Data
    final daysInMonth =
        DateTime(_heatmapMonth.year, _heatmapMonth.month + 1, 0).day;
    final heatmapData = <DateTime, HeatmapDayData>{};

    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_heatmapMonth.year, _heatmapMonth.month, d);
      final dateStr = _dateFormatter.format(date);

      int dayScheduled = 0;
      int dayCompleted = 0;

      for (final habit in _habits) {
        if (StreakCalculator.isHabitScheduledOnDate(habit, date)) {
          dayScheduled++;
          final habitLogs = logsByHabit[habit.id] ?? const [];
          final dayLogs = habitLogs.where((l) => l.date == dateStr).toList();
          if (StreakCalculator.isHabitCompletedOnDate(habit, dayLogs)) {
            dayCompleted++;
          }
        }
      }

      final rate = dayScheduled > 0
          ? ((dayCompleted / dayScheduled) * 100).round()
          : 0;

      heatmapData[date] = HeatmapDayData(
        date: date,
        completedCount: dayCompleted,
        scheduledCount: dayScheduled,
        ratePercent: rate,
      );
    }

    // 5. Wellbeing & Energy Correlation Summary
    final wellbeingSummary = WellbeingCorrelationEngine.calculateCorrelation(
      habits: _habits,
      logs: _logs,
      referenceDate: today,
      daysCount: 30,
    );

    state = AnalyticsUiState(
      consistency30Days: consistency30,
      consistencyDelta30Days: delta30,
      bestStreakRecord: bestOverall?.bestStreak ?? 0,
      bestStreakHabitTitle: bestOverall?.habit.title ?? 'None',
      bestStreakUnit: bestOverall?.unitLabel ?? 'days',
      completedTodayCount: completedToday,
      scheduledTodayCount: scheduledToday,
      leaderboard: leaderboard,
      trendRange: _trendRange,
      trendDataPoints: trendPoints,
      heatmapMonth: _heatmapMonth,
      heatmapData: heatmapData,
      wellbeingSummary: wellbeingSummary,
      isLoading: false,
    );
  }

  void setTrendRange(TrendRange range) {
    _trendRange = range;
    _recalculate();
  }

  void previousHeatmapMonth() {
    _heatmapMonth = DateTime(_heatmapMonth.year, _heatmapMonth.month - 1, 1);
    _recalculate();
  }

  void nextHeatmapMonth() {
    _heatmapMonth = DateTime(_heatmapMonth.year, _heatmapMonth.month + 1, 1);
    _recalculate();
  }

  @override
  void dispose() {
    _habitsSub?.cancel();
    _logsSub?.cancel();
    _categoriesSub?.cancel();
    super.dispose();
  }
}
