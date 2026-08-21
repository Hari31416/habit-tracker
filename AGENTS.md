# Agent Guidelines and Engineering Standards

## Technology Stack

- **Language & Framework:** Dart 3.13+ / Flutter 3.47+ (Android min SDK 26, target SDK 34, iOS)
- **Architecture:** Clean Architecture with reactive unidirectional data flow (Riverpod 2.6+)
- **State Management:** Riverpod `AsyncNotifier` and `StateNotifier`
- **Local Persistence:** Drift SQLite database with reactive Streams, DAOs, and type-safe converters
- **Services:** Foreground focus timer service, `flutter_local_notifications`, and background rollover tasks
- **Widgets:** Android AppWidgets and iOS WidgetKit synchronized via `SharedPreferences` and method channels
- **Styling & UI:** Material 3 Design System, custom charts (`fl_chart`), system haptics only

## Sequential Verification Workflow

Follow this verification sequence for all codebase modifications:

### 1. Code Generation (Drift Tables and Converters)

Execute whenever Drift table schemas, queries, or type converters change:

```bash
make codegen
```

Ensure code generation completes with zero errors before running tests.

### 2. Unit and Widget Testing

Execute after any changes to domain models, calculation engines, DAOs, or repositories:

```bash
make test
```

All unit and widget tests must pass before proceeding.

### 3. Build Assembly Verification

Execute to verify Flutter compilation and Android packaging:

```bash
make build
```

Ensure zero compilation errors or warnings.

### 4. Emulator Lifecycle and Runtime Inspection

Deploy, test, and inspect runtime state:

```bash
# Launch emulator (if not running), build, and deploy debug APK
make run

# Stream runtime logs
make logcat

# Stop application process
make stop

# Gracefully terminate running emulator
make emulator-stop
```

## Architecture and Domain Invariants

### Entity mapping contract

When adding or modifying fields on domain entities or Drift tables, keep `test/data/entity_contract_roundtrip_test.dart` green. Distinctive values live in `test/helpers/contract_fixtures.dart`. That roundtrip is the source of truth for row, companion, and `SyncEnvelope` JSON mapping.

### Streak Engine Invariants

- **Daily Habits:** Evaluates day-by-day; unlogged current day preserves in-progress streak chain.
- **Weekly Habits:** Evaluates against canonical ISO Monday-Sunday week boundaries. Target is met when distinct completed days `>= targetCountPerWeek`; streak unit is weeks.
- **Custom Days:** Non-scheduled days are skipped without breaking consecutive streak chains.
- **Elastic Goals (Bad-Day Mode):** Reaching `miniTargetValue` preserves streak momentum on difficult days.

### Gamification and Achievement Invariants

- **Active Streak Multipliers:** Multipliers (1.0x, 1.25x, 1.5x, 2.0x) must evaluate strictly against active `currentStreak`, never historic `bestStreak`.
- **Achievement Unlocks:** Achievements evaluate `isUnlocked` strictly via `progress >= targetValue`. Unearned achievements must never be marked unlocked.
- **Sync Merging:** Merged payloads must only export and persist genuinely unlocked achievements (`ea.isUnlocked`).

### UI Controls and Icon Registry

- **Habit Cards:** Support pin, quick check-in, and tier selectors. Archive and delete are restricted to Habit Detail view.
- **Icon Resolution:** String keys stored on habits resolve at runtime via `HabitIconRegistry` to Material Icons.

## Git Commit Protocol

- Commit only upon explicit user request.
- Format: `<type>(<scope>): <subject>` with a concise imperative subject (under 50 characters).
  - **Types:** `feat`, `fix`, `refactor`, `docs`, `style`, `test`, `chore`
  - **Scopes:** `frontend`, `backend`, `infra`, `general`
- Body must be a bulleted list describing key changes.
- Do not include links or emojis in commit messages.
