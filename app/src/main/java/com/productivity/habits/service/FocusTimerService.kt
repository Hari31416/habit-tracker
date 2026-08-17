package com.productivity.habits.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.RingtoneManager
import android.os.Build
import android.os.IBinder
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.NotificationCompat
import androidx.glance.appwidget.updateAll
import com.productivity.habits.MainActivity
import com.productivity.habits.domain.repository.HabitRepository
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.util.Locale
import javax.inject.Inject

@AndroidEntryPoint
class FocusTimerService : Service() {

    @Inject
    lateinit var repository: HabitRepository

    private val serviceScope = CoroutineScope(Dispatchers.Default + Job())
    private var timerJob: Job? = null

    private lateinit var notificationManager: NotificationManager

    companion object {
        const val CHANNEL_ID = "habit_focus_timer"
        const val NOTIFICATION_ID = 1001

        const val ACTION_START = "com.productivity.habits.ACTION_START"
        const val ACTION_PAUSE = "com.productivity.habits.ACTION_PAUSE"
        const val ACTION_RESUME = "com.productivity.habits.ACTION_RESUME"
        const val ACTION_STOP = "com.productivity.habits.ACTION_STOP"
        const val ACTION_ADJUST = "com.productivity.habits.ACTION_ADJUST"

        const val EXTRA_HABIT_ID = "extra_habit_id"
        const val EXTRA_HABIT_TITLE = "extra_habit_title"
        const val EXTRA_DURATION_MINUTES = "extra_duration_minutes"
        const val EXTRA_DELTA_SECONDS = "extra_delta_seconds"

        fun startTimer(context: Context, habitId: String, habitTitle: String, durationMinutes: Double) {
            val intent = Intent(context, FocusTimerService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_HABIT_ID, habitId)
                putExtra(EXTRA_HABIT_TITLE, habitTitle)
                putExtra(EXTRA_DURATION_MINUTES, durationMinutes)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun pauseTimer(context: Context) {
            val intent = Intent(context, FocusTimerService::class.java).apply {
                action = ACTION_PAUSE
            }
            context.startService(intent)
        }

        fun resumeTimer(context: Context) {
            val intent = Intent(context, FocusTimerService::class.java).apply {
                action = ACTION_RESUME
            }
            context.startService(intent)
        }

        fun stopTimer(context: Context) {
            val intent = Intent(context, FocusTimerService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }

        fun adjustTimer(context: Context, deltaSeconds: Long) {
            val intent = Intent(context, FocusTimerService::class.java).apply {
                action = ACTION_ADJUST
                putExtra(EXTRA_DELTA_SECONDS, deltaSeconds)
            }
            context.startService(intent)
        }
    }

    override fun onCreate() {
        super.onCreate()
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val habitId = intent.getStringExtra(EXTRA_HABIT_ID) ?: ""
                val title = intent.getStringExtra(EXTRA_HABIT_TITLE) ?: "Habit Focus"
                val duration = intent.getDoubleExtra(EXTRA_DURATION_MINUTES, 25.0)

                TimerStateHolder.start(habitId, title, duration)
                startForegroundWithNotification(buildNotification())
                startCountdown()
                serviceScope.launch { com.productivity.habits.widget.WidgetUpdater.updateAllWidgets(applicationContext) }
            }
            ACTION_PAUSE -> {
                TimerStateHolder.pause()
                timerJob?.cancel()
                updateNotification()
                serviceScope.launch { com.productivity.habits.widget.WidgetUpdater.updateAllWidgets(applicationContext) }
            }
            ACTION_RESUME -> {
                TimerStateHolder.resume()
                startCountdown()
                serviceScope.launch { com.productivity.habits.widget.WidgetUpdater.updateAllWidgets(applicationContext) }
            }
            ACTION_STOP -> {
                timerJob?.cancel()
                TimerStateHolder.stop()
                stopForeground(STOP_FOREGROUND_REMOVE)
                serviceScope.launch { com.productivity.habits.widget.WidgetUpdater.updateAllWidgets(applicationContext) }
                stopSelf()
            }
            ACTION_ADJUST -> {
                val delta = intent.getLongExtra(EXTRA_DELTA_SECONDS, 0L)
                TimerStateHolder.adjustRemaining(delta)
                updateNotification()
                serviceScope.launch { com.productivity.habits.widget.WidgetUpdater.updateAllWidgets(applicationContext) }
            }
        }
        return START_NOT_STICKY
    }

    private fun startCountdown() {
        timerJob?.cancel()
        val currentRemaining = TimerStateHolder.timerState.value.remainingSeconds
        val targetEndTime = System.currentTimeMillis() + (currentRemaining * 1000)

        timerJob = serviceScope.launch {
            while (isActive) {
                val millisLeft = targetEndTime - System.currentTimeMillis()
                val secondsLeft = (millisLeft / 1000).coerceAtLeast(0)

                TimerStateHolder.tick(secondsLeft)
                updateNotification()

                if (secondsLeft <= 0) {
                    onTimerFinished()
                    break
                }
                delay(1000)
            }
        }
    }

    private fun onTimerFinished() {
        val state = TimerStateHolder.timerState.value
        val habitId = state.habitId
        val totalSec = state.totalSeconds
        val totalMin = totalSec / 60.0

        if (!habitId.isNullOrBlank()) {
            serviceScope.launch {
                repository.logCheckIn(
                    habitId = habitId,
                    date = LocalDate.now(),
                    completed = true,
                    value = totalMin,
                    durationSeconds = totalSec,
                    note = "Completed focus timer session (${totalMin.toInt()} mins)"
                )
            }
        }

        playCompletionFeedback()
        TimerStateHolder.complete()
        serviceScope.launch { com.productivity.habits.widget.WidgetUpdater.updateAllWidgets(applicationContext) }

        val completionNotification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(com.productivity.habits.R.mipmap.ic_launcher)
            .setContentTitle("Focus Session Complete!")
            .setContentText("${state.habitTitle} session completed.")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(NOTIFICATION_ID + 1, completionNotification)
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun playCompletionFeedback() {
        try {
            // Sound
            val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            val ringtone = RingtoneManager.getRingtone(applicationContext, alarmUri)
            ringtone?.play()

            // Vibration
            val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vibratorManager?.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            }

            if (vibrator != null && vibrator.hasVibrator()) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vibrator.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 300, 200, 400), -1))
                } else {
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(longArrayOf(0, 300, 200, 400), -1)
                }
            }
        } catch (e: Exception) {
            // Ignore feedback errors
        }
    }

    private fun startForegroundWithNotification(notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val serviceType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            } else {
                0
            }
            startForeground(NOTIFICATION_ID, notification, serviceType)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun updateNotification() {
        notificationManager.notify(NOTIFICATION_ID, buildNotification())
    }

    private fun buildNotification(): Notification {
        val state = TimerStateHolder.timerState.value
        val minutes = state.remainingSeconds / 60
        val seconds = state.remainingSeconds % 60
        val timeString = String.format(Locale.getDefault(), "%02d:%02d", minutes, seconds)

        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            this, 0, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val pauseResumeIntent = Intent(this, FocusTimerService::class.java).apply {
            action = if (state.isRunning) ACTION_PAUSE else ACTION_RESUME
        }
        val pauseResumePendingIntent = PendingIntent.getService(
            this, 1, pauseResumeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopIntent = Intent(this, FocusTimerService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 2, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val actionTitle = if (state.isRunning) "Pause" else "Resume"
        val progressPercent = (state.progress * 100).toInt()

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(com.productivity.habits.R.mipmap.ic_launcher)
            .setContentTitle(state.habitTitle.ifEmpty { "Focus Timer" })
            .setContentText("$timeString remaining")
            .setProgress(100, progressPercent, false)
            .setContentIntent(openAppPendingIntent)
            .setOngoing(state.isRunning)
            .setOnlyAlertOnce(true)
            .addAction(android.R.drawable.ic_media_pause, actionTitle, pauseResumePendingIntent)
            .addAction(android.R.drawable.ic_delete, "Stop", stopPendingIntent)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Focus Timer",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Displays running habit focus countdown timer"
                setShowBadge(false)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        timerJob?.cancel()
        super.onDestroy()
    }
}
