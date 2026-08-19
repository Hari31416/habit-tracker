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

Phase 2 benchmarks will measure the consolidation of gamification streams, elimination of redundant listeners, single-pass streak caching, and debounced controller state recomputations.

*Status: Scheduled*

## Phase 3: Algorithmic and Computation Optimizations

Phase 3 benchmarks will evaluate fast ISO date string formatting, lexicographical date comparisons, indexed log lookups (replacing quadratic `where` scans), and analytics pipeline memoization.

*Status: Scheduled*

## Phase 4: Platform Channels and Startup Pipeline

Phase 4 benchmarks will measure widget sync MethodChannel debounce latency, asynchronous notification scheduling, and cold start time-to-first-frame.

*Status: Scheduled*

## Phase 5: UI Layer and Rebuild Scoping

Phase 5 benchmarks will evaluate granular Riverpod selector scoping, viewport virtualization in week matrix grids, and UI frame build times during search and check-in interactions.

*Status: Scheduled*
