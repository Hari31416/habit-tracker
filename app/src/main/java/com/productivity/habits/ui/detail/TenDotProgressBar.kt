package com.productivity.habits.ui.detail

import androidx.compose.foundation.BorderStroke
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
import androidx.compose.foundation.shape.CircleShape
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
import androidx.compose.ui.unit.dp
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitFrequencyType
import com.productivity.habits.data.local.entity.HabitTargetType
import com.productivity.habits.ui.common.HapticsHelper
import kotlin.math.ceil
import kotlin.math.floor
import kotlin.math.min

@Composable
fun TenDotProgressBar(
    habit: HabitEntity,
    currentValue: Double,
    accentColor: Color,
    onDotClick: (Double) -> Unit,
    modifier: Modifier = Modifier
) {
    // Show strictly for NUMERIC and TIMER, and not for subday/times-per-day slot models
    if (habit.targetType == HabitTargetType.BOOLEAN ||
        habit.frequencyType == HabitFrequencyType.SUBDAY_INTERVAL ||
        habit.frequencyType == HabitFrequencyType.TIMES_PER_DAY
    ) {
        return
    }

    val context = LocalContext.current
    val haptic = LocalHapticFeedback.current

    val targetValue = habit.targetValue ?: 1.0
    val fillCount = min(10, floor((currentValue / targetValue) * 10).toInt()).coerceAtLeast(0)

    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = "10-Dot Progress",
                style = MaterialTheme.typography.labelMedium,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            val percent = min(100, ((currentValue / targetValue) * 100).toInt())
            Text(
                text = "$percent%",
                style = MaterialTheme.typography.labelSmall,
                fontWeight = FontWeight.Bold,
                color = accentColor
            )
        }

        Spacer(modifier = Modifier.height(10.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            for (dotIndex in 1..10) {
                val isFilled = dotIndex <= fillCount
                val targetForDot = ceil(dotIndex / 10.0 * targetValue)

                Surface(
                    modifier = Modifier
                        .size(26.dp)
                        .clip(CircleShape)
                        .clickable {
                            if (dotIndex == 10 || targetForDot >= targetValue) {
                                HapticsHelper.performHeavyConfirmationHaptic(context, haptic)
                            } else {
                                HapticsHelper.performLightHaptic(haptic)
                            }
                            onDotClick(targetForDot)
                        },
                    shape = CircleShape,
                    color = if (isFilled) accentColor else MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f),
                    border = if (isFilled) null else BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Text(
                            text = "$dotIndex",
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.Bold,
                            color = if (isFilled) Color.White else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
                        )
                    }
                }
            }
        }
    }
}
