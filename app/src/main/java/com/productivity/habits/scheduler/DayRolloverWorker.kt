package com.productivity.habits.scheduler

import android.content.Context
import androidx.glance.appwidget.updateAll
import androidx.work.CoroutineWorker
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import com.productivity.habits.widget.DailyFocusWidget
import com.productivity.habits.widget.QuickLogHabitWidget
import java.time.Duration
import java.time.LocalDateTime
import java.time.LocalTime
import java.util.concurrent.TimeUnit

class DayRolloverWorker(
    context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    companion object {
        const val UNIQUE_WORK_NAME = "habit_day_rollover"

        fun scheduleNextMidnight(context: Context) {
            val now = LocalDateTime.now()
            val nextMidnight = now.toLocalDate().plusDays(1).atTime(LocalTime.MIDNIGHT).plusMinutes(1)
            val delayMinutes = Duration.between(now, nextMidnight).toMinutes().coerceAtLeast(1)

            val workRequest = OneTimeWorkRequestBuilder<DayRolloverWorker>()
                .setInitialDelay(delayMinutes, TimeUnit.MINUTES)
                .build()

            WorkManager.getInstance(context).enqueueUniqueWork(
                UNIQUE_WORK_NAME,
                ExistingWorkPolicy.REPLACE,
                workRequest
            )
        }
    }

    override suspend fun doWork(): Result {
        try {
            QuickLogHabitWidget().updateAll(applicationContext)
            DailyFocusWidget().updateAll(applicationContext)
        } catch (e: Exception) {
            // Ignore if widgets are not placed
        }

        // Schedule next midnight cycle
        scheduleNextMidnight(applicationContext)

        return Result.success()
    }
}
