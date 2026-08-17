package com.productivity.habits.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.appwidget.GlanceAppWidget
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
import kotlin.math.roundToInt

class DailyFocusWidget : GlanceAppWidget() {

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

        val today = LocalDate.now()
        val todayStr = today.format(DateTimeFormatter.ofPattern("yyyy-MM-dd"))

        val (completedCount, totalScheduled, bestStreak) = withContext(Dispatchers.IO) {
            val allActive = entryPoint.habitDao().getActiveHabitsOnce()
            val allLogs = entryPoint.habitLogDao().getLogsForDateOnce(todayStr)
            val logsByHabit = allLogs.groupBy { it.habitId }

            var completed = 0
            var scheduled = 0
            var maxStreak = 0

            allActive.forEach { habit ->
                if (StreakCalculator.isHabitScheduledOnDate(habit, today)) {
                    scheduled++
                    val logs = logsByHabit[habit.id] ?: emptyList()
                    if (StreakCalculator.isHabitCompletedOnDate(habit, logs)) {
                        completed++
                    }
                }
            }

            allActive.forEach { habit ->
                val habitLogs = entryPoint.habitLogDao().getLogsForHabitOnce(habit.id)
                val streak = StreakCalculator.calculateStreak(habit, habitLogs, today)
                if (streak.currentStreak > maxStreak) {
                    maxStreak = streak.currentStreak
                }
            }

            Triple(completed, scheduled, maxStreak)
        }

        val rate = if (totalScheduled > 0) {
            ((completedCount.toDouble() / totalScheduled.toDouble()) * 100).roundToInt()
        } else 0

        provideContent {
            GlanceTheme {
                DailyFocusWidgetContent(
                    completed = completedCount,
                    total = totalScheduled,
                    ratePercent = rate,
                    bestStreak = bestStreak
                )
            }
        }
    }
}

@Composable
fun DailyFocusWidgetContent(
    completed: Int,
    total: Int,
    ratePercent: Int,
    bestStreak: Int
) {
    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(Color(0xFF1E2925))
            .cornerRadius(16.dp)
            .padding(14.dp)
    ) {
        Column(
            modifier = GlanceModifier.fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Daily Focus",
                style = TextStyle(
                    color = ColorProvider(Color.White),
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold
                )
            )

            Spacer(modifier = GlanceModifier.height(8.dp))

            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "$completed / $total",
                    style = TextStyle(
                        color = ColorProvider(Color(0xFF66DBBF)),
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Bold
                    )
                )
            }

            Text(
                text = "$ratePercent% Completed",
                style = TextStyle(
                    color = ColorProvider(Color(0xFF94A3B8)),
                    fontSize = 11.sp
                )
            )

            Spacer(modifier = GlanceModifier.height(10.dp))

            Row(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .background(Color(0xFF263530))
                    .cornerRadius(8.dp)
                    .padding(horizontal = 8.dp, vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "🔥 Top Streak: $bestStreak days",
                    style = TextStyle(
                        color = ColorProvider(Color(0xFFF59E0B)),
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold
                    )
                )
            }
        }
    }
}
