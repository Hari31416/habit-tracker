package com.productivity.habits.habit_tracker

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
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.NotificationCompat
import org.json.JSONObject
import java.util.Locale

class FocusTimerService : Service() {

    private lateinit var notificationManager: NotificationManager
    private val mainHandler = Handler(Looper.getMainLooper())
    private var tickerRunnable: Runnable? = null

    private var habitId: String = ""
    private var habitTitle: String = "Focus Session"
    private var totalSeconds: Long = 1500L
    private var remainingSeconds: Long = 1500L
    private var isRunning: Boolean = false
    private var isPaused: Boolean = false
    private var targetEndTimeMillis: Long = 0L

    companion object {
        const val CHANNEL_ID = "habit_focus_timer"
        const val NOTIFICATION_ID = 1001
        const val COMPLETION_NOTIFICATION_ID = 1002

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
                habitId = intent.getStringExtra(EXTRA_HABIT_ID) ?: ""
                habitTitle = intent.getStringExtra(EXTRA_HABIT_TITLE) ?: "Focus Session"
                val duration = intent.getDoubleExtra(EXTRA_DURATION_MINUTES, 25.0)
                totalSeconds = (duration * 60).toLong().coerceAtLeast(60L)
                remainingSeconds = totalSeconds
                isRunning = true
                isPaused = false
                targetEndTimeMillis = System.currentTimeMillis() + (remainingSeconds * 1000)

                saveStateToPreferences("Running")
                emitStateToFlutter()
                startForegroundWithNotification(buildNotification())
                startCountdown()
                MainActivity.updateAllAppWidgets(applicationContext)
            }
            ACTION_PAUSE -> {
                if (isRunning) {
                    isRunning = false
                    isPaused = true
                    stopCountdown()
                    saveStateToPreferences("Paused")
                    emitStateToFlutter()
                    updateNotification()
                    MainActivity.updateAllAppWidgets(applicationContext)
                }
            }
            ACTION_RESUME -> {
                if (isPaused) {
                    isRunning = true
                    isPaused = false
                    targetEndTimeMillis = System.currentTimeMillis() + (remainingSeconds * 1000)
                    saveStateToPreferences("Running")
                    emitStateToFlutter()
                    startCountdown()
                    updateNotification()
                    MainActivity.updateAllAppWidgets(applicationContext)
                }
            }
            ACTION_STOP -> {
                stopCountdown()
                isRunning = false
                isPaused = false
                remainingSeconds = totalSeconds
                saveStateToPreferences("Ready")
                emitStateToFlutter()
                stopForeground(STOP_FOREGROUND_REMOVE)
                MainActivity.updateAllAppWidgets(applicationContext)
                stopSelf()
            }
            ACTION_ADJUST -> {
                val delta = intent.getLongExtra(EXTRA_DELTA_SECONDS, 0L)
                remainingSeconds = (remainingSeconds + delta).coerceIn(0L, 86400L)
                if (totalSeconds < remainingSeconds) {
                    totalSeconds = remainingSeconds
                }
                if (isRunning) {
                    targetEndTimeMillis = System.currentTimeMillis() + (remainingSeconds * 1000)
                }
                saveStateToPreferences(if (isRunning) "Running" else if (isPaused) "Paused" else "Ready")
                emitStateToFlutter()
                updateNotification()
                MainActivity.updateAllAppWidgets(applicationContext)
            }
        }
        return START_NOT_STICKY
    }

    private fun startCountdown() {
        stopCountdown()
        val runnable = object : Runnable {
            override fun run() {
                if (!isRunning) return

                val millisLeft = targetEndTimeMillis - System.currentTimeMillis()
                val secondsLeft = (millisLeft / 1000).coerceAtLeast(0)
                remainingSeconds = secondsLeft

                saveStateToPreferences("Running")
                updateNotification()

                // Update widgets every 5 seconds or at completion
                if (secondsLeft % 5 == 0L || secondsLeft <= 0) {
                    MainActivity.updateAllAppWidgets(applicationContext)
                }

                if (secondsLeft <= 0) {
                    onTimerFinished()
                } else {
                    mainHandler.postDelayed(this, 1000)
                }
            }
        }
        tickerRunnable = runnable
        mainHandler.postDelayed(runnable, 1000)
    }

    private fun stopCountdown() {
        tickerRunnable?.let { mainHandler.removeCallbacks(it) }
        tickerRunnable = null
    }

    private fun onTimerFinished() {
        stopCountdown()
        isRunning = false
        isPaused = false
        remainingSeconds = 0

        saveStateToPreferences("Done")
        emitStateToFlutter()

        // Record finished session in preferences for Flutter sync
        val prefs = getSharedPreferences("habit_widget_prefs", Context.MODE_PRIVATE)
        val pendingSet = prefs.getStringSet("pending_completed_focus_sessions", null)?.toMutableSet() ?: mutableSetOf()
        val sessionJson = JSONObject().apply {
            put("habitId", habitId)
            put("durationSeconds", totalSeconds)
            put("timestamp", System.currentTimeMillis())
        }
        pendingSet.add(sessionJson.toString())
        prefs.edit().putStringSet("pending_completed_focus_sessions", pendingSet).apply()

        playCompletionFeedback()
        MainActivity.updateAllAppWidgets(applicationContext)

        val completionNotification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Focus Session Complete!")
            .setContentText("$habitTitle session completed.")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(COMPLETION_NOTIFICATION_ID, completionNotification)
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun playCompletionFeedback() {
        try {
            val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            val ringtone = RingtoneManager.getRingtone(applicationContext, alarmUri)
            ringtone?.play()

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
        } catch (_: Exception) {}
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
        val minutes = remainingSeconds / 60
        val seconds = remainingSeconds % 60
        val timeString = String.format(Locale.getDefault(), "%02d:%02d", minutes, seconds)

        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            this, 0, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val pauseResumeIntent = Intent(this, FocusTimerService::class.java).apply {
            action = if (isRunning) ACTION_PAUSE else ACTION_RESUME
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

        val actionTitle = if (isRunning) "Pause" else "Resume"
        val progressFraction = if (totalSeconds > 0) {
            ((totalSeconds - remainingSeconds).toDouble() / totalSeconds.toDouble()).coerceIn(0.0, 1.0)
        } else 0.0
        val progressPercent = (progressFraction * 100).toInt()

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(habitTitle.ifEmpty { "Focus Timer" })
            .setContentText("$timeString remaining")
            .setProgress(100, progressPercent, false)
            .setContentIntent(openAppPendingIntent)
            .setOngoing(isRunning)
            .setOnlyAlertOnce(true)
            .addAction(android.R.drawable.ic_media_pause, actionTitle, pauseResumePendingIntent)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop", stopPendingIntent)
            .build()
    }

    private fun emitStateToFlutter() {
        val status = when {
            isRunning -> "Running"
            isPaused -> "Paused"
            remainingSeconds <= 0L -> "Done"
            else -> "Ready"
        }
        val payload = hashMapOf<String, Any?>(
            "habitId" to habitId,
            "habitTitle" to habitTitle,
            "totalSeconds" to totalSeconds,
            "remainingSeconds" to remainingSeconds,
            "status" to status,
        )
        mainHandler.post {
            try {
                MainActivity.timerChannel?.invokeMethod("onNativeTimerEvent", payload)
            } catch (_: Exception) {
            }
        }
    }

    private fun saveStateToPreferences(status: String) {
        try {
            val progressFraction = if (totalSeconds > 0) {
                ((totalSeconds - remainingSeconds).toDouble() / totalSeconds.toDouble()).coerceIn(0.0, 1.0)
            } else 0.0

            val prefs = getSharedPreferences("habit_widget_prefs", Context.MODE_PRIVATE)
            val json = JSONObject().apply {
                put("habitId", habitId)
                put("habitTitle", habitTitle)
                put("totalSeconds", totalSeconds)
                put("remainingSeconds", remainingSeconds)
                put("status", status)
                put("progressFraction", progressFraction)
            }
            prefs.edit().putString("focus_timer", json.toString()).apply()
        } catch (_: Exception) {}
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
        stopCountdown()
        super.onDestroy()
    }
}
