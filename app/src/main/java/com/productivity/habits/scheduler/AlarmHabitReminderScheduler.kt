package com.productivity.habits.scheduler

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.AlarmManagerCompat
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import com.productivity.habits.data.local.dao.HabitDao
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.domain.engine.StreakCalculator
import com.productivity.habits.domain.scheduler.HabitReminderScheduler
import com.productivity.habits.receiver.HabitReminderReceiver
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import java.util.concurrent.TimeUnit
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AlarmHabitReminderScheduler @Inject constructor(
    @ApplicationContext private val context: Context,
    private val habitDao: HabitDao
) : HabitReminderScheduler {

    private val alarmManager: AlarmManager? = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
    private val timeFormatter = DateTimeFormatter.ofPattern("HH:mm")

    override suspend fun schedule(habit: HabitEntity) {
        withContext(Dispatchers.IO) {
            cancel(habit.id)

            if (habit.archived || habit.reminderTimes.isEmpty()) {
                return@withContext
            }

            habit.reminderTimes.forEachIndexed { index, timeStr ->
                val localTime = parseTime(timeStr) ?: return@forEachIndexed
                val nextDateTime = calculateNextOccurrence(habit, localTime)

                scheduleAlarmForTime(habit, nextDateTime, index)
            }
        }
    }

    override suspend fun cancel(habitId: String) {
        withContext(Dispatchers.IO) {
            // Cancel up to 10 possible reminder index slots per habit
            for (index in 0 until 10) {
                val intent = Intent(context, HabitReminderReceiver::class.java)
                val requestCode = generateRequestCode(habitId, index)
                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    requestCode,
                    intent,
                    PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
                )
                if (pendingIntent != null) {
                    alarmManager?.cancel(pendingIntent)
                    pendingIntent.cancel()
                }
                WorkManager.getInstance(context).cancelUniqueWork("reminder_${habitId}_$index")
            }
        }
    }

    override suspend fun rescheduleAll() {
        withContext(Dispatchers.IO) {
            val activeHabits = habitDao.getActiveHabitsOnce()
            activeHabits.forEach { habit ->
                schedule(habit)
            }
        }
    }

    fun calculateNextOccurrence(
        habit: HabitEntity,
        reminderTime: LocalTime,
        referenceDateTime: LocalDateTime = LocalDateTime.now()
    ): LocalDateTime {
        var candidateDate = referenceDateTime.toLocalDate()
        val refTimeMinute = referenceDateTime.toLocalTime().truncatedTo(ChronoUnit.MINUTES)

        // If today's reminder minute has already passed (strictly greater than reminderTime), start checking from tomorrow
        if (refTimeMinute.isAfter(reminderTime)) {
            candidateDate = candidateDate.plusDays(1)
        }

        // Find the next date when this habit is scheduled
        for (i in 0 until 14) {
            val checkDate = candidateDate.plusDays(i.toLong())
            if (StreakCalculator.isHabitScheduledOnDate(habit, checkDate)) {
                return LocalDateTime.of(checkDate, reminderTime)
            }
        }

        return LocalDateTime.of(candidateDate, reminderTime)
    }

    private fun scheduleAlarmForTime(habit: HabitEntity, triggerDateTime: LocalDateTime, reminderIndex: Int) {
        val calculatedMillis = triggerDateTime.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()
        // If scheduled for today's current minute, ensure trigger is at least 1s in the future
        val triggerMillis = maxOf(System.currentTimeMillis() + 1000L, calculatedMillis)
        val requestCode = generateRequestCode(habit.id, reminderIndex)

        val intent = Intent(context, HabitReminderReceiver::class.java).apply {
            action = HabitReminderReceiver.ACTION_HABIT_REMINDER
            putExtra(HabitReminderReceiver.EXTRA_HABIT_ID, habit.id)
            putExtra(HabitReminderReceiver.EXTRA_HABIT_TITLE, habit.title)
            putExtra(HabitReminderReceiver.EXTRA_HABIT_COLOR, habit.color)
            putExtra(HabitReminderReceiver.EXTRA_HABIT_ICON, habit.icon)
            putExtra(HabitReminderReceiver.EXTRA_REMINDER_INDEX, reminderIndex)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val canScheduleExact = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            alarmManager?.canScheduleExactAlarms() == true
        } else {
            true
        }

        if (alarmManager != null && canScheduleExact) {
            AlarmManagerCompat.setExactAndAllowWhileIdle(
                alarmManager,
                AlarmManager.RTC_WAKEUP,
                triggerMillis,
                pendingIntent
            )
        } else {
            // Fallback: Schedule one-time WorkManager task with initial delay
            val delayMillis = (triggerMillis - System.currentTimeMillis()).coerceAtLeast(0L)
            val workData = Data.Builder()
                .putString(HabitReminderReceiver.EXTRA_HABIT_ID, habit.id)
                .putString(HabitReminderReceiver.EXTRA_HABIT_TITLE, habit.title)
                .putString(HabitReminderReceiver.EXTRA_HABIT_COLOR, habit.color)
                .putString(HabitReminderReceiver.EXTRA_HABIT_ICON, habit.icon)
                .putInt(HabitReminderReceiver.EXTRA_REMINDER_INDEX, reminderIndex)
                .build()

            val workRequest = OneTimeWorkRequestBuilder<ReminderNotificationWorker>()
                .setInitialDelay(delayMillis, TimeUnit.MILLISECONDS)
                .setInputData(workData)
                .build()

            WorkManager.getInstance(context).enqueueUniqueWork(
                "reminder_${habit.id}_$reminderIndex",
                ExistingWorkPolicy.REPLACE,
                workRequest
            )
        }
    }

    private fun parseTime(timeStr: String): LocalTime? {
        return try {
            LocalTime.parse(timeStr.trim(), timeFormatter)
        } catch (e: Exception) {
            null
        }
    }

    private fun generateRequestCode(habitId: String, reminderIndex: Int): Int {
        return (habitId.hashCode() * 31) + reminderIndex
    }
}
