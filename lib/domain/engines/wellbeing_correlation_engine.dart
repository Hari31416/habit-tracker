import '../models/habit.dart';
import '../models/habit_log.dart';
import 'streak_calculator.dart';

class WellbeingDayDataPoint {
  final DateTime date;
  final String dateString;
  final bool habitCompleted;
  final int? energyLevel; // 1-5
  final String? mood;
  final String? note;

  const WellbeingDayDataPoint({
    required this.date,
    required this.dateString,
    required this.habitCompleted,
    this.energyLevel,
    this.mood,
    this.note,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WellbeingDayDataPoint &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          dateString == other.dateString &&
          habitCompleted == other.habitCompleted &&
          energyLevel == other.energyLevel &&
          mood == other.mood &&
          note == other.note;

  @override
  int get hashCode =>
      date.hashCode ^
      dateString.hashCode ^
      habitCompleted.hashCode ^
      energyLevel.hashCode ^
      mood.hashCode ^
      note.hashCode;
}

class WellbeingSummary {
  final double avgEnergyOnCompletedDays;
  final double avgEnergyOnMissedDays;
  final double overallAvgEnergy;
  final int totalReflectionsLogged;
  final int energyBoostPercentage; // e.g. +35%
  final Map<String, int> moodCounts;
  final List<WellbeingDayDataPoint> timelinePoints;

  const WellbeingSummary({
    required this.avgEnergyOnCompletedDays,
    required this.avgEnergyOnMissedDays,
    required this.overallAvgEnergy,
    required this.totalReflectionsLogged,
    required this.energyBoostPercentage,
    required this.moodCounts,
    required this.timelinePoints,
  });

  static const WellbeingSummary empty = WellbeingSummary(
    avgEnergyOnCompletedDays: 0.0,
    avgEnergyOnMissedDays: 0.0,
    overallAvgEnergy: 0.0,
    totalReflectionsLogged: 0,
    energyBoostPercentage: 0,
    moodCounts: {},
    timelinePoints: [],
  );
}

class WellbeingCorrelationEngine {
  /// Computes wellbeing correlation metrics across all habits or for a specific habit over [daysCount] (default 30 days).
  static WellbeingSummary calculateCorrelation({
    required List<Habit> habits,
    required List<HabitLog> logs,
    DateTime? referenceDate,
    int daysCount = 30,
  }) {
    final today = referenceDate ?? DateTime.now();
    final cleanToday = DateTime(today.year, today.month, today.day);

    final logsByDate = <String, List<HabitLog>>{};
    for (final log in logs) {
      logsByDate.putIfAbsent(log.date, () => []).add(log);
    }

    final logsByHabit = <String, List<HabitLog>>{};
    for (final log in logs) {
      logsByHabit.putIfAbsent(log.habitId, () => []).add(log);
    }

    final moodCounts = <String, int>{};
    final completedDayEnergies = <int>[];
    final missedDayEnergies = <int>[];
    final allEnergies = <int>[];
    final timelinePoints = <WellbeingDayDataPoint>[];
    int totalReflections = 0;

    for (int i = 0; i < daysCount; i++) {
      final date = cleanToday.subtract(Duration(days: i));
      final dateStr = StreakCalculator.dateFormatter.format(date);
      final dayLogs = logsByDate[dateStr] ?? const [];

      // Check if habits scheduled for this day were completed
      bool anyHabitScheduled = false;
      bool allScheduledCompleted = true;
      int completedHabitCount = 0;

      for (final habit in habits) {
        if (StreakCalculator.isHabitScheduledOnDate(habit, date)) {
          anyHabitScheduled = true;
          final hLogs = (logsByHabit[habit.id] ?? const [])
              .where((l) => l.date == dateStr)
              .toList();
          if (StreakCalculator.isHabitCompletedOnDate(habit, hLogs)) {
            completedHabitCount++;
          } else {
            allScheduledCompleted = false;
          }
        }
      }

      final isCompletedDay = anyHabitScheduled
          ? (allScheduledCompleted && completedHabitCount > 0)
          : dayLogs.any((l) => l.completed);

      // Find best reflection (with energyLevel, mood, or note) for this day
      int? dayEnergy;
      String? dayMood;
      String? dayNote;

      for (final l in dayLogs) {
        if (l.energyLevel != null && l.energyLevel! > 0) {
          dayEnergy = l.energyLevel;
        }
        if (l.mood != null && l.mood!.trim().isNotEmpty) {
          dayMood = l.mood;
        }
        if (l.note != null && l.note!.trim().isNotEmpty) {
          dayNote = l.note;
        }
      }

      if (dayEnergy != null || dayMood != null || dayNote != null) {
        totalReflections++;
      }

      if (dayMood != null) {
        moodCounts[dayMood] = (moodCounts[dayMood] ?? 0) + 1;
      }

      if (dayEnergy != null) {
        allEnergies.add(dayEnergy);
        if (isCompletedDay) {
          completedDayEnergies.add(dayEnergy);
        } else {
          missedDayEnergies.add(dayEnergy);
        }
      }

      timelinePoints.add(WellbeingDayDataPoint(
        date: date,
        dateString: dateStr,
        habitCompleted: isCompletedDay,
        energyLevel: dayEnergy,
        mood: dayMood,
        note: dayNote,
      ));
    }

    final double avgCompleted = completedDayEnergies.isNotEmpty
        ? completedDayEnergies.reduce((a, b) => a + b) / completedDayEnergies.length
        : 0.0;

    final double avgMissed = missedDayEnergies.isNotEmpty
        ? missedDayEnergies.reduce((a, b) => a + b) / missedDayEnergies.length
        : 0.0;

    final double overallAvg = allEnergies.isNotEmpty
        ? allEnergies.reduce((a, b) => a + b) / allEnergies.length
        : 0.0;

    int energyBoost = 0;
    if (avgMissed > 0 && avgCompleted > 0) {
      energyBoost = (((avgCompleted - avgMissed) / avgMissed) * 100).round();
    } else if (avgCompleted > 0 && avgMissed == 0) {
      energyBoost = 0;
    }

    return WellbeingSummary(
      avgEnergyOnCompletedDays: avgCompleted,
      avgEnergyOnMissedDays: avgMissed,
      overallAvgEnergy: overallAvg,
      totalReflectionsLogged: totalReflections,
      energyBoostPercentage: energyBoost,
      moodCounts: moodCounts,
      timelinePoints: timelinePoints,
    );
  }
}
