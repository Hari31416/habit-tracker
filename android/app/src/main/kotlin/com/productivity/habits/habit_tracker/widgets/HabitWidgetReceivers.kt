package com.productivity.habits.habit_tracker.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.productivity.habits.habit_tracker.MainActivity
import com.productivity.habits.habit_tracker.R

open class BaseHabitWidgetProvider(private val layoutResId: Int) : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val views = RemoteViews(context.packageName, layoutResId).apply {
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

class TodaysHabitsWidgetReceiver : BaseHabitWidgetProvider(R.layout.widget_todays_habits)
class DailyFocusWidgetReceiver : BaseHabitWidgetProvider(R.layout.widget_daily_focus)
class FocusTimerWidgetReceiver : BaseHabitWidgetProvider(R.layout.widget_focus_timer)
class StreaksWidgetReceiver : BaseHabitWidgetProvider(R.layout.widget_streaks)
class XpMasteryWidgetReceiver : BaseHabitWidgetProvider(R.layout.widget_xp_mastery)
