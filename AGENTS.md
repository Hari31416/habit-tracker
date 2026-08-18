## Technology Stack and Standards

### Primary Framework: Flutter
- Language: Dart 3.13+ / Flutter 3.47+ targeting Android (min SDK 26, target SDK 34) and iOS
- Architecture: Clean Architecture with reactive unidirectional data flow (Riverpod 2.6+)
- UI: Material 3 Design System
- State: Riverpod `AsyncNotifier` / `StateNotifier`
- Local Persistence: Drift Database with reactive Streams, DAOs, and type-safe converters
- Background Tasks & Notifications: `flutter_local_notifications`, foreground focus timer service, and background rollover tasks
- Widgets: Android AppWidgets & iOS WidgetKit synchronized via `SharedPreferences` and method channels
- Charts: Custom / `fl_chart` with Vico styling parity
- Haptics: System haptics only (no Konfetti or particle libraries)

## Development and Verification Flow

When making changes to the codebase, follow this sequential verification workflow:

### 1. Incremental Changes

- Keep changes small, modular, and focused
- Preserve existing comments and docstrings
- Follow existing entity, DAO, engine, and repository patterns

### 2. Unit & Widget Testing (Mandatory for Logic Changes)

After modifying domain calculation engines, Drift tables/converters, or repository implementations, run:

```bash
make test
```

Command executes `flutter test`. Ensure all Flutter unit and widget tests pass before proceeding.

### 3. Code Generation and Build Assembly Verification

If modifying Drift tables, run codegen first:

```bash
make codegen
```

Verify that Flutter compiles cleanly:

```bash
make build
```

Command executes `flutter build apk --debug --android-skip-build-dependency-validation`. Ensure zero compilation errors or warnings.

### 4. Emulator and Device Testing

To deploy and test UI, navigation, or database state on an emulator:

```bash
make run
```

This target automatically detects if an emulator is running (launches the default AVD if not), builds, installs the debug APK, and opens the application.

### 5. Runtime Log Inspection

To inspect app logs:

```bash
make logcat
```

### 6. Process and Emulator Teardown

To stop the running application or shut down the emulator:

```bash
# Stop application process
make stop

# Gracefully shut down running emulator
make emulator-stop
```

## Git Commit Guidelines

- Commit only when explicitly requested by the user
- Follow conventional commit style: `<type>(<scope>): <subject>`
  - Types: `feat`, `fix`, `refactor`, `docs`, `style`, `test`, `chore`
  - Scopes: `frontend`, `backend`, `infra`, `general`
- Subject line must be concise and imperative (under 50 characters)
- Body should be a bulleted list describing key changes
- Do not include links or emojis in commit messages

## Key Architecture Decisions

- Streak Engine:
  - Daily: day-based streak with in-progress day preservation for unlogged current day
  - Weekly: canonical ISO Monday–Sunday week boundaries; week is met when distinct completed days `>= targetCountPerWeek`; streak unit is weeks
  - Custom Days: non-scheduled days are skipped without breaking consecutive streak chains
- Icons: String keys stored on habits resolved at runtime via `HabitIconRegistry` to Material Icons
- Cards vs Detail: Habit cards support pin and check-in controls; archive and delete are restricted to Habit Detail view

