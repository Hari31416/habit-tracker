package com.productivity.habits.ui.matrix

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.productivity.habits.data.local.entity.HabitFrequencyType
import com.productivity.habits.ui.common.ColorUtils
import com.productivity.habits.ui.common.HabitIconRegistry
import com.productivity.habits.ui.common.HapticsHelper
import java.time.LocalDate
import java.time.format.TextStyle
import java.util.Locale

@Composable
fun WeekMatrixGrid(
    rows: List<MatrixRow>,
    onToggleCell: (String, LocalDate) -> Unit,
    onHabitClick: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val haptic = LocalHapticFeedback.current

    if (rows.isEmpty()) {
        Card(
            modifier = modifier.fillMaxWidth(),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(32.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "No active habits for this week",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        return
    }

    val firstRowCells = rows.first().cells

    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f))
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp)
        ) {
            // Header Row: Habit Column + 7 Day Columns (Mo 17, Tu 18, etc.)
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Habits",
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.weight(1.3f)
                )

                Row(
                    modifier = Modifier.weight(2.4f),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    firstRowCells.forEach { cell ->
                        val dayName = cell.date.dayOfWeek.getDisplayName(TextStyle.SHORT, Locale.getDefault()).take(2)
                        val dayNum = cell.date.dayOfMonth.toString()

                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            modifier = Modifier.width(28.dp)
                        ) {
                            Text(
                                text = dayName,
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = if (cell.isToday) FontWeight.Bold else FontWeight.Medium,
                                color = if (cell.isToday) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Text(
                                text = dayNum,
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = if (cell.isToday) FontWeight.Bold else FontWeight.Normal,
                                color = if (cell.isToday) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            // Habit Rows
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                rows.forEach { row ->
                    val habit = row.habit
                    val accentColor = ColorUtils.parseHexColor(habit.color)
                    val iconVector = HabitIconRegistry.getIcon(habit.icon)

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Left Habit Info: Icon + Title
                        Row(
                            modifier = Modifier
                                .weight(1.3f)
                                .clickable { onHabitClick(habit.id) },
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Surface(
                                modifier = Modifier.size(28.dp),
                                shape = RoundedCornerShape(8.dp),
                                color = accentColor.copy(alpha = 0.15f)
                            ) {
                                Box(contentAlignment = Alignment.Center) {
                                    Icon(
                                        imageVector = iconVector,
                                        contentDescription = null,
                                        tint = accentColor,
                                        modifier = Modifier.size(16.dp)
                                    )
                                }
                            }

                            Spacer(modifier = Modifier.width(8.dp))

                            Column {
                                Text(
                                    text = habit.title,
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.SemiBold,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )

                                val freqBadge = when (habit.frequencyType) {
                                    HabitFrequencyType.DAILY -> "Daily"
                                    HabitFrequencyType.WEEKLY -> "${habit.targetCountPerWeek ?: 1}x/wk"
                                    HabitFrequencyType.CUSTOM_DAYS -> "Specific"
                                    HabitFrequencyType.SUBDAY_INTERVAL -> "Interval"
                                    HabitFrequencyType.TIMES_PER_DAY -> "Subday"
                                }

                                Text(
                                    text = "${row.completedCountThisWeek}/${row.targetCountThisWeek} - $freqBadge",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                    maxLines = 1
                                )
                            }
                        }

                        // 7 Day Cells (Tappable circles)
                        Row(
                            modifier = Modifier.weight(2.4f),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            row.cells.forEach { cell ->
                                val isDone = cell.status == MatrixCellStatus.COMPLETED
                                val isScheduled = cell.status == MatrixCellStatus.SCHEDULED_INCOMPLETE

                                val cellColor = when {
                                    isDone -> accentColor
                                    cell.isToday -> MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.4f)
                                    else -> Color.Transparent
                                }

                                val border = when {
                                    cell.isToday && !isDone -> BorderStroke(1.5.dp, MaterialTheme.colorScheme.primary)
                                    isScheduled -> BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant)
                                    else -> null
                                }

                                Box(
                                    modifier = Modifier
                                        .size(28.dp)
                                        .clip(CircleShape)
                                        .background(cellColor)
                                        .then(if (border != null) Modifier.border(border, CircleShape) else Modifier)
                                        .clickable {
                                            if (!isDone) {
                                                HapticsHelper.performHeavyConfirmationHaptic(context, haptic)
                                            } else {
                                                HapticsHelper.performLightHaptic(haptic)
                                            }
                                            onToggleCell(habit.id, cell.date)
                                        },
                                    contentAlignment = Alignment.Center
                                ) {
                                    if (isDone) {
                                        Icon(
                                            imageVector = Icons.Default.Check,
                                            contentDescription = "Completed",
                                            tint = Color.White,
                                            modifier = Modifier.size(16.dp)
                                        )
                                    } else if (!isScheduled && cell.status == MatrixCellStatus.NOT_SCHEDULED) {
                                        Box(
                                            modifier = Modifier
                                                .size(4.dp)
                                                .clip(CircleShape)
                                                .background(MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.6f))
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
