package com.productivity.habits.habit_tracker.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
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

    protected fun createPendingIntent(context: Context, appWidgetId: Int): PendingIntent {
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
        var habitsText = "Open app to complete today's habits"

        if (jsonStr != null) {
            try {
                val obj = JSONObject(jsonStr)
                completedCount = obj.optInt("completedCount", 0)
                totalScheduled = obj.optInt("totalScheduled", 0)
                topStreak = obj.optInt("topStreak", 0)
                todayXp = obj.optInt("todayXp", 0)

                val habitsArray = obj.optJSONArray("habits")
                if (habitsArray != null && habitsArray.length() > 0) {
                    val lines = mutableListOf<String>()
                    for (i in 0 until minOf(habitsArray.length(), 4)) {
                        val h = habitsArray.getJSONObject(i)
                        val isDone = h.optBoolean("isCompleted", false)
                        val title = h.optString("title", "")
                        val streak = h.optInt("currentStreak", 0)
                        val check = if (isDone) "✓" else "○"
                        val streakStr = if (streak > 0) " (${streak}d)" else ""
                        lines.add("$check $title$streakStr")
                    }
                    habitsText = lines.joinToString("\n")
                } else if (totalScheduled == 0) {
                    habitsText = "No habits scheduled for today"
                }
            } catch (_: Exception) {}
        }

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, layoutResId).apply {
                setOnClickPendingIntent(R.id.widget_root, createPendingIntent(context, appWidgetId))
                setTextViewText(R.id.tv_habit_counts, "$completedCount/$totalScheduled")
                setTextViewText(R.id.tv_habits_preview, habitsText)
                setTextViewText(R.id.tv_bottom_streak, "Top Streak: ${topStreak}d")
                setTextViewText(R.id.tv_bottom_xp, "+$todayXp XP")
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
                setOnClickPendingIntent(R.id.widget_root, createPendingIntent(context, appWidgetId))
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
    override fun updateWidgets(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("habit_widget_prefs", Context.MODE_PRIVATE)
        val jsonStr = prefs.getString("focus_timer", null)

        var title = "Focus Timer"
        var status = "Ready"
        var countdown = "25:00"
        var progress = 0

        if (jsonStr != null) {
            try {
                val obj = JSONObject(jsonStr)
                title = obj.optString("habitTitle", "Focus Timer")
                status = obj.optString("status", "Ready")
                val remaining = obj.optLong("remainingSeconds", 1500L)
                val m = remaining / 60
                val s = remaining % 60
                countdown = String.format("%02d:%02d", m, s)
                progress = (obj.optDouble("progressFraction", 0.0) * 100).toInt()
            } catch (_: Exception) {}
        }

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, layoutResId).apply {
                setOnClickPendingIntent(R.id.widget_root, createPendingIntent(context, appWidgetId))
                setTextViewText(R.id.tv_timer_title, title)
                setTextViewText(R.id.tv_timer_status, status)
                setTextViewText(R.id.tv_timer_countdown, countdown)
                setProgressBar(R.id.pb_timer_progress, 100, progress, false)
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
                setOnClickPendingIntent(R.id.widget_root, createPendingIntent(context, appWidgetId))
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
                setOnClickPendingIntent(R.id.widget_root, createPendingIntent(context, appWidgetId))
                setTextViewText(R.id.tv_player_level_title, levelTitle)
                setTextViewText(R.id.tv_player_total_xp, totalXpStr)
                setProgressBar(R.id.pb_xp_progress, 100, progress, false)
                setTextViewText(R.id.tv_next_milestone, nextMilestone)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
