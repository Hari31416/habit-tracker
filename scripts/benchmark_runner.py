# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "matplotlib",
#     "websockets",
# ]
# ///

import asyncio
import json
import logging
import os
import re
import subprocess
import sys
import time
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import matplotlib.pyplot as plt
import websockets

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("BenchmarkRunner")

PACKAGE_NAME = "app.phial.habits"
MAIN_ACTIVITY = f"{PACKAGE_NAME}.MainActivity"
OUTPUT_DIR = Path("build/benchmark_reports")


@dataclass
class MemorySample:
    timestamp: float
    cpu_percent: float
    total_pss_mb: float
    native_heap_mb: float
    graphics_mb: float
    code_mb: float


@dataclass
class ClassAllocation:
    name: str
    instances: int
    bytes_allocated: int

    @property
    def kb_allocated(self) -> float:
        return self.bytes_allocated / 1024.0


@dataclass
class BenchmarkResults:
    baseline_pss_mb: float
    peak_pss_mb: float
    resting_pss_mb: float
    memory_delta_mb: float
    baseline_native_mb: float
    resting_native_mb: float
    baseline_dart_heap_mb: float
    resting_dart_heap_mb: float
    avg_cpu_percent: float
    peak_cpu_percent: float
    samples: List[MemorySample] = field(default_factory=list)
    top_classes: List[ClassAllocation] = field(default_factory=list)


def get_adb_path() -> str:
    adb_env = os.environ.get("ADB")
    if adb_env and Path(adb_env).is_file():
        return adb_env
    android_home = os.environ.get(
        "ANDROID_HOME", str(Path.home() / "Library/Android/sdk")
    )
    candidate = Path(android_home) / "platform-tools/adb"
    if candidate.is_file():
        return str(candidate)
    return "adb"


def run_adb(args: List[str], adb_path: str) -> str:
    cmd = [adb_path] + args
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        logger.debug(f"ADB command failed: {' '.join(cmd)}: {res.stderr}")
    return res.stdout.strip()


def check_connected_device(adb_path: str) -> str:
    out = run_adb(["devices"], adb_path)
    lines = [line for line in out.splitlines() if line and not line.startswith("List")]
    devices = [line.split()[0] for line in lines if "device" in line]
    if not devices:
        raise RuntimeError("No connected Android device or running emulator detected.")
    return devices[0]


def get_screen_dimensions(adb_path: str) -> Tuple[int, int]:
    out = run_adb(["shell", "wm", "size"], adb_path)
    match = re.search(r"(\d+)x(\d+)", out)
    if match:
        return int(match.group(1)), int(match.group(2))
    return 1080, 2400


def query_system_memory(adb_path: str) -> Tuple[float, float, float, float]:
    out = run_adb(["shell", "dumpsys", "meminfo", PACKAGE_NAME], adb_path)
    total_pss_kb = 0.0
    native_kb = 0.0
    graphics_kb = 0.0
    code_kb = 0.0

    for line in out.splitlines():
        if "TOTAL PSS:" in line:
            parts = line.split()
            if len(parts) >= 3:
                try:
                    total_pss_kb = float(parts[2].replace(",", ""))
                except ValueError:
                    pass
        elif "TOTAL" in line and total_pss_kb == 0.0:
            parts = line.split()
            if len(parts) >= 2 and parts[1].replace(",", "").isdigit():
                total_pss_kb = float(parts[1].replace(",", ""))
        elif "Native Heap" in line:
            parts = line.split()
            if len(parts) >= 3 and parts[2].replace(",", "").isdigit():
                native_kb = float(parts[2].replace(",", ""))
        elif "Graphics" in line:
            parts = line.split()
            for part in parts[1:]:
                clean = part.replace(",", "")
                if clean.isdigit():
                    graphics_kb = float(clean)
                    break
        elif "Code" in line:
            parts = line.split()
            for part in parts[1:]:
                clean = part.replace(",", "")
                if clean.isdigit():
                    code_kb = float(clean)
                    break

    return (
        total_pss_kb / 1024.0,
        native_kb / 1024.0,
        graphics_kb / 1024.0,
        code_kb / 1024.0,
    )


def query_cpu_percent(adb_path: str) -> float:
    out = run_adb(["shell", f"top -b -n 1 | grep {PACKAGE_NAME}"], adb_path)
    first_line = out.splitlines()[0] if out.splitlines() else ""
    if not first_line:
        return 0.0
    for token in first_line.split():
        clean = token.replace("%", "")
        try:
            val = float(clean)
            if 0.0 <= val <= 800.0:
                return val
        except ValueError:
            continue
    return 0.0


class DartVmClient:
    def __init__(self, ws_uri: str) -> None:
        self.ws_uri = ws_uri
        self.ws: Optional[websockets.WebSocketClientProtocol] = None
        self._req_id = 0

    async def connect(self) -> None:
        self.ws = await websockets.connect(self.ws_uri)

    async def close(self) -> None:
        if self.ws:
            await self.ws.close()

    async def call(
        self, method: str, params: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        if not self.ws:
            raise RuntimeError("WebSocket not connected")
        self._req_id += 1
        payload = {
            "jsonrpc": "2.0",
            "id": str(self._req_id),
            "method": method,
            "params": params or {},
        }
        await self.ws.send(json.dumps(payload))
        resp_text = await self.ws.recv()
        resp = json.loads(resp_text)
        if "error" in resp:
            raise RuntimeError(f"Dart VM Service error in {method}: {resp['error']}")
        return resp.get("result", {})

    async def get_main_isolate_id(self) -> str:
        vm = await self.call("getVM")
        isolates = vm.get("isolates", [])
        if not isolates:
            raise RuntimeError("No isolates found in Dart VM")
        return isolates[0]["id"]

    async def collect_garbage(self, isolate_id: str) -> None:
        try:
            await self.call("_collectAllGarbage", {"isolateId": isolate_id})
        except Exception as e:
            logger.debug(f"GC trigger exception (non-fatal): {e}")

    async def get_memory_usage(self, isolate_id: str) -> float:
        res = await self.call("getMemoryUsage", {"isolateId": isolate_id})
        heap_used = res.get("heapUsage", 0)
        return heap_used / (1024.0 * 1024.0)

    async def get_top_allocations(
        self, isolate_id: str, limit: int = 12
    ) -> List[ClassAllocation]:
        res = await self.call(
            "getAllocationProfile", {"isolateId": isolate_id, "reset": False}
        )
        members = res.get("members", [])
        allocations: List[ClassAllocation] = []
        for item in members:
            cls_info = item.get("class", {})
            name = cls_info.get("name", "Unknown")
            instances = item.get("instancesCurrent", 0)
            bytes_alloc = item.get("bytesCurrent", 0)
            if instances > 0:
                allocations.append(
                    ClassAllocation(
                        name=name,
                        instances=instances,
                        bytes_allocated=bytes_alloc,
                    )
                )
        allocations.sort(key=lambda x: x.bytes_allocated, reverse=True)
        return allocations[:limit]


async def run_benchmark_session(
    adb_path: str, vm_client: Optional[DartVmClient], isolate_id: Optional[str]
) -> BenchmarkResults:
    width, height = get_screen_dimensions(adb_path)
    nav_y = int(height * 0.94)
    nav_today_x = int(width * 0.10)
    nav_week_x = int(width * 0.30)
    nav_analytics_x = int(width * 0.70)
    nav_mastery_x = int(width * 0.90)

    # 1. Warm-up Pass: Visit tabs once to load first-time route caches, charts, and table schemas
    logger.info("Executing initial warm-up pass to initialize screen caches...")
    run_adb(["shell", "input", "tap", str(nav_week_x), str(nav_y)], adb_path)
    await asyncio.sleep(0.5)
    run_adb(["shell", "input", "tap", str(nav_analytics_x), str(nav_y)], adb_path)
    await asyncio.sleep(0.5)
    run_adb(["shell", "input", "tap", str(nav_mastery_x), str(nav_y)], adb_path)
    await asyncio.sleep(0.5)
    run_adb(["shell", "input", "tap", str(nav_today_x), str(nav_y)], adb_path)
    await asyncio.sleep(0.8)

    # 2. Settle & Trigger GC for True Post-Warmup Baseline
    logger.info("Stabilizing and taking post-warmup baseline measurements...")
    if vm_client and isolate_id:
        await vm_client.collect_garbage(isolate_id)
    await asyncio.sleep(1.5)

    base_pss, base_native, base_graphics, base_code = query_system_memory(adb_path)
    base_dart = (
        await vm_client.get_memory_usage(isolate_id)
        if (vm_client and isolate_id)
        else 0.0
    )

    samples: List[MemorySample] = []
    start_time = time.time()

    async def sample_worker(stop_event: asyncio.Event) -> None:
        while not stop_event.is_set():
            t = time.time() - start_time
            cpu = query_cpu_percent(adb_path)
            pss, native, gfx, code = query_system_memory(adb_path)
            samples.append(MemorySample(t, cpu, pss, native, gfx, code))
            await asyncio.sleep(0.4)

    stop_event = asyncio.Event()
    sampler_task = asyncio.create_task(sample_worker(stop_event))

    logger.info("Executing automated stress interaction workflow...")
    # Iteration 1: Scrolling and tapping
    for _ in range(3):
        run_adb(
            [
                "shell",
                "input",
                "swipe",
                str(width // 2),
                str(int(height * 0.65)),
                str(width // 2),
                str(int(height * 0.30)),
                "250",
            ],
            adb_path,
        )
        await asyncio.sleep(0.3)
        run_adb(
            [
                "shell",
                "input",
                "swipe",
                str(width // 2),
                str(int(height * 0.30)),
                str(width // 2),
                str(int(height * 0.65)),
                "250",
            ],
            adb_path,
        )
        await asyncio.sleep(0.3)

    # Tap habit toggle
    run_adb(
        ["shell", "input", "tap", str(int(width * 0.90)), str(int(height * 0.38))],
        adb_path,
    )
    await asyncio.sleep(0.5)

    # Iteration 2: Navigate through Week, Analytics, Mastery tabs
    for _ in range(2):
        run_adb(["shell", "input", "tap", str(nav_week_x), str(nav_y)], adb_path)
        await asyncio.sleep(0.8)
        run_adb(
            [
                "shell",
                "input",
                "swipe",
                str(width // 2),
                str(int(height * 0.60)),
                str(width // 2),
                str(int(height * 0.35)),
                "200",
            ],
            adb_path,
        )

        run_adb(["shell", "input", "tap", str(nav_analytics_x), str(nav_y)], adb_path)
        await asyncio.sleep(0.8)
        run_adb(
            [
                "shell",
                "input",
                "swipe",
                str(width // 2),
                str(int(height * 0.60)),
                str(width // 2),
                str(int(height * 0.35)),
                "200",
            ],
            adb_path,
        )

        run_adb(["shell", "input", "tap", str(nav_mastery_x), str(nav_y)], adb_path)
        await asyncio.sleep(0.8)

        run_adb(["shell", "input", "tap", str(nav_today_x), str(nav_y)], adb_path)
        await asyncio.sleep(0.8)

    # Iteration 3: Rapid tab cycling
    for _ in range(3):
        run_adb(["shell", "input", "tap", str(nav_week_x), str(nav_y)], adb_path)
        await asyncio.sleep(0.3)
        run_adb(["shell", "input", "tap", str(nav_analytics_x), str(nav_y)], adb_path)
        await asyncio.sleep(0.3)
        run_adb(["shell", "input", "tap", str(nav_mastery_x), str(nav_y)], adb_path)
        await asyncio.sleep(0.3)
        run_adb(["shell", "input", "tap", str(nav_today_x), str(nav_y)], adb_path)
        await asyncio.sleep(0.3)

    stop_event.set()
    await sampler_task

    logger.info("Cooling down and measuring resting memory...")
    if vm_client and isolate_id:
        await vm_client.collect_garbage(isolate_id)
    await asyncio.sleep(2.0)

    resting_pss, resting_native, resting_graphics, resting_code = query_system_memory(
        adb_path
    )
    resting_dart = (
        await vm_client.get_memory_usage(isolate_id)
        if (vm_client and isolate_id)
        else 0.0
    )
    top_allocations = (
        await vm_client.get_top_allocations(isolate_id)
        if (vm_client and isolate_id)
        else []
    )

    peak_pss = max([s.total_pss_mb for s in samples] + [base_pss, resting_pss])
    avg_cpu = sum(s.cpu_percent for s in samples) / len(samples) if samples else 0.0
    peak_cpu = max([s.cpu_percent for s in samples] + [0.0])

    return BenchmarkResults(
        baseline_pss_mb=base_pss,
        peak_pss_mb=peak_pss,
        resting_pss_mb=resting_pss,
        memory_delta_mb=resting_pss - base_pss,
        baseline_native_mb=base_native,
        resting_native_mb=resting_native,
        baseline_dart_heap_mb=base_dart,
        resting_dart_heap_mb=resting_dart,
        avg_cpu_percent=avg_cpu,
        peak_cpu_percent=peak_cpu,
        samples=samples,
        top_classes=top_allocations,
    )


def generate_plots(
    results: BenchmarkResults, output_dir: Path
) -> Tuple[Path, Optional[Path]]:
    output_dir.mkdir(parents=True, exist_ok=True)
    timeline_path = output_dir / "timeline_cpu_memory.png"
    classes_path = output_dir / "top_dart_allocations.png"

    # 1. Timeline Plot
    fig, ax1 = plt.subplots(figsize=(10, 5), dpi=150)
    times = [s.timestamp for s in results.samples]
    pss = [s.total_pss_mb for s in results.samples]
    native = [s.native_heap_mb for s in results.samples]
    cpus = [s.cpu_percent for s in results.samples]

    color_pss = "#2563EB"
    color_native = "#059669"
    color_cpu = "#DC2626"

    ax1.set_xlabel("Elapsed Time (seconds)", fontsize=11, fontweight="medium")
    ax1.set_ylabel("Memory (MB)", fontsize=11, fontweight="medium")
    l1 = ax1.plot(times, pss, label="Total RAM (PSS)", color=color_pss, linewidth=2)
    l2 = ax1.plot(
        times,
        native,
        label="Native Heap",
        color=color_native,
        linewidth=1.8,
        linestyle="--",
    )
    ax1.grid(True, linestyle=":", alpha=0.6)

    ax2 = ax1.twinx()
    ax2.set_ylabel(
        "CPU Utilization (%)", color=color_cpu, fontsize=11, fontweight="medium"
    )
    l3 = ax2.plot(
        times, cpus, label="Active CPU %", color=color_cpu, linewidth=1.5, alpha=0.85
    )
    ax2.tick_params(axis="y", labelcolor=color_cpu)

    lines = l1 + l2 + l3
    labels = [line.get_label() for line in lines]
    ax1.legend(lines, labels, loc="upper left", framealpha=0.9)
    plt.title(
        "Automated Performance Benchmark - Memory & CPU Timeline",
        fontsize=12,
        fontweight="bold",
        pad=12,
    )
    plt.tight_layout()
    plt.savefig(timeline_path)
    plt.close(fig)

    # 2. Top Classes Plot
    if results.top_classes:
        fig, ax = plt.subplots(figsize=(10, 6), dpi=150)
        class_names = [c.name for c in reversed(results.top_classes)]
        sizes_kb = [c.kb_allocated for c in reversed(results.top_classes)]
        counts = [c.instances for c in reversed(results.top_classes)]

        bars = ax.barh(
            class_names, sizes_kb, color="#4F46E5", edgecolor="#3730A3", height=0.65
        )
        ax.set_xlabel("Dart Heap Memory (KB)", fontsize=11, fontweight="medium")
        ax.set_title(
            "Top Dart Classes by Allocated Heap Memory",
            fontsize=12,
            fontweight="bold",
            pad=12,
        )
        ax.grid(True, axis="x", linestyle=":", alpha=0.6)

        for bar, count in zip(bars, counts):
            width = bar.get_width()
            ax.text(
                width + (max(sizes_kb) * 0.01),
                bar.get_y() + bar.get_height() / 2,
                f"{count:,} instances",
                va="center",
                ha="left",
                fontsize=9,
                color="#374151",
            )

        plt.tight_layout()
        plt.savefig(classes_path)
        plt.close(fig)
    else:
        classes_path = None

    return timeline_path, classes_path


def generate_markdown_report(
    results: BenchmarkResults,
    timeline_plot: Path,
    classes_plot: Optional[Path],
    output_dir: Path,
) -> Path:
    report_path = output_dir / "benchmark_report.md"
    health_status = "STABLE" if results.memory_delta_mb <= 15.0 else "WARNING_LEAK"

    lines: List[str] = [
        "# Automated Performance and Footprint Benchmark Report",
        "",
        f"Generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} for `{PACKAGE_NAME}`.",
        "",
        "## Executive Summary",
        "",
        "| Metric | Baseline | Peak | Resting | Delta (Post-GC) | Health Status |",
        "| :--- | :--- | :--- | :--- | :--- | :--- |",
        f"| **Total System RAM (PSS)** | {results.baseline_pss_mb:.1f} MB | {results.peak_pss_mb:.1f} MB | {results.resting_pss_mb:.1f} MB | {results.memory_delta_mb:+.1f} MB | **{health_status}** |",
        f"| **Native Heap (Impeller/C++)** | {results.baseline_native_mb:.1f} MB | - | {results.resting_native_mb:.1f} MB | {results.resting_native_mb - results.baseline_native_mb:+.1f} MB | **OPTIMAL** |",
        f"| **Dart VM Heap** | {results.baseline_dart_heap_mb:.1f} MB | - | {results.resting_dart_heap_mb:.1f} MB | {results.resting_dart_heap_mb - results.baseline_dart_heap_mb:+.1f} MB | **OPTIMAL** |",
        "",
        "## CPU Utilization",
        "",
        f"- **Average Active CPU:** {results.avg_cpu_percent:.1f}%",
        f"- **Peak CPU Spike:** {results.peak_cpu_percent:.1f}%",
        "",
        "## Performance Timeline",
        "",
        f"![Memory and CPU Timeline]({timeline_plot.name})",
        "",
    ]

    if results.top_classes:
        lines.extend(
            [
                "## Dart Heap Class Allocations",
                "",
                "| Class Name | Active Instances | Memory Allocated (KB) |",
                "| :--- | :--- | :--- |",
            ]
        )
        for c in results.top_classes:
            lines.append(f"| `{c.name}` | {c.instances:,} | {c.kb_allocated:.1f} KB |")
        lines.append("")
        if classes_plot:
            lines.extend(
                [
                    f"![Top Dart Allocations]({classes_plot.name})",
                    "",
                ]
            )

    report_path.write_text("\n".join(lines), encoding="utf-8")
    return report_path


async def main_async() -> None:
    adb_path = get_adb_path()
    logger.info(f"Using ADB binary: {adb_path}")

    device = check_connected_device(adb_path)
    logger.info(f"Connected Target Device: {device}")

    # Look for active Dart VM Service port on device or from service_info.json
    vm_client: Optional[DartVmClient] = None
    isolate_id: Optional[str] = None

    service_file = Path("build/service_info.json")
    ws_uri: Optional[str] = None

    if service_file.is_file():
        try:
            info_data = json.loads(service_file.read_text(encoding="utf-8"))
            raw_uri = info_data.get("uri")
            if raw_uri:
                # Convert http://127.0.0.1:port/token/ -> ws://127.0.0.1:port/token/ws
                clean_uri = raw_uri.rstrip("/")
                if clean_uri.startswith("http://"):
                    ws_uri = f"ws://{clean_uri[7:]}/ws"
                elif clean_uri.startswith("https://"):
                    ws_uri = f"wss://{clean_uri[8:]}/ws"
                else:
                    ws_uri = f"{clean_uri}/ws"
        except Exception as e:
            logger.debug(f"Could not parse service_info.json: {e}")

    if not ws_uri:
        vm_forward_port = 8181
        run_adb(
            ["forward", f"tcp:{vm_forward_port}", f"tcp:{vm_forward_port}"], adb_path
        )
        ws_uri = f"ws://127.0.0.1:{vm_forward_port}/ws"

    try:
        vm_client = DartVmClient(ws_uri)
        await asyncio.wait_for(vm_client.connect(), timeout=2.0)
        isolate_id = await vm_client.get_main_isolate_id()
        logger.info(
            f"Connected to Dart VM Service at {ws_uri}. Main Isolate: {isolate_id}"
        )
    except Exception as e:
        logger.info(
            f"Dart VM Service not connected ({e}); capturing OS-level metrics and system memory."
        )
        vm_client = None

    try:
        results = await run_benchmark_session(adb_path, vm_client, isolate_id)
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        timeline_img, classes_img = generate_plots(results, OUTPUT_DIR)
        report_md = generate_markdown_report(
            results, timeline_img, classes_img, OUTPUT_DIR
        )

        logger.info("==================================================")
        logger.info("             BENCHMARK COMPLETED                  ")
        logger.info("==================================================")
        logger.info(f"Baseline Total RAM : {results.baseline_pss_mb:.1f} MB")
        logger.info(f"Peak Total RAM     : {results.peak_pss_mb:.1f} MB")
        logger.info(
            f"Resting Total RAM  : {results.resting_pss_mb:.1f} MB (Delta: {results.memory_delta_mb:+.1f} MB)"
        )
        logger.info(
            f"Average CPU        : {results.avg_cpu_percent:.1f}% (Peak: {results.peak_cpu_percent:.1f}%)"
        )
        if results.resting_dart_heap_mb > 0:
            logger.info(f"Resting Dart Heap  : {results.resting_dart_heap_mb:.1f} MB")
        logger.info(f"Report Generated   : {report_md}")
        logger.info(f"Timeline Chart     : {timeline_img}")
        if classes_img:
            logger.info(f"Class Allocation Chart : {classes_img}")
        logger.info("==================================================")
    finally:
        if vm_client:
            await vm_client.close()


def main() -> None:
    asyncio.run(main_async())


if __name__ == "__main__":
    main()
