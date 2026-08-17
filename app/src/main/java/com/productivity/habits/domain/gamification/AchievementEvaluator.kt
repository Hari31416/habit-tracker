package com.productivity.habits.domain.gamification

import com.productivity.habits.data.local.entity.HabitCategoryEntity
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitLogEntity
import com.productivity.habits.data.local.entity.HabitTargetType
import com.productivity.habits.domain.engine.StreakCalculator
import com.productivity.habits.domain.engine.StreakResult
import java.time.Instant
import java.time.LocalDate
import java.time.format.DateTimeFormatter

object AchievementEvaluator {

    private val DATE_FORMATTER: DateTimeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")

    data class EvaluationContext(
        val habits: List<HabitEntity>,
        val allLogs: List<HabitLogEntity>,
        val categories: List<HabitCategoryEntity>,
        val currentLevel: Int = 1,
        val storedUnlocks: Map<String, Instant> = emptyMap(),
        val referenceDate: LocalDate = LocalDate.now()
    )

    fun evaluateAll(context: EvaluationContext): List<AchievementStatus> {
        val habitsMap = context.habits.associateBy { it.id }
        val categoryMap = context.categories.associateBy { it.id }
        val logsByHabit = context.allLogs.groupBy { it.habitId }
        val logsByDate = context.allLogs.groupBy { it.date }

        // 1. Streak calculations
        val streaks = context.habits.map { habit ->
            val logs = logsByHabit[habit.id] ?: emptyList()
            StreakCalculator.calculateStreak(habit, logs, context.referenceDate)
        }
        val maxStreak = streaks.maxOfOrNull { maxOf(it.currentStreak, it.bestStreak) } ?: 0

        // 2. Volume calculations (total day-level completions)
        var totalCompletions = 0
        var totalFocusMinutes = 0
        val completedCategoryIds = mutableSetOf<String>()
        val categoryCompletions = mutableMapOf<String, Int>() // categoryName keyword -> count

        for (log in context.allLogs) {
            if (log.durationSeconds != null && log.durationSeconds > 0) {
                totalFocusMinutes += (log.durationSeconds / 60).toInt()
            } else if (log.value != null && habitsMap[log.habitId]?.targetType == HabitTargetType.TIMER) {
                totalFocusMinutes += log.value.toInt()
            }
        }

        for (habit in context.habits) {
            val logsForHabit = logsByHabit[habit.id] ?: emptyList()
            val habitLogsByDate = logsForHabit.groupBy { it.date }
            val cat = habit.categoryId?.let { categoryMap[it] }

            for ((_, dayLogs) in habitLogsByDate) {
                if (StreakCalculator.isHabitCompletedOnDate(habit, dayLogs)) {
                    totalCompletions++
                    if (habit.categoryId != null) {
                        completedCategoryIds.add(habit.categoryId)
                    }
                    if (cat != null) {
                        val catNameLower = cat.name.lowercase()
                        val key = when {
                            catNameLower.contains("health") || catNameLower.contains("fitness") -> "health"
                            catNameLower.contains("work") || catNameLower.contains("productivity") || catNameLower.contains("study") -> "productivity"
                            catNameLower.contains("mind") || catNameLower.contains("meditat") || catNameLower.contains("wellbeing") -> "mind"
                            else -> catNameLower
                        }
                        categoryCompletions[key] = (categoryCompletions[key] ?: 0) + 1
                    }
                }
            }
        }

        // 3. Perfect Days calculation
        val allDates = logsByDate.keys.mapNotNull {
            try { LocalDate.parse(it, DATE_FORMATTER) } catch (e: Exception) { null }
        }.sorted()

        var totalPerfectDays = 0
        var maxConsecutivePerfectDays = 0
        var currentConsecutivePerfect = 0
        var prevPerfectDate: LocalDate? = null

        for (date in allDates) {
            val scheduledHabits = context.habits.filter { habit ->
                !habit.archived && StreakCalculator.isHabitScheduledOnDate(habit, date)
            }
            if (scheduledHabits.isNotEmpty()) {
                val dateStr = date.format(DATE_FORMATTER)
                val allScheduledCompleted = scheduledHabits.all { habit ->
                    val dayLogs = (logsByHabit[habit.id] ?: emptyList()).filter { it.date == dateStr }
                    StreakCalculator.isHabitCompletedOnDate(habit, dayLogs)
                }
                if (allScheduledCompleted) {
                    totalPerfectDays++
                    if (prevPerfectDate != null && prevPerfectDate.plusDays(1) == date) {
                        currentConsecutivePerfect++
                    } else {
                        currentConsecutivePerfect = 1
                    }
                    if (currentConsecutivePerfect > maxConsecutivePerfectDays) {
                        maxConsecutivePerfectDays = currentConsecutivePerfect
                    }
                    prevPerfectDate = date
                }
            }
        }

        // 4. Map each definition to AchievementStatus
        return AchievementDefinitions.ALL_ACHIEVEMENTS.map { def ->
            val progress = when (def.id) {
                // Streak
                "streak_3", "streak_7", "streak_14", "streak_21", "streak_30", "streak_100" -> maxStreak

                // Volume
                "vol_1", "vol_10", "vol_50", "vol_100", "vol_500", "vol_1000" -> totalCompletions

                // Diversity
                "div_2_cats", "div_3_cats", "div_5_cats" -> completedCategoryIds.size
                "div_health_20" -> categoryCompletions["health"] ?: 0
                "div_prod_20" -> categoryCompletions["productivity"] ?: 0
                "div_mind_20" -> categoryCompletions["mind"] ?: 0

                // Perfect Days
                "perf_1", "perf_3", "perf_30" -> totalPerfectDays
                "perf_7" -> maxConsecutivePerfectDays

                // Focus
                "focus_60", "focus_300", "focus_1000" -> totalFocusMinutes

                // Mastery
                "mastery_lvl_5", "mastery_lvl_10", "mastery_lvl_20" -> context.currentLevel

                else -> 0
            }

            val target = def.targetValue
            val isUnlocked = progress >= target || context.storedUnlocks.containsKey(def.id)
            val currentProgress = minOf(progress, target)
            val fraction = if (target > 0) (currentProgress.toFloat() / target.toFloat()).coerceIn(0.0f, 1.0f) else 1.0f

            AchievementStatus(
                definition = def,
                isUnlocked = isUnlocked,
                currentProgress = currentProgress,
                progressFraction = fraction,
                unlockedAt = context.storedUnlocks[def.id] ?: if (isUnlocked) Instant.now() else null
            )
        }
    }
}
