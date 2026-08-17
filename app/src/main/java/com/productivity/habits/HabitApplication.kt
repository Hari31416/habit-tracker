package com.productivity.habits

import android.app.Application
import com.productivity.habits.receiver.HabitReminderReceiver
import com.productivity.habits.scheduler.DayRolloverWorker
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class HabitApplication : Application() {

    override fun onCreate() {
        super.onCreate()

        // Create default notification channels
        HabitReminderReceiver.createNotificationChannel(this)

        // Schedule next midnight day rollover worker
        DayRolloverWorker.scheduleNextMidnight(this)
    }
}
