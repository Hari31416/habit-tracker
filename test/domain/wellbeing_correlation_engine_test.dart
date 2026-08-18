import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/engines/wellbeing_correlation_engine.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_log.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';

void main() {
  group('WellbeingCorrelationEngine Tests', () {
    final now = DateTime(2026, 8, 18);
    final testHabit = Habit(
      id: 'habit-1',
      title: 'Morning Meditation',
      color: '#4CAF50',
      icon: 'self_improvement',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      createdAt: now,
      updatedAt: now,
    );

    test('calculateCorrelation returns empty summary when no logs exist', () {
      final summary = WellbeingCorrelationEngine.calculateCorrelation(
        habits: [testHabit],
        logs: [],
        referenceDate: now,
        daysCount: 7,
      );

      expect(summary.totalReflectionsLogged, 0);
      expect(summary.avgEnergyOnCompletedDays, 0.0);
      expect(summary.avgEnergyOnMissedDays, 0.0);
      expect(summary.timelinePoints.length, 7);
    });

    test('calculateCorrelation correctly computes average energy on completed vs missed days', () {
      final logs = [
        // Day 1 (today: 2026-08-18): completed, energy 5, mood energized
        HabitLog(
          id: 'log-1',
          habitId: 'habit-1',
          date: '2026-08-18',
          timestamp: now,
          completed: true,
          energyLevel: 5,
          mood: 'energized',
          note: 'Felt amazing today',
          createdAt: now,
          updatedAt: now,
        ),
        // Day 2 (yesterday: 2026-08-17): completed, energy 4, mood happy
        HabitLog(
          id: 'log-2',
          habitId: 'habit-1',
          date: '2026-08-17',
          timestamp: now.subtract(const Duration(days: 1)),
          completed: true,
          energyLevel: 4,
          mood: 'happy',
          note: 'Good flow',
          createdAt: now,
          updatedAt: now,
        ),
        // Day 3 (2 days ago: 2026-08-16): missed (uncompleted), energy 2, mood tired
        HabitLog(
          id: 'log-3',
          habitId: 'habit-1',
          date: '2026-08-16',
          timestamp: now.subtract(const Duration(days: 2)),
          completed: false,
          energyLevel: 2,
          mood: 'tired',
          note: 'Woke up late',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final summary = WellbeingCorrelationEngine.calculateCorrelation(
        habits: [testHabit],
        logs: logs,
        referenceDate: now,
        daysCount: 3,
      );

      expect(summary.totalReflectionsLogged, 3);
      // Completed days: (5 + 4) / 2 = 4.5
      expect(summary.avgEnergyOnCompletedDays, 4.5);
      // Missed days: 2.0
      expect(summary.avgEnergyOnMissedDays, 2.0);
      // Boost: ((4.5 - 2.0) / 2.0) * 100 = 125%
      expect(summary.energyBoostPercentage, 125);
      // Mood counts
      expect(summary.moodCounts['energized'], 1);
      expect(summary.moodCounts['happy'], 1);
      expect(summary.moodCounts['tired'], 1);
    });
  });
}
