package com.productivity.habits.domain.gamification

import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitFrequencyType
import com.productivity.habits.data.local.entity.HabitLogEntity
import com.productivity.habits.data.local.entity.HabitTargetType
import kotlin.math.roundToLong

object GamificationEngine {

    const val PERFECT_DAY_BONUS_XP = 50
    const val BASE_BOOLEAN_XP = 20
    const val BASE_NUMERIC_COMPLETION_XP = 25
    const val BASE_TIMER_COMPLETION_BONUS_XP = 10
    const val BASE_SLOT_CHECK_IN_XP = 10
    const val BASE_ALL_SLOTS_BONUS_XP = 15

    /**
     * Calculates the streak multiplier based on active streak length:
     * - < 7 days: 1.0x
     * - 7..13 days: 1.25x
     * - 14..29 days: 1.5x
     * - 30+ days: 2.0x
     */
    fun calculateStreakMultiplier(streakDays: Int): Double {
        return when {
            streakDays >= 30 -> 2.0
            streakDays >= 14 -> 1.5
            streakDays >= 7 -> 1.25
            else -> 1.0
        }
    }

    /**
     * Total XP threshold to reach a given level using quadratic formula:
     * T(L) = 25 * (L - 1)^2 + 75 * (L - 1)
     * Level 1: 0 XP
     * Level 2: 100 XP
     * Level 3: 250 XP
     * Level 4: 450 XP
     * Level 5: 700 XP (Apprentice)
     * Level 10: 2700 XP (Pathfinder)
     * Level 20: 10450 XP (Grandmaster)
     */
    fun xpThresholdForLevel(level: Int): Long {
        if (level <= 1) return 0L
        val n = (level - 1).toLong()
        return 25L * n * n + 75L * n
    }

    /**
     * Resolves the PlayerProgression (level, title, progress fraction, thresholds) for total XP.
     */
    fun calculateProgression(
        totalXp: Long,
        longestActiveStreak: Int = 0,
        unlockedBadgesCount: Int = 0,
        totalBadgesCount: Int = 0
    ): PlayerProgression {
        val safeXp = maxOf(0L, totalXp)
        var level = 1
        while (xpThresholdForLevel(level + 1) <= safeXp) {
            level++
        }

        val currentLevelBase = xpThresholdForLevel(level)
        val nextLevelTarget = xpThresholdForLevel(level + 1)
        val levelXpSpan = (nextLevelTarget - currentLevelBase).toFloat()
        val currentProgressInLevel = (safeXp - currentLevelBase).toFloat()
        val progressFraction = if (levelXpSpan > 0f) {
            (currentProgressInLevel / levelXpSpan).coerceIn(0.0f, 1.0f)
        } else {
            1.0f
        }

        val multiplier = calculateStreakMultiplier(longestActiveStreak)
        val title = PlayerTitle.fromLevel(level)

        return PlayerProgression(
            totalXp = safeXp,
            level = level,
            title = title,
            currentLevelBaseXp = currentLevelBase,
            nextLevelTargetXp = nextLevelTarget,
            progressFraction = progressFraction,
            activeStreakMultiplier = multiplier,
            longestActiveStreak = longestActiveStreak,
            unlockedBadgesCount = unlockedBadgesCount,
            totalBadgesCount = totalBadgesCount
        )
    }

    /**
     * Calculates base XP earned for a habit day's logs and completion state.
     */
    fun calculateHabitDayBaseXp(
        habit: HabitEntity,
        logsOnDate: List<HabitLogEntity>,
        isCompleted: Boolean
    ): Int {
        if (logsOnDate.isEmpty() && !isCompleted) return 0

        return when (habit.targetType) {
            HabitTargetType.BOOLEAN -> {
                when (habit.frequencyType) {
                    HabitFrequencyType.SUBDAY_INTERVAL, HabitFrequencyType.TIMES_PER_DAY -> {
                        val completedSlots = logsOnDate.filter { it.completed }.mapNotNull { it.intervalIndex }.toSet().size
                        val slotXp = completedSlots * BASE_SLOT_CHECK_IN_XP
                        val bonusXp = if (isCompleted) BASE_ALL_SLOTS_BONUS_XP else 0
                        slotXp + bonusXp
                    }
                    else -> if (isCompleted) BASE_BOOLEAN_XP else 0
                }
            }
            HabitTargetType.NUMERIC -> {
                val target = habit.targetValue ?: 1.0
                val totalValue = logsOnDate.sumOf { it.value ?: if (it.completed) target else 0.0 }
                if (isCompleted) {
                    BASE_NUMERIC_COMPLETION_XP
                } else if (target > 0) {
                    val ratio = (totalValue / target).coerceIn(0.0, 1.0)
                    (ratio * BASE_BOOLEAN_XP).toInt().coerceAtLeast(if (logsOnDate.isNotEmpty()) 5 else 0)
                } else {
                    0
                }
            }
            HabitTargetType.TIMER -> {
                val targetMinutes = habit.targetValue ?: 25.0
                val totalMinutes = logsOnDate.sumOf { log ->
                    if (log.durationSeconds != null && log.durationSeconds > 0) {
                        log.durationSeconds / 60.0
                    } else {
                        log.value ?: if (log.completed) targetMinutes else 0.0
                    }
                }
                val minuteXp = totalMinutes.toInt().coerceAtLeast(0)
                val bonus = if (isCompleted) BASE_TIMER_COMPLETION_BONUS_XP else 0
                minuteXp + bonus
            }
        }
    }

    /**
     * Applies streak multiplier to a base XP amount.
     */
    fun applyMultiplier(baseXp: Int, multiplier: Double): Long {
        if (baseXp <= 0) return 0L
        return (baseXp * multiplier).roundToLong().coerceAtLeast(1L)
    }
}
