package com.productivity.habits.scheduler

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.productivity.habits.data.local.dao.HabitDao
import com.productivity.habits.receiver.HabitReminderReceiver
import dagger.hilt.EntryPoint
import dagger.hilt.InstallIn
import dagger.hilt.android.EntryPointAccessors
import dagger.hilt.components.SingletonComponent

class ReminderNotificationWorker(
    context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    @EntryPoint
    @InstallIn(SingletonComponent::class)
    interface ReminderWorkerEntryPoint {
        fun habitDao(): HabitDao
    }

    override suspend fun doWork(): Result {
        val habitId = inputData.getString(HabitReminderReceiver.EXTRA_HABIT_ID) ?: return Result.failure()
        val reminderIndex = inputData.getInt(HabitReminderReceiver.EXTRA_REMINDER_INDEX, 0)

        val entryPoint = EntryPointAccessors.fromApplication(
            applicationContext,
            ReminderWorkerEntryPoint::class.java
        )
        val habit = entryPoint.habitDao().getHabitByIdOnce(habitId) ?: return Result.failure()

        HabitReminderReceiver.showNotification(
            context = applicationContext,
            habit = habit,
            reminderIndex = reminderIndex
        )

        return Result.success()
    }
}
