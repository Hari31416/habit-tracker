package com.productivity.habits.ui.detail

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.productivity.habits.service.FocusTimerService
import com.productivity.habits.service.TimerStateHolder
import com.productivity.habits.service.TimerStatus
import com.productivity.habits.ui.common.HapticsHelper
import java.util.Locale

@Composable
fun CircularFocusTimer(
    habitId: String,
    habitTitle: String,
    defaultDurationMinutes: Double,
    remainingUnloggedMinutes: Double = defaultDurationMinutes,
    accentColor: Color,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val haptic = LocalHapticFeedback.current
    val timerState by TimerStateHolder.timerState.collectAsState()

    var showEditMinutesDialog by remember { mutableStateOf(false) }

    val isRunningOrPausedForThisHabit = timerState.habitId == habitId && (timerState.status == TimerStatus.RUNNING || timerState.status == TimerStatus.PAUSED)
    val isCompletedForThisHabit = timerState.habitId == habitId && timerState.status == TimerStatus.COMPLETED

    // Default duration in seconds based on current remaining unlogged time
    val defaultDurationSec = (defaultDurationMinutes * 60).toLong().coerceAtLeast(60L)

    val remainingSec = when {
        isRunningOrPausedForThisHabit -> timerState.remainingSeconds
        isCompletedForThisHabit -> 0L
        timerState.habitId == habitId && timerState.status == TimerStatus.IDLE -> timerState.remainingSeconds
        else -> defaultDurationSec
    }

    val totalSec = when {
        isRunningOrPausedForThisHabit -> timerState.totalSeconds
        isCompletedForThisHabit -> timerState.totalSeconds
        timerState.habitId == habitId && timerState.status == TimerStatus.IDLE -> timerState.totalSeconds
        else -> defaultDurationSec
    }

    val status = when {
        isRunningOrPausedForThisHabit -> timerState.status
        isCompletedForThisHabit -> TimerStatus.COMPLETED
        else -> TimerStatus.IDLE
    }

    val progress = if (totalSec > 0) {
        ((totalSec - remainingSec).toFloat() / totalSec.toFloat()).coerceIn(0f, 1f)
    } else 0f
    val animatedProgress by animateFloatAsState(targetValue = progress, label = "SweepTimerProgress")

    val minutes = remainingSec / 60
    val seconds = remainingSec % 60
    val timeFormatted = String.format(Locale.getDefault(), "%02d:%02d", minutes, seconds)

    if (showEditMinutesDialog) {
        var inputMins by remember { mutableStateOf((totalSec / 60).toString()) }
        AlertDialog(
            onDismissRequest = { showEditMinutesDialog = false },
            title = { Text("Set Timer Minutes", style = MaterialTheme.typography.titleMedium) },
            text = {
                OutlinedTextField(
                    value = inputMins,
                    onValueChange = { if (it.isEmpty() || it.all { c -> c.isDigit() }) inputMins = it },
                    label = { Text("Minutes") },
                    singleLine = true
                )
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        val parsed = inputMins.toLongOrNull() ?: 25L
                        if (isRunningOrPausedForThisHabit) {
                            TimerStateHolder.setRemainingMinutes(parsed)
                        } else {
                            TimerStateHolder.setDuration(habitId, habitTitle, parsed.toDouble())
                        }
                        showEditMinutesDialog = false
                    }
                ) {
                    Text("Save", fontWeight = FontWeight.Bold)
                }
            },
            dismissButton = {
                TextButton(onClick = { showEditMinutesDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Top Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Focus Timer",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface
            )

            IconButton(
                onClick = {
                    HapticsHelper.performLightHaptic(haptic)
                    showEditMinutesDialog = true
                },
                modifier = Modifier.size(32.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Edit,
                    contentDescription = "Edit timer duration",
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(18.dp)
                )
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        // Circular Countdown Canvas
        Box(
            modifier = Modifier.size(200.dp),
            contentAlignment = Alignment.Center
        ) {
            val trackColor = MaterialTheme.colorScheme.surfaceVariant
            val sweepAngle = animatedProgress * 360f

            Canvas(modifier = Modifier.size(190.dp)) {
                val strokeWidth = 12.dp.toPx()

                // Background track circle
                drawCircle(
                    color = trackColor,
                    style = Stroke(width = strokeWidth)
                )

                // Foreground sweep arc
                drawArc(
                    color = accentColor,
                    startAngle = -90f,
                    sweepAngle = sweepAngle,
                    useCenter = false,
                    style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
                )
            }

            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = timeFormatted,
                    style = MaterialTheme.typography.displayMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface,
                    letterSpacing = (-0.5).sp
                )

                val statusLabel = when (status) {
                    TimerStatus.RUNNING -> "Focusing..."
                    TimerStatus.PAUSED -> "Paused"
                    TimerStatus.COMPLETED -> "Completed!"
                    TimerStatus.IDLE -> "Ready"
                }

                Text(
                    text = statusLabel,
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = if (status == TimerStatus.RUNNING) accentColor else MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        // Primary Control Buttons: Play/Pause and Reset
        Row(
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Reset Button
            Surface(
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape)
                    .clickable {
                        HapticsHelper.performLightHaptic(haptic)
                        FocusTimerService.stopTimer(context)
                        TimerStateHolder.stop()
                    },
                shape = CircleShape,
                color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f),
                border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        imageVector = Icons.Default.Refresh,
                        contentDescription = "Reset Timer",
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.size(22.dp)
                    )
                }
            }

            // Play / Pause Main Button
            Button(
                onClick = {
                    HapticsHelper.performLightHaptic(haptic)
                    if (status == TimerStatus.RUNNING && isRunningOrPausedForThisHabit) {
                        FocusTimerService.pauseTimer(context)
                    } else if (status == TimerStatus.PAUSED && isRunningOrPausedForThisHabit) {
                        FocusTimerService.resumeTimer(context)
                    } else {
                        FocusTimerService.startTimer(
                            context = context,
                            habitId = habitId,
                            habitTitle = habitTitle,
                            durationMinutes = (remainingSec / 60.0)
                        )
                    }
                },
                modifier = Modifier
                    .height(52.dp)
                    .width(140.dp),
                shape = RoundedCornerShape(26.dp),
                colors = ButtonDefaults.buttonColors(containerColor = accentColor)
            ) {
                Icon(
                    imageVector = if (status == TimerStatus.RUNNING && isRunningOrPausedForThisHabit) Icons.Default.Pause else Icons.Default.PlayArrow,
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier.size(24.dp)
                )
                Spacer(modifier = Modifier.width(6.dp))
                Text(
                    text = if (status == TimerStatus.RUNNING && isRunningOrPausedForThisHabit) "Pause" else "Start",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Quick Adjustment Chips (-10m, -5m, +5m, +10m, and Remaining)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            val remMinInt = remainingUnloggedMinutes.toInt()
            if (remMinInt > 0) {
                Surface(
                    modifier = Modifier
                        .padding(horizontal = 4.dp)
                        .clip(RoundedCornerShape(14.dp))
                        .clickable {
                            HapticsHelper.performLightHaptic(haptic)
                            if (isRunningOrPausedForThisHabit) {
                                FocusTimerService.stopTimer(context)
                            }
                            TimerStateHolder.setDuration(habitId, habitTitle, remMinInt.toDouble())
                        },
                    shape = RoundedCornerShape(14.dp),
                    color = accentColor.copy(alpha = 0.15f),
                    border = BorderStroke(1.dp, accentColor.copy(alpha = 0.4f))
                ) {
                    Text(
                        text = "Remaining (${remMinInt}m)",
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.Bold,
                        color = accentColor,
                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 5.dp)
                    )
                }
            }

            listOf(-600L to "-10m", -300L to "-5m", 300L to "+5m", 600L to "+10m").forEach { (deltaSec, label) ->
                Surface(
                    modifier = Modifier
                        .padding(horizontal = 4.dp)
                        .clip(RoundedCornerShape(14.dp))
                        .clickable {
                            HapticsHelper.performLightHaptic(haptic)
                            if (isRunningOrPausedForThisHabit) {
                                FocusTimerService.adjustTimer(context, deltaSec)
                            } else {
                                val currentMins = (totalSec / 60) + (deltaSec / 60)
                                TimerStateHolder.setDuration(habitId, habitTitle, currentMins.toDouble().coerceAtLeast(1.0))
                            }
                        },
                    shape = RoundedCornerShape(14.dp),
                    color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
                    border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.6f))
                ) {
                    Text(
                        text = label,
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 5.dp)
                    )
                }
            }
        }
    }
}
