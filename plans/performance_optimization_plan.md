# Performance Optimization Plan

This document outlines the performance bottlenecks identified in the local Flutter habit tracker application and details actionable technical optimization strategies across persistence, state streams, computation algorithms, platform channels, startup pipeline, and user interface rendering.

Code review on 2026-08-19 validated each original claim against the current tree and added extra bottlenecks. Verdicts use **Do it**, **Do it with caveats**, **Low impact**, **Risky**, or **Overstated**.

## Overview and Problem Statement

The application is an offline-first, local Flutter application backed by Drift SQLite, Riverpod state management, and platform widget synchronizers. Despite having no network latency, several operational paths experience latency and UI frame drops.

Slowness is not primarily disk I/O on a tiny habits table. The hot path on a check-in is main-isolate CPU plus duplicated Drift watches:

1. Write one log row (sometimes several sequential statements).
2. Every `watchAllLogs()` subscriber reloads and maps the entire log table.
3. Daily, matrix, analytics, gamification, widget sync, and detail each recompute 365-day streaks for every habit.
4. `WidgetSyncService.syncAllWidgets()` then re-reads all logs and spins up extra gamification streams.
5. Daily tracker `build()` watches the whole `DailyTrackerUiState`, so the screen rebuilds as a unit.

Profiling of the architecture revealed six primary bottleneck categories:

- Disk I/O stalls caused by unconfigured SQLite journaling mode, lack of indexes on the habits table, and redundant database seeding on every cold start.
- Stream multiplication storms and feedback cascades where controllers subscribe to multiple redundant streams, resulting in up to 18 concurrent database listeners (24 on the badges screen; more if detail or widget sync is active).
- Unbounded full-table queries and N+1 database round-trips during shield protection and check-in logging.
- Heavy CPU operations (repeated `DateFormat` string parsing, 395 date formatting operations per habit, and nested loops) executed synchronously on the main UI thread.
- Unbatched platform MethodChannel dispatches triggered synchronously on every check-in click.
- Monolithic screen rebuilds where typing in search or toggling a single habit causes the entire screen hierarchy to rebuild.

## Validation Summary

| Item                                    | Verdict                | Notes                                                                                                               |
| --------------------------------------- | ---------------------- | ------------------------------------------------------------------------------------------------------------------- |
| SQLite WAL / PRAGMAs                    | **Do it with caveats** | WAL and `synchronous=NORMAL` are real wins. A 64MB cache is oversized for this dataset.                             |
| Habits table indexes                    | **Low impact**         | Correct, but the habits table is tens of rows. Not the source of jank.                                              |
| Seeder on every launch                  | **Do it with caveats** | Already runs in `onCreate` *and* `beforeOpen`. Remove the `beforeOpen` call. Impact is small.                       |
| Transactions / N+1 shields              | **Do it**              | Check-in writes and `autoProtectMissedDays` are real sequential I/O.                                                |
| Scoped date-range log queries           | **Risky**              | Right idea for matrix and daily UI. A 30-90 day window would break 365-day streaks and lifetime XP.                 |
| Shared gamification stream              | **Do it**              | Highest-leverage item. There are four factory methods, not three.                                                   |
| Single-pass streak map                  | **Do it**              | Steps 1, 2, 6, and `AchievementEvaluator` all recompute streaks.                                                    |
| Achievement feedback loop               | **Do it**              | `upsertAchievements` is fire-and-forget and retriggers the same pipeline.                                           |
| Debounce daily `_recomputeState`        | **Do it**              | Coalesce stream bursts. Do not recompute streaks on search text.                                                    |
| `autoDispose` daily tracker             | **Do it with caveats** | Provider is permanent. Recalc is event-driven, not a tight loop. Still holds four watches off-screen.               |
| Fast ISO date helpers                   | **Do it**              | Real CPU cost, secondary to fewer 365-day passes.                                                                   |
| Split analytics providers / `compute()` | **Do it with caveats** | Split watches help rebuilds. `compute()` is premature until logs are large. Nested `.where` scans matter more.      |
| Debounce widget MethodChannel           | **Do it**              | Also stop awaiting sync on the check-in UI path, and stop spawning gamification streams inside sync.                |
| Post-frame cold start                   | **Overstated**         | `Future.microtask` is not the blocker. `tz_data.initializeTimeZones()` and notification init run *before* `runApp`. |
| Riverpod `select` on screens            | **Do it**              | Daily and analytics watch the whole state object.                                                                   |
| Virtualize `WeekMatrixGrid`             | **Do it with caveats** | Grid sits in a `SingleChildScrollView`. `ListView.builder(shrinkWrap: true)` will not virtualize. Use slivers.      |
| Shield card StreamBuilder               | **Do it**              | `getShieldBankState()` creates a *new* 6-listener pipeline on every `build()`.                                      |

## Phase 1: Database and Persistence Layer Optimizations

### SQLite WAL Mode, Cache Size, and Memory Temp Store

- **File Reference:** `lib/data/local/app_database.dart`
- **Verdict:** **Do it with caveats**
- **Root Cause:** Drift `NativeDatabase.createInBackground` is already used, so SQLite work is off the UI isolate. Journal mode is still default `DELETE`. `beforeOpen` currently only sets `PRAGMA foreign_keys = ON`. Writes still serialize readers more than WAL would.
- **Caveats:**
  - Do not expect a 5x to 10x UI speedup on a small local database. The win is smoother concurrent reads during check-ins.
  - `PRAGMA cache_size = -64000` (64MB) is too large for a habit log database. Prefer something like `-2000` to `-8000` (2-8MB) so low-memory devices are not pressured.
  - Set PRAGMAs in `NativeDatabase` `setup:` *and/or* `beforeOpen`. WAL must be set on the connection that executes queries.
- **Implementation:** Configure PRAGMAs in `AppDatabase.migration.beforeOpen`:

```dart
beforeOpen: (details) async {
  await customStatement('PRAGMA journal_mode = WAL;');
  await customStatement('PRAGMA synchronous = NORMAL;');
  await customStatement('PRAGMA foreign_keys = ON;');
  await customStatement('PRAGMA temp_store = MEMORY;');
  await customStatement('PRAGMA cache_size = -4000;'); // 4MB cache
}
```

- **Impact:** Allows concurrent reads while writing and reduces fsync cost. Helpful, not sufficient alone.

### Adding Missing Indexes to Habits Table

- **File Reference:** `lib/data/local/tables/habits.dart`
- **Verdict:** **Low impact**
- **Root Cause:** While `HabitLogs` and `HabitShields` have compound indexes, the `Habits` table contains zero indexes besides the primary key. Queries filtering by `archived == false`, `pinned`, or `categoryId` execute full table scans.
- **Why this will not fix perceived slowness:** Active habit count is small. A full scan of dozens of rows is microseconds. Indexes are still fine hygiene if shipping a schema bump (`schemaVersion` is currently `3`; adding `@TableIndex` requires `onUpgrade` `createIndex` calls).
- **Implementation:** Add `@TableIndex` definitions to `Habits`:

```dart
@DataClassName('HabitRow')
@TableIndex(name: 'idx_habits_archived', columns: {#archived})
@TableIndex(name: 'idx_habits_pinned', columns: {#pinned})
@TableIndex(name: 'idx_habits_category_id', columns: {#categoryId})
class Habits extends Table { ... }
```

- **Impact:** Negligible for current data sizes. Do this opportunistically with other schema work, not as sprint 1.

### Eliminating Redundant Seeder Execution on Every Launch

- **File References:** `lib/data/local/app_database.dart`, `lib/data/local/database_seeder.dart`
- **Verdict:** **Do it with caveats**
- **Root Cause (corrected):** `onCreate` already calls `DatabaseSeeder.seedIfEmpty(this)`. `beforeOpen` calls it again on *every* open. That re-runs `insertDefaultCategories` (`insertOrIgnore` batch) and `getActiveHabitsOnce()`. It is redundant work, not a full reseed of habits.
- **Implementation:** Restrict `DatabaseSeeder.seedIfEmpty(this)` strictly to `onCreate` within `MigrationStrategy`. Delete the `beforeOpen` call.
- **Impact:** Small cold-start saving. Safe and worth doing.

### Atomic Transactions and Resolving N+1 Database Queries

- **File Reference:** `lib/data/repositories/habit_repository_impl.dart`
- **Verdict:** **Do it**
- **Root Cause:**
  - `toggleBooleanCheckIn`, `updateNumericValue`, and `addNumericDelta` execute 3 to 4 sequential database queries without an enclosing transaction. Boolean complete for `timesPerDay` / `subdayInterval` also loops `upsertLog` per slot instead of `HabitLogDao.insertLogs`.
  - `addNumericDelta` reads logs, then calls `updateNumericValue`, which reads the habit and logs again.
  - `autoProtectMissedDays` already loads all logs and shields once, then after each `applyShield` it calls `await getAllShieldsOnce()` and `ShieldBankingEngine.calculateBankState()` again. That is N+1 plus a full streak pass per applied shield.
  - `autoProtectMissedDays` also uses `habitDao.watchActiveHabits().first` instead of `getActiveHabitsOnce()`.
- **Implementation:**
  - Wrap multi-statement repository mutations in Drift `transaction(() async { ... })` blocks.
  - Batch slot inserts with `insertLogs`.
  - In `autoProtectMissedDays`, keep a local shield list, decrement bank counts in memory, and batch-insert shields once.

- **Impact:** Lower check-in write latency and far cheaper midnight auto-protect.

### Scoped Date-Range Log Queries

- **File References:** `lib/data/repositories/habit_repository_impl.dart`, `lib/data/local/daos/habit_log_dao.dart`
- **Verdict:** **Risky** if applied as a global 30-90 day window. **Do it** per screen with the right window.
- **Root Cause:** `HabitRepositoryImpl.getAllLogs()` and `HabitLogDao.watchAllLogs()` fetch and deserialize every historical habit log row whenever any check-in occurs. Confirmed subscribers:
  - `DailyTrackerController`
  - `WeekMatrixController` (only needs the visible week)
  - `AnalyticsController`
  - `GamificationRepositoryImpl._buildGamificationStream`
  - `WidgetSyncService.syncAllWidgets` via `getAllLogsOnce()`
  - `ShieldBankBottomSheet` nested `StreamBuilder`
- **Correct windows:**
  - Week matrix: visible Monday-Sunday only.
  - Daily tracker streak UI: at least 365 days (matches `StreakCalculator.calculateStreak`).
  - Gamification XP and achievements: full history, or persist derived totals instead of rescoring all logs.
  - Widget sync: today plus enough history for current streak (365 days), not necessarily lifetime.
- **Implementation:**
  - Shift screen controllers to `watchLogsForDateRange(startDate, endDate)` with the window above.
  - Retain full-history queries strictly for on-demand data export and lifetime XP until XP is persisted.
- **Do not** switch daily streaks to a 30-day window. `bestStreak` and `totalCompletions` walk 365 days today.

## Phase 2: Reactive Data Flow and Gamification Architecture

### Consolidating Gamification Streams and Eliminating Redundant Listeners

- **File References:** `lib/data/repositories/gamification_repository_impl.dart`, `lib/ui/gamification/controllers/gamification_controller.dart`
- **Verdict:** **Do it** (highest leverage)
- **Root Cause (corrected):** Each of `getPlayerProgression()`, `getAchievements()`, `getPendingCelebration()`, and `getShieldBankState()` calls `_buildGamificationStream()`, which opens **six** Drift watches and runs `evaluateAndEmit()` on the calling isolate.
  - `GamificationController` subscribes to three of those (18 listeners).
  - `ShieldBankStatusCard` and `ShieldBankBottomSheet` each call `getShieldBankState()` (six more).
  - `HabitDetailController` also listens to `getShieldBankState()`.
  - `WidgetSyncService.syncAllWidgets` awaits `.first` on progression and achievements, which creates two more full pipelines per sync.
- **Implementation:**
  - Convert `_buildGamificationStream()` into a single shared, broadcast stream managed via Riverpod (`gamificationStateStreamProvider`).
  - Cache latest calculated gamification state and emit updates only when underlying entities change.
  - Map that one stream to progression, achievements, celebration, and shield bank.

- **Impact:** Cuts redundant full-history scoring from O(subscribers) to O(1) per data change.

### Single-Pass Streak Calculations in Gamification Pipeline

- **File Reference:** `lib/data/repositories/gamification_repository_impl.dart`
- **Verdict:** **Do it**
- **Root Cause:** `evaluateAndEmit()` calculates streaks for all habits in Step 1, calculates streaks for all habits again in Step 2, and calls `ShieldBankingEngine.calculateBankState()` in Step 6 which calculates streaks for all habits a third time. `AchievementEvaluator.evaluateAll()` then calculates streaks a fourth time.
- **Implementation:** Calculate `StreakResult` for each habit once into a `Map<String, StreakResult>` at the start of `evaluateAndEmit()` and reuse it across XP calculation, achievement evaluation, and shield banking. Extend `EvaluationContext` / `ShieldBankingEngine` to accept precomputed streaks.

### Breaking Gamification Feedback Loops

- **File Reference:** `lib/data/repositories/gamification_repository_impl.dart`
- **Verdict:** **Do it**
- **Root Cause:** When `evaluateAndEmit()` detects a newly unlocked achievement, it executes `gamificationDao.upsertAchievements()` without awaiting. That emits on `watchAllAchievements()` and triggers `evaluateAndEmit()` again. Newly unlocked is filtered by `storedMap`, so the second pass usually writes nothing, but the full XP/streak pipeline still runs twice.
- **Implementation:**
  - Keep the in-memory unlocked check before writing (already present).
  - Ignore achievement-table emissions that did not change unlock IDs, or persist asynchronously with a re-entrancy guard so an in-flight evaluate does not restart.

### Debouncing Multi-Stream Controller Invocations

- **File Reference:** `lib/ui/daily/controllers/daily_tracker_controller.dart`
- **Verdict:** **Do it**
- **Root Cause:** `DailyTrackerController` attaches 4 independent listeners to categories, habits, logs, and shields. On app start or batch updates, all 4 emit in rapid succession, triggering `_recomputeState()` 4 consecutive times with full 365-day streak recalculations for all habits. Same pattern exists in `WeekMatrixController` and `AnalyticsController`.
- **Implementation:**
  - Coalesce `_recomputeState()` with a single microtask / `scheduleMicrotask` so batched database emissions execute once per event-loop turn.
  - Apply the same coalescing in matrix, analytics, and `evaluateAndEmit()`.

### Lifecycle Scoping on Tracker Providers

- **File Reference:** `lib/ui/daily/controllers/daily_tracker_controller.dart`
- **Verdict:** **Do it with caveats**
- **Root Cause:** `dailyTrackerControllerProvider` is a permanent `StateNotifierProvider`. Matrix, analytics, and badges providers are already `autoDispose`. When the user leaves Daily via `pushReplacementNamed`, the four Drift subscriptions stay alive and recompute on every log write.
- **Caveat:** Recalculation is not a background timer. It only runs when streams emit. `autoDispose` is still correct because Daily is not on screen. Alternatively pause subscriptions in `AppLifecycleState.paused` / when the route is not current.
- **Implementation:** Apply `autoDispose` to `dailyTrackerControllerProvider` or pause recalculations when the screen is inactive.

## Phase 3: Algorithmic and Computation Optimizations

### Fast Date String Formatting and Lexicographical Comparisons

- **File References:** `lib/domain/engines/streak_calculator.dart`, `lib/domain/gamification/achievement_evaluator.dart`, `lib/data/repositories/gamification_repository_impl.dart`
- **Verdict:** **Do it**
- **Root Cause:**
  - `StreakCalculator.calculateStreak` executes 30 daily checks + 365 daily checks using `dateFormatter.format(checkDate)`. For 20 habits, this produces 7,900 `DateFormat` evaluations *per streak pass*. One check-in currently runs several passes (daily UI, widget sync, gamification xN).
  - `AchievementEvaluator` and `GamificationRepositoryImpl` parse ISO date strings back into `DateTime` objects using `DateFormat.parse()` solely to sort dates.
- **Also do:** Walk a `Set<String>` of completed/shielded ISO dates instead of formatting 365 calendar days after the current streak has broken, if best-streak can be derived from sorted date keys. That reduces work more than swapping `DateFormat` alone.
- **Implementation:**
  - Replace `DateFormat.format()` with integer padded ISO string generation:

```dart
String formatIsoDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
```

  - Rely on standard ISO-8601 lexicographical string sorting (`dateStrA.compareTo(dateStrB)`) instead of parsing `DateTime` instances.

### Decomposed and Memoized Analytics Pipeline

- **File References:** `lib/ui/analytics/controllers/analytics_controller.dart`, `lib/ui/detail/controllers/habit_detail_controller.dart`
- **Verdict:** **Do it with caveats**
- **Root Cause:** `AnalyticsController._recalculate()` executes 30-day, 60-day, trend, heatmap, and Pearson wellbeing correlation calculations synchronously on the UI isolate whenever any log changes.
- **Stronger bug than splitting providers:** For each habit and each day it does `habitLogs.where((l) => l.date == dateStr).toList()`. That is O(habits x days x logsPerHabit). Index once as `Map<String, Map<String, List<HabitLog>>>` keyed by habitId then date.
- **Caveats:**
  - Splitting `AnalyticsUiState` into providers reduces rebuilds; it does not fix the nested scans.
  - `compute()` at 200 records is likely overhead (isolate spawn + copy). Use it only if a timeline profile shows multi-digit milliseconds after indexing.
- **Implementation:**
  - Split `AnalyticsUiState` into focused, independent providers (`consistencyProvider`, `leaderboardProvider`, `heatmapProvider`, `wellbeingProvider`) after indexing logs.
  - Memoize correlation results keyed by the most recent habit log update timestamp.
  - Offload heavy multi-month aggregation to background isolates via `compute()` only when profiling justifies it.

## Phase 4: Platform Channels and Startup Pipeline

### Debouncing Widget Sync MethodChannel Invocations

- **File References:** `lib/services/widget_sync_service.dart`, `lib/ui/daily/controllers/daily_tracker_controller.dart`
- **Verdict:** **Do it**
- **Root Cause:** Every habit toggle, numeric delta, pin, slot check-in, and quick-add **awaits** `WidgetSyncService.syncAllWidgets()`. Each invocation:
  - Queries all active habits, all logs, all categories.
  - Runs `StreakCalculator.calculateStreak` for every habit.
  - Awaits `getPlayerProgression().first` and `getAchievements().first` (two extra full gamification pipelines).
  - Dispatches up to 6 `MethodChannel` calls.
- **Implementation:**
  - Introduce a 400ms to 600ms debounce timer in `WidgetSyncService.syncAllWidgets()`.
  - Do not `await` widget sync from `DailyTrackerController` mutations; fire-and-forget the debounced call so the checkbox can paint first.
  - Feed widget XP from the shared gamification snapshot instead of opening new streams.
  - When the user rapidly checks off multiple habits, all updates batch into a single database read and a single platform sync call.

### Non-Blocking Cold Start Pipeline

- **File Reference:** `lib/main.dart`
- **Verdict:** **Overstated** for microtask vs post-frame. **Do it** for work before `runApp`.
- **Root Cause (corrected):** `main()` is `async` and *blocks first frame* on:
  - `tz_data.initializeTimeZones()` (`timezone/data/latest_all.dart` is a large dataset)
  - `FlutterTimezone.getLocalTimezone()`
  - `NotificationService.init()` and `requestPermission()`
- `Future.microtask` for widget consume/sync/reschedule runs after `runApp` and does not block the first paint the way the original write-up claimed. Deferring it to `addPostFrameCallback` is still slightly nicer.
- `rescheduleAll()` cancels up to 10 notification IDs per habit, then reschedules each reminder. That is a burst of platform calls and should stay off the first frame.
- **Implementation:**
  - Call `runApp` first (after `WidgetsFlutterBinding.ensureInitialized()`).
  - Load a smaller timezone database if possible, or initialize timezone after first frame if reminders can wait one frame.
  - Defer permission prompts, `syncAllWidgets()`, and `rescheduleAll()` until after the first frame.
  - Keep `consumePendingWidgetActions()` early enough that home-screen widget taps still apply, but do not block painting.

## Phase 5: UI Layer and Rebuild Scoping

### Granular Riverpod Selectors in Screens

- **File References:** `lib/ui/daily/daily_tracker_screen.dart`, `lib/ui/analytics/habit_analytics_screen.dart`
- **Verdict:** **Do it**
- **Root Cause:** Root `build()` watches `dailyTrackerControllerProvider` directly (`ref.watch(dailyTrackerControllerProvider)`). Any state change (search text, single habit value change, category filter) forces the entire screen, including AppBar, date banner, progress card, chips, and list view, to rebuild completely. `DailyTrackerUiState` has no `==`, so Riverpod always treats updates as new. The habit list is already `ListView.separated` (good).
- **Related cheap win:** `setSearchQuery` / `selectCategory` / `setSortOption` call `_recomputeState()`, which recomputes 365-day streaks. Filter and sort in-memory from the last progress snapshot instead.
- **Implementation:**
  - Extract sub-components (Progress Card, Category Filter Chips, Habit List) into dedicated `ConsumerWidget` classes.
  - Use `select` to bind widgets only to the specific state slice they consume:

```dart
final habits = ref.watch(
  dailyTrackerControllerProvider.select((state) => state.habits),
);
```

### Viewport Virtualization in WeekMatrixGrid

- **File Reference:** `lib/ui/matrix/widgets/week_matrix_grid.dart`
- **Verdict:** **Do it with caveats**
- **Root Cause:** `WeekMatrixGrid` renders all habit rows and 7-day cells inside a single `Column` using `...rows.map(...)`. For users with 15+ habits, over 150 nested layout elements are created in a single build pass without viewport recycling.
- **Caveat:** `HabitWeekMatrixScreen` wraps the grid in `SingleChildScrollView` > `Column`. A nested `ListView.builder` with `shrinkWrap: true` builds every child anyway. Promote the screen to `CustomScrollView` with slivers (stepper, stats, then `SliverList` of rows).
- **Implementation:** Convert matrix screen + `WeekMatrixGrid` row rendering to a sliver-based layout with `const` cell widgets.

### Eliminating StreamBuilder Re-subscriptions in Cards

- **File Reference:** `lib/ui/gamification/widgets/shield_bank_status_card.dart`
- **Verdict:** **Do it**
- **Root Cause:** `StreamBuilder(stream: gamificationRepo.getShieldBankState(), ...)` does not reuse a stream. Each `build()` calls `getShieldBankState()`, which constructs a new broadcast controller and six Drift subscriptions. `ShieldBankBottomSheet` does the same, plus nested StreamBuilders on `getActiveHabits()`, `getAllShields()`, and `getAllLogs()`.
- **Implementation:** Convert `ShieldBankStatusCard` and the bottom sheet to watch a Riverpod provider (`shieldBankStateProvider`) instead of creating inline streams inside `build()`.

## Phase 6: Additional Bottlenecks Found in Code Review

### Check-in Path Does Too Much Before the Next Frame

Toggling a habit awaits repository writes *and* widget sync. The checkbox cannot settle until both finish. Keep the write, update local UI from the existing stream, and move widget sync off the critical path (Phase 4 debounce).

### Search and Sort Recalculate Every Streak

`DailyTrackerController.setSearchQuery` writes search text then calls `_recomputeState()`. Typing should only refilter `List<HabitWithProgress>`. Streaks do not depend on the query.

### Analytics and Matrix Watch Lifetime Logs

`WeekMatrixController` only paints seven days but listens to `getAllLogs()`. Point it at `watchLogsForDateRange(weekStart, weekEnd)`. Analytics heatmap needs the visible month; leaderboard streaks still need a 365-day (or persisted) window.

### Quadratic Day-Log Lookups

Repeated `habitLogs.where((l) => l.date == dateStr)` appears in analytics, daily week strip, gamification perfect-day scoring, wellbeing correlation, and the matrix. Build `logsByHabitDate` once per recompute.

### Habit Detail Opens a Full Gamification Pipeline

`HabitDetailController` already has per-habit logs and shields, then also subscribes to `getShieldBankState()`. That scores every habit. Pass shield bank from the shared provider, or compute availability from persisted counters.

### Duplicate Domain Mapping on Every Emit

`HabitRepositoryImpl` and `GamificationRepositoryImpl` each map every Drift row to domain models on every snapshot. Mapping all historical logs on the UI isolate adds allocation pressure. Prefer mapping in the DAO once, or keep rows until a screen needs domain objects. `GamificationRepositoryImpl._logRowToDomain` also drops `energyLevel` and `mood` (correctness, not just speed).

### Reminder `cancel` Is 10 Platform Calls per Habit

`FlutterHabitReminderScheduler.cancel` always cancels indexes `0..9`. `rescheduleAll` does that for every active habit on launch. Cancel only configured `reminderTimes.length` (or keep a stored ID list).

### Timezone Database Size

`import 'package:timezone/data/latest_all.dart'` loads the full tz database during `main()`. Prefer `latest.dart` or deferred init if reminder accuracy allows.

### Missing Equatable UI State

`DailyTrackerUiState` and several other UI states omit `==` / `hashCode`. Combined with `ref.watch` of the whole object, every coalesced recompute rebuilds the screen even when visible data did not change.

## Implementation Roadmap

Priority is user-visible snappiness, not schema hygiene.

### Sprint 1: Stop Duplicate Work on Every Check-in

- Share one gamification stream/provider; delete per-method `_buildGamificationStream()` factories.
- Debounce `WidgetSyncService.syncAllWidgets()` and stop awaiting it from check-in handlers.
- Coalesce `_recomputeState()` / `evaluateAndEmit()` to one run per event-loop turn.
- Guard achievement upserts so they do not immediately rescore.
- Compute `StreakResult` once per habit per evaluation and reuse it.
- Replace `DateFormat` in streak/gamification hot loops with ISO helpers.

### Sprint 2: Scope Queries and Writes

- Enable WAL + modest cache PRAGMAs.
- Move seeder off `beforeOpen`.
- Wrap check-in mutations in transactions; batch slot inserts; fix shield auto-protect N+1.
- Watch date-ranged logs for matrix (7 days) and daily (365 days), not `watchAllLogs()`.
- Index logs by habit+date in analytics/daily/gamification loops.
- Filter/sort daily habits without recomputing streaks.

### Sprint 3: UI Scoping, Startup, and Virtualization

- Refactor `DailyTrackerScreen` and `HabitAnalyticsScreen` to use granular Riverpod selectors.
- Convert matrix screen to slivers so rows can virtualize.
- Defer timezone-heavy work, notification permission, widget sync, and reminder reschedule until after first frame.
- Convert shield card/sheet to Riverpod.
- `autoDispose` or pause `dailyTrackerControllerProvider` when Daily is not visible.
- Add habits indexes only with a schema migration if touching Drift anyway.
- Benchmark check-in time-to-next-frame and `evaluateAndEmit` duration before/after.

## Suggested Measurement Before Coding

Instrument one check-in with timeline traces around:

- `toggleBooleanCheckIn`
- `DailyTrackerController._recomputeState`
- `GamificationRepositoryImpl.evaluateAndEmit`
- `WidgetSyncService.syncAllWidgets`

That will confirm the duplicated scoring/widget path dominates, rather than SQLite table scans on `Habits`.
