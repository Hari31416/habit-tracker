package app.phial.habits

import android.app.NotificationManager
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.activity.result.ActivityResultLauncher
import androidx.lifecycle.lifecycleScope
import app.phial.habits.widgets.*
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterFragmentActivity() {
    private val WIDGETS_CHANNEL = "app.phial.habits/widgets"
    private val TIMER_CHANNEL = "app.phial.habits/focus_timer"
    private val HEALTH_CONNECT_CHANNEL = "app.phial.habits/health_connect"

    private var initialDeepLink: String? = null
    private var widgetsChannel: MethodChannel? = null
    private var healthChannel: MethodChannel? = null
    private var pendingHealthPermissionResult: MethodChannel.Result? = null

    private val healthConnectManager by lazy {
        app.phial.habits.health.HealthConnectManager(applicationContext)
    }

    private lateinit var requestHealthPermissionsLauncher: ActivityResultLauncher<Set<String>>

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        initialDeepLink = intent?.data?.toString()

        requestHealthPermissionsLauncher = registerForActivityResult(
            androidx.health.connect.client.PermissionController.createRequestPermissionResultContract()
        ) { grantedPermissions: Set<String> ->
            pendingHealthPermissionResult?.success(grantedPermissions.isNotEmpty())
            pendingHealthPermissionResult = null
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val deepLink = intent.data?.toString()
        if (!deepLink.isNullOrEmpty()) {
            widgetsChannel?.invokeMethod("onDeepLink", deepLink)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        timerChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TIMER_CHANNEL)

        // Widgets Method Channel
        widgetsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGETS_CHANNEL)
        widgetsChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialDeepLink" -> {
                    val uri = initialDeepLink
                    initialDeepLink = null
                    result.success(uri)
                }
                "updateWidgetData" -> {
                    val widgetType = call.argument<String>("widgetType")
                    val jsonData = call.argument<String>("jsonData")
                    if (widgetType != null && jsonData != null) {
                        val prefs = getSharedPreferences("habit_widget_prefs", Context.MODE_PRIVATE)
                        prefs.edit().putString(widgetType, jsonData).apply()
                    }
                    updateAllAppWidgets(applicationContext)
                    result.success(true)
                }
                "updateAllWidgets" -> {
                    updateAllAppWidgets(applicationContext)
                    result.success(true)
                }
                "getPendingWidgetCheckIns" -> {
                    val prefs = getSharedPreferences("habit_widget_prefs", Context.MODE_PRIVATE)
                    val pendingSet = prefs.getStringSet("pending_toggled_habit_ids", null)
                    val pendingList = pendingSet?.toList() ?: emptyList<String>()
                    prefs.edit().remove("pending_toggled_habit_ids").apply()
                    result.success(pendingList)
                }
                "getPendingCompletedFocusSessions" -> {
                    val prefs = getSharedPreferences("habit_widget_prefs", Context.MODE_PRIVATE)
                    val pendingSet = prefs.getStringSet("pending_completed_focus_sessions", null)
                    val pendingList = pendingSet?.toList() ?: emptyList<String>()
                    prefs.edit().remove("pending_completed_focus_sessions").apply()
                    result.success(pendingList)
                }
                else -> result.notImplemented()
            }
        }

        // Focus Timer Method Channel
        timerChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startTimer" -> {
                    val habitId = call.argument<String>("habitId") ?: ""
                    val habitTitle = call.argument<String>("habitTitle") ?: "Focus Session"
                    val durationMinutes = call.argument<Double>("durationMinutes") ?: 25.0
                    val dndEnabled = call.argument<Boolean>("dndEnabled") ?: false
                    FocusTimerService.startTimer(applicationContext, habitId, habitTitle, durationMinutes, dndEnabled)
                    result.success(true)
                }
                "setDndMode" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    FocusTimerService.setDndMode(applicationContext, enabled)
                    if (!enabled) {
                        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && notificationManager.isNotificationPolicyAccessGranted) {
                            try {
                                notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                            } catch (_: Exception) {}
                        }
                    }
                    result.success(true)
                }
                "pauseTimer" -> {
                    FocusTimerService.pauseTimer(applicationContext)
                    result.success(true)
                }
                "resumeTimer" -> {
                    FocusTimerService.resumeTimer(applicationContext)
                    result.success(true)
                }
                "stopTimer" -> {
                    FocusTimerService.stopTimer(applicationContext)
                    result.success(true)
                }
                "resetTimer" -> {
                    FocusTimerService.resetTimer(applicationContext)
                    result.success(true)
                }
                "adjustTimer" -> {
                    val deltaSeconds = (call.argument<Number>("deltaSeconds")?.toLong()) ?: 0L
                    FocusTimerService.adjustTimer(applicationContext, deltaSeconds)
                    result.success(true)
                }
                "getTimerState" -> {
                    val prefs = getSharedPreferences("habit_widget_prefs", Context.MODE_PRIVATE)
                    result.success(prefs.getString("focus_timer", null))
                }
                "isDndAccessGranted" -> {
                    val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        result.success(notificationManager.isNotificationPolicyAccessGranted)
                    } else {
                        result.success(true)
                    }
                }
                "openDndSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Health Connect Method Channel
        healthChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HEALTH_CONNECT_CHANNEL)
        healthChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkAvailability" -> {
                    result.success(healthConnectManager.checkAvailability())
                }
                "openHealthConnectInstall" -> {
                    try {
                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            data = Uri.parse("market://details?id=com.google.android.apps.healthdata")
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (_: Exception) {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                data = Uri.parse("https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (_: Exception) {
                            result.success(false)
                        }
                    }
                }
                "checkPermissions" -> {
                    val metrics = call.argument<List<String>>("metrics") ?: emptyList()
                    lifecycleScope.launch(Dispatchers.IO) {
                        val has = healthConnectManager.hasPermissions(metrics)
                        withContext(Dispatchers.Main) {
                            result.success(has)
                        }
                    }
                }
                "requestPermissions" -> {
                    val metrics = call.argument<List<String>>("metrics") ?: emptyList()
                    val permissions = healthConnectManager.getPermissionsForMetrics(metrics)
                    android.util.Log.d("HealthConnect", "Requesting health permissions: $permissions")
                    if (permissions.isEmpty()) {
                        result.success(true)
                    } else {
                        pendingHealthPermissionResult = result
                        requestHealthPermissionsLauncher.launch(permissions)
                    }
                }
                "getDailyMetrics" -> {
                    val dateStr = call.argument<String>("date") ?: ""
                    val metrics = call.argument<List<String>>("metrics") ?: emptyList()
                    lifecycleScope.launch(Dispatchers.IO) {
                        val data = healthConnectManager.getDailyMetrics(dateStr, metrics)
                        withContext(Dispatchers.Main) {
                            result.success(data)
                        }
                    }
                }
                "getMetricRange" -> {
                    val startDateStr = call.argument<String>("startDate") ?: ""
                    val endDateStr = call.argument<String>("endDate") ?: ""
                    val metrics = call.argument<List<String>>("metrics") ?: emptyList()
                    lifecycleScope.launch(Dispatchers.IO) {
                        val data = healthConnectManager.getMetricsRange(startDateStr, endDateStr, metrics)
                        withContext(Dispatchers.Main) {
                            result.success(data)
                        }
                    }
                }
                "schedulePeriodicSync" -> {
                    val interval = (call.argument<Number>("intervalMinutes")?.toLong()) ?: 30L
                    app.phial.habits.health.HealthConnectSyncWorker.schedule(applicationContext, interval)
                    result.success(true)
                }
                "cancelPeriodicSync" -> {
                    app.phial.habits.health.HealthConnectSyncWorker.cancel(applicationContext)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        if (isFinishing) {
            timerChannel = null
            widgetsChannel = null
            healthChannel = null
        }
        super.onDestroy()
    }

    companion object {
        @Volatile
        var timerChannel: MethodChannel? = null

        fun updateAllAppWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)

            // 1. Today's Habits
            val todaysHabitsIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, TodaysHabitsWidgetReceiver::class.java)
            )
            if (todaysHabitsIds.isNotEmpty()) {
                TodaysHabitsWidgetReceiver().updateWidgets(context, appWidgetManager, todaysHabitsIds)
            }

            // 2. Daily Focus
            val dailyFocusIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, DailyFocusWidgetReceiver::class.java)
            )
            if (dailyFocusIds.isNotEmpty()) {
                DailyFocusWidgetReceiver().updateWidgets(context, appWidgetManager, dailyFocusIds)
            }

            // 3. Streaks
            val streaksIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, StreaksWidgetReceiver::class.java)
            )
            if (streaksIds.isNotEmpty()) {
                StreaksWidgetReceiver().updateWidgets(context, appWidgetManager, streaksIds)
            }

            // 5. XP Mastery
            val xpMasteryIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, XpMasteryWidgetReceiver::class.java)
            )
            if (xpMasteryIds.isNotEmpty()) {
                XpMasteryWidgetReceiver().updateWidgets(context, appWidgetManager, xpMasteryIds)
            }
        }
    }
}
