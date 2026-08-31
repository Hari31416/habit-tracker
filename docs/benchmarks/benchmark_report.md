# Automated Performance and Footprint Benchmark Report

- **Generated At:** 2026-08-31 14:55:48
- **Application Package:** `app.phial.habits`
- **Target Device:** `sdk_gphone64_arm64` (`Android 16`, `1080x2400`, Serial: `emulator-5554`)
- **Report Identifier / Tag:** `emulator`
- **Interaction Driver:** Maestro (`benchmark_suite.yaml`)

## Executive Summary

| Metric | Baseline | Peak | Resting | Delta (Post-GC) | Health Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Total System RAM (PSS)** | 167.8 MB | 186.8 MB | 166.8 MB | -1.0 MB | **STABLE** |
| **Native Heap (Impeller/C++)** | 37.9 MB | - | 31.5 MB | -6.4 MB | **OPTIMAL** |
| **Dart VM Heap** | 21.9 MB | - | 21.0 MB | -0.9 MB | **OPTIMAL** |

## CPU Utilization

- **Average Active CPU:** 14.2%
- **Peak CPU Spike:** 20.0%

## Frame Rate and Rendering Performance

| Rendering Metric | Measurement | Target / Budget | Status |
| :--- | :--- | :--- | :--- |
| **Total Frames Rendered** | 1,008 | - | COMPLETED |
| **Active Motion Render Rate** | **99.7 FPS** | 60.0 / 120.0 FPS | **OPTIMAL** |
| **Frame Smoothness / Fluidity** | **91.7%** | > 95.0% | **WARN** |
| **Janky Frames (>16.6ms)** | 84 (8.3%) | < 5.0% | **WARN** |
| **UI Thread Build Time (Avg)** | 1.1 ms (95th: 2.2ms) | < 8.0 ms | **OPTIMAL** |
| **Raster GPU Time (Avg)** | 5.3 ms (95th: 22.9ms) | < 8.0 ms | **OPTIMAL** |
| **Total Frame Time (Avg)** | 10.0 ms (99th: 155.3ms) | < 16.6 ms | **OPTIMAL** |

![Frame Timing Distribution](frame_timings_distribution_emulator.png)

## Performance Timeline

![Memory and CPU Timeline](timeline_cpu_memory_emulator.png)

## Dart Heap Class Allocations

| Class Name | Active Instances | Memory Allocated (KB) |
| :--- | :--- | :--- |
| `InstructionsSection` | 1 | 5587.2 KB |
| `Code` | 24,507 | 3829.2 KB |
| `_OneByteString` | 36,899 | 2535.6 KB |
| `CodeSourceMap` | 18,975 | 2206.4 KB |
| `_List` | 34,581 | 2136.1 KB |
| `Function` | 24,101 | 1506.3 KB |
| `_GrowableList` | 25,566 | 798.9 KB |
| `Field` | 11,232 | 702.0 KB |
| `Class` | 5,131 | 561.2 KB |
| `_Mint` | 24,985 | 390.4 KB |
| `_Closure` | 7,710 | 361.4 KB |
| `_RenderObjectSemantics` | 4,165 | 325.4 KB |

![Top Dart Allocations](top_dart_allocations_emulator.png)
