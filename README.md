# Habit Tracker

A modern, standalone habit tracking application built with Flutter, Riverpod, Drift persistence, and Material 3 design, with full feature and logic parity to the native Android Kotlin architecture.

## Overview

Habit Tracker provides flexible tracking across multiple habit models:

- Daily Habits with rolling date navigation and active streak preservation
- Weekly Habits with ISO Monday–Sunday week boundaries and week-unit streaks
- Custom Day Scheduling skipping non-scheduled days without penalty
- Numeric Stepper Habits with magnitude-aware step sizing and quick-add chips
- Duration and Timer Habits with countdown focus sessions
- Subday Interval and Slot Habits for structured daytime routines
- Gamification with XP, streak multipliers, player titles, and achievement badges

## Architecture and Technology Stack

### Primary Framework: Flutter
- Language: Dart 3.13+ / Flutter 3.47+ (min SDK 26, target SDK 34)
- UI Toolkit: Flutter Material 3 Design System
- State Management: Flutter Riverpod 2.6+
- Local Persistence: Drift Database with reactive Streams and type-safe DAOs
- Background Tasks: `flutter_local_notifications`, native focus timer service, and background rollover tasks
- Widgets: Native Android AppWidgets & iOS WidgetKit via shared preferences synchronization
- Charts: Custom / `fl_chart` configured for Vico visual parity

### Reference Implementation: Native Android (Kotlin)
- Location: `app/src/main/java/com/productivity/habits/`
- Stack: Kotlin 2.0, Jetpack Compose, Room, Hilt, Glance widgets

## Project Structure

```text
habit-tracker-android/
├── lib/                                # Flutter source code
│   ├── data/
│   │   ├── local/                      # Drift database, DAOs, tables, converters
│   │   ├── preferences/                # SharedPreferences / Theme preferences
│   │   ├── repositories/               # Repository implementations
│   │   └── schedulers/                 # Notification and background schedulers
│   ├── di/                             # Riverpod provider definitions
│   ├── domain/
│   │   ├── engines/                    # Pure Dart calculation engines (Streak, Stepper, Slots)
│   │   ├── gamification/               # XP and achievement evaluation engines
│   │   ├── models/                     # Domain models
│   │   └── repositories/               # Repository interfaces
│   ├── services/                       # Focus timer, widget sync, rollover services
│   └── ui/                             # Material 3 UI (Daily, Matrix, Analytics, Detail, Form)
├── test/                               # Flutter unit, widget, and domain test suite
├── android/                            # Android native host project & widgets
│   ├── app/
│   │   ├── build.gradle.kts            # Android application gradle config
│   │   └── src/main/kotlin/com/productivity/habits/
│   │       ├── MainActivity.kt
│   │       ├── FocusTimerService.kt
│   │       └── widgets/                # Android AppWidget receivers & layouts
├── app/                                # Kotlin reference source implementation
├── plans/                              # Architecture specifications and migration roadmap
├── Makefile                            # Build, test, run, and emulator automation
└── pubspec.yaml                        # Flutter package dependencies
```

## Getting Started

### Prerequisites

- Flutter SDK 3.47+
- Dart SDK 3.13+
- Java 17 or Java 21 JDK
- Android SDK installed (`ANDROID_HOME` or `~/Library/Android/sdk`) with Platform SDK 34

### Building with Flutter

To build the debug APK:

```bash
flutter build apk --debug --android-skip-build-dependency-validation
```

Debug builds use the default Android debug key. Release builds require a private keystore via `ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, and `ANDROID_KEY_PASSWORD`, or a gitignored `android/key.properties` file.

To build release split-ABI APKs:

```bash
flutter build apk --release --split-per-abi --android-skip-build-dependency-validation
```

To build the release Android App Bundle (AAB):

```bash
flutter build appbundle --release --android-skip-build-dependency-validation
```

### Running Unit & Widget Tests

Execute the automated test suite:

```bash
flutter test
```

### Using Make Commands

A `Makefile` is provided for common development and debugging tasks:

```bash
# Display help and available commands
make help

# Build the Flutter debug APK
make build

# Run all Flutter unit and widget tests
make test

# Run Flutter code analysis
make lint

# Run Drift/Riverpod code generator
make codegen

# List available Android Virtual Devices (AVDs)
make emulator-list

# Start the default emulator in the background
make emulator-start

# Stop running emulator
make emulator-stop

# Build, install, and launch Flutter app (starts emulator if none running)
make run

# Stream colored logcat logs for the application
make logcat
```

### Native Kotlin Reference Commands

```bash
# Run native Kotlin unit tests
make kotlin-test

# Build native Kotlin debug APK
make kotlin-build
```

## Privacy Policy

Habit Tracker is completely offline and stores all data locally. For details, see [PRIVACY.md](PRIVACY.md).
