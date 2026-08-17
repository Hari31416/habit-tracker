# Phase 1: Project Setup and Data Architecture

## Objective

Establish the project scaffolding, Gradle version catalog configuration, Room database persistence layer, domain models, business logic calculation engines (including WEEKLY week-based streaks), reminder scheduler abstraction, icon registry, and automated unit test suite.

## Scope of Work

### 1. Build and Gradle Configuration

- Configure Gradle version catalog (`gradle/libs.versions.toml`) with:
  - Kotlin 2.0+
  - Android Gradle Plugin 8.5+
  - Jetpack Compose with Compose Compiler
  - Room 2.6+
  - Hilt 2.51+
  - Jetpack Glance 1.1+ (dependency only; implement in Phase 5)
  - Vico Charts 2.0+ (dependency only; implement in Phase 4)
  - WorkManager (dependency only; implement in Phase 5)
  - AndroidX Core, Lifecycle, Activity, Navigation Compose
  - Material Icons Extended (for `HabitIconRegistry`)
- Do **not** add Konfetti or other particle libraries.
- Configure `settings.gradle.kts` and root `build.gradle.kts`.
- Configure `app/build.gradle.kts` targeting SDK 34 with min SDK 26.
- Add `app/proguard-rules.pro`.
- Set up Gradle wrapper scripts and properties.

### 2. Room Persistence Layer

- **Entities**:
  - `HabitEntity`: Core habit configuration with frequency types (`DAILY`, `WEEKLY`, `CUSTOM_DAYS`, `SUBDAY_INTERVAL`, `TIMES_PER_DAY`) and target types (`BOOLEAN`, `NUMERIC`, `TIMER`).
  - `HabitLogEntity`: Granular check-ins with habit foreign key cascade, date indexing, numeric values, duration seconds, and interval indices.
  - `HabitCategoryEntity`: Categories with theme colors and icon names.
- **Type Converters**:
  - Converters for `Instant`, `List<Int>`, `List<String>`, `TimeWindow`, and enums.
- **DAOs**:
  - `HabitDao`: CRUD operations and reactive `Flow` queries for active, pinned, and category-filtered habits.
  - `HabitLogDao`: Date-range queries, daily log queries, and upsert operations.
  - `HabitCategoryDao`: Category listings and custom category creation.
- **Database and Seeding**:
  - `HabitDatabase` Room instance.
  - `PrepopulateDataCallback` to seed the 6 default preset categories (*Health and Fitness*, *Mindfulness*, *Learning*, *Productivity*, *Personal*, *Routine*).

### 3. Domain Models and Calculation Engines

- **Streak Engine (`StreakCalculator`)** — rules must match `plans/overview.md`:
  - Daily / custom-days / subday: day-based streaks with active preservation for unlogged current day; custom days skip unscheduled days without penalty.
  - **WEEKLY:** ISO Monday–Sunday weeks; week met when distinct completed days `>= targetCountPerWeek`; streak counts consecutive met weeks; in-progress week preservation; 30-day rate = met intersecting weeks / intersecting weeks.
  - Rolling 30-day adherence for non-weekly frequencies (scheduled days).
  - Historical best streak determination.
- **Dynamic Stepper Engine (`DynamicStepEngine`)**:
  - Magnitude-aware step sizes and quick-add chips for volume (`ml`, `l`), distance (`steps`, `km`), energy (`cal`, `kcal`), and general numeric targets.
  - Timer duration step sizing.
- **Subday Slot Engine (`SubdaySlotEngine`)**:
  - Dynamic generation of timestamped slot intervals from time windows (`startTime` to `endTime`) and interval hours.
- **Repository Interface and Implementation**:
  - `HabitRepository` interface in domain layer.
  - `HabitRepositoryImpl` implementing Room data streaming and transaction logic.

### 4. Reminder Scheduler Abstraction

- `HabitReminderScheduler` interface in domain/data boundary:
  - `schedule(habit)`, `cancel(habitId)`, `rescheduleAll()`.
- `NoOpHabitReminderScheduler` bound via Hilt for Phases 1–4.
- Phase 5 replaces binding with AlarmManager + WorkManager implementation (no Phase 2/2b changes required beyond calling the interface).

### 5. Icon Registry

- `HabitIconRegistry`: maps Lucide-style string keys (e.g. `activity`, `brain`, `book-open`) to Compose `ImageVector` / drawable resources.
- Include at least 16 keys covering default categories and form picker; unknown keys fall back to a generic icon.

### 6. Automated Unit Tests

- `StreakCalculatorTest`: daily streaks, **weekly ISO week meets and week-unit streaks**, custom day gaps, 30-day rolling rates.
- `DynamicStepEngineTest`: step sizing and quick-add values across units and scales.
- `SubdaySlotEngineTest`: time window division, edge cases, and interval indexing.

## Deliverables

- `gradle/libs.versions.toml`
- `build.gradle.kts`
- `settings.gradle.kts`
- `app/build.gradle.kts`
- `app/src/main/java/com/productivity/habits/data/local/entity/`
- `app/src/main/java/com/productivity/habits/data/local/converters/`
- `app/src/main/java/com/productivity/habits/data/local/dao/`
- `app/src/main/java/com/productivity/habits/data/local/HabitDatabase.kt`
- `app/src/main/java/com/productivity/habits/data/local/PrepopulateDataCallback.kt`
- `app/src/main/java/com/productivity/habits/data/repository/HabitRepositoryImpl.kt`
- `app/src/main/java/com/productivity/habits/data/scheduler/NoOpHabitReminderScheduler.kt`
- `app/src/main/java/com/productivity/habits/domain/engine/`
- `app/src/main/java/com/productivity/habits/domain/model/`
- `app/src/main/java/com/productivity/habits/domain/repository/HabitRepository.kt`
- `app/src/main/java/com/productivity/habits/domain/scheduler/HabitReminderScheduler.kt`
- `app/src/main/java/com/productivity/habits/ui/common/HabitIconRegistry.kt`
- `app/src/test/java/com/productivity/habits/`

## Acceptance Criteria

- Gradle project configuration parses and syncs cleanly.
- Room database schema creates tables and indices matching specification.
- Database callback seeds preset categories on creation.
- WEEKLY streak tests prove ISO week boundaries, `targetCountPerWeek` meets, week-unit current/best streak, and in-progress week preservation.
- All unit tests for `StreakCalculator`, `DynamicStepEngine`, and `SubdaySlotEngine` pass.
- Hilt binds `NoOpHabitReminderScheduler` for `HabitReminderScheduler`.
