package com.productivity.habits.ui.daily

import androidx.compose.foundation.BorderStroke
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
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.PushPin
import androidx.compose.material.icons.outlined.PushPin
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.productivity.habits.data.local.entity.HabitFrequencyType
import com.productivity.habits.data.local.entity.HabitTargetType
import com.productivity.habits.domain.model.HabitWithProgress
import com.productivity.habits.ui.common.ColorUtils
import com.productivity.habits.ui.common.HabitIconRegistry
import com.productivity.habits.ui.common.HapticsHelper

@Composable
fun HabitCard(
    habitWithProgress: HabitWithProgress,
    onHabitClick: (String) -> Unit,
    onToggleCheckIn: () -> Unit,
    onValueChange: (Double) -> Unit,
    onDeltaAdd: (Double) -> Unit,
    onToggleSlot: (Int) -> Unit,
    onTogglePin: () -> Unit,
    onStartFocus: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val haptic = LocalHapticFeedback.current

    val habit = habitWithProgress.habit
    val category = habitWithProgress.category
    val isCompleted = habitWithProgress.isCompletedOnDate
    val streak = habitWithProgress.streak

    val habitColor = ColorUtils.parseHexColor(habit.color)
    val iconVector = HabitIconRegistry.getIcon(habit.icon)

    // Format streak label: "X wks" for weekly frequency, "X d" for others
    val streakUnit = if (habit.frequencyType == HabitFrequencyType.WEEKLY) "wks" else "d"
    val streakLabel = "${streak.currentStreak} $streakUnit"

    Card(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .clickable { onHabitClick(habit.id) },
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = if (isCompleted) 1.dp else 1.5.dp),
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f))
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp)
        ) {
            // Header Row: Icon, Title & Category, Streak Badge, Pin
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Color-tinted icon badge
                Surface(
                    modifier = Modifier.size(40.dp),
                    shape = RoundedCornerShape(10.dp),
                    color = habitColor.copy(alpha = 0.15f)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            imageVector = iconVector,
                            contentDescription = null,
                            tint = habitColor,
                            modifier = Modifier.size(22.dp)
                        )
                    }
                }

                Spacer(modifier = Modifier.width(12.dp))

                // Title and category badge
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.Center
                ) {
                    Text(
                        text = habit.title,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.onSurface,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )

                    if (category != null || habit.description != null) {
                        val subtitle = category?.name ?: habit.description ?: ""
                        Text(
                            text = subtitle,
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }

                // Streak Badge
                if (streak.currentStreak > 0) {
                    Surface(
                        modifier = Modifier.clip(RoundedCornerShape(12.dp)),
                        shape = RoundedCornerShape(12.dp),
                        color = MaterialTheme.colorScheme.tertiaryContainer.copy(alpha = 0.6f)
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 3.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.LocalFireDepartment,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.tertiary,
                                modifier = Modifier.size(13.dp)
                            )
                            Spacer(modifier = Modifier.width(2.dp))
                            Text(
                                text = streakLabel,
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onTertiaryContainer
                            )
                        }
                    }
                    Spacer(modifier = Modifier.width(6.dp))
                }

                // Pin toggle button
                IconButton(
                    onClick = {
                        HapticsHelper.performLightHaptic(haptic)
                        onTogglePin()
                    },
                    modifier = Modifier.size(32.dp)
                ) {
                    Icon(
                        imageVector = if (habit.pinned) Icons.Filled.PushPin else Icons.Outlined.PushPin,
                        contentDescription = if (habit.pinned) "Unpin" else "Pin",
                        tint = if (habit.pinned) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outlineVariant,
                        modifier = Modifier.size(18.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Body Control Variation based on Target and Frequency Types
            when {
                // Subday Interval / Times Per Day Slots
                habit.frequencyType == HabitFrequencyType.SUBDAY_INTERVAL ||
                    habit.frequencyType == HabitFrequencyType.TIMES_PER_DAY -> {
                    SlotHabitControls(
                        habit = habit,
                        logsForDate = habitWithProgress.logsForDate,
                        accentColor = habitColor,
                        onToggleSlot = onToggleSlot
                    )
                }

                // Numeric Target
                habit.targetType == HabitTargetType.NUMERIC -> {
                    NumericHabitControls(
                        habit = habit,
                        currentValue = habitWithProgress.currentValueOnDate,
                        isCompleted = isCompleted,
                        accentColor = habitColor,
                        onValueChange = onValueChange,
                        onDeltaAdd = onDeltaAdd
                    )
                }

                // Timer Target
                habit.targetType == HabitTargetType.TIMER -> {
                    val currentMinutes = habitWithProgress.currentDurationSecondsOnDate / 60.0
                    TimerHabitControls(
                        habit = habit,
                        currentMinutes = currentMinutes,
                        isCompleted = isCompleted,
                        accentColor = habitColor,
                        onDeltaAddMinutes = onDeltaAdd,
                        onStartFocus = onStartFocus
                    )
                }

                // Standard Boolean Target
                else -> {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = if (isCompleted) "Completed today" else "Tap circle to complete",
                            style = MaterialTheme.typography.bodySmall,
                            color = if (isCompleted) habitColor else MaterialTheme.colorScheme.onSurfaceVariant
                        )

                        // Large Circular Boolean Check Button
                        Surface(
                            modifier = Modifier
                                .size(42.dp)
                                .clip(CircleShape)
                                .clickable {
                                    if (!isCompleted) {
                                        HapticsHelper.performHeavyConfirmationHaptic(context, haptic)
                                    } else {
                                        HapticsHelper.performLightHaptic(haptic)
                                    }
                                    onToggleCheckIn()
                                },
                            shape = CircleShape,
                            color = if (isCompleted) habitColor else Color.Transparent,
                            border = BorderStroke(
                                2.dp,
                                if (isCompleted) habitColor else MaterialTheme.colorScheme.outlineVariant
                            )
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                if (isCompleted) {
                                    Icon(
                                        imageVector = Icons.Default.Check,
                                        contentDescription = "Completed",
                                        tint = Color.White,
                                        modifier = Modifier.size(24.dp)
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
