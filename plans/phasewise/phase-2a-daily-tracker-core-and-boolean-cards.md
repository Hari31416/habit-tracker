# Phase 2a: Daily Tracker Core and Boolean Cards

## Objective

Implement the Material 3 design system, navigation architecture, daily tracking dashboard chrome, and boolean habit cards with pin/check-in and real haptics. Numeric, timer, slot controls, and the full habit form land in Phase 2b.

## Scope of Work

### 1. Design System and Navigation

- **Material 3 Theme**:
  - Color palette (`Color.kt`) supporting dynamic color, dark mode, and vibrant habit accent colors.
  - Typography (`Type.kt`) with crisp hierarchy for metrics and headings.
  - Shapes and Elevation (`Shape.kt`).
- **Navigation Architecture**:
  - `HabitNavGraph` with routes for Daily Tracker, Habit Detail (`app://habits/detail/{habitId}`), Week Matrix, Analytics, and Add Habit (route wired; form UI in 2b).
  - Deep link handler registration (targets may be placeholders until later phases).
- **Entry Points**:
  - `MainActivity.kt` with edge-to-edge support.
  - `HabitApplication.kt` with Hilt initialization (notification channel creation can wait until Phase 5).

### 2. Daily Tracker Dashboard Components

- **Top Action Bar**:
  - Segmented control to toggle between `Daily`, `Week Matrix`, and `Analytics` (Week/Analytics screens may be stubs until Phase 4).
  - Add Habit trigger / FAB opens a **minimal create sheet** (title + category → boolean daily habit). Full `HabitFormBottomSheet` replaces this in Phase 2b.
- **Historical Date Indicator**:
  - Banner when viewing past or future dates with a "Return to Today" action.
- **Rolling Week Strip (`RollingWeekStrip`)**:
  - Stepper navigation (`<`, `>`) and "Today" pill.
  - 7-day horizontal strip with day name, date number, selected indicator, and completion dots.
- **Search and Filter Controls**:
  - Text search matching habit title and description.
  - Horizontally scrollable category filter chips.
  - Sort dropdown (Pinned first, Streak length, Alphabetical, Category).
  - Show archived toggle (list can *show* archived; archive/restore actions remain Phase 3 detail-only).
- **Quick-Add Bar (`QuickAddBar`)** (optional in 2a):
  - Inline title + category for one-tap **boolean daily** habit creation; expanded form in 2b.

### 3. Boolean Habit Card (`HabitCard` — boolean path)

- **Card Header**:
  - Color-tinted icon via `HabitIconRegistry`, title, category badge, and pin toggle.
  - Streak pill (days, or weeks label when frequency is `WEEKLY`).
- **Boolean control**:
  - Large circular check button.
  - Light haptic on press; **heavy confirmation haptic** on completion.
  - No Konfetti / particle effects.
- **Interactions allowed on card**: pin toggle and check-in only.
- **Not on card**: archive, restore, delete (Phase 3 detail overflow only).
- **Card tap**: navigates to Habit Detail (detail body may be stub until Phase 3).

### 4. ViewModels

- `DailyTrackerViewModel` owning selected date, filters, sort, and habit list `StateFlow`s.
- Wire repository Flows; compute per-card progress using Phase 1 engines.

## Deliverables

- `app/src/main/java/com/productivity/habits/ui/theme/`
- `app/src/main/java/com/productivity/habits/ui/navigation/`
- `app/src/main/java/com/productivity/habits/ui/daily/DailyTrackerScreen.kt`
- `app/src/main/java/com/productivity/habits/ui/daily/DailyTrackerViewModel.kt`
- `app/src/main/java/com/productivity/habits/ui/daily/RollingWeekStrip.kt`
- `app/src/main/java/com/productivity/habits/ui/daily/HabitCard.kt` (boolean path)
- `app/src/main/java/com/productivity/habits/ui/common/` (shared haptics helpers as needed)
- `app/src/main/java/com/productivity/habits/MainActivity.kt`
- `app/src/main/java/com/productivity/habits/HabitApplication.kt`

## Acceptance Criteria

- User can pin/unpin and complete/uncomplete **boolean** habits for the selected date with reactive Room updates and confirmation haptics.
- Daily tracker lists habits scheduled for the selected date (WEEKLY habits appear every day; streak pill uses weeks when applicable).
- Search, category filters, and sort update the list in real time.
- Date navigation supports viewing and logging on historical dates.
- Archive/delete actions are **not** available from the list/card UI.
- No Konfetti dependency or particle UI.
