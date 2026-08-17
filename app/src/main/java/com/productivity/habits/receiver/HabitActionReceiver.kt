package com.productivity.habits.receiver

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.glance.appwidget.updateAll
import com.productivity.habits.domain.repository.HabitRepository
import com.productivity.habits.widget.DailyFocusWidget
import com.productivity.habits.widget.QuickLogHabitWidget
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.time.LocalDate
import javax.inject.Inject

@AndroidEntryPoint
class HabitActionReceiver : BroadcastReceiver() {

    @Inject
    lateinit var repository: HabitRepository

    companion object {
        const val ACTION_CHECK_IN = "com.productivity.habits.ACTION_CHECK_IN"
        const val EXTRA_HABIT_ID = "extra_habit_id"
        const val EXTRA_NOTIFICATION_ID = "extra_notification_id"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_CHECK_IN) {
            val habitId = intent.getStringExtra(EXTRA_HABIT_ID) ?: return
            val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, -1)

            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (notificationId != -1) {
                notificationManager.cancel(notificationId)
            }

            val pendingResult = goAsync()
            CoroutineScope(Dispatchers.IO).launch {
                try {
                    repository.toggleBooleanCheckIn(habitId, LocalDate.now())
                    try {
                        QuickLogHabitWidget().updateAll(context)
                        DailyFocusWidget().updateAll(context)
                    } catch (e: Exception) {
                        // Ignore widget update errors if widgets are not yet placed
                    }
                } finally {
                    pendingResult.finish()
                }
            }
        }
    }
}
