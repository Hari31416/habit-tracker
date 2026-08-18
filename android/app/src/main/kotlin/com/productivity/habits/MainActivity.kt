package com.productivity.habits
 
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import com.productivity.habits.widgets.*
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val WIDGETS_CHANNEL = "com.productivity.habits/widgets"
    private val TIMER_CHANNEL = "com.productivity.habits/focus_timer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        timerChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TIMER_CHANNEL)

        // Widgets Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGETS_CHANNEL).setMethodCallHandler { call, result ->
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
                "getPendingWidgetCheckIns" -> {
                    val prefs = getSharedPreferences("habit_widget_prefs", Context.MODE_PRIVATE)
                    val pendingSet = prefs.getStringSet("pending_toggled_habit_ids", null)
                    val pendingList = pendingSet?.toList() ?: emptyList<String>()
                    prefs.edit().remove("pending_toggled_habit_ids").apply()
                    result.success(pendingList)
                }
                "getPendingCompletedFocusSessions" -> {
                    val prefs = getSharedPreferences("habit_widget_prefs", Context.MODE_PRIVATE)
                    val pendingSet = prefs.getStringSet("pending_completed_focus_sessions", null)
                    val pendingList = pendingSet?.toList() ?: emptyList<String>()
                    prefs.edit().remove("pending_completed_focus_sessions").apply()
                    result.success(pendingList)
                }
                else -> result.notImplemented()
            }
        }

        // Focus Timer Method Channel
        timerChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startTimer" -> {
                    val habitId = call.argument<String>("habitId") ?: ""
                    val habitTitle = call.argument<String>("habitTitle") ?: "Focus Session"
                    val durationMinutes = call.argument<Double>("durationMinutes") ?: 25.0
                    FocusTimerService.startTimer(applicationContext, habitId, habitTitle, durationMinutes)
                    result.success(true)
                }
                "pauseTimer" -> {
                    FocusTimerService.pauseTimer(applicationContext)
                    result.success(true)
                }
                "resumeTimer" -> {
                    FocusTimerService.resumeTimer(applicationContext)
                    result.success(true)
                }
                "stopTimer" -> {
                    FocusTimerService.stopTimer(applicationContext)
                    result.success(true)
                }
                "adjustTimer" -> {
                    val deltaSeconds = (call.argument<Number>("deltaSeconds")?.toLong()) ?: 0L
                    FocusTimerService.adjustTimer(applicationContext, deltaSeconds)
                    result.success(true)
                }
                "getTimerState" -> {
                    val prefs = getSharedPreferences("habit_widget_prefs", Context.MODE_PRIVATE)
                    result.success(prefs.getString("focus_timer", null))
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        if (isFinishing) {
            timerChannel = null
        }
        super.onDestroy()
    }

    companion object {
        @Volatile
        var timerChannel: MethodChannel? = null

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

            // 3. Streaks
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
