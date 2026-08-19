import 'dart:math';
import 'package:intl/intl.dart';
import '../engines/streak_calculator.dart';
import '../models/habit.dart';
import '../models/habit_category.dart';
import '../models/habit_log.dart';
import '../models/habit_target_type.dart';
import 'achievement_definitions.dart';
import 'gamification_models.dart';

class EvaluationContext {
  final List<Habit> habits;
  final List<HabitLog> allLogs;
  final List<HabitCategory> categories;
  final int currentLevel;
  final Map<String, DateTime> storedUnlocks;
  final DateTime referenceDate;
  final Map<String, StreakResult>? precomputedStreaks;

  EvaluationContext({
    required this.habits,
    required this.allLogs,
    required this.categories,
    this.currentLevel = 1,
    this.storedUnlocks = const {},
    DateTime? referenceDate,
    this.precomputedStreaks,
  }) : referenceDate = referenceDate ?? DateTime.now();
}

class AchievementEvaluator {
  static final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');

  static List<AchievementStatus> evaluateAll(EvaluationContext context) {
    final habitsMap = {for (var h in context.habits) h.id: h};
    final categoryMap = {for (var c in context.categories) c.id: c};
    final logsByHabit = <String, List<HabitLog>>{};
    final logsByDate = <String, List<HabitLog>>{};
    final logsByHabitDate = <String, Map<String, List<HabitLog>>>{};

    for (final log in context.allLogs) {
      logsByHabit.putIfAbsent(log.habitId, () => []).add(log);
      logsByDate.putIfAbsent(log.date, () => []).add(log);
      logsByHabitDate
          .putIfAbsent(log.habitId, () => {})
          .putIfAbsent(log.date, () => [])
          .add(log);
    }

    // 1. Streak calculations
    var maxStreak = 0;
    for (final habit in context.habits) {
      final streak = context.precomputedStreaks?[habit.id] ??
          StreakCalculator.calculateStreak(
            habit,
            logsByHabit[habit.id] ?? const [],
            context.referenceDate,
          );
      maxStreak = max(maxStreak, max(streak.currentStreak, streak.bestStreak));
    }

    // 2. Volume calculations (total day-level completions)
    var totalCompletions = 0;
    var totalFocusMinutes = 0;
    final completedCategoryIds = <String>{};
    final categoryCompletions = <String, int>{}; // categoryName keyword -> count

    for (final log in context.allLogs) {
      if (log.durationSeconds != null && log.durationSeconds! > 0) {
        totalFocusMinutes += (log.durationSeconds! ~/ 60);
      } else if (log.value != null && habitsMap[log.habitId]?.targetType == HabitTargetType.timer) {
        totalFocusMinutes += log.value!.toInt();
      }
    }

    for (final habit in context.habits) {
      final habitLogsByDate = logsByHabitDate[habit.id] ?? const {};
      final cat = habit.categoryId != null ? categoryMap[habit.categoryId] : null;

      for (final dayLogs in habitLogsByDate.values) {
        if (StreakCalculator.isHabitCompletedOnDate(habit, dayLogs)) {
          totalCompletions++;
          if (habit.categoryId != null) {
            completedCategoryIds.add(habit.categoryId!);
          }
          if (cat != null) {
            final catNameLower = cat.name.toLowerCase();
            final String key;
            if (catNameLower.contains('health') || catNameLower.contains('fitness')) {
              key = 'health';
            } else if (catNameLower.contains('work') ||
                catNameLower.contains('productivity') ||
                catNameLower.contains('study')) {
              key = 'productivity';
            } else if (catNameLower.contains('mind') ||
                catNameLower.contains('meditat') ||
                catNameLower.contains('wellbeing')) {
              key = 'mind';
            } else {
              key = catNameLower;
            }
            categoryCompletions[key] = (categoryCompletions[key] ?? 0) + 1;
          }
        }
      }
    }

    // 3. Perfect Days calculation using lexicographical ISO date sorting
    final allDateStrings = logsByDate.keys.toList()..sort();

    var totalPerfectDays = 0;
    var maxConsecutivePerfectDays = 0;
    var currentConsecutivePerfect = 0;
    DateTime? prevPerfectDate;

    for (final dateStr in allDateStrings) {
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;

      final scheduledHabits = context.habits.where((habit) {
        return !habit.archived && StreakCalculator.isHabitScheduledOnDate(habit, date);
      }).toList();

      if (scheduledHabits.isNotEmpty) {
        final allScheduledCompleted = scheduledHabits.every((habit) {
          final dayLogs = logsByHabitDate[habit.id]?[dateStr] ?? const [];
          return StreakCalculator.isHabitCompletedOnDate(habit, dayLogs);
        });

        if (allScheduledCompleted) {
          totalPerfectDays++;
          if (prevPerfectDate != null &&
              date.difference(prevPerfectDate).inDays == 1) {
            currentConsecutivePerfect++;
          } else {
            currentConsecutivePerfect = 1;
          }
          if (currentConsecutivePerfect > maxConsecutivePerfectDays) {
            maxConsecutivePerfectDays = currentConsecutivePerfect;
          }
          prevPerfectDate = date;
        }
      }
    }

    // 4. Map each definition to AchievementStatus
    return AchievementDefinitions.allAchievements.map((def) {
      int progress;
      switch (def.id) {
        // Streak
        case 'streak_3':
        case 'streak_7':
        case 'streak_14':
        case 'streak_21':
        case 'streak_30':
        case 'streak_100':
          progress = maxStreak;
          break;

        // Volume
        case 'vol_1':
        case 'vol_10':
        case 'vol_50':
        case 'vol_100':
        case 'vol_500':
        case 'vol_1000':
          progress = totalCompletions;
          break;

        // Diversity
        case 'div_2_cats':
        case 'div_3_cats':
        case 'div_5_cats':
          progress = completedCategoryIds.length;
          break;
        case 'div_health_20':
          progress = categoryCompletions['health'] ?? 0;
          break;
        case 'div_prod_20':
          progress = categoryCompletions['productivity'] ?? 0;
          break;
        case 'div_mind_20':
          progress = categoryCompletions['mind'] ?? 0;
          break;

        // Perfect Days
        case 'perf_1':
        case 'perf_3':
        case 'perf_30':
          progress = totalPerfectDays;
          break;
        case 'perf_7':
          progress = maxConsecutivePerfectDays;
          break;

        // Focus
        case 'focus_60':
        case 'focus_300':
        case 'focus_1000':
          progress = totalFocusMinutes;
          break;

        // Mastery
        case 'mastery_lvl_5':
        case 'mastery_lvl_10':
        case 'mastery_lvl_20':
          progress = context.currentLevel;
          break;

        default:
          progress = 0;
      }

      final target = def.targetValue;
      final isUnlocked = progress >= target || context.storedUnlocks.containsKey(def.id);
      final currentProgress = min(progress, target);
      final fraction = target > 0 ? (currentProgress / target).clamp(0.0, 1.0) : 1.0;

      return AchievementStatus(
        definition: def,
        isUnlocked: isUnlocked,
        currentProgress: currentProgress,
        progressFraction: fraction,
        unlockedAt: context.storedUnlocks[def.id] ?? (isUnlocked ? DateTime.now() : null),
      );
    }).toList();
  }
}
