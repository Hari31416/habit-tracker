import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/local/app_database.dart';
import '../data/repositories/habit_repository_impl.dart';
import '../data/schedulers/no_op_habit_reminder_scheduler.dart';
import '../data/schedulers/notification_action_handler.dart';
import '../data/schedulers/notification_channel_handler.dart';

/// Top-level callback for notification action buttons pressed in background.
/// Must be a top-level function for isolate compatibility.
@pragma('vm:entry-point')
void onNotificationActionBackground(NotificationResponse response) {
  // Parse the action payload
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;

  try {
    final data = jsonDecode(payload) as Map<String, dynamic>;
    final action = response.actionId ?? '';
    final habitId = data['habitId'] as String? ?? '';

    if (habitId.isEmpty) return;
    if (action != NotificationPayload.actionMarkDone &&
        action != NotificationPayload.actionAddDelta) {
      return;
    }

    final delta = data['delta'] as double?;

    // Create a background DB instance for this isolate
    final db = AppDatabase.backgroundInstance();
    final habitDao = db.habitDao;
    final habitLogDao = db.habitLogDao;
    final habitCategoryDao = db.habitCategoryDao;
    const noOpScheduler = NoOpHabitReminderScheduler();
    final repo = HabitRepositoryImpl(
      habitDao: habitDao,
      habitLogDao: habitLogDao,
      habitCategoryDao: habitCategoryDao,
      reminderScheduler: noOpScheduler,
    );
    final handler = NotificationActionHandler(repo);

    handler.handleAction(
      action: action,
      habitId: habitId,
      delta: delta,
    ).then((_) {
      db.close();
    });
  } catch (_) {
    // Silently handle parse errors in background
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static FlutterLocalNotificationsPlugin get plugin => _plugin;

  /// Global callback for notification taps (foreground/app launch).
  /// Stored so the app can read which habit to navigate to.
  static String? pendingDeepLink;

  /// Test mode flags and recorded calls for unit testing
  static bool mockMode = false;
  static bool mockHasPermission = true;
  static final List<int> mockCancelledIds = [];
  static final List<Map<String, dynamic>> mockScheduledNotifications = [];

  static void resetMockData() {
    mockCancelledIds.clear();
    mockScheduledNotifications.clear();
    mockHasPermission = true;
  }

  /// Initialize the notification plugin and create channels.
  static Future<void> init() async {
    if (mockMode) return;

    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onForegroundNotificationResponse,
        onDidReceiveBackgroundNotificationResponse:
            onNotificationActionBackground,
      );

      // Create the notification channel (matches Kotlin CHANNEL_ID)
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            NotificationPayload.channelId,
            NotificationPayload.channelName,
            description: NotificationPayload.channelDescription,
            importance: Importance.high,
            enableVibration: true,
          ),
        );
      }
    } catch (_) {
      // Graceful fallback for test/headless environments
    }
  }

  /// Request notification permission on Android 13+ (and exact alarm permission).
  static Future<bool> requestPermission() async {
    if (mockMode) return mockHasPermission;

    try {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
        return granted ?? true;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Check if notifications are permitted.
  static Future<bool> hasPermission() async {
    if (mockMode) return mockHasPermission;

    try {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.areNotificationsEnabled();
        return granted ?? true;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Schedule a notification at a specific time.
  static Future<void> scheduleNotification({
    required int id,
    required NotificationPayload payload,
    required tz.TZDateTime scheduledDate,
  }) async {
    if (mockMode) {
      mockScheduledNotifications.add({
        'id': id,
        'payload': payload,
        'scheduledDate': scheduledDate,
      });
      return;
    }

    try {
      final androidActions = payload.actions.map((action) {
        return AndroidNotificationAction(
          action.actionId,
          action.label,
          showsUserInterface: false,
        );
      }).toList();

      final actionPayloadJson = jsonEncode({
        'habitId': payload.actions.isNotEmpty
            ? payload.actions.first.habitId
            : '',
        'delta': payload.actions
            .where((a) => a.delta != null)
            .map((a) => a.delta)
            .firstOrNull,
      });

      final androidDetails = AndroidNotificationDetails(
        NotificationPayload.channelId,
        NotificationPayload.channelName,
        channelDescription: NotificationPayload.channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        autoCancel: true,
        enableVibration: true,
        actions: androidActions,
      );

      final details = NotificationDetails(android: androidDetails);

      await _plugin.zonedSchedule(
        id: id,
        title: payload.title,
        body: payload.body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        payload: actionPayloadJson,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      // Graceful fallback for test/headless environments
    }
  }

  /// Cancel a specific notification by ID.
  static Future<void> cancelNotification(int id) async {
    if (mockMode) {
      mockCancelledIds.add(id);
      return;
    }

    try {
      await _plugin.cancel(id: id);
    } catch (_) {
      // Graceful fallback for test/headless environments
    }
  }

  /// Cancel all scheduled notifications.
  static Future<void> cancelAll() async {
    if (mockMode) {
      mockCancelledIds.clear();
      mockScheduledNotifications.clear();
      return;
    }

    try {
      await _plugin.cancelAll();
    } catch (_) {
      // Graceful fallback for test/headless environments
    }
  }

  /// Handle foreground notification tap -- store deep link for navigation.
  static void _onForegroundNotificationResponse(
      NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        final habitId = data['habitId'] as String?;
        if (habitId != null && habitId.isNotEmpty) {
          pendingDeepLink = 'detail/$habitId';
        }
      } catch (_) {
        // Ignore parse errors
      }
    }

    // If it's an action button press in the foreground, handle it
    if (response.notificationResponseType ==
        NotificationResponseType.selectedNotificationAction) {
      onNotificationActionBackground(response);
    }
  }
}
