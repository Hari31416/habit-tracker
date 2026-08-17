package com.productivity.habits.receiver

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.productivity.habits.data.local.entity.HabitTargetType
import com.productivity.habits.domain.repository.HabitRepository
import com.productivity.habits.widget.WidgetUpdater
import dagger.hilt.EntryPoint
import dagger.hilt.InstallIn
import dagger.hilt.android.EntryPointAccessors
import dagger.hilt.components.SingletonComponent
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.time.LocalDate

class HabitActionReceiver : BroadcastReceiver() {

    @EntryPoint
    @InstallIn(SingletonComponent::class)
    interface HabitActionEntryPoint {
        fun repository(): HabitRepository
    }

    companion object {
        const val ACTION_MARK_DONE = "com.productivity.habits.ACTION_MARK_DONE"
        const val ACTION_ADD_DELTA = "com.productivity.habits.ACTION_ADD_DELTA"

        const val EXTRA_HABIT_ID = "extra_habit_id"
        const val EXTRA_NOTIFICATION_ID = "extra_notification_id"
        const val EXTRA_DELTA = "extra_delta"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val habitId = intent.getStringExtra(EXTRA_HABIT_ID) ?: return
        val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, -1)

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (notificationId != -1) {
            notificationManager.cancel(notificationId)
        }

        val pendingResult = goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val entryPoint = EntryPointAccessors.fromApplication(
                    context.applicationContext,
                    HabitActionEntryPoint::class.java
                )
                val repository = entryPoint.repository()
                val habit = repository.getHabitByIdOnce(habitId)
                val today = LocalDate.now()

                when (action) {
                    ACTION_MARK_DONE -> {
                        if (habit != null) {
                            when (habit.targetType) {
                                HabitTargetType.BOOLEAN -> {
                                    repository.logCheckIn(habitId, today, completed = true)
                                }
                                HabitTargetType.NUMERIC, HabitTargetType.TIMER -> {
                                    repository.updateNumericValue(habitId, today, habit.targetValue ?: 1.0)
                                }
                            }
                        } else {
                            repository.logCheckIn(habitId, today, completed = true)
                        }
                    }
                    ACTION_ADD_DELTA -> {
                        val delta = intent.getDoubleExtra(EXTRA_DELTA, 1.0)
                        repository.addNumericDelta(habitId, today, delta)
                    }
                }

                WidgetUpdater.updateAllWidgets(context)
            } finally {
                pendingResult.finish()
            }
        }
    }
}
