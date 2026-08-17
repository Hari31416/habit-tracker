package com.productivity.habits.widget

import android.content.Context
import androidx.compose.runtime.Composable
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
import com.productivity.habits.data.local.dao.HabitDao
import com.productivity.habits.data.local.dao.HabitLogDao
import com.productivity.habits.data.local.entity.HabitTargetType
import com.productivity.habits.domain.engine.StreakCalculator
import com.productivity.habits.service.FocusTimerService
import com.productivity.habits.service.TimerStateHolder
import com.productivity.habits.service.TimerStatus
import dagger.hilt.EntryPoint
import dagger.hilt.InstallIn
import dagger.hilt.android.EntryPointAccessors
import dagger.hilt.components.SingletonComponent
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

data class FocusTimerWidgetData(
    val habitId: String?,
    val habitTitle: String,
    val totalSeconds: Long,
    val remainingSeconds: Long,
    val status: TimerStatus,
    val targetMinutes: Double,
    val todayFocusMinutes: Int = 0,
    val completedSessionsToday: Int = 0,
    val currentStreak: Int = 0
) {
    val isRunning: Boolean get() = status == TimerStatus.RUNNING
    val isPaused: Boolean get() = status == TimerStatus.PAUSED
    val isCompleted: Boolean get() = status == TimerStatus.COMPLETED
    val isIdle: Boolean get() = status == TimerStatus.IDLE
    val progress: Float get() = if (totalSeconds > 0) {
        ((totalSeconds - remainingSeconds).toFloat() / totalSeconds.toFloat()).coerceIn(0f, 1f)
    } else 0f
}

class FocusTimerWidget : GlanceAppWidget() {

    override val sizeMode: SizeMode = SizeMode.Exact

    @EntryPoint
    @InstallIn(SingletonComponent::class)
    interface FocusTimerEntryPoint {
        fun habitDao(): HabitDao
        fun habitLogDao(): HabitLogDao
    }

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val entryPoint = EntryPointAccessors.fromApplication(
            context.applicationContext,
            FocusTimerEntryPoint::class.java
        )

        val liveState = TimerStateHolder.timerState.value
        val today = LocalDate.now()
        val todayStr = today.format(DateTimeFormatter.ofPattern("yyyy-MM-dd"))

        val data = withContext(Dispatchers.IO) {
            val activeHabits = entryPoint.habitDao().getActiveHabitsOnce()
            val allLogsToday = entryPoint.habitLogDao().getLogsForDateOnce(todayStr)

            val timerHabit = if (!liveState.habitId.isNullOrBlank()) {
                activeHabits.find { it.id == liveState.habitId }
            } else {
                activeHabits.firstOrNull { it.targetType == HabitTargetType.TIMER } ?: activeHabits.firstOrNull()
            }

            val habitId = timerHabit?.id ?: liveState.habitId
            val habitTitle = if (liveState.habitTitle.isNotBlank()) liveState.habitTitle else (timerHabit?.title ?: "Focus Session")
            val durationMin = timerHabit?.targetValue ?: (liveState.totalSeconds / 60.0).coerceAtLeast(1.0)
            val totalSec = if (liveState.totalSeconds > 0) liveState.totalSeconds else (durationMin * 60).toLong().coerceAtLeast(60L)
            val remainingSec = if (liveState.status != TimerStatus.IDLE) liveState.remainingSeconds else totalSec

            var habitTodayFocusSec = 0L
            var habitCompletedSessions = 0
            for (log in allLogsToday) {
                if (log.habitId == habitId || habitId == null) {
                    if (log.durationSeconds != null && log.durationSeconds > 0) {
                        habitTodayFocusSec += log.durationSeconds
                    } else if (log.value != null && log.value > 0) {
                        habitTodayFocusSec += (log.value * 60).toLong()
                    }
                    if (log.completed) {
                        habitCompletedSessions++
                    }
                }
            }

            var streak = 0
            if (timerHabit != null) {
                val habitLogs = entryPoint.habitLogDao().getLogsForHabitOnce(timerHabit.id)
                streak = StreakCalculator.calculateStreak(timerHabit, habitLogs, today).currentStreak
            }

            FocusTimerWidgetData(
                habitId = habitId,
                habitTitle = habitTitle,
                totalSeconds = totalSec,
                remainingSeconds = remainingSec,
                status = liveState.status,
                targetMinutes = durationMin,
                todayFocusMinutes = (habitTodayFocusSec / 60).toInt(),
                completedSessionsToday = habitCompletedSessions,
                currentStreak = streak
            )
        }

        provideContent {
            GlanceTheme {
                val layoutSize = resolveWidgetLayoutSize(LocalSize.current)
                when (layoutSize) {
                    WidgetLayoutSize.SMALL -> FocusTimerSmall(data)
                    WidgetLayoutSize.MEDIUM -> FocusTimerMedium(data)
                    WidgetLayoutSize.LARGE -> FocusTimerLarge(data)
                }
            }
        }
    }
}

val TimerActionKey = ActionParameters.Key<String>("timer_action")
val TimerHabitIdKey = ActionParameters.Key<String>("timer_habit_id")
val TimerHabitTitleKey = ActionParameters.Key<String>("timer_habit_title")
val TimerDurationKey = ActionParameters.Key<Double>("timer_duration")
val TimerDeltaKey = ActionParameters.Key<Long>("timer_delta")
val TimerPresetMinutesKey = ActionParameters.Key<Double>("timer_preset_minutes")

class FocusTimerControlCallback : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters
    ) {
        val action = parameters[TimerActionKey] ?: return
        val habitId = parameters[TimerHabitIdKey] ?: ""
        val habitTitle = parameters[TimerHabitTitleKey] ?: "Focus"
        val duration = parameters[TimerDurationKey] ?: 25.0
        val delta = parameters[TimerDeltaKey] ?: 0L
        val preset = parameters[TimerPresetMinutesKey] ?: 25.0

        when (action) {
            "START" -> FocusTimerService.startTimer(context, habitId, habitTitle, duration)
            "PAUSE" -> FocusTimerService.pauseTimer(context)
            "RESUME" -> FocusTimerService.resumeTimer(context)
            "STOP" -> FocusTimerService.stopTimer(context)
            "RESET" -> {
                FocusTimerService.stopTimer(context)
                TimerStateHolder.reset()
            }
            "ADJUST" -> FocusTimerService.adjustTimer(context, delta)
            "SET_PRESET" -> {
                FocusTimerService.stopTimer(context)
                TimerStateHolder.setDuration(habitId, habitTitle, preset)
            }
        }

        WidgetUpdater.updateAllWidgets(context)
    }
}

fun formatTimeMmSs(seconds: Long): String {
    val m = seconds / 60
    val s = seconds % 60
    return String.format(Locale.getDefault(), "%02d:%02d", m, s)
}

@Composable
fun FocusTimerSmall(data: FocusTimerWidgetData) {
    val deepLink = if (data.habitId != null) "app://habits/detail/${data.habitId}" else "app://habits/daily"

    WidgetCard(padding = 10.dp) {
        Row(
            modifier = GlanceModifier.fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(
                modifier = GlanceModifier
                    .defaultWeight()
                    .clickable(actionStartActivity(createDeepLinkIntent(deepLink)))
            ) {
                Text(
                    text = data.habitTitle,
                    maxLines = 1,
                    style = TextStyle(
                        color = ColorProvider(WidgetColors.TextSecondary),
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Medium
                    )
                )

                Spacer(modifier = GlanceModifier.height(2.dp))

                Text(
                    text = formatTimeMmSs(data.remainingSeconds),
                    style = TextStyle(
                        color = ColorProvider(if (data.isRunning) WidgetColors.Primary else WidgetColors.TextPrimary),
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold
                    )
                )
            }

            TimerActionButton(data = data, size = 32)
        }
    }
}

@Composable
fun FocusTimerMedium(data: FocusTimerWidgetData) {
    val deepLink = if (data.habitId != null) "app://habits/detail/${data.habitId}" else "app://habits/daily"

    WidgetCard(padding = 12.dp) {
        Column(
            modifier = GlanceModifier.fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .clickable(actionStartActivity(createDeepLinkIntent(deepLink))),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = data.habitTitle,
                    maxLines = 1,
                    style = TextStyle(
                        color = ColorProvider(WidgetColors.TextPrimary),
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold
                    ),
                    modifier = GlanceModifier.defaultWeight()
                )

                val statusLabel = when (data.status) {
                    TimerStatus.RUNNING -> "Running"
                    TimerStatus.PAUSED -> "Paused"
                    TimerStatus.COMPLETED -> "Done"
                    TimerStatus.IDLE -> "Ready"
                }

                val statusColor = when (data.status) {
                    TimerStatus.RUNNING -> WidgetColors.Primary
                    TimerStatus.PAUSED -> WidgetColors.AccentAmber
                    TimerStatus.COMPLETED -> WidgetColors.Success
                    TimerStatus.IDLE -> WidgetColors.TextSecondary
                }

                Text(
                    text = statusLabel,
                    style = TextStyle(
                        color = ColorProvider(statusColor),
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold
                    )
                )
            }

            Spacer(modifier = GlanceModifier.height(4.dp))

            Text(
                text = formatTimeMmSs(data.remainingSeconds),
                style = TextStyle(
                    color = ColorProvider(if (data.isRunning) WidgetColors.Primary else WidgetColors.TextPrimary),
                    fontSize = 26.sp,
                    fontWeight = FontWeight.Bold
                )
            )

            Spacer(modifier = GlanceModifier.height(4.dp))

            WidgetProgressBar(progressFraction = data.progress, height = 5.dp)

            Spacer(modifier = GlanceModifier.height(8.dp))

            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                TimerActionLargeButton(data = data, modifier = GlanceModifier.defaultWeight())

                if (!data.isIdle) {
                    Spacer(modifier = GlanceModifier.width(6.dp))
                    ResetTimerButton(data = data)
                }
            }

            Spacer(modifier = GlanceModifier.height(8.dp))

            // Lower context section: presets if idle, or today's stats if active
            if (data.isIdle) {
                Row(
                    modifier = GlanceModifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Goal:",
                        style = TextStyle(color = ColorProvider(WidgetColors.TextSecondary), fontSize = 10.sp)
                    )
                    Spacer(modifier = GlanceModifier.width(4.dp))
                    listOf(15.0, 25.0, 45.0, 60.0).forEach { mins ->
                        PresetChip(data = data, minutes = mins)
                        Spacer(modifier = GlanceModifier.width(3.dp))
                    }
                }
            } else {
                Row(
                    modifier = GlanceModifier
                        .fillMaxWidth()
                        .background(WidgetColors.Surface)
                        .cornerRadius(6.dp)
                        .padding(horizontal = 8.dp, vertical = 4.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Today: ${data.todayFocusMinutes}m focused",
                        style = TextStyle(
                            color = ColorProvider(WidgetColors.Primary),
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Medium
                        )
                    )
                    if (data.currentStreak > 0) {
                        Spacer(modifier = GlanceModifier.defaultWeight())
                        Text(
                            text = "${data.currentStreak}d streak",
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
}

@Composable
fun FocusTimerLarge(data: FocusTimerWidgetData) {
    val deepLink = if (data.habitId != null) "app://habits/detail/${data.habitId}" else "app://habits/daily"

    WidgetCard(padding = 12.dp) {
        Column(
            modifier = GlanceModifier.fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .clickable(actionStartActivity(createDeepLinkIntent(deepLink))),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = data.habitTitle,
                    maxLines = 1,
                    style = TextStyle(
                        color = ColorProvider(WidgetColors.TextPrimary),
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold
                    ),
                    modifier = GlanceModifier.defaultWeight()
                )

                val percent = (data.progress * 100).toInt()
                Text(
                    text = "$percent%",
                    style = TextStyle(
                        color = ColorProvider(WidgetColors.Primary),
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )
                )
            }

            Spacer(modifier = GlanceModifier.height(4.dp))

            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = formatTimeMmSs(data.remainingSeconds),
                    style = TextStyle(
                        color = ColorProvider(if (data.isRunning) WidgetColors.Primary else WidgetColors.TextPrimary),
                        fontSize = 26.sp,
                        fontWeight = FontWeight.Bold
                    )
                )

                Spacer(modifier = GlanceModifier.defaultWeight())

                Text(
                    text = "${data.targetMinutes.toInt()} min target",
                    style = TextStyle(
                        color = ColorProvider(WidgetColors.TextSecondary),
                        fontSize = 11.sp
                    )
                )
            }

            Spacer(modifier = GlanceModifier.height(4.dp))

            WidgetProgressBar(progressFraction = data.progress, height = 5.dp)

            Spacer(modifier = GlanceModifier.height(8.dp))

            // Control Buttons Row
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                TimerActionLargeButton(data = data, modifier = GlanceModifier.defaultWeight())

                Spacer(modifier = GlanceModifier.width(6.dp))

                AdjustTimerButton(deltaSeconds = -300L, label = "-5m")

                Spacer(modifier = GlanceModifier.width(4.dp))

                AdjustTimerButton(deltaSeconds = 300L, label = "+5m")

                if (!data.isIdle) {
                    Spacer(modifier = GlanceModifier.width(4.dp))
                    ResetTimerButton(data = data)
                }
            }

            Spacer(modifier = GlanceModifier.height(8.dp))

            // Rich Bottom Section filling vertical space
            Row(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .background(WidgetColors.Surface)
                    .cornerRadius(8.dp)
                    .padding(horizontal = 10.dp, vertical = 6.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (data.isIdle) {
                    Text(
                        text = "Quick Presets:",
                        style = TextStyle(
                            color = ColorProvider(WidgetColors.TextSecondary),
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Medium
                        )
                    )
                    Spacer(modifier = GlanceModifier.width(6.dp))
                    listOf(15.0, 25.0, 45.0, 60.0).forEach { mins ->
                        PresetChip(data = data, minutes = mins)
                        Spacer(modifier = GlanceModifier.width(4.dp))
                    }
                } else {
                    Text(
                        text = "Today: ${data.todayFocusMinutes}m logged (${data.completedSessionsToday} sessions)",
                        style = TextStyle(
                            color = ColorProvider(WidgetColors.TextPrimary),
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Medium
                        ),
                        modifier = GlanceModifier.defaultWeight()
                    )

                    if (data.currentStreak > 0) {
                        Text(
                            text = "${data.currentStreak}d streak",
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
    }
}

@Composable
fun PresetChip(data: FocusTimerWidgetData, minutes: Double) {
    val isSelected = (data.targetMinutes == minutes)
    val bgColor = if (isSelected) WidgetColors.PrimaryContainer else WidgetColors.SurfaceElevated
    val textColor = if (isSelected) WidgetColors.Primary else WidgetColors.TextSecondary

    Box(
        modifier = GlanceModifier
            .background(bgColor)
            .cornerRadius(4.dp)
            .padding(horizontal = 6.dp, vertical = 2.dp)
            .clickable(
                actionRunCallback<FocusTimerControlCallback>(
                    actionParametersOf(
                        TimerActionKey to "SET_PRESET",
                        TimerHabitIdKey to (data.habitId ?: ""),
                        TimerHabitTitleKey to data.habitTitle,
                        TimerPresetMinutesKey to minutes
                    )
                )
            ),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = "${minutes.toInt()}m",
            style = TextStyle(
                color = ColorProvider(textColor),
                fontSize = 10.sp,
                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
            )
        )
    }
}

@Composable
fun ResetTimerButton(data: FocusTimerWidgetData) {
    Box(
        modifier = GlanceModifier
            .background(WidgetColors.SurfaceElevated)
            .cornerRadius(8.dp)
            .padding(horizontal = 8.dp, vertical = 6.dp)
            .clickable(
                actionRunCallback<FocusTimerControlCallback>(
                    actionParametersOf(
                        TimerActionKey to "RESET",
                        TimerHabitIdKey to (data.habitId ?: ""),
                        TimerHabitTitleKey to data.habitTitle
                    )
                )
            ),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = "↺",
            style = TextStyle(
                color = ColorProvider(WidgetColors.TextSecondary),
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold
            )
        )
    }
}

@Composable
fun TimerActionButton(data: FocusTimerWidgetData, size: Int) {
    val actionType = when (data.status) {
        TimerStatus.RUNNING -> "PAUSE"
        TimerStatus.PAUSED -> "RESUME"
        TimerStatus.IDLE, TimerStatus.COMPLETED -> "START"
    }

    val symbol = when (data.status) {
        TimerStatus.RUNNING -> "❚❚"
        TimerStatus.PAUSED, TimerStatus.IDLE, TimerStatus.COMPLETED -> "▶"
    }

    val bgColor = if (data.isRunning) WidgetColors.Primary else WidgetColors.SurfaceElevated

    Box(
        modifier = GlanceModifier
            .size(size.dp)
            .background(bgColor)
            .cornerRadius((size / 2).dp)
            .clickable(
                actionRunCallback<FocusTimerControlCallback>(
                    actionParametersOf(
                        TimerActionKey to actionType,
                        TimerHabitIdKey to (data.habitId ?: ""),
                        TimerHabitTitleKey to data.habitTitle,
                        TimerDurationKey to data.targetMinutes
                    )
                )
            ),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = symbol,
            style = TextStyle(
                color = ColorProvider(if (data.isRunning) WidgetColors.Background else WidgetColors.TextPrimary),
                fontSize = (size / 2.5).sp,
                fontWeight = FontWeight.Bold
            )
        )
    }
}

@Composable
fun TimerActionLargeButton(data: FocusTimerWidgetData, modifier: GlanceModifier = GlanceModifier) {
    val actionType = when (data.status) {
        TimerStatus.RUNNING -> "PAUSE"
        TimerStatus.PAUSED -> "RESUME"
        TimerStatus.IDLE, TimerStatus.COMPLETED -> "START"
    }

    val label = when (data.status) {
        TimerStatus.RUNNING -> "❚❚ Pause"
        TimerStatus.PAUSED -> "▶ Resume"
        TimerStatus.IDLE -> "▶ Start"
        TimerStatus.COMPLETED -> "↺ Restart"
    }

    val bgColor = if (data.isRunning) WidgetColors.Primary else WidgetColors.SurfaceElevated
    val textColor = if (data.isRunning) WidgetColors.Background else WidgetColors.TextPrimary

    Box(
        modifier = modifier
            .background(bgColor)
            .cornerRadius(8.dp)
            .padding(horizontal = 14.dp, vertical = 6.dp)
            .clickable(
                actionRunCallback<FocusTimerControlCallback>(
                    actionParametersOf(
                        TimerActionKey to actionType,
                        TimerHabitIdKey to (data.habitId ?: ""),
                        TimerHabitTitleKey to data.habitTitle,
                        TimerDurationKey to data.targetMinutes
                    )
                )
            ),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = label,
            style = TextStyle(
                color = ColorProvider(textColor),
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold
            )
        )
    }
}

@Composable
fun AdjustTimerButton(deltaSeconds: Long, label: String) {
    Box(
        modifier = GlanceModifier
            .background(WidgetColors.SurfaceElevated)
            .cornerRadius(8.dp)
            .padding(horizontal = 10.dp, vertical = 6.dp)
            .clickable(
                actionRunCallback<FocusTimerControlCallback>(
                    actionParametersOf(
                        TimerActionKey to "ADJUST",
                        TimerDeltaKey to deltaSeconds
                    )
                )
            ),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = label,
            style = TextStyle(
                color = ColorProvider(WidgetColors.TextPrimary),
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold
            )
        )
    }
}
