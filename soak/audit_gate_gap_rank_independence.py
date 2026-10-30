#!/usr/bin/env python3
"""Bounded, partial-independence audit of gate-gap ring/rank arithmetic.

Does NOT independently verify sauceWithScars or full calendar dates. No certifying mode.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import sys
import time

from verify_pinned_gate_checkpoints import (
    FOUNDATION_DAY, MAX_GAP, MIN_GAP, PINNED_SHA, ProofError, pinned_source,
)

M = (1 << 127) - 1
N = 922
SEAL = 1
LIMIT = (M // N) * N


def accepted_answer_closed_form(first: int, direction: int) -> tuple[int, int]:
    """Return (accepted answer, skip count) WITHOUT iterating the answer ring."""
    if type(first) is not int or not 1 <= first <= M or direction not in (-1, 1):
        raise ProofError("E_ORACLE_RING_INPUT")
    if first <= LIMIT:
        accepted, rejected = first, 0
    elif direction == 1:
        # The ring wraps to one: all values > LIMIT are rejected.
        rejected = M - first + 1
        accepted = 1
    else:
        rejected = first - LIMIT
        accepted = LIMIT
    if not (1 <= accepted <= LIMIT and 0 <= rejected <= M % N):
        raise ProofError("E_ORACLE_ACCEPTANCE")
    return accepted, rejected


def oracle_from_sauce(sauce_result) -> tuple[int, int, int, int]:
    """Rebuild the ring from raw bowls/order; avoid source ring and rank helpers."""
    order = tuple(sauce_result.order_at_drop_46)
    if len(order) != 6 or set(order) != set(range(1, 7)):
        raise ProofError("E_ORACLE_LATCH")
    bowls = sauce_result.bowls
    if any(type(bowls[i]) is not int for i in range(1, 7)):
        raise ProofError("E_ORACLE_BOWLS")
    successor = order[(order.index(1) + 1) % 6]

    def patched(x: int) -> int:
        return ((x - 1) % M) + 1

    first = patched((bowls[1] + SEAL + 181)**2 + 179 * bowls[successor] + SEAL)
    parity_value = patched((first + SEAL + 1 + 193)**2 + 193*first + 197*bowls[6])
    direction = 1 if parity_value % 2 == 1 else -1
    accepted, rejected = accepted_answer_closed_form(first, direction)
    rank = 1 + ((accepted - 1) % N)
    gap = 41 + rank
    if not MIN_GAP <= gap <= MAX_GAP:
        raise ProofError("E_ORACLE_GAP_RANGE")
    return gap, direction, rejected, accepted


def audit_indices() -> tuple[int, ...]:
    # Includes checkpoint boundaries and their neighbors, both signed directions.
    indices = {-1024, -1023, -512, -2, -1, 1, 2, 3, 41, 42, 963,
               1023, 1024, 1025, 2047, 2048, 8191, 8192, 28671, 28672}
    for boundary in range(1024, 28673, 1024):
        indices.update((boundary - 1, boundary, min(28672, boundary + 1)))
    return tuple(sorted(indices))


def audit(gap_fn, sauce_fn, indices: tuple[int, ...], deadline: float) -> dict:
    if not indices or len(indices) > 128 or len(set(indices)) != len(indices):
        raise ProofError("E_ORACLE_WORK_BUDGET")
    if any(type(i) is not int or i == 0 or abs(i) > 28672 for i in indices):
        raise ProofError("E_ORACLE_INDEX_BUDGET")
    rows = []
    for index in indices:
        if time.monotonic() >= deadline:
            raise ProofError(f"E_ORACLE_TIMEOUT_AFTER_{len(rows)}")
        question_day = FOUNDATION_DAY + index
        # Shared sauce is explicitly a scope limitation; nothing else from the
        # Python gate/rank implementation is used to calculate the oracle gap.
        raw = sauce_fn(FOUNDATION_DAY, question_day)
        independent_gap, direction, rejected, accepted = oracle_from_sauce(raw)
        original_gap = gap_fn(index)
        row = {"index": index, "question_day": question_day,
               "oracle_gap": independent_gap, "original_gap": original_gap,
               "direction": direction, "rejected": rejected,
               "accepted": accepted}
        rows.append(row)
        if independent_gap != original_gap:
            raise ProofError(f"E_GATE_RANK_MISMATCH_AT_{index}: {independent_gap}!={original_gap}")
    canonical = "".join(f'{x["index"]}:{x["oracle_gap"]}:{x["direction"]}:{x["rejected"]}\n' for x in rows)
    return {"status": "PASS_PARTIAL_GATE_RANK_DIAGNOSTIC_NOT_CERTIFIED",
            "sample_count": len(rows), "positive": sum(x["index"] > 0 for x in rows),
            "negative": sum(x["index"] < 0 for x in rows),
            "nonzero_rejections": sum(x["rejected"] > 0 for x in rows),
            "trace_sha256": hashlib.sha256(canonical.encode("ascii")).hexdigest(),
            "samples": rows}


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-sha", default=PINNED_SHA)
    parser.add_argument("--timeout-seconds", type=int, default=180)
    parser.add_argument("--evidence", type=Path, required=True)
    args = parser.parse_args(argv)
    started = time.monotonic()
    report = {"status": "FAIL_PARTIAL_GATE_RANK_DIAGNOSTIC", "source_sha": args.source_sha,
              "independent_ring_rank": True, "independent_sauce": False,
              "independent_full_gate_gap": False, "certifiable": False,
              "full_date_verified": False, "checkpoint_seed_used": False}
    try:
        if not 1 <= args.timeout_seconds <= 300:
            raise ProofError("E_ORACLE_TIME_BUDGET")
        source = os.environ.get("PASTAFARIAN_PYTHON_SRC")
        if not source:
            raise ProofError("E_SOURCE_ENV_MISSING")
        original_gap, checkpoints, module_sha, ctx = pinned_source(Path(source), args.source_sha)
        module = sys.modules["pastafari_calendar.final_integration"]
        if checkpoints.get(28672) != -674161 or checkpoints.get(-1024) != -15566968:
            raise ProofError("E_AUDITED_CHECKPOINT_SET_DRIFT")
        report["module_sha256"] = module_sha
        report.update(audit(original_gap, module.sauceWithScars, audit_indices(),
                            time.monotonic() + args.timeout_seconds))
        if ctx.integration_gate_questions != report["sample_count"]:
            raise ProofError("E_ORACLE_QUESTION_ACCOUNTING")
    except (ProofError, OSError, ImportError, AssertionError, KeyError, ValueError) as exc:
        report["status"] = "FAIL_PARTIAL_GATE_RANK_DIAGNOSTIC"
        report["error"] = str(exc)
    finally:
        report["elapsed_seconds"] = round(time.monotonic() - started, 3)
        args.evidence.parent.mkdir(parents=True, exist_ok=True)
        args.evidence.write_text(json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        print(json.dumps({k: v for k, v in report.items() if k != "samples"}, sort_keys=True))
    return 0 if report["status"] == "PASS_PARTIAL_GATE_RANK_DIAGNOSTIC_NOT_CERTIFIED" else 2


if __name__ == "__main__":
    raise SystemExit(main())
