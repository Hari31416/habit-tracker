# Phase 4: Week Matrix and Analytics

## Objective

Implement the multi-habit Week Matrix consistency grid, long-term Analytics dashboard, and Gamification badges UI by directly translating existing Kotlin implementations.

## Reference Kotlin Source Files for 1:1 Implementation

When implementing this phase, use the following Kotlin source files as direct references:

- `app/src/main/java/com/productivity/habits/ui/matrix/HabitWeekMatrixScreen.kt` -> `lib/ui/matrix/habit_week_matrix_screen.dart`
- `app/src/main/java/com/productivity/habits/ui/matrix/WeekMatrixGrid.kt` -> `lib/ui/matrix/widgets/week_matrix_grid.dart`
- `app/src/main/java/com/productivity/habits/ui/matrix/WeekMatrixViewModel.kt` -> `lib/ui/matrix/controllers/week_matrix_controller.dart`
- `app/src/main/java/com/productivity/habits/ui/analytics/HabitAnalyticsScreen.kt` -> `lib/ui/analytics/habit_analytics_screen.dart`
- `app/src/main/java/com/productivity/habits/ui/analytics/AnalyticsViewModel.kt` -> `lib/ui/analytics/controllers/analytics_controller.dart`
- `app/src/main/java/com/productivity/habits/ui/analytics/AdherenceAreaChart.kt` -> `lib/ui/analytics/widgets/adherence_area_chart.dart`
- `app/src/main/java/com/productivity/habits/ui/analytics/MonthlyHeatmapGrid.kt` -> `lib/ui/analytics/widgets/monthly_heatmap_grid.dart`
- `app/src/main/java/com/productivity/habits/ui/gamification/PlayerLevelHeaderBadge.kt` -> `lib/ui/gamification/widgets/player_level_header_badge.dart`
- `app/src/main/java/com/productivity/habits/ui/gamification/BadgesShowcaseScreen.kt` -> `lib/ui/gamification/badges_showcase_screen.dart`
- `app/src/main/java/com/productivity/habits/ui/gamification/LevelUpCelebrationDialog.kt` -> `lib/ui/gamification/dialogs/level_up_celebration_dialog.dart`

## Scope of Work

### 1. Week Matrix Screen

- Replicate `HabitWeekMatrixScreen.kt` and `WeekMatrixGrid.kt`:
  - ISO Monday–Sunday date range header with `<` and `>` week navigation and `"Current Week"` reset.
  - Matrix table: Habit icon, title, weekly target badge, and 7 day-cells (filled green/theme for completed, outlined for scheduled, dim for unscheduled).
  - Tapping cell toggles check-in with haptics.
  - Weekly adherence summary card (completed count / total scheduled).
  - Toggleable weekday distribution bar chart using `fl_chart`.

### 2. Analytics and Trends Screen

- Replicate `HabitAnalyticsScreen.kt`:
  - 3 Top KPI cards: 30-Day Consistency Score, Best Overall Streak, Completed Today.
  - Streaks Leaderboard: Ranked list of top 5 active habits sorted by current streak.
  - Replicate `AdherenceAreaChart.kt` using `fl_chart` LineChart with 7-Day and 30-Day filter toggles and theme gradient fills.
  - Replicate `MonthlyHeatmapGrid.kt`: 4-level density shading for historical completions.

### 3. Gamification Progression UI

- Replicate `PlayerLevelHeaderBadge.kt` with dynamic level title and XP progress bar.
- Replicate `BadgesShowcaseScreen.kt` with unlockable achievement badges.
- Replicate `LevelUpCelebrationDialog.kt` with celebratory dialog and haptic fanfare.

## Acceptance Criteria

- Week Matrix displays habits with identical layout to `WeekMatrixGrid.kt`.
- `fl_chart` charts visually and behaviorally match the existing Vico implementation in `AdherenceAreaChart.kt`.
- Heatmap renders identical color tiers to `MonthlyHeatmapGrid.kt`.
- Gamification badges and level-up dialogs match `BadgesShowcaseScreen.kt` and `LevelUpCelebrationDialog.kt`.
