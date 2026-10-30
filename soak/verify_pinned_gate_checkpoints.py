#!/usr/bin/env python3
"""Bounded pinned-source gate replay from index zero; not full-date certification."""
from __future__ import annotations
import argparse
import hashlib
import importlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time
from types import SimpleNamespace
from typing import Callable

PINNED_SHA = "7cb12bf355461e5a179e0deadb7365689288bf29"
FOUNDATION_DAY = -15055671
MIN_GAP, MAX_GAP = 42, 963

class ProofError(RuntimeError):
    pass

def replay(target: int, max_steps: int, chunk_size: int,
           gap_fn: Callable[[int], int], checkpoints: dict[int, int],
           deadline: float | None = None) -> dict:
    """Use signed global indices; never seed state from checkpoints/oracles."""
    if isinstance(target, bool) or not isinstance(target, int) or target == 0:
        raise ProofError("E_TARGET_INDEX")
    if not 1 <= max_steps <= 32768 or not 1 <= chunk_size <= 1024:
        raise ProofError("E_WORK_BUDGET")
    if checkpoints.get(0) != FOUNDATION_DAY:
        raise ProofError("E_FOUNDATION_CHECKPOINT")
    direction = 1 if target > 0 else -1
    completed, day = 0, FOUNDATION_DAY
    verified, chunk_ends = [0], []
    digest = hashlib.sha256(b"GATE_PROVENANCE_REPLAY_V1\n")
    digest.update(f"0:{FOUNDATION_DAY}\n".encode("ascii"))
    for step in range(1, min(abs(target), max_steps) + 1):
        if deadline is not None and time.monotonic() >= deadline:
            break
        index = direction * step
        gap = gap_fn(index)
        if type(gap) is not int or not MIN_GAP <= gap <= MAX_GAP:
            raise ProofError(f"E_GAP_RANGE_AT_{index}")
        day += direction * gap
        completed = step
        digest.update(f"{index}:{day}:{gap}\n".encode("ascii"))
        if index in checkpoints:
            if day != checkpoints[index]:
                raise ProofError(f"E_CHECKPOINT_MISMATCH_AT_{index}: computed={day}, expected={checkpoints[index]}")
            verified.append(index)
        if step % chunk_size == 0 or step == abs(target):
            chunk_ends.append({"index": index, "day": day,
                               "transcript_sha256": digest.hexdigest()})
    reached = direction * completed
    return {
        "status": ("PASS_GATE_CHECKPOINT_REPLAY_NOT_CERTIFIED"
                   if reached == target and target in checkpoints
                   else "PARTIAL_REPLAY_NOT_CERTIFIED"),
        "start_index": 0, "requested_index": target,
        "reached_index": reached, "reached_day": day,
        "steps": completed, "max_steps": max_steps,
        "chunk_size": chunk_size, "verified_checkpoint_indices": verified,
        "chunk_ends": chunk_ends, "transcript_sha256": digest.hexdigest(),
        "certifiable": False, "independent_gap_oracle": False,
        "full_date_verified": False,
    }

def pinned_source(source_root: Path, expected_sha: str):
    source_root = source_root.resolve()
    source_sha = subprocess.check_output(
        ["git", "-C", str(source_root.parent), "rev-parse", "HEAD"],
        text=True, stderr=subprocess.PIPE, timeout=10).strip()
    if source_sha != PINNED_SHA or source_sha != expected_sha:
        raise ProofError("E_PINNED_SOURCE_SHA")
    path = source_root / "pastafari_calendar" / "final_integration.py"
    if not path.is_file():
        raise ProofError("E_PINNED_MODULE_MISSING")
    sys.path.insert(0, str(source_root))
    module = importlib.import_module("pastafari_calendar.final_integration")
    actual_path = Path(module.__file__).resolve()
    if not actual_path.is_relative_to(source_root):
        raise ProofError("E_PINNED_MODULE_LOCATION")
    if (module.FOUNDATION_DAY_INTEGRATED != FOUNDATION_DAY
            or module.GATE_GAP_CHOICES != 922 or module.GATE_GAP_BASE != 41):
        raise ProofError("E_GATE_CONTRACT_DRIFT")
    checkpoints = dict(module.GATE_CHECKPOINTS_INTEGRATED)
    if len(checkpoints) != len(module.GATE_CHECKPOINTS_INTEGRATED):
        raise ProofError("E_DUPLICATE_CHECKPOINT")
    ctx = SimpleNamespace(acceleration_scars=SimpleNamespace(enabled=False),
                          integration_gate_retry_count=0,
                          integration_gate_questions=0,
                          integration_gate_last_signed_index=0,
                          integration_gate_last_question_day=0,
                          integration_gate_last_gap=0)
    engine = module.IntegratedGateCache(ctx)
    return engine._gap, checkpoints, hashlib.sha256(actual_path.read_bytes()).hexdigest(), ctx

def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--target-index", type=int, default=1024)
    parser.add_argument("--max-steps", type=int, default=1024)
    parser.add_argument("--chunk-size", type=int, default=64)
    parser.add_argument("--timeout-seconds", type=float, default=300)
    parser.add_argument("--source-sha", default=PINNED_SHA)
    parser.add_argument("--evidence", required=True)
    args = parser.parse_args(argv)
    started = time.monotonic()
    report = {"status": "FAIL_REPLAY", "certifiable": False,
              "full_date_verified": False, "source_sha": args.source_sha,
              "checkpoint_trust": "compare_only_not_seed"}
    try:
        if not 1 <= args.timeout_seconds <= 600:
            raise ProofError("E_TIME_BUDGET")
        source = os.environ.get("PASTAFARIAN_PYTHON_SRC")
        if not source:
            raise ProofError("E_SOURCE_ENV_MISSING")
        gap, checkpoints, digest, ctx = pinned_source(Path(source), args.source_sha)
        report["module_sha256"] = digest
        report.update(replay(args.target_index, args.max_steps, args.chunk_size,
                             gap, checkpoints, time.monotonic() + args.timeout_seconds))
        report["gap_questions"] = ctx.integration_gate_questions
        if report["gap_questions"] != report["steps"]:
            raise ProofError("E_GAP_QUESTION_ACCOUNTING")
    except (ProofError, OSError, ImportError, subprocess.SubprocessError, AssertionError) as exc:
        report["status"] = "FAIL_REPLAY"
        report["error"] = str(exc)
    finally:
        report["elapsed_seconds"] = round(time.monotonic() - started, 3)
        path = Path(args.evidence)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
                        encoding="utf-8")
        print(json.dumps({k: v for k, v in report.items() if k != "chunk_ends"},
                         sort_keys=True))
    return 2 if report["status"] == "FAIL_REPLAY" else 0

if __name__ == "__main__":
    raise SystemExit(main())
