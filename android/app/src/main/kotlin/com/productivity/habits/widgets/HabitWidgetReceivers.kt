package com.productivity.habits.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Paint
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import com.productivity.habits.FocusTimerService
import com.productivity.habits.MainActivity
import com.productivity.habits.R
import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale

import android.os.Bundle

abstract class BaseHabitWidgetProvider(protected val layoutResId: Int) : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        updateWidgets(context, appWidgetManager, appWidgetIds)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateWidgets(context, appWidgetManager, intArrayOf(appWidgetId))
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

    protected fun createDeepLinkPendingIntent(context: Context, appWidgetId: Int, uriStr: String): PendingIntent {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uriStr), context, MainActivity::class.java).apply {
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
        const val EXTRA_AUTH_TOKEN = "extra_auth_token"

        fun getOrCreateWidgetToken(context: Context): String {
            val prefs = context.getSharedPreferences("habit_widget_prefs", Context.MODE_PRIVATE)
            var token = prefs.getString("widget_auth_token", null)
            if (token == null) {
                token = java.util.UUID.randomUUID().toString()
                prefs.edit().putString("widget_auth_token", token).apply()
            }
            return token
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_TOGGLE_HABIT) {
            val token = intent.getStringExtra(EXTRA_AUTH_TOKEN)
            val expectedToken = getOrCreateWidgetToken(context)
            if (token == null || token != expectedToken) {
                return
            }

            val habitId = intent.getStringExtra(EXTRA_HABIT_ID)
            if (!habitId.isNullOrBlank()) {
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

            val currentPending = prefs.getStringSet("pending_toggled_habit_ids", null)?.toMutableSet() ?: mutableSetOf()
            if (currentPending.contains(habitId)) {
                currentPending.remove(habitId)
            } else {
                currentPending.add(habitId)
            }

            prefs.edit()
                .putString("todays_habits", obj.toString())
                .putStringSet("pending_toggled_habit_ids", currentPending)
                .apply()

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

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, layoutResId).apply {
                setOnClickPendingIntent(R.id.widget_root, createActivityPendingIntent(context, appWidgetId))
                setOnClickPendingIntent(R.id.ll_todays_habits_header, createActivityPendingIntent(context, appWidgetId))
                setOnClickPendingIntent(R.id.tv_bottom_add, createDeepLinkPendingIntent(context, appWidgetId, "app://habits/daily"))

                setTextViewText(R.id.tv_habit_counts, "$completedCount/$totalScheduled")
                setTextViewText(R.id.tv_bottom_streak, if (topStreak > 0) "${topStreak}d streak" else "0d streak")
                setTextViewText(R.id.tv_bottom_xp, "+$todayXp XP")

                // Clear previous dynamically added rows
                removeAllViews(R.id.ll_habits_container)

                val count = habitsArray?.length() ?: 0
                if (count == 0) {
                    setViewVisibility(R.id.tv_empty_habits, View.VISIBLE)
                    setViewVisibility(R.id.ll_habits_container, View.GONE)
                } else {
                    setViewVisibility(R.id.tv_empty_habits, View.GONE)
                    setViewVisibility(R.id.ll_habits_container, View.VISIBLE)

                    // Add dynamic rows for all scheduled habits (up to 8 items to fit nicely)
                    val maxDisplay = minOf(count, 8)
                    for (i in 0 until maxDisplay) {
                        val h = habitsArray!!.getJSONObject(i)
                        val id = h.optString("id")
                        val title = h.optString("title")
                        val isDone = h.optBoolean("isCompleted", false)
                        val streak = h.optInt("currentStreak", 0)

                        val rowView = RemoteViews(context.packageName, R.layout.widget_item_todays_habit).apply {
                            setTextViewText(R.id.tv_habit_check, if (isDone) "✓" else "○")
                            setTextColor(
                                R.id.tv_habit_check,
                                if (isDone) Color.parseColor("#10B981") else Color.parseColor("#9EADA9")
                            )

                            setTextViewText(R.id.tv_habit_title, title)
                            setTextColor(
                                R.id.tv_habit_title,
                                if (isDone) Color.parseColor("#10B981") else Color.parseColor("#F1F5F4")
                            )

                            setTextViewText(R.id.tv_habit_streak, if (streak > 0) "${streak}d" else "")

                            // Toggle click pending intent
                            val toggleIntent = Intent(context, TodaysHabitsWidgetReceiver::class.java).apply {
                                action = ACTION_TOGGLE_HABIT
                                `package` = context.packageName
                                putExtra(EXTRA_HABIT_ID, id)
                                putExtra(EXTRA_AUTH_TOKEN, getOrCreateWidgetToken(context))
                            }
                            val togglePendingIntent = PendingIntent.getBroadcast(
                                context,
                                (appWidgetId * 100) + i,
                                toggleIntent,
                                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                            )
                            setOnClickPendingIntent(R.id.ll_habit_row, togglePendingIntent)
                        }

                        addView(R.id.ll_habits_container, rowView)
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
        var focusMinutes = 0
        var xpEarnedToday = 0

        if (jsonStr != null) {
            try {
                val obj = JSONObject(jsonStr)
                completedCount = obj.optInt("completedCount", 0)
                totalScheduled = obj.optInt("totalScheduled", 0)
                ratePercent = obj.optInt("ratePercent", 0)
                bestStreak = obj.optInt("bestStreak", 0)
                focusMinutes = obj.optInt("focusMinutes", 0)
                xpEarnedToday = obj.optInt("xpEarnedToday", 0)
            } catch (_: Exception) {}
        }

        val focusTimeStr = if (focusMinutes >= 60) {
            String.format(Locale.getDefault(), "%dh %02dm", focusMinutes / 60, focusMinutes % 60)
        } else {
            "${focusMinutes}m"
        }

        for (appWidgetId in appWidgetIds) {
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val minHeight = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0) ?: 0
            val isExpanded = minHeight >= 140

            val views = RemoteViews(context.packageName, layoutResId).apply {
                setOnClickPendingIntent(R.id.widget_root, createActivityPendingIntent(context, appWidgetId))
                setTextViewText(R.id.tv_adherence_percent, "$ratePercent% Completed")
                setTextViewText(R.id.tv_completed_count, "$completedCount / $totalScheduled completed")
                setProgressBar(R.id.pb_daily_progress, 100, ratePercent, false)

                setViewVisibility(R.id.ll_daily_cards, if (isExpanded) View.VISIBLE else View.GONE)
                if (isExpanded) {
                    setTextViewText(R.id.tv_card_best_streak, "$bestStreak days")
                    setTextViewText(R.id.tv_card_focus_time, focusTimeStr)
                    setTextViewText(R.id.tv_card_xp_earned, "+$xpEarnedToday")
                }
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
        var habitsArray: JSONArray? = null

        if (jsonStr != null) {
            try {
                val obj = JSONObject(jsonStr)
                bestOverall = obj.optInt("bestOverallStreak", 0)
                activeStreaksCount = obj.optInt("activeStreaksCount", 0)
                habitsArray = obj.optJSONArray("habits")
            } catch (_: Exception) {}
        }

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, layoutResId).apply {
                setOnClickPendingIntent(R.id.widget_root, createActivityPendingIntent(context, appWidgetId))
                setOnClickPendingIntent(R.id.ll_streaks_header, createActivityPendingIntent(context, appWidgetId))

                setTextViewText(R.id.tv_active_streaks_badge, "$activeStreaksCount Active")
                setTextViewText(R.id.tv_bottom_overall_streak, "Top overall streak: $bestOverall days")

                removeAllViews(R.id.ll_streaks_container)

                val count = habitsArray?.length() ?: 0
                if (count == 0) {
                    setViewVisibility(R.id.tv_empty_streaks, View.VISIBLE)
                    setViewVisibility(R.id.ll_streaks_container, View.GONE)
                } else {
                    setViewVisibility(R.id.tv_empty_streaks, View.GONE)
                    setViewVisibility(R.id.ll_streaks_container, View.VISIBLE)

                    val maxDisplay = minOf(count, 5)
                    for (i in 0 until maxDisplay) {
                        val h = habitsArray!!.getJSONObject(i)
                        val id = h.optString("id")
                        val title = h.optString("title")
                        val streak = h.optInt("currentStreak", 0)
                        val isDone = h.optBoolean("isCompletedToday", false)
                        val isAtRisk = h.optBoolean("isAtRiskToday", false)

                        val statusText = when {
                            isDone -> "${streak}d streak secured"
                            isAtRisk -> "Keep it alive today"
                            streak > 0 -> "${streak}d active streak"
                            else -> "No active streak"
                        }

                        val rowView = RemoteViews(context.packageName, R.layout.widget_item_streak_habit).apply {
                            setTextViewText(R.id.tv_streak_title, title)
                            setTextViewText(R.id.tv_streak_status, statusText)
                            setTextColor(
                                R.id.tv_streak_status,
                                when {
                                    isDone -> Color.parseColor("#10B981")
                                    isAtRisk -> Color.parseColor("#F59E0B")
                                    else -> Color.parseColor("#9EADA9")
                                }
                            )
                            setTextViewText(R.id.tv_streak_count, "${streak}d")
                            setTextColor(
                                R.id.tv_streak_count,
                                if (streak > 0) Color.parseColor("#F59E0B") else Color.parseColor("#9EADA9")
                            )

                            setOnClickPendingIntent(
                                R.id.ll_streak_row,
                                createDeepLinkPendingIntent(context, appWidgetId * 100 + i, "app://habits/detail/$id")
                            )
                        }

                        addView(R.id.ll_streaks_container, rowView)
                    }
                }
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

        var level = 1
        var title = "Novice"
        var totalXp = 0
        var nextTargetXp = 100
        var progress = 0
        var unlockedBadges = 0
        var totalBadges = 0
        var neededXp = 100
        var nextTitleName = "Apprentice"
        var nextBadgeName = "Habit Pioneer"
        var nextBadgeProgress = 0
        var nextBadgeTarget = 5
        var nextBadgeUnit = "days"
        var streakMultiplier = "1.0x"

        if (jsonStr != null) {
            try {
                val obj = JSONObject(jsonStr)
                level = obj.optInt("level", 1)
                title = obj.optString("titleDisplayName", "Novice")
                totalXp = obj.optInt("totalXp", 0)
                nextTargetXp = obj.optInt("nextLevelTargetXp", 100)
                progress = (obj.optDouble("progressFraction", 0.0) * 100).toInt()
                unlockedBadges = obj.optInt("unlockedBadgesCount", 0)
                totalBadges = obj.optInt("totalBadgesCount", 0)
                neededXp = obj.optInt("xpNeededForNextLevel", nextTargetXp - totalXp)
                nextTitleName = obj.optString("nextTitleDisplayName", "Level ${level + 1}")
                nextBadgeName = obj.optString("nextBadgeTitle", "Next Badge")
                nextBadgeProgress = obj.optInt("nextBadgeProgress", 0)
                nextBadgeTarget = obj.optInt("nextBadgeTarget", 10)
                nextBadgeUnit = obj.optString("nextBadgeUnit", "days")
                val mult = obj.optDouble("activeStreakMultiplier", 1.0)
                streakMultiplier = String.format(Locale.getDefault(), "%.1fx Multiplier", mult)
            } catch (_: Exception) {}
        }

        for (appWidgetId in appWidgetIds) {
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val minHeight = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0) ?: 0
            val isExpanded = minHeight >= 140

            val views = RemoteViews(context.packageName, layoutResId).apply {
                setOnClickPendingIntent(R.id.widget_root, createActivityPendingIntent(context, appWidgetId))
                setOnClickPendingIntent(R.id.ll_card_next_badge, createDeepLinkPendingIntent(context, appWidgetId * 100 + 1, "app://habits/badges"))
                setOnClickPendingIntent(R.id.ll_card_next_level, createDeepLinkPendingIntent(context, appWidgetId * 100 + 2, "app://habits/badges"))

                setTextViewText(R.id.tv_player_level_title, "Lv.$level $title")
                setTextViewText(R.id.tv_player_badges_badge, "$unlockedBadges/$totalBadges Badges")
                setTextViewText(R.id.tv_player_xp_ratio, "$totalXp / $nextTargetXp XP")
                setTextViewText(R.id.tv_player_xp_percent, "$progress%")
                setProgressBar(R.id.pb_xp_progress, 100, progress, false)

                setViewVisibility(R.id.ll_xp_cards, if (isExpanded) View.VISIBLE else View.GONE)
                if (isExpanded) {
                    // Card 1: Next Badge
                    setTextViewText(R.id.tv_badge_card_title, nextBadgeName)
                    setTextViewText(R.id.tv_badge_card_progress, "$nextBadgeProgress / $nextBadgeTarget $nextBadgeUnit")

                    // Card 2: Next Milestone
                    setTextViewText(R.id.tv_level_card_label, "NEXT: ${nextTitleName.uppercase(Locale.getDefault())}")
                    setTextViewText(R.id.tv_level_card_needed, "$neededXp XP needed")
                    setTextViewText(R.id.tv_level_card_multiplier, streakMultiplier)
                }
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
