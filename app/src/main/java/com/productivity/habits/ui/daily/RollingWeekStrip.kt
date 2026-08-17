package com.productivity.habits.ui.daily

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Today
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.productivity.habits.ui.common.HapticsHelper
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
import java.util.Locale

@Composable
fun RollingWeekStrip(
    selectedDate: LocalDate,
    weekLogs: Map<LocalDate, Int>,
    onDateSelected: (LocalDate) -> Unit,
    onPreviousDay: () -> Unit,
    onNextDay: () -> Unit,
    onTodayClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val haptic = LocalHapticFeedback.current
    val isToday = selectedDate == LocalDate.now()

    // 7 days centered on selected date (-3 to +3)
    val days = (-3..3).map { selectedDate.plusDays(it.toLong()) }

    Surface(
        modifier = modifier.fillMaxWidth(),
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 1.dp
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 8.dp, horizontal = 12.dp)
        ) {
            // Header Row: Steppers + Month/Year + Today button if not today
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    IconButton(
                        onClick = {
                            HapticsHelper.performLightHaptic(haptic)
                            onPreviousDay()
                        },
                        modifier = Modifier.size(36.dp)
                    ) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.KeyboardArrowLeft,
                            contentDescription = "Previous Day",
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }

                    val monthFormatter = DateTimeFormatter.ofPattern("MMMM yyyy")
                    Text(
                        text = selectedDate.format(monthFormatter),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.onSurface,
                        modifier = Modifier.padding(horizontal = 4.dp)
                    )

                    IconButton(
                        onClick = {
                            HapticsHelper.performLightHaptic(haptic)
                            onNextDay()
                        },
                        modifier = Modifier.size(36.dp)
                    ) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                            contentDescription = "Next Day",
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                if (!isToday) {
                    TextButton(
                        onClick = {
                            HapticsHelper.performLightHaptic(haptic)
                            onTodayClick()
                        },
                        modifier = Modifier.height(32.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Today,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp),
                            tint = MaterialTheme.colorScheme.primary
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = "Today",
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // 7-day strip
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                days.forEach { date ->
                    val isSelected = date == selectedDate
                    val isDayToday = date == LocalDate.now()
                    val completedCount = weekLogs[date] ?: 0

                    DayStripItem(
                        date = date,
                        isSelected = isSelected,
                        isToday = isDayToday,
                        completedCount = completedCount,
                        onClick = {
                            HapticsHelper.performLightHaptic(haptic)
                            onDateSelected(date)
                        },
                        modifier = Modifier.weight(1f)
                    )
                }
            }
        }
    }
}

@Composable
private fun DayStripItem(
    date: LocalDate,
    isSelected: Boolean,
    isToday: Boolean,
    completedCount: Int,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val dayName = date.dayOfWeek.getDisplayName(TextStyle.SHORT, Locale.getDefault()).take(3)
    val dayNum = date.dayOfMonth.toString()

    val backgroundColor = when {
        isSelected -> MaterialTheme.colorScheme.primary
        isToday -> MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.4f)
        else -> Color.Transparent
    }

    val contentColor = when {
        isSelected -> MaterialTheme.colorScheme.onPrimary
        isToday -> MaterialTheme.colorScheme.primary
        else -> MaterialTheme.colorScheme.onSurface
    }

    val dayNameColor = when {
        isSelected -> MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.85f)
        isToday -> MaterialTheme.colorScheme.primary
        else -> MaterialTheme.colorScheme.onSurfaceVariant
    }

    Column(
        modifier = modifier
            .padding(horizontal = 2.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(backgroundColor)
            .clickable(onClick = onClick)
            .padding(vertical = 8.dp, horizontal = 4.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = dayName,
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.Medium,
            color = dayNameColor
        )

        Spacer(modifier = Modifier.height(4.dp))

        Text(
            text = dayNum,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = if (isSelected || isToday) FontWeight.Bold else FontWeight.Normal,
            color = contentColor
        )

        Spacer(modifier = Modifier.height(6.dp))

        // Indicator dot for completion
        Box(
            modifier = Modifier
                .size(6.dp)
                .clip(CircleShape)
                .background(
                    when {
                        completedCount > 0 && isSelected -> MaterialTheme.colorScheme.onPrimary
                        completedCount > 0 -> MaterialTheme.colorScheme.primary
                        else -> Color.Transparent
                    }
                )
        )
    }
}
