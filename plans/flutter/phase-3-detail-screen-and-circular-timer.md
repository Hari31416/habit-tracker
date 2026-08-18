# Phase 3: Habit Detail Screen and Circular Focus Timer

## Objective

Build the dedicated Habit Detail view featuring the Hero header, archive/delete controls, 3-metric statistics banner, 10-dot segmented progress bar, circular focus countdown timer, and full-month history calendar by directly translating existing Kotlin implementations.

## Reference Kotlin Source Files for 1:1 Implementation

When implementing this phase, use the following Kotlin source files as direct references:

- `app/src/main/java/com/productivity/habits/ui/detail/HabitDetailScreen.kt` -> `lib/ui/detail/habit_detail_screen.dart`
- `app/src/main/java/com/productivity/habits/ui/detail/HabitDetailViewModel.kt` -> `lib/ui/detail/controllers/habit_detail_controller.dart`
- `app/src/main/java/com/productivity/habits/ui/detail/TenDotProgressBar.kt` -> `lib/ui/detail/widgets/ten_dot_progress_bar.dart`
- `app/src/main/java/com/productivity/habits/ui/detail/CircularFocusTimer.kt` -> `lib/ui/detail/widgets/circular_focus_timer.dart`
- `app/src/main/java/com/productivity/habits/ui/detail/FocusTimerScreen.kt` -> `lib/ui/detail/focus_timer_screen.dart`
- `app/src/main/java/com/productivity/habits/ui/detail/HabitMonthlyCalendar.kt` -> `lib/ui/detail/widgets/habit_monthly_calendar.dart`
- `app/src/main/java/com/productivity/habits/service/TimerStateHolder.kt` -> `lib/ui/detail/controllers/timer_state_holder.dart`

## Scope of Work

### 1. Habit Detail Screen and Actions

- Replicate `HabitDetailScreen.kt`:
  - Hero Header with large category icon, title, description, category badge, and creation date.
  - Overflow Action Menu with *Edit*, *Toggle Pin*, *Archive / Restore*, and *Delete*.
  - **Strict Constraint:** Archive and delete actions exist exclusively on this screen.

### 2. 3-Metric Statistics Banner

- 3-card stats layout matching Kotlin detail screen:
  - Current Streak (`🔥 X days` or `🔥 X weeks` for `WEEKLY` frequency).
  - Best Streak (`🏆 X days` or `🏆 X weeks`).
  - Total Completions (`✅ X times`).

### 3. 10-Dot Segmented Progress Bar

- Replicate `TenDotProgressBar.kt`:
  - Rendered for `NUMERIC` and `TIMER` habits only (hidden for `BOOLEAN` and subday slots).
  - 10 circular dots showing progress fill `min(10, floor(currentValue / targetValue * 10))`.
  - Tapping dot `N` (1 to 10) sets logged value to `ceil(N / 10.0 * targetValue)`.

### 4. Interactive Circular Focus Timer

- Replicate `CircularFocusTimer.kt`:
  - Animated circular progress sweep with theme color.
  - Central `MM:SS` countdown timer display.
  - Play, Pause, and Reset controls.
  - Stepper adjustment chips: `-10m`, `-5m`, `+5m`, `+10m`.
  - `"Autofill Remaining"` button to set timer to remaining unlogged minutes today.
  - Direct duration tap to open minute input dialog.
  - Session completion: Logs elapsed duration in Drift, plays completion audio chime, and triggers strong system haptic vibration.

### 5. Monthly History Calendar

- Replicate `HabitMonthlyCalendar.kt`:
  - Full-month grid with month steppers (`<`, `>`).
  - Scheduled vs completed day indicator circles.
  - Monthly metrics strip: Completion Rate %, Completed Days, Month's Best Streak, Total Accumulated Units/Minutes.

## Watch Out For During Execution

### 1. Focus Timer Wakelock and Battery Sleep

- **Screen Sleep Prevention:**  
  When running a focus countdown session, users expect the screen to stay awake while viewing the timer. Use `wakelock_plus` (`WakelockPlus.enable()`) when the timer is actively running, and remember to disable it (`WakelockPlus.disable()`) on pause, reset, or when leaving the screen to avoid draining battery.

### 2. Background Timer Ticking & App Lifecycle

- **Flutter Ticker Pauses in Background:**  
  Standard Flutter `AnimationController` and `Ticker` objects pause when the app is minimized. Do not rely on continuous UI ticks to calculate remaining time.
- **Timestamp Delta Calculation:**  
  Store the session `startTimestamp` and `targetDuration`. When the app returns to the foreground (`AppLifecycleState.resumed`), recalculate remaining time by comparing `DateTime.now()` with `startTimestamp` to ensure accurate elapsed time.

### 3. Audio Chime Playback on Silent Mode

- **Audio Session Initialization:**  
  Configure `audioplayers` or `just_audio` with appropriate audio session modes (e.g. `AVAudioSessionCategoryPlayback` on iOS) so the timer completion chime plays audibly even if the user has their hardware mute switch engaged.

## Deliverables

- `lib/ui/detail/habit_detail_screen.dart`
- `lib/ui/detail/widgets/detail_hero_header.dart`
- `lib/ui/detail/widgets/stats_metric_strip.dart`
- `lib/ui/detail/widgets/ten_dot_progress_bar.dart`
- `lib/ui/detail/widgets/circular_focus_timer.dart`
- `lib/ui/detail/widgets/habit_monthly_calendar.dart`
- `lib/ui/detail/widgets/motivation_card.dart`
- `lib/ui/detail/controllers/habit_detail_controller.dart`
- `lib/ui/detail/controllers/focus_timer_controller.dart`
- `test/ui/habit_detail_screen_test.dart`

## Acceptance Criteria

- All components match the exact visual styling and behavior of `HabitDetailScreen.kt`, `TenDotProgressBar.kt`, `CircularFocusTimer.kt`, and `HabitMonthlyCalendar.kt`.
- 10-dot progress bar accurately calculates and updates values using the `ceil(N / 10.0 * targetValue)` formula.
- Focus timer countdown operates smoothly, accurately accounts for background lifecycle state, and records elapsed time in Drift.
