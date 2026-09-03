# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.13.1] - 2026-09-03

### Fixed

- Backup import hardening: reject picked files over 25MB and decompressed payloads over 50MB to prevent OOM and gzip-bomb denial of service.
- Sync envelope validation: reject unsupported schema versions, missing device and payload fields, malformed record ids and dates, and oversized record lists on import.
- Backup encryption pinning: enforce exact KDF iteration count, AES-256-GCM and PBKDF2-HMAC-SHA256 identifiers, salt and nonce lengths, and ciphertext size caps on decrypt.
- Sync merge protection: quarantine remote timestamps more than 5 minutes in the future so crafted backups cannot force last-write-wins overwrites; merge only allowlisted preference keys.
- Sobriety streak time-bomb: made future-date completion checks clock-injectable so tests no longer depend on wall-clock time.
- Maestro workflow execution reliability.

## [0.13.0] - 2026-09-01

### Added

- Abstinence and negative habit tracking: support for breaking bad habits with custom clean dates, live sobriety duration counters, and progressive milestone celebrations.
- Urge Surfer mindfulness tool: 2-minute box breathing exercise with visual expansion animations, ambient chime audio cues, and emergency grounding support.
- Archived habits category filter: dedicated category chip to filter, view, and restore archived habits with badge counts.
- Partial routine progress support: step satisfaction evaluation for multi-slot boolean, numeric, and timer habits across daily tracker cards and routine player.
- Routine date targeting: support for executing and logging habit routines for non-today target dates.
- Drift SQLite schema version 9 migration adding `isNegative` and `cleanSince` columns to `habits` table with automated data migration and sync envelope serialization.
- Maestro automated end-to-end test flows for negative habit sobriety tracking and incremental routine progress.

### Changed

- Decoupled streak shield banking and auto-protection mechanisms from negative habits to reflect passive clean-day tracking.
- Enforced read-only state for archived habits in habit detail view and daily tracker, disabling active check-in mutations while preserving historic logs.
- Dynamic habit form section visibility when toggling between standard and sobriety habit modes.

### Fixed

- Monthly calendar and weekly matrix negative habit status evaluation across custom dates.
- Day number text contrast in monthly calendar view.
- Routine player countdown timer ring layout sizing and initialization.

## [0.12.1] - 2026-08-31

### Fixed

- Category filter chip selection and reset: fixed issue where tapping "All" chip did not clear the active category filter.
- Scheduled habit and XP count consistency: ensured total daily scheduled counts and earned XP remain consistent across category selections and search filtering.
- Category chip badges: added scheduled habit counts to all category filter chips.
- Empty category state: added contextual empty state messaging and quick action to create a habit or return to all habits when filtering an empty category.

### Changed

- Daily Progress Card: redesigned hero progress ring to 80x80 with prominent percentage and completion statistics.

## [0.12.0] - 2026-08-31

### Added

- Habit Stacking Routines allowing users to group habits into sequential morning, workday, or evening flows with custom cues and target durations.
- Routine Builder bottom sheet supporting reorderable habit steps, custom duration targets, reminder times, and scheduled days configuration.
- Full-screen Routine Player Screen featuring automated countdown and stopwatch timers, step advance/skip controls, completion celebrations, and step transition sound cues.
- Routine gamification rewards including bonus XP on routine completion, streak multipliers, and 3 unlockable achievement badges (Chain Starter, Routine Master, Iron Routine).
- Drift SQLite schema version 8 migration introducing `habit_routines` and `routine_logs` tables with DAOs and reactive stream providers.
- Extended backup export, encrypted restore, and 2-way sync envelope schemas to serialize habit routines and routine logs with tombstone tracking.

## [0.11.0] - 2026-08-21

### Added

- Elastic Goals and Bad-Day Mode introducing three-tiered milestone tracking (Mini, Base, Elite) so users can preserve streak momentum on low-energy days.
- Interactive milestone check-in controls with 1-tap selectors on daily habit cards and habit detail screens with custom tier progress indicators.
- Proportional tiered XP rewards (Mini: 5 XP, Base: 20 XP, Elite: 35 XP) amplified by active streak multipliers.
- Drift SQLite schema version 7 migration adding `miniTargetValue` and `eliteTargetValue` columns to `habits` table and `targetTier` column to `habit_logs` table.
- Full backup export, JSON serialization, and encrypted restore support for elastic goal tiers and logged milestone check-in tiers.
- Interactive web showcase tab and comprehensive user guide documentation with visual screenshots.

### Fixed

- Achievement evaluator convergence loop ensuring level-dependent mastery badges (e.g. Pathfinder Journey) correctly unlock when earned milestone badge XP pushes the player past the required level threshold.
- Active streak multiplier evaluation strictly bound to active `currentStreak` rather than historic best streaks.
- Achievement database persistence enforcing deterministic unlock status (`progress >= targetValue`) and pruning unearned rows.
- SnackBar presentation during backup restore sheet dismissal avoiding Hero animation tag collisions.

## [0.10.0] - 2026-08-20

### Added

- Google Health Connect Android SDK integration (`androidx.health.connect`) supporting 7 physical health metrics: Daily Steps, Active Exercise, Move Minutes, Distance, Active Calories, Hydration, and Sleep Duration.
- Zero-touch habit check-ins and automated background progress synchronization from Google Fit, smartwatches, and connected wearable sensors.
- Discrete cadence analysis engine in Kotlin for Google Fit Move Minute parity (&ge;30 steps/min cadence threshold) and real-time elapsed daily calorie burn queries.
- Multi-unit conversion engine (`HealthSyncEngine`) with automatic normalizations across kilometers/miles/meters, milliliters/liters/glasses, and hours/minutes.
- Health Connect settings bottom sheet with granular runtime permission controls, live sync indicators, sync interval configurations, and manual 1-tap sync actions.
- Habit creation form integration with Health Connect toggle, metric selector chips, recommended goal defaults, and custom target preservation.
- Drift database schema version 6 migration adding `healthMetric` and `healthSyncEnabled` columns to `habits` table.
- Periodic and multi-day reconciliation background worker powered by Android WorkManager (`HealthConnectSyncWorker`).
- Habit cards and habit detail view real-time sync status badges, deep-linked settings, and manual sync action buttons.
- Comprehensive user guide and landing page documentation for Health Connect setup, permissions, and metrics.

## [0.9.0] - 2026-08-20

### Added

- Data and Backup settings bottom sheet with options for snapshot export, plain JSON, Gzip archive (.json.gz), and RFC 4180 CSV tables.
- Zero-knowledge AES-256-GCM client-side encrypted backup export and restore engine with PBKDF2 key derivation (100,000 iterations, 32-byte salt, 12-byte IV) and cryptographic authentication tags.
- Secure 4-segment alphanumeric passkey generator and responsive segment input modal with paste support, live verification, and granular error feedback.
- Deterministic 2-way sync merge engine with Last-Write-Wins (LWW) resolution, ISO-8601 UTC timestamps, natural key deduplication for subday slots, and idempotent gamification XP/level re-evaluation.
- Drift database schema version 5 migration introducing soft-delete tombstone flags (`isDeleted`) and `createdAt`/`updatedAt` synchronization timestamps across habits, logs, shields, categories, and gamification tables.
- Direct save-to-folder file export allowing users to store backups in local document directories or synchronized file providers.
- Comprehensive user guide and technical documentation covering offline backup encryption, merge semantics, and schema structures.

## [0.8.1] - 2026-08-20

### Added

- Responsive Android Home-Screen Widgets (2x2, 2x4, and 4x4) supporting dynamic density scaling, dark/light theme tokens, and interactive quick check-in actions.
- Interactive scrollable `ListView` (`RemoteViewsService` / `TodaysHabitsWidgetService`) for 2x4 and 4x4 Today's Habits widgets.
- Widget preview screen (`HabitWidgetPreviewsScreen`) and mock data fixtures for interactive widget visual verification.
- Comprehensive system architecture, module boundaries, and reactive logic flow diagrams in project documentation.

### Fixed

- Do Not Disturb (DND) mode lifecycle handling, permission verification, and state synchronization with native Android notification policy.
- Focus Timer screen UI state preservation during external notification interactions and background service resets.


## [0.8.0] - 2026-08-19

### Added

- Phial brand identity across application launcher, Play Store metadata, deep links, and package identifier (`app.phial.habits`).
- Clean first-run onboarding with empty state and on-demand "Load Demo Habits" option.
- Non-intrusive animated reflection toast with swipe-to-dismiss and auto-dismissal replacing blocking modal popups.
- Per-habit reflection opt-in setting (`promptReflection`) supported by Drift database schema version 4 migration.
- Material 3 `SearchBar` header on Daily screen integrating live habit search and profile bottom sheet.
- Modernized navigation headers: compact week stepper in Week Matrix, today completion counter in Analytics, and live level/badge pill in Mastery.
- Deep link routing for `phial://habits/...` and `app://habits/...` URIs with empty ID validation.
- Structured `AppLogger` utility wrapping `dart:developer.log` for error telemetry and lifecycle logging.
- Automated Phase 1-6 performance benchmark suites and Python hardware benchmark runner with Markdown reporting and plots (`make benchmark`, `make perf-test`).
- Automated ADB UI and regression testing harness (`make adb-test`).
- Dedicated privacy policy documentation in `PRIVACY.md`.
- Fully responsive mobile overhaul for documentation and showcase website.
- Automated `flutter analyze` code quality gate in CI workflow.

### Performance

- Tuned SQLite database configuration with WAL journal mode, memory temp store, 4MB cache PRAGMAs, and transactional batch mutations.
- Pre-indexed log, shield, and streak lookups eliminating quadratic scans in UI controllers, gamification evaluators, and widget sync.
- In-memory cached habit search and category filtering yielding a 334x acceleration in search latency.
- Decomposed Daily Tracker, Analytics, and Week Matrix screens with granular Riverpod selectors and value equality on UI states.
- Debounced widget synchronization (500ms coalescing timer) with unawaited check-in updates and async startup initialization.
- Virtualized week matrix rows with extracted lightweight cell widgets.

### Fixed

- Prevented first-second clipping on focus timer countdown by using ceiling duration calculation and fixing integer truncation across Dart and Kotlin tickers.
- Synchronized focus timer state with native foreground service events and logged completed sessions reliably.
- Habit reminder scheduling now uses repeating zoned alarm components and recalculates dynamically on check-ins and app resume.
- Day rollover task now runs idempotently on app startup and resume, automatically protecting missed days with available streak shields.
- Hardened Android AppWidget toggle broadcast receivers with installation-scoped authentication tokens.
- Replaced Play-restricted `USE_EXACT_ALARM` permission with contextual notification and alarm permission requests on habit reminder creation.
- Configured explicit storage domain rules in `data_extraction_rules.xml` and disabled cloud backup (`android:allowBackup="false"`).
- Resolved mobile text clipping and table overflow on documentation site.
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
