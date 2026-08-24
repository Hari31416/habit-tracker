import 'dart:math';
import '../engines/streak_calculator.dart';
import '../gamification/achievement_evaluator.dart';
import '../gamification/gamification_engine.dart';
import '../gamification/gamification_models.dart';
import '../models/habit.dart';
import '../models/habit_category.dart';
import '../models/habit_log.dart';
import '../models/habit_routine.dart';
import '../models/habit_shield.dart';
import '../models/routine_log.dart';
import '../models/sync/sync_envelope.dart';

/// Merge statistics for preview dialogs and confirmation summaries.
class MergeStats {
  final int habitsAdded;
  final int habitsUpdated;
  final int habitsDeleted;
  final int logsMerged;
  final int shieldsMerged;
  final int categoriesAdded;
  final int categoriesUpdated;
  final int totalXp;
  final int level;

  const MergeStats({
    this.habitsAdded = 0,
    this.habitsUpdated = 0,
    this.habitsDeleted = 0,
    this.logsMerged = 0,
    this.shieldsMerged = 0,
    this.categoriesAdded = 0,
    this.categoriesUpdated = 0,
    this.totalXp = 0,
    this.level = 1,
  });
}

/// Result of a 2-way merge operation.
class MergeResult {
  final SyncDataPayload mergedPayload;
  final MergeStats stats;

  const MergeResult({
    required this.mergedPayload,
    required this.stats,
  });
}

/// Pure deterministic two-way state merging engine.
class SyncMergeEngine {
  /// Natural key generator for HabitLog slots.
  static String logNaturalKey(HabitLog log) =>
      '${log.habitId}_${log.date}_${log.intervalIndex ?? -1}';

  /// Natural key generator for HabitShields.
  static String shieldNaturalKey(HabitShield shield) =>
      '${shield.habitId}_${shield.date}';

  /// Performs a deterministic 2-way merge of local and remote states.
  static MergeResult merge({
    required SyncDataPayload local,
    required SyncDataPayload remote,
    DateTime Function()? clock,
  }) {
    final now = (clock != null ? clock() : DateTime.now()).toUtc();

    // 1. Merge Categories by ID (LWW)
    final mergedCategoriesMap = <String, HabitCategory>{};
    var categoriesAdded = 0;
    var categoriesUpdated = 0;

    final localCategories = {for (var c in local.categories) c.id: c};
    final remoteCategories = {for (var c in remote.categories) c.id: c};
    final allCategoryIds = {...localCategories.keys, ...remoteCategories.keys};

    for (final id in allCategoryIds) {
      final loc = localCategories[id];
      final rem = remoteCategories[id];

      if (loc == null && rem != null) {
        mergedCategoriesMap[id] = rem;
        if (!rem.isDeleted) categoriesAdded++;
      } else if (loc != null && rem == null) {
        mergedCategoriesMap[id] = loc;
      } else if (loc != null && rem != null) {
        final locUpdated = loc.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
        final remUpdated = rem.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

        if (remUpdated.isAfter(locUpdated)) {
          mergedCategoriesMap[id] = rem;
          categoriesUpdated++;
        } else {
          mergedCategoriesMap[id] = loc;
        }
      }
    }

    // 2. Merge Habits by ID (LWW)
    final mergedHabitsMap = <String, Habit>{};
    var habitsAdded = 0;
    var habitsUpdated = 0;
    var habitsDeleted = 0;

    final localHabits = {for (var h in local.habits) h.id: h};
    final remoteHabits = {for (var h in remote.habits) h.id: h};
    final allHabitIds = {...localHabits.keys, ...remoteHabits.keys};

    for (final id in allHabitIds) {
      final loc = localHabits[id];
      final rem = remoteHabits[id];

      if (loc == null && rem != null) {
        mergedHabitsMap[id] = rem;
        if (rem.isDeleted) {
          habitsDeleted++;
        } else {
          habitsAdded++;
        }
      } else if (loc != null && rem == null) {
        mergedHabitsMap[id] = loc;
      } else if (loc != null && rem != null) {
        if (rem.updatedAt.toUtc().isAfter(loc.updatedAt.toUtc())) {
          mergedHabitsMap[id] = rem;
          if (rem.isDeleted && !loc.isDeleted) {
            habitsDeleted++;
          } else {
            habitsUpdated++;
          }
        } else {
          mergedHabitsMap[id] = loc;
        }
      }
    }

    // 3. Merge Logs by Natural Key (habitId_date_slot) (LWW)
    final mergedLogsMap = <String, HabitLog>{};
    var logsMerged = 0;

    final localLogs = {for (var l in local.logs) logNaturalKey(l): l};
    final remoteLogs = {for (var l in remote.logs) logNaturalKey(l): l};
    final allLogKeys = {...localLogs.keys, ...remoteLogs.keys};

    for (final key in allLogKeys) {
      final loc = localLogs[key];
      final rem = remoteLogs[key];

      if (loc == null && rem != null) {
        mergedLogsMap[key] = rem;
        if (!rem.isDeleted) logsMerged++;
      } else if (loc != null && rem == null) {
        mergedLogsMap[key] = loc;
      } else if (loc != null && rem != null) {
        if (rem.updatedAt.toUtc().isAfter(loc.updatedAt.toUtc())) {
          mergedLogsMap[key] = rem;
          logsMerged++;
        } else {
          mergedLogsMap[key] = loc;
        }
      }
    }

    // 4. Merge Shields by Natural Key (habitId_date) (LWW)
    final mergedShieldsMap = <String, HabitShield>{};
    var shieldsMerged = 0;

    final localShields = {for (var s in local.shields) shieldNaturalKey(s): s};
    final remoteShields = {for (var s in remote.shields) shieldNaturalKey(s): s};
    final allShieldKeys = {...localShields.keys, ...remoteShields.keys};

    for (final key in allShieldKeys) {
      final loc = localShields[key];
      final rem = remoteShields[key];

      if (loc == null && rem != null) {
        mergedShieldsMap[key] = rem;
        if (!rem.isDeleted) shieldsMerged++;
      } else if (loc != null && rem == null) {
        mergedShieldsMap[key] = loc;
      } else if (loc != null && rem != null) {
        if (rem.updatedAt.toUtc().isAfter(loc.updatedAt.toUtc())) {
          mergedShieldsMap[key] = rem;
          shieldsMerged++;
        } else {
          mergedShieldsMap[key] = loc;
        }
      }
    }

    final mergedCategories = mergedCategoriesMap.values.toList();
    final mergedHabits = mergedHabitsMap.values.toList();
    final mergedLogs = mergedLogsMap.values.toList();
    final mergedShields = mergedShieldsMap.values.toList();

    // 5. Fact-First Gamification Recomputation
    final activeHabits = mergedHabits.where((h) => !h.isDeleted).toList();
    final activeLogs = mergedLogs.where((l) => !l.isDeleted).toList();
    final activeShields = mergedShields.where((s) => !s.isDeleted).toList();
    final activeCategories = mergedCategories.where((c) => !c.isDeleted).toList();

    final logsByHabit = <String, List<HabitLog>>{};
    final logsByDate = <String, List<HabitLog>>{};
    final logsByHabitDate = <String, Map<String, List<HabitLog>>>{};
    for (final log in activeLogs) {
      logsByHabit.putIfAbsent(log.habitId, () => []).add(log);
      logsByDate.putIfAbsent(log.date, () => []).add(log);
      logsByHabitDate
          .putIfAbsent(log.habitId, () => {})
          .putIfAbsent(log.date, () => [])
          .add(log);
    }

    final shieldsByHabit = <String, List<HabitShield>>{};
    for (final shield in activeShields) {
      shieldsByHabit.putIfAbsent(shield.habitId, () => []).add(shield);
    }

    final streakByHabit = <String, StreakResult>{};
    var longestActiveStreak = 0;

    for (final habit in activeHabits) {
      final habitLogs = logsByHabit[habit.id] ?? const [];
      final habitShields = shieldsByHabit[habit.id] ?? const [];
      final streak = StreakCalculator.calculateStreak(
        habit,
        habitLogs,
        now,
        habitShields,
      );
      streakByHabit[habit.id] = streak;
      longestActiveStreak = max(longestActiveStreak, streak.currentStreak);
    }

    // Calculate Base Habit Check-in XP
    var habitCheckInXp = 0;
    for (final habit in activeHabits) {
      final habitLogsByDate = logsByHabitDate[habit.id] ?? const {};
      final currentStreak = streakByHabit[habit.id]?.currentStreak ?? 0;
      final habitMultiplier = GamificationEngine.calculateStreakMultiplier(currentStreak);

      for (final dayLogs in habitLogsByDate.values) {
        final isCompleted = StreakCalculator.isHabitCompletedOnDate(habit, dayLogs);
        final baseXp = GamificationEngine.calculateHabitDayBaseXp(habit, dayLogs, isCompleted);
        if (baseXp > 0) {
          habitCheckInXp += GamificationEngine.applyMultiplier(baseXp, habitMultiplier);
        }
      }
    }

    // Perfect Days Bonus XP
    var perfectDaysBonusXp = 0;
    for (final dateStr in logsByDate.keys) {
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;
      final scheduled = activeHabits
          .where((h) => !h.archived && StreakCalculator.isHabitScheduledOnDate(h, date))
          .toList();
      if (scheduled.isNotEmpty) {
        final allCompleted = scheduled.every((h) {
          final dayLogs = logsByHabitDate[h.id]?[dateStr] ?? const [];
          return StreakCalculator.isHabitCompletedOnDate(h, dayLogs);
        });
        if (allCompleted) {
          perfectDaysBonusXp += GamificationEngine.perfectDayBonusXp;
        }
      }
    }

    // Stored unlocks union (earliest unlocked date)
    final localAchMap = {for (var a in local.achievements) a.id: a};
    final remoteAchMap = {for (var a in remote.achievements) a.id: a};
    final allAchIds = {...localAchMap.keys, ...remoteAchMap.keys};

    final storedUnlocks = <String, DateTime>{};
    final storedNotified = <String, bool>{};

    for (final id in allAchIds) {
      final loc = localAchMap[id];
      final rem = remoteAchMap[id];

      if (loc != null && rem != null) {
        storedUnlocks[id] = loc.unlockedAt.isBefore(rem.unlockedAt) ? loc.unlockedAt : rem.unlockedAt;
        storedNotified[id] = loc.notified || rem.notified;
      } else if (loc != null) {
        storedUnlocks[id] = loc.unlockedAt;
        storedNotified[id] = loc.notified;
      } else if (rem != null) {
        storedUnlocks[id] = rem.unlockedAt;
        storedNotified[id] = rem.notified;
      }
    }

    // Merge Routines by ID (LWW)
    final mergedRoutinesMap = <String, HabitRoutine>{};
    final localRoutines = {for (var r in local.routines) r.id: r};
    final remoteRoutines = {for (var r in remote.routines) r.id: r};
    final allRoutineIds = {...localRoutines.keys, ...remoteRoutines.keys};
    for (final id in allRoutineIds) {
      final loc = localRoutines[id];
      final rem = remoteRoutines[id];
      if (loc == null && rem != null) {
        mergedRoutinesMap[id] = rem;
      } else if (loc != null && rem == null) {
        mergedRoutinesMap[id] = loc;
      } else if (loc != null && rem != null) {
        if (rem.updatedAt.isAfter(loc.updatedAt)) {
          mergedRoutinesMap[id] = rem;
        } else {
          mergedRoutinesMap[id] = loc;
        }
      }
    }
    final mergedRoutines = mergedRoutinesMap.values.toList();

    // Merge RoutineLogs by ID (LWW)
    final mergedRoutineLogsMap = <String, RoutineLog>{};
    final localRoutineLogs = {for (var l in local.routineLogs) l.id: l};
    final remoteRoutineLogs = {for (var l in remote.routineLogs) l.id: l};
    final allRoutineLogIds = {...localRoutineLogs.keys, ...remoteRoutineLogs.keys};
    for (final id in allRoutineLogIds) {
      final loc = localRoutineLogs[id];
      final rem = remoteRoutineLogs[id];
      if (loc == null && rem != null) {
        mergedRoutineLogsMap[id] = rem;
      } else if (loc != null && rem == null) {
        mergedRoutineLogsMap[id] = loc;
      } else if (loc != null && rem != null) {
        if (rem.updatedAt.isAfter(loc.updatedAt)) {
          mergedRoutineLogsMap[id] = rem;
        } else {
          mergedRoutineLogsMap[id] = loc;
        }
      }
    }
    final mergedRoutineLogs = mergedRoutineLogsMap.values.toList();

    var routineBonusXp = 0;
    for (final rLog in mergedRoutineLogs) {
      if (rLog.isDeleted) continue;
      routineBonusXp += rLog.xpEarned;
    }

    final initialTotalXp = habitCheckInXp + perfectDaysBonusXp + routineBonusXp;
    var currentProgression = GamificationEngine.calculateProgression(
      totalXp: initialTotalXp,
      longestActiveStreak: longestActiveStreak,
    );
    List<AchievementStatus> evaluatedAchievements = const [];
    var achievementsXp = 0;
    var finalTotalXp = initialTotalXp;

    for (int iter = 0; iter < 5; iter++) {
      final evalContext = EvaluationContext(
        habits: activeHabits,
        allLogs: activeLogs,
        categories: activeCategories,
        routines: mergedRoutines,
        routineLogs: mergedRoutineLogs,
        currentLevel: currentProgression.level,
        storedUnlocks: storedUnlocks,
        referenceDate: now,
        precomputedStreaks: streakByHabit,
      );
      evaluatedAchievements = AchievementEvaluator.evaluateAll(evalContext);

      final newAchievementsXp = evaluatedAchievements
          .where((a) => a.isUnlocked)
          .fold<int>(0, (sum, a) => sum + a.definition.xpReward);

      final newTotalXp = initialTotalXp + newAchievementsXp;
      final newProgression = GamificationEngine.calculateProgression(
        totalXp: newTotalXp,
        longestActiveStreak: longestActiveStreak,
        unlockedBadgesCount: evaluatedAchievements.where((a) => a.isUnlocked).length,
        totalBadgesCount: evaluatedAchievements.length,
      );

      if (newAchievementsXp == achievementsXp && newProgression.level == currentProgression.level) {
        achievementsXp = newAchievementsXp;
        finalTotalXp = newTotalXp;
        currentProgression = newProgression;
        break;
      }

      achievementsXp = newAchievementsXp;
      finalTotalXp = newTotalXp;
      currentProgression = newProgression;
    }

    final finalProgression = currentProgression;

    // Merge UserGamification (preserve max celebration level)
    final lastCelebratedLevel = max(
      local.gamification.lastCelebratedLevel,
      remote.gamification.lastCelebratedLevel,
    );
    final maxShieldsCapacity = max(
      local.gamification.maxShieldsCapacity,
      remote.gamification.maxShieldsCapacity,
    );
    final autoConsumeShields = local.gamification.autoConsumeShields && remote.gamification.autoConsumeShields;

    final mergedGamification = SyncUserGamification(
      totalXp: finalTotalXp,
      currentLevel: finalProgression.level,
      lastCelebratedLevel: max(lastCelebratedLevel, 1),
      maxShieldsCapacity: maxShieldsCapacity,
      autoConsumeShields: autoConsumeShields,
      updatedAt: now,
    );

    // Merge Achievements List (only genuinely unlocked achievements)
    final mergedAchievements = evaluatedAchievements
        .where((ea) => ea.isUnlocked)
        .map((ea) {
      final wasNotified = storedNotified[ea.definition.id] ?? false;
      return SyncAchievement(
        id: ea.definition.id,
        unlockedAt: ea.unlockedAt ?? now,
        progress: ea.currentProgress,
        notified: wasNotified,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    // 6. Preferences (LWW)
    final mergedPreferences = <String, dynamic>{
      ...local.preferences,
      ...remote.preferences,
    };

    final mergedPayload = SyncDataPayload(
      categories: mergedCategories,
      habits: mergedHabits,
      logs: mergedLogs,
      shields: mergedShields,
      routines: mergedRoutines,
      routineLogs: mergedRoutineLogs,
      gamification: mergedGamification,
      achievements: mergedAchievements,
      preferences: mergedPreferences,
    );

    final stats = MergeStats(
      habitsAdded: habitsAdded,
      habitsUpdated: habitsUpdated,
      habitsDeleted: habitsDeleted,
      logsMerged: logsMerged,
      shieldsMerged: shieldsMerged,
      categoriesAdded: categoriesAdded,
      categoriesUpdated: categoriesUpdated,
      totalXp: finalTotalXp,
      level: finalProgression.level,
    );

    return MergeResult(
      mergedPayload: mergedPayload,
      stats: stats,
    );
  }
}
