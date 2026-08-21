#!/usr/bin/env python3
"""Fail if lib/domain + lib/data line coverage drops below baseline - 1.0 pp.

Reads coverage/lcov.info and .github/coverage_baseline (single float percent).
"""

from __future__ import annotations

import sys
from pathlib import Path


def coverage_for_prefixes(lcov_path: Path, prefixes: list[str]) -> float:
    found = 0
    hit = 0
    include = False
    for line in lcov_path.read_text(encoding="utf-8").splitlines():
        if line.startswith("SF:"):
            path = line[3:].replace("\\", "/")
            include = any(f"/{p}/" in f"/{path}" or path.startswith(p) for p in prefixes)
            continue
        if not include:
            continue
        if line.startswith("DA:"):
            # DA:<line>,<hits>
            parts = line[3:].split(",")
            if len(parts) != 2:
                continue
            found += 1
            if int(parts[1]) > 0:
                hit += 1
    if found == 0:
        raise SystemExit(f"No coverage lines found for prefixes {prefixes}")
    return 100.0 * hit / found


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    lcov = root / "coverage" / "lcov.info"
    baseline_file = root / ".github" / "coverage_baseline"
    if not lcov.is_file():
        print(f"Missing {lcov}; run: flutter test --coverage", file=sys.stderr)
        return 1
    if not baseline_file.is_file():
        print(f"Missing {baseline_file}", file=sys.stderr)
        return 1

    baseline = float(baseline_file.read_text(encoding="utf-8").strip())
    actual = coverage_for_prefixes(lcov, ["lib/domain", "lib/data"])
    floor = baseline - 1.0
    print(f"domain+data coverage: {actual:.2f}% (baseline {baseline:.2f}%, floor {floor:.2f}%)")
    if actual < floor:
        print(
            f"Coverage {actual:.2f}% dropped more than 1.0 pp below baseline {baseline:.2f}%",
            file=sys.stderr,
        )
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
