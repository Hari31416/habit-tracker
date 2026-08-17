package com.productivity.habits.ui.detail

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitFrequencyType
import com.productivity.habits.data.local.entity.HabitLogEntity
import com.productivity.habits.domain.engine.StreakCalculator
import com.productivity.habits.ui.common.HapticsHelper
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.DateTimeFormatter
import kotlin.math.roundToInt

data class MonthlyStats(
    val completionRate: Int,
    val completedCount: Int,
    val scheduledCount: Int,
    val bestStreakInMonth: Int,
    val totalLoggedValue: Double
)

@Composable
fun HabitMonthlyCalendar(
    habit: HabitEntity,
    logs: List<HabitLogEntity>,
    currentMonth: YearMonth,
    selectedDate: LocalDate?,
    accentColor: Color,
    onPreviousMonth: () -> Unit,
    onNextMonth: () -> Unit,
    onDateClick: (LocalDate) -> Unit,
    modifier: Modifier = Modifier
) {
    val haptic = LocalHapticFeedback.current

    val logsByDate = logs.groupBy { it.date }
    val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")

    val daysInMonth = currentMonth.lengthOfMonth()
    val firstDayOfMonth = currentMonth.atDay(1)
    // 0 = Sunday, 1 = Monday ... 6 = Saturday (firstDayOfWeek standard)
    val dayOfWeekOffset = firstDayOfMonth.dayOfWeek.value % 7

    // Calculate Monthly Stats
    var scheduledDays = 0
    var completedDays = 0
    var currentStreakMonth = 0
    var bestStreakMonth = 0
    var totalValue = 0.0

    for (day in 1..daysInMonth) {
        val d = currentMonth.atDay(day)
        val isScheduled = StreakCalculator.isHabitScheduledOnDate(habit, d)
        val dayLogs = logsByDate[d.format(formatter)] ?: emptyList()
        val isCompleted = StreakCalculator.isHabitCompletedOnDate(habit, dayLogs)

        if (isScheduled) {
            scheduledDays++
            if (isCompleted) {
                completedDays++
                currentStreakMonth++
                if (currentStreakMonth > bestStreakMonth) bestStreakMonth = currentStreakMonth
            } else {
                currentStreakMonth = 0
            }
        }

        totalValue += dayLogs.sumOf { it.value ?: if (it.completed) (habit.targetValue ?: 1.0) else 0.0 }
    }

    val completionRate = if (scheduledDays > 0) {
        ((completedDays.toDouble() / scheduledDays.toDouble()) * 100).roundToInt()
    } else 0

    val monthlyStats = MonthlyStats(
        completionRate = completionRate,
        completedCount = completedDays,
        scheduledCount = scheduledDays,
        bestStreakInMonth = bestStreakMonth,
        totalLoggedValue = totalValue
    )

    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            // Header Row: Month Name and Steppers
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = currentMonth.format(DateTimeFormatter.ofPattern("MMMM yyyy")),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )

                Row(verticalAlignment = Alignment.CenterVertically) {
                    IconButton(
                        onClick = {
                            HapticsHelper.performLightHaptic(haptic)
                            onPreviousMonth()
                        },
                        modifier = Modifier.size(32.dp)
                    ) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.KeyboardArrowLeft,
                            contentDescription = "Previous Month",
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    IconButton(
                        onClick = {
                            HapticsHelper.performLightHaptic(haptic)
                            onNextMonth()
                        },
                        modifier = Modifier.size(32.dp)
                    ) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                            contentDescription = "Next Month",
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Days of Week Header
            val dayHeaders = listOf("S", "M", "T", "W", "T", "F", "S")
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                dayHeaders.forEach { header ->
                    Box(
                        modifier = Modifier.weight(1f),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = header,
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Calendar Days Grid (6 rows max)
            val totalCells = ((dayOfWeekOffset + daysInMonth + 6) / 7) * 7
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                for (row in 0 until (totalCells / 7)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        for (col in 0 until 7) {
                            val cellIndex = (row * 7) + col
                            val dayNumber = cellIndex - dayOfWeekOffset + 1

                            if (dayNumber in 1..daysInMonth) {
                                val cellDate = currentMonth.atDay(dayNumber)
                                val isScheduled = StreakCalculator.isHabitScheduledOnDate(habit, cellDate)
                                val dayLogs = logsByDate[cellDate.format(formatter)] ?: emptyList()
                                val isCompleted = StreakCalculator.isHabitCompletedOnDate(habit, dayLogs)
                                val isSelected = selectedDate == cellDate
                                val isPast = cellDate.isBefore(LocalDate.now())

                                CalendarDayCell(
                                    dayNumber = dayNumber,
                                    isCompleted = isCompleted,
                                    isScheduled = isScheduled,
                                    isSelected = isSelected,
                                    isPast = isPast,
                                    accentColor = accentColor,
                                    onClick = {
                                        HapticsHelper.performLightHaptic(haptic)
                                        onDateClick(cellDate)
                                    },
                                    modifier = Modifier.weight(1f)
                                )
                            } else {
                                Spacer(modifier = Modifier.weight(1f))
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Monthly Summary Metrics Strip
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.35f)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(12.dp),
                    horizontalArrangement = Arrangement.SpaceAround,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    MetricItem(
                        label = "Rate",
                        value = "${monthlyStats.completionRate}%",
                        valueColor = accentColor
                    )
                    MetricItem(
                        label = "Completed",
                        value = "${monthlyStats.completedCount}/${monthlyStats.scheduledCount}d"
                    )
                    MetricItem(
                        label = "Best Streak",
                        value = "${monthlyStats.bestStreakInMonth}d"
                    )
                    val unitLabel = habit.unit ?: if (habit.targetType == com.productivity.habits.data.local.entity.HabitTargetType.TIMER) "m" else ""
                    MetricItem(
                        label = "Total",
                        value = "${monthlyStats.totalLoggedValue.roundToInt()} $unitLabel".trim()
                    )
                }
            }
        }
    }
}

@Composable
private fun CalendarDayCell(
    dayNumber: Int,
    isCompleted: Boolean,
    isScheduled: Boolean,
    isSelected: Boolean,
    isPast: Boolean,
    accentColor: Color,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val backgroundColor = when {
        isCompleted -> accentColor
        isSelected -> MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.5f)
        else -> Color.Transparent
    }

    val textColor = when {
        isCompleted -> Color.White
        !isScheduled -> MaterialTheme.colorScheme.outlineVariant
        isSelected -> MaterialTheme.colorScheme.primary
        isPast -> MaterialTheme.colorScheme.onSurfaceVariant
        else -> MaterialTheme.colorScheme.onSurface
    }

    val border = when {
        isSelected -> BorderStroke(2.dp, MaterialTheme.colorScheme.primary)
        isScheduled && !isCompleted && isPast -> BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant)
        else -> null
    }

    Box(
        modifier = modifier
            .aspectRatio(1f)
            .padding(2.dp)
            .clip(CircleShape)
            .background(backgroundColor)
            .then(if (border != null) Modifier.border(border, CircleShape) else Modifier)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        if (isCompleted) {
            Icon(
                imageVector = Icons.Default.Check,
                contentDescription = null,
                tint = Color.White,
                modifier = Modifier.size(16.dp)
            )
        } else {
            Text(
                text = "$dayNumber",
                style = MaterialTheme.typography.labelMedium,
                fontWeight = if (isSelected || isCompleted) FontWeight.Bold else FontWeight.Normal,
                color = textColor
            )
        }
    }
}

@Composable
private fun MetricItem(
    label: String,
    value: String,
    valueColor: Color = MaterialTheme.colorScheme.onSurface,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = value,
            style = MaterialTheme.typography.titleSmall,
            fontWeight = FontWeight.Bold,
            color = valueColor
        )
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}
