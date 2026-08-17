# Phase 5: Native Notifications, WorkManager, and Glance Widgets

## Objective

Wire system integration: AlarmManager exact reminders with interactive check-in actions, WorkManager for midnight rollover / inexact fallback / widget maintenance, boot receiver, and Jetpack Glance Home Screen widgets. Haptics already shipped in Phases 2a/2b — **do not add Konfetti**.

## Scope of Work

### 1. AlarmManager and Notification System

- **Reminder Scheduler (`AlarmHabitReminderScheduler`)**:
  - Replace Hilt binding: `HabitReminderScheduler` → AlarmManager + WorkManager-backed implementation (remove no-op for release builds).
  - Exact alarms via `AlarmManager.setExactAndAllowWhileIdle()` when permitted.
  - Notification channel setup (high importance, vibration).
  - Re-schedule on habit update and significant time change.
- **Broadcast Receivers**:
  - `HabitReminderReceiver`: habit title, color, deep link, "+1 Check-in" action.
  - `HabitActionReceiver`: Room check-in, update/dismiss notification, trigger widget refresh.
  - `BootReceiver`: `ACTION_BOOT_COMPLETED` → `rescheduleAll()`.
- **Permission Flow**:
  - `POST_NOTIFICATIONS` (API 33+).
  - `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` with settings deep link when denied.
  - **Fallback:** when exact alarms are unavailable, enqueue WorkManager flexible windows approximating reminder times (inexact).

### 2. WorkManager Maintenance

- **Midnight day-rollover worker:** schedule next local midnight (and/or periodic) to refresh day-bound UI caches, cancel obsolete same-day notifications, and request widget updates.
- **Reminder reconcile worker:** used after boot, habit edits, and as inexact alarm fallback.
- **Widget update worker:** update Glance state when logs change and app process may not be foregrounded.

### 3. Jetpack Glance Home Screen Widgets

- **Quick-Log Habit Widget (4x2 / 4x1)**:
  - Top 3–4 pinned or active habits; Glance `ActionCallback` check-in; streak + daily progress.
- **Daily Focus Widget (2x2)**:
  - Today adherence ring, `completed/total`, top streak badge.
- **Widget Receiver and Update Trigger**:
  - `HabitWidgetReceiver`; update on log changes and from WorkManager.

### 4. Polish Boundary

- Verify light/heavy haptics from 2a/2b still feel correct from notification-driven updates (optional).
- Explicitly **out of scope:** Konfetti, particle systems, new celebration libraries.

## Deliverables

- `app/src/main/java/com/productivity/habits/scheduler/AlarmHabitReminderScheduler.kt`
- `app/src/main/java/com/productivity/habits/scheduler/DayRolloverWorker.kt`
- `app/src/main/java/com/productivity/habits/scheduler/ReminderReconcileWorker.kt`
- `app/src/main/java/com/productivity/habits/scheduler/WidgetUpdateWorker.kt`
- `app/src/main/java/com/productivity/habits/receiver/HabitReminderReceiver.kt`
- `app/src/main/java/com/productivity/habits/receiver/HabitActionReceiver.kt`
- `app/src/main/java/com/productivity/habits/receiver/BootReceiver.kt`
- `app/src/main/java/com/productivity/habits/widget/QuickLogHabitWidget.kt`
- `app/src/main/java/com/productivity/habits/widget/DailyFocusWidget.kt`
- `app/src/main/java/com/productivity/habits/widget/HabitWidgetReceiver.kt`
- `app/src/main/res/xml/quick_log_widget_info.xml`
- `app/src/main/res/xml/daily_focus_widget_info.xml`
- Hilt module update binding `HabitReminderScheduler` to the real implementation
- Manifest permissions, receivers, and WorkManager configuration

## Acceptance Criteria

- Exact reminders fire at configured times when permission granted; inexact WorkManager fallback used otherwise.
- Notification "+1 Check-in" increments logs and refreshes widgets without opening the app.
- Midnight rollover worker runs and refreshes day-sensitive widget/notification state.
- Reboot restores reminders via `BootReceiver` + `rescheduleAll()`.
- Glance widgets show today progress and support 1-tap logging.
- No Konfetti dependency in the project.
