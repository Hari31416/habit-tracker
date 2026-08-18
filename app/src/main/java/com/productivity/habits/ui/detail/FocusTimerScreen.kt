package com.productivity.habits.ui.detail

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.NotificationsOff
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
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
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import com.productivity.habits.data.local.preferences.ThemePreferences
import com.productivity.habits.service.FocusTimerService
import com.productivity.habits.service.TimerStateHolder
import com.productivity.habits.service.TimerStatus
import com.productivity.habits.ui.common.HapticsHelper
import java.util.Locale

/**
 * A dedicated, distraction-free focus screen that shows only the timer,
 * habit name, and essential controls. Replaces the previous immersive
 * fullscreen approach that hid system bars globally from MainActivity.
 *
 * System bars are hidden only while this screen is in the composition.
 */
@Composable
fun FocusTimerScreen(
    habitId: String,
    themePreferences: ThemePreferences,
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val haptic = LocalHapticFeedback.current
    val timerState by TimerStateHolder.timerState.collectAsState()

    // Keep screen awake and hide system bars while on this screen
    DisposableEffect(Unit) {
        val activity = context as? ComponentActivity
        val window = activity?.window

        window?.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        val insetsController = window?.let {
            WindowCompat.getInsetsController(it, it.decorView)
        }
        insetsController?.systemBarsBehavior =
            WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        insetsController?.hide(WindowInsetsCompat.Type.systemBars())

        onDispose {
            window?.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            insetsController?.show(WindowInsetsCompat.Type.systemBars())
        }
    }

    val isActiveForHabit = timerState.habitId == habitId
    val status = if (isActiveForHabit) timerState.status else TimerStatus.IDLE
    val remainingSec = if (isActiveForHabit) timerState.remainingSeconds else timerState.totalSeconds
    val totalSec = if (isActiveForHabit) timerState.totalSeconds else timerState.totalSeconds

    val progress = if (totalSec > 0) {
        ((totalSec - remainingSec).toFloat() / totalSec.toFloat()).coerceIn(0f, 1f)
    } else 0f
    val animatedProgress by animateFloatAsState(
        targetValue = progress,
        label = "FocusScreenProgress"
    )

    val minutes = remainingSec / 60
    val seconds = remainingSec % 60
    val timeFormatted = String.format(Locale.getDefault(), "%02d:%02d", minutes, seconds)

    val accentColor = MaterialTheme.colorScheme.primary

    val statusLabel = when (status) {
        TimerStatus.RUNNING -> "Focusing..."
        TimerStatus.PAUSED -> "Paused"
        TimerStatus.COMPLETED -> "Completed!"
        TimerStatus.IDLE -> "Ready"
    }

    Surface(
        modifier = modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.surface
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            // Close button (top-left)
            IconButton(
                onClick = onBack,
                modifier = Modifier
                    .align(Alignment.TopStart)
                    .padding(16.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Close,
                    contentDescription = "Exit focus mode",
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(28.dp)
                )
            }

            // Main content centered
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 32.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                // Habit title
                Text(
                    text = timerState.habitTitle.ifBlank { "Focus Timer" },
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    letterSpacing = 0.5.sp
                )

                Spacer(modifier = Modifier.height(32.dp))

                // Large circular timer
                Box(
                    modifier = Modifier.size(280.dp),
                    contentAlignment = Alignment.Center
                ) {
                    val trackColor = MaterialTheme.colorScheme.surfaceVariant
                    val sweepAngle = animatedProgress * 360f

                    Canvas(modifier = Modifier.size(260.dp)) {
                        val strokeWidth = 12.dp.toPx()

                        // Background track
                        drawCircle(
                            color = trackColor,
                            style = Stroke(width = strokeWidth)
                        )

                        // Progress arc
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
                            style = MaterialTheme.typography.displayLarge,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onSurface,
                            letterSpacing = (-1).sp
                        )

                        Text(
                            text = statusLabel,
                            style = MaterialTheme.typography.labelLarge,
                            fontWeight = FontWeight.SemiBold,
                            color = if (status == TimerStatus.RUNNING) {
                                accentColor
                            } else {
                                MaterialTheme.colorScheme.onSurfaceVariant
                            }
                        )
                    }
                }

                Spacer(modifier = Modifier.height(40.dp))

                // Controls: Reset + Play/Pause
                Row(
                    horizontalArrangement = Arrangement.spacedBy(20.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Reset
                    Surface(
                        modifier = Modifier
                            .size(56.dp)
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
                                modifier = Modifier.size(26.dp)
                            )
                        }
                    }

                    // Play / Pause
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
                                    val durationMins = if (totalSec > 0) totalSec / 60.0 else 25.0
                                    FocusTimerService.startTimer(
                                        context,
                                        habitId,
                                        timerState.habitTitle,
                                        durationMins
                                    )
                                }
                            }
                        },
                        modifier = Modifier
                            .height(56.dp)
                            .width(180.dp),
                        shape = RoundedCornerShape(28.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = accentColor,
                            contentColor = Color.White
                        )
                    ) {
                        Icon(
                            imageVector = if (status == TimerStatus.RUNNING) {
                                Icons.Default.Pause
                            } else {
                                Icons.Default.PlayArrow
                            },
                            contentDescription = if (status == TimerStatus.RUNNING) "Pause" else "Start",
                            modifier = Modifier.size(24.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = if (status == TimerStatus.RUNNING) "Pause" else "Start",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // DND Toggle
                val dndEnabled by themePreferences.focusDndEnabled.collectAsState()
                val notificationManager = remember {
                    context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                }

                FilterChip(
                    selected = dndEnabled,
                    onClick = {
                        HapticsHelper.performLightHaptic(haptic)
                        if (!dndEnabled && !notificationManager.isNotificationPolicyAccessGranted) {
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
                            imageVector = if (dndEnabled) {
                                Icons.Default.NotificationsOff
                            } else {
                                Icons.Default.Notifications
                            },
                            contentDescription = if (dndEnabled) {
                                "Disable Do Not Disturb"
                            } else {
                                "Enable Do Not Disturb"
                            },
                            modifier = Modifier.size(16.dp)
                        )
                    },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = accentColor.copy(alpha = 0.2f),
                        selectedLabelColor = accentColor,
                        selectedLeadingIconColor = accentColor
                    )
                )
            }
        }
    }
}
