package com.productivity.habits.domain.engine

import com.google.common.truth.Truth.assertThat
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitFrequencyType
import com.productivity.habits.data.local.entity.HabitLogEntity
import com.productivity.habits.data.local.entity.HabitTargetType
import org.junit.Test
import java.time.Instant
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.UUID

class StreakCalculatorTest {

    private val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")

    private fun createHabit(
        id: String = "test-habit-1",
        title: String = "Daily Reading",
        frequencyType: HabitFrequencyType = HabitFrequencyType.DAILY,
        targetType: HabitTargetType = HabitTargetType.BOOLEAN,
        targetDaysOfWeek: List<Int>? = null,
        targetCountPerWeek: Int? = null,
        targetValue: Double? = null,
        timesPerDay: Int? = null
    ): HabitEntity {
        val now = Instant.now()
        return HabitEntity(
            id = id,
            title = title,
            color = "#10b981",
            frequencyType = frequencyType,
            targetType = targetType,
            targetDaysOfWeek = targetDaysOfWeek,
            targetCountPerWeek = targetCountPerWeek,
            targetValue = targetValue,
            timesPerDay = timesPerDay,
            createdAt = now,
            updatedAt = now
        )
    }

    private fun createLog(
        habitId: String,
        date: LocalDate,
        completed: Boolean = true,
        value: Double? = null,
        durationSeconds: Long? = null,
        intervalIndex: Int? = null
    ): HabitLogEntity {
        val now = Instant.now()
        return HabitLogEntity(
            id = UUID.randomUUID().toString(),
            habitId = habitId,
            date = date.format(formatter),
            timestamp = now,
            completed = completed,
            value = value,
            durationSeconds = durationSeconds,
            intervalIndex = intervalIndex,
            createdAt = now,
            updatedAt = now
        )
    }

    @Test
    fun calculateStreak_dailyHabit_consecutiveDays_returnsCorrectStreak() {
        val habit = createHabit()
        val today = LocalDate.of(2026, 8, 17) // Monday
        val logs = listOf(
            createLog(habit.id, today),
            createLog(habit.id, today.minusDays(1)),
            createLog(habit.id, today.minusDays(2)),
            createLog(habit.id, today.minusDays(3)),
            createLog(habit.id, today.minusDays(4))
        )

        val result = StreakCalculator.calculateStreak(habit, logs, today)

        assertThat(result.currentStreak).isEqualTo(5)
        assertThat(result.bestStreak).isEqualTo(5)
        assertThat(result.totalCompletions).isEqualTo(5)
    }

    @Test
    fun calculateStreak_dailyHabit_todayUnlogged_preservesStreakFromYesterday() {
        val habit = createHabit()
        val today = LocalDate.of(2026, 8, 17)
        val logs = listOf(
            // Today is not logged yet
            createLog(habit.id, today.minusDays(1)),
            createLog(habit.id, today.minusDays(2)),
            createLog(habit.id, today.minusDays(3))
        )

        val result = StreakCalculator.calculateStreak(habit, logs, today)

        // Current streak should still be 3 because today is not over yet
        assertThat(result.currentStreak).isEqualTo(3)
        assertThat(result.bestStreak).isEqualTo(3)
    }

    @Test
    fun calculateStreak_dailyHabit_gapYesterday_resetsCurrentStreak() {
        val habit = createHabit()
        val today = LocalDate.of(2026, 8, 17)
        val logs = listOf(
            createLog(habit.id, today),
            // Yesterday (minusDays(1)) is missing!
            createLog(habit.id, today.minusDays(2)),
            createLog(habit.id, today.minusDays(3)),
            createLog(habit.id, today.minusDays(4))
        )

        val result = StreakCalculator.calculateStreak(habit, logs, today)

        assertThat(result.currentStreak).isEqualTo(1)
        assertThat(result.bestStreak).isEqualTo(3)
    }

    @Test
    fun calculateStreak_customDays_skipsUnscheduledDaysWithoutBreakingStreak() {
        // Mon (1), Wed (3), Fri (5)
        val habit = createHabit(
            frequencyType = HabitFrequencyType.CUSTOM_DAYS,
            targetDaysOfWeek = listOf(1, 3, 5)
        )
        val monday = LocalDate.of(2026, 8, 17) // Monday
        val friday = monday.minusDays(3) // Friday 2026-08-14
        val wednesday = monday.minusDays(5) // Wednesday 2026-08-12

        val logs = listOf(
            createLog(habit.id, monday),
            createLog(habit.id, friday),
            createLog(habit.id, wednesday)
        )

        val result = StreakCalculator.calculateStreak(habit, logs, monday)

        assertThat(result.currentStreak).isEqualTo(3)
        assertThat(result.bestStreak).isEqualTo(3)
    }

    @Test
    fun calculateWeeklyStreak_canonicalIsoWeeks_streakInWeeks() {
        // Target: 3 times per week
        val habit = createHabit(
            frequencyType = HabitFrequencyType.WEEKLY,
            targetCountPerWeek = 3
        )

        // Today is Monday 2026-08-17 (start of current week)
        val refDate = LocalDate.of(2026, 8, 17)

        // Current week (starting Aug 17): 3 completions on Mon, Tue, Wed
        val currentWeekLogs = listOf(
            createLog(habit.id, LocalDate.of(2026, 8, 17)),
            createLog(habit.id, LocalDate.of(2026, 8, 18)),
            createLog(habit.id, LocalDate.of(2026, 8, 19))
        )

        // Previous week 1 (Aug 10 - Aug 16): 3 completions
        val prevWeek1Logs = listOf(
            createLog(habit.id, LocalDate.of(2026, 8, 10)),
            createLog(habit.id, LocalDate.of(2026, 8, 12)),
            createLog(habit.id, LocalDate.of(2026, 8, 14))
        )

        // Previous week 2 (Aug 03 - Aug 09): 3 completions
        val prevWeek2Logs = listOf(
            createLog(habit.id, LocalDate.of(2026, 8, 4)),
            createLog(habit.id, LocalDate.of(2026, 8, 5)),
            createLog(habit.id, LocalDate.of(2026, 8, 6))
        )

        // Previous week 3 (Jul 27 - Aug 02): only 2 completions (unmet!)
        val prevWeek3Logs = listOf(
            createLog(habit.id, LocalDate.of(2026, 7, 28)),
            createLog(habit.id, LocalDate.of(2026, 7, 30))
        )

        val allLogs = currentWeekLogs + prevWeek1Logs + prevWeek2Logs + prevWeek3Logs

        val result = StreakCalculator.calculateStreak(habit, allLogs, refDate)

        // Streak unit is weeks: current week + prev week 1 + prev week 2 = 3 consecutive met weeks
        assertThat(result.currentStreak).isEqualTo(3)
        assertThat(result.bestStreak).isEqualTo(3)
        // Day level completions total = 3 + 3 + 3 + 2 = 11
        assertThat(result.totalCompletions).isEqualTo(11)
    }

    @Test
    fun calculateWeeklyStreak_inProgressCurrentWeek_preservesStreak() {
        val habit = createHabit(
            frequencyType = HabitFrequencyType.WEEKLY,
            targetCountPerWeek = 3
        )

        // Reference date is Tuesday Aug 18. Current week has only 1 completion so far (not yet met, but in-progress)
        val refDate = LocalDate.of(2026, 8, 18)
        val currentWeekLogs = listOf(
            createLog(habit.id, LocalDate.of(2026, 8, 17))
        )

        // Previous week (Aug 10 - Aug 16): 3 completions (met)
        val prevWeek1Logs = listOf(
            createLog(habit.id, LocalDate.of(2026, 8, 10)),
            createLog(habit.id, LocalDate.of(2026, 8, 12)),
            createLog(habit.id, LocalDate.of(2026, 8, 14))
        )

        // Previous week 2 (Aug 03 - Aug 09): 3 completions (met)
        val prevWeek2Logs = listOf(
            createLog(habit.id, LocalDate.of(2026, 8, 4)),
            createLog(habit.id, LocalDate.of(2026, 8, 5)),
            createLog(habit.id, LocalDate.of(2026, 8, 6))
        )

        val allLogs = currentWeekLogs + prevWeek1Logs + prevWeek2Logs

        val result = StreakCalculator.calculateStreak(habit, allLogs, refDate)

        // Because current week is in-progress and not over, streak is preserved from previous weeks (2 weeks)
        assertThat(result.currentStreak).isEqualTo(2)
        assertThat(result.bestStreak).isEqualTo(2)
    }

    @Test
    fun calculateStreak_numericTarget_requiresSumToReachTarget() {
        val habit = createHabit(
            targetType = HabitTargetType.NUMERIC,
            targetValue = 2000.0 // e.g. 2000 ml water
        )
        val today = LocalDate.of(2026, 8, 17)

        // Day 1 (today): 1000 + 1000 = 2000 (Complete)
        val logsToday = listOf(
            createLog(habit.id, today, value = 1000.0),
            createLog(habit.id, today, value = 1000.0)
        )

        // Day 2 (yesterday): 500 + 500 = 1000 (Incomplete, target is 2000)
        val logsYesterday = listOf(
            createLog(habit.id, today.minusDays(1), value = 500.0),
            createLog(habit.id, today.minusDays(1), value = 500.0)
        )

        val result = StreakCalculator.calculateStreak(habit, logsToday + logsYesterday, today)

        assertThat(result.currentStreak).isEqualTo(1)
    }

    @Test
    fun calculateStreak_timerTarget_convertsSecondsToMinutes() {
        val habit = createHabit(
            targetType = HabitTargetType.TIMER,
            targetValue = 30.0 // 30 minutes
        )
        val today = LocalDate.of(2026, 8, 17)

        // 1800 seconds = 30 minutes
        val logsToday = listOf(
            createLog(habit.id, today, durationSeconds = 1800L)
        )

        val result = StreakCalculator.calculateStreak(habit, logsToday, today)

        assertThat(result.currentStreak).isEqualTo(1)
    }

    @Test
    fun calculateStreak_subdaySlots_requiresAllSlotsCompleted() {
        val habit = createHabit(
            frequencyType = HabitFrequencyType.TIMES_PER_DAY,
            targetType = HabitTargetType.BOOLEAN,
            timesPerDay = 3
        )
        val today = LocalDate.of(2026, 8, 17)

        // Slot 0, Slot 1, Slot 2 completed
        val logsToday = listOf(
            createLog(habit.id, today, intervalIndex = 0),
            createLog(habit.id, today, intervalIndex = 1),
            createLog(habit.id, today, intervalIndex = 2)
        )

        // Yesterday: only slot 0 and slot 1 completed (missing slot 2)
        val logsYesterday = listOf(
            createLog(habit.id, today.minusDays(1), intervalIndex = 0),
            createLog(habit.id, today.minusDays(1), intervalIndex = 1)
        )

        val result = StreakCalculator.calculateStreak(habit, logsToday + logsYesterday, today)

        assertThat(result.currentStreak).isEqualTo(1)
    }
}
