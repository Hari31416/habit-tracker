package com.productivity.habits.receiver

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import com.productivity.habits.MainActivity
import com.productivity.habits.data.local.dao.HabitDao
import com.productivity.habits.domain.scheduler.HabitReminderScheduler
import dagger.hilt.EntryPoint
import dagger.hilt.InstallIn
import dagger.hilt.android.EntryPointAccessors
import dagger.hilt.components.SingletonComponent
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class HabitReminderReceiver : BroadcastReceiver() {

    @EntryPoint
    @InstallIn(SingletonComponent::class)
    interface HabitReminderEntryPoint {
        fun scheduler(): HabitReminderScheduler
        fun habitDao(): HabitDao
    }

    companion object {
        const val CHANNEL_ID = "habit_reminders"
        const val ACTION_HABIT_REMINDER = "com.productivity.habits.ACTION_HABIT_REMINDER"

        const val EXTRA_HABIT_ID = "extra_habit_id"
        const val EXTRA_HABIT_TITLE = "extra_habit_title"
        const val EXTRA_HABIT_COLOR = "extra_habit_color"
        const val EXTRA_HABIT_ICON = "extra_habit_icon"
        const val EXTRA_REMINDER_INDEX = "extra_reminder_index"

        fun createNotificationChannel(context: Context) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "Habit Reminders",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Timely reminders to complete your scheduled habits"
                    enableVibration(true)
                }
                notificationManager.createNotificationChannel(channel)
            }
        }

        fun showNotification(
            context: Context,
            habitId: String,
            habitTitle: String,
            reminderIndex: Int
        ) {
            createNotificationChannel(context)
            val notificationId = (habitId.hashCode() * 31) + reminderIndex

            val deepLinkIntent = Intent(
                Intent.ACTION_VIEW,
                Uri.parse("app://habits/detail/$habitId"),
                context,
                MainActivity::class.java
            ).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }

            val contentPendingIntent = PendingIntent.getActivity(
                context,
                notificationId,
                deepLinkIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val checkInIntent = Intent(context, HabitActionReceiver::class.java).apply {
                action = HabitActionReceiver.ACTION_CHECK_IN
                putExtra(HabitActionReceiver.EXTRA_HABIT_ID, habitId)
                putExtra(HabitActionReceiver.EXTRA_NOTIFICATION_ID, notificationId)
            }

            val checkInPendingIntent = PendingIntent.getBroadcast(
                context,
                notificationId,
                checkInIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val notification = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle(habitTitle)
                .setContentText("Time to complete your habit today!")
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setContentIntent(contentPendingIntent)
                .setAutoCancel(true)
                .addAction(android.R.drawable.checkbox_on_background, "+1 Check-in", checkInPendingIntent)
                .build()

            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(notificationId, notification)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val habitId = intent.getStringExtra(EXTRA_HABIT_ID) ?: return
        val habitTitle = intent.getStringExtra(EXTRA_HABIT_TITLE) ?: "Habit Reminder"
        val reminderIndex = intent.getIntExtra(EXTRA_REMINDER_INDEX, 0)

        showNotification(context, habitId, habitTitle, reminderIndex)

        val pendingResult = goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val entryPoint = EntryPointAccessors.fromApplication(
                    context.applicationContext,
                    HabitReminderEntryPoint::class.java
                )
                val habit = entryPoint.habitDao().getHabitByIdOnce(habitId)
                if (habit != null) {
                    entryPoint.scheduler().schedule(habit)
                }
            } finally {
                pendingResult.finish()
            }
        }
    }
}
