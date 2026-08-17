package com.productivity.habits.scheduler

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.productivity.habits.receiver.HabitReminderReceiver

class ReminderNotificationWorker(
    context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    override suspend fun doWork(): Result {
        val habitId = inputData.getString(HabitReminderReceiver.EXTRA_HABIT_ID) ?: return Result.failure()
        val habitTitle = inputData.getString(HabitReminderReceiver.EXTRA_HABIT_TITLE) ?: "Habit Reminder"
        val reminderIndex = inputData.getInt(HabitReminderReceiver.EXTRA_REMINDER_INDEX, 0)

        HabitReminderReceiver.showNotification(
            context = applicationContext,
            habitId = habitId,
            habitTitle = habitTitle,
            reminderIndex = reminderIndex
        )

        return Result.success()
    }
}
