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

class WidgetUpdateWorker(
    context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    companion object {
        const val UNIQUE_WORK_NAME = "habit_widget_update"

        fun enqueue(context: Context) {
            val request = OneTimeWorkRequestBuilder<WidgetUpdateWorker>().build()
            WorkManager.getInstance(context).enqueueUniqueWork(
                UNIQUE_WORK_NAME,
                ExistingWorkPolicy.REPLACE,
                request
            )
        }
    }

    override suspend fun doWork(): Result {
        return try {
            QuickLogHabitWidget().updateAll(applicationContext)
            DailyFocusWidget().updateAll(applicationContext)
            Result.success()
        } catch (e: Exception) {
            Result.success()
        }
    }
}
