package com.productivity.habits.ui.analytics

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.productivity.habits.ui.common.HapticsHelper
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.DateTimeFormatter

data class HeatmapDayData(
    val date: LocalDate,
    val completedCount: Int,
    val scheduledCount: Int,
    val ratePercent: Int
)

@Composable
fun MonthlyHeatmapGrid(
    month: YearMonth,
    dayDataMap: Map<LocalDate, HeatmapDayData>,
    onPreviousMonth: () -> Unit,
    onNextMonth: () -> Unit,
    modifier: Modifier = Modifier
) {
    val haptic = LocalHapticFeedback.current
    var selectedDayDetail by remember { mutableStateOf<HeatmapDayData?>(null) }

    val daysInMonth = month.lengthOfMonth()
    val firstDayOfMonth = month.atDay(1)
    val dayOfWeekOffset = firstDayOfMonth.dayOfWeek.value % 7

    if (selectedDayDetail != null) {
        val detail = selectedDayDetail!!
        AlertDialog(
            onDismissRequest = { selectedDayDetail = null },
            title = {
                Text(
                    text = detail.date.format(DateTimeFormatter.ofPattern("EEEE, MMM d, yyyy")),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            },
            text = {
                Column {
                    Text("Completion Rate: ${detail.ratePercent}%", fontWeight = FontWeight.SemiBold)
                    Spacer(modifier = Modifier.height(4.dp))
                    Text("Completed Habits: ${detail.completedCount} of ${detail.scheduledCount}")
                }
            },
            confirmButton = {
                TextButton(onClick = { selectedDayDetail = null }) {
                    Text("Close")
                }
            }
        )
    }

    Column(modifier = modifier.fillMaxWidth()) {
        // Month Navigation Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = month.format(DateTimeFormatter.ofPattern("MMMM yyyy")),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
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
                        contentDescription = "Previous Month"
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
                        contentDescription = "Next Month"
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Heatmap Grid
        val totalCells = ((dayOfWeekOffset + daysInMonth + 6) / 7) * 7
        val primary = MaterialTheme.colorScheme.primary

        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            for (row in 0 until (totalCells / 7)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    for (col in 0 until 7) {
                        val cellIndex = (row * 7) + col
                        val dayNumber = cellIndex - dayOfWeekOffset + 1

                        if (dayNumber in 1..daysInMonth) {
                            val date = month.atDay(dayNumber)
                            val dayData = dayDataMap[date] ?: HeatmapDayData(date, 0, 0, 0)
                            val rate = dayData.ratePercent

                            val cellColor = when {
                                rate == 100 -> primary
                                rate >= 50 -> primary.copy(alpha = 0.65f)
                                rate > 0 -> primary.copy(alpha = 0.3f)
                                else -> MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f)
                            }

                            Box(
                                modifier = Modifier
                                    .weight(1f)
                                    .aspectRatio(1f)
                                    .padding(2.dp)
                                    .clip(RoundedCornerShape(6.dp))
                                    .background(cellColor)
                                    .clickable {
                                        HapticsHelper.performLightHaptic(haptic)
                                        selectedDayDetail = dayData
                                    },
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    text = "$dayNumber",
                                    style = MaterialTheme.typography.labelSmall,
                                    fontWeight = if (rate >= 50) FontWeight.Bold else FontWeight.Normal,
                                    color = if (rate >= 50) Color.White else MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        } else {
                            Spacer(modifier = Modifier.weight(1f))
                        }
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(14.dp))

        // Heatmap Legend
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.End,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Less",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.width(6.dp))

            listOf(
                MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f),
                primary.copy(alpha = 0.3f),
                primary.copy(alpha = 0.65f),
                primary
            ).forEach { color ->
                Box(
                    modifier = Modifier
                        .size(12.dp)
                        .padding(horizontal = 1.dp)
                        .clip(RoundedCornerShape(2.dp))
                        .background(color)
                )
            }

            Spacer(modifier = Modifier.width(6.dp))
            Text(
                text = "More",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
