# Phase 3: Habit Detail Screen and Circular Focus Timer

## Objective

Build the dedicated Habit Detail deep-dive screen (including **archive/restore/delete**), NUMERIC/TIMER 10-dot progress bar, monthly history calendar, and the native Compose circular focus timer with foreground service execution and Play policy declaration.

## Scope of Work

### 1. Habit Detail Screen (`HabitDetailScreen`)

- **Top Navigation Bar**:
  - Back navigation with predictive back support.
  - Action overflow menu: Edit habit, Pin/Unpin, **Archive/Restore**, **Delete** (confirmation dialog). These destructive/archive actions are **detail-only** (not on daily cards).
- **Hero Header**:
  - Color-accented icon via `HabitIconRegistry` and habit title.
  - Description text, category badge, and creation date.
- **3-Metric Stats Strip**:
  - Current Streak (`X days` / `X weeks` for WEEKLY).
  - Best Streak record (`X days` / `X weeks`).
  - Total All-Time Completions (`X times`).
- **10-Dot Segmented Progress Bar (`TenDotProgressBar`)**:
  - **Show only for `NUMERIC` and `TIMER` targets.** Hide for `BOOLEAN` and for subday / times-per-day slot UIs.
  - Fill = `min(10, floor(currentValue / targetValue * 10))`.
  - Tap dot `N` (1–10) sets logged value to `ceil(N / 10.0 * targetValue)` (timer: minutes via `value` and/or equivalent duration fields per repository convention).
- **Motivation and Notes Card**:
  - Motivation card displaying custom note and reminder text.
- **Scheduled Notifications List**:
  - Active reminder times display with inline toggles (persist on habit; scheduler interface no-op until Phase 5).

### 2. Monthly History Calendar (`HabitMonthlyCalendar`)

- **Full Month Calendar Grid**:
  - Month navigation controls (`<`, `>`).
  - Day cells: filled = completed; outlined = scheduled/missed; dimmed = not scheduled (WEEKLY: all days loggable; visual “scheduled” may reflect contribution toward weekly target).
  - Tap date cell to view logs for that day.
- **Monthly Summary Metrics Strip**:
  - Completion rate, completed vs scheduled (or met weeks for WEEKLY), month best streak, total units/minutes.

### 3. Native Circular Focus Timer (`CircularFocusTimer`)

- **UI and Sweep Animation**:
  - Circular Canvas progress ring with smooth countdown animation.
  - Central `MM:SS`, Play / Pause / Reset, chips `-10m` `-5m` `+5m` `+10m`.
  - Autofill Remaining; direct minute editing dialog.
- **Background Foreground Service (`FocusTimerService`)**:
  - Foreground service with documented `foregroundServiceType` (prefer special-use or the most specific allowed type for user-initiated timers).
  - Include Play Console / manifest declaration notes in README or `docs/` as required for `FOREGROUND_SERVICE_SPECIAL_USE`.
  - Ongoing notification with countdown, progress, Pause/Resume/Stop.
  - Timestamp-based end time to avoid drift.
  - Audio chime + vibration on completion; auto-log duration to Room.

## Deliverables

- `app/src/main/java/com/productivity/habits/ui/detail/HabitDetailScreen.kt`
- `app/src/main/java/com/productivity/habits/ui/detail/HabitDetailViewModel.kt`
- `app/src/main/java/com/productivity/habits/ui/detail/CircularFocusTimer.kt`
- `app/src/main/java/com/productivity/habits/ui/detail/TenDotProgressBar.kt`
- `app/src/main/java/com/productivity/habits/ui/detail/HabitMonthlyCalendar.kt`
- `app/src/main/java/com/productivity/habits/service/FocusTimerService.kt`
- `app/src/main/java/com/productivity/habits/service/TimerStateHolder.kt`
- Manifest foreground service entries + policy declaration notes

## Acceptance Criteria

- Detail screen shows metadata, streak stats (days vs weeks), and monthly history accurately.
- Archive, restore, and delete are available from detail and are not duplicated on daily cards.
- 10-dot bar is hidden for boolean/slot habits; for numeric/timer, taps write `ceil(N/10 * target)` and UI updates reactively.
- Focus timer runs in UI and foreground notification; completion logs to Room with audio/haptic feedback.
- No Konfetti.
