package com.productivity.habits.domain.gamification

import com.google.common.truth.Truth.assertThat
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitFrequencyType
import com.productivity.habits.data.local.entity.HabitLogEntity
import com.productivity.habits.data.local.entity.HabitTargetType
import org.junit.Test
import java.time.Instant
import java.util.UUID

class GamificationEngineTest {

    @Test
    fun calculateStreakMultiplier_returnsCorrectMultiplierForStreakLengths() {
        assertThat(GamificationEngine.calculateStreakMultiplier(0)).isEqualTo(1.0)
        assertThat(GamificationEngine.calculateStreakMultiplier(6)).isEqualTo(1.0)
        assertThat(GamificationEngine.calculateStreakMultiplier(7)).isEqualTo(1.25)
        assertThat(GamificationEngine.calculateStreakMultiplier(13)).isEqualTo(1.25)
        assertThat(GamificationEngine.calculateStreakMultiplier(14)).isEqualTo(1.5)
        assertThat(GamificationEngine.calculateStreakMultiplier(29)).isEqualTo(1.5)
        assertThat(GamificationEngine.calculateStreakMultiplier(30)).isEqualTo(2.0)
        assertThat(GamificationEngine.calculateStreakMultiplier(100)).isEqualTo(2.0)
    }

    @Test
    fun xpThresholdForLevel_quadraticCurveProgression() {
        assertThat(GamificationEngine.xpThresholdForLevel(1)).isEqualTo(0L)
        assertThat(GamificationEngine.xpThresholdForLevel(2)).isEqualTo(100L)
        assertThat(GamificationEngine.xpThresholdForLevel(3)).isEqualTo(250L)
        assertThat(GamificationEngine.xpThresholdForLevel(4)).isEqualTo(450L)
        assertThat(GamificationEngine.xpThresholdForLevel(5)).isEqualTo(700L)
        assertThat(GamificationEngine.xpThresholdForLevel(10)).isEqualTo(2700L)
        assertThat(GamificationEngine.xpThresholdForLevel(20)).isEqualTo(10450L)
    }

    @Test
    fun calculateProgression_resolvesLevelTitlesAndProgressFractions() {
        // Level 1: 0 XP
        val prog1 = GamificationEngine.calculateProgression(totalXp = 0L)
        assertThat(prog1.level).isEqualTo(1)
        assertThat(prog1.title).isEqualTo(PlayerTitle.NOVICE)
        assertThat(prog1.currentLevelBaseXp).isEqualTo(0L)
        assertThat(prog1.nextLevelTargetXp).isEqualTo(100L)
        assertThat(prog1.progressFraction).isEqualTo(0.0f)

        // Level 1: 50 XP (halfway to Lv 2)
        val progHalf = GamificationEngine.calculateProgression(totalXp = 50L)
        assertThat(progHalf.level).isEqualTo(1)
        assertThat(progHalf.progressFraction).isEqualTo(0.5f)

        // Level 5: 700 XP (Apprentice)
        val prog5 = GamificationEngine.calculateProgression(totalXp = 700L, longestActiveStreak = 14)
        assertThat(prog5.level).isEqualTo(5)
        assertThat(prog5.title).isEqualTo(PlayerTitle.APPRENTICE)
        assertThat(prog5.activeStreakMultiplier).isEqualTo(1.5)

        // Level 10: 2700 XP (Pathfinder)
        val prog10 = GamificationEngine.calculateProgression(totalXp = 2700L, longestActiveStreak = 30)
        assertThat(prog10.level).isEqualTo(10)
        assertThat(prog10.title).isEqualTo(PlayerTitle.PATHFINDER)
        assertThat(prog10.activeStreakMultiplier).isEqualTo(2.0)

        // Level 20: 10450 XP (Grandmaster)
        val prog20 = GamificationEngine.calculateProgression(totalXp = 10450L)
        assertThat(prog20.level).isEqualTo(20)
        assertThat(prog20.title).isEqualTo(PlayerTitle.GRANDMASTER)
    }

    @Test
    fun calculateHabitDayBaseXp_booleanHabit() {
        val now = Instant.now()
        val habit = HabitEntity(
            id = "h1",
            title = "Drink Water",
            color = "#000000",
            frequencyType = HabitFrequencyType.DAILY,
            targetType = HabitTargetType.BOOLEAN,
            createdAt = now,
            updatedAt = now
        )
        val log = HabitLogEntity(
            id = UUID.randomUUID().toString(),
            habitId = "h1",
            date = "2026-08-17",
            timestamp = now,
            completed = true,
            createdAt = now,
            updatedAt = now
        )

        val xpCompleted = GamificationEngine.calculateHabitDayBaseXp(habit, listOf(log), isCompleted = true)
        assertThat(xpCompleted).isEqualTo(GamificationEngine.BASE_BOOLEAN_XP)

        val xpNotCompleted = GamificationEngine.calculateHabitDayBaseXp(habit, emptyList(), isCompleted = false)
        assertThat(xpNotCompleted).isEqualTo(0)
    }

    @Test
    fun calculateHabitDayBaseXp_timerHabit() {
        val now = Instant.now()
        val habit = HabitEntity(
            id = "h2",
            title = "Deep Work",
            color = "#000000",
            frequencyType = HabitFrequencyType.DAILY,
            targetType = HabitTargetType.TIMER,
            targetValue = 25.0,
            createdAt = now,
            updatedAt = now
        )
        val log = HabitLogEntity(
            id = UUID.randomUUID().toString(),
            habitId = "h2",
            date = "2026-08-17",
            timestamp = now,
            completed = true,
            durationSeconds = 1500L, // 25 minutes
            createdAt = now,
            updatedAt = now
        )

        val xp = GamificationEngine.calculateHabitDayBaseXp(habit, listOf(log), isCompleted = true)
        // 25 mins (25 XP) + 10 XP bonus
        assertThat(xp).isEqualTo(35)
    }

    @Test
    fun calculateHabitDayBaseXp_slotsHabit() {
        val now = Instant.now()
        val habit = HabitEntity(
            id = "h3",
            title = "Walks",
            color = "#000000",
            frequencyType = HabitFrequencyType.TIMES_PER_DAY,
            timesPerDay = 3,
            targetType = HabitTargetType.BOOLEAN,
            createdAt = now,
            updatedAt = now
        )
        val logs = (0 until 3).map { slot ->
            HabitLogEntity(
                id = UUID.randomUUID().toString(),
                habitId = "h3",
                date = "2026-08-17",
                timestamp = now,
                intervalIndex = slot,
                completed = true,
                createdAt = now,
                updatedAt = now
            )
        }

        val xp = GamificationEngine.calculateHabitDayBaseXp(habit, logs, isCompleted = true)
        // 3 slots * 10 XP + 15 XP bonus = 45 XP
        assertThat(xp).isEqualTo(45)
    }

    @Test
    fun applyMultiplier_scalesXpCorrectly() {
        assertThat(GamificationEngine.applyMultiplier(20, 1.0)).isEqualTo(20L)
        assertThat(GamificationEngine.applyMultiplier(20, 1.25)).isEqualTo(25L)
        assertThat(GamificationEngine.applyMultiplier(20, 1.5)).isEqualTo(30L)
        assertThat(GamificationEngine.applyMultiplier(20, 2.0)).isEqualTo(40L)
    }
}
