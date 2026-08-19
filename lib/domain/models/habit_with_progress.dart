import '../engines/streak_calculator.dart';
import 'habit.dart';
import 'habit_category.dart';
import 'habit_log.dart';

class HabitWithProgress {
  final Habit habit;
  final HabitCategory? category;
  final List<HabitLog> logsForDate;
  final bool isCompletedOnDate;
  final bool isShieldedOnDate;
  final double currentValueOnDate;
  final int currentDurationSecondsOnDate;
  final StreakResult streak;

  const HabitWithProgress({
    required this.habit,
    this.category,
    this.logsForDate = const [],
    this.isCompletedOnDate = false,
    this.isShieldedOnDate = false,
    this.currentValueOnDate = 0.0,
    this.currentDurationSecondsOnDate = 0,
    this.streak = const StreakResult(
      currentStreak: 0,
      bestStreak: 0,
      completionRate30Days: 0,
      totalCompletions: 0,
    ),
  });

  HabitWithProgress copyWith({
    Habit? habit,
    HabitCategory? category,
    List<HabitLog>? logsForDate,
    bool? isCompletedOnDate,
    bool? isShieldedOnDate,
    double? currentValueOnDate,
    int? currentDurationSecondsOnDate,
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
          streak == other.streak;

  @override
  int get hashCode =>
      habit.hashCode ^
      category.hashCode ^
      isCompletedOnDate.hashCode ^
      isShieldedOnDate.hashCode ^
      currentValueOnDate.hashCode ^
      currentDurationSecondsOnDate.hashCode ^
      streak.hashCode;
}
