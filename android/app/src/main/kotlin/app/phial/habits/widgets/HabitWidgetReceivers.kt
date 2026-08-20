package app.phial.habits.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import app.phial.habits.MainActivity
import app.phial.habits.R
import org.json.JSONArray
import org.json.JSONObject

abstract class BaseHabitWidgetProvider : AppWidgetProvider() {
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

    protected fun isSmallSize(options: Bundle?): Boolean {
        if (options == null) return false
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        return minWidth < 220 && minHeight < 200
    }

    protected fun isLargeSize(options: Bundle?): Boolean {
        if (options == null) return false
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        return minHeight >= 200
    }
}

class TodaysHabitsWidgetReceiver : BaseHabitWidgetProvider() {
    companion object {
        const val ACTION_TOGGLE_HABIT = "app.phial.habits.widget.ACTION_TOGGLE_HABIT"
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
        val density = context.resources.displayMetrics.density

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

        val ratePercent = if (totalScheduled > 0) ((completedCount.toFloat() / totalScheduled) * 100).toInt() else 0
        val habitCount = habitsArray?.length() ?: 0

        for (appWidgetId in appWidgetIds) {
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val isSmall = isSmallSize(options)
            val isLarge = isLargeSize(options)

            val layoutId = when {
                isSmall -> R.layout.widget_todays_habits_2x2
                isLarge -> R.layout.widget_todays_habits_4x4
                else -> R.layout.widget_todays_habits_2x4
            }

            val views = RemoteViews(context.packageName, layoutId).apply {
                setOnClickPendingIntent(R.id.widget_root, createActivityPendingIntent(context, appWidgetId))

                if (isSmall) {
                    setTextViewText(R.id.tv_todays_habits_count_2x2, "$completedCount/$totalScheduled")
                    setTextViewText(R.id.tv_percent_done_2x2, "$ratePercent% done")

                    val ringBitmap = WidgetGraphicsHelper.drawCircularProgressRing(
                        percentage = ratePercent,
                        subtitle = "",
                        sizeDp = 56,
                        strokeWidthDp = 5f,
                        density = density,
                        showCheckInside = ratePercent >= 100
                    )
                    setImageViewBitmap(R.id.iv_progress_ring_2x2, ringBitmap)

                    val dotsBitmap = WidgetGraphicsHelper.drawHabitStatusDots(
                        total = totalScheduled,
                        completed = completedCount,
                        widthDp = 80,
                        heightDp = 12,
                        density = density
                    )
                    setImageViewBitmap(R.id.iv_status_dots_2x2, dotsBitmap)
                } else if (isLarge) {
                    setOnClickPendingIntent(R.id.ll_todays_habits_header, createActivityPendingIntent(context, appWidgetId))
                    setOnClickPendingIntent(R.id.tv_bottom_add_pill, createDeepLinkPendingIntent(context, appWidgetId, "app://habits/daily"))

                    setTextViewText(R.id.tv_completed_header_4x4, "$completedCount/$totalScheduled completed")
                    setTextViewText(R.id.tv_bottom_streak, "🔥 ${topStreak}d streak")
                    setTextViewText(R.id.tv_bottom_xp, "+$todayXp XP")

                    val ringBitmap = WidgetGraphicsHelper.drawCircularProgressRing(
                        percentage = ratePercent,
                        subtitle = "completed",
                        sizeDp = 85,
                        strokeWidthDp = 7f,
                        density = density
                    )
                    setImageViewBitmap(R.id.iv_progress_ring_4x4, ringBitmap)

                    removeAllViews(R.id.ll_habits_container)
                    if (habitCount == 0) {
                        setViewVisibility(R.id.tv_empty_habits, View.VISIBLE)
                        setViewVisibility(R.id.ll_habits_container, View.GONE)
                    } else {
                        setViewVisibility(R.id.tv_empty_habits, View.GONE)
                        setViewVisibility(R.id.ll_habits_container, View.VISIBLE)

                        val maxDisplay = minOf(habitCount, 6)
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
                } else {
                    // Standard 2x4
                    setOnClickPendingIntent(R.id.ll_todays_habits_header, createActivityPendingIntent(context, appWidgetId))
                    setOnClickPendingIntent(R.id.tv_bottom_add, createDeepLinkPendingIntent(context, appWidgetId, "app://habits/daily"))

                    setTextViewText(R.id.tv_habit_counts, "$completedCount/$totalScheduled")
                    setTextViewText(R.id.tv_bottom_streak, "🔥 ${topStreak}d streak")
                    setTextViewText(R.id.tv_bottom_xp, "+$todayXp XP")

                    removeAllViews(R.id.ll_habits_container)
                    if (habitCount == 0) {
                        setViewVisibility(R.id.tv_empty_habits, View.VISIBLE)
                        setViewVisibility(R.id.ll_habits_container, View.GONE)
                    } else {
                        setViewVisibility(R.id.tv_empty_habits, View.GONE)
                        setViewVisibility(R.id.ll_habits_container, View.VISIBLE)

                        val maxDisplay = minOf(habitCount, 5)
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
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

class DailyFocusWidgetReceiver : BaseHabitWidgetProvider() {
    override fun updateWidgets(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("habit_widget_prefs", Context.MODE_PRIVATE)
        val jsonStr = prefs.getString("daily_focus", null)
        val density = context.resources.displayMetrics.density

        var completedCount = 0
        var totalScheduled = 0
        var ratePercent = 0
        var remainingCount = 0
        var xpEarnedToday = 0
        var nextHabitTitle: String? = null
        var nextHabitStreak = 0
        val weeklyDays = mutableListOf<DayAdherence>()

        if (jsonStr != null) {
            try {
                val obj = JSONObject(jsonStr)
                completedCount = obj.optInt("completedCount", 0)
                totalScheduled = obj.optInt("totalScheduled", 0)
                ratePercent = obj.optInt("ratePercent", 0)
                remainingCount = obj.optInt("remainingCount", (totalScheduled - completedCount).coerceAtLeast(0))
                xpEarnedToday = obj.optInt("xpEarnedToday", 0)
                nextHabitTitle = if (obj.has("nextHabitTitle") && !obj.isNull("nextHabitTitle")) obj.getString("nextHabitTitle") else null
                nextHabitStreak = obj.optInt("nextHabitStreak", 0)

                val historyArr = obj.optJSONArray("weeklyHistory")
                if (historyArr != null) {
                    for (i in 0 until historyArr.length()) {
                        val d = historyArr.getJSONObject(i)
                        weeklyDays.add(
                            DayAdherence(
                                dayLetter = d.optString("dayLetter", "M"),
                                ratePercent = d.optInt("ratePercent", 0),
                                isToday = d.optBoolean("isToday", false),
                                isFuture = d.optBoolean("isFuture", false)
                            )
                        )
                    }
                }
            } catch (_: Exception) {}
        }

        for (appWidgetId in appWidgetIds) {
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val isSmall = isSmallSize(options)
            val isLarge = isLargeSize(options)

            val layoutId = when {
                isSmall -> R.layout.widget_daily_focus_2x2
                isLarge -> R.layout.widget_daily_focus_4x4
                else -> R.layout.widget_daily_focus_2x4
            }

            val views = RemoteViews(context.packageName, layoutId).apply {
                setOnClickPendingIntent(R.id.widget_root, createActivityPendingIntent(context, appWidgetId))

                if (isSmall) {
                    setTextViewText(R.id.tv_progress_ratio_2x2, "$completedCount/$totalScheduled")
                    setProgressBar(R.id.pb_daily_progress_2x2, 100, ratePercent, false)
                    setTextViewText(R.id.tv_remaining_2x2, "$remainingCount left")
                } else if (isLarge) {
                    val ringBitmap = WidgetGraphicsHelper.drawCircularProgressRing(
                        percentage = ratePercent,
                        subtitle = "",
                        sizeDp = 65,
                        strokeWidthDp = 6f,
                        density = density
                    )
                    setImageViewBitmap(R.id.iv_progress_ring_4x4, ringBitmap)

                    setTextViewText(R.id.tv_rate_percent_4x4, "$ratePercent% completed")
                    setTextViewText(R.id.tv_completed_count_4x4, "✓ $completedCount completed")
                    setTextViewText(R.id.tv_remaining_count_4x4, "○ $remainingCount remaining")
                    setTextViewText(R.id.tv_xp_available_4x4, "🏆 +$xpEarnedToday XP available")

                    if (!nextHabitTitle.isNullOrBlank()) {
                        setTextViewText(R.id.tv_next_up_title, nextHabitTitle)
                        setTextViewText(R.id.tv_next_up_streak, "${nextHabitStreak}d streak")
                    } else {
                        setTextViewText(R.id.tv_next_up_title, "All habits done for today")
                        setTextViewText(R.id.tv_next_up_streak, "✓ Done")
                    }

                    val weekChartBitmap = WidgetGraphicsHelper.drawWeeklyBarChart(
                        days = weeklyDays,
                        widthDp = 220,
                        heightDp = 50,
                        density = density
                    )
                    setImageViewBitmap(R.id.iv_weekly_completion_4x4, weekChartBitmap)
                } else {
                    // Standard 2x4
                    setTextViewText(R.id.tv_rate_percent_2x4, "$ratePercent%")
                    setTextViewText(R.id.tv_completed_count_2x4, "$completedCount of $totalScheduled completed")
                    setProgressBar(R.id.pb_daily_progress_2x4, 100, ratePercent, false)
                    setTextViewText(R.id.tv_remaining_2x4, "$remainingCount remaining")
                    setTextViewText(R.id.tv_xp_to_earn_2x4, "+$xpEarnedToday XP to earn")

                    val weekChartBitmap = WidgetGraphicsHelper.drawWeeklyBarChart(
                        days = weeklyDays,
                        widthDp = 110,
                        heightDp = 65,
                        density = density
                    )
                    setImageViewBitmap(R.id.iv_weekly_barchart_2x4, weekChartBitmap)
                }
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

class StreaksWidgetReceiver : BaseHabitWidgetProvider() {
    override fun updateWidgets(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("habit_widget_prefs", Context.MODE_PRIVATE)
        val jsonStr = prefs.getString("streaks", null)
        val density = context.resources.displayMetrics.density

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

        val habitCount = habitsArray?.length() ?: 0

        for (appWidgetId in appWidgetIds) {
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val isSmall = isSmallSize(options)
            val isLarge = isLargeSize(options)

            val layoutId = when {
                isSmall -> R.layout.widget_streaks_2x2
                isLarge -> R.layout.widget_streaks_4x4
                else -> R.layout.widget_streaks_2x4
            }

            val views = RemoteViews(context.packageName, layoutId).apply {
                setOnClickPendingIntent(R.id.widget_root, createActivityPendingIntent(context, appWidgetId))

                if (isSmall) {
                    setTextViewText(R.id.tv_active_streaks_count_2x2, "$activeStreaksCount")
                    val flameBitmap = WidgetGraphicsHelper.drawFlameRow(
                        activeCount = activeStreaksCount,
                        maxDisplay = 5,
                        widthDp = 110,
                        heightDp = 22,
                        density = density
                    )
                    setImageViewBitmap(R.id.iv_flame_row_2x2, flameBitmap)
                } else if (isLarge) {
                    setOnClickPendingIntent(R.id.ll_streaks_header, createActivityPendingIntent(context, appWidgetId))
                    setTextViewText(R.id.tv_active_streaks_badge, "$activeStreaksCount Active")
                    setTextViewText(R.id.tv_bottom_overall_streak, "🔥 Top overall streak: $bestOverall days")

                    removeAllViews(R.id.ll_streaks_container)
                    if (habitCount == 0) {
                        setViewVisibility(R.id.tv_empty_streaks, View.VISIBLE)
                        setViewVisibility(R.id.ll_streaks_container, View.GONE)
                    } else {
                        setViewVisibility(R.id.tv_empty_streaks, View.GONE)
                        setViewVisibility(R.id.ll_streaks_container, View.VISIBLE)

                        val maxDisplay = minOf(habitCount, 6)
                        for (i in 0 until maxDisplay) {
                            val h = habitsArray!!.getJSONObject(i)
                            val id = h.optString("id")
                            val title = h.optString("title")
                            val streak = h.optInt("currentStreak", 0)

                            val historyList = mutableListOf<Boolean>()
                            val historyArr = h.optJSONArray("weeklyHistory")
                            if (historyArr != null) {
                                for (k in 0 until historyArr.length()) {
                                    historyList.add(historyArr.optBoolean(k, false))
                                }
                            }

                            val rowView = RemoteViews(context.packageName, R.layout.widget_item_streak_habit).apply {
                                setTextViewText(R.id.tv_streak_title, title)
                                setTextViewText(R.id.tv_streak_count, "${streak}d")

                                val dotsBitmap = WidgetGraphicsHelper.drawStreakDots(
                                    history = historyList,
                                    widthDp = 70,
                                    heightDp = 12,
                                    density = density
                                )
                                setImageViewBitmap(R.id.iv_streak_dots, dotsBitmap)

                                setOnClickPendingIntent(
                                    R.id.ll_streak_row,
                                    createDeepLinkPendingIntent(context, appWidgetId * 100 + i, "app://habits/detail/$id")
                                )
                            }
                            addView(R.id.ll_streaks_container, rowView)
                        }
                    }
                } else {
                    // Standard 2x4
                    setOnClickPendingIntent(R.id.ll_streaks_header, createActivityPendingIntent(context, appWidgetId))
                    setTextViewText(R.id.tv_active_streaks_badge, "$activeStreaksCount")
                    setTextViewText(R.id.tv_bottom_overall_streak, "🔥 Top overall streak: $bestOverall days")

                    removeAllViews(R.id.ll_streaks_container)
                    if (habitCount == 0) {
                        setViewVisibility(R.id.tv_empty_streaks, View.VISIBLE)
                        setViewVisibility(R.id.ll_streaks_container, View.GONE)
                    } else {
                        setViewVisibility(R.id.tv_empty_streaks, View.GONE)
                        setViewVisibility(R.id.ll_streaks_container, View.VISIBLE)

                        val maxDisplay = minOf(habitCount, 3)
                        for (i in 0 until maxDisplay) {
                            val h = habitsArray!!.getJSONObject(i)
                            val id = h.optString("id")
                            val title = h.optString("title")
                            val streak = h.optInt("currentStreak", 0)

                            val historyList = mutableListOf<Boolean>()
                            val historyArr = h.optJSONArray("weeklyHistory")
                            if (historyArr != null) {
                                for (k in 0 until historyArr.length()) {
                                    historyList.add(historyArr.optBoolean(k, false))
                                }
                            }

                            val rowView = RemoteViews(context.packageName, R.layout.widget_item_streak_habit).apply {
                                setTextViewText(R.id.tv_streak_title, title)
                                setTextViewText(R.id.tv_streak_count, "${streak}d")

                                val dotsBitmap = WidgetGraphicsHelper.drawStreakDots(
                                    history = historyList,
                                    widthDp = 70,
                                    heightDp = 12,
                                    density = density
                                )
                                setImageViewBitmap(R.id.iv_streak_dots, dotsBitmap)

                                setOnClickPendingIntent(
                                    R.id.ll_streak_row,
                                    createDeepLinkPendingIntent(context, appWidgetId * 100 + i, "app://habits/detail/$id")
                                )
                            }
                            addView(R.id.ll_streaks_container, rowView)
                        }
                    }
                }
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

class XpMasteryWidgetReceiver : BaseHabitWidgetProvider() {
    override fun updateWidgets(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("habit_widget_prefs", Context.MODE_PRIVATE)
        val jsonStr = prefs.getString("xp_mastery", null)
        val density = context.resources.displayMetrics.density

        var level = 1
        var title = "Novice"
        var totalXp = 0
        var nextTargetXp = 100
        var progress = 0
        var unlockedBadges = 0
        var totalBadges = 0
        var neededXp = 100

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
                neededXp = obj.optInt("xpNeededForNextLevel", (nextTargetXp - totalXp).coerceAtLeast(0))
            } catch (_: Exception) {}
        }

        for (appWidgetId in appWidgetIds) {
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val isSmall = isSmallSize(options)
            val isLarge = isLargeSize(options)

            val layoutId = when {
                isSmall -> R.layout.widget_xp_mastery_2x2
                isLarge -> R.layout.widget_xp_mastery_4x4
                else -> R.layout.widget_xp_mastery_2x4
            }

            val views = RemoteViews(context.packageName, layoutId).apply {
                setOnClickPendingIntent(R.id.widget_root, createActivityPendingIntent(context, appWidgetId))

                if (isSmall) {
                    val shieldBitmap = WidgetGraphicsHelper.drawLevelShieldBadge(
                        level = level,
                        sizeDp = 52,
                        density = density
                    )
                    setImageViewBitmap(R.id.iv_level_shield_2x2, shieldBitmap)

                    setTextViewText(R.id.tv_rank_title_2x2, title)
                    setTextViewText(R.id.tv_current_xp_2x2, "$totalXp XP")
                    setProgressBar(R.id.pb_xp_progress_2x2, 100, progress, false)
                } else if (isLarge) {
                    val medalBitmap = WidgetGraphicsHelper.drawLevelShieldBadge(
                        level = level,
                        sizeDp = 60,
                        density = density,
                        withRibbon = true
                    )
                    setImageViewBitmap(R.id.iv_level_shield_4x4, medalBitmap)

                    setTextViewText(R.id.tv_level_name_4x4, "Level $level")
                    setTextViewText(R.id.tv_rank_title_4x4, title)
                    setTextViewText(R.id.tv_xp_ratio_4x4, "$totalXp XP / $nextTargetXp")
                    setProgressBar(R.id.pb_xp_progress_4x4, 100, progress, false)

                    setTextViewText(R.id.tv_card_xp_needed, "↗ $neededXp XP\nto Level ${level + 1}")
                    setTextViewText(R.id.tv_card_badges, "⭐ $unlockedBadges/$totalBadges\nBadges")
                    setTextViewText(R.id.tv_card_progress_pct, "○ $progress%\nProgress")

                    setOnClickPendingIntent(
                        R.id.ll_card_badges,
                        createDeepLinkPendingIntent(context, appWidgetId * 100 + 1, "app://habits/badges")
                    )
                } else {
                    // Standard 2x4
                    val shieldBitmap = WidgetGraphicsHelper.drawLevelShieldBadge(
                        level = level,
                        sizeDp = 48,
                        density = density
                    )
                    setImageViewBitmap(R.id.iv_level_shield_2x4, shieldBitmap)

                    setTextViewText(R.id.tv_level_name_2x4, "Level $level")
                    setTextViewText(R.id.tv_rank_title_2x4, title)
                    setTextViewText(R.id.tv_xp_ratio_2x4, "$totalXp XP / $nextTargetXp")
                    setProgressBar(R.id.pb_xp_progress_2x4, 100, progress, false)

                    setTextViewText(R.id.tv_xp_needed_2x4, "$neededXp XP to Level ${level + 1}")
                    setTextViewText(R.id.tv_badges_count_2x4, "🏆 $unlockedBadges/$totalBadges Badges")
                }
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
