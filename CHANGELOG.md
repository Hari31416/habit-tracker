# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.8.0-alpha.1] - 2026-08-19

### Added

- Phial branding across launcher name, Play store metadata, deep links, and package identifier (`app.phial.habits`).
- On-demand "Load Demo Habits" option in the empty daily tracker screen for tester exploration.
- Structured `AppLogger` utility wrapping `dart:developer.log` for error and warning telemetry.
- Support for `phial://habits/...` and `app://habits/...` deep link routing with empty ID validation.
- Dedicated privacy policy documentation in `PRIVACY.md`.
- `flutter analyze` gate in CI workflow.

### Fixed

- Habit reminder scheduling now uses repeating zoned alarm components and recalculates on in-app check-ins and app resume.
- Day rollover task now executes idempotently on startup and resume, auto-protecting missed days with available streak shields.
- Removed Play-restricted `USE_EXACT_ALARM` permission and relocated notification/alarm permission requests to contextual habit creation.
- Disabled Android cloud backup and database auto-extraction (`android:allowBackup="false"`).
- Hardened widget toggle broadcast receivers with installation-scoped auth tokens.
- Resolved all analyzer warnings and benchmark print lints.

## [0.7.0] - 2026-08-18

### Added

- Post-check-in reflection with optional energy rating (1-5), mood tags, and a short micro-note.
- Reflection history timeline on the habit detail screen.
- Wellbeing correlation summary comparing energy on completed vs missed days.
- Habit log energy and mood fields with a schema v3 database migration.

### Fixed

- Shield bank and reflection bottom sheets wrap in Material so ink and theming render correctly.

## [0.6.1] - 2026-08-18

### Changed

- Release APKs and App Bundles are signed with a private keystore supplied by GitHub Actions secrets or local Makefile credentials.

### Security

- Removed the committed debug keystore from the repository and from release signing.

## [0.6.0] - 2026-08-18

### Added

- Ambient Audio sound generator with 8 looping soundscapes (Rain, Ocean Waves, Campfire, Forest Birds, Running Stream, Cafe Ambience, Gentle Wind, White Noise) and master volume slider.
- Comprehensive technical documentation and App Showcase deployed via GitHub Pages.
- High-resolution app screenshots and verified feature guides for all core engines.

### Changed

- Updated landing page aesthetics and navigation with direct GitHub Release APK download links.
- Streamlined App Showcase with tabbed interface covering daily tracker, 7-day week matrix, Zen focus timer, habit detail, habit shields, analytics, and RPG mastery.

## [0.5.0] - 2026-08-18

### Added

- Do Not Disturb (DND) mode toggle directly accessible in Focus Timer UI.
- Split-ABI release packaging (`--split-per-abi`) producing optimized individual architecture APKs (`arm64-v8a`, `armeabi-v7a`, `x86_64`) and Android App Bundle (`.aab`).
- Automated changelog extraction in CI/CD pipeline for GitHub Releases.

### Changed

- Enhanced timer session state management to preserve remaining duration on service pause/stop, enabling distinct reset and resume flows.
- Makefile release targets expanded with `build-release` (split-ABI) and `build-appbundle`.

## [0.4.0] - 2026-08-18

### Added

- Default Flutter Android build and verification toolchain integration.
- CI/CD automated workflow running Flutter analyze, unit/widget tests, and release APK packaging.
- Dedicated Flutter signing configuration with local debug keystore.

### Changed

- Transitioned root build system, test suites, and linter defaults in Makefile to Flutter.
- Aligned Flutter host application ID and namespace with `com.productivity.habits`.
- Updated release automation process and documentation for Flutter project versioning.

## [0.3.0] - 2026-08-18

### Added

- Dedicated Focus Timer screen:
  - Full-screen focus session with large animated circular timer arc and live countdown.
  - Duration adjustment chips (+1m, +5m, -1m, -5m) and session controls (Start, Pause, Resume, Reset).
  - Integrated Do Not Disturb (DND) filter toggle.
  - Lifecycle-scoped immersive fullscreen mode (hidden status and navigation bars) and screen wake lock.
  - Direct navigation entry from the Habit Detail circular focus timer header.

### Changed

- Compacted Habit Detail hero header layout with refined typography and circular check-in button.

### Fixed

- Applied system navigation bar insets to prevent bottom navigation bar content clipping.
- Added partial progress increment/decrement controls to Habit Detail card for numeric and timer habits.
- Aligned custom reminder time picker chip styling with preset reminder chips.

## [0.2.0] - 2026-08-17

### Added

- 5 responsive Android home-screen widgets built with Jetpack Glance:
  - **Today's Habits**: Interactive daily habit checklist with Glance `LazyColumn` and stable check-in toggles.
  - **Daily Focus**: Summary of daily completion rate, active streak, focus minutes, and earned XP.
  - **Focus Timer**: Dedicated timer card with live countdown, quick presets, and Start/Pause/Resume/Reset controls.
  - **Streaks**: At-a-glance tracker highlighting active streaks, best records, and at-risk habits.
  - **XP / Mastery**: Gamification widget displaying player level, title, progress bar, and next badge target.
- Multi-size responsive widget layouts tailored for Small (2x1), Medium (2x2), and Large (4x2) dimensions.
- Reactive Glance composition architecture bound directly to `StateFlow` and Room database queries.
- Immersive Focus Mode experience:
  - Automatic fullscreen immersive mode hiding system status and navigation bars during active sessions.
  - Screen wake lock (`FLAG_KEEP_SCREEN_ON`) during focus sessions.
  - Opt-in Do Not Disturb (DND) filter integration with automatic filter restoration on session completion.
- Bottom navigation bar featuring 4 core destinations and an elevated center quick-add action button.
- Redesigned Daily Tracker screen with circular hero adherence progress ring and compact date selector.
- Redesigned Habit Detail view with a 200dp circular sweep countdown, duration adjust chips, and statistics strip.
- Redesigned Week Matrix grid with adherence headers and a daily completions breakdown chart.
- Enhanced Analytics and Badges showcase with 30-day consistency metrics and ranked leaderboard layout.

### Fixed

- Replaced standard Glance Column with `LazyColumn` in Today's Habits widget to remove the 10-child element limit.
- Prevented unneeded full-screen widget refreshes on timer state transitions.
- Resolved check-in toggle support across Numeric, Timer, Times-per-day, and Boolean habit types.
- Fixed week matrix grid text truncation and unpinned badges showcase top bar for natural scrolling.

## [0.1.0] - 2026-08-17

### Added

- Native Android Habit Tracker implementation in Jetpack Compose and Material 3
- Room database schema with support for daily, weekly, and custom schedule habits
- Domain calculation engine for streak tracking and completion metrics
- Habit creation, editing, detail inspection, and archive management
- Dark and light theme support with dynamic Material 3 color system
- Gamification level and badge progression system
- Automated GitHub Actions release pipeline building release APKs
