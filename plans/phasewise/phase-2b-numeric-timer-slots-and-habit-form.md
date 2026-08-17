# Phase 2b: Numeric / Timer / Slots and Habit Form

## Objective

Extend habit cards for numeric, timer, and subday/times-per-day targets; ship the full add/edit habit form. Reminder times are persisted and passed to `HabitReminderScheduler` (still no-op until Phase 5).

## Scope of Work

### 1. Habit Card Control Variations

Extend `HabitCard` (and related composables) beyond boolean:

- **Numeric Target**:
  - Progress bar, current vs target label (e.g. `1,250 / 2,000 ml`).
  - Minus/plus stepper using `DynamicStepEngine` primary step.
  - Dynamic quick-add chips; pencil button for direct number input dialog.
  - Light haptics on stepper taps; heavy haptic when progress first reaches 100% for the day.
- **Timer Target**:
  - Progress bar (e.g. `15 / 25 mins`), quick +5m/+10m (or engine-driven) buttons.
  - "Start Focus" launches detail timer route (full circular timer + service in Phase 3; 2b may navigate to detail or a lightweight timer placeholder).
- **Subday Interval / Times Per Day**:
  - Horizontal row of slot pills from `SubdaySlotEngine` / fixed `timesPerDay` indices with independent check-in states.
- Keep card interactions limited to **pin + logging controls** (no archive/delete).

### 2. Add / Edit Habit Modal (`HabitFormBottomSheet`)

- **Form Sections**:
  - **Basic Info**: Title, description, motivation note, category dropdown, color palette (8 presets), icon picker (16+ keys from `HabitIconRegistry`).
  - **Target Model Selector**: Boolean, Numeric (value + unit presets / custom unit), Timer (duration presets 15, 25, 30, 45, 60 mins).
  - **Frequency Rules**: Daily, Specific Days of Week, Times Per Week (`targetCountPerWeek` 1–6), Subday Intervals (interval hours + active time window), Times Per Day.
  - **Reminders**: Multi-reminder list, presets (Morning 08:00, Midday 12:30, Evening 18:00, Night 21:30), custom TimePicker. Persist `reminderTimes` on the habit.
- **Validation and Persistence**:
  - Input validation and Room insert/update.
  - On save: call `HabitReminderScheduler.schedule(habit)` / `cancel` as appropriate (no-op implementation until Phase 5).
- **Edit entry points**: from detail (Phase 3) and optionally long-press/menu later; 2b must support edit when opened with `habitId`.

### 3. ViewModels

- `HabitFormViewModel` for create/edit state, validation, and persistence.
- Update `DailyTrackerViewModel` / card state to render numeric, timer, and slot progress.

### 4. Quick-Add Bar

- Expand `QuickAddBar` if present: still creates a simple habit; advanced frequency/target via full form.

## Deliverables

- `app/src/main/java/com/productivity/habits/ui/daily/HabitCard.kt` (numeric / timer / slots paths)
- `app/src/main/java/com/productivity/habits/ui/daily/NumericHabitControls.kt` (or equivalent splits)
- `app/src/main/java/com/productivity/habits/ui/daily/TimerHabitControls.kt`
- `app/src/main/java/com/productivity/habits/ui/daily/SlotHabitControls.kt`
- `app/src/main/java/com/productivity/habits/ui/form/HabitFormBottomSheet.kt`
- `app/src/main/java/com/productivity/habits/ui/form/HabitFormViewModel.kt`
- Updates to `DailyTrackerViewModel` and navigation for add/edit routes

## Acceptance Criteria

- User can create and edit habits with any frequency and target type via the form.
- Numeric steppers, quick-adds, timer quick-adds, and slot pills update Room reactively with haptics (no Konfetti).
- Saving reminder times invokes `HabitReminderScheduler` without requiring Phase 5 to be implemented.
- WEEKLY habits persist `targetCountPerWeek` and show week-based streak labels from Phase 1 engine.
- Archive/delete remain unavailable on cards (Phase 3 only).
