import '../engines/streak_calculator.dart';
import 'habit.dart';
import 'habit_category.dart';
import 'habit_log.dart';
import 'habit_tier.dart';

class HabitWithProgress {
  final Habit habit;
  final HabitCategory? category;
  final List<HabitLog> logsForDate;
  final bool isCompletedOnDate;
  final bool isShieldedOnDate;
  final double currentValueOnDate;
  final int currentDurationSecondsOnDate;
  final HabitTier achievedTier;
  final StreakResult streak;

  const HabitWithProgress({
    required this.habit,
    this.category,
    this.logsForDate = const [],
    this.isCompletedOnDate = false,
    this.isShieldedOnDate = false,
    this.currentValueOnDate = 0.0,
    this.currentDurationSecondsOnDate = 0,
    this.achievedTier = HabitTier.none,
    this.streak = const StreakResult(
      currentStreak: 0,
      bestStreak: 0,
      completionRate30Days: 0,
      totalCompletions: 0,
    ),
  });

  bool get isMiniAchieved => achievedTier.isAtLeast(HabitTier.mini);
  bool get isBaseAchieved => achievedTier.isAtLeast(HabitTier.base);
  bool get isEliteAchieved => achievedTier == HabitTier.elite;

  HabitWithProgress copyWith({
    Habit? habit,
    HabitCategory? category,
    List<HabitLog>? logsForDate,
    bool? isCompletedOnDate,
    bool? isShieldedOnDate,
    double? currentValueOnDate,
    int? currentDurationSecondsOnDate,
    HabitTier? achievedTier,
    StreakResult? streak,
  }) {
    return HabitWithProgress(
      habit: habit ?? this.habit,
      category: category ?? this.category,
      logsForDate: logsForDate ?? this.logsForDate,
      isCompletedOnDate: isCompletedOnDate ?? this.isCompletedOnDate,
      isShieldedOnDate: isShieldedOnDate ?? this.isShieldedOnDate,
      currentValueOnDate: currentValueOnDate ?? this.currentValueOnDate,
      currentDurationSecondsOnDate:
          currentDurationSecondsOnDate ?? this.currentDurationSecondsOnDate,
      achievedTier: achievedTier ?? this.achievedTier,
      streak: streak ?? this.streak,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitWithProgress &&
          runtimeType == other.runtimeType &&
          habit == other.habit &&
          category == other.category &&
          isCompletedOnDate == other.isCompletedOnDate &&
          isShieldedOnDate == other.isShieldedOnDate &&
          currentValueOnDate == other.currentValueOnDate &&
          currentDurationSecondsOnDate == other.currentDurationSecondsOnDate &&
          achievedTier == other.achievedTier &&
          streak == other.streak;

  @override
  int get hashCode =>
      habit.hashCode ^
      category.hashCode ^
      isCompletedOnDate.hashCode ^
      isShieldedOnDate.hashCode ^
      currentValueOnDate.hashCode ^
      currentDurationSecondsOnDate.hashCode ^
      achievedTier.hashCode ^
      streak.hashCode;
}
