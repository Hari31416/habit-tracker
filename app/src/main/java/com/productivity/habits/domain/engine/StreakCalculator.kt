package com.productivity.habits.domain.engine

import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitFrequencyType
import com.productivity.habits.data.local.entity.HabitLogEntity
import com.productivity.habits.data.local.entity.HabitTargetType
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.temporal.TemporalAdjusters
import kotlin.math.roundToInt

data class StreakResult(
    val currentStreak: Int,
    val bestStreak: Int,
    val completionRate30Days: Int,
    val totalCompletions: Int // day-level completions; for WEEKLY also exposes week meets
)

object StreakCalculator {

    private val DATE_FORMATTER: DateTimeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")

    fun isoWeekStart(date: LocalDate): LocalDate =
        date.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))

    fun isHabitScheduledOnDate(habit: HabitEntity, date: LocalDate): Boolean {
        return when (habit.frequencyType) {
            HabitFrequencyType.DAILY -> true
            HabitFrequencyType.CUSTOM_DAYS -> {
                // 0 = Sunday, 1 = Monday, ... 6 = Saturday
                val dayOfWeek = if (date.dayOfWeek.value == 7) 0 else date.dayOfWeek.value
                habit.targetDaysOfWeek?.contains(dayOfWeek) == true
            }
            HabitFrequencyType.WEEKLY -> true // loggable any day; week success uses targetCountPerWeek
            HabitFrequencyType.SUBDAY_INTERVAL, HabitFrequencyType.TIMES_PER_DAY -> true
        }
    }

    fun isHabitCompletedOnDate(habit: HabitEntity, logs: List<HabitLogEntity>): Boolean {
        if (logs.isEmpty()) return false

        return when (habit.targetType) {
            HabitTargetType.BOOLEAN -> {
                when (habit.frequencyType) {
                    HabitFrequencyType.SUBDAY_INTERVAL, HabitFrequencyType.TIMES_PER_DAY -> {
                        val requiredSlots = habit.timesPerDay ?: habit.targetValue?.toInt() ?: 1
                        val completedSlots = logs.filter { it.completed }.mapNotNull { it.intervalIndex }.toSet().size
                        completedSlots >= requiredSlots
                    }
                    else -> logs.any { it.completed }
                }
            }
            HabitTargetType.NUMERIC -> {
                val target = habit.targetValue ?: 1.0
                val totalValue = logs.sumOf { log ->
                    log.value ?: if (log.completed) target else 0.0
                }
                totalValue >= target
            }
            HabitTargetType.TIMER -> {
                val targetMinutes = habit.targetValue ?: 25.0
                val totalMinutes = logs.sumOf { log ->
                    if (log.durationSeconds != null && log.durationSeconds > 0) {
                        (log.durationSeconds / 60.0)
                    } else {
                        log.value ?: if (log.completed) targetMinutes else 0.0
                    }
                }
                totalMinutes >= targetMinutes
            }
        }
    }

    fun isWeeklyTargetMet(
        habit: HabitEntity,
        logsByDate: Map<String, List<HabitLogEntity>>,
        weekStart: LocalDate,
        formatter: DateTimeFormatter = DATE_FORMATTER
    ): Boolean {
        val required = habit.targetCountPerWeek ?: 1
        var completedDays = 0
        for (offset in 0 until 7) {
            val date = weekStart.plusDays(offset.toLong())
            val dayLogs = logsByDate[date.format(formatter)] ?: emptyList()
            if (isHabitCompletedOnDate(habit, dayLogs)) completedDays++
        }
        return completedDays >= required
    }

    fun calculateStreak(
        habit: HabitEntity,
        allLogs: List<HabitLogEntity>,
        referenceDate: LocalDate = LocalDate.now()
    ): StreakResult {
        val logsByDate = allLogs.filter { it.habitId == habit.id }.groupBy { it.date }
        val formatter = DATE_FORMATTER

        if (habit.frequencyType == HabitFrequencyType.WEEKLY) {
            return calculateWeeklyStreak(habit, logsByDate, referenceDate, formatter)
        }

        var currentStreak = 0
        var bestStreak = 0
        var tempStreak = 0
        var totalCompletions = 0

        var scheduledDaysIn30 = 0
        var completedDaysIn30 = 0

        for (i in 0 until 30) {
            val checkDate = referenceDate.minusDays(i.toLong())
            val dateStr = checkDate.format(formatter)
            val isScheduled = isHabitScheduledOnDate(habit, checkDate)

            if (isScheduled) {
                scheduledDaysIn30++
                val dayLogs = logsByDate[dateStr] ?: emptyList()
                if (isHabitCompletedOnDate(habit, dayLogs)) {
                    completedDaysIn30++
                }
            }
        }

        val completionRate30Days = if (scheduledDaysIn30 > 0) {
            ((completedDaysIn30.toDouble() / scheduledDaysIn30.toDouble()) * 100).roundToInt()
        } else 0

        var checkDate = referenceDate
        var isCurrentStreakChain = true

        val refDateStr = referenceDate.format(formatter)
        val refLogs = logsByDate[refDateStr] ?: emptyList()
        val refCompleted = isHabitCompletedOnDate(habit, refLogs)

        // In-progress preservation: If today is not completed but is scheduled, start evaluating streak from yesterday
        if (!refCompleted && isHabitScheduledOnDate(habit, referenceDate)) {
            checkDate = referenceDate.minusDays(1)
        }

        for (i in 0 until 365) {
            val dateStr = checkDate.format(formatter)
            val isScheduled = isHabitScheduledOnDate(habit, checkDate)

            if (isScheduled) {
                val dayLogs = logsByDate[dateStr] ?: emptyList()
                val completed = isHabitCompletedOnDate(habit, dayLogs)

                if (completed) {
                    totalCompletions++
                    tempStreak++
                    if (isCurrentStreakChain) {
                        currentStreak++
                    }
                    if (tempStreak > bestStreak) {
                        bestStreak = tempStreak
                    }
                } else {
                    isCurrentStreakChain = false
                    tempStreak = 0
                }
            }
            checkDate = checkDate.minusDays(1)
        }

        return StreakResult(
            currentStreak = currentStreak,
            bestStreak = maxOf(bestStreak, currentStreak),
            completionRate30Days = completionRate30Days,
            totalCompletions = totalCompletions
        )
    }

    fun calculateWeeklyStreak(
        habit: HabitEntity,
        logsByDate: Map<String, List<HabitLogEntity>>,
        referenceDate: LocalDate,
        formatter: DateTimeFormatter = DATE_FORMATTER
    ): StreakResult {
        var currentStreak = 0
        var bestStreak = 0
        var tempStreak = 0
        var totalCompletions = 0

        val windowStart = referenceDate.minusDays(29)
        val weeksInWindow = linkedSetOf<LocalDate>()
        var cursor = windowStart
        while (!cursor.isAfter(referenceDate)) {
            weeksInWindow.add(isoWeekStart(cursor))
            cursor = cursor.plusDays(1)
        }
        val metWeeksInWindow = weeksInWindow.count { isWeeklyTargetMet(habit, logsByDate, it, formatter) }
        val completionRate30Days = if (weeksInWindow.isNotEmpty()) {
            ((metWeeksInWindow.toDouble() / weeksInWindow.size.toDouble()) * 100).roundToInt()
        } else 0

        var weekStart = isoWeekStart(referenceDate)
        var isCurrentStreakChain = true
        val currentWeekMet = isWeeklyTargetMet(habit, logsByDate, weekStart, formatter)
        if (!currentWeekMet) {
            // In-progress week: do not break streak until the week ends unmet
            weekStart = weekStart.minusWeeks(1)
        }

        for (i in 0 until 52) {
            val met = isWeeklyTargetMet(habit, logsByDate, weekStart, formatter)
            // Count day-level completions inside the week for totalCompletions
            for (offset in 0 until 7) {
                val dayLogs = logsByDate[weekStart.plusDays(offset.toLong()).format(formatter)] ?: emptyList()
                if (isHabitCompletedOnDate(habit, dayLogs)) totalCompletions++
            }
            if (met) {
                tempStreak++
                if (isCurrentStreakChain) currentStreak++
                if (tempStreak > bestStreak) bestStreak = tempStreak
            } else {
                isCurrentStreakChain = false
                tempStreak = 0
            }
            weekStart = weekStart.minusWeeks(1)
        }

        return StreakResult(
            currentStreak = currentStreak,
            bestStreak = maxOf(bestStreak, currentStreak),
            completionRate30Days = completionRate30Days,
            totalCompletions = totalCompletions
        )
    }
}
