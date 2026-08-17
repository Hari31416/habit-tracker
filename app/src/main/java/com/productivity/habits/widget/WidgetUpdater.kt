package com.productivity.habits.widget

import android.content.Context
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.updateAll
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

object WidgetUpdater {

    suspend fun updateAllWidgets(context: Context) {
        withContext(Dispatchers.Main.immediate) {
            val widgets = listOf<GlanceAppWidget>(
                TodaysHabitsWidget(),
                DailyFocusWidget(),
                FocusTimerWidget(),
                StreaksWidget(),
                XpMasteryWidget()
            )

            val manager = try {
                GlanceAppWidgetManager(context.applicationContext)
            } catch (_: Exception) {
                null
            }

            for (widget in widgets) {
                try {
                    if (manager != null) {
                        val ids = manager.getGlanceIds(widget.javaClass)
                        for (glanceId in ids) {
                            try {
                                widget.update(context.applicationContext, glanceId)
                            } catch (_: Exception) {}
                        }
                    } else {
                        widget.updateAll(context.applicationContext)
                    }
                } catch (_: Exception) {}
            }
        }
    }
}
