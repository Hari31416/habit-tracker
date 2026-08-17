package com.productivity.habits.ui.daily

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
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
import androidx.compose.ui.unit.dp
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitLogEntity
import com.productivity.habits.domain.engine.SubdaySlotEngine
import com.productivity.habits.ui.common.HapticsHelper

@Composable
fun SlotHabitControls(
    habit: HabitEntity,
    logsForDate: List<HabitLogEntity>,
    accentColor: Color,
    onToggleSlot: (Int) -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val haptic = LocalHapticFeedback.current

    val slots = SubdaySlotEngine.generateSlots(habit, logsForDate)
    val completedCount = slots.count { it.completed }
    val totalSlots = slots.size

    Row(
        modifier = modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState()),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        slots.forEach { slot ->
            val isDone = slot.completed
            val backgroundColor = if (isDone) accentColor else MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
            val contentColor = if (isDone) Color.White else MaterialTheme.colorScheme.onSurfaceVariant
            val borderStroke = if (isDone) null else BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.7f))

            Surface(
                modifier = Modifier
                    .clip(RoundedCornerShape(12.dp))
                    .clickable {
                        val willCompleteAll = !isDone && (completedCount + 1 >= totalSlots)
                        if (willCompleteAll) {
                            HapticsHelper.performHeavyConfirmationHaptic(context, haptic)
                        } else {
                            HapticsHelper.performLightHaptic(haptic)
                        }
                        onToggleSlot(slot.index)
                    },
                shape = RoundedCornerShape(12.dp),
                color = backgroundColor,
                border = borderStroke
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    if (isDone) {
                        Icon(
                            imageVector = Icons.Default.Check,
                            contentDescription = "Completed",
                            tint = Color.White,
                            modifier = Modifier.size(14.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                    }
                    Text(
                        text = slot.timeLabel,
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = if (isDone) FontWeight.Bold else FontWeight.Medium,
                        color = contentColor
                    )
                }
            }
        }
    }
}
