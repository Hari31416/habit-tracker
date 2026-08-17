package com.productivity.habits.domain.model

import com.productivity.habits.data.local.entity.HabitCategoryEntity
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitLogEntity
import com.productivity.habits.domain.engine.StreakResult

data class HabitWithProgress(
    val habit: HabitEntity,
    val category: HabitCategoryEntity? = null,
    val logsForDate: List<HabitLogEntity> = emptyList(),
    val isCompletedOnDate: Boolean = false,
    val currentValueOnDate: Double = 0.0,
    val currentDurationSecondsOnDate: Long = 0L,
    val streak: StreakResult = StreakResult(0, 0, 0, 0)
)
