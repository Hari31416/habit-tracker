package com.productivity.habits.habit_tracker.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import com.productivity.habits.habit_tracker.MainActivity
import com.productivity.habits.habit_tracker.R
import org.json.JSONArray
import org.json.JSONObject

abstract class BaseHabitWidgetProvider(protected val layoutResId: Int) : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        updateWidgets(context, appWidgetManager, appWidgetIds)
    }

    abstract fun updateWidgets(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    )

    protected fun createActivityPendingIntent(context: Context, appWidgetId: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            appWidgetId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}

class TodaysHabitsWidgetReceiver : BaseHabitWidgetProvider(R.layout.widget_todays_habits) {
    companion object {
        const val ACTION_TOGGLE_HABIT = "com.productivity.habits.widget.ACTION_TOGGLE_HABIT"
        const val EXTRA_HABIT_ID = "extra_habit_id"
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_TOGGLE_HABIT) {
            val habitId = intent.getStringExtra(EXTRA_HABIT_ID)
            if (habitId != null) {
                toggleHabitInPreferences(context, habitId)
            }
        }
    }

    private fun toggleHabitInPreferences(context: Context, habitId: String) {
        val prefs = context.getSharedPreferences("habit_widget_prefs", Context.MODE_PRIVATE)
        val jsonStr = prefs.getString("todays_habits", null) ?: return
        try {
            val obj = JSONObject(jsonStr)
            val habitsArray = obj.optJSONArray("habits") ?: return
            var completedCount = 0
            for (i in 0 until habitsArray.length()) {
                val h = habitsArray.getJSONObject(i)
                if (h.optString("id") == habitId) {
                    val currentDone = h.optBoolean("isCompleted", false)
                    val newDone = !currentDone
                    h.put("isCompleted", newDone)
                    val curStreak = h.optInt("currentStreak", 0)
                    if (newDone) {
                        h.put("currentStreak", curStreak + 1)
                    } else if (curStreak > 0) {
                        h.put("currentStreak", curStreak - 1)
                    }
                }
                if (h.optBoolean("isCompleted", false)) {
                    completedCount++
                }
            }
            obj.put("completedCount", completedCount)
            prefs.edit().putString("todays_habits", obj.toString()).apply()

            val appWidgetManager = AppWidgetManager.getInstance(context)
            val ids = appWidgetManager.getAppWidgetIds(
                ComponentName(context, TodaysHabitsWidgetReceiver::class.java)
            )
            updateWidgets(context, appWidgetManager, ids)
        } catch (_: Exception) {}
    }

    override fun updateWidgets(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("habit_widget_prefs", Context.MODE_PRIVATE)
        val jsonStr = prefs.getString("todays_habits", null)

        var completedCount = 0
        var totalScheduled = 0
        var topStreak = 0
        var todayXp = 0
        var habitsArray: JSONArray? = null

        if (jsonStr != null) {
            try {
                val obj = JSONObject(jsonStr)
                completedCount = obj.optInt("completedCount", 0)
                totalScheduled = obj.optInt("totalScheduled", 0)
                topStreak = obj.optInt("topStreak", 0)
                todayXp = obj.optInt("todayXp", 0)
                habitsArray = obj.optJSONArray("habits")
            } catch (_: Exception) {}
        }

        val rowLayoutIds = intArrayOf(
            R.id.ll_habit_row_0,
            R.id.ll_habit_row_1,
            R.id.ll_habit_row_2,
            R.id.ll_habit_row_3
        )
        val checkViewIds = intArrayOf(
            R.id.tv_habit_check_0,
            R.id.tv_habit_check_1,
            R.id.tv_habit_check_2,
            R.id.tv_habit_check_3
        )
        val titleViewIds = intArrayOf(
            R.id.tv_habit_title_0,
            R.id.tv_habit_title_1,
            R.id.tv_habit_title_2,
            R.id.tv_habit_title_3
        )
        val streakViewIds = intArrayOf(
            R.id.tv_habit_streak_0,
            R.id.tv_habit_streak_1,
            R.id.tv_habit_streak_2,
            R.id.tv_habit_streak_3
        )

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, layoutResId).apply {
                setOnClickPendingIntent(
                    R.id.widget_root,
                    createActivityPendingIntent(context, appWidgetId)
                )
                setOnClickPendingIntent(
                    R.id.ll_todays_habits_header,
                    createActivityPendingIntent(context, appWidgetId)
                )
                setTextViewText(R.id.tv_habit_counts, "$completedCount/$totalScheduled")
                setTextViewText(R.id.tv_bottom_streak, "Top Streak: ${topStreak}d")
                setTextViewText(R.id.tv_bottom_xp, "+$todayXp XP")

                val count = habitsArray?.length() ?: 0
                if (count == 0) {
                    setViewVisibility(R.id.tv_empty_habits, View.VISIBLE)
                    for (rowId in rowLayoutIds) {
                        setViewVisibility(rowId, View.GONE)
                    }
                } else {
                    setViewVisibility(R.id.tv_empty_habits, View.GONE)
                    for (i in 0..3) {
                        if (i < count) {
                            val h = habitsArray!!.getJSONObject(i)
                            val id = h.optString("id")
                            val title = h.optString("title")
                            val isDone = h.optBoolean("isCompleted", false)
                            val streak = h.optInt("currentStreak", 0)

                            setViewVisibility(rowLayoutIds[i], View.VISIBLE)
                            setTextViewText(checkViewIds[i], if (isDone) "✓" else "○")
                            setTextColor(
                                checkViewIds[i],
                                if (isDone) Color.parseColor("#10B981") else Color.parseColor("#9EADA9")
                            )
                            setTextViewText(titleViewIds[i], title)
                            setTextViewText(streakViewIds[i], if (streak > 0) "🔥 ${streak}d" else "")

                            // Clickable row toggle
                            val toggleIntent = Intent(context, TodaysHabitsWidgetReceiver::class.java).apply {
                                action = ACTION_TOGGLE_HABIT
                                putExtra(EXTRA_HABIT_ID, id)
                            }
                            val togglePendingIntent = PendingIntent.getBroadcast(
                                context,
                                (appWidgetId * 10) + i,
                                toggleIntent,
                                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                            )
                            setOnClickPendingIntent(rowLayoutIds[i], togglePendingIntent)
                        } else {
                            setViewVisibility(rowLayoutIds[i], View.GONE)
                        }
                    }
                }
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

class DailyFocusWidgetReceiver : BaseHabitWidgetProvider(R.layout.widget_daily_focus) {
    override fun updateWidgets(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("habit_widget_prefs", Context.MODE_PRIVATE)
        val jsonStr = prefs.getString("daily_focus", null)

        var completedCount = 0
        var totalScheduled = 0
        var ratePercent = 0
        var bestStreak = 0

        if (jsonStr != null) {
            try {
                val obj = JSONObject(jsonStr)
                completedCount = obj.optInt("completedCount", 0)
                totalScheduled = obj.optInt("totalScheduled", 0)
                ratePercent = obj.optInt("ratePercent", 0)
                bestStreak = obj.optInt("bestStreak", 0)
            } catch (_: Exception) {}
        }

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, layoutResId).apply {
                setOnClickPendingIntent(R.id.widget_root, createActivityPendingIntent(context, appWidgetId))
                setTextViewText(R.id.tv_adherence_percent, "$ratePercent%")
                setTextViewText(R.id.tv_completed_count, "$completedCount / $totalScheduled Completed")
                setProgressBar(R.id.pb_daily_progress, 100, ratePercent, false)
                setTextViewText(R.id.tv_best_streak, "Best Streak: $bestStreak days")
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

class FocusTimerWidgetReceiver : BaseHabitWidgetProvider(R.layout.widget_focus_timer) {
    companion object {
        const val ACTION_TIMER_START_PAUSE = "com.productivity.habits.widget.ACTION_TIMER_START_PAUSE"
        const val ACTION_TIMER_RESET = "com.productivity.habits.widget.ACTION_TIMER_RESET"
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val prefs = context.getSharedPreferences("habit_widget_prefs", Context.MODE_PRIVATE)
        val jsonStr = prefs.getString("focus_timer", null) ?: return

        when (intent.action) {
            ACTION_TIMER_START_PAUSE -> {
                try {
                    val obj = JSONObject(jsonStr)
                    val status = obj.optString("status", "Ready")
                    val newStatus = if (status.equals("Running", ignoreCase = true)) "Paused" else "Running"
                    obj.put("status", newStatus)
                    prefs.edit().putString("focus_timer", obj.toString()).apply()

                    val appWidgetManager = AppWidgetManager.getInstance(context)
                    val ids = appWidgetManager.getAppWidgetIds(
                        ComponentName(context, FocusTimerWidgetReceiver::class.java)
                    )
                    updateWidgets(context, appWidgetManager, ids)
                } catch (_: Exception) {}
            }
            ACTION_TIMER_RESET -> {
                try {
                    val obj = JSONObject(jsonStr)
                    val totalSec = obj.optLong("totalSeconds", 1500L)
                    obj.put("remainingSeconds", totalSec)
                    obj.put("status", "Ready")
                    obj.put("progressFraction", 0.0)
                    prefs.edit().putString("focus_timer", obj.toString()).apply()

                    val appWidgetManager = AppWidgetManager.getInstance(context)
                    val ids = appWidgetManager.getAppWidgetIds(
                        ComponentName(context, FocusTimerWidgetReceiver::class.java)
                    )
                    updateWidgets(context, appWidgetManager, ids)
                } catch (_: Exception) {}
            }
        }
    }

    override fun updateWidgets(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("habit_widget_prefs", Context.MODE_PRIVATE)
        val jsonStr = prefs.getString("focus_timer", null)

        var title = "Deep Work Session"
        var status = "Ready"
        var countdown = "25:00"
        var progress = 0

        if (jsonStr != null) {
            try {
                val obj = JSONObject(jsonStr)
                title = obj.optString("habitTitle", "Deep Work Session")
                status = obj.optString("status", "Ready")
                val remaining = obj.optLong("remainingSeconds", 1500L)
                val m = remaining / 60
                val s = remaining % 60
                countdown = String.format("%02d:%02d", m, s)
                progress = (obj.optDouble("progressFraction", 0.0) * 100).toInt()
            } catch (_: Exception) {}
        }

        val buttonText = if (status.equals("Running", ignoreCase = true)) "Pause" else "Start"

        for (appWidgetId in appWidgetIds) {
            val startPauseIntent = Intent(context, FocusTimerWidgetReceiver::class.java).apply {
                action = ACTION_TIMER_START_PAUSE
            }
            val startPausePendingIntent = PendingIntent.getBroadcast(
                context,
                appWidgetId * 100 + 1,
                startPauseIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val resetIntent = Intent(context, FocusTimerWidgetReceiver::class.java).apply {
                action = ACTION_TIMER_RESET
            }
            val resetPendingIntent = PendingIntent.getBroadcast(
                context,
                appWidgetId * 100 + 2,
                resetIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val views = RemoteViews(context.packageName, layoutResId).apply {
                setOnClickPendingIntent(R.id.widget_root, createActivityPendingIntent(context, appWidgetId))
                setOnClickPendingIntent(R.id.ll_timer_header, createActivityPendingIntent(context, appWidgetId))
                setOnClickPendingIntent(R.id.tv_timer_countdown, createActivityPendingIntent(context, appWidgetId))
                setTextViewText(R.id.tv_timer_title, title)
                setTextViewText(R.id.tv_timer_status, status)
                setTextViewText(R.id.tv_timer_countdown, countdown)
                setProgressBar(R.id.pb_timer_progress, 100, progress, false)
                setTextViewText(R.id.btn_timer_action, buttonText)
                setOnClickPendingIntent(R.id.btn_timer_action, startPausePendingIntent)
                setOnClickPendingIntent(R.id.btn_timer_reset, resetPendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

class StreaksWidgetReceiver : BaseHabitWidgetProvider(R.layout.widget_streaks) {
    override fun updateWidgets(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("habit_widget_prefs", Context.MODE_PRIVATE)
        val jsonStr = prefs.getString("streaks", null)

        var bestOverall = 0
        var activeStreaksCount = 0
        var leadText = "Keep streaks alive today"

        if (jsonStr != null) {
            try {
                val obj = JSONObject(jsonStr)
                bestOverall = obj.optInt("bestOverallStreak", 0)
                activeStreaksCount = obj.optInt("activeStreaksCount", 0)
                val habitsArray = obj.optJSONArray("habits")
                if (habitsArray != null && habitsArray.length() > 0) {
                    val top = habitsArray.getJSONObject(0)
                    val title = top.optString("title", "")
                    val streak = top.optInt("currentStreak", 0)
                    if (streak > 0) {
                        leadText = "$title: ${streak}d active streak"
                    }
                }
            } catch (_: Exception) {}
        }

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, layoutResId).apply {
                setOnClickPendingIntent(R.id.widget_root, createActivityPendingIntent(context, appWidgetId))
                setTextViewText(R.id.tv_best_streak_badge, "${bestOverall}d Best")
                setTextViewText(R.id.tv_streak_lead, leadText)
                setTextViewText(R.id.tv_streak_sub, "$activeStreaksCount active streaks")
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

class XpMasteryWidgetReceiver : BaseHabitWidgetProvider(R.layout.widget_xp_mastery) {
    override fun updateWidgets(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("habit_widget_prefs", Context.MODE_PRIVATE)
        val jsonStr = prefs.getString("xp_mastery", null)

        var levelTitle = "Lv.1 Novice"
        var totalXpStr = "0 XP"
        var progress = 0
        var nextMilestone = "Next Level at 100 XP"

        if (jsonStr != null) {
            try {
                val obj = JSONObject(jsonStr)
                val level = obj.optInt("level", 1)
                val title = obj.optString("titleDisplayName", "Novice")
                val xp = obj.optInt("totalXp", 0)
                val needed = obj.optInt("xpNeededForNextLevel", 100)
                val fraction = obj.optDouble("progressFraction", 0.0)

                levelTitle = "Lv.$level $title"
                totalXpStr = "$xp XP"
                progress = (fraction * 100).toInt()
                nextMilestone = "$needed XP to Next Level"
            } catch (_: Exception) {}
        }

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, layoutResId).apply {
                setOnClickPendingIntent(R.id.widget_root, createActivityPendingIntent(context, appWidgetId))
                setTextViewText(R.id.tv_player_level_title, levelTitle)
                setTextViewText(R.id.tv_player_total_xp, totalXpStr)
                setProgressBar(R.id.pb_xp_progress, 100, progress, false)
                setTextViewText(R.id.tv_next_milestone, nextMilestone)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
