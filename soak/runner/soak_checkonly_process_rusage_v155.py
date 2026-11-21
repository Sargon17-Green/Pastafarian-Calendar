#!/usr/bin/env python3
"""v155: real Linux process-level rusage for exactly two source CHECK-ONLY probes.

Each invocation with --engine is a fresh Python supervisor that waits on one
v042 direct child. RUSAGE_CHILDREN peak RSS is per child ONLY if this fresh
supervisor has never reaped a prior child. It must start with ru_maxrss == 0.
One process per command; two sequential commands via GitHub Actions.

Unlike the static v154 audit, source import/require happens in the real child
and CPU/wall/maxRSS are measured. Unlike any native date test, both invocations
are --check-only and must never compute F(c,t), run a full year or authorize
restarting original Soak. No Windows or user machine process is touched.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import resource
import time

from native_execution_receipt_v038 import canonical
from native_raw_pair_gate_v018 import sha
from supervised_original_source_preflight_v042 import (
    ADAPTERS, SCHEMA as PROCESS_SCHEMA, _capture_one, _admit,
    PYTHON_COMMIT, JS_COMMIT
)
from supervised_process_observation_v041 import _durable_exclusive, _read_limited

SCHEMA = "PASTAFARI_SOAK_CHECKONLY_PROCESS_RUSAGE_V155/1"
SUMMARY_SCHEMA = "PASTAFARI_SOAK_CHECKONLY_PROCESS_RUSAGE_SUMMARY_V155/1"
ENGINES = {"REF-41": PYTHON_COMMIT, "REF-24": JS_COMMIT}
MAX_PEAK_RSS_KIB = 512 * 1024
MAX_CHILD_CPU_SECONDS = 12.0
MAX_OBSERVED_WALL_SECONDS = 30.0
HEX = __import__("re").compile(r"[0-9a-f]{64}\Z")
SINGLE_PROCESS_ONLY = "FRESH_ONE_WAITED_CHILD_PER_SUPERVISOR_PROCESS"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def no_duplicate_pairs(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, "duplicate evidence JSON key: " + key)
        result[key] = value
    return result


def decode_canonical_bytes(data: bytes) -> dict:
    try:
        value = json.loads(data.decode("utf-8"), object_pairs_hook=no_duplicate_pairs,
                           parse_constant=lambda x: (_ for _ in ()).throw(
                               ValueError("unrecognized constant " + x)))
    except (UnicodeError, TypeError) as exc:
        raise ValueError("invalid evidence JSON") from exc
    require(type(value) is dict and canonical(value) == data,
            "evidence must be exact canonical JSON bytes")
    return value


def run_engine(source_root: Path, evidence_root: Path, engine_id: str) -> dict:
    """Run v042 one pinned --check-only child and record measurable OS usage."""
    require(engine_id in ENGINES, "unsupported original reference engine")
    _admit(evidence_root)
    source_root = source_root.resolve(strict=True)
    evidence_root = evidence_root.resolve(strict=True)
    require(evidence_root != source_root
            and evidence_root not in source_root.parents
            and source_root not in evidence_root.parents,
            "evidence and source trees overlap")
    report_path = evidence_root / (engine_id + "-rusage-v155.json")
    require(not report_path.exists() and not (evidence_root / engine_id).exists(),
            "write-once check-only evidence already exists")
    before = resource.getrusage(resource.RUSAGE_CHILDREN)
    require(before.ru_maxrss == 0
            and before.ru_utime == 0.0 and before.ru_stime == 0.0,
            "supervisor has already reaped children; cannot claim per-child RSS")
    started = time.monotonic_ns()
    original = _capture_one(evidence_root, source_root, engine_id)
    elapsed_ns = time.monotonic_ns() - started
    after = resource.getrusage(resource.RUSAGE_CHILDREN)
    rusage = {
        "elapsed_supervisor_plus_child_wall_ns": elapsed_ns,
        "waited_child_user_cpu_seconds": round(after.ru_utime - before.ru_utime, 6),
        "waited_child_system_cpu_seconds": round(after.ru_stime - before.ru_stime, 6),
        "waited_child_peak_rss_kib_linux": after.ru_maxrss,
        "waited_child_minor_faults": after.ru_minflt - before.ru_minflt,
        "waited_child_major_faults": after.ru_majflt - before.ru_majflt,
        "rusage_origin": "resource.getrusage(RUSAGE_CHILDREN) in fresh one-child supervisor",
        "rss_unit": "Linux ru_maxrss kilobytes, not address-space bytes",
        "includes_child_source_import_initialization": True,
        "isolates_module_import_cost_from_interpreter_startup": False,
    }
    require(original["status"] ==
            "ORIGINAL_PINNED_SOURCE_CHECK_ONLY_PROCESS_OBSERVED_NO_DATE_CALLS",
            "v042 did not attest zero-date check-only child")
    require(original["engine_id"] == engine_id and
            original["source_commit"] == ENGINES[engine_id] and
            original["exit_code"] == 0 and
            original["converter_calls"] == 0 and
            original["os_stdout_is_native_raw_date_data"] is False,
            "unexpected v042 native date execution or identity")
    require(elapsed_ns > 0
            and elapsed_ns <= int(MAX_OBSERVED_WALL_SECONDS * 1_000_000_000),
            "observed wall time missing or over CI check-only admission budget")
    require(type(after.ru_maxrss) is int
            and 0 < after.ru_maxrss <= MAX_PEAK_RSS_KIB,
            "observed child peak RSS outside bounded Linux CI check-only budget")
    require(rusage["waited_child_user_cpu_seconds"] >= 0
            and rusage["waited_child_system_cpu_seconds"] >= 0
            and sum((rusage["waited_child_user_cpu_seconds"],
                     rusage["waited_child_system_cpu_seconds"])) < MAX_CHILD_CPU_SECONDS,
            "observed child CPU usage outside bounded Linux CI check-only budget")
    require(rusage["waited_child_minor_faults"] >= 0
            and rusage["waited_child_major_faults"] >= 0,
            "invalid Linux waited-child page fault counters")
    raw = (evidence_root / engine_id / "process-evidence.json").read_bytes()
    require(decode_canonical_bytes(raw) == original,
            "original process receipt bytes changed while collecting usage")
    result = {
        "schema": SCHEMA,
        "status": "MEASURED_REAL_CHECKONLY_PROCESS_NOT_NATIVE_DATE_EXECUTION",
        "engine_id": engine_id,
        "source_commit": ENGINES[engine_id],
        "source_process_evidence_sha256": sha(raw),
        "source_process_pid": original["pid"],
        "source_process_creation_id": original["process_creation_id"],
        "runtime_executable_sha256": original["runtime_executable_sha256"],
        "transport_adapter_sha256": original["transport_adapter_sha256"],
        "native_output_stdout_sha256": original["stdout_sha256"],
        "linux_resource_measurements": rusage,
        "resource_bounds": {
            "peak_rss_kib_max": MAX_PEAK_RSS_KIB,
            "child_cpu_seconds_max_exclusive": MAX_CHILD_CPU_SECONDS,
            "supervisor_plus_child_wall_seconds_max": MAX_OBSERVED_WALL_SECONDS,
        },
        "rusage_identity_scope": SINGLE_PROCESS_ONLY,
        "v042_process_exit_code": 0,
        "observed_source_import_checkonly": True,
        "observed_native_date_Fct_calls": 0,
        "source_import_side_effects_exhaustively_proven": False,
        "runtime_cost_without_interpreter_startup_proven": False,
        "independent_source_algorithms_certified": 0,
        "original_full_years_certified": 0,
        "halt_new_native_soak_dispatch": True,
        "main_changes_permitted": False,
    }
    _durable_exclusive(report_path, canonical(result))
    return result


def verify_engine(evidence_root: Path, engine_id: str) -> dict:
    require(engine_id in ENGINES, "invalid engine identity")
    report = decode_canonical_bytes(
        (evidence_root / (engine_id + "-rusage-v155.json")).read_bytes()
    )
    require(report.get("schema") == SCHEMA
            and report.get("status") ==
                "MEASURED_REAL_CHECKONLY_PROCESS_NOT_NATIVE_DATE_EXECUTION"
            and report.get("engine_id") == engine_id
            and report.get("source_commit") == ENGINES[engine_id],
            "usage receipt identity/schema not exact")
    require(report.get("rusage_identity_scope") == SINGLE_PROCESS_ONLY
            and report.get("observed_source_import_checkonly") is True
            and type(report.get("observed_native_date_Fct_calls")) is int
            and report["observed_native_date_Fct_calls"] == 0
            and report.get("source_import_side_effects_exhaustively_proven") is False
            and report.get("runtime_cost_without_interpreter_startup_proven") is False
            and report.get("original_full_years_certified") == 0
            and report.get("independent_source_algorithms_certified") == 0
            and report.get("halt_new_native_soak_dispatch") is True
            and report.get("main_changes_permitted") is False,
            "resource receipt tried to promote unverified native/original claims")
    source = decode_canonical_bytes(
        (evidence_root / engine_id / "process-evidence.json").read_bytes()
    )
    raw = (evidence_root / engine_id / "process-evidence.json").read_bytes()
    require(report.get("source_process_evidence_sha256") == sha(raw)
            and source.get("schema") == PROCESS_SCHEMA
            and source.get("status") ==
                "ORIGINAL_PINNED_SOURCE_CHECK_ONLY_PROCESS_OBSERVED_NO_DATE_CALLS"
            and source.get("engine_id") == engine_id
            and source.get("source_commit") == ENGINES[engine_id]
            and source.get("exit_code") == 0
            and type(source.get("converter_calls")) is int
            and source["converter_calls"] == 0
            and source.get("os_stdout_is_native_raw_date_data") is False
            and source.get("actual_native_date_execution_proven") is False
            and source.get("full_original_soak_years_approved") == 0
            and source.get("pid") == report.get("source_process_pid")
            and source.get("process_creation_id") ==
                report.get("source_process_creation_id")
            and source.get("runtime_executable_sha256") ==
                report.get("runtime_executable_sha256")
            and source.get("transport_adapter_sha256") ==
                report.get("transport_adapter_sha256")
            and len(source.get("launch_argv", [])) > 3
            and source["launch_argv"][-1] == "--check-only"
            and "--first-target-day" not in source["launch_argv"]
            and "--calculation-day" not in source["launch_argv"],
            "rusage not bound to exact v042 zero-native-date source process receipt")
    native_stdout = _read_limited(evidence_root / engine_id / "os-stdout.log")
    native_stderr = _read_limited(evidence_root / engine_id / "os-stderr.log")
    require(sha(native_stdout) == source.get("stdout_sha256")
            and sha(native_stderr) == source.get("stderr_sha256")
            and sha(native_stdout) == report.get("native_output_stdout_sha256")
            and native_stdout.endswith(b"\n") and
            native_stdout.count(b"\n") == 1,
            "raw OS stdout/stderr not bound to observed process receipt")
    stdout = json.loads(native_stdout.decode("utf-8"),
                        object_pairs_hook=no_duplicate_pairs)
    require(stdout.get("status") == "SOURCE_AND_TRANSPORT_PREFLIGHT_ONLY"
            and stdout.get("engine") == engine_id
            and type(stdout.get("converter_calls")) is int
            and stdout["converter_calls"] == 0
            and set(stdout) == {"status", "engine", "sha256", "converter_calls"},
            "check-only stdout claims or format invalid")
    usage = report["linux_resource_measurements"]
    require(type(usage) is dict and
            type(usage.get("waited_child_peak_rss_kib_linux")) is int and
            type(usage.get("elapsed_supervisor_plus_child_wall_ns")) is int and
            usage.get("rusage_origin") ==
            "resource.getrusage(RUSAGE_CHILDREN) in fresh one-child supervisor"
            and usage.get("rss_unit") ==
            "Linux ru_maxrss kilobytes, not address-space bytes"
            and usage.get("includes_child_source_import_initialization") is True
            and usage.get("isolates_module_import_cost_from_interpreter_startup") is False,
            "rusage source/unit/isolation disclosure not exact")
    bounds = report["resource_bounds"]
    require(bounds == {
        "peak_rss_kib_max": MAX_PEAK_RSS_KIB,
        "child_cpu_seconds_max_exclusive": MAX_CHILD_CPU_SECONDS,
        "supervisor_plus_child_wall_seconds_max": MAX_OBSERVED_WALL_SECONDS
    }, "unexpected check-only resource caps")
    require(0 < usage["waited_child_peak_rss_kib_linux"] <= MAX_PEAK_RSS_KIB
            and 0 < usage["elapsed_supervisor_plus_child_wall_ns"]
            <= MAX_OBSERVED_WALL_SECONDS * 1_000_000_000,
            "OS wall or memory usage invalid")
    for field in ("waited_child_user_cpu_seconds", "waited_child_system_cpu_seconds"):
        val = usage[field]
        require(type(val) in (int, float) and 0 <= val < MAX_CHILD_CPU_SECONDS,
                "invalid CPU rusage sample")
    require(sum(usage[x] for x in ("waited_child_user_cpu_seconds",
                                  "waited_child_system_cpu_seconds"))
            < MAX_CHILD_CPU_SECONDS,
            "process CPU cap exceeded")
    for field in ("waited_child_minor_faults", "waited_child_major_faults"):
        require(type(usage[field]) is int and usage[field] >= 0,
                "invalid fault count")
    return report


def summarize(evidence_root: Path) -> dict:
    records = [verify_engine(evidence_root, eid) for eid in ENGINES]
    return {
        "schema": SUMMARY_SCHEMA,
        "status": "TWO_LINUX_ORIGINAL_SOURCE_IMPORT_CHECKONLY_RESOURCE_MEASUREMENTS_PASS",
        "engine_ids": list(ENGINES),
        "source_commits": [x["source_commit"] for x in records],
        "pinned_process_receipts_sha256": [
            x["source_process_evidence_sha256"] for x in records
        ],
        "measured_per_engine": {
            x["engine_id"]: x["linux_resource_measurements"] for x in records
        },
        "measured_peak_rss_kib_max": max(
            x["linux_resource_measurements"]["waited_child_peak_rss_kib_linux"]
            for x in records
        ),
        "original_source_import_processes_observed": 2,
        "original_native_date_Fct_calls": 0,
        "original_soak_years_certified": 0,
        "independent_original_algorithms_certified": 0,
        "module_import_side_effect_freedom_proven": False,
        "resource_benchmark_stable_across_os_or_machine": False,
        "halt_new_native_soak_dispatch": True,
        "main_changes_permitted": False,
    }


def main() -> int:
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument("--sources-root", type=Path)
    cli.add_argument("--evidence-root", type=Path, required=True)
    cli.add_argument("--engine", choices=tuple(ENGINES))
    cli.add_argument("--verify-both", action="store_true")
    args = cli.parse_args()
    require(args.engine is not None and args.sources_root is not None
            if not args.verify_both
            else args.engine is None and args.sources_root is None,
            "choose either --engine+--sources-root or --verify-both")
    if args.verify_both:
        report = summarize(args.evidence_root)
        _durable_exclusive(args.evidence_root / "v155-summary.json", canonical(report))
    else:
        report = run_engine(args.sources_root, args.evidence_root, args.engine)
    print(json.dumps(report, sort_keys=True, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
