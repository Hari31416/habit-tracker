package com.productivity.habits.data.scheduler

import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.domain.scheduler.HabitReminderScheduler
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class NoOpHabitReminderScheduler @Inject constructor() : HabitReminderScheduler {
    override suspend fun schedule(habit: HabitEntity) {
        // No-op for Phases 1-4. Wired to AlarmManager & WorkManager in Phase 5.
    }

    override suspend fun cancel(habitId: String) {
        // No-op for Phases 1-4. Wired to AlarmManager & WorkManager in Phase 5.
    }

    override suspend fun rescheduleAll() {
        // No-op for Phases 1-4. Wired to AlarmManager & WorkManager in Phase 5.
    }
}
