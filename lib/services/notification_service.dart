import 'dart:convert';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/local/app_database.dart';
import '../data/repositories/habit_repository_impl.dart';
import '../data/schedulers/flutter_habit_reminder_scheduler.dart';
import '../data/schedulers/notification_action_handler.dart';
import '../data/schedulers/notification_channel_handler.dart';

typedef NotificationActionCallback = Future<void> Function({
  required String action,
  required String habitId,
  double? delta,
});

/// Top-level callback for notification action buttons pressed in background.
/// Must be a top-level function for isolate compatibility.
@pragma('vm:entry-point')
void onNotificationActionBackground(NotificationResponse response) {
  NotificationService.dispatchAction(response, allowBackgroundDb: true);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static FlutterLocalNotificationsPlugin get plugin => _plugin;

  /// Global callback for notification taps (foreground/app launch).
  /// Stored so the app can read which habit to navigate to.
  static String? pendingDeepLink;

  /// Main-isolate handler so check-in/log writes hit the same Drift database
  /// the UI is watching.
  static NotificationActionCallback? actionCallback;
  static NotificationResponse? _pendingActionResponse;

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

  static void bindActionHandler(NotificationActionCallback callback) {
    actionCallback = callback;
    final pending = _pendingActionResponse;
    _pendingActionResponse = null;
    if (pending != null) {
      dispatchAction(pending);
    }
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
            playSound: true,
          ),
        );
      }

      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      final launchResponse = launchDetails?.notificationResponse;
      if (launchDetails?.didNotificationLaunchApp == true &&
          launchResponse != null) {
        _onForegroundNotificationResponse(launchResponse);
      }
    } catch (_) {
      // Graceful fallback for test/headless environments
    }
  }

  /// Request notification permission on Android 13+ (and optional exact alarm permission).
  static Future<bool> requestPermission() async {
    if (mockMode) return mockHasPermission;

    try {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        if (granted == true) {
          try {
            final canExact = await androidPlugin.canScheduleExactNotifications();
            if (canExact == false) {
              await androidPlugin.requestExactAlarmsPermission();
            }
          } catch (_) {
            // Exact alarm permission request is optional; fallback to inexact is handled in schedule
          }
        }
        return granted ?? false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Check if notifications are permitted (fail closed on errors).
  static Future<bool> hasPermission() async {
    if (mockMode) return mockHasPermission;

    try {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.areNotificationsEnabled();
        return granted ?? false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Schedule a notification at a specific time.
  static Future<void> scheduleNotification({
    required int id,
    required NotificationPayload payload,
    required tz.TZDateTime scheduledDate,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    if (mockMode) {
      mockScheduledNotifications.add({
        'id': id,
        'payload': payload,
        'scheduledDate': scheduledDate,
        'matchDateTimeComponents': matchDateTimeComponents,
      });
      return;
    }

    try {
      final androidActions = payload.actions.map((action) {
        return AndroidNotificationAction(
          action.actionId,
          action.label,
          cancelNotification: true,
          // Route through the main isolate so Drift streams (and the UI) update.
          showsUserInterface: true,
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
        playSound: true,
        category: AndroidNotificationCategory.reminder,
        actions: androidActions,
      );

      final details = NotificationDetails(android: androidDetails);

      AndroidScheduleMode scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final canExact = await androidPlugin.canScheduleExactNotifications();
        if (canExact == false) {
          scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
        }
      }

      var triggerDate = scheduledDate;
      final now = tz.TZDateTime.now(triggerDate.location);
      if (!triggerDate.isAfter(now)) {
        triggerDate = now.add(const Duration(seconds: 1));
      }

      await _plugin.zonedSchedule(
        id: id,
        title: payload.title,
        body: payload.body,
        scheduledDate: triggerDate,
        notificationDetails: details,
        payload: actionPayloadJson,
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    } catch (e) {
      debugPrint('Failed to schedule notification $id: $e');
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
    if (response.notificationResponseType ==
        NotificationResponseType.selectedNotificationAction) {
      final actionId = response.actionId ?? '';
      if (actionId == NotificationPayload.actionViewHabit) {
        _storeDeepLink(response.payload);
        return;
      }
      dispatchAction(response);
      return;
    }

    _storeDeepLink(response.payload);
  }

  static void _storeDeepLink(String? payload) {
    if (payload == null || payload.isEmpty) return;
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

  static void dispatchAction(
    NotificationResponse response, {
    bool allowBackgroundDb = false,
  }) {
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

      final delta = _asDouble(data['delta']);

      if (actionCallback != null) {
        actionCallback!(
          action: action,
          habitId: habitId,
          delta: delta,
        );
        return;
      }

      _pendingActionResponse = response;
      // On the main isolate during startup, wait for bindActionHandler so we
      // reuse the Riverpod AppDatabase instead of opening a second connection.
      if (allowBackgroundDb) {
        _handleActionInBackgroundIsolate(
          action: action,
          habitId: habitId,
          delta: delta,
        );
      }
    } catch (e) {
      debugPrint('Failed to handle notification action: $e');
    }
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return null;
  }

  static Future<void> _handleActionInBackgroundIsolate({
    required String action,
    required String habitId,
    double? delta,
  }) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      DartPluginRegistrant.ensureInitialized();

      final db = AppDatabase.backgroundInstance();
      final scheduler = FlutterHabitReminderScheduler(db.habitDao);
      final repo = HabitRepositoryImpl(
        habitDao: db.habitDao,
        habitLogDao: db.habitLogDao,
        habitShieldDao: db.habitShieldDao,
        habitCategoryDao: db.habitCategoryDao,
        reminderScheduler: scheduler,
      );
      final handler = NotificationActionHandler(repo, null, scheduler);
      await handler.handleAction(
        action: action,
        habitId: habitId,
        delta: delta,
      );
      await db.close();
    } catch (e) {
      debugPrint('Background notification action failed: $e');
    }
  }
}
