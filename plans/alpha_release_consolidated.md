# Alpha release work brief for agent

**App:** Habit Tracker (`com.productivity.habits`)  
**Version today:** `0.7.0+8`  
**Scope:** Android alpha only. Do not treat iOS as in-scope.  
**Verdict:** Not ready. Two production-path gaps (reminders and day rollover) will fail for testers who leave the app closed. Fix those first, then the P1 items, then ship a signed APK.

Use this document as the implementation checklist.

## How to use this document

- Implement in priority order: P0, then P1, then P2. Do not start P3/optional work until P0 and P1 are done.
- Keep changes small and follow existing patterns (Riverpod providers, Drift DAOs, `NotificationService`, native Kotlin widgets/timer).
- Do not add new packages unless a P0/P1 item cannot be done with current dependencies. If you add one, justify it in the PR/commit body.
- After domain, scheduler, Drift, or repository changes: `make test`. After Drift table changes: `make codegen` then `make build`.
- Do not enable R8/ProGuard in this pass. Enabling it without tested keep rules is likelier to break plugins than to help the alpha.
- Do not implement iOS notifications, WidgetKit, or App Groups.

## P0 must fix before alpha

### 1. Recurring habit reminders

**Problem:** `FlutterHabitReminderScheduler` computes the next occurrence and `NotificationService.scheduleNotification` calls `zonedSchedule` once with no `matchDateTimeComponents`. After the alarm fires, nothing schedules the following day unless Dart runs `schedule` / `rescheduleAll`.

Reschedule currently happens only on:

- Cold start in `main.dart` (`rescheduleAll`)
- Habit create/update/unarchive in `HabitRepositoryImpl`
- Notification action buttons in `NotificationActionHandler` (Mark done / Add delta)

It does **not** happen on:

- App resume (`didChangeAppLifecycleState` only consumes widget actions)
- Notification body tap / dismiss
- Check-in from the in-app UI
- After the notification fires while the process is dead

Boot restore via `ScheduledNotificationBootReceiver` only re-posts alarms the plugin still has stored. Fired one-shots are gone.

**Files:**

- `lib/data/schedulers/flutter_habit_reminder_scheduler.dart`
- `lib/services/notification_service.dart` (`scheduleNotification`, ~199–224)
- `lib/main.dart` (startup pipeline and lifecycle)
- `lib/data/schedulers/notification_action_handler.dart`
- `android/app/src/main/AndroidManifest.xml` (boot receiver already present)

**Required implementation:**

1. After each reminder is delivered or cancelled by the user, schedule the next occurrence for that habit/time index. Prefer doing this in the notification response path **and** by making `zonedSchedule` recurring where the frequency model allows it.
2. Daily / times-per-day / weekly (any calendar day): use repeating schedule components (`DateTimeComponents.time`) **or** an equivalent one-shot-plus-reschedule that is proven to run with the app killed.
3. Custom days: repeating `dayOfWeekAndTime` is not enough for arbitrary weekday sets. Keep next-occurrence calculation (`_calculateNextOccurrence` / `_isHabitScheduledOnDate`) and chain the following fire after each delivery.
4. Call `rescheduleAll()` on `AppLifecycleState.resumed` in addition to cold start (cheap safety net; not a substitute for killed-app recurrence).
5. After in-app check-in (`logCheckIn` / toggle / numeric update), reschedule that habit’s reminders if they are enabled.
6. Exact-alarm denied: keep the existing fallback to `AndroidScheduleMode.inexactAllowWhileIdle`. Do not crash.
7. Do not request notification/exact-alarm permission on every launch as part of this fix; that is P1. Scheduling must still work after permission is granted later.

**Acceptance:**

- With the app force-stopped, a daily reminder fires on day 1 and again on day 2 at the same time without opening the app.
- Custom-days habit only fires on selected weekdays.
- Reboot before the next fire still delivers the pending reminder (`RECEIVE_BOOT_COMPLETED` path).
- Completing a habit from the notification action still logs the check-in and schedules the next fire.
- Unit tests cover next-occurrence for daily, weekly, and custom days, including “already fired today.”
- Add or extend tests in `test/services/flutter_habit_reminder_scheduler_test.dart` and `test/services/local_notifications_scheduler_test.dart`. Device/manual steps belong in the alpha test plan at the bottom of this file.

### 2. Day rollover actually runs

**Problem:** `DayRolloverTask.executeRollover` is the only production caller of `autoProtectMissedDays`. `dayRolloverTaskProvider` is never read outside `lib/di/providers.dart`. There is no WorkManager, AlarmManager, or startup invocation. Shield auto-protect and midnight widget refresh never happen, even when the user opens the app the next day.

**Files:**

- `lib/data/background/day_rollover_task.dart`
- `lib/di/providers.dart` (`dayRolloverTaskProvider`)
- `lib/data/repositories/habit_repository_impl.dart` (`autoProtectMissedDays`)
- `lib/services/widget_sync_service.dart`
- `test/services/day_rollover_task_test.dart`

**Required implementation (minimum for alpha):**

1. On every cold start **and** resume, run rollover for local “yesterday” if it has not already run for that calendar date. Persist the last successful rollover date (SharedPreferences is fine) so it is idempotent.
2. `executeRollover` must: `autoProtectMissedDays(yesterday)`, then `syncAllWidgets` for today.
3. Register a durable Android scheduler so rollover still runs if the app stays closed overnight. Prefer a supported Flutter WorkManager integration **or** a native `WorkManager`/`AlarmManager` worker that can enter Dart / call the same logic. Reschedule after boot and app update (manifest already has `BOOT_COMPLETED` / `MY_PACKAGE_REPLACED` for notifications; extend similarly).
4. Stop swallowing errors with `catch (_) { return false; }`. Log and return false.
5. If you add `workmanager` (or similar), wire a `@pragma('vm:entry-point')` callback, use `AppDatabase.backgroundInstance()`, and do not open a second Drift connection on the UI isolate.

**Acceptance:**

- Opening the app the day after a missed habit applies shields when the user has banked shields and auto-consume is on, without a separate manual action.
- Widgets show the new calendar day’s counts after rollover, not yesterday’s snapshot.
- Rollover does not double-apply shields if startup and the background worker both run.
- Existing `test/services/day_rollover_task_test.dart` still passes; add tests for delay-to-midnight and “already ran today.”
- Manual: app killed over midnight, then either worker runs or next cold start catches up.

## P1 should fix before alpha

### 3. Explicit backup and privacy policy

**Problem:** `<application>` in the main manifest does not set `android:allowBackup` or data-extraction rules. Auto Backup defaults on and will include `habit_tracker.sqlite` plus SharedPreferences (habit titles, notes, mood, energy). There is no privacy policy file in the repo.

**Files:**

- `android/app/src/main/AndroidManifest.xml`
- `lib/data/local/app_database.dart` (DB path under app documents)

**Required implementation:**

For this alpha, **disable backup** unless product explicitly wants Drive restore:

```xml
<application
    android:allowBackup="false"
    android:fullBackupContent="false"
    android:dataExtractionRules="@xml/data_extraction_rules"
    ...>
```

Add `android/app/src/main/res/xml/data_extraction_rules.xml` that disallows cloud backup and device-transfer of the DB if you keep extraction rules. If product later wants backup, replace this with a narrow allow-list and test restore.

Add a short `PRIVACY.md` stating: fully offline, no network in release, local SQLite, no account, backup disabled for alpha. Point testers at it from `README.md`.

**Acceptance:** Manifest is explicit. Release APK does not opt into Auto Backup. Privacy note exists.

### 4. Exact-alarm and notification permission flow

**Problem:** Manifest declares both `SCHEDULE_EXACT_ALARM` and `USE_EXACT_ALARM`. `main.dart` calls `NotificationService.requestPermission()` on every cold start, which requests notifications **and** exact alarms with no explanation. `USE_EXACT_ALARM` is Play-restricted to core calendar/alarm/timer apps.

**Files:**

- `android/app/src/main/AndroidManifest.xml`
- `lib/main.dart`
- `lib/services/notification_service.dart`
- Habit form reminder UI (`lib/ui/form/`)

**Required implementation:**

1. Remove `USE_EXACT_ALARM`. Keep `SCHEDULE_EXACT_ALARM` plus `POST_NOTIFICATIONS`.
2. Do not prompt on startup. Prompt when the user first enables a reminder time on a habit.
3. Copy should say reminders need notification access; exact alarms are optional for punctuality.
4. If notifications denied: do not schedule; show a durable in-app hint to open system settings.
5. If exact alarms denied: schedule inexact (already partially implemented) and do not loop the system dialog.
6. Re-check permission and `rescheduleAll` on resume after the user returns from settings.

**Acceptance:** Fresh install never shows a permission dialog before the user opts into reminders. Denied exact alarm still delivers inexact reminders. Denied notifications never schedule.

### 5. Map `app://habits` URIs to Flutter routes

**Problem:** Widgets and shortcuts emit `app://habits/daily`, `app://habits/detail/{id}`, `app://habits/badges`. `MaterialApp.onGenerateRoute` only understands `detail/` and `focus_timer/` prefixes (plus named screens). There is no `getInitialIntent` / `onNewIntent` bridge in `MainActivity`. Notification taps that set `pendingDeepLink = 'detail/$habitId'` work; widget deep links likely open Daily instead of the intended screen. Empty `habitId` is not rejected.

**Files:**

- `lib/main.dart` (`onGenerateRoute`, `_handlePendingDeepLink`)
- `android/app/src/main/kotlin/com/productivity/habits/MainActivity.kt`
- `android/app/src/main/kotlin/com/productivity/habits/widgets/HabitWidgetReceivers.kt`
- `lib/ui/navigation/screen.dart`

**Required implementation:**

1. On launch and `onNewIntent`, read `Intent.data` and convert:
   - `app://habits/daily` → Daily
   - `app://habits/detail/{id}` → Habit detail if `id` is non-empty
   - `app://habits/badges` → Badges
   - `app://habits/focus_timer/{id}` if used
2. Ignore empty or malformed ids; stay on Daily.
3. Keep existing notification `pendingDeepLink` path working.

**Acceptance:** From the streaks widget, tapping a habit opens that habit’s detail. Badges widget card opens badges. Garbage `habitId` does not push a blank detail screen.

## P2 do if time remains before tag

### 6. Startup and notification error logging

Replace empty `catch (_) {}` in `lib/main.dart` (timezone, notification init, widget sync) and the `catch` in `DayRolloverTask` / `NotificationService.init` with logged warnings. Do not rethrow on the startup microtask.

Replace `debugPrint` in `lib/services/notification_service.dart` (schedule failure, action failure, background action failure) with the project logger.

`NotificationService.hasPermission` / `requestPermission` currently return `true` on exception (fail-open). Fail **closed** for `hasPermission` (return false). `requestPermission` should return false on failure, not true.

### 7. Analyzer noise so `make lint` is a real gate

All 72 issues are under `test/benchmark/`. Either:

- Exclude `test/benchmark/**` in `analysis_options.yaml`, or
- Remove unused imports and wrap benchmark `print`s with `// ignore: avoid_print`

Then add `flutter analyze` (or `make lint`) as a step in `.github/workflows/ci.yml` so CI matches `RELEASE_PROCESS.md`.

Pin Flutter in CI (`flutter-version` from a known-good SDK, not only `channel: stable`). Pinning Actions to SHAs is nice-to-have, not required to ship alpha.

### 8. Alpha version string and changelog

Set `pubspec.yaml` to an obvious alpha, for example `0.8.0-alpha.1+9` (keep `+build` monotonically increasing). Add a `CHANGELOG.md` section that lists alpha limitations: no iOS, reminders/rollover behavior after the P0 fixes, backup disabled.

### 9. Widget toggle broadcast hardening

`TodaysHabitsWidgetReceiver` is `exported="true"` (required for `AppWidgetProvider`) and handles `ACTION_TOGGLE_HABIT` without a caller check. Untrusted apps can send the broadcast if they guess a habit UUID.

Keep the provider exported. Validate a per-install nonce (or `PendingIntent` package identity) before writing `pending_toggled_habit_ids`. Ignore empty/malformed ids. Do not change widget check-in UX.

### 10. Seed data for testers

`DatabaseSeeder.seedIfEmpty` inserts demo habits on first launch. That is useful for alpha. Add a visible “demo data” affordance or first-run copy so testers know they can delete those habits. Do not remove seeding unless product asks.

## P3 out of scope for this alpha

Do **not** spend time on these unless P0–P1 are done and you still have leftover capacity:

- R8 `isMinifyEnabled` / `isShrinkResources` / ProGuard rules
- Riverpod 3 / `flutter_timezone` major upgrades / `sqlite3_flutter_libs` replacement
- Wiring `AppShortcutsService` / `quick_actions` (provider exists, never called)
- Deduplicating `LocalNotificationsScheduler` vs `FlutterHabitReminderScheduler`
- `focusTimerBackgroundServiceProvider` (native `FocusTimerService` is the real timer)
- iOS `DarwinInitializationSettings`, WidgetKit, signing
- Crashlytics/Sentry
- Full DAO-to-UI integration test suite
- Restricting `ACCESS_NOTIFICATION_POLICY` (needed for optional focus DND)

## Do not regress

- Release manifest must stay without `INTERNET`.
- Drift parameterized queries only; no raw string-built SQL from UI input.
- Widget `PendingIntent`s stay `FLAG_IMMUTABLE`.
- `FocusTimerService` stays `exported="false"` with `foregroundServiceType="specialUse"`.
- Notification action receivers stay `exported="false"`.
- Signing continues to load keystore from env / gitignored `key.properties` only.
- Streak rules in `AGENTS.md` (daily / weekly ISO / custom-day skip) stay unchanged.

## Suggested implementation order

1. Reminder recurrence + resume `rescheduleAll` + tests
2. Rollover on startup/resume with last-run date, then background scheduler
3. Backup disabled + `PRIVACY.md`
4. Permission prompts only when enabling reminders; drop `USE_EXACT_ALARM`
5. Deep-link URI mapping
6. Logging / fail-closed permission helpers
7. Analyzer exclude or fix + CI `flutter analyze`
8. Alpha version + changelog
9. Widget nonce if time

## Alpha test plan the agent should not skip

Run after code changes, on a physical device if possible (emulator is acceptable for functional checks except Doze).

- [ ] `make test` passes
- [ ] `make lint` passes (after P2 analyzer cleanup) or production-only analyze is clean
- [ ] `make build-release` produces a signed APK (needs local keystore / CI secrets)
- [ ] Fresh install: no permission dialog until a reminder is enabled
- [ ] Enable a daily reminder, force-stop the app, wait for fire, wait for the next day’s fire (or time-travel / short test interval if you add one behind a debug flag)
- [ ] Custom-days reminder skips a non-selected weekday
- [ ] Reboot with a pending reminder; it still fires
- [ ] Notification Mark done writes a log and the next reminder is scheduled
- [ ] Miss a day with shields available, keep app killed overnight (or trigger rollover); next open/worker auto-protects
- [ ] Home widget toggle check-in applies after next app open
- [ ] Widget deep link opens the correct screen
- [ ] Focus timer foreground service survives leaving the detail screen
- [ ] Notification permission denied: no crash, no reminders
- [ ] Exact alarm denied: reminder still appears, possibly late
- [ ] Airplane mode / no INTERNET: app fully usable
- [ ] iOS is not distributed

## Done definition

Alpha may be tagged when:

1. P0 items 1 and 2 are implemented and covered by tests plus at least one device pass for killed-app reminders and rollover catch-up.
2. P1 items 3–5 are implemented.
3. A signed release APK/AAB builds.
4. Changelog and version string identify the build as alpha.
5. iOS is explicitly out of the GitHub release notes.
