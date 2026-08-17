package com.productivity.habits.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.LocalSize
import androidx.glance.action.ActionParameters
import androidx.glance.action.actionParametersOf
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
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
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.productivity.habits.data.local.dao.HabitCategoryDao
import com.productivity.habits.data.local.dao.HabitDao
import com.productivity.habits.data.local.dao.HabitLogDao
import com.productivity.habits.domain.engine.StreakCalculator
import com.productivity.habits.domain.gamification.GamificationEngine
import com.productivity.habits.domain.repository.HabitRepository
import dagger.hilt.EntryPoint
import dagger.hilt.InstallIn
import dagger.hilt.android.EntryPointAccessors
import dagger.hilt.components.SingletonComponent
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.time.LocalDate
import java.time.format.DateTimeFormatter

data class TodaysHabitItem(
    val id: String,
    val title: String,
    val categoryName: String,
    val colorHex: String,
    val isCompleted: Boolean,
    val currentStreak: Int,
    val pinned: Boolean
)

data class TodaysHabitsWidgetData(
    val habits: List<TodaysHabitItem>,
    val completedCount: Int,
    val totalScheduled: Int,
    val topStreak: Int,
    val todayXp: Long
)

class TodaysHabitsWidget : GlanceAppWidget() {

    override val sizeMode: SizeMode = SizeMode.Exact

    @EntryPoint
    @InstallIn(SingletonComponent::class)
    interface TodaysHabitsEntryPoint {
        fun habitDao(): HabitDao
        fun habitLogDao(): HabitLogDao
        fun habitCategoryDao(): HabitCategoryDao
    }

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val entryPoint = EntryPointAccessors.fromApplication(
            context.applicationContext,
            TodaysHabitsEntryPoint::class.java
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

            var completedCount = 0
            var scheduledCount = 0
            var maxStreak = 0
            var totalXp = 0L

            val scheduledItems = mutableListOf<TodaysHabitItem>()

            for (habit in activeHabits) {
                val isScheduled = StreakCalculator.isHabitScheduledOnDate(habit, today)
                val habitLogs = allLogsByHabit[habit.id] ?: emptyList()
                val streakResult = StreakCalculator.calculateStreak(habit, habitLogs, today)
                if (streakResult.currentStreak > maxStreak) {
                    maxStreak = streakResult.currentStreak
                }

                if (isScheduled) {
                    scheduledCount++
                    val todayLogs = logsByHabit[habit.id] ?: emptyList()
                    val isDone = StreakCalculator.isHabitCompletedOnDate(habit, todayLogs)
                    if (isDone) {
                        completedCount++
                    }

                    val baseXp = GamificationEngine.calculateHabitDayBaseXp(habit, todayLogs, isDone)
                    val mult = GamificationEngine.calculateStreakMultiplier(streakResult.currentStreak)
                    totalXp += GamificationEngine.applyMultiplier(baseXp, mult)

                    val category = categories[habit.categoryId]?.name ?: "General"

                    scheduledItems.add(
                        TodaysHabitItem(
                            id = habit.id,
                            title = habit.title,
                            categoryName = category,
                            colorHex = habit.color,
                            isCompleted = isDone,
                            currentStreak = streakResult.currentStreak,
                            pinned = habit.pinned
                        )
                    )
                }
            }

            // Stable ordering: Pinned habits first, then by title
            val sorted = scheduledItems.sortedWith(
                compareByDescending<TodaysHabitItem> { it.pinned }
                    .thenBy { it.title }
            )

            val data = TodaysHabitsWidgetData(
                habits = sorted,
                completedCount = completedCount,
                totalScheduled = scheduledCount,
                topStreak = maxStreak,
                todayXp = totalXp
            )

            GlanceTheme {
                val layoutSize = resolveWidgetLayoutSize(LocalSize.current)
                when (layoutSize) {
                    WidgetLayoutSize.SMALL -> TodaysHabitsSmall(data)
                    WidgetLayoutSize.MEDIUM -> TodaysHabitsMedium(data)
                    WidgetLayoutSize.LARGE -> TodaysHabitsLarge(data)
                }
            }
        }
    }
}

val HabitToggleIdKey = ActionParameters.Key<String>("toggle_habit_id")

class TodaysHabitToggleCallback : ActionCallback {
    @EntryPoint
    @InstallIn(SingletonComponent::class)
    interface ToggleEntryPoint {
        fun repository(): HabitRepository
    }

    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters
    ) {
        val habitId = parameters[HabitToggleIdKey] ?: return
        val entryPoint = EntryPointAccessors.fromApplication(
            context.applicationContext,
            ToggleEntryPoint::class.java
        )

        withContext(Dispatchers.IO) {
            entryPoint.repository().toggleBooleanCheckIn(habitId, LocalDate.now())
        }

        WidgetUpdater.updateAllWidgets(context)
    }
}

@Composable
fun TodaysHabitsSmall(data: TodaysHabitsWidgetData) {
    WidgetCard(padding = 10.dp) {
        Column(modifier = GlanceModifier.fillMaxSize()) {
            WidgetHeader(
                title = "Today's Habits",
                badgeText = "${data.completedCount}/${data.totalScheduled}",
                deepLinkUri = "app://habits/daily"
            )

            Spacer(modifier = GlanceModifier.height(6.dp))

            if (data.habits.isEmpty()) {
                WidgetEmptyState(
                    message = "No habits scheduled",
                    actionText = "+ Add Habit",
                    actionDeepLink = "app://habits/daily"
                )
            } else {
                val displayHabits = data.habits.take(2)
                val remaining = data.habits.size - displayHabits.size

                Column(
                    modifier = GlanceModifier.fillMaxSize(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    displayHabits.forEach { habit ->
                        TodaysHabitCompactRow(habit = habit)
                        Spacer(modifier = GlanceModifier.height(4.dp))
                    }

                    if (remaining > 0) {
                        Row(
                            modifier = GlanceModifier.fillMaxWidth(),
                            horizontalAlignment = Alignment.End
                        ) {
                            Text(
                                text = "+$remaining more",
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
    }
}

@Composable
fun TodaysHabitsMedium(data: TodaysHabitsWidgetData) {
    WidgetCard(padding = 12.dp) {
        Column(modifier = GlanceModifier.fillMaxSize()) {
            WidgetHeader(
                title = "Today's Habits",
                badgeText = "${data.completedCount}/${data.totalScheduled}",
                deepLinkUri = "app://habits/daily"
            )

            Spacer(modifier = GlanceModifier.height(8.dp))

            if (data.habits.isEmpty()) {
                WidgetEmptyState(
                    message = "No habits scheduled for today",
                    actionText = "+ Add Habit",
                    actionDeepLink = "app://habits/daily"
                )
            } else {
                val displayHabits = data.habits.take(4)
                val remaining = data.habits.size - displayHabits.size

                Column(modifier = GlanceModifier.defaultWeight()) {
                    displayHabits.forEach { habit ->
                        TodaysHabitStandardRow(habit = habit)
                        Spacer(modifier = GlanceModifier.height(5.dp))
                    }
                }

                if (remaining > 0) {
                    Row(
                        modifier = GlanceModifier.fillMaxWidth(),
                        horizontalAlignment = Alignment.End,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "+$remaining more",
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
}

@Composable
fun TodaysHabitsLarge(data: TodaysHabitsWidgetData) {
    WidgetCard(padding = 12.dp) {
        Column(modifier = GlanceModifier.fillMaxSize()) {
            WidgetHeader(
                title = "Today's Habits",
                badgeText = "${data.completedCount}/${data.totalScheduled} Completed",
                deepLinkUri = "app://habits/daily"
            )

            Spacer(modifier = GlanceModifier.height(8.dp))

            if (data.habits.isEmpty()) {
                WidgetEmptyState(
                    message = "No habits scheduled today",
                    actionText = "+ Add Habit",
                    actionDeepLink = "app://habits/daily"
                )
            } else {
                val displayHabits = data.habits.take(5)

                Column(modifier = GlanceModifier.defaultWeight()) {
                    displayHabits.forEach { habit ->
                        TodaysHabitDetailedRow(habit = habit)
                        Spacer(modifier = GlanceModifier.height(5.dp))
                    }
                }

                Spacer(modifier = GlanceModifier.height(6.dp))

                // Bottom summary bar
                Row(
                    modifier = GlanceModifier
                        .fillMaxWidth()
                        .background(WidgetColors.SurfaceElevated)
                        .cornerRadius(8.dp)
                        .padding(horizontal = 10.dp, vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Top Streak: ${data.topStreak}d",
                        style = TextStyle(
                            color = ColorProvider(WidgetColors.AccentAmber),
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold
                        )
                    )

                    Spacer(modifier = GlanceModifier.defaultWeight())

                    Text(
                        text = "+${data.todayXp} XP today",
                        style = TextStyle(
                            color = ColorProvider(WidgetColors.Primary),
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold
                        )
                    )

                    Spacer(modifier = GlanceModifier.width(12.dp))

                    Box(
                        modifier = GlanceModifier
                            .clickable(actionStartActivity(createDeepLinkIntent("app://habits/daily"))),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "+ Add",
                            style = TextStyle(
                                color = ColorProvider(WidgetColors.TextPrimary),
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold
                            )
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun TodaysHabitCompactRow(habit: TodaysHabitItem) {
    Row(
        modifier = GlanceModifier
            .fillMaxWidth()
            .background(WidgetColors.Surface)
            .cornerRadius(8.dp)
            .padding(horizontal = 8.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = habit.title,
            maxLines = 1,
            style = TextStyle(
                color = ColorProvider(if (habit.isCompleted) WidgetColors.Primary else WidgetColors.TextPrimary),
                fontSize = 12.sp,
                fontWeight = if (habit.isCompleted) FontWeight.Bold else FontWeight.Normal
            ),
            modifier = GlanceModifier
                .defaultWeight()
                .clickable(actionStartActivity(createDeepLinkIntent("app://habits/detail/${habit.id}")))
        )

        HabitCheckButton(habit = habit, size = 24)
    }
}

@Composable
fun TodaysHabitStandardRow(habit: TodaysHabitItem) {
    Row(
        modifier = GlanceModifier
            .fillMaxWidth()
            .background(WidgetColors.Surface)
            .cornerRadius(10.dp)
            .padding(horizontal = 10.dp, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(
            modifier = GlanceModifier
                .defaultWeight()
                .clickable(actionStartActivity(createDeepLinkIntent("app://habits/detail/${habit.id}")))
        ) {
            Text(
                text = habit.title,
                maxLines = 1,
                style = TextStyle(
                    color = ColorProvider(if (habit.isCompleted) WidgetColors.Primary else WidgetColors.TextPrimary),
                    fontSize = 13.sp,
                    fontWeight = if (habit.isCompleted) FontWeight.Bold else FontWeight.Medium
                )
            )
            if (habit.currentStreak > 0) {
                Text(
                    text = "${habit.currentStreak}d streak",
                    style = TextStyle(
                        color = ColorProvider(WidgetColors.AccentAmber),
                        fontSize = 10.sp
                    )
                )
            }
        }

        HabitCheckButton(habit = habit, size = 28)
    }
}

@Composable
fun TodaysHabitDetailedRow(habit: TodaysHabitItem) {
    Row(
        modifier = GlanceModifier
            .fillMaxWidth()
            .background(WidgetColors.Surface)
            .cornerRadius(10.dp)
            .padding(horizontal = 10.dp, vertical = 5.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(
            modifier = GlanceModifier
                .defaultWeight()
                .clickable(actionStartActivity(createDeepLinkIntent("app://habits/detail/${habit.id}")))
        ) {
            Text(
                text = habit.title,
                maxLines = 1,
                style = TextStyle(
                    color = ColorProvider(if (habit.isCompleted) WidgetColors.Primary else WidgetColors.TextPrimary),
                    fontSize = 12.sp,
                    fontWeight = if (habit.isCompleted) FontWeight.Bold else FontWeight.Medium
                )
            )

            val metaText = if (habit.currentStreak > 0) {
                "${habit.categoryName} - ${habit.currentStreak}d streak"
            } else {
                habit.categoryName
            }

            Text(
                text = metaText,
                style = TextStyle(
                    color = ColorProvider(WidgetColors.TextSecondary),
                    fontSize = 10.sp
                )
            )
        }

        HabitCheckButton(habit = habit, size = 28)
    }
}

@Composable
fun HabitCheckButton(habit: TodaysHabitItem, size: Int = 28) {
    val checkColor = if (habit.isCompleted) WidgetColors.CheckActive else WidgetColors.CheckInactive
    val checkSymbol = if (habit.isCompleted) "✓" else "○"

    Box(
        modifier = GlanceModifier
            .size(size.dp)
            .background(checkColor)
            .cornerRadius((size / 2).dp)
            .clickable(
                actionRunCallback<TodaysHabitToggleCallback>(
                    actionParametersOf(HabitToggleIdKey to habit.id)
                )
            ),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = checkSymbol,
            style = TextStyle(
                color = ColorProvider(Color.White),
                fontSize = (size / 2).sp,
                fontWeight = FontWeight.Bold
            )
        )
    }
}
