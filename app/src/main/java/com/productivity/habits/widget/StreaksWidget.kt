package com.productivity.habits.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.productivity.habits.data.local.dao.HabitCategoryDao
import com.productivity.habits.data.local.dao.HabitDao
import com.productivity.habits.data.local.dao.HabitLogDao
import com.productivity.habits.domain.engine.StreakCalculator
import dagger.hilt.EntryPoint
import dagger.hilt.InstallIn
import dagger.hilt.android.EntryPointAccessors
import dagger.hilt.components.SingletonComponent
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.time.LocalDate
import java.time.format.DateTimeFormatter

data class StreakHabitItem(
    val id: String,
    val title: String,
    val categoryName: String,
    val currentStreak: Int,
    val bestStreak: Int,
    val isScheduledToday: Boolean,
    val isCompletedToday: Boolean
) {
    val isAtRiskToday: Boolean get() = isScheduledToday && !isCompletedToday && currentStreak > 0
}

data class StreaksWidgetData(
    val habits: List<StreakHabitItem>,
    val bestOverallStreak: Int,
    val activeStreaksCount: Int
)

class StreaksWidget : GlanceAppWidget() {

    override val sizeMode: SizeMode = SizeMode.Exact

    @EntryPoint
    @InstallIn(SingletonComponent::class)
    interface StreaksWidgetEntryPoint {
        fun habitDao(): HabitDao
        fun habitLogDao(): HabitLogDao
        fun habitCategoryDao(): HabitCategoryDao
    }

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val entryPoint = EntryPointAccessors.fromApplication(
            context.applicationContext,
            StreaksWidgetEntryPoint::class.java
        )

        provideContent {
            val today = LocalDate.now()
            val todayStr = today.format(DateTimeFormatter.ofPattern("yyyy-MM-dd"))

            val activeHabits by entryPoint.habitDao().getActiveHabits().collectAsState(initial = emptyList())
            val categoriesList by entryPoint.habitCategoryDao().getAllCategories().collectAsState(initial = emptyList())
            val allLogsToday by entryPoint.habitLogDao().getLogsForDate(todayStr).collectAsState(initial = emptyList())
            val allLogs by entryPoint.habitLogDao().getAllLogs().collectAsState(initial = emptyList())

            val categories = categoriesList.associateBy { it.id }
            val logsByHabit = allLogsToday.groupBy { it.habitId }
            val allLogsByHabit = allLogs.groupBy { it.habitId }

            var bestOverall = 0
            val items = mutableListOf<StreakHabitItem>()

            for (habit in activeHabits) {
                val habitLogs = allLogsByHabit[habit.id] ?: emptyList()
                val streakResult = StreakCalculator.calculateStreak(habit, habitLogs, today)
                if (streakResult.bestStreak > bestOverall) {
                    bestOverall = streakResult.bestStreak
                }

                val isScheduled = StreakCalculator.isHabitScheduledOnDate(habit, today)
                val todayLogs = logsByHabit[habit.id] ?: emptyList()
                val isDone = StreakCalculator.isHabitCompletedOnDate(habit, todayLogs)
                val categoryName = categories[habit.categoryId]?.name ?: "General"

                items.add(
                    StreakHabitItem(
                        id = habit.id,
                        title = habit.title,
                        categoryName = categoryName,
                        currentStreak = streakResult.currentStreak,
                        bestStreak = streakResult.bestStreak,
                        isScheduledToday = isScheduled,
                        isCompletedToday = isDone
                    )
                )
            }

            // Sort: 1. Active streaks highest first, 2. At risk first among same streak
            val sorted = items.sortedWith(
                compareByDescending<StreakHabitItem> { it.currentStreak }
                    .thenByDescending { it.isAtRiskToday }
                    .thenByDescending { it.bestStreak }
            )

            val activeCount = sorted.count { it.currentStreak > 0 }

            val data = StreaksWidgetData(
                habits = sorted,
                bestOverallStreak = bestOverall,
                activeStreaksCount = activeCount
            )

            GlanceTheme {
                val layoutSize = resolveWidgetLayoutSize(LocalSize.current)
                when (layoutSize) {
                    WidgetLayoutSize.SMALL -> StreaksSmall(data)
                    WidgetLayoutSize.MEDIUM -> StreaksMedium(data)
                    WidgetLayoutSize.LARGE -> StreaksLarge(data)
                }
            }
        }
    }
}

@Composable
fun StreaksSmall(data: StreaksWidgetData) {
    val topHabit = data.habits.firstOrNull()

    WidgetCard(padding = 10.dp, deepLinkUri = "app://habits/analytics") {
        Column(
            modifier = GlanceModifier.fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            WidgetHeader(
                title = "Streaks",
                badgeText = "${data.bestOverallStreak}d Best",
                badgeColor = WidgetColors.AccentAmber
            )

            Spacer(modifier = GlanceModifier.height(6.dp))

            if (topHabit == null || data.bestOverallStreak == 0) {
                Text(
                    text = "Start a habit streak today",
                    style = TextStyle(
                        color = ColorProvider(WidgetColors.TextSecondary),
                        fontSize = 11.sp
                    )
                )
            } else if (topHabit.isAtRiskToday) {
                Text(
                    text = "${topHabit.currentStreak}d - ${topHabit.title}",
                    maxLines = 1,
                    style = TextStyle(
                        color = ColorProvider(WidgetColors.TextPrimary),
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )
                )
                Spacer(modifier = GlanceModifier.height(2.dp))
                Text(
                    text = "Complete today to keep it",
                    style = TextStyle(
                        color = ColorProvider(WidgetColors.AccentAmber),
                        fontSize = 10.sp
                    )
                )
            } else {
                Text(
                    text = "${topHabit.currentStreak}d - ${topHabit.title}",
                    maxLines = 1,
                    style = TextStyle(
                        color = ColorProvider(WidgetColors.TextPrimary),
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )
                )
                Spacer(modifier = GlanceModifier.height(2.dp))
                Text(
                    text = if (topHabit.isCompletedToday) "Streak secured today" else "${data.activeStreaksCount} active streaks",
                    style = TextStyle(
                        color = ColorProvider(if (topHabit.isCompletedToday) WidgetColors.Success else WidgetColors.TextSecondary),
                        fontSize = 10.sp
                    )
                )
            }
        }
    }
}

@Composable
fun StreaksMedium(data: StreaksWidgetData) {
    WidgetCard(padding = 12.dp) {
        Column(modifier = GlanceModifier.fillMaxSize()) {
            WidgetHeader(
                title = "Streaks",
                badgeText = "${data.bestOverallStreak}d Best",
                badgeColor = WidgetColors.AccentAmber,
                deepLinkUri = "app://habits/analytics"
            )

            Spacer(modifier = GlanceModifier.height(8.dp))

            if (data.habits.isEmpty() || data.activeStreaksCount == 0) {
                WidgetEmptyState(
                    message = "No active streaks yet",
                    actionText = "View Habits",
                    actionDeepLink = "app://habits/daily"
                )
            } else {
                val displayHabits = data.habits.filter { it.currentStreak > 0 }.take(3).ifEmpty { data.habits.take(3) }

                Column(modifier = GlanceModifier.defaultWeight()) {
                    displayHabits.forEach { habit ->
                        StreakMediumRow(habit = habit)
                        Spacer(modifier = GlanceModifier.height(4.dp))
                    }
                }

                Row(
                    modifier = GlanceModifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.End,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Best: ${data.bestOverallStreak} days",
                        style = TextStyle(
                            color = ColorProvider(WidgetColors.TextSecondary),
                            fontSize = 10.sp
                        )
                    )
                }
            }
        }
    }
}

@Composable
fun StreaksLarge(data: StreaksWidgetData) {
    WidgetCard(padding = 12.dp) {
        Column(modifier = GlanceModifier.fillMaxSize()) {
            WidgetHeader(
                title = "Streaks",
                badgeText = "${data.activeStreaksCount} Active",
                badgeColor = WidgetColors.AccentAmber,
                deepLinkUri = "app://habits/analytics"
            )

            Spacer(modifier = GlanceModifier.height(8.dp))

            if (data.habits.isEmpty()) {
                WidgetEmptyState(
                    message = "No habits available",
                    actionText = "Add Habit",
                    actionDeepLink = "app://habits/daily"
                )
            } else {
                val displayHabits = data.habits.take(4)

                Column(modifier = GlanceModifier.defaultWeight()) {
                    displayHabits.forEach { habit ->
                        StreakLargeRow(habit = habit)
                        Spacer(modifier = GlanceModifier.height(4.dp))
                    }
                }

                Spacer(modifier = GlanceModifier.height(4.dp))

                Row(
                    modifier = GlanceModifier
                        .fillMaxWidth()
                        .background(WidgetColors.SurfaceElevated)
                        .cornerRadius(6.dp)
                        .padding(horizontal = 8.dp, vertical = 4.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Top overall streak: ${data.bestOverallStreak} days",
                        style = TextStyle(
                            color = ColorProvider(WidgetColors.AccentAmber),
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Bold
                        )
                    )
                }
            }
        }
    }
}

@Composable
fun StreakMediumRow(habit: StreakHabitItem) {
    Row(
        modifier = GlanceModifier
            .fillMaxWidth()
            .background(WidgetColors.Surface)
            .cornerRadius(8.dp)
            .padding(horizontal = 8.dp, vertical = 4.dp)
            .clickable(actionStartActivity(createDeepLinkIntent("app://habits/detail/${habit.id}"))),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = habit.title,
            maxLines = 1,
            style = TextStyle(
                color = ColorProvider(WidgetColors.TextPrimary),
                fontSize = 12.sp,
                fontWeight = FontWeight.Medium
            ),
            modifier = GlanceModifier.defaultWeight()
        )

        Text(
            text = "${habit.currentStreak}d",
            style = TextStyle(
                color = ColorProvider(if (habit.currentStreak > 0) WidgetColors.AccentAmber else WidgetColors.TextSecondary),
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold
            )
        )
    }
}

@Composable
fun StreakLargeRow(habit: StreakHabitItem) {
    Row(
        modifier = GlanceModifier
            .fillMaxWidth()
            .background(WidgetColors.Surface)
            .cornerRadius(8.dp)
            .padding(horizontal = 8.dp, vertical = 4.dp)
            .clickable(actionStartActivity(createDeepLinkIntent("app://habits/detail/${habit.id}"))),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = GlanceModifier.defaultWeight()) {
            Text(
                text = habit.title,
                maxLines = 1,
                style = TextStyle(
                    color = ColorProvider(WidgetColors.TextPrimary),
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold
                )
            )

            val statusText = when {
                habit.isCompletedToday -> "${habit.currentStreak}d streak secured"
                habit.isAtRiskToday -> "Keep it alive today"
                habit.currentStreak > 0 -> "${habit.currentStreak}d active streak"
                else -> "${habit.categoryName} - No active streak"
            }

            val statusColor = when {
                habit.isCompletedToday -> WidgetColors.Success
                habit.isAtRiskToday -> WidgetColors.AccentAmber
                else -> WidgetColors.TextSecondary
            }

            Text(
                text = statusText,
                style = TextStyle(
                    color = ColorProvider(statusColor),
                    fontSize = 10.sp
                )
            )
        }

        Text(
            text = "${habit.currentStreak}d",
            style = TextStyle(
                color = ColorProvider(if (habit.currentStreak > 0) WidgetColors.AccentAmber else WidgetColors.TextSecondary),
                fontSize = 13.sp,
                fontWeight = FontWeight.Bold
            )
        )
    }
}
