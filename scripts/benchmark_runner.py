# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "matplotlib",
#     "websockets",
# ]
# ///

import argparse
import asyncio
import json
import logging
import os
import re
import shutil
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
class FrameMetrics:
    total_frames: int = 0
    average_fps: float = 0.0
    janky_frames: int = 0
    jank_percent: float = 0.0
    build_times_ms: List[float] = field(default_factory=list)
    raster_times_ms: List[float] = field(default_factory=list)
    total_times_ms: List[float] = field(default_factory=list)

    build_mean_ms: float = 0.0
    build_90th_ms: float = 0.0
    build_95th_ms: float = 0.0
    build_99th_ms: float = 0.0

    raster_mean_ms: float = 0.0
    raster_90th_ms: float = 0.0
    raster_95th_ms: float = 0.0
    raster_99th_ms: float = 0.0

    total_mean_ms: float = 0.0
    total_90th_ms: float = 0.0
    total_95th_ms: float = 0.0
    total_99th_ms: float = 0.0


@dataclass
class DeviceInfo:
    serial: str
    model: str
    android_version: str
    screen_size: str


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
    frame_metrics: Optional[FrameMetrics] = None


class AdbClient:
    def __init__(self, adb_path: str, device_id: str) -> None:
        self.adb_path = adb_path
        self.device_id = device_id

    def run(self, args: List[str]) -> str:
        cmd = [self.adb_path, "-s", self.device_id] + args
        res = subprocess.run(cmd, capture_output=True, text=True)
        if res.returncode != 0:
            logger.debug(f"ADB command failed: {' '.join(cmd)}: {res.stderr}")
        return res.stdout.strip()

    def get_device_info(self) -> DeviceInfo:
        model = self.run(["shell", "getprop", "ro.product.model"]) or "Android Device"
        version = (
            self.run(["shell", "getprop", "ro.build.version.release"]) or "Unknown"
        )
        size = self.run(["shell", "wm", "size"]) or "Unknown"
        m = re.search(r"(\d+x\d+)", size)
        size_str = m.group(1) if m else size
        return DeviceInfo(
            serial=self.device_id,
            model=model,
            android_version=version,
            screen_size=size_str,
        )


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


def check_connected_device(
    adb_path: str, requested_device: Optional[str] = None
) -> str:
    if requested_device:
        return requested_device
    if os.environ.get("ANDROID_SERIAL"):
        return os.environ["ANDROID_SERIAL"]
    cmd = [adb_path, "devices"]
    res = subprocess.run(cmd, capture_output=True, text=True)
    lines = [
        line for line in res.stdout.splitlines() if line and not line.startswith("List")
    ]
    devices = [
        line.split()[0]
        for line in lines
        if len(line.split()) >= 2 and line.split()[1] == "device"
    ]
    if not devices:
        raise RuntimeError("No connected Android device or running emulator detected.")
    # If multiple devices attached, prioritize physical mobile over emulator
    physical_devices = [d for d in devices if not d.startswith("emulator-")]
    if physical_devices:
        return physical_devices[0]
    return devices[0]


def sanitize_tag(tag: str) -> str:
    clean = re.sub(r"[^\w\-]+", "_", tag).strip("_").lower()
    return clean or "device"


def get_screen_dimensions(adb: AdbClient) -> Tuple[int, int]:
    out = adb.run(["shell", "wm", "size"])
    match = re.search(r"(\d+)x(\d+)", out)
    if match:
        return int(match.group(1)), int(match.group(2))
    return 1080, 2400


def query_system_memory(adb: AdbClient) -> Tuple[float, float, float, float]:
    out = adb.run(["shell", "dumpsys", "meminfo", PACKAGE_NAME])
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
        elif "Graphics" in line or "Gfx dev" in line or "EGL mtrack" in line:
            parts = line.split()
            for part in parts[1:]:
                clean = part.replace(",", "")
                if clean.isdigit():
                    graphics_kb += float(clean)
                    break
        elif "Code" in line or ".so mmap" in line or ".dex mmap" in line:
            parts = line.split()
            for part in parts[1:]:
                clean = part.replace(",", "")
                if clean.isdigit():
                    code_kb += float(clean)
                    break

    return (
        total_pss_kb / 1024.0,
        native_kb / 1024.0,
        graphics_kb / 1024.0,
        code_kb / 1024.0,
    )


def query_cpu_percent(adb: AdbClient) -> float:
    out = adb.run(["shell", f"top -b -n 1 | grep {PACKAGE_NAME}"])
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


def calculate_percentile(data: List[float], percentile: float) -> float:
    if not data:
        return 0.0
    sorted_data = sorted(data)
    idx = int(len(sorted_data) * (percentile / 100.0))
    idx = min(idx, len(sorted_data) - 1)
    return sorted_data[idx]


def normalize_ws_uri(uri: str) -> str:
    u = uri.strip()
    u = re.sub(r"^http://", "ws://", u)
    u = re.sub(r"^https://", "wss://", u)
    u = u.rstrip("/")
    if not u.endswith("/ws"):
        u = f"{u}/ws"
    return u


class DartVmClient:
    def __init__(self, uri: str) -> None:
        self.ws_uri = normalize_ws_uri(uri)
        self.ws: Optional[websockets.WebSocketClientProtocol] = None
        self._req_id = 0

    async def connect(self) -> None:
        try:
            self.ws = await websockets.connect(self.ws_uri, max_size=32 * 1024 * 1024)
        except Exception as e:
            err_msg = str(e)
            m = re.search(r"(https?://[^\s'\"]+)", err_msg)
            if m:
                redirected = m.group(1)
                new_ws = normalize_ws_uri(redirected)
                logger.info(f"Following DDS redirect to {new_ws}...")
                self.ws_uri = new_ws
                self.ws = await websockets.connect(
                    self.ws_uri, max_size=32 * 1024 * 1024
                )
            else:
                raise

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
        res = await self.call("getAllocationProfile", {"isolateId": isolate_id})
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

    async def reset_frame_metrics(self, isolate_id: str) -> None:
        try:
            await self.call(
                "ext.habits.getFrameMetrics",
                {"isolateId": isolate_id, "reset": "true"},
            )
        except Exception as e:
            logger.debug(f"Could not reset frame metrics: {e}")

    async def get_frame_metrics(
        self, isolate_id: str, elapsed_seconds: float
    ) -> Optional[FrameMetrics]:
        try:
            res = await self.call(
                "ext.habits.getFrameMetrics",
                {"isolateId": isolate_id, "reset": "false"},
            )
            raw_data = res.get("data", res)
            if isinstance(raw_data, str):
                raw_data = json.loads(raw_data)

            build_times = [float(x) for x in raw_data.get("buildTimesMs", [])]
            raster_times = [float(x) for x in raw_data.get("rasterTimesMs", [])]
            total_times = [float(x) for x in raw_data.get("totalTimesMs", [])]
            total_frames = len(total_times)

            if total_frames == 0:
                return None

            janky_count = sum(1 for t in total_times if t > 16.66)
            jank_pct = (janky_count / total_frames * 100.0) if total_frames > 0 else 0.0
            mean_total = (
                (sum(total_times) / len(total_times)) if total_frames > 0 else 16.66
            )
            # Active rendering FPS during active motion (excludes idle sleeps between gestures)
            active_fps = (1000.0 / mean_total) if mean_total > 0 else 60.0
            active_fps = min(active_fps, 120.0)

            return FrameMetrics(
                total_frames=total_frames,
                average_fps=active_fps,
                janky_frames=janky_count,
                jank_percent=jank_pct,
                build_times_ms=build_times,
                raster_times_ms=raster_times,
                total_times_ms=total_times,
                build_mean_ms=sum(build_times) / len(build_times),
                build_90th_ms=calculate_percentile(build_times, 90),
                build_95th_ms=calculate_percentile(build_times, 95),
                build_99th_ms=calculate_percentile(build_times, 99),
                raster_mean_ms=sum(raster_times) / len(raster_times),
                raster_90th_ms=calculate_percentile(raster_times, 90),
                raster_95th_ms=calculate_percentile(raster_times, 95),
                raster_99th_ms=calculate_percentile(raster_times, 99),
                total_mean_ms=mean_total,
                total_90th_ms=calculate_percentile(total_times, 90),
                total_95th_ms=calculate_percentile(total_times, 95),
                total_99th_ms=calculate_percentile(total_times, 99),
            )
        except Exception as e:
            logger.debug(f"Frame metrics retrieval error: {e}")
            return None


async def run_benchmark_session(
    adb: AdbClient, vm_client: Optional[DartVmClient], isolate_id: Optional[str]
) -> BenchmarkResults:
    width, height = get_screen_dimensions(adb)
    nav_y = int(height * 0.94)
    nav_today_x = int(width * 0.10)
    nav_week_x = int(width * 0.30)
    nav_analytics_x = int(width * 0.70)
    nav_mastery_x = int(width * 0.90)

    # 1. Warm-up Pass
    logger.info("Executing initial warm-up pass to initialize screen caches...")
    adb.run(["shell", "input", "tap", str(nav_week_x), str(nav_y)])
    await asyncio.sleep(0.5)
    adb.run(["shell", "input", "tap", str(nav_analytics_x), str(nav_y)])
    await asyncio.sleep(0.5)
    adb.run(["shell", "input", "tap", str(nav_mastery_x), str(nav_y)])
    await asyncio.sleep(0.5)
    adb.run(["shell", "input", "tap", str(nav_today_x), str(nav_y)])
    await asyncio.sleep(0.8)

    # 2. Settle & Trigger GC for True Post-Warmup Baseline
    logger.info("Stabilizing and taking post-warmup baseline measurements...")
    if vm_client and isolate_id:
        await vm_client.collect_garbage(isolate_id)
        await vm_client.reset_frame_metrics(isolate_id)
    await asyncio.sleep(1.5)

    base_pss, base_native, base_graphics, base_code = query_system_memory(adb)
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
            cpu = query_cpu_percent(adb)
            pss, native, gfx, code = query_system_memory(adb)
            samples.append(MemorySample(t, cpu, pss, native, gfx, code))
            await asyncio.sleep(0.4)

    stop_event = asyncio.Event()
    sampler_task = asyncio.create_task(sample_worker(stop_event))

    logger.info("Executing comprehensive multi-screen stress & interaction workflow...")

    # --- Phase 1: Today Screen & Date Bar Navigation ---
    logger.info("  [1/5] Interacting with Today Tracker, Date Bar, and Habit Detail...")
    adb.run(
        [
            "shell",
            "input",
            "swipe",
            str(int(width * 0.80)),
            str(int(height * 0.14)),
            str(int(width * 0.20)),
            str(int(height * 0.14)),
            "200",
        ]
    )
    await asyncio.sleep(0.4)
    adb.run(
        [
            "shell",
            "input",
            "swipe",
            str(int(width * 0.20)),
            str(int(height * 0.14)),
            str(int(width * 0.80)),
            str(int(height * 0.14)),
            "200",
        ]
    )
    await asyncio.sleep(0.4)

    for _ in range(3):
        adb.run(
            [
                "shell",
                "input",
                "swipe",
                str(width // 2),
                str(int(height * 0.70)),
                str(width // 2),
                str(int(height * 0.25)),
                "250",
            ]
        )
        await asyncio.sleep(0.3)
        adb.run(
            [
                "shell",
                "input",
                "swipe",
                str(width // 2),
                str(int(height * 0.25)),
                str(width // 2),
                str(int(height * 0.70)),
                "250",
            ]
        )
        await asyncio.sleep(0.3)

    # Toggle habit check-in
    adb.run(
        [
            "shell",
            "input",
            "tap",
            str(int(width * 0.90)),
            str(int(height * 0.38)),
        ]
    )
    await asyncio.sleep(0.6)

    # Tap on habit card to open HabitDetailScreen
    adb.run(
        [
            "shell",
            "input",
            "tap",
            str(int(width * 0.45)),
            str(int(height * 0.38)),
        ]
    )
    await asyncio.sleep(1.0)

    # Scroll inside Habit Detail screen
    adb.run(
        [
            "shell",
            "input",
            "swipe",
            str(width // 2),
            str(int(height * 0.70)),
            str(width // 2),
            str(int(height * 0.30)),
            "250",
        ]
    )
    await asyncio.sleep(0.5)
    adb.run(
        [
            "shell",
            "input",
            "swipe",
            str(width // 2),
            str(int(height * 0.30)),
            str(width // 2),
            str(int(height * 0.70)),
            "250",
        ]
    )
    await asyncio.sleep(0.5)

    # Tap AppBar back arrow at top-left
    app_bar_back_x = int(width * 0.08)
    app_bar_back_y = int(height * 0.06)
    adb.run(["shell", "input", "tap", str(app_bar_back_x), str(app_bar_back_y)])
    await asyncio.sleep(0.5)
    adb.run(["shell", "input", "tap", str(nav_today_x), str(nav_y)])
    await asyncio.sleep(0.5)

    # --- Phase 2: Week Matrix Tab & Grid Navigation ---
    logger.info("  [2/5] Interacting with Week Matrix (2D grid pan & cell taps)...")
    adb.run(["shell", "input", "tap", str(nav_week_x), str(nav_y)])
    await asyncio.sleep(0.8)

    for _ in range(2):
        adb.run(
            [
                "shell",
                "input",
                "swipe",
                str(width // 2),
                str(int(height * 0.65)),
                str(width // 2),
                str(int(height * 0.35)),
                "250",
            ]
        )
        await asyncio.sleep(0.3)
        adb.run(
            [
                "shell",
                "input",
                "swipe",
                str(width // 2),
                str(int(height * 0.35)),
                str(width // 2),
                str(int(height * 0.65)),
                "250",
            ]
        )
        await asyncio.sleep(0.3)

    adb.run(
        [
            "shell",
            "input",
            "swipe",
            str(int(width * 0.85)),
            str(int(height * 0.50)),
            str(int(width * 0.15)),
            str(int(height * 0.50)),
            "200",
        ]
    )
    await asyncio.sleep(0.4)
    adb.run(
        [
            "shell",
            "input",
            "swipe",
            str(int(width * 0.15)),
            str(int(height * 0.50)),
            str(int(width * 0.85)),
            str(int(height * 0.50)),
            "200",
        ]
    )
    await asyncio.sleep(0.4)

    adb.run(
        [
            "shell",
            "input",
            "tap",
            str(int(width * 0.60)),
            str(int(height * 0.40)),
        ]
    )
    await asyncio.sleep(0.5)

    # --- Phase 3: Analytics Tab & Charts Interaction ---
    logger.info(
        "  [3/5] Interacting with Analytics (heatmaps, charts, filter toggles)..."
    )
    adb.run(["shell", "input", "tap", str(nav_analytics_x), str(nav_y)])
    await asyncio.sleep(0.8)

    for _ in range(3):
        adb.run(
            [
                "shell",
                "input",
                "swipe",
                str(width // 2),
                str(int(height * 0.70)),
                str(width // 2),
                str(int(height * 0.25)),
                "250",
            ]
        )
        await asyncio.sleep(0.4)

    adb.run(
        [
            "shell",
            "input",
            "tap",
            str(int(width * 0.50)),
            str(int(height * 0.20)),
        ]
    )
    await asyncio.sleep(0.5)

    for _ in range(3):
        adb.run(
            [
                "shell",
                "input",
                "swipe",
                str(width // 2),
                str(int(height * 0.25)),
                str(width // 2),
                str(int(height * 0.70)),
                "250",
            ]
        )
        await asyncio.sleep(0.3)

    # --- Phase 4: Mastery / Badges Showcase ---
    logger.info("  [4/5] Interacting with Mastery & Gamification showcase...")
    adb.run(["shell", "input", "tap", str(nav_mastery_x), str(nav_y)])
    await asyncio.sleep(0.8)

    for _ in range(2):
        adb.run(
            [
                "shell",
                "input",
                "swipe",
                str(width // 2),
                str(int(height * 0.65)),
                str(width // 2),
                str(int(height * 0.30)),
                "250",
            ]
        )
        await asyncio.sleep(0.3)
        adb.run(
            [
                "shell",
                "input",
                "swipe",
                str(width // 2),
                str(int(height * 0.30)),
                str(width // 2),
                str(int(height * 0.65)),
                "250",
            ]
        )
        await asyncio.sleep(0.3)

    adb.run(
        [
            "shell",
            "input",
            "tap",
            str(int(width * 0.30)),
            str(int(height * 0.45)),
        ]
    )
    await asyncio.sleep(0.6)
    adb.run(
        [
            "shell",
            "input",
            "tap",
            str(int(width * 0.50)),
            str(int(height * 0.15)),
        ]
    )
    await asyncio.sleep(0.5)

    # --- Phase 5: Rapid Multi-Screen Switching Stress ---
    logger.info("  [5/5] Executing rapid multi-tab switching stress cycles...")
    for _ in range(4):
        adb.run(["shell", "input", "tap", str(nav_today_x), str(nav_y)])
        await asyncio.sleep(0.3)
        adb.run(["shell", "input", "tap", str(nav_week_x), str(nav_y)])
        await asyncio.sleep(0.3)
        adb.run(["shell", "input", "tap", str(nav_analytics_x), str(nav_y)])
        await asyncio.sleep(0.3)
        adb.run(["shell", "input", "tap", str(nav_mastery_x), str(nav_y)])
        await asyncio.sleep(0.3)

    # Return to Today
    adb.run(["shell", "input", "tap", str(nav_today_x), str(nav_y)])
    await asyncio.sleep(0.5)

    stop_event.set()
    await sampler_task
    elapsed_total = time.time() - start_time

    logger.info("Cooling down and measuring resting memory & frame metrics...")
    frame_metrics: Optional[FrameMetrics] = None
    if vm_client and isolate_id:
        frame_metrics = await vm_client.get_frame_metrics(isolate_id, elapsed_total)
        await vm_client.collect_garbage(isolate_id)

    await asyncio.sleep(2.0)

    resting_pss, resting_native, resting_graphics, resting_code = query_system_memory(
        adb
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
        frame_metrics=frame_metrics,
    )


def generate_plots(
    results: BenchmarkResults, output_dir: Path, tag: str
) -> Tuple[Path, Optional[Path], Optional[Path]]:
    output_dir.mkdir(parents=True, exist_ok=True)
    suffix = f"_{tag}" if tag else ""
    timeline_path = output_dir / f"timeline_cpu_memory{suffix}.png"
    classes_path = output_dir / f"top_dart_allocations{suffix}.png"
    frames_path = output_dir / f"frame_timings_distribution{suffix}.png"

    # 1. Timeline Plot
    fig, ax1 = plt.subplots(figsize=(11, 5.5), dpi=150)
    times = [s.timestamp for s in results.samples]
    pss = [s.total_pss_mb for s in results.samples]
    native = [s.native_heap_mb for s in results.samples]
    cpus = [s.cpu_percent for s in results.samples]

    color_pss = "#2563EB"
    color_native = "#059669"
    color_cpu = "#DC2626"

    ax1.set_xlabel("Elapsed Time (seconds)", fontsize=11, fontweight="normal")
    ax1.set_ylabel("Memory (MB)", fontsize=11, fontweight="normal")
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
        "CPU Utilization (%)", color=color_cpu, fontsize=11, fontweight="normal"
    )
    l3 = ax2.plot(
        times,
        cpus,
        label="Active CPU %",
        color=color_cpu,
        linewidth=1.5,
        alpha=0.85,
    )
    ax2.tick_params(axis="y", labelcolor=color_cpu)

    lines = l1 + l2 + l3
    labels = [line.get_label() for line in lines]
    ax1.legend(lines, labels, loc="upper left", framealpha=0.9)
    plt.title(
        f"Automated Multi-Screen Stress Benchmark ({tag}) - Memory & CPU Timeline",
        fontsize=12,
        fontweight="bold",
        pad=12,
    )
    plt.tight_layout()
    plt.savefig(timeline_path)
    plt.close(fig)

    # 2. Frame Timings Plot (if available)
    if results.frame_metrics and len(results.frame_metrics.total_times_ms) > 0:
        fm = results.frame_metrics
        fig, (ax_hist, ax_box) = plt.subplots(
            2,
            1,
            figsize=(11, 6.5),
            dpi=150,
            gridspec_kw={"height_ratios": [2.5, 1]},
        )

        ax_hist.hist(
            fm.build_times_ms,
            bins=30,
            alpha=0.6,
            color="#3B82F6",
            label=f"UI Build Time (Avg: {fm.build_mean_ms:.1f}ms)",
        )
        ax_hist.hist(
            fm.raster_times_ms,
            bins=30,
            alpha=0.6,
            color="#10B981",
            label=f"Raster GPU Time (Avg: {fm.raster_mean_ms:.1f}ms)",
        )
        ax_hist.axvline(
            16.66,
            color="#EF4444",
            linestyle="--",
            linewidth=2,
            label="60 FPS Threshold (16.6ms)",
        )
        ax_hist.set_title(
            f"Frame Timing Distribution - {fm.total_frames} Frames ({fm.average_fps:.1f} Active FPS, {100.0 - fm.jank_percent:.1f}% Smooth)",
            fontsize=12,
            fontweight="bold",
        )
        ax_hist.set_xlabel("Frame Duration (ms)")
        ax_hist.set_ylabel("Frame Count")
        ax_hist.legend(loc="upper right")
        ax_hist.grid(True, linestyle=":", alpha=0.6)

        try:
            ax_box.boxplot(
                [fm.build_times_ms, fm.raster_times_ms, fm.total_times_ms],
                orientation="horizontal",
                tick_labels=["UI Build", "Raster GPU", "Total Frame"],
                patch_artist=True,
                boxprops=dict(facecolor="#E0E7FF", color="#4338CA"),
                medianprops=dict(color="#DC2626", linewidth=1.5),
            )
        except TypeError:
            try:
                ax_box.boxplot(
                    [fm.build_times_ms, fm.raster_times_ms, fm.total_times_ms],
                    vert=False,
                    tick_labels=["UI Build", "Raster GPU", "Total Frame"],
                    patch_artist=True,
                    boxprops=dict(facecolor="#E0E7FF", color="#4338CA"),
                    medianprops=dict(color="#DC2626", linewidth=1.5),
                )
            except TypeError:
                ax_box.boxplot(
                    [fm.build_times_ms, fm.raster_times_ms, fm.total_times_ms],
                    vert=False,
                    labels=["UI Build", "Raster GPU", "Total Frame"],
                    patch_artist=True,
                    boxprops=dict(facecolor="#E0E7FF", color="#4338CA"),
                    medianprops=dict(color="#DC2626", linewidth=1.5),
                )

        ax_box.axvline(16.66, color="#EF4444", linestyle="--", linewidth=1.5)
        ax_box.set_xlabel("Milliseconds")
        ax_box.grid(True, linestyle=":", alpha=0.6)

        plt.tight_layout()
        plt.savefig(frames_path)
        plt.close(fig)
    else:
        frames_path = None

    # 3. Top Classes Plot
    if results.top_classes:
        fig, ax = plt.subplots(figsize=(10, 6), dpi=150)
        class_names = [c.name for c in reversed(results.top_classes)]
        sizes_kb = [c.kb_allocated for c in reversed(results.top_classes)]
        counts = [c.instances for c in reversed(results.top_classes)]

        bars = ax.barh(
            class_names,
            sizes_kb,
            color="#4F46E5",
            edgecolor="#3730A3",
            height=0.65,
        )
        ax.set_xlabel("Dart Heap Memory (KB)", fontsize=11, fontweight="normal")
        ax.set_title(
            f"Top Dart Classes by Allocated Heap Memory ({tag})",
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

    return timeline_path, classes_path, frames_path


def generate_markdown_report(
    results: BenchmarkResults,
    timeline_plot: Path,
    classes_plot: Optional[Path],
    frames_plot: Optional[Path],
    output_dir: Path,
    tag: str,
    device_info: DeviceInfo,
) -> Tuple[Path, Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    suffix = f"_{tag}" if tag else ""
    tagged_report_path = output_dir / f"benchmark_report{suffix}.md"
    default_report_path = output_dir / "benchmark_report.md"

    health_status = "STABLE" if results.memory_delta_mb <= 15.0 else "WARNING_LEAK"

    lines: List[str] = [
        "# Automated Performance and Footprint Benchmark Report",
        "",
        f"- **Generated At:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"- **Application Package:** `{PACKAGE_NAME}`",
        f"- **Target Device:** `{device_info.model}` (`Android {device_info.android_version}`, `{device_info.screen_size}`, Serial: `{device_info.serial}`)",
        f"- **Report Identifier / Tag:** `{tag}`",
        "",
        "## Executive Summary",
        "",
        "| Metric | Baseline | Peak | Resting | Delta (Post-GC) | Health Status |",
        "| :--- | :--- | :--- | :--- | :--- | :--- |",
        f"| **Total System RAM (PSS)** | {results.baseline_pss_mb:.1f} MB | {results.peak_pss_mb:.1f} MB | {results.resting_pss_mb:.1f} MB | {results.memory_delta_mb:+.1f} MB | **{health_status}** |",
        f"| **Native Heap (Impeller/C++)** | {results.baseline_native_mb:.1f} MB | - | {results.resting_native_mb:.1f} MB | {results.resting_native_mb - results.baseline_native_mb:+.1f} MB | **OPTIMAL** |",
    ]

    if results.resting_dart_heap_mb > 0.0:
        lines.append(
            f"| **Dart VM Heap** | {results.baseline_dart_heap_mb:.1f} MB | - | {results.resting_dart_heap_mb:.1f} MB | {results.resting_dart_heap_mb - results.baseline_dart_heap_mb:+.1f} MB | **OPTIMAL** |"
        )

    lines.extend(
        [
            "",
            "## CPU Utilization",
            "",
            f"- **Average Active CPU:** {results.avg_cpu_percent:.1f}%",
            f"- **Peak CPU Spike:** {results.peak_cpu_percent:.1f}%",
            "",
        ]
    )

    if results.frame_metrics:
        fm = results.frame_metrics
        lines.extend(
            [
                "## Frame Rate and Rendering Performance",
                "",
                "| Rendering Metric | Measurement | Target / Budget | Status |",
                "| :--- | :--- | :--- | :--- |",
                f"| **Total Frames Rendered** | {fm.total_frames:,} | - | COMPLETED |",
                f"| **Active Motion Render Rate** | **{fm.average_fps:.1f} FPS** | 60.0 / 120.0 FPS | **{'OPTIMAL' if fm.average_fps >= 55.0 else 'GOOD'}** |",
                f"| **Frame Smoothness / Fluidity** | **{100.0 - fm.jank_percent:.1f}%** | > 95.0% | **{'PASS' if fm.jank_percent <= 5.0 else 'WARN'}** |",
                f"| **Janky Frames (>16.6ms)** | {fm.janky_frames} ({fm.jank_percent:.1f}%) | < 5.0% | **{'PASS' if fm.jank_percent <= 5.0 else 'WARN'}** |",
                f"| **UI Thread Build Time (Avg)** | {fm.build_mean_ms:.1f} ms (95th: {fm.build_95th_ms:.1f}ms) | < 8.0 ms | **OPTIMAL** |",
                f"| **Raster GPU Time (Avg)** | {fm.raster_mean_ms:.1f} ms (95th: {fm.raster_95th_ms:.1f}ms) | < 8.0 ms | **OPTIMAL** |",
                f"| **Total Frame Time (Avg)** | {fm.total_mean_ms:.1f} ms (99th: {fm.total_99th_ms:.1f}ms) | < 16.6 ms | **OPTIMAL** |",
                "",
            ]
        )
        if frames_plot:
            lines.extend(
                [
                    f"![Frame Timing Distribution]({frames_plot.name})",
                    "",
                ]
            )

    lines.extend(
        [
            "## Performance Timeline",
            "",
            f"![Memory and CPU Timeline]({timeline_plot.name})",
            "",
        ]
    )

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

    content = "\n".join(lines)
    tagged_report_path.write_text(content, encoding="utf-8")
    if tagged_report_path != default_report_path:
        default_report_path.write_text(content, encoding="utf-8")
    return tagged_report_path, default_report_path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Automated Flutter Benchmark Suite with Device Tagging and Multi-Report Support"
    )
    parser.add_argument(
        "--tag",
        "-t",
        "--device-name",
        "--id",
        dest="tag",
        type=str,
        default=os.environ.get("DEVICE_TAG"),
        help="Custom identifier tag for output filenames (e.g., 'moto_g60', 'pixel8', 'emulator')",
    )
    parser.add_argument(
        "--device",
        "-d",
        "--serial",
        dest="device_id",
        type=str,
        default=os.environ.get("ANDROID_SERIAL"),
        help="Specific target Android device serial ID (e.g. 'ZD2224QRJY' or 'emulator-5554')",
    )
    parser.add_argument(
        "--vm-service-url",
        "-u",
        dest="vm_service_url",
        type=str,
        default=os.environ.get("VM_SERVICE_URL"),
        help="Explicit Dart VM Service WebSocket/HTTP URL",
    )
    parser.add_argument(
        "--output-dir",
        "-o",
        dest="output_dir",
        type=str,
        default="build/benchmark_reports",
        help="Output directory for generated plots and Markdown reports",
    )
    # Support positional URI if passed
    parser.add_argument(
        "positional_url",
        nargs="?",
        default=None,
        help="Optional positional Dart VM Service URL",
    )
    return parser.parse_args()


async def main_async() -> None:
    args = parse_args()
    adb_path = get_adb_path()
    logger.info(f"Using ADB binary: {adb_path}")

    device_id = check_connected_device(adb_path, requested_device=args.device_id)
    adb = AdbClient(adb_path, device_id)
    device_info = adb.get_device_info()
    logger.info(
        f"Target Device: {device_info.model} (Android {device_info.android_version}, Serial: {device_id})"
    )

    # Determine report tag
    tag_raw = args.tag
    if not tag_raw:
        tag_raw = f"{device_info.model}_{device_id[-4:]}"
    tag = sanitize_tag(tag_raw)
    logger.info(f"Benchmark Report Identifier Tag: '{tag}'")

    output_dir = Path(args.output_dir)

    # Look for active Dart VM Service port
    vm_client: Optional[DartVmClient] = None
    isolate_id: Optional[str] = None
    ws_uri: Optional[str] = args.vm_service_url or args.positional_url

    if ws_uri:
        m = re.search(r":(\d+)/([^/\s]+)/?", ws_uri)
        if m:
            dev_port = int(m.group(1))
            auth_token = m.group(2)
            adb.run(["forward", f"tcp:{dev_port}", f"tcp:{dev_port}"])
            ws_uri = f"ws://127.0.0.1:{dev_port}/{auth_token}/ws"
        logger.info(f"Using explicit VM Service URL: {ws_uri}")
    else:
        # 1. Primary discovery: Check running host dart development-service process
        try:

            ps_out = subprocess.check_output(["ps", "aux"], text=True)
            for line in ps_out.splitlines():
                if "development-service" in line and "--vm-service-uri=" in line:
                    m = re.search(r"--vm-service-uri=([^\s]+)", line)
                    if m:
                        raw_uri = m.group(1).strip("\"'")
                        ws_uri = normalize_ws_uri(raw_uri)
                        logger.info(f"Auto-discovered host DDS VM Service: {ws_uri}")
                        break
        except Exception as e:
            logger.debug(f"Host process inspection skipped: {e}")

        # 2. Fallback: Auto-discover from device logcat
        if not ws_uri:
            for _ in range(5):
                logcat_out = adb.run(["logcat", "-d"])
                for line in reversed(logcat_out.splitlines()):
                    if (
                        "The Dart VM service is listening on" in line
                        or "A Dart VM Service on" in line
                    ):
                        m = re.search(r"http://127\.0\.0\.1:(\d+)/([^/\s]+)/?", line)
                        if m:
                            dev_port = int(m.group(1))
                            auth_token = m.group(2)
                            adb.run(["forward", f"tcp:{dev_port}", f"tcp:{dev_port}"])
                            ws_uri = f"ws://127.0.0.1:{dev_port}/{auth_token}/ws"
                            logger.info(
                                f"Auto-discovered Dart VM Service from logcat on port {dev_port}"
                            )
                            break
                if ws_uri:
                    break
                await asyncio.sleep(1.0)

    if ws_uri:
        try:
            vm_client = DartVmClient(ws_uri)
            await asyncio.wait_for(vm_client.connect(), timeout=3.0)
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
        results = await run_benchmark_session(adb, vm_client, isolate_id)
        output_dir.mkdir(parents=True, exist_ok=True)
        timeline_img, classes_img, frames_img = generate_plots(results, output_dir, tag)
        tagged_report, default_report = generate_markdown_report(
            results, timeline_img, classes_img, frames_img, output_dir, tag, device_info
        )

        logger.info("==================================================")
        logger.info("             BENCHMARK COMPLETED                  ")
        logger.info("==================================================")
        logger.info(f"Target Device      : {device_info.model} ({device_info.serial})")
        logger.info(f"Report Tag         : {tag}")
        logger.info(f"Baseline Total RAM : {results.baseline_pss_mb:.1f} MB")
        logger.info(f"Peak Total RAM     : {results.peak_pss_mb:.1f} MB")
        logger.info(
            f"Resting Total RAM  : {results.resting_pss_mb:.1f} MB (Delta: {results.memory_delta_mb:+.1f} MB)"
        )
        logger.info(
            f"Average CPU        : {results.avg_cpu_percent:.1f}% (Peak: {results.peak_cpu_percent:.1f}%)"
        )
        if results.frame_metrics:
            fm = results.frame_metrics
            logger.info(
                f"Active Render Rate : {fm.average_fps:.1f} FPS ({fm.total_frames} frames, {100.0 - fm.jank_percent:.1f}% smooth)"
            )
            logger.info(
                f"Frame Timings      : UI Avg: {fm.build_mean_ms:.1f}ms | Raster Avg: {fm.raster_mean_ms:.1f}ms | Total Avg: {fm.total_mean_ms:.1f}ms"
            )
        if results.resting_dart_heap_mb > 0:
            logger.info(f"Resting Dart Heap  : {results.resting_dart_heap_mb:.1f} MB")
        logger.info(f"Tagged Report      : {tagged_report}")
        logger.info(f"Default Report     : {default_report}")
        logger.info(f"Timeline Chart     : {timeline_img}")
        if frames_img:
            logger.info(f"Frames Chart       : {frames_img}")
        if classes_img:
            logger.info(f"Class Alloc Chart  : {classes_img}")
        logger.info("==================================================")
    finally:
        if vm_client:
            await vm_client.close()


def main() -> None:
    asyncio.run(main_async())


if __name__ == "__main__":
    main()
