import 'dart:math';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/habit_shield.dart';
import 'streak_calculator.dart';

class ShieldBankState {
  final int availableShields;
  final int maxCapacity;
  final int totalShieldsEarned;
  final int usedShieldsCount;
  final int daysToNextShield;
  final double progressToNextShield;
  final bool autoConsumeEnabled;

  const ShieldBankState({
    required this.availableShields,
    required this.maxCapacity,
    required this.totalShieldsEarned,
    required this.usedShieldsCount,
    required this.daysToNextShield,
    required this.progressToNextShield,
    required this.autoConsumeEnabled,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShieldBankState &&
          runtimeType == other.runtimeType &&
          availableShields == other.availableShields &&
          maxCapacity == other.maxCapacity &&
          totalShieldsEarned == other.totalShieldsEarned &&
          usedShieldsCount == other.usedShieldsCount &&
          daysToNextShield == other.daysToNextShield &&
          progressToNextShield == other.progressToNextShield &&
          autoConsumeEnabled == other.autoConsumeEnabled;

  @override
  int get hashCode =>
      availableShields.hashCode ^
      maxCapacity.hashCode ^
      totalShieldsEarned.hashCode ^
      usedShieldsCount.hashCode ^
      daysToNextShield.hashCode ^
      progressToNextShield.hashCode ^
      autoConsumeEnabled.hashCode;

  @override
  String toString() =>
      'ShieldBankState(available: $availableShields/$maxCapacity, earned: $totalShieldsEarned, used: $usedShieldsCount, daysToNext: $daysToNextShield, autoConsume: $autoConsumeEnabled)';
}

class ShieldBankingEngine {
  static const int daysPerShield = 14;
  static const int defaultMaxCapacity = 3;
  static const int starterBonusShields = 1;

  static ShieldBankState calculateBankState({
    required List<Habit> habits,
    required List<HabitLog> logs,
    required List<HabitShield> shields,
    int maxCapacity = defaultMaxCapacity,
    bool autoConsumeEnabled = true,
    DateTime? referenceDate,
    Map<String, StreakResult>? precomputedStreaks,
  }) {
    final ref = referenceDate ?? DateTime.now();
    final activeHabits = habits.where((h) => !h.archived).toList();

    final logsByHabit = <String, List<HabitLog>>{};
    for (final log in logs) {
      logsByHabit.putIfAbsent(log.habitId, () => []).add(log);
    }

    final shieldsByHabit = <String, List<HabitShield>>{};
    for (final shield in shields) {
      shieldsByHabit.putIfAbsent(shield.habitId, () => []).add(shield);
    }

    var totalEarnedFromConsistency = 0;
    var maxStreakProgressDays = 0;

    for (final habit in activeHabits) {
      final habitLogs = logsByHabit[habit.id] ?? const [];
      final habitShields = shieldsByHabit[habit.id] ?? const [];
      final streak = precomputedStreaks?[habit.id] ??
          StreakCalculator.calculateStreak(
            habit,
            habitLogs,
            ref,
            habitShields,
          );

      final highestStreak = max(streak.currentStreak, streak.bestStreak);
      final earnedForHabit = highestStreak ~/ daysPerShield;
      totalEarnedFromConsistency += earnedForHabit;

      final currentCycleDays = streak.currentStreak % daysPerShield;
      if (currentCycleDays > maxStreakProgressDays ||
          (currentCycleDays == 0 && streak.currentStreak > 0)) {
        maxStreakProgressDays = currentCycleDays;
      }
    }

    final totalEarned = starterBonusShields + totalEarnedFromConsistency;
    final usedCount = shields.length;
    final netAvailable = max(0, totalEarned - usedCount);
    final availableShields = min(netAvailable, maxCapacity);

    final daysToNext = maxStreakProgressDays == 0
        ? daysPerShield
        : (daysPerShield - maxStreakProgressDays);
    final progressFraction = (maxStreakProgressDays / daysPerShield).clamp(0.0, 1.0);

    return ShieldBankState(
      availableShields: availableShields,
      maxCapacity: maxCapacity,
      totalShieldsEarned: totalEarned,
      usedShieldsCount: usedCount,
      daysToNextShield: daysToNext,
      progressToNextShield: progressFraction,
      autoConsumeEnabled: autoConsumeEnabled,
    );
  }
}
