package com.productivity.habits.ui.detail

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.provider.Settings
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.Canvas
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
import androidx.compose.material.icons.filled.CenterFocusStrong
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.NotificationsOff
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
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
import com.productivity.habits.data.local.preferences.ThemePreferences
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
    themePreferences: ThemePreferences,
    onFocusScreenClick: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val haptic = LocalHapticFeedback.current
    val timerState by TimerStateHolder.timerState.collectAsState()

    var showEditMinutesDialog by remember { mutableStateOf(false) }

    val isRunningOrPausedForThisHabit = timerState.habitId == habitId && (timerState.status == TimerStatus.RUNNING || timerState.status == TimerStatus.PAUSED)
    val isCompletedForThisHabit = timerState.habitId == habitId && timerState.status == TimerStatus.COMPLETED

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

            Row(
                horizontalArrangement = Arrangement.spacedBy(4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Focus Screen toggle (enabled when timer is active)
                IconButton(
                    onClick = {
                        HapticsHelper.performLightHaptic(haptic)
                        onFocusScreenClick()
                    },
                    enabled = isRunningOrPausedForThisHabit,
                    modifier = Modifier.size(32.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.CenterFocusStrong,
                        contentDescription = "Enter focus mode",
                        tint = if (isRunningOrPausedForThisHabit) {
                            accentColor
                        } else {
                            MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f)
                        },
                        modifier = Modifier.size(20.dp)
                    )
                }

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
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Large Circular Countdown Canvas
        Box(
            modifier = Modifier.size(200.dp),
            contentAlignment = Alignment.Center
        ) {
            val trackColor = MaterialTheme.colorScheme.surfaceVariant
            val sweepAngle = animatedProgress * 360f

            Canvas(modifier = Modifier.size(190.dp)) {
                val strokeWidth = 10.dp.toPx()

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

        // Primary Control Buttons: Play/Pause Pill and Reset
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
                        FocusTimerService.resetTimer(context)
                        TimerStateHolder.reset()
                    },
                shape = CircleShape,
                color = MaterialTheme.colorScheme.surfaceVariant
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

            // Primary Play / Pause Pill Button
            Button(
                onClick = {
                    HapticsHelper.performLightHaptic(haptic)
                    when (status) {
                        TimerStatus.RUNNING -> {
                            FocusTimerService.pauseTimer(context)
                        }
                        TimerStatus.PAUSED -> {
                            FocusTimerService.resumeTimer(context)
                        }
                        TimerStatus.COMPLETED, TimerStatus.IDLE -> {
                            val durationMins = if (totalSec > 0) totalSec / 60.0 else defaultDurationMinutes
                            FocusTimerService.startTimer(context, habitId, habitTitle, durationMins)
                        }
                    }
                },
                modifier = Modifier
                    .height(48.dp)
                    .width(160.dp),
                shape = RoundedCornerShape(24.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = accentColor,
                    contentColor = Color.White
                )
            ) {
                Icon(
                    imageVector = if (status == TimerStatus.RUNNING) Icons.Default.Pause else Icons.Default.PlayArrow,
                    contentDescription = if (status == TimerStatus.RUNNING) "Pause" else "Start",
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = if (status == TimerStatus.RUNNING) "Pause" else "Start",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Duration Adjustment Quick Chips: -10m, -5m, [Goal], +5m, +10m
        val currentGoalMins = (totalSec / 60).toInt()
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            val deltas = listOf(-10, -5, 0, 5, 10)
            deltas.forEach { delta ->
                val label = if (delta == 0) "${currentGoalMins}m Goal" else if (delta > 0) "+${delta}m" else "${delta}m"
                val isGoal = delta == 0

                FilterChip(
                    selected = isGoal,
                    onClick = {
                        if (delta != 0) {
                            HapticsHelper.performLightHaptic(haptic)
                            val newMins = maxOf(1L, (totalSec / 60) + delta)
                            if (isRunningOrPausedForThisHabit) {
                                TimerStateHolder.setRemainingMinutes(newMins)
                            } else {
                                TimerStateHolder.setDuration(habitId, habitTitle, newMins.toDouble())
                            }
                        }
                    },
                    label = {
                        Text(
                            text = label,
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = if (isGoal) FontWeight.Bold else FontWeight.Medium
                        )
                    },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = accentColor.copy(alpha = 0.2f),
                        selectedLabelColor = accentColor
                    ),
                    modifier = Modifier.padding(horizontal = 4.dp)
                )
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // DND Toggle Chip
        val dndEnabled by themePreferences.focusDndEnabled.collectAsState()
        val notificationManager = remember {
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Center
        ) {
            FilterChip(
                selected = dndEnabled,
                onClick = {
                    HapticsHelper.performLightHaptic(haptic)
                    if (!dndEnabled && !notificationManager.isNotificationPolicyAccessGranted) {
                        // Redirect to system settings to grant DND access
                        val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        context.startActivity(intent)
                    } else {
                        themePreferences.setFocusDndEnabled(!dndEnabled)
                    }
                },
                label = {
                    Text(
                        text = if (dndEnabled) "DND On" else "DND Off",
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Medium
                    )
                },
                leadingIcon = {
                    Icon(
                        imageVector = if (dndEnabled) Icons.Default.NotificationsOff else Icons.Default.Notifications,
                        contentDescription = if (dndEnabled) "Disable Do Not Disturb" else "Enable Do Not Disturb",
                        modifier = Modifier.size(16.dp)
                    )
                },
                colors = FilterChipDefaults.filterChipColors(
                    selectedContainerColor = accentColor.copy(alpha = 0.2f),
                    selectedLabelColor = accentColor,
                    selectedLeadingIconColor = accentColor
                ),
                modifier = Modifier.padding(horizontal = 4.dp)
            )
        }
    }
}
