package com.productivity.habits.domain.gamification

import com.google.common.truth.Truth.assertThat
import com.productivity.habits.data.local.entity.HabitCategoryEntity
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitFrequencyType
import com.productivity.habits.data.local.entity.HabitLogEntity
import com.productivity.habits.data.local.entity.HabitTargetType
import org.junit.Test
import java.time.Instant
import java.time.LocalDate
import java.util.UUID

class AchievementEvaluatorTest {

    @Test
    fun evaluateAll_unlocksStreakAndVolumeAchievements() {
        val now = Instant.now()
        val refDate = LocalDate.parse("2026-08-17")
        val habit = HabitEntity(
            id = "habit-1",
            title = "Morning Meditation",
            color = "#0A7A64",
            frequencyType = HabitFrequencyType.DAILY,
            targetType = HabitTargetType.BOOLEAN,
            createdAt = now,
            updatedAt = now
        )

        // 7 consecutive completed days
        val logs = (0..6).map { offset ->
            val dateStr = refDate.minusDays(offset.toLong()).toString()
            HabitLogEntity(
                id = UUID.randomUUID().toString(),
                habitId = "habit-1",
                date = dateStr,
                timestamp = now,
                completed = true,
                createdAt = now,
                updatedAt = now
            )
        }

        val context = AchievementEvaluator.EvaluationContext(
            habits = listOf(habit),
            allLogs = logs,
            categories = emptyList(),
            currentLevel = 2,
            referenceDate = refDate
        )

        val results = AchievementEvaluator.evaluateAll(context)
        val streak3 = results.first { it.definition.id == "streak_3" }
        val streak7 = results.first { it.definition.id == "streak_7" }
        val streak14 = results.first { it.definition.id == "streak_14" }
        val vol1 = results.first { it.definition.id == "vol_1" }

        assertThat(streak3.isUnlocked).isTrue()
        assertThat(streak7.isUnlocked).isTrue()
        assertThat(streak14.isUnlocked).isFalse()
        assertThat(vol1.isUnlocked).isTrue()
    }

    @Test
    fun evaluateAll_detectsCategoryDiversityAndPerfectDays() {
        val now = Instant.now()
        val refDate = LocalDate.parse("2026-08-17")
        val catHealth = HabitCategoryEntity(id = "cat-health", name = "Health & Fitness", color = "#10B981")
        val catWork = HabitCategoryEntity(id = "cat-work", name = "Productivity", color = "#3B82F6")

        val habit1 = HabitEntity(
            id = "h1",
            title = "Run 5k",
            color = "#10B981",
            categoryId = "cat-health",
            frequencyType = HabitFrequencyType.DAILY,
            targetType = HabitTargetType.BOOLEAN,
            createdAt = now,
            updatedAt = now
        )
        val habit2 = HabitEntity(
            id = "h2",
            title = "Deep Work",
            color = "#3B82F6",
            categoryId = "cat-work",
            frequencyType = HabitFrequencyType.DAILY,
            targetType = HabitTargetType.TIMER,
            targetValue = 60.0,
            createdAt = now,
            updatedAt = now
        )

        val dateStr = refDate.toString()
        val logs = listOf(
            HabitLogEntity(
                id = UUID.randomUUID().toString(),
                habitId = "h1",
                date = dateStr,
                timestamp = now,
                completed = true,
                createdAt = now,
                updatedAt = now
            ),
            HabitLogEntity(
                id = UUID.randomUUID().toString(),
                habitId = "h2",
                date = dateStr,
                timestamp = now,
                completed = true,
                durationSeconds = 3600L, // 60 mins
                createdAt = now,
                updatedAt = now
            )
        )

        val context = AchievementEvaluator.EvaluationContext(
            habits = listOf(habit1, habit2),
            allLogs = logs,
            categories = listOf(catHealth, catWork),
            currentLevel = 5,
            referenceDate = refDate
        )

        val results = AchievementEvaluator.evaluateAll(context)
        val div2 = results.first { it.definition.id == "div_2_cats" }
        val perf1 = results.first { it.definition.id == "perf_1" }
        val focus60 = results.first { it.definition.id == "focus_60" }
        val mastery5 = results.first { it.definition.id == "mastery_lvl_5" }

        assertThat(div2.isUnlocked).isTrue()
        assertThat(perf1.isUnlocked).isTrue()
        assertThat(focus60.isUnlocked).isTrue()
        assertThat(mastery5.isUnlocked).isTrue()
    }
}
