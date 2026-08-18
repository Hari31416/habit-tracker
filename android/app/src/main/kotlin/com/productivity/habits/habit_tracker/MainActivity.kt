package com.productivity.habits.habit_tracker

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import com.productivity.habits.habit_tracker.widgets.*
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.productivity.habits/widgets"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidgetData" -> {
                    val widgetType = call.argument<String>("widgetType")
                    val jsonData = call.argument<String>("jsonData")
                    if (widgetType != null && jsonData != null) {
                        val prefs = getSharedPreferences("habit_widget_prefs", Context.MODE_PRIVATE)
                        prefs.edit().putString(widgetType, jsonData).apply()
                    }
                    updateAllAppWidgets(applicationContext)
                    result.success(true)
                }
                "updateAllWidgets" -> {
                    updateAllAppWidgets(applicationContext)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    companion object {
        fun updateAllAppWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)

            // 1. Today's Habits
            val todaysHabitsIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, TodaysHabitsWidgetReceiver::class.java)
            )
            if (todaysHabitsIds.isNotEmpty()) {
                TodaysHabitsWidgetReceiver().updateWidgets(context, appWidgetManager, todaysHabitsIds)
            }

            // 2. Daily Focus
            val dailyFocusIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, DailyFocusWidgetReceiver::class.java)
            )
            if (dailyFocusIds.isNotEmpty()) {
                DailyFocusWidgetReceiver().updateWidgets(context, appWidgetManager, dailyFocusIds)
            }

            // 3. Focus Timer
            val focusTimerIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, FocusTimerWidgetReceiver::class.java)
            )
            if (focusTimerIds.isNotEmpty()) {
                FocusTimerWidgetReceiver().updateWidgets(context, appWidgetManager, focusTimerIds)
            }

            // 4. Streaks
            val streaksIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, StreaksWidgetReceiver::class.java)
            )
            if (streaksIds.isNotEmpty()) {
                StreaksWidgetReceiver().updateWidgets(context, appWidgetManager, streaksIds)
            }

            // 5. XP Mastery
            val xpMasteryIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, XpMasteryWidgetReceiver::class.java)
            )
            if (xpMasteryIds.isNotEmpty()) {
                XpMasteryWidgetReceiver().updateWidgets(context, appWidgetManager, xpMasteryIds)
            }
        }
    }
}
