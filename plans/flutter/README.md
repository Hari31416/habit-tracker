# Habit Tracker Flutter Migration Plans

Master architecture specification and phase-wise migration roadmap for building the standalone Flutter Habit Tracker application with 100% feature, UI, and logic parity with the existing native Android Kotlin codebase.

## Core Principle: Direct 1:1 Kotlin Reference Implementation

The foundational directive for this migration is **do not reinvent the wheel**. Every Flutter model, calculation engine, Drift table, DAO query, Riverpod controller, and widget layout must directly reference and port the corresponding Kotlin implementation in `app/src/main/java/com/productivity/habits/`.

All calculations, algorithms, UI paddings, colors, shapes, haptic strengths, and lifecycle behaviors in Flutter must match the Kotlin source with exact parity.

## Overview

The migration is structured into six sequential phases:

- [Phase 1: Project Setup and Data Architecture](phase-1-project-setup-and-data-architecture.md)
- [Phase 2a: Daily Tracker Core and Boolean Cards](phase-2a-daily-tracker-core-and-boolean-cards.md)
- [Phase 2b: Numeric / Timer / Slots and Habit Form](phase-2b-numeric-timer-slots-and-habit-form.md)
- [Phase 3: Habit Detail Screen and Circular Focus Timer](phase-3-detail-screen-and-circular-timer.md)
- [Phase 4: Week Matrix and Analytics](phase-4-week-matrix-and-analytics.md)
- [Phase 5: Notifications, Background Sync, and Home Screen Widgets](phase-5-notifications-background-and-home-widgets.md)

## Direct Kotlin-to-Flutter 1:1 Source File Mapping

### Domain Calculation Engines and Gamification

| Existing Kotlin Source File | Target Flutter / Dart File | Parity Requirement |
| - | - | - |
| `domain/engine/StreakCalculator.kt` | `lib/domain/engines/streak_calculator.dart` | 100% logic parity: ISO Monday–Sunday week boundaries, `targetCountPerWeek`, week-unit streaks, in-progress day/week preservation, 30-day adherence. |
| `domain/engine/DynamicStepEngine.kt` | `lib/domain/engines/dynamic_step_engine.dart` | 100% logic parity: Magnitude-aware step sizes and quick-add arrays for `ml`, `l`, `steps`, `cal`, `kcal`, and general numbers. |
| `domain/engine/SubdaySlotEngine.kt` | `lib/domain/engines/subday_slot_engine.dart` | 100% logic parity: Time window splitting into discrete timestamped slot intervals. |
| `domain/gamification/GamificationEngine.kt` | `lib/domain/gamification/gamification_engine.dart` | 100% logic parity: XP scaling, streak multipliers (1.25x, 1.5x, 2.0x), and level thresholds. |
| `domain/gamification/AchievementEvaluator.kt` | `lib/domain/gamification/achievement_evaluator.dart` | 100% logic parity: 20+ achievement unlocks based on streaks, totals, and diversity. |
| `domain/gamification/AchievementDefinitions.kt` | `lib/domain/gamification/achievement_definitions.dart` | 100% data parity: Exact badge metadata, titles, and icons. |
| `domain/gamification/PlayerTitle.kt` | `lib/domain/gamification/player_title.dart` | 100% enum parity: Titles from Novice to Grandmaster. |

### Data Persistence and Local Database

| Existing Kotlin Source File | Target Flutter / Dart File | Parity Requirement |
| - | - | - |
| `data/local/entity/HabitEntity.kt` | `lib/data/local/tables/habits.dart` | 100% schema parity: All columns, defaults, enums (`HabitFrequencyType`, `HabitTargetType`), and constraints. |
| `data/local/entity/HabitLogEntity.kt` | `lib/data/local/tables/habit_logs.dart` | 100% schema parity: Foreign key cascade, date indexing (`yyyy-MM-dd`), `intervalIndex`, `durationSeconds`. |
| `data/local/entity/HabitCategoryEntity.kt` | `lib/data/local/tables/habit_categories.dart` | 100% schema parity: Category ID, name, color, and icon. |
| `data/local/entity/UserGamificationEntity.kt` | `lib/data/local/tables/user_gamification.dart` | 100% schema parity: Total XP, current level, current title. |
| `data/local/entity/AchievementEntity.kt` | `lib/data/local/tables/achievements.dart` | 100% schema parity: Unlocked state and timestamp. |
| `data/local/dao/HabitDao.kt` | `lib/data/local/daos/habit_dao.dart` | 1:1 Drift DAO queries with reactive Streams (`watchActiveHabits`, `watchPinnedHabits`). |
| `data/local/dao/HabitLogDao.kt` | `lib/data/local/daos/habit_log_dao.dart` | 1:1 Drift DAO queries with date range Streams (`watchLogsBetween`). |
| `data/local/PrepopulateDataCallback.kt` | `lib/data/local/database_seeder.dart` | Seeds exact 6 default categories (*Health and Fitness*, *Mindfulness*, *Learning*, *Productivity*, *Personal*, *Routine*). |

### UI Themes, Common Utilities, and Navigation

| Existing Kotlin Source File | Target Flutter / Dart File | Parity Requirement |
| - | - | - |
| `ui/theme/Color.kt`, `Theme.kt` | `lib/ui/theme/app_theme.dart` | Exact color hex codes (`#0A7A64`, `#10B981`, etc.) and Material 3 light/dark schemes. |
| `ui/theme/Shape.kt`, `Type.kt` | `lib/ui/theme/app_shapes.dart`, `app_typography.dart` | Exact 16dp card radii and Material 3 text hierarchy. |
| `ui/common/HabitIconRegistry.kt` | `lib/ui/common/habit_icon_registry.dart` | Exact string key to icon resolution with fallback. |
| `ui/common/HapticsHelper.kt` | `lib/ui/common/haptics_helper.dart` | Exact haptic mappings: `heavyImpact` on completion, `selectionClick` on step/pin. |
| `ui/navigation/HabitNavGraph.kt` | `lib/ui/navigation/app_router.dart` | Bottom navigation between Daily, Week Matrix, and Analytics; deep-link routes. |

### Daily Tracker Screen

| Existing Kotlin Source File | Target Flutter / Dart File | Parity Requirement |
| - | - | - |
| `ui/daily/DailyTrackerScreen.kt` | `lib/ui/daily/daily_tracker_screen.dart` | Exact top bar, segmented controls, quick-add bar, and habit list layout. |
| `ui/daily/RollingWeekStrip.kt` | `lib/ui/daily/widgets/rolling_week_strip.dart` | 7-day horizontal strip centered on selected date with completion dots and `<` `>` steppers. |
| `ui/daily/HistoricalBanner.kt` | `lib/ui/daily/widgets/historical_banner.dart` | Amber container *"Viewing [Date]"* with `"Return to Today"` button. |
| `ui/daily/QuickAddBar.kt` | `lib/ui/daily/widgets/quick_add_bar.dart` | Inline title input, category dropdown, and one-tap creation. |
| `ui/daily/HabitCard.kt` | `lib/ui/daily/widgets/habit_card.dart` | Header strip, category badge, pin star toggle, streak flame pill, and card tap to detail. No archive/delete on card. |
| `ui/daily/NumericHabitControls.kt` | `lib/ui/daily/widgets/numeric_habit_controls.dart` | Progress bar, current/target label, stepper `-` `+` buttons, and dynamic quick-add chips. |
| `ui/daily/DirectNumericInputDialog.kt` | `lib/ui/daily/dialogs/direct_numeric_input_dialog.dart` | Inline pencil button dialog for direct number entry. |
| `ui/daily/TimerHabitControls.kt` | `lib/ui/daily/widgets/timer_habit_controls.dart` | Progress bar, quick +5m/+10m chips, and "Start Focus" button. |
| `ui/daily/SlotHabitControls.kt` | `lib/ui/daily/widgets/slot_habit_controls.dart` | Horizontal slot pills with independent toggle check-ins. |

### Habit Detail and Focus Timer

| Existing Kotlin Source File | Target Flutter / Dart File | Parity Requirement |
| - | - | - |
| `ui/detail/HabitDetailScreen.kt` | `lib/ui/detail/habit_detail_screen.dart` | Overflow menu with Edit, Pin, Archive, Delete (archive/delete restricted to here). |
| `ui/detail/TenDotProgressBar.kt` | `lib/ui/detail/widgets/ten_dot_progress_bar.dart` | 10-dot progress bar for numeric/timer habits; tap dot `N` sets `ceil(N / 10.0 * targetValue)`. |
| `ui/detail/CircularFocusTimer.kt` | `lib/ui/detail/widgets/circular_focus_timer.dart` | Circular progress ring, `MM:SS` display, play/pause/reset, stepper chips, and autofill remaining. |
| `ui/detail/HabitMonthlyCalendar.kt` | `lib/ui/detail/widgets/habit_monthly_calendar.dart` | Full-month grid with scheduled/completed day circles and monthly metric summary. |

### Habit Creation Form

| Existing Kotlin Source File | Target Flutter / Dart File | Parity Requirement |
| - | - | - |
| `ui/form/HabitFormBottomSheet.kt` | `lib/ui/form/habit_form_bottom_sheet.dart` | Modal sheet with title, description, category selector, 8 color presets, icon picker, target type selector, frequency recurrence rules, and multi-reminder section. |

### Week Matrix, Analytics, and Gamification

| Existing Kotlin Source File | Target Flutter / Dart File | Parity Requirement |
| - | - | - |
| `ui/matrix/HabitWeekMatrixScreen.kt` | `lib/ui/matrix/habit_week_matrix_screen.dart` | ISO Monday–Sunday grid, completion summary card, and weekday distribution bar chart. |
| `ui/analytics/HabitAnalyticsScreen.kt` | `lib/ui/analytics/habit_analytics_screen.dart` | Top 3 KPI cards, top 5 streaks leaderboard, 7d/30d adherence trend area chart, and density heatmap. |
| `ui/gamification/PlayerLevelHeaderBadge.kt` | `lib/ui/gamification/widgets/player_level_header_badge.dart` | Level badge with animated XP progress bar. |
| `ui/gamification/BadgesShowcaseScreen.kt` | `lib/ui/gamification/badges_showcase_screen.dart` | Grid of unlocked and locked achievement badges. |
| `ui/gamification/LevelUpCelebrationDialog.kt` | `lib/ui/gamification/dialogs/level_up_celebration_dialog.dart` | Level-up modal with title unlock announcement and celebratory haptics. |

## Watch Out For During Execution (Platform Considerations)

### 1. Native Home Screen Widgets

- **Constraint:** Flutter cannot draw directly into the home screen widget process on Android or iOS.
- **Solution:** Use the `home_widget` package as a data synchronization bridge.
- **Android Implementation:** Write the widget UI using Android Jetpack Glance or XML `RemoteViews` in `android/app/src/main/kotlin/.../widgets/`. Read serialized data from `SharedPreferences`.
- **iOS Implementation:** Write the widget UI using SwiftUI / WidgetKit in an iOS App Extension (`ios/HabitWidgetExtension/`). Configure an `App Group` (`group.com.productivity.habits`) to share data from Flutter `UserDefaults`.
- **Background Actions:** For single-tap check-ins from widgets without opening the app, Android uses an `ActionCallback` / `BroadcastReceiver`, and iOS uses `AppIntent` (iOS 17+) or URL schemes with background completion.

### 2. Permissions and Exact Alarm Nuances

- **Android 13+ (API 33) Notification Permission:** Explicitly request runtime `android.permission.POST_NOTIFICATIONS` before scheduling habit reminders.
- **Android 13+ Exact Alarms (`SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`):** Exact alarms for habit reminders require `SCHEDULE_EXACT_ALARM`. Check `canScheduleExactAlarms()` before scheduling; if denied, fallback gracefully to inexact reminders via `workmanager`.
- **iOS Notification Authorization:** Request badge, sound, and alert permissions via `flutter_local_notifications` on first launch or when the user toggles a reminder.
- **OEM Battery Restrictions:** Certain Android devices (Xiaomi, Samsung, Huawei) aggressively terminate background processes. Provide an in-app prompt or settings link allowing users to disable battery optimization for reliable alarms.

### 3. Background Dart Isolates and Database Concurrency

- **Isolate State Sharing:** When notifications or background tasks fire (via `flutter_local_notifications` action click or `workmanager`), they run in a separate background Dart isolate.
- **Drift Concurrency:** Ensure that the Drift database instance is accessed safely across isolates (using Drift's isolate connection sharing utilities or reopening the file-based SQLite database safely).

### 4. Focus Timer Wakelock and Audio Session

- **Screen Sleep:** Focus sessions require the screen to remain active if the user keeps the timer on-screen. Use `wakelock_plus` to keep the display awake during active countdowns.
- **Audio Session Handling:** Completion chime audio playback requires configuring the audio session mode so sound plays even if the device is in silent/vibrate mode on Android and iOS.

## Locked Product Rules

- **No reinvention:** Translate existing Kotlin classes directly to equivalent Dart code.
- **Charts:** Use `fl_chart` configured with exact styling matching Vico.
- **Haptics:** Native system haptics only — **no Konfetti** or particle effects.
- **WEEKLY Habits:** Canonical ISO Monday–Sunday week boundaries; week is met when distinct completed days `>= targetCountPerWeek`; streak unit is weeks.
- **List vs Detail:** Cards support pin and check-in only; archive and delete are restricted to Habit Detail.
