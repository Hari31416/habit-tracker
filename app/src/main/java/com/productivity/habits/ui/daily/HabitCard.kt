package com.productivity.habits.ui.daily

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
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
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.PushPin
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
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
    val outlineVariant = MaterialTheme.colorScheme.outlineVariant

    val streakUnit = if (habit.frequencyType == HabitFrequencyType.WEEKLY) "wks" else "d"
    val streakLabel = "${streak.currentStreak} $streakUnit streak"

    val checkButtonScale by animateFloatAsState(
        targetValue = if (isCompleted) 1.05f else 1.0f,
        animationSpec = spring(dampingRatio = 0.6f),
        label = "check_scale"
    )

    val checkBgColor by animateColorAsState(
        targetValue = if (isCompleted) habitColor else Color.Transparent,
        label = "check_bg_color"
    )

    Card(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .clickable { onHabitClick(habit.id) },
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (isCompleted) {
                MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f)
            } else {
                MaterialTheme.colorScheme.surface
            }
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = if (isCompleted) 0.5.dp else 1.5.dp),
        border = BorderStroke(
            1.dp,
            if (habit.pinned) {
                MaterialTheme.colorScheme.primary.copy(alpha = 0.3f)
            } else {
                outlineVariant.copy(alpha = 0.35f)
            }
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 14.dp, vertical = 12.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Left Icon Badge
                Surface(
                    modifier = Modifier.size(44.dp),
                    shape = RoundedCornerShape(12.dp),
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

                // Middle: Title, Category, Streak / Metadata
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.Center
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Text(
                            text = habit.title,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onSurface,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                            modifier = Modifier.weight(1f, fill = false)
                        )

                        if (habit.pinned) {
                            Icon(
                                imageVector = Icons.Filled.PushPin,
                                contentDescription = "Pinned",
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(14.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(2.dp))

                    val categoryText = category?.name ?: habit.description
                    if (!categoryText.isNullOrBlank()) {
                        Text(
                            text = categoryText,
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }

                    Spacer(modifier = Modifier.height(2.dp))

                    // Streak or target status
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        if (streak.currentStreak > 0) {
                            Icon(
                                imageVector = Icons.Default.LocalFireDepartment,
                                contentDescription = "Streak",
                                tint = MaterialTheme.colorScheme.tertiary,
                                modifier = Modifier.size(13.dp)
                            )
                            Spacer(modifier = Modifier.width(2.dp))
                            Text(
                                text = streakLabel,
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.tertiary
                            )
                        } else {
                            val targetDesc = when {
                                habit.targetType == HabitTargetType.NUMERIC -> {
                                    val current = habitWithProgress.currentValueOnDate.toInt()
                                    val target = (habit.targetValue ?: 0.0).toInt()
                                    "$current / $target ${habit.unit ?: ""}".trim()
                                }
                                habit.targetType == HabitTargetType.TIMER -> {
                                    val mins = (habitWithProgress.currentDurationSecondsOnDate / 60.0).toInt()
                                    val targetMins = (habit.targetValue ?: 0.0).toInt()
                                    "$mins / $targetMins min"
                                }
                                else -> "Not started"
                            }
                            Text(
                                text = targetDesc,
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.outline
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.width(8.dp))

                // Right Completion Control / Focus Action (Touch target >= 48dp)
                if (habit.targetType == HabitTargetType.TIMER && !isCompleted) {
                    Surface(
                        modifier = Modifier
                            .clip(RoundedCornerShape(20.dp))
                            .clickable {
                                HapticsHelper.performLightHaptic(haptic)
                                onStartFocus()
                            },
                        shape = RoundedCornerShape(20.dp),
                        color = habitColor.copy(alpha = 0.15f)
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(4.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.PlayArrow,
                                contentDescription = "Start Focus",
                                tint = habitColor,
                                modifier = Modifier.size(16.dp)
                            )
                            Text(
                                text = "Focus",
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.Bold,
                                color = habitColor
                            )
                        }
                    }
                } else {
                    Box(
                        modifier = Modifier
                            .size(48.dp)
                            .clip(CircleShape)
                            .clickable {
                                if (!isCompleted) {
                                    HapticsHelper.performHeavyConfirmationHaptic(context, haptic)
                                } else {
                                    HapticsHelper.performLightHaptic(haptic)
                                }
                                onToggleCheckIn()
                            },
                        contentAlignment = Alignment.Center
                    ) {
                        Box(
                            modifier = Modifier
                                .size(34.dp)
                                .scale(checkButtonScale)
                                .clip(CircleShape)
                                .background(checkBgColor)
                                .then(
                                    if (!isCompleted) {
                                        Modifier.border(2.dp, outlineVariant, CircleShape)
                                    } else Modifier
                                ),
                            contentAlignment = Alignment.Center
                        ) {
                            if (isCompleted) {
                                Icon(
                                    imageVector = Icons.Default.Check,
                                    contentDescription = "Completed",
                                    tint = Color.White,
                                    modifier = Modifier.size(20.dp)
                                )
                            }
                        }
                    }
                }
            }

            // Compact auxiliary controls for numeric / slot targets
            if (habit.targetType == HabitTargetType.NUMERIC && !isCompleted) {
                Spacer(modifier = Modifier.height(8.dp))
                NumericHabitControls(
                    habit = habit,
                    currentValue = habitWithProgress.currentValueOnDate,
                    isCompleted = isCompleted,
                    accentColor = habitColor,
                    onValueChange = onValueChange,
                    onDeltaAdd = onDeltaAdd
                )
            } else if ((habit.frequencyType == HabitFrequencyType.SUBDAY_INTERVAL || habit.frequencyType == HabitFrequencyType.TIMES_PER_DAY) && !isCompleted) {
                Spacer(modifier = Modifier.height(8.dp))
                SlotHabitControls(
                    habit = habit,
                    logsForDate = habitWithProgress.logsForDate,
                    accentColor = habitColor,
                    onToggleSlot = onToggleSlot
                )
            }
        }
    }
}
