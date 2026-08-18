## Technology Stack and Standards

- Language: Kotlin 2.0+ targeting SDK 34 (min SDK 26) with Java 8+ API desugaring
- Architecture: Clean Architecture with reactive unidirectional data flow (MVI / MVVM)
- UI: Jetpack Compose with Material 3 Design System
- State: Jetpack ViewModel with `StateFlow`
- Dependency Injection: Hilt / Dagger
- Local Persistence: Room Database with reactive Flow queries and schema exports
- Background Tasks: AlarmManager for exact alarms; WorkManager for maintenance and day rollover
- Widgets: Jetpack Glance (AppWidgets)
- Charts: Vico Compose (do not use MPAndroidChart)
- Haptics: System haptics only (no Konfetti or particle libraries)

## Development and Verification Flow

When making changes to the codebase, follow this sequential verification workflow:

### 1. Incremental Changes

- Keep changes small, modular, and focused
- Preserve existing comments and docstrings
- Follow existing entity, DAO, engine, and repository patterns

### 2. Unit Testing (Mandatory for Logic Changes)

After modifying domain calculation engines, Room converters, or repository implementations, run:

```bash
make test
```

Command executes `./gradlew testDebugUnitTest`. Ensure all domain unit tests pass before proceeding.

### 3. Build Assembly Verification

Verify that Room schemas, KSP code generation, Hilt dependency bindings, and the Jetpack Compose compiler compile cleanly:

```bash
make build
```

Command executes `./gradlew assembleDebug`. Ensure zero compilation errors or warnings.

### 4. Emulator and Device Testing

To deploy and test UI, navigation, or database state on an emulator:

```bash
make run
```

This target automatically detects if an emulator is running (launches the default AVD if not), builds, installs the debug APK, and opens the application.

### 5. Runtime Log Inspection

To inspect app logs, Room query logs, and uncaught exceptions:

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

## Flutter Migration Guidelines

When implementing the Flutter migration:

- **Do Not Start from Scratch:** Every Flutter model, calculation engine, Drift table, DAO query, Riverpod controller, and widget layout must directly reference and port the corresponding Kotlin implementation in `app/src/main/java/com/productivity/habits/`.
- **Logic & UI Parity:** All calculations, algorithms, UI paddings, colors, shapes, haptic strengths, and lifecycle behaviors in Flutter must match the Kotlin source with 100% exact parity.
- **Reference Mapping:** Refer to `plans/flutter/README.md` for the complete 1:1 file mapping table.

### Flutter Verification Commands

```bash
# Run unit tests
flutter test

# Run code generator
dart run build_runner build --delete-conflicting-outputs

# Build debug APK
flutter build apk --debug
```

