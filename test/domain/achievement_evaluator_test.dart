import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/gamification/achievement_evaluator.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_category.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_log.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

void main() {
  final formatter = DateFormat('yyyy-MM-dd');
  const uuid = Uuid();

  test('evaluateAll_unlocksStreakAndVolumeAchievements', () {
    final now = DateTime.now().toUtc();
    final refDate = DateTime.parse('2026-08-17');
    final habit = Habit(
      id: 'habit-1',
      title: 'Morning Meditation',
      color: '#0A7A64',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      createdAt: now,
      updatedAt: now,
    );

    // 7 consecutive completed days
    final logs = List.generate(7, (offset) {
      final dateStr = formatter.format(refDate.subtract(Duration(days: offset)));
      return HabitLog(
        id: uuid.v4(),
        habitId: 'habit-1',
        date: dateStr,
        timestamp: now,
        completed: true,
        createdAt: now,
        updatedAt: now,
      );
    });

    final context = EvaluationContext(
      habits: [habit],
      allLogs: logs,
      categories: const [],
      currentLevel: 2,
      referenceDate: refDate,
    );

    final results = AchievementEvaluator.evaluateAll(context);
    final streak3 = results.firstWhere((a) => a.definition.id == 'streak_3');
    final streak7 = results.firstWhere((a) => a.definition.id == 'streak_7');
    final streak14 = results.firstWhere((a) => a.definition.id == 'streak_14');
    final vol1 = results.firstWhere((a) => a.definition.id == 'vol_1');

    expect(streak3.isUnlocked, isTrue);
    expect(streak7.isUnlocked, isTrue);
    expect(streak14.isUnlocked, isFalse);
    expect(vol1.isUnlocked, isTrue);
  });

  test('evaluateAll_detectsCategoryDiversityAndPerfectDays', () {
    final now = DateTime.now().toUtc();
    final refDate = DateTime.parse('2026-08-17');
    const catHealth = HabitCategory(id: 'cat-health', name: 'Health & Fitness', color: '#10B981');
    const catWork = HabitCategory(id: 'cat-work', name: 'Productivity', color: '#3B82F6');

    final habit1 = Habit(
      id: 'h1',
      title: 'Run 5k',
      color: '#10B981',
      categoryId: 'cat-health',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      createdAt: now,
      updatedAt: now,
    );
    final habit2 = Habit(
      id: 'h2',
      title: 'Deep Work',
      color: '#3B82F6',
      categoryId: 'cat-work',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.timer,
      targetValue: 60.0,
      createdAt: now,
      updatedAt: now,
    );

    final dateStr = formatter.format(refDate);
    final logs = [
      HabitLog(
        id: uuid.v4(),
        habitId: 'h1',
        date: dateStr,
        timestamp: now,
        completed: true,
        createdAt: now,
        updatedAt: now,
      ),
      HabitLog(
        id: uuid.v4(),
        habitId: 'h2',
        date: dateStr,
        timestamp: now,
        completed: true,
        durationSeconds: 3600, // 60 mins
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final context = EvaluationContext(
      habits: [habit1, habit2],
      allLogs: logs,
      categories: const [catHealth, catWork],
      currentLevel: 5,
      referenceDate: refDate,
    );

    final results = AchievementEvaluator.evaluateAll(context);
    final div2 = results.firstWhere((a) => a.definition.id == 'div_2_cats');
    final perf1 = results.firstWhere((a) => a.definition.id == 'perf_1');
    final focus60 = results.firstWhere((a) => a.definition.id == 'focus_60');
    final mastery5 = results.firstWhere((a) => a.definition.id == 'mastery_lvl_5');

    expect(div2.isUnlocked, isTrue);
    expect(perf1.isUnlocked, isTrue);
    expect(focus60.isUnlocked, isTrue);
    expect(mastery5.isUnlocked, isTrue);
  });
}
