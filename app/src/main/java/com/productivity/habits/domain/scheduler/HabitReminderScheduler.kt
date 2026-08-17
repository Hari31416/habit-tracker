package com.productivity.habits.domain.scheduler

import com.productivity.habits.data.local.entity.HabitEntity

interface HabitReminderScheduler {
    suspend fun schedule(habit: HabitEntity)
    suspend fun cancel(habitId: String)
    suspend fun rescheduleAll()
}
