# Performance Benchmark Results

This document tracks empirical before-and-after benchmark measurements across all optimization phases in the habit tracker application.

## Overview

Benchmarks are executed using automated test suites located in `test/benchmark/` to measure execution time, memory allocation patterns, and throughput improvements under simulated and real-world workloads.

## Phase 1: Database and Persistence Layer

### Phase 1 Results Summary

| Scenario / Operation                                                                            | Before Optimization | After Phase 1 Optimization | Speedup | Notes                                                                                 |
| :---------------------------------------------------------------------------------------------- | :------------------ | :------------------------- | :------ | :------------------------------------------------------------------------------------ |
| **Week Matrix & Log Queries**<br>*(100 queries on 2,000 log dataset)*                           | 429.38 ms           | 19.07 ms                   | 22.51x  | Scoped 7-day range index query vs. deserializing full lifetime table history.         |
| **Auto-Protect Rollover (`autoProtectMissedDays`)**<br>*(15 active habits with 20-day streaks)* | 73.53 ms            | 7.70 ms                    | 9.55x   | Eliminated N+1 database round-trips & repeated O(N) streak passes per applied shield. |
| **Batch Shield Insertion**<br>*(20 shields)*                                                    | 1.19 ms             | 0.34 ms                    | 3.50x   | `insertShields` batch statement vs. individual `upsertShield` loop round-trips.       |
| **Multi-Slot Check-In**<br>*(50 check-ins x 8 slots = 400 rows)*                                | 46.65 ms            | 39.23 ms                   | 1.19x   | Single transaction + batch `insertLogs` vs. un-batched sequential upserts.            |

### Phase 1 Detailed Breakdown

- **Week Matrix & Date Range Queries:** Scoped `getLogsForDateRangeOnce` and `getShieldsForDateRange` to the visible Monday–Sunday week. Achieved ~22.5x query speedup with significant reduction in memory allocation.
- **Midnight Auto-Protection:** Replaced loop queries and multiple bank state calculations with a single bank calculation, in-memory state tracking, and batch shield insertion (`insertShields`). Reduced background rollover CPU time by ~90%.
- **Batch Shield Insertion:** Grouped multiple shield records into SQLite batch statements via `insertShields`, yielding a ~3.5x speedup per batch write.
- **Multi-Slot Check-Ins:** Grouped multi-statement check-in mutations within an enclosing transaction and used batch `insertLogs` for multi-slot habit completion.

### Phase 1 Benchmark Suite

Run the Phase 1 benchmark suite with:

```bash
flutter test test/benchmark/phase1_benchmark_test.dart
```

## Phase 2: Reactive Data Flow and Gamification Architecture

### Phase 2 Results Summary

| Scenario / Operation                                                      | Before Optimization | After Phase 2 Optimization | Speedup / Reduction   | Notes                                                                                                 |
| :------------------------------------------------------------------------ | :------------------ | :------------------------- | :-------------------- | :---------------------------------------------------------------------------------------------------- |
| **Gamification Streak Passes**<br>*(50 runs on 20 habits x 60 days)*      | 605.92 ms           | 174.30 ms                  | 3.48x                 | Single-pass precomputed streak map reused across XP multipliers, achievements, and shield banking.    |
| **Multi-Table Stream Coalescing**<br>*(500 bursts of 4 table emissions)*  | 2,000 evaluations   | 500 evaluations            | 4.00x (75% fewer)     | Microtask coalescing ensures rapid consecutive emissions trigger one calculation per event loop turn. |
| **Shared Stream Pipeline**<br>*(25 write cycles with 4 active listeners)* | 24 DAO streams      | 6 shared DAO streams       | 4.00x fewer listeners | 8.08 ms average write cycle under full 4-listener subscription load.                                  |

### Phase 2 Detailed Breakdown

- **Single-Pass Streaks:** Eliminated 4 redundant full-history streak calculation passes in `GamificationRepositoryImpl.evaluateAndEmit()`. Streaks are now computed once per habit and reused in XP multipliers, `AchievementEvaluator`, and `ShieldBankingEngine`.
- **Stream Event Coalescing:** Multi-stream database emissions during app startup or multi-table updates are coalesced via `scheduleMicrotask`, reducing redundant calculations by 75%.
- **Stream Consolidation:** Replaced per-method stream creation with a single shared broadcast pipeline (`_getCombinedStream()`), cutting concurrent Drift listeners and eliminating redundant evaluations.
- **Feedback Loop Elimination:** Guarded achievement persistence to skip re-evaluations when unlocked achievement IDs and progress remain unchanged.

### Phase 2 Benchmark Suite

Run the Phase 2 benchmark suite with:

```bash
flutter test test/benchmark/phase2_benchmark_test.dart
```

## Phase 3: Algorithmic and Computation Optimizations

### Phase 3 Results Summary

| Scenario / Operation                                                                   | Before Optimization | After Phase 3 Optimization | Speedup | Notes                                                                                       |
| :------------------------------------------------------------------------------------- | :------------------ | :------------------------- | :------ | :------------------------------------------------------------------------------------------ |
| **Fast ISO Date Formatting**<br>*(10,000 dates)*                                       | 9.98 ms             | 3.63 ms                    | 2.75x   | Integer padded ISO string generation vs. repeated `DateFormat.format()` invocations.        |
| **Log Lookup in Analytics/Engines**<br>*(30 runs x 60 days x 20 habits on 4,866 logs)* | 54.97 ms            | 23.24 ms                   | 2.37x   | Pre-indexed `Map<String, Map<String, List<HabitLog>>>` vs. quadratic linear `.where` scans. |
| **Wellbeing & Achievement Pipeline**<br>*(50 runs on 15 habits x 90 days)*             | N/A                 | 2.36 ms / run              | Optimal | End-to-end evaluation throughput with indexed log lookups and fast ISO date formatting.     |

### Phase 3 Detailed Breakdown

- **Fast ISO Date Formatting:** Introduced `StreakCalculator.formatIsoDate` replacing heavy `DateFormat.format()` calls across streak engines, analytics loops, matrix calculations, and daily tracker updates.
- **Lexicographical Date Operations:** Eliminated unnecessary `DateFormat.parse()` round-trips for date sorting in `AchievementEvaluator` and `GamificationRepositoryImpl` by sorting ISO-8601 strings directly.
- **Indexed Log Lookups:** Pre-indexed logs by habit ID and date across `AnalyticsController`, `AchievementEvaluator`, `WellbeingCorrelationEngine`, `DailyTrackerController`, and `WeekMatrixController`, replacing repeated O(N) linear scans with O(1) map lookups.

### Phase 3 Benchmark Suite

Run the Phase 3 benchmark suite with:

```bash
flutter test test/benchmark/phase3_benchmark_test.dart
```

## Phase 4: Platform Channels and Startup Pipeline

### Phase 4 Results Summary

| Scenario / Operation                                                 | Before Optimization                                   | After Phase 4 Optimization | Speedup / Reduction          | Notes                                                                                  |
| :------------------------------------------------------------------- | :---------------------------------------------------- | :------------------------- | :--------------------------- | :------------------------------------------------------------------------------------- |
| **Burst Check-In Widget Sync UI Dispatch**<br>*(50 rapid check-ins)* | 119.67 ms (blocking UI)                               | 0.67 ms (unblocked UI)     | 178.07x UI latency speedup   | Check-in mutations fire unawaited debounced widget sync so checkboxes paint instantly. |
| **Widget Sync Channel Coalescing**<br>*(50 rapid check-ins burst)*   | 50 full sync passes                                   | 1 coalesced pass           | 50x fewer IPC & DB passes    | 500ms debounce timer merges bursts into a single snapshot generation pass.             |
| **Timezone Database Initialization**                                 | `latest_all.dart` (large full historical tz database) | `latest.dart` (~18.36 ms)  | Non-blocking background init | Moved off first-frame critical path before `runApp()`.                                 |

### Phase 4 Detailed Breakdown

- **Debounced Widget Synchronization:** Replaced immediate blocking widget synchronization on every habit check-in mutation with a 500ms debounce timer in `WidgetSyncService`. Bursts of check-ins now coalesce into a single pass.
- **Unblocked Check-In UI Path:** Removed `await` on widget synchronization across all check-in, shield, numeric, slot, pin, and quick-add mutations in `DailyTrackerController`. The UI repaints immediately without waiting for JSON serialization or MethodChannel IPC.
- **Non-Blocking Cold Start Pipeline:** Streamlined `main.dart` by switching to `timezone/data/latest.dart` and moving timezone setup, notification initialization, permission checks, initial widget sync, and reminder scheduling to execute asynchronously in the background after first frame rendering.

### Phase 4 Benchmark Suite

Run the Phase 4 benchmark suite with:

```bash
flutter test test/benchmark/phase4_benchmark_test.dart
```

## Phase 5: UI Layer and Rebuild Scoping

### Phase 5 Results Summary

| Scenario / Operation                                                                  | Before Optimization                                     | After Phase 5 Optimization | Speedup / Efficiency | Notes                                                                               |
| :------------------------------------------------------------------------------------ | :------------------------------------------------------ | :------------------------- | :------------------- | :---------------------------------------------------------------------------------- |
| **Search & Filtering with History**<br>*(50 keystrokes across 30 habits x 365 days)*  | 267.42 ms                                               | 0.80 ms                    | 334.27x              | Instant in-memory filtering on cached state vs. full 365-day streak recalculations. |
| **UI State Equality Evaluation**<br>*(5,000 state checks)*                            | Full widget subtree rebuilds on all state notifications | 0.634 µs / check           | 100% scoped rebuilds | Riverpod skips rebuilding widgets when selected sub-state is unchanged.             |
| **Category Filtering & Sorting Throughput**<br>*(500 filter operations on 30 habits)* | Recalculates full habit tree                            | 0.003 ms / filter          | Instantaneous        | Sub-millisecond category switching and pinned-first sorting.                        |
| **Week Matrix & Analytics Virtualization**                                            | Monolithic unvirtualized single column layout           | CustomScrollView & Slivers | Viewport-bounded     | Slivers and dedicated modular cell widgets eliminate offscreen rendering overhead.  |

### Phase 5 Detailed Breakdown

- **In-Memory Search & Category Filtering:** Cached `_unfilteredHabitsWithProgress` on the selected date in `DailyTrackerController`. Searching, category selection, sorting, and archive toggling now filter and sort in-memory directly without triggering 365-day streak recalculations.
- **Granular Riverpod Selectors (`.select(...)`):** Decomposed `DailyTrackerScreen`, `HabitAnalyticsScreen`, and `HabitWeekMatrixScreen` from monolithic root watchers into granular `ConsumerWidget` subcomponents. Each widget only listens to the exact state properties it renders.
- **UI State & Model Equality:** Implemented `operator ==` and `hashCode` across `DailyTrackerUiState`, `AnalyticsUiState`, `HabitWithProgress`, and `WellbeingSummary` to ensure state updates only notify widgets whose bound properties changed.
- **Matrix Viewport Virtualization:** Converted `HabitWeekMatrixScreen` to `CustomScrollView` with slivers and extracted `WeekMatrixGrid` into lightweight `_MatrixRowWidget` and `_MatrixCellWidget` components.
- **Shield Bank Stream Consolidation:** Replaced nested `StreamBuilder` widgets in `ShieldBankBottomSheet` with Riverpod auto-disposing stream providers (`activeHabitsStreamProvider`, `allShieldsStreamProvider`, `allLogsStreamProvider`), eliminating repeated SQLite stream subscriptions on every modal rebuild.

### Phase 5 Benchmark Suite

Run the Phase 5 benchmark suite with:

```bash
flutter test test/benchmark/phase5_benchmark_test.dart
```

