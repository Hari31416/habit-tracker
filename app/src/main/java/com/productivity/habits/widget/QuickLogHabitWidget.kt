package com.productivity.habits.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.action.ActionParameters
import androidx.glance.action.actionParametersOf
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.updateAll
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
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitFrequencyType
import com.productivity.habits.data.local.entity.HabitLogEntity
import com.productivity.habits.domain.engine.StreakCalculator
import com.productivity.habits.domain.repository.HabitRepository
import dagger.hilt.EntryPoint
import dagger.hilt.InstallIn
import dagger.hilt.android.EntryPointAccessors
import dagger.hilt.components.SingletonComponent
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.time.LocalDate
import java.time.format.DateTimeFormatter

class QuickLogHabitWidget : GlanceAppWidget() {

    @EntryPoint
    @InstallIn(SingletonComponent::class)
    interface QuickLogWidgetEntryPoint {
        fun habitDao(): HabitDao
        fun habitLogDao(): HabitLogDao
    }

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val entryPoint = EntryPointAccessors.fromApplication(
            context.applicationContext,
            QuickLogWidgetEntryPoint::class.java
        )

        val today = LocalDate.now()
        val todayStr = today.format(DateTimeFormatter.ofPattern("yyyy-MM-dd"))

        val habits = withContext(Dispatchers.IO) {
            val allActive = entryPoint.habitDao().getActiveHabitsOnce()
            val allLogs = entryPoint.habitLogDao().getLogsForDateOnce(todayStr)
            val logsByHabit = allLogs.groupBy { it.habitId }

            allActive
                .filter { StreakCalculator.isHabitScheduledOnDate(it, today) }
                .sortedByDescending { it.pinned }
                .take(4)
                .map { habit ->
                    val logs = logsByHabit[habit.id] ?: emptyList()
                    val isDone = StreakCalculator.isHabitCompletedOnDate(habit, logs)
                    WidgetHabitItem(habit.id, habit.title, habit.color, isDone)
                }
        }

        provideContent {
            GlanceTheme {
                QuickLogWidgetContent(habits = habits)
            }
        }
    }
}

data class WidgetHabitItem(
    val id: String,
    val title: String,
    val colorHex: String,
    val isCompleted: Boolean
)

val HabitIdKey = ActionParameters.Key<String>("habit_id")

class QuickLogActionCallback : ActionCallback {
    @EntryPoint
    @InstallIn(SingletonComponent::class)
    interface ActionCallbackEntryPoint {
        fun repository(): HabitRepository
    }

    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters
    ) {
        val habitId = parameters[HabitIdKey] ?: return
        val entryPoint = EntryPointAccessors.fromApplication(
            context.applicationContext,
            ActionCallbackEntryPoint::class.java
        )

        withContext(Dispatchers.IO) {
            entryPoint.repository().toggleBooleanCheckIn(habitId, LocalDate.now())
        }

        QuickLogHabitWidget().updateAll(context)
        DailyFocusWidget().updateAll(context)
    }
}

@Composable
fun QuickLogWidgetContent(habits: List<WidgetHabitItem>) {
    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(Color(0xFF1E2925))
            .cornerRadius(16.dp)
            .padding(12.dp)
    ) {
        Column(modifier = GlanceModifier.fillMaxSize()) {
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Today's Habits",
                    style = TextStyle(
                        color = ColorProvider(Color.White),
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold
                    )
                )
            }

            Spacer(modifier = GlanceModifier.height(8.dp))

            if (habits.isEmpty()) {
                Box(
                    modifier = GlanceModifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "All caught up today!",
                        style = TextStyle(color = ColorProvider(Color(0xFF94A3B8)), fontSize = 12.sp)
                    )
                }
            } else {
                Column(
                    modifier = GlanceModifier.fillMaxSize(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    habits.forEach { item ->
                        WidgetHabitRow(item = item)
                        Spacer(modifier = GlanceModifier.height(6.dp))
                    }
                }
            }
        }
    }
}

@Composable
fun WidgetHabitRow(item: WidgetHabitItem) {
    Row(
        modifier = GlanceModifier
            .fillMaxWidth()
            .background(Color(0xFF263530))
            .cornerRadius(10.dp)
            .padding(horizontal = 10.dp, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = item.title,
            maxLines = 1,
            style = TextStyle(
                color = ColorProvider(if (item.isCompleted) Color(0xFF66DBBF) else Color.White),
                fontSize = 13.sp,
                fontWeight = if (item.isCompleted) FontWeight.Bold else FontWeight.Normal
            ),
            modifier = GlanceModifier.defaultWeight()
        )

        val checkColor = if (item.isCompleted) Color(0xFF10B981) else Color(0xFF475569)
        val checkText = if (item.isCompleted) "✓" else "○"

        Box(
            modifier = GlanceModifier
                .size(24.dp)
                .background(checkColor)
                .cornerRadius(12.dp)
                .clickable(
                    actionRunCallback<QuickLogActionCallback>(
                        actionParametersOf(HabitIdKey to item.id)
                    )
                ),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = checkText,
                style = TextStyle(
                    color = ColorProvider(Color.White),
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold
                )
            )
        }
    }
}
