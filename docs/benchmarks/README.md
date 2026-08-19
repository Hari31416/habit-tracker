# Automated Mobile and Hardware Performance Benchmarks

This directory contains empirical performance benchmarks, system memory footprint analyses, and hardware rendering profiles for the habit tracker application.

## Overview

The benchmark suite (`scripts/benchmark_runner.py`) automates end-to-end multi-screen interactions across:
- **Today Tracker:** Horizontal date carousel swiping, habit card scrolling, habit check-in, detail view transitions, and app bar navigation.
- **Week Matrix:** 2D grid panning, vertical scrolling, and individual day cell interactions.
- **Analytics:** 7D/30D/90D time range filtering, interactive completion rate charts, and frequency heatmaps.
- **Mastery:** Gamification level showcases, badge detail inspection modals, and scrim dismissals.
- **Multi-Tab Switching:** Rapid tab cycling across all primary navigation destinations to measure GPU texture stability and memory retention.

## Side-by-Side Comparison: Physical Hardware vs. Emulator


Measurements recorded across 1,600+ frames during automated stress sessions:

| Benchmark Metric                | Moto G60 Physical Device (`moto_g60`)       | Android Emulator (`emulator`)                | Notes                                            |
| :------------------------------ | :------------------------------------------ | :------------------------------------------- | :----------------------------------------------- |
| **Target Device**               | Motorola Moto G60 (`Android 12`, 1080x2460) | sdk_gphone64_arm64 (`Android 16`, 1080x2400) | Snapdragon 732G vs Virtualized AVD               |
| **Total System RAM (PSS)**      | 216.2 MB baseline / 216.3 MB resting        | 142.8 MB baseline / 142.1 MB resting         | Full OEM display driver stack on hardware        |
| **Resting Memory Delta**        | +0.1 MB (Stable)                            | -0.7 MB (Stable)                             | Completely flat baseline across 5 phases         |
| **Dart VM Heap**                | 19.8 MB - 20.0 MB                           | 20.6 MB                                      | Efficient Drift streams and Riverpod scoping     |
| **Active Render Rate**          | 102.7 FPS                                   | 120.0 FPS                                    | Smooth motion utilizing 120Hz display            |
| **Frame Smoothness / Fluidity** | 96.6% Smooth (3.4% Jank)                    | 86.7% Smooth (13.3% Jank)                    | Hardware acceleration outpaces emulator bridge   |
| **UI Thread Build Time (Avg)**  | 1.5 ms (95th: 3.4 ms)                       | 0.4 ms (95th: 1.1 ms)                        | Granular `.select(...)` isolates widget rebuilds |
| **Raster GPU Time (Avg)**       | 6.4 ms (95th: 9.4 ms)                       | 4.0 ms (95th: 16.9 ms)                       | Well within 8.3 ms frame budget for 120Hz        |
| **Average CPU Utilization**     | 12.1% (single-core equivalent)              | 12.6% (virtual core)                         | Negligible battery footprint                     |

## Tracked Device Reports

Detailed performance dossiers and visual plots for each tested platform:

### 1. Motorola Moto G60 (Physical Hardware)
- Report: [benchmark_report_moto_g60.md](benchmark_report_moto_g60.md)
- CPU & Memory Timeline: `timeline_cpu_memory_moto_g60.png`
- Frame Timing Distribution: `frame_timings_distribution_moto_g60.png`
- Top Dart Heap Allocations: `top_dart_allocations_moto_g60.png`

### 2. Android Emulator (AVD)
- Report: [benchmark_report_emulator.md](benchmark_report_emulator.md)
- CPU & Memory Timeline: `timeline_cpu_memory_emulator.png`
- Frame Timing Distribution: `frame_timings_distribution_emulator.png`
- Top Dart Heap Allocations: `top_dart_allocations_emulator.png`

## How to Execute Automated Benchmarks

### Prerequisites

1. Connect target Android device via USB (or launch the Android emulator).
2. Start the application in profile mode on the device:

```bash
# On physical device
flutter run --profile -d <DEVICE_ID>

# On emulator
make profile
```

### Running the Suite

In a separate terminal window, execute:

```bash
# Run benchmark on physical phone with custom tag
make benchmark TAG=moto_g60

# Run benchmark on emulator with custom tag
make benchmark TAG=emulator DEVICE=emulator-5554

# Or run directly via uv
uv run scripts/benchmark_runner.py --tag pixel8 --device <SERIAL>
```

### Exporting PDF Reports

To compile any markdown benchmark report into a PDF document:

```bash
md2pdf docs/benchmarks/benchmark_report_moto_g60.md --theme academic
```

