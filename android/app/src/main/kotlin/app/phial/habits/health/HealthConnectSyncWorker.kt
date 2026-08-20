package app.phial.habits.health

import android.content.Context
import androidx.work.*
import app.phial.habits.MainActivity
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.concurrent.TimeUnit

class HealthConnectSyncWorker(
    private val context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        return try {
            val manager = HealthConnectManager(context)
            if (manager.checkAvailability() != "available") {
                return Result.success()
            }

            val todayStr = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd"))
            val metrics = listOf("steps", "exercise_time", "hydration", "sleep_duration")

            if (manager.hasPermissions(metrics)) {
                manager.getDailyMetrics(todayStr, metrics)
                MainActivity.updateAllAppWidgets(context)
            }

            Result.success()
        } catch (e: Exception) {
            android.util.Log.w("HealthConnectWorker", "Background health sync failed", e)
            Result.retry()
        }
    }

    companion object {
        private const val WORK_NAME = "habit_health_connect_sync"

        fun schedule(context: Context, intervalMinutes: Long = 30) {
            val constraints = Constraints.Builder()
                .setRequiresBatteryNotLow(true)
                .build()

            val workRequest = PeriodicWorkRequestBuilder<HealthConnectSyncWorker>(
                intervalMinutes.coerceAtLeast(15), TimeUnit.MINUTES
            )
                .setConstraints(constraints)
                .build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.UPDATE,
                workRequest
            )
        }

        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
        }
    }
}
