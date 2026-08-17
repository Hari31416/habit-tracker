# Phase 4: Week Matrix and Analytics

## Objective

Construct the Week Matrix overview screen for multi-day consistency visualization and the Analytics screen featuring Vico charts, streak leaderboards, and monthly completion heatmap grids.

## Scope of Work

### 1. Week Matrix Screen (`HabitWeekMatrixScreen`)

- **Navigation and Header**:
  - Week date range display using **ISO Monday–Sunday** (e.g. `Aug 11 - Aug 17, 2026`).
  - Previous / next week steppers and "Current Week" reset.
- **7-Day Matrix Grid**:
  - Habit rows: category color, icon (`HabitIconRegistry`), title, frequency badge (including `N×/week` for WEEKLY).
  - Columns Mon–Sun.
  - Cell status: filled = completed that day; outlined = incomplete but loggable/scheduled; empty/dimmed = not scheduled (`CUSTOM_DAYS`).
  - WEEKLY rows: every day is loggable; badge/summary can show progress toward `targetCountPerWeek`.
  - Interactive cell taps to log or un-log completions.
- **Weekly Adherence Summary Strip**:
  - Aggregate adherence percentage; completed vs scheduled check-ins (define scheduled for WEEKLY as days in week or target count — prefer completed distinct days vs `targetCountPerWeek` for that habit’s contribution).
- **Toggleable Daily Bar Chart**:
  - Bar chart of daily completions Mon–Sun (Vico or simple Compose canvas; prefer Vico for consistency with analytics).

### 2. Analytics and Trends Screen (`HabitAnalyticsScreen`)

- **Top KPI Cards**:
  - 30-Day Consistency Score (%) with optional trend delta.
  - Best Overall Streak (normalize days vs weeks carefully in copy).
  - Completed Today count (e.g. `5 / 7 Done`).
- **Streaks Leaderboard**:
  - Top 5 habits by current streak; show unit (days/weeks) per habit frequency.
- **Adherence Trend Chart (Vico)**:
  - Smooth area/line chart; `7-Day` and `30-Day` toggles; Material 3 styling.
- **Monthly Heatmap Grid (`MonthlyHeatmapGrid`)**:
  - Density levels 0% / 1–49% / 50–99% / 100%; cell click for day breakdown.

## Deliverables

- `app/src/main/java/com/productivity/habits/ui/matrix/HabitWeekMatrixScreen.kt`
- `app/src/main/java/com/productivity/habits/ui/matrix/WeekMatrixViewModel.kt`
- `app/src/main/java/com/productivity/habits/ui/matrix/WeekMatrixGrid.kt`
- `app/src/main/java/com/productivity/habits/ui/analytics/HabitAnalyticsScreen.kt`
- `app/src/main/java/com/productivity/habits/ui/analytics/AnalyticsViewModel.kt`
- `app/src/main/java/com/productivity/habits/ui/analytics/AdherenceAreaChart.kt`
- `app/src/main/java/com/productivity/habits/ui/analytics/MonthlyHeatmapGrid.kt`

## Acceptance Criteria

- Week matrix uses ISO weeks and reflects completion status for all frequency types.
- Cell toggles update Room and refresh adherence immediately.
- Vico chart renders 7-day and 30-day adherence with theme tokens.
- Monthly heatmap density matches historical completion rates.
- No MPAndroidChart; no Konfetti.
