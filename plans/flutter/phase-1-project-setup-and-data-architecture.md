# Phase 1: Project Setup and Data Architecture

## Objective

Establish the Flutter project structure, `pubspec.yaml` dependencies, Drift persistence layer, domain models, pure Dart calculation engines, reminder scheduler abstraction, icon registry, and automated unit tests by directly translating the existing Kotlin data and domain architecture.

## Reference Kotlin Source Files for 1:1 Implementation

When implementing this phase, use the following Kotlin source files as direct references:

- `app/src/main/java/com/productivity/habits/domain/engine/StreakCalculator.kt` -> `lib/domain/engines/streak_calculator.dart`
- `app/src/main/java/com/productivity/habits/domain/engine/DynamicStepEngine.kt` -> `lib/domain/engines/dynamic_step_engine.dart`
- `app/src/main/java/com/productivity/habits/domain/engine/SubdaySlotEngine.kt` -> `lib/domain/engines/subday_slot_engine.dart`
- `app/src/main/java/com/productivity/habits/domain/gamification/GamificationEngine.kt` -> `lib/domain/gamification/gamification_engine.dart`
- `app/src/main/java/com/productivity/habits/domain/gamification/AchievementEvaluator.kt` -> `lib/domain/gamification/achievement_evaluator.dart`
- `app/src/main/java/com/productivity/habits/domain/gamification/AchievementDefinitions.kt` -> `lib/domain/gamification/achievement_definitions.dart`
- `app/src/main/java/com/productivity/habits/domain/gamification/PlayerTitle.kt` -> `lib/domain/gamification/player_title.dart`
- `app/src/main/java/com/productivity/habits/data/local/entity/HabitEntity.kt` -> `lib/data/local/tables/habits.dart`
- `app/src/main/java/com/productivity/habits/data/local/entity/HabitLogEntity.kt` -> `lib/data/local/tables/habit_logs.dart`
- `app/src/main/java/com/productivity/habits/data/local/entity/HabitCategoryEntity.kt` -> `lib/data/local/tables/habit_categories.dart`
- `app/src/main/java/com/productivity/habits/data/local/entity/UserGamificationEntity.kt` -> `lib/data/local/tables/user_gamification.dart`
- `app/src/main/java/com/productivity/habits/data/local/entity/AchievementEntity.kt` -> `lib/data/local/tables/achievements.dart`
- `app/src/main/java/com/productivity/habits/data/local/dao/HabitDao.kt` -> `lib/data/local/daos/habit_dao.dart`
- `app/src/main/java/com/productivity/habits/data/local/dao/HabitLogDao.kt` -> `lib/data/local/daos/habit_log_dao.dart`
- `app/src/main/java/com/productivity/habits/data/local/dao/GamificationDao.kt` -> `lib/data/local/daos/gamification_dao.dart`
- `app/src/main/java/com/productivity/habits/data/local/PrepopulateDataCallback.kt` -> `lib/data/local/database_seeder.dart`
- `app/src/main/java/com/productivity/habits/domain/repository/HabitRepository.kt` -> `lib/domain/repositories/habit_repository.dart`
- `app/src/main/java/com/productivity/habits/data/repository/HabitRepositoryImpl.kt` -> `lib/data/repositories/habit_repository_impl.dart`
- `app/src/main/java/com/productivity/habits/domain/scheduler/HabitReminderScheduler.kt` -> `lib/domain/schedulers/habit_reminder_scheduler.dart`
- `app/src/main/java/com/productivity/habits/data/scheduler/NoOpHabitReminderScheduler.kt` -> `lib/data/schedulers/no_op_habit_reminder_scheduler.dart`
- `app/src/main/java/com/productivity/habits/ui/common/HabitIconRegistry.kt` -> `lib/ui/common/habit_icon_registry.dart`

## Scope of Work

### 1. Build and Dependency Configuration

- Configure `pubspec.yaml` with required dependencies:
  - `flutter_riverpod`, `riverpod_annotation`
  - `drift`, `sqlite3_flutter_libs`, `path_provider`, `path`
  - `intl`, `uuid`, `material_design_icons_flutter`
  - `build_runner`, `drift_dev`, `riverpod_generator`, `flutter_test`

### 2. Drift Persistence Layer

- **Tables & Schemas**: Recreate exact schemas from `HabitEntity.kt`, `HabitLogEntity.kt`, `HabitCategoryEntity.kt`, `UserGamificationEntity.kt`, and `AchievementEntity.kt`.
- **Type Converters**: Recreate converters from `HabitConverters.kt` for `TimeWindow`, `List<int>`, `List<String>`, and enums.
- **DAOs**: Implement `HabitDao`, `HabitLogDao`, `HabitCategoryDao`, and `GamificationDao` with reactive Streams.
- **Database Seeding**: Seed the exact 6 default categories defined in `PrepopulateDataCallback.kt`.

### 3. Pure Dart Domain Engines

- **Streak Engine (`streak_calculator.dart`)**:
  - Direct 1:1 port of `StreakCalculator.kt`.
  - Canonical ISO Monday–Sunday week boundaries (`DateTime.monday`).
  - Weekly target logic: Week met when distinct completed days `>= targetCountPerWeek`. Streak counts consecutive met weeks.
  - In-progress day and week preservation for unlogged current periods.
  - 30-day adherence rate calculations for weekly and non-weekly frequencies.
- **Dynamic Stepper Engine (`dynamic_step_engine.dart`)**:
  - Direct 1:1 port of `DynamicStepEngine.kt` matching step and quick-add calculations for `ml`, `l`, `steps`, `cal`, `kcal`, and general numbers.
- **Subday Slot Engine (`subday_slot_engine.dart`)**:
  - Direct 1:1 port of `SubdaySlotEngine.kt` for time-window splitting.
- **Gamification Engine (`gamification_engine.dart`)**:
  - Direct 1:1 port of `GamificationEngine.kt`, `AchievementEvaluator.kt`, and `AchievementDefinitions.kt`.

### 4. Repository and Scheduler Abstraction

- Port `HabitRepository.kt` interface and `HabitRepositoryImpl.kt`.
- Port `HabitReminderScheduler.kt` interface and `NoOpHabitReminderScheduler.kt` (used until Phase 5).

### 5. Automated Unit Tests

Port tests directly from the existing test suite:
- `StreakCalculatorTest.kt` -> `test/domain/streak_calculator_test.dart`
- `DynamicStepEngineTest.kt` -> `test/domain/dynamic_step_engine_test.dart`
- `SubdaySlotEngineTest.kt` -> `test/domain/subday_slot_engine_test.dart`
- `GamificationEngineTest.kt` -> `test/domain/gamification_engine_test.dart`

## Watch Out For During Execution

### 1. Date and Time Consistency (Local vs UTC)

- **ISO Date Strings (`yyyy-MM-dd`):**  
  All daily habit logs store their calendar date as an ISO date string (e.g. `2026-08-18`). Always format and parse calendar dates using local time (`DateTime(year, month, day)`) and `intl`'s `DateFormat('yyyy-MM-dd')`. Avoid converting calendar day keys to UTC, which can shift dates across midnight time zone boundaries.
- **Timestamps (`DateTime`):**  
  Store granular creation/update timestamps in UTC ISO 8601 strings or milliseconds epoch.

### 2. SQLite Native Dynamic Libraries

- On Android and iOS, ensure `sqlite3_flutter_libs` is included in `dependencies` so that Drift links the updated SQLite binary properly across all CPU architectures (arm64-v8a, armeabi-v7a, x86_64).

### 3. Code Generation Workflow

- Run `dart run build_runner build --delete-conflicting-outputs` whenever editing Drift tables or Riverpod annotations to keep `.g.dart` generated files in sync.

## Acceptance Criteria

- All table definitions, foreign keys, and indices match Room schema definitions.
- All domain unit tests ported from Kotlin pass with 100% success rate.
- Riverpod successfully injects repository and no-op reminder scheduler instances.
