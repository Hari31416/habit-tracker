# Phase 2a: Daily Tracker Core and Boolean Cards

## Objective

Implement the Material 3 design system, root app scaffold, daily tracker dashboard, rolling 7-day date navigator, historical date banner, search/category filter bar, and interactive Boolean habit cards with native system haptics and pin controls by directly translating the existing Kotlin Jetpack Compose UI components.

## Reference Kotlin Source Files for 1:1 Implementation

When implementing this phase, use the following Kotlin source files as direct references:

- `app/src/main/java/com/productivity/habits/ui/theme/Color.kt`, `Theme.kt`, `Shape.kt`, `Type.kt` -> `lib/ui/theme/app_theme.dart`, `app_colors.dart`, `app_shapes.dart`
- `app/src/main/java/com/productivity/habits/ui/navigation/HabitNavGraph.kt`, `Screen.kt` -> `lib/ui/navigation/app_router.dart`
- `app/src/main/java/com/productivity/habits/ui/daily/DailyTrackerScreen.kt` -> `lib/ui/daily/daily_tracker_screen.dart`
- `app/src/main/java/com/productivity/habits/ui/daily/DailyTrackerViewModel.kt` -> `lib/ui/daily/controllers/daily_tracker_controller.dart`
- `app/src/main/java/com/productivity/habits/ui/daily/RollingWeekStrip.kt` -> `lib/ui/daily/widgets/rolling_week_strip.dart`
- `app/src/main/java/com/productivity/habits/ui/daily/HistoricalBanner.kt` -> `lib/ui/daily/widgets/historical_banner.dart`
- `app/src/main/java/com/productivity/habits/ui/daily/QuickAddBar.kt` -> `lib/ui/daily/widgets/quick_add_bar.dart`
- `app/src/main/java/com/productivity/habits/ui/daily/HabitCard.kt` -> `lib/ui/daily/widgets/habit_card.dart`
- `app/src/main/java/com/productivity/habits/ui/common/HapticsHelper.kt` -> `lib/ui/common/haptics_helper.dart`
- `app/src/main/java/com/productivity/habits/ui/common/ColorUtils.kt` -> `lib/ui/common/color_utils.dart`

## Scope of Work

### 1. Material 3 Theme and Design Tokens

- Match the exact color hex codes and color schemes from `Color.kt` and `Theme.kt` (`#0A7A64` primary, emerald accents).
- Match 16dp rounded card shapes from `Shape.kt`.
- Support light and dark themes with dynamic adaptation.

### 2. Daily Dashboard Layout and Navigation

- Translate `DailyTrackerScreen.kt` layout into Flutter widgets.
- **Historical Banner:** Replicate `HistoricalBanner.kt` with amber tint, *"Viewing [Date]"* text, and `"Return to Today"` button.
- **Rolling Week Strip:** Replicate `RollingWeekStrip.kt` with 7-day horizontal strip centered on selected date, `<` and `>` navigation, and completion dots.
- **Quick-Add Bar:** Replicate `QuickAddBar.kt` with title input and category selector.
- **Filter and Search:** Text search, category chip filter, sort dropdown (*Pinned first*, *Streak length*, *Alphabetical*, *Category*), and archived toggle.

### 3. Boolean Habit Card

- Replicate `HabitCard.kt` visual structure:
  - Header strip with icon container, title, category badge, and pin star toggle.
  - Streak flame pill (`🔥 X days` / `🔥 X weeks`).
  - Large circular toggle checkbox button.
- **Haptics:** Direct mapping to `HapticsHelper.kt` (`HapticFeedback.heavyImpact()` on completion check-in; `HapticFeedback.selectionClick()` on pin toggle).
- **Strict Parity Constraints:**
  - Habit cards support pin and check-in controls **only**.
  - **No archive or delete controls** on habit cards (restricted to Habit Detail screen).
  - Tapping the card opens the Habit Detail screen.

## Acceptance Criteria

- Layout and visual elements match `DailyTrackerScreen.kt` and `HabitCard.kt` pixel-for-pixel.
- Checking in a habit triggers heavy system haptic feedback and updates database state.
- Pinning a habit reorders the list when sorted by *Pinned first*.
- No archive/delete options are present on the habit list cards.
