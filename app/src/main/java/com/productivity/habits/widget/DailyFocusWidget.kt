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
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
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
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.productivity.habits.data.local.dao.HabitDao
import com.productivity.habits.data.local.dao.HabitLogDao
import com.productivity.habits.domain.engine.StreakCalculator
import com.productivity.habits.domain.gamification.GamificationEngine
import dagger.hilt.EntryPoint
import dagger.hilt.InstallIn
import dagger.hilt.android.EntryPointAccessors
import dagger.hilt.components.SingletonComponent
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlin.math.roundToInt

data class DailyFocusWidgetData(
    val completedCount: Int,
    val totalScheduled: Int,
    val ratePercent: Int,
    val bestStreak: Int,
    val focusMinutes: Int,
    val xpEarnedToday: Long
)

class DailyFocusWidget : GlanceAppWidget() {

    override val sizeMode: SizeMode = SizeMode.Exact

    @EntryPoint
    @InstallIn(SingletonComponent::class)
    interface DailyFocusWidgetEntryPoint {
        fun habitDao(): HabitDao
        fun habitLogDao(): HabitLogDao
    }

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val entryPoint = EntryPointAccessors.fromApplication(
            context.applicationContext,
            DailyFocusWidgetEntryPoint::class.java
        )

        provideContent {
            val today = LocalDate.now()
            val todayStr = today.format(DateTimeFormatter.ofPattern("yyyy-MM-dd"))

            val allActive by entryPoint.habitDao().getActiveHabits().collectAsState(initial = emptyList())
            val allLogsToday by entryPoint.habitLogDao().getLogsForDate(todayStr).collectAsState(initial = emptyList())
            val allLogs by entryPoint.habitLogDao().getAllLogs().collectAsState(initial = emptyList())

            val logsByHabit = allLogsToday.groupBy { it.habitId }
            val allLogsByHabit = allLogs.groupBy { it.habitId }

            var completed = 0
            var scheduled = 0
            var maxStreak = 0
            var totalFocusSec = 0L
            var totalXp = 0L

            for (habit in allActive) {
                val isScheduled = StreakCalculator.isHabitScheduledOnDate(habit, today)
                val habitLogs = allLogsByHabit[habit.id] ?: emptyList()
                val streak = StreakCalculator.calculateStreak(habit, habitLogs, today)
                if (streak.currentStreak > maxStreak) {
                    maxStreak = streak.currentStreak
                }

                if (isScheduled) {
                    scheduled++
                    val todayLogs = logsByHabit[habit.id] ?: emptyList()
                    val isDone = StreakCalculator.isHabitCompletedOnDate(habit, todayLogs)
                    if (isDone) {
                        completed++
                    }

                    val baseXp = GamificationEngine.calculateHabitDayBaseXp(habit, todayLogs, isDone)
                    val mult = GamificationEngine.calculateStreakMultiplier(streak.currentStreak)
                    totalXp += GamificationEngine.applyMultiplier(baseXp, mult)
                }
            }

            // Total focus duration from today's logs
            for (log in allLogsToday) {
                if (log.durationSeconds != null && log.durationSeconds > 0) {
                    totalFocusSec += log.durationSeconds
                } else if (log.value != null && log.value > 0) {
                    val habit = allActive.find { it.id == log.habitId }
                    if (habit?.targetType == com.productivity.habits.data.local.entity.HabitTargetType.TIMER) {
                        totalFocusSec += (log.value * 60).toLong()
                    }
                }
            }

            val rate = if (scheduled > 0) {
                ((completed.toDouble() / scheduled.toDouble()) * 100).roundToInt()
            } else 0

            val data = DailyFocusWidgetData(
                completedCount = completed,
                totalScheduled = scheduled,
                ratePercent = rate,
                bestStreak = maxStreak,
                focusMinutes = (totalFocusSec / 60).toInt(),
                xpEarnedToday = totalXp
            )

            GlanceTheme {
                val layoutSize = resolveWidgetLayoutSize(LocalSize.current)
                when (layoutSize) {
                    WidgetLayoutSize.SMALL -> DailyFocusSmall(data)
                    WidgetLayoutSize.MEDIUM -> DailyFocusMedium(data)
                    WidgetLayoutSize.LARGE -> DailyFocusLarge(data)
                }
            }
        }
    }
}

@Composable
fun DailyFocusSmall(data: DailyFocusWidgetData) {
    WidgetCard(padding = 10.dp, deepLinkUri = "app://habits/daily") {
        Column(
            modifier = GlanceModifier.fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            WidgetHeader(
                title = "Daily Focus",
                badgeText = "${data.ratePercent}%"
            )

            Spacer(modifier = GlanceModifier.height(6.dp))

            Text(
                text = "${data.completedCount} / ${data.totalScheduled} completed",
                style = TextStyle(
                    color = ColorProvider(WidgetColors.TextPrimary),
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium
                )
            )

            Spacer(modifier = GlanceModifier.height(6.dp))

            val fraction = if (data.totalScheduled > 0) data.completedCount.toFloat() / data.totalScheduled else 0f
            WidgetProgressBar(progressFraction = fraction, height = 5.dp)
        }
    }
}

@Composable
fun DailyFocusMedium(data: DailyFocusWidgetData) {
    WidgetCard(padding = 12.dp, deepLinkUri = "app://habits/daily") {
        Column(
            modifier = GlanceModifier.fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            WidgetHeader(
                title = "Daily Focus",
                badgeText = "${data.ratePercent}%"
            )

            Spacer(modifier = GlanceModifier.height(8.dp))

            Text(
                text = "${data.completedCount} / ${data.totalScheduled}",
                style = TextStyle(
                    color = ColorProvider(WidgetColors.Primary),
                    fontSize = 26.sp,
                    fontWeight = FontWeight.Bold
                )
            )

            Text(
                text = "${data.ratePercent}% Completed",
                style = TextStyle(
                    color = ColorProvider(WidgetColors.TextSecondary),
                    fontSize = 11.sp
                )
            )

            Spacer(modifier = GlanceModifier.height(8.dp))

            val fraction = if (data.totalScheduled > 0) data.completedCount.toFloat() / data.totalScheduled else 0f
            WidgetProgressBar(progressFraction = fraction, height = 6.dp)

            Spacer(modifier = GlanceModifier.height(10.dp))

            Row(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .background(WidgetColors.Surface)
                    .cornerRadius(8.dp)
                    .padding(horizontal = 8.dp, vertical = 5.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Best Streak: ${data.bestStreak} days",
                    style = TextStyle(
                        color = ColorProvider(WidgetColors.AccentAmber),
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold
                    )
                )
            }
        }
    }
}

@Composable
fun DailyFocusLarge(data: DailyFocusWidgetData) {
    WidgetCard(padding = 12.dp, deepLinkUri = "app://habits/daily") {
        Column(modifier = GlanceModifier.fillMaxSize()) {
            WidgetHeader(
                title = "Daily Focus",
                badgeText = "${data.ratePercent}% Completed"
            )

            Spacer(modifier = GlanceModifier.height(6.dp))

            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "${data.completedCount} / ${data.totalScheduled} completed",
                    style = TextStyle(
                        color = ColorProvider(WidgetColors.TextPrimary),
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold
                    ),
                    modifier = GlanceModifier.defaultWeight()
                )
            }

            Spacer(modifier = GlanceModifier.height(6.dp))

            val fraction = if (data.totalScheduled > 0) data.completedCount.toFloat() / data.totalScheduled else 0f
            WidgetProgressBar(progressFraction = fraction, height = 6.dp)

            Spacer(modifier = GlanceModifier.height(10.dp))

            // 3-card metric dashboard
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                DailyMetricCard(
                    label = "Best Streak",
                    value = "${data.bestStreak} days",
                    valueColor = WidgetColors.AccentAmber,
                    modifier = GlanceModifier.defaultWeight()
                )

                Spacer(modifier = GlanceModifier.width(6.dp))

                val focusText = if (data.focusMinutes >= 60) {
                    String.format(Locale.getDefault(), "%dh %02dm", data.focusMinutes / 60, data.focusMinutes % 60)
                } else {
                    "${data.focusMinutes}m"
                }

                DailyMetricCard(
                    label = "Focus Time",
                    value = focusText,
                    valueColor = WidgetColors.Primary,
                    modifier = GlanceModifier.defaultWeight()
                )

                Spacer(modifier = GlanceModifier.width(6.dp))

                DailyMetricCard(
                    label = "XP Earned",
                    value = "+${data.xpEarnedToday}",
                    valueColor = WidgetColors.Success,
                    modifier = GlanceModifier.defaultWeight()
                )
            }
        }
    }
}

@Composable
fun DailyMetricCard(
    label: String,
    value: String,
    valueColor: androidx.compose.ui.graphics.Color,
    modifier: GlanceModifier = GlanceModifier
) {
    Column(
        modifier = modifier
            .background(WidgetColors.Surface)
            .cornerRadius(8.dp)
            .padding(horizontal = 8.dp, vertical = 6.dp)
    ) {
        Text(
            text = label,
            style = TextStyle(
                color = ColorProvider(WidgetColors.TextSecondary),
                fontSize = 10.sp
            )
        )
        Spacer(modifier = GlanceModifier.height(2.dp))
        Text(
            text = value,
            style = TextStyle(
                color = ColorProvider(valueColor),
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold
            )
        )
    }
}
