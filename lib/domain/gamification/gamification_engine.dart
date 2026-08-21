import 'dart:math';
import '../engines/streak_calculator.dart';
import '../models/habit.dart';
import '../models/habit_frequency_type.dart';
import '../models/habit_log.dart';
import '../models/habit_target_type.dart';
import '../models/habit_tier.dart';
import 'gamification_models.dart';
import 'player_title.dart';

class GamificationEngine {
  static const int perfectDayBonusXp = 50;
  static const int baseBooleanXp = 20;
  static const int baseNumericCompletionXp = 25;
  static const int baseTimerCompletionBonusXp = 10;
  static const int baseSlotCheckInXp = 10;
  static const int baseAllSlotsBonusXp = 15;

  // Elastic Goal Tier XP Constants
  static const int miniTierXp = 5;
  static const int baseTierXp = 20;
  static const int eliteTierXp = 35;

  /// Returns the base XP reward for a given elastic goal tier.
  static int tierBaseXp(HabitTier tier) {
    switch (tier) {
      case HabitTier.none:
        return 0;
      case HabitTier.mini:
        return miniTierXp;
      case HabitTier.base:
        return baseTierXp;
      case HabitTier.elite:
        return eliteTierXp;
    }
  }

  /// Calculates the streak multiplier based on active streak length:
  /// - < 7 days: 1.0x
  /// - 7..13 days: 1.25x
  /// - 14..29 days: 1.5x
  /// - 30+ days: 2.0x
  static double calculateStreakMultiplier(int streakDays) {
    if (streakDays >= 30) {
      return 2.0;
    } else if (streakDays >= 14) {
      return 1.5;
    } else if (streakDays >= 7) {
      return 1.25;
    } else {
      return 1.0;
    }
  }

  /// Total XP threshold to reach a given level using quadratic formula:
  /// T(L) = 25 * (L - 1)^2 + 75 * (L - 1)
  /// Level 1: 0 XP
  /// Level 2: 100 XP
  /// Level 3: 250 XP
  /// Level 4: 450 XP
  /// Level 5: 700 XP (Apprentice)
  /// Level 10: 2700 XP (Pathfinder)
  /// Level 20: 10450 XP (Grandmaster)
  static int xpThresholdForLevel(int level) {
    if (level <= 1) return 0;
    final n = level - 1;
    return 25 * n * n + 75 * n;
  }

  /// Resolves the PlayerProgression (level, title, progress fraction, thresholds) for total XP.
  static PlayerProgression calculateProgression({
    required int totalXp,
    int longestActiveStreak = 0,
    int unlockedBadgesCount = 0,
    int totalBadgesCount = 0,
  }) {
    final safeXp = max(0, totalXp);
    var level = 1;
    while (xpThresholdForLevel(level + 1) <= safeXp) {
      level++;
    }

    final currentLevelBase = xpThresholdForLevel(level);
    final nextLevelTarget = xpThresholdForLevel(level + 1);
    final levelXpSpan = (nextLevelTarget - currentLevelBase).toDouble();
    final currentProgressInLevel = (safeXp - currentLevelBase).toDouble();
    final progressFraction = levelXpSpan > 0.0
        ? (currentProgressInLevel / levelXpSpan).clamp(0.0, 1.0)
        : 1.0;

    final multiplier = calculateStreakMultiplier(longestActiveStreak);
    final title = PlayerTitle.fromLevel(level);

    return PlayerProgression(
      totalXp: safeXp,
      level: level,
      title: title,
      currentLevelBaseXp: currentLevelBase,
      nextLevelTargetXp: nextLevelTarget,
      progressFraction: progressFraction,
      activeStreakMultiplier: multiplier,
      longestActiveStreak: longestActiveStreak,
      unlockedBadgesCount: unlockedBadgesCount,
      totalBadgesCount: totalBadgesCount,
    );
  }

  /// Calculates base XP earned for a habit day's logs and completion state.
  static int calculateHabitDayBaseXp(
    Habit habit,
    List<HabitLog> logsOnDate,
    bool isCompleted,
  ) {
    if (logsOnDate.isEmpty && !isCompleted) return 0;

    final tier = StreakCalculator.resolveAchievedTier(habit, logsOnDate);

    // Elastic goals prioritize tiered XP scaling
    if (habit.hasElasticTiers) {
      switch (tier) {
        case HabitTier.elite:
          return eliteTierXp;
        case HabitTier.base:
          return baseTierXp;
        case HabitTier.mini:
          return miniTierXp;
        case HabitTier.none:
          return 0;
      }
    }

    // Check if an explicit tier was logged for a non-elastic habit
    if (tier == HabitTier.elite) {
      return eliteTierXp;
    } else if (tier == HabitTier.mini) {
      return miniTierXp;
    }

    switch (habit.targetType) {
      case HabitTargetType.boolean:
        switch (habit.frequencyType) {
          case HabitFrequencyType.subdayInterval:
          case HabitFrequencyType.timesPerDay:
            final completedSlots = logsOnDate
                .where((log) => log.completed)
                .map((log) => log.intervalIndex)
                .where((idx) => idx != null)
                .toSet()
                .length;
            final slotXp = completedSlots * baseSlotCheckInXp;
            final bonusXp = isCompleted ? baseAllSlotsBonusXp : 0;
            return slotXp + bonusXp;
          default:
            return isCompleted ? baseBooleanXp : 0;
        }

      case HabitTargetType.numeric:
        final target = habit.targetValue ?? 1.0;
        final totalValue = logsOnDate.fold<double>(
          0.0,
          (sum, log) => sum + (log.value ?? (log.completed ? target : 0.0)),
        );
        if (isCompleted) {
          return baseNumericCompletionXp;
        } else if (target > 0) {
          final ratio = (totalValue / target).clamp(0.0, 1.0);
          final calculated = (ratio * baseBooleanXp).toInt();
          return calculated >= (logsOnDate.isNotEmpty ? 5 : 0)
              ? calculated
              : (logsOnDate.isNotEmpty ? 5 : 0);
        } else {
          return 0;
        }

      case HabitTargetType.timer:
        final targetMinutes = habit.targetValue ?? 25.0;
        final totalMinutes = logsOnDate.fold<double>(
          0.0,
          (sum, log) {
            if (log.durationSeconds != null && log.durationSeconds! > 0) {
              return sum + (log.durationSeconds! / 60.0);
            } else {
              return sum + (log.value ?? (log.completed ? targetMinutes : 0.0));
            }
          },
        );
        final minuteXp = max(0, totalMinutes.toInt());
        final bonus = isCompleted ? baseTimerCompletionBonusXp : 0;
        return minuteXp + bonus;
    }
  }

  /// Applies streak multiplier to a base XP amount.
  static int applyMultiplier(int baseXp, double multiplier) {
    if (baseXp <= 0) return 0;
    return max(1, (baseXp * multiplier).round());
  }
}
