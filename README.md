# Habit Tracker Android

A native Android habit tracking application built with Jetpack Compose, Material 3, Room persistence, and Kotlin Coroutines/Flow following Clean Architecture principles.

## Overview

Habit Tracker provides flexible tracking across multiple habit models:

- Daily Habits with rolling date navigation and active streak preservation
- Weekly Habits with ISO Monday–Sunday week boundaries and week-unit streaks
- Custom Day Scheduling skipping non-scheduled days without penalty
- Numeric Stepper Habits with magnitude-aware step sizing and quick-add chips
- Duration and Timer Habits with countdown focus sessions
- Subday Interval and Slot Habits for structured daytime routines

## Architecture and Technology Stack

The application follows the official Android Architecture guidelines:

- Language: Kotlin 2.0 with Java 8+ API desugaring (min SDK 26, target SDK 34)
- UI Toolkit: Jetpack Compose with Material 3 Design System
- Dependency Injection: Hilt / Dagger
- Persistence: Room Database with reactive Flow streaming and Prepopulation callback
- Domain Engine: Pure Kotlin calculation engines for streaks, dynamic stepping, and subday slots
- Background Tasks: AlarmManager for exact reminders; WorkManager for maintenance and day-rollover
- Widgets: Jetpack Glance (AppWidgets)
- Charts: Vico Compose

## Project Structure

```text
habit-tracker-android/
├── app/
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/productivity/habits/
│   │   │   │   ├── data/
│   │   │   │   │   ├── local/          # Room database, DAOs, entities, converters
│   │   │   │   │   ├── repository/     # Repository implementations
│   │   │   │   │   └── scheduler/      # Reminder scheduler implementations
│   │   │   │   ├── di/                 # Hilt dependency injection modules
│   │   │   │   ├── domain/
│   │   │   │   │   ├── engine/         # Calculation engines (Streak, Stepper, Slots)
│   │   │   │   │   ├── model/          # Domain models
│   │   │   │   │   ├── repository/     # Repository interfaces
│   │   │   │   │   └── scheduler/      # Scheduler interfaces
│   │   │   │   └── ui/
│   │   │   │       └── common/         # Icon registry and shared UI components
│   │   │   └── AndroidManifest.xml
│   │   └── test/                       # Comprehensive unit test suite
│   ├── build.gradle.kts
│   └── proguard-rules.pro
├── gradle/
│   └── libs.versions.toml              # Version catalog
├── plans/                              # Specifications and phase-wise roadmaps
├── Makefile                            # Build, test, and emulator automation
├── build.gradle.kts
├── settings.gradle.kts
└── gradle.properties
```

## Getting Started

### Prerequisites

- Java 17 or Java 21 JDK
- Android SDK installed (`ANDROID_HOME` or `~/Library/Android/sdk`)
- Android Build-Tools 34.0.0 and Platform SDK 34

### Building with Gradle

To assemble the debug build:

```bash
./gradlew assembleDebug
```

To assemble the release build:

```bash
./gradlew assembleRelease
```

### Running Unit Tests

Execute the automated unit test suite:

```bash
./gradlew testDebugUnitTest
```

### Using Make Commands

A `Makefile` is provided for common development and debugging tasks:

```bash
# Display help and available commands
make help

# Build the debug APK
make build

# Run all unit tests
make test

# List available Android Virtual Devices (AVDs)
make emulator-list

# Start the default emulator in the background
make emulator-start

# Stop running emulator
make emulator-stop

# Build, install, and launch the app (starts emulator if none running)
make run

# Stream colored logcat logs for the application
make logcat
```

## Implementation Phases

The project roadmap is structured into sequential milestones:

- Phase 1: Project Setup, Room Persistence, Domain Calculation Engines, and Tests
- Phase 2a: Daily Tracker Core, Material 3 Theme, Rolling Week Strip, and Boolean Cards
- Phase 2b: Numeric, Timer, and Slot Cards with Add/Edit Habit Form
- Phase 3: Dedicated Habit Detail Screen, Monthly Calendar, and Circular Focus Timer
- Phase 4: Week Matrix Grid and Analytics with Vico Charts
- Phase 5: AlarmManager Reminders, WorkManager Rollover, and Jetpack Glance Widgets

For detailed phase documentation and technical specifications, refer to `plans/overview.md` and `plans/phasewise/README.md`.

## Flutter Migration and Parity Guidelines

A comprehensive, phase-by-phase migration plan to Flutter is documented in `plans/flutter/`.

### Core Directive for Agents

- **Do Not Start from Scratch:** Every Flutter model, calculation engine, Drift table, DAO query, Riverpod controller, and widget layout must directly reference and port the corresponding Kotlin implementation in `app/src/main/java/com/productivity/habits/`.
- **Logic & UI Parity:** All calculations, algorithms, UI paddings, colors, shapes, haptic strengths, and lifecycle behaviors in Flutter must match the Kotlin source with 100% exact parity.
- **Reference Kotlin Source Mapping:** Refer to `plans/flutter/README.md` for the complete 1:1 file mapping table between Kotlin source files and Flutter target files.

### Flutter Development & Verification Workflow

The Flutter SDK (3.47+) and Android SDK toolchain (36.1.0) are pre-installed and configured on the machine.

```bash
# Run pure Dart domain unit tests
flutter test test/domain/

# Run widget and UI component tests
flutter test test/ui/

# Run code generator for Drift tables and Riverpod providers
dart run build_runner build --delete-conflicting-outputs

# Build the debug APK
flutter build apk --debug

# Launch interactive emulator session with Hot Reload
flutter run
```

