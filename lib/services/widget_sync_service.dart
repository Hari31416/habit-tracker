import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../domain/engines/streak_calculator.dart';
import '../domain/gamification/gamification_engine.dart';
import '../domain/gamification/gamification_models.dart';
import '../domain/gamification/player_title.dart';
import '../domain/models/habit_target_type.dart';
import '../domain/repositories/gamification_repository.dart';
import '../domain/repositories/habit_repository.dart';

class DailyFocusWidgetSnapshot {
  final int completedCount;
  final int totalScheduled;
  final int ratePercent;
  final int bestStreak;
  final int focusMinutes;
  final int xpEarnedToday;

  const DailyFocusWidgetSnapshot({
    required this.completedCount,
    required this.totalScheduled,
    required this.ratePercent,
    required this.bestStreak,
    required this.focusMinutes,
    required this.xpEarnedToday,
  });

  Map<String, dynamic> toJson() => {
        'completedCount': completedCount,
        'totalScheduled': totalScheduled,
        'ratePercent': ratePercent,
        'bestStreak': bestStreak,
        'focusMinutes': focusMinutes,
        'xpEarnedToday': xpEarnedToday,
      };
}

class TodaysHabitWidgetSnapshotItem {
  final String id;
  final String title;
  final String categoryName;
  final String colorHex;
  final bool isCompleted;
  final int currentStreak;
  final bool pinned;

  const TodaysHabitWidgetSnapshotItem({
    required this.id,
    required this.title,
    required this.categoryName,
    required this.colorHex,
    required this.isCompleted,
    required this.currentStreak,
    required this.pinned,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'categoryName': categoryName,
        'colorHex': colorHex,
        'isCompleted': isCompleted,
        'currentStreak': currentStreak,
        'pinned': pinned,
      };
}

class TodaysHabitsWidgetSnapshot {
  final List<TodaysHabitWidgetSnapshotItem> habits;
  final int completedCount;
  final int totalScheduled;
  final int topStreak;
  final int todayXp;

  const TodaysHabitsWidgetSnapshot({
    required this.habits,
    required this.completedCount,
    required this.totalScheduled,
    required this.topStreak,
    required this.todayXp,
  });

  Map<String, dynamic> toJson() => {
        'habits': habits.map((h) => h.toJson()).toList(),
        'completedCount': completedCount,
        'totalScheduled': totalScheduled,
        'topStreak': topStreak,
        'todayXp': todayXp,
      };
}

class StreakHabitWidgetSnapshotItem {
  final String id;
  final String title;
  final String categoryName;
  final int currentStreak;
  final int bestStreak;
  final bool isScheduledToday;
  final bool isCompletedToday;

  const StreakHabitWidgetSnapshotItem({
    required this.id,
    required this.title,
    required this.categoryName,
    required this.currentStreak,
    required this.bestStreak,
    required this.isScheduledToday,
    required this.isCompletedToday,
  });

  bool get isAtRiskToday =>
      isScheduledToday && !isCompletedToday && currentStreak > 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'categoryName': categoryName,
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'isScheduledToday': isScheduledToday,
        'isCompletedToday': isCompletedToday,
        'isAtRiskToday': isAtRiskToday,
      };
}

class StreaksWidgetSnapshot {
  final List<StreakHabitWidgetSnapshotItem> habits;
  final int bestOverallStreak;
  final int activeStreaksCount;

  const StreaksWidgetSnapshot({
    required this.habits,
    required this.bestOverallStreak,
    required this.activeStreaksCount,
  });

  Map<String, dynamic> toJson() => {
        'habits': habits.map((h) => h.toJson()).toList(),
        'bestOverallStreak': bestOverallStreak,
        'activeStreaksCount': activeStreaksCount,
      };
}

class FocusTimerWidgetSnapshot {
  final String? habitId;
  final String habitTitle;
  final int totalSeconds;
  final int remainingSeconds;
  final String status;
  final double progressFraction;
  final int todayFocusMinutes;
  final int currentStreak;

  const FocusTimerWidgetSnapshot({
    this.habitId,
    required this.habitTitle,
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.status,
    required this.progressFraction,
    this.todayFocusMinutes = 0,
    this.currentStreak = 0,
  });

  Map<String, dynamic> toJson() => {
        'habitId': habitId,
        'habitTitle': habitTitle,
        'totalSeconds': totalSeconds,
        'remainingSeconds': remainingSeconds,
        'status': status,
        'progressFraction': progressFraction,
        'todayFocusMinutes': todayFocusMinutes,
        'currentStreak': currentStreak,
      };
}

class XpMasteryWidgetSnapshot {
  final int level;
  final String titleDisplayName;
  final int totalXp;
  final int nextLevelTargetXp;
  final double progressFraction;
  final int unlockedBadgesCount;
  final int totalBadgesCount;
  final int xpNeededForNextLevel;
  final String? nextTitleDisplayName;
  final String? nextBadgeTitle;
  final int nextBadgeProgress;
  final int nextBadgeTarget;
  final String nextBadgeUnit;
  final double activeStreakMultiplier;

  const XpMasteryWidgetSnapshot({
    required this.level,
    required this.titleDisplayName,
    required this.totalXp,
    required this.nextLevelTargetXp,
    required this.progressFraction,
    required this.unlockedBadgesCount,
    required this.totalBadgesCount,
    required this.xpNeededForNextLevel,
    this.nextTitleDisplayName,
    this.nextBadgeTitle,
    this.nextBadgeProgress = 0,
    this.nextBadgeTarget = 10,
    this.nextBadgeUnit = 'days',
    this.activeStreakMultiplier = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'level': level,
        'titleDisplayName': titleDisplayName,
        'totalXp': totalXp,
        'nextLevelTargetXp': nextLevelTargetXp,
        'progressFraction': progressFraction,
        'unlockedBadgesCount': unlockedBadgesCount,
        'totalBadgesCount': totalBadgesCount,
        'xpNeededForNextLevel': xpNeededForNextLevel,
        'nextTitleDisplayName': nextTitleDisplayName,
        'nextBadgeTitle': nextBadgeTitle,
        'nextBadgeProgress': nextBadgeProgress,
        'nextBadgeTarget': nextBadgeTarget,
        'nextBadgeUnit': nextBadgeUnit,
        'activeStreakMultiplier': activeStreakMultiplier,
      };
}

class WidgetSyncService {
  final HabitRepository _repository;
  final GamificationRepository? _gamificationRepository;
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');

  // Cached snapshots for platform widgets / testing
  DailyFocusWidgetSnapshot? lastDailyFocus;
  TodaysHabitsWidgetSnapshot? lastTodaysHabits;
  StreaksWidgetSnapshot? lastStreaks;
  XpMasteryWidgetSnapshot? lastXpMastery;
  FocusTimerWidgetSnapshot? lastFocusTimer;

  WidgetSyncService(
    this._repository, [
    this._gamificationRepository,
  ]);

  Future<void> syncFocusTimerWidget({
    String? habitId,
    required String habitTitle,
    required int totalSeconds,
    required int remainingSeconds,
    required String status,
    required double progressFraction,
  }) async {
    lastFocusTimer = FocusTimerWidgetSnapshot(
      habitId: habitId,
      habitTitle: habitTitle,
      totalSeconds: totalSeconds,
      remainingSeconds: remainingSeconds,
      status: status,
      progressFraction: progressFraction,
    );
    try {
      const channel = MethodChannel('com.productivity.habits/widgets');
      await channel.invokeMethod('updateWidgetData', {
        'widgetType': 'focus_timer',
        'jsonData': jsonEncode(lastFocusTimer!.toJson()),
      });
      await channel.invokeMethod('updateAllWidgets');
    } catch (_) {}
  }

  Future<void> consumePendingWidgetActions() async {
    try {
      const channel = MethodChannel('com.productivity.habits/widgets');
      final dynamic checkIns =
          await channel.invokeMethod('getPendingWidgetCheckIns');
      final now = DateTime.now();
      if (checkIns is List && checkIns.isNotEmpty) {
        for (final habitId in checkIns) {
          if (habitId is String && habitId.isNotEmpty) {
            await _repository.toggleBooleanCheckIn(habitId, now);
          }
        }
      }

      final dynamic sessions =
          await channel.invokeMethod('getPendingCompletedFocusSessions');
      if (sessions is List && sessions.isNotEmpty) {
        for (final item in sessions) {
          if (item is String && item.isNotEmpty) {
            try {
              final obj = jsonDecode(item) as Map<String, dynamic>;
              final habitId = obj['habitId'] as String?;
              final durationSeconds = (obj['durationSeconds'] as num?)?.toInt() ?? 1500;
              final durationMinutes = durationSeconds / 60.0;
              if (habitId != null && habitId.isNotEmpty) {
                await _repository.logCheckIn(
                  habitId: habitId,
                  date: now,
                  completed: true,
                  value: durationMinutes,
                  durationSeconds: durationSeconds,
                  note: 'Completed focus timer session (${durationMinutes.toInt()} mins)',
                );
              }
            } catch (_) {}
          }
        }
      }

      if ((checkIns is List && checkIns.isNotEmpty) ||
          (sessions is List && sessions.isNotEmpty)) {
        await syncAllWidgets(now);
      }
    } catch (_) {}
  }

  Future<void> syncAllWidgets([DateTime? date]) async {
    final today = date ?? DateTime.now();
    final todayStr = _dateFormatter.format(today);

    final activeHabits = await _repository.getActiveHabits().first;
    final allLogs = await _repository.getAllLogsOnce();
    final categoriesList = await _repository.getAllCategoriesOnce();

    final categories = {for (var c in categoriesList) c.id: c.name};
    final allLogsByHabit = <String, List<dynamic>>{};
    for (final l in allLogs) {
      allLogsByHabit.putIfAbsent(l.habitId, () => []).add(l);
    }

    final todayLogs = allLogs.where((l) => l.date == todayStr).toList();
    final logsByHabit = <String, List<dynamic>>{};
    for (final l in todayLogs) {
      logsByHabit.putIfAbsent(l.habitId, () => []).add(l);
    }

    int completedCount = 0;
    int scheduledCount = 0;
    int maxStreak = 0;
    int totalFocusSec = 0;
    int totalXpToday = 0;

    final scheduledItems = <TodaysHabitWidgetSnapshotItem>[];
    final streakItems = <StreakHabitWidgetSnapshotItem>[];

    for (final habit in activeHabits) {
      final isScheduled = StreakCalculator.isHabitScheduledOnDate(habit, today);
      final habitLogs =
          (allLogsByHabit[habit.id] ?? const []).cast<dynamic>();
      final streakResult = StreakCalculator.calculateStreak(
        habit,
        habitLogs.cast(),
        today,
      );

      if (streakResult.currentStreak > maxStreak) {
        maxStreak = streakResult.currentStreak;
      }

      final todayHabitLogs =
          (logsByHabit[habit.id] ?? const []).cast<dynamic>();
      final isDone = StreakCalculator.isHabitCompletedOnDate(
        habit,
        todayHabitLogs.cast(),
      );

      final categoryName = categories[habit.categoryId] ?? 'General';

      if (isScheduled) {
        scheduledCount++;
        if (isDone) {
          completedCount++;
        }

        final baseXp = GamificationEngine.calculateHabitDayBaseXp(
          habit,
          todayHabitLogs.cast(),
          isDone,
        );
        final mult = GamificationEngine.calculateStreakMultiplier(
          streakResult.currentStreak,
        );
        totalXpToday += GamificationEngine.applyMultiplier(baseXp, mult);

        scheduledItems.add(
          TodaysHabitWidgetSnapshotItem(
            id: habit.id,
            title: habit.title,
            categoryName: categoryName,
            colorHex: habit.color,
            isCompleted: isDone,
            currentStreak: streakResult.currentStreak,
            pinned: habit.pinned,
          ),
        );
      }

      streakItems.add(
        StreakHabitWidgetSnapshotItem(
          id: habit.id,
          title: habit.title,
          categoryName: categoryName,
          currentStreak: streakResult.currentStreak,
          bestStreak: streakResult.bestStreak,
          isScheduledToday: isScheduled,
          isCompletedToday: isDone,
        ),
      );
    }

    for (final log in todayLogs) {
      if (log.durationSeconds != null && log.durationSeconds! > 0) {
        totalFocusSec += log.durationSeconds!;
      } else if (log.value != null && log.value! > 0) {
        final habit = activeHabits.where((h) => h.id == log.habitId).firstOrNull;
        if (habit?.targetType == HabitTargetType.timer) {
          totalFocusSec += (log.value! * 60).toInt();
        }
      }
    }

    final ratePercent = scheduledCount > 0
        ? ((completedCount / scheduledCount) * 100).round()
        : 0;

    // 1. Daily Focus
    lastDailyFocus = DailyFocusWidgetSnapshot(
      completedCount: completedCount,
      totalScheduled: scheduledCount,
      ratePercent: ratePercent,
      bestStreak: maxStreak,
      focusMinutes: (totalFocusSec / 60).toInt(),
      xpEarnedToday: totalXpToday,
    );

    // 2. Today's Habits
    final sortedScheduled = List<TodaysHabitWidgetSnapshotItem>.from(scheduledItems)
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return a.title.compareTo(b.title);
      });

    lastTodaysHabits = TodaysHabitsWidgetSnapshot(
      habits: sortedScheduled,
      completedCount: completedCount,
      totalScheduled: scheduledCount,
      topStreak: maxStreak,
      todayXp: totalXpToday,
    );

    // 3. Streaks
    final sortedStreaks = List<StreakHabitWidgetSnapshotItem>.from(streakItems)
      ..sort((a, b) {
        if (a.currentStreak != b.currentStreak) {
          return b.currentStreak.compareTo(a.currentStreak);
        }
        if (a.isAtRiskToday != b.isAtRiskToday) {
          return a.isAtRiskToday ? -1 : 1;
        }
        return b.bestStreak.compareTo(a.bestStreak);
      });

    final activeStreaks = sortedStreaks.where((s) => s.currentStreak > 0).length;
    final bestOverall = sortedStreaks.fold<int>(
      0,
      (max, s) => s.bestStreak > max ? s.bestStreak : max,
    );

    lastStreaks = StreaksWidgetSnapshot(
      habits: sortedStreaks,
      bestOverallStreak: bestOverall,
      activeStreaksCount: activeStreaks,
    );

    // 4. XP Mastery
    if (_gamificationRepository != null) {
      try {
        final prog =
            await _gamificationRepository.getPlayerProgression().first;
        final achievements =
            await _gamificationRepository.getAchievements().first;

        final xpNeeded =
            (prog.nextLevelTargetXp - prog.totalXp).clamp(0, 999999);
        final nextTitle = PlayerTitle.nextTitle(prog.level);
        final inProgressBadge = achievements
            .where((a) => !a.isUnlocked)
            .fold<AchievementStatus?>(
              null,
              (best, a) =>
                  best == null || a.progressFraction > best.progressFraction
                      ? a
                      : best,
            );

        lastXpMastery = XpMasteryWidgetSnapshot(
          level: prog.level,
          titleDisplayName: prog.title.displayName,
          totalXp: prog.totalXp,
          nextLevelTargetXp: prog.nextLevelTargetXp,
          progressFraction: prog.progressFraction,
          unlockedBadgesCount: prog.unlockedBadgesCount,
          totalBadgesCount: prog.totalBadgesCount,
          xpNeededForNextLevel: xpNeeded,
          nextTitleDisplayName: nextTitle?.displayName,
          nextBadgeTitle: inProgressBadge?.definition.title,
          nextBadgeProgress: inProgressBadge?.currentProgress ?? 0,
          nextBadgeTarget: inProgressBadge?.definition.targetValue ?? 10,
          nextBadgeUnit: inProgressBadge?.definition.unit ?? 'days',
          activeStreakMultiplier: prog.activeStreakMultiplier,
        );
      } catch (_) {}
    }

    // 5. Focus Timer
    if (lastFocusTimer == null ||
        lastFocusTimer!.status == 'Ready' ||
        lastFocusTimer!.status == 'idle') {
      final timerHabit = activeHabits
              .where((h) => h.targetType == HabitTargetType.timer)
              .firstOrNull ??
          activeHabits.firstOrNull;
      if (timerHabit != null) {
        final targetMins = timerHabit.targetValue ?? 25.0;
        final totalSec = (targetMins * 60).round();
        final habitLogs =
            (allLogsByHabit[timerHabit.id] ?? const []).cast<dynamic>();
        final streakResult = StreakCalculator.calculateStreak(
          timerHabit,
          habitLogs.cast(),
          today,
        );
        lastFocusTimer = FocusTimerWidgetSnapshot(
          habitId: timerHabit.id,
          habitTitle: timerHabit.title,
          totalSeconds: totalSec,
          remainingSeconds: totalSec,
          status: 'Ready',
          progressFraction: 0.0,
          todayFocusMinutes: (totalFocusSec / 60).toInt(),
          currentStreak: streakResult.currentStreak,
        );
      }
    }

    // Platform sync via MethodChannel
    try {
      const channel = MethodChannel('com.productivity.habits/widgets');
      if (lastDailyFocus != null) {
        await channel.invokeMethod('updateWidgetData', {
          'widgetType': 'daily_focus',
          'jsonData': jsonEncode(lastDailyFocus!.toJson()),
        });
      }
      if (lastTodaysHabits != null) {
        await channel.invokeMethod('updateWidgetData', {
          'widgetType': 'todays_habits',
          'jsonData': jsonEncode(lastTodaysHabits!.toJson()),
        });
      }
      if (lastStreaks != null) {
        await channel.invokeMethod('updateWidgetData', {
          'widgetType': 'streaks',
          'jsonData': jsonEncode(lastStreaks!.toJson()),
        });
      }
      if (lastXpMastery != null) {
        await channel.invokeMethod('updateWidgetData', {
          'widgetType': 'xp_mastery',
          'jsonData': jsonEncode(lastXpMastery!.toJson()),
        });
      }
      if (lastFocusTimer != null) {
        await channel.invokeMethod('updateWidgetData', {
          'widgetType': 'focus_timer',
          'jsonData': jsonEncode(lastFocusTimer!.toJson()),
        });
      }
      await channel.invokeMethod('updateAllWidgets');
    } catch (_) {
      // Ignored in headless/test environments
    }
  }
}
