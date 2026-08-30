from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from dataclasses import asdict
from pathlib import Path
from typing import Any


FOUNDATION_DAY = -15055671

SCENARIOS: dict[str, dict[str, Any]] = {
    "cold_single_lookup": {
        "kind": "calendar",
        "target_offset": 3,
        "warm_primes": [3],
        "warm_repeats": 1,
        "description": "single lookup; warm side is one verified final-burial resurrection",
    },
    "repeated_identical_lookup": {
        "kind": "calendar",
        "target_offset": 1000,
        "warm_primes": [1000],
        "warm_repeats": 20,
        "description": "twenty repeated identical requests after one verified full run",
    },
    "repeated_calculation_day_different_targets": {
        "kind": "calendar",
        "target_offset": 1100,
        "warm_primes": [1000],
        "warm_repeats": 1,
        "description": "same calculation day, different target, same already-built semantic year",
    },
    "far_target_years": {
        "kind": "calendar",
        "target_offset": 401500,
        "warm_primes": [400000, 401000],
        "warm_repeats": 1,
        "description": "far target after two nearby far searches; exercises checkpoints/shards",
    },
    "sequential_target_days": {
        "kind": "calendar",
        "target_offset": 1002,
        "warm_primes": [1000, 1001],
        "warm_repeats": 1,
        "description": "sequential target day after two adjacent requests",
    },
    "repeated_requests_same_year": {
        "kind": "calendar",
        "target_offset": 2000,
        "warm_primes": [1000, 1400],
        "warm_repeats": 1,
        "description": "different target requests known to remain in semantic year 5001",
    },
    "selection_heavy_remembered_offset": {
        "kind": "selection",
        "warm_repeats": 200,
        "description": "short-selection rejection loop with a previously observed offset of 2000",
    },
}


def _metric_delta(after: dict[str, int], before: dict[str, int]) -> dict[str, int]:
    keys = set(after) | set(before)
    return {key: after.get(key, 0) - before.get(key, 0) for key in sorted(keys)}


def _metric_summary(metrics: dict[str, int]) -> dict[str, int]:
    cache_hits = sum(
        metrics.get(name, 0)
        for name in (
            "final_result_cache_hit",
            "year_checkpoint_hit",
            "gate_shard_hit",
            "year_structure_cache_hit",
            "selection_oracle_hit",
        )
    )
    return {
        "cache_hits": cache_hits,
        "final_result_cache_hits": metrics.get("final_result_cache_hit", 0),
        "year_checkpoint_hits": metrics.get("year_checkpoint_hit", 0),
        "year_steps_avoided": metrics.get("year_checkpoint_distance_saved", 0),
        "gate_shard_hits": metrics.get("gate_shard_hit", 0),
        "gate_generations_avoided": metrics.get("gate_shard_hit", 0) * 512,
        "year_structure_cache_hits": metrics.get("year_structure_cache_hit", 0),
        "selection_oracle_hits": metrics.get("selection_oracle_hit", 0),
        "selection_iterations_avoided": metrics.get("selection_oracle_saved_iterations", 0),
    }


def _calendar_worker(scenario: dict[str, Any], mode: str) -> dict[str, Any]:
    from pastafari_calendar.acceleration_scars import (
        acceleration_mode,
        global_acceleration_metrics,
        reset_acceleration_scars_for_tests,
    )
    from pastafari_calendar.calendar import calendar_date_spaghetti

    reset_acceleration_scars_for_tests()
    calculation_day = FOUNDATION_DAY
    target_day = FOUNDATION_DAY + int(scenario["target_offset"])

    enabled = mode != "baseline"
    primes = list(scenario.get("warm_primes", ())) if mode == "warm" else []
    repeats = int(scenario.get("warm_repeats", 1)) if mode == "warm" else 1

    with acceleration_mode(enabled):
        for offset in primes:
            calendar_date_spaghetti(calculation_day, FOUNDATION_DAY + int(offset))

        before = global_acceleration_metrics()
        start = time.perf_counter()
        results = [
            calendar_date_spaghetti(calculation_day, target_day)
            for _ in range(repeats)
        ]
        elapsed = time.perf_counter() - start
        after = global_acceleration_metrics()

    first = results[0]
    for result in results[1:]:
        if result != first:
            raise AssertionError("repeated benchmark request changed semantic result")

    metrics = _metric_delta(after, before)
    return {
        "elapsed_seconds": elapsed,
        "per_lookup_seconds": elapsed / repeats,
        "repeats": repeats,
        "result": asdict(first),
        "metrics": metrics,
        "summary": _metric_summary(metrics),
    }


def _selection_worker(scenario: dict[str, Any], mode: str) -> dict[str, Any]:
    from pastafari_calendar.acceleration_scars import (
        global_acceleration_metrics,
        reset_acceleration_scars_for_tests,
    )
    from pastafari_calendar.final_integration import _chooseIntegratedRank
    from pastafari_calendar.legacy_arithmetic import M_OLD
    from pastafari_calendar.legacy_selection import LegacyAnswerRing
    from pastafari_calendar.monster_bootstrap import MonsterContext

    reset_acceleration_scars_for_tests()
    ring = LegacyAnswerRing(first=M_OLD, direction_step=-1)
    family_count = M_OLD - 2000
    scope = ("benchmark-selection-heavy", 31)
    enabled = mode != "baseline"

    def choose() -> int:
        ctx = MonsterContext(1, 1)
        ctx.acceleration_scars.enabled = enabled
        return _chooseIntegratedRank(ring, family_count, ctx, scope)

    if mode == "warm":
        choose()  # observe and bury the accepted offset using the original loop

    repeats = int(scenario.get("warm_repeats", 1)) if mode == "warm" else 1
    before = global_acceleration_metrics()
    start = time.perf_counter()
    results = [choose() for _ in range(repeats)]
    elapsed = time.perf_counter() - start
    after = global_acceleration_metrics()

    if len(set(results)) != 1:
        raise AssertionError("selection benchmark changed semantic rank")

    metrics = _metric_delta(after, before)
    return {
        "elapsed_seconds": elapsed,
        "per_lookup_seconds": elapsed / repeats,
        "repeats": repeats,
        "result": results[0],
        "metrics": metrics,
        "summary": _metric_summary(metrics),
    }


def _worker(name: str, mode: str) -> None:
    scenario = SCENARIOS[name]
    if scenario["kind"] == "calendar":
        payload = _calendar_worker(scenario, mode)
    else:
        payload = _selection_worker(scenario, mode)
    print(json.dumps(payload, ensure_ascii=False, sort_keys=True))


def _run_isolated(repo_root: Path, name: str, mode: str) -> dict[str, Any]:
    env = os.environ.copy()
    src_root = str(repo_root / "src")
    previous_pythonpath = env.get("PYTHONPATH", "")
    env["PYTHONPATH"] = (
        src_root
        if not previous_pythonpath
        else src_root + os.pathsep + previous_pythonpath
    )
    completed = subprocess.run(
        [sys.executable, str(Path(__file__).resolve()), "--worker", name, mode],
        cwd=repo_root,
        env=env,
        text=True,
        capture_output=True,
        check=True,
        timeout=180,
    )
    return json.loads(completed.stdout.strip().splitlines()[-1])


def _ratio(numerator: float, denominator: float) -> float:
    if denominator <= 0:
        return float("inf")
    return numerator / denominator


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--worker", nargs=2, metavar=("SCENARIO", "MODE"))
    parser.add_argument("--scenario", choices=tuple(SCENARIOS))
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    if args.worker:
        name, mode = args.worker
        if name not in SCENARIOS:
            raise SystemExit(f"unknown scenario: {name}")
        if mode not in {"baseline", "cold", "warm"}:
            raise SystemExit(f"unknown mode: {mode}")
        _worker(name, mode)
        return

    repo_root = Path(__file__).resolve().parents[1]
    report: dict[str, Any] = {}
    selected = (
        {args.scenario: SCENARIOS[args.scenario]}
        if args.scenario is not None
        else SCENARIOS
    )
    for name, scenario in selected.items():
        print(f"benchmarking {name}", file=sys.stderr, flush=True)
        baseline = _run_isolated(repo_root, name, "baseline")
        cold = _run_isolated(repo_root, name, "cold")
        warm = _run_isolated(repo_root, name, "warm")

        if baseline["result"] != cold["result"] or baseline["result"] != warm["result"]:
            raise AssertionError(f"benchmark semantic mismatch in {name}")

        report[name] = {
            "description": scenario["description"],
            "baseline": baseline,
            "accelerated_cold": cold,
            "accelerated_warm": warm,
            "cold_speedup": _ratio(
                baseline["per_lookup_seconds"], cold["per_lookup_seconds"]
            ),
            "warm_speedup": _ratio(
                baseline["per_lookup_seconds"], warm["per_lookup_seconds"]
            ),
        }

    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True))
        return

    header = (
        "scenario\tbaseline_s\taccelerated_cold_s\taccelerated_warm_s\t"
        "cold_speedup\twarm_speedup\tcache_hits\tyear_steps_avoided\t"
        "gate_generations_avoided\tselection_iterations_avoided"
    )
    print(header)
    for name, row in report.items():
        warm_summary = row["accelerated_warm"]["summary"]
        print(
            "\t".join(
                [
                    name,
                    f"{row['baseline']['per_lookup_seconds']:.9f}",
                    f"{row['accelerated_cold']['per_lookup_seconds']:.9f}",
                    f"{row['accelerated_warm']['per_lookup_seconds']:.9f}",
                    f"{row['cold_speedup']:.3f}",
                    f"{row['warm_speedup']:.3f}",
                    str(warm_summary["cache_hits"]),
                    str(warm_summary["year_steps_avoided"]),
                    str(warm_summary["gate_generations_avoided"]),
                    str(warm_summary["selection_iterations_avoided"]),
                ]
            )
        )


if __name__ == "__main__":
    main()
