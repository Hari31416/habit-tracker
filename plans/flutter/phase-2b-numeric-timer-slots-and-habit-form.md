# Phase 2b: Numeric / Timer / Slots and Habit Form

## Objective

Implement interactive card controls for Numeric Counter, Duration Timer, and Subday Slot habits, along with the complete Add/Edit Habit bottom sheet form by directly translating existing Kotlin implementations.

## Reference Kotlin Source Files for 1:1 Implementation

When implementing this phase, use the following Kotlin source files as direct references:

- `app/src/main/java/com/productivity/habits/ui/daily/NumericHabitControls.kt` -> `lib/ui/daily/widgets/numeric_habit_controls.dart`
- `app/src/main/java/com/productivity/habits/ui/daily/DirectNumericInputDialog.kt` -> `lib/ui/daily/dialogs/direct_numeric_input_dialog.dart`
- `app/src/main/java/com/productivity/habits/ui/daily/TimerHabitControls.kt` -> `lib/ui/daily/widgets/timer_habit_controls.dart`
- `app/src/main/java/com/productivity/habits/ui/daily/SlotHabitControls.kt` -> `lib/ui/daily/widgets/slot_habit_controls.dart`
- `app/src/main/java/com/productivity/habits/ui/form/HabitFormBottomSheet.kt` -> `lib/ui/form/habit_form_bottom_sheet.dart`
- `app/src/main/java/com/productivity/habits/ui/form/HabitFormViewModel.kt` -> `lib/ui/form/controllers/habit_form_controller.dart`

## Scope of Work

### 1. Numeric Counter Controls

- Replicate `NumericHabitControls.kt`:
  - Progress bar and progress label (e.g. `1,250 / 2,000 ml`).
  - Stepper `-` and `+` buttons using dynamic step sizing from `DynamicStepEngine`.
  - Dynamic quick-add chips.
  - Inline pencil button triggering direct numeric entry dialog.
- Replicate `DirectNumericInputDialog.kt` for direct keypad numeric overrides.

### 2. Duration Timer Controls

- Replicate `TimerHabitControls.kt`:
  - Progress bar and elapsed duration text (e.g. `15 / 25 mins`).
  - Quick-add chips (`+5m`, `+10m`, `+15m`).
  - `"Start Focus"` action button navigating directly to Focus Timer.

### 3. Subday Interval and Slot Controls

- Replicate `SlotHabitControls.kt`:
  - Horizontal row of slot pills generated via `SubdaySlotEngine`.
  - Timestamped pills for `SUBDAY_INTERVAL` (e.g. `08:00`, `11:00`, `14:00`).
  - Numbered pills for `TIMES_PER_DAY` (`Slot 1`, `Slot 2`, `Slot 3`).
  - Independent check-in toggle per slot index.

### 4. Add / Edit Habit Form

- Replicate `HabitFormBottomSheet.kt`:
  - Basic Info: Title, description, category selector, 8-color preset palette, icon picker (`HabitIconRegistry`).
  - Target Types: Boolean, Numeric (with unit presets: `glasses`, `pages`, `reps`, `steps`, `ml`, `km`, `mins`, `cal`), Timer (minutes with presets: `15m`, `25m`, `30m`, `45m`, `60m`).
  - Frequency Rules: Daily, Specific Days (Mon–Sun), Times Per Week (1–6), Subday Intervals (hours + time window start/end), Times Per Day.
  - Multi-Reminder section with preset time chips (*Morning*, *Midday*, *Evening*, *Night*) and TimePicker.
  - Saves entity and invokes `HabitReminderScheduler.schedule(habit)`.

## Acceptance Criteria

- All card controls operate identically to their Kotlin counterparts in `NumericHabitControls.kt`, `TimerHabitControls.kt`, and `SlotHabitControls.kt`.
- Dynamic stepper correctly applies unit-specific and magnitude-specific step increments.
- Add/Edit form validates, creates, and updates habits with identical validation logic to `HabitFormViewModel.kt`.
