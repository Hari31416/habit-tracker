package com.productivity.habits.widget

import android.content.Context
import androidx.glance.appwidget.updateAll
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

object WidgetUpdater {

    suspend fun updateAllWidgets(context: Context) {
        withContext(Dispatchers.Main.immediate) {
            try {
                TodaysHabitsWidget().updateAll(context)
            } catch (_: Exception) {}
            try {
                DailyFocusWidget().updateAll(context)
            } catch (_: Exception) {}
            try {
                FocusTimerWidget().updateAll(context)
            } catch (_: Exception) {}
            try {
                StreaksWidget().updateAll(context)
            } catch (_: Exception) {}
            try {
                XpMasteryWidget().updateAll(context)
            } catch (_: Exception) {}
        }
    }
}
