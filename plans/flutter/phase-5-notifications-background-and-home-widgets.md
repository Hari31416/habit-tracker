# Phase 5: Notifications, Background Sync, and Home Screen Widgets

## Objective

Implement native notification scheduling, interactive notification check-ins, WorkManager background maintenance, dynamic app shortcuts, and Home Screen Widgets by referencing existing Kotlin background services, receivers, and workers.

## Reference Kotlin Source Files for 1:1 Implementation

When implementing this phase, use the following Kotlin source files as direct references:

- `app/src/main/java/com/productivity/habits/scheduler/AlarmHabitReminderScheduler.kt` -> `lib/data/schedulers/local_notifications_scheduler.dart`
- `app/src/main/java/com/productivity/habits/receiver/HabitReminderReceiver.kt` -> `lib/data/schedulers/notification_channel_handler.dart`
- `app/src/main/java/com/productivity/habits/receiver/HabitActionReceiver.kt` -> `lib/data/schedulers/notification_action_handler.dart`
- `app/src/main/java/com/productivity/habits/receiver/BootReceiver.kt` -> Handled by `flutter_local_notifications` auto-reschedule
- `app/src/main/java/com/productivity/habits/scheduler/DayRolloverWorker.kt` -> `lib/data/background/day_rollover_task.dart`
- `app/src/main/java/com/productivity/habits/scheduler/WidgetUpdateWorker.kt` -> `lib/services/widget_sync_service.dart`
- `app/src/main/java/com/productivity/habits/service/FocusTimerService.kt` -> `lib/services/focus_timer_background_service.dart`

## Scope of Work

### 1. Local Notifications and Action Buttons

- Replicate behavior of `AlarmHabitReminderScheduler.kt` and `HabitReminderReceiver.kt`:
  - Schedule exact notifications with high-priority channel settings.
  - Interactive `"Check-In (+1)"` action button directly on the notification shade (matching `HabitActionReceiver.kt` to record check-in without launching app).
  - Deep linking: Tapping notification body opens Habit Detail (`app://habits/detail/{habitId}`).

### 2. Background Sync and Day Rollover

- Replicate behavior of `DayRolloverWorker.kt`:
  - Periodic background task via `workmanager` running around midnight to refresh today's progress state and prune expired notifications.

### 3. Dynamic App Shortcuts

- Use `quick_actions` to expose top 3 pinned habits for instant check-in from long-press app icon.

### 4. Home Screen Widgets (`home_widget`)

- Replicate behavior of `WidgetUpdateWorker.kt`:
  - Quick-Log Widget (4x2 / 4x1): Top 3–4 pinned habits with single-tap check-in buttons and streak counters.
  - Daily Focus Widget (2x2): Circular progress ring, today's completed count (`4/6 Completed`), and top streak badge.
  - Synchronizes Drift database state to Android Glance AppWidgets and iOS WidgetKit.

## Watch Out For During Execution

### 1. Exact Alarm Permissions & OEM Battery Optimizations

- **Android 13+ (API 33+) Runtime Permissions:**  
  Declare `android.permission.POST_NOTIFICATIONS` and `android.permission.SCHEDULE_EXACT_ALARM` in `android/app/src/main/AndroidManifest.xml`. Always check `canScheduleExactAlarms()` at runtime before scheduling. If the user revokes exact alarm permission, fall back to inexact periodic scheduling via `workmanager`.
- **Aggressive OEM Battery Savers:**  
  Devices from manufacturers like Xiaomi (MIUI), Samsung (OneUI), and Huawei terminate background alarms and workers unless battery optimization is disabled. Provide a clean settings link or prompt directing users to exclude the app from aggressive battery optimizations.
- **iOS Authorization:**  
  Request `alert`, `badge`, and `sound` permissions via `flutter_local_notifications` during initialization.

### 2. Home Screen Widget Bridging & App Groups

- **No Direct Flutter Widget Rendering:**  
  Flutter cannot render inside Android AppWidgets or iOS WidgetKit extensions. You must write native view layouts:
  - **Android:** Glance Composable or XML `RemoteViews` in `android/app/src/main/kotlin/.../widgets/`.
  - **iOS:** SwiftUI `Widget` and `TimelineProvider` in `ios/HabitWidgetExtension/`.
- **iOS App Group Configuration:**  
  Configure an `App Group` identifier (e.g. `group.com.productivity.habits`) in Apple Developer settings and Xcode capabilities. Both the main Flutter app and the Widget Extension must be members of this App Group to read shared data from `home_widget`.
- **Android SharedPreferences Group:**  
  Configure `home_widget` to write to a dedicated named `SharedPreferences` file that the Glance widget receiver reads.

### 3. Background Dart Isolates and Database Concurrency

- **Isolate Entry Points:**  
  When an interactive notification action (`Check-In (+1)`) or a `workmanager` task fires, it executes in a separate background Dart isolate.
- **Top-Level Callback Annotation:**  
  Ensure background handlers are top-level or static functions annotated with `@pragma('vm:entry-point')` so they are not stripped by tree-shaking during release builds (`flutter build apk` / `flutter build ipa`).
- **Drift DB Access in Isolates:**  
  Instantiate the Drift database with proper SQLite file locks or isolate connections to avoid database corruption or locked transaction errors when both the UI isolate and background isolate write simultaneously.

## Deliverables

- `lib/data/schedulers/local_notifications_scheduler.dart`
- `lib/data/schedulers/notification_action_handler.dart`
- `lib/data/background/background_worker.dart`
- `lib/services/app_shortcuts_service.dart`
- `lib/services/widget_sync_service.dart`
- `android/app/src/main/kotlin/.../widgets/` (Glance widget provider)
- `ios/Runner/` & `ios/HabitWidgetExtension/` (WidgetKit SwiftUI implementation)
- `test/services/local_notifications_scheduler_test.dart`

## Acceptance Criteria

- Scheduled notifications fire at exact times with interactive check-in action buttons matching `HabitActionReceiver.kt`.
- Background handlers are decorated with `@pragma('vm:entry-point')` and successfully log completions across isolates.
- App shortcuts appear on long-pressing the app icon and deep-link or check-in habits.
- Home screen widgets update immediately when check-ins are logged inside or outside the app.
- Midnight rollover background worker runs without unhandled exceptions.
