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
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitTargetType
import com.productivity.habits.domain.engine.DynamicStepEngine
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
            habit: HabitEntity,
            reminderIndex: Int
        ) {
            createNotificationChannel(context)
            val notificationId = (habit.id.hashCode() * 31) + reminderIndex

            // 1. Content Intent: Opens habit detail via deep link
            val deepLinkIntent = Intent(
                Intent.ACTION_VIEW,
                Uri.parse("app://habits/detail/${habit.id}"),
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

            // 2. Mark Done Intent
            val markDoneIntent = Intent(context, HabitActionReceiver::class.java).apply {
                action = HabitActionReceiver.ACTION_MARK_DONE
                putExtra(HabitActionReceiver.EXTRA_HABIT_ID, habit.id)
                putExtra(HabitActionReceiver.EXTRA_NOTIFICATION_ID, notificationId)
            }
            val markDonePendingIntent = PendingIntent.getBroadcast(
                context,
                notificationId * 10 + 1,
                markDoneIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val builder = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle(habit.title)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setContentIntent(contentPendingIntent)
                .setAutoCancel(true)

            when (habit.targetType) {
                HabitTargetType.BOOLEAN -> {
                    builder.setContentText("Ready for your daily check-in?")
                    builder.addAction(android.R.drawable.checkbox_on_background, "Check-In", markDonePendingIntent)
                    builder.addAction(android.R.drawable.ic_menu_view, "View Habit", contentPendingIntent)
                }

                HabitTargetType.NUMERIC -> {
                    val stepConfig = DynamicStepEngine.getDynamicStepConfig(habit.targetValue ?: 1.0, habit.unit)
                    val primaryStep = stepConfig.primaryStep
                    val stepText = if (primaryStep % 1.0 == 0.0) "${primaryStep.toInt()}" else "$primaryStep"
                    val unitSuffix = if (!habit.unit.isNullOrBlank()) " ${habit.unit}" else ""
                    val stepLabel = "+$stepText$unitSuffix"

                    builder.setContentText("Log progress ($stepLabel) toward daily goal.")

                    // Log Progress Delta Intent
                    val deltaIntent = Intent(context, HabitActionReceiver::class.java).apply {
                        action = HabitActionReceiver.ACTION_ADD_DELTA
                        putExtra(HabitActionReceiver.EXTRA_HABIT_ID, habit.id)
                        putExtra(HabitActionReceiver.EXTRA_NOTIFICATION_ID, notificationId)
                        putExtra(HabitActionReceiver.EXTRA_DELTA, primaryStep)
                    }
                    val deltaPendingIntent = PendingIntent.getBroadcast(
                        context,
                        notificationId * 10 + 2,
                        deltaIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )

                    builder.addAction(android.R.drawable.checkbox_on_background, "Mark Done", markDonePendingIntent)
                    builder.addAction(android.R.drawable.ic_input_add, "Log Progress", deltaPendingIntent)
                    builder.addAction(android.R.drawable.ic_menu_view, "View Habit", contentPendingIntent)
                }

                HabitTargetType.TIMER -> {
                    val timerConfig = DynamicStepEngine.getDynamicTimerConfig(habit.targetValue ?: 25.0)
                    val primaryStep = timerConfig.primaryStep
                    val stepLabel = "+${primaryStep.toInt()} min"

                    builder.setContentText("Log progress ($stepLabel) toward daily goal.")

                    // Add Timer Minutes Delta Intent
                    val deltaIntent = Intent(context, HabitActionReceiver::class.java).apply {
                        action = HabitActionReceiver.ACTION_ADD_DELTA
                        putExtra(HabitActionReceiver.EXTRA_HABIT_ID, habit.id)
                        putExtra(HabitActionReceiver.EXTRA_NOTIFICATION_ID, notificationId)
                        putExtra(HabitActionReceiver.EXTRA_DELTA, primaryStep)
                    }
                    val deltaPendingIntent = PendingIntent.getBroadcast(
                        context,
                        notificationId * 10 + 2,
                        deltaIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )

                    builder.addAction(android.R.drawable.checkbox_on_background, "Mark Done", markDonePendingIntent)
                    builder.addAction(android.R.drawable.ic_input_add, "Log Progress", deltaPendingIntent)
                    builder.addAction(android.R.drawable.ic_menu_view, "View Habit", contentPendingIntent)
                }
            }

            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(notificationId, builder.build())
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val habitId = intent.getStringExtra(EXTRA_HABIT_ID) ?: return
        val reminderIndex = intent.getIntExtra(EXTRA_REMINDER_INDEX, 0)

        val pendingResult = goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val entryPoint = EntryPointAccessors.fromApplication(
                    context.applicationContext,
                    HabitReminderEntryPoint::class.java
                )
                val habit = entryPoint.habitDao().getHabitByIdOnce(habitId)
                if (habit != null) {
                    showNotification(context, habit, reminderIndex)
                    entryPoint.scheduler().schedule(habit)
                }
            } finally {
                pendingResult.finish()
            }
        }
    }
}
