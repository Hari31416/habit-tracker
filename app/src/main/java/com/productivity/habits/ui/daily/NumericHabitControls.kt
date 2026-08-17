package com.productivity.habits.ui.daily

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.domain.engine.DynamicStepEngine
import com.productivity.habits.ui.common.HapticsHelper
import java.text.NumberFormat
import java.util.Locale

@Composable
fun NumericHabitControls(
    habit: HabitEntity,
    currentValue: Double,
    isCompleted: Boolean,
    accentColor: Color,
    onValueChange: (Double) -> Unit,
    onDeltaAdd: (Double) -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val haptic = LocalHapticFeedback.current
    var showDirectInputDialog by remember { mutableStateOf(false) }

    val targetValue = habit.targetValue ?: 1.0
    val unit = habit.unit ?: ""
    val stepConfig = DynamicStepEngine.getDynamicStepConfig(targetValue, habit.unit)

    val progress = (currentValue / targetValue).coerceIn(0.0, 1.0).toFloat()
    val animatedProgress by animateFloatAsState(targetValue = progress, label = "NumericProgress")

    val numberFormatter = NumberFormat.getNumberInstance(Locale.getDefault()).apply {
        maximumFractionDigits = 1
    }

    if (showDirectInputDialog) {
        DirectNumericInputDialog(
            habitTitle = habit.title,
            currentValue = currentValue,
            targetValue = targetValue,
            unit = habit.unit,
            onDismiss = { showDirectInputDialog = false },
            onConfirm = { newValue ->
                showDirectInputDialog = false
                val previouslyMet = currentValue >= targetValue
                onValueChange(newValue)
                if (!previouslyMet && newValue >= targetValue) {
                    HapticsHelper.performHeavyConfirmationHaptic(context, haptic)
                } else {
                    HapticsHelper.performLightHaptic(haptic)
                }
            }
        )
    }

    Column(modifier = modifier.fillMaxWidth()) {
        // Progress Row: Label + Edit Pencil
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = numberFormatter.format(currentValue),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = if (isCompleted) accentColor else MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text = " / ${numberFormatter.format(targetValue)} $unit".trimEnd(),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(start = 4.dp)
                )
            }

            IconButton(
                onClick = {
                    HapticsHelper.performLightHaptic(haptic)
                    showDirectInputDialog = true
                },
                modifier = Modifier.size(28.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Edit,
                    contentDescription = "Edit value",
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(16.dp)
                )
            }
        }

        Spacer(modifier = Modifier.height(6.dp))

        // Progress Bar
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(6.dp)
                .clip(RoundedCornerShape(3.dp))
                .background(MaterialTheme.colorScheme.surfaceVariant)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth(animatedProgress)
                    .fillMaxHeight()
                    .clip(RoundedCornerShape(3.dp))
                    .background(accentColor)
            )
        }

        Spacer(modifier = Modifier.height(10.dp))

        // Stepper & Quick Add Chips Row
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            // Minus / Plus Steppers
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                // Minus primary step
                Surface(
                    modifier = Modifier
                        .size(32.dp)
                        .clip(CircleShape)
                        .clickable(enabled = currentValue > 0) {
                            HapticsHelper.performLightHaptic(haptic)
                            onDeltaAdd(-stepConfig.primaryStep)
                        },
                    shape = CircleShape,
                    color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.7f),
                    border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            imageVector = Icons.Default.Remove,
                            contentDescription = "Decrease",
                            tint = if (currentValue > 0) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.outline,
                            modifier = Modifier.size(16.dp)
                        )
                    }
                }

                // Plus primary step
                Surface(
                    modifier = Modifier
                        .size(32.dp)
                        .clip(CircleShape)
                        .clickable {
                            val newTotal = currentValue + stepConfig.primaryStep
                            val wasMet = currentValue >= targetValue
                            if (!wasMet && newTotal >= targetValue) {
                                HapticsHelper.performHeavyConfirmationHaptic(context, haptic)
                            } else {
                                HapticsHelper.performLightHaptic(haptic)
                            }
                            onDeltaAdd(stepConfig.primaryStep)
                        },
                    shape = CircleShape,
                    color = accentColor.copy(alpha = 0.15f),
                    border = BorderStroke(1.dp, accentColor.copy(alpha = 0.3f))
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            imageVector = Icons.Default.Add,
                            contentDescription = "Increase",
                            tint = accentColor,
                            modifier = Modifier.size(18.dp)
                        )
                    }
                }
            }

            // Quick Add Chips
            Row(
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                stepConfig.quickAddValues.forEach { quickVal ->
                    val quickValFormatted = if (quickVal % 1.0 == 0.0) "+${quickVal.toInt()}" else "+$quickVal"
                    Surface(
                        modifier = Modifier
                            .clip(RoundedCornerShape(14.dp))
                            .clickable {
                                val newTotal = currentValue + quickVal
                                val wasMet = currentValue >= targetValue
                                if (!wasMet && newTotal >= targetValue) {
                                    HapticsHelper.performHeavyConfirmationHaptic(context, haptic)
                                } else {
                                    HapticsHelper.performLightHaptic(haptic)
                                }
                                onDeltaAdd(quickVal)
                            },
                        shape = RoundedCornerShape(14.dp),
                        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
                        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.6f))
                    ) {
                        Text(
                            text = quickValFormatted,
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                        )
                    }
                }
            }
        }
    }
}
