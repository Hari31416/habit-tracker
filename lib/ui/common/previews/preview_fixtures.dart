import '../../../domain/engines/shield_banking_engine.dart';
import '../../../domain/engines/streak_calculator.dart';
import '../../../domain/gamification/gamification_models.dart';
import '../../../domain/gamification/player_title.dart';
import '../../../domain/models/habit.dart';
import '../../../domain/models/habit_category.dart';
import '../../../domain/models/habit_frequency_type.dart';
import '../../../domain/models/habit_target_type.dart';
import '../../../domain/models/habit_with_progress.dart';

/// Centralized mock fixtures for widget previews and UI testing.
abstract final class PreviewFixtures {
  static Habit sampleHabit({
    String id = 'habit-1',
    String title = 'Morning Meditation',
    String? description = 'Mindfulness and breathing',
    HabitTargetType targetType = HabitTargetType.boolean,
    HabitFrequencyType frequencyType = HabitFrequencyType.daily,
    String color = '#3B82F6',
    String icon = 'self_improvement',
    double? targetValue,
    double? miniTargetValue,
    double? eliteTargetValue,
    String? unit,
    int? timesPerDay,
    bool pinned = false,
  }) {
    final now = DateTime.now();
    return Habit(
      id: id,
      title: title,
      description: description,
      color: color,
      icon: icon,
      frequencyType: frequencyType,
      targetType: targetType,
      targetValue: targetValue,
      miniTargetValue: miniTargetValue,
      eliteTargetValue: eliteTargetValue,
      unit: unit,
      timesPerDay: timesPerDay,
      pinned: pinned,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
    );
  }

  static Habit sampleHabitWithElasticTiers({
    String id = 'elastic-habit-1',
    String title = 'Read Book',
    double miniTarget = 5.0,
    double baseTarget = 25.0,
    double eliteTarget = 50.0,
    String unit = 'pages',
  }) {
    return sampleHabit(
      id: id,
      title: title,
      targetType: HabitTargetType.numeric,
      targetValue: baseTarget,
      miniTargetValue: miniTarget,
      eliteTargetValue: eliteTarget,
      unit: unit,
    );
  }

  static HabitCategory sampleCategory({
    String id = 'cat-1',
    String name = 'Mindfulness',
    String color = '#8B5CF6',
    String icon = 'spa',
  }) {
    return HabitCategory(
      id: id,
      name: name,
      color: color,
      icon: icon,
    );
  }

  static StreakResult sampleStreakResult({
    int currentStreak = 7,
    int bestStreak = 21,
    int completionRate30Days = 85,
    int totalCompletions = 42,
    int totalShieldedDays = 2,
  }) {
    return StreakResult(
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      completionRate30Days: completionRate30Days,
      totalCompletions: totalCompletions,
      totalShieldedDays: totalShieldedDays,
    );
  }

  static HabitWithProgress sampleHabitWithProgress({
    Habit? habit,
    HabitCategory? category,
    double currentValue = 0.0,
    bool isCompleted = false,
    bool isShielded = false,
    int currentStreak = 5,
    int longestStreak = 14,
  }) {
    final resolvedHabit = habit ?? sampleHabit();
    return HabitWithProgress(
      habit: resolvedHabit,
      category: category,
      currentValueOnDate: currentValue > 0 ? currentValue : (isCompleted ? 1.0 : 0.0),
      isCompletedOnDate: isCompleted,
      isShieldedOnDate: isShielded,
      streak: StreakResult(
        currentStreak: currentStreak,
        bestStreak: longestStreak,
        completionRate30Days: 80,
        totalCompletions: 30,
      ),
    );
  }

  static PlayerProgression sampleProgression({
    int level = 4,
    int totalXp = 1850,
    int baseLevelXp = 1500,
    int nextLevelXp = 2200,
    double progressFraction = 0.5,
    double multiplier = 1.5,
    int unlockedBadges = 6,
    int totalBadges = 16,
    PlayerTitle title = PlayerTitle.pathfinder,
  }) {
    return PlayerProgression(
      totalXp: totalXp,
      level: level,
      title: title,
      currentLevelBaseXp: baseLevelXp,
      nextLevelTargetXp: nextLevelXp,
      progressFraction: progressFraction,
      activeStreakMultiplier: multiplier,
      longestActiveStreak: 18,
      unlockedBadgesCount: unlockedBadges,
      totalBadgesCount: totalBadges,
    );
  }

  static ShieldBankState sampleShieldBankState({
    int availableShields = 2,
    int maxCapacity = 3,
    int totalEarned = 5,
    int usedShields = 3,
    int daysToNext = 3,
    double progress = 0.6,
    bool autoConsume = true,
  }) {
    return ShieldBankState(
      availableShields: availableShields,
      maxCapacity: maxCapacity,
      totalShieldsEarned: totalEarned,
      usedShieldsCount: usedShields,
      daysToNextShield: daysToNext,
      progressToNextShield: progress,
      autoConsumeEnabled: autoConsume,
    );
  }
}
