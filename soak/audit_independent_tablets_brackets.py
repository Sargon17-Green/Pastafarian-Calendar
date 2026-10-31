#!/usr/bin/env python3
"""Bounded unseeded TABLETS±1 bracket audit, independent structural gate oracle.

This is a diagnostic, not a production change, date conversion, or certification.
Every gate is recomputed from FOUNDATION using a signed GLOBAL index, with no
checkpoint used as a seed. Source gate gaps are comparison-only.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import sys
import time

from audit_gate_segment_navigation import (
    FOUNDATION, TABLETS, GAP_MIN, GAP_MAX, PRODUCTION_SEGMENT_LIMIT,
    PROOF_TOTAL_LIMIT,
)
from independent_sauce_oracle import SauceOracleError, evaluate, gap_from_witness
from verify_pinned_gate_checkpoints import PINNED_SHA, ProofError, pinned_source

TARGETS = (TABLETS - 1, TABLETS, TABLETS + 1)
STATUS = "PASS_TABLETS_INDEPENDENT_UNSEEDED_BRACKETS_NOT_CERTIFIED"


class TabletsAuditError(ValueError):
    pass


def audit_tablets(oracle_gap, source_gap, *, origin=FOUNDATION, targets=TARGETS,
                  max_questions=PROOF_TOTAL_LIMIT, segment_limit=4096,
                  deadline=None):
    """A single forward pass brackets all three days; O(N) queries, O(N/S) space."""
    if type(origin) is not int or (type(targets) is not tuple or len(targets) != 3
            or any(type(t) is not int for t in targets)
            or not (origin < targets[0] < targets[1] < targets[2])):
        raise TabletsAuditError("E_TABLETS_TARGET_CONTRACT")
    if (type(max_questions) is not int or not 1 <= max_questions <= PROOF_TOTAL_LIMIT
            or type(segment_limit) is not int
            or not 1 <= segment_limit <= PRODUCTION_SEGMENT_LIMIT):
        raise TabletsAuditError("E_TABLETS_BUDGET")
    if PRODUCTION_SEGMENT_LIMIT != 8192:
        raise TabletsAuditError("E_PRODUCTION_BOUND_DRIFT")
    if (targets[2] - origin + GAP_MAX - 1) // GAP_MAX > max_questions:
        raise TabletsAuditError("E_TABLETS_GEOMETRY_BUDGET")

    trace = hashlib.sha256(b"TABLETS_INDEPENDENT_UNSEEDED_GATE_V1\n")
    trace.update(f"origin:{origin}\n".encode("ascii"))
    segment_hash = hashlib.sha256(b"TABLETS_SEGMENTS_V1\n").hexdigest()
    position = origin
    segment_start_day = origin
    next_target = 0
    brackets = []
    segments = []
    for index in range(1, max_questions + 1):
        if deadline is not None and time.monotonic() >= deadline:
            raise TabletsAuditError("E_TABLETS_DEADLINE")
        independent = oracle_gap(index)
        reference = source_gap(index)
        if type(independent) is not int or not GAP_MIN <= independent <= GAP_MAX:
            raise TabletsAuditError(f"E_INDEPENDENT_RANGE_AT_{index}")
        if type(reference) is not int or not GAP_MIN <= reference <= GAP_MAX:
            raise TabletsAuditError(f"E_SOURCE_RANGE_AT_{index}")
        if independent != reference:
            raise TabletsAuditError(f"E_TABLETS_MISMATCH_AT_{index}")
        previous = position
        position += independent
        trace.update(f"{index}:{independent}:{position}\n".encode("ascii"))
        while next_target < len(targets) and targets[next_target] <= position:
            target = targets[next_target]
            if not previous <= target <= position:
                raise TabletsAuditError(f"E_TABLETS_BRACKET_AT_{index}")
            brackets.append({
                "target_day": target, "gate_index": index,
                "bracket_low": previous, "bracket_high": position,
                "from_foundation": index,
            })
            next_target += 1
        if index % segment_limit == 0 or next_target == len(targets):
            entry = (f"{segment_hash}|{index - ((index - 1) % segment_limit)}|"
                     f"{index}|{segment_start_day}|{position}\n")
            segment_hash = hashlib.sha256(entry.encode("ascii")).hexdigest()
            segments.append({
                "end_index": index, "end_day": position,
                "segment_sha256": segment_hash,
            })
            segment_start_day = position
        if next_target == len(targets):
            return {
                "status": STATUS,
                "origin": origin, "targets": list(targets),
                "brackets": brackets, "questions": index,
                "max_questions": max_questions, "segment_limit": segment_limit,
                "segments": segments, "segment_count": len(segments),
                "trace_sha256": trace.hexdigest(),
                "terminal_segment_sha256": segment_hash,
                "checkpoint_seed_used": False,
                "production_gate_limit_unchanged": 8192,
                "full_date_verified": False, "certifiable": False,
                "tablets_bracket_verified": True,
                "tablets_date_components_verified": False,
            }
    raise TabletsAuditError("E_TABLETS_QUERY_BUDGET")


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--max-questions", type=int, default=PROOF_TOTAL_LIMIT)
    p.add_argument("--segment-limit", type=int, default=4096)
    p.add_argument("--timeout-seconds", type=int, default=480)
    p.add_argument("--evidence", type=Path, required=True)
    args = p.parse_args(argv)
    started = time.monotonic()
    report = {
        "status": "FAIL_TABLETS_INDEPENDENT_UNSEEDED",
        "source_sha": PINNED_SHA, "full_date_verified": False,
        "certifiable": False, "checkpoint_seed_used": False,
        "tablets_bracket_verified": False,
        "production_gate_limit_unchanged": 8192,
    }
    try:
        if not 1 <= args.timeout_seconds <= 600:
            raise TabletsAuditError("E_TABLETS_TIME_BUDGET")
        root = os.environ.get("PASTAFARIAN_PYTHON_SRC")
        if not root:
            raise TabletsAuditError("E_PINNED_SOURCE_MISSING")
        source_gap, checkpoints, source_digest, context = pinned_source(Path(root), PINNED_SHA)
        if checkpoints.get(0) != FOUNDATION:
            raise TabletsAuditError("E_PINNED_ORIGIN")
        report["source_module_sha256"] = source_digest
        deadline = started + args.timeout_seconds
        def oracle_gap(index):
            return gap_from_witness(evaluate(FOUNDATION, FOUNDATION + index,
                                             deadline=deadline))
        report.update(audit_tablets(
            oracle_gap, source_gap, max_questions=args.max_questions,
            segment_limit=args.segment_limit, deadline=deadline,
        ))
        if context.integration_gate_questions != report["questions"]:
            raise TabletsAuditError("E_SOURCE_QUERY_ACCOUNTING")
        report["source_gate_questions"] = context.integration_gate_questions
    except (TabletsAuditError, SauceOracleError, ProofError,
            OSError, ValueError, ImportError, AssertionError, KeyError) as exc:
        report["status"] = "FAIL_TABLETS_INDEPENDENT_UNSEEDED"
        report["error"] = str(exc)
    finally:
        report["elapsed_seconds"] = round(time.monotonic() - started, 3)
        args.evidence.parent.mkdir(parents=True, exist_ok=True)
        args.evidence.write_text(json.dumps(report, ensure_ascii=False,
                                            sort_keys=True, indent=2) + "\n",
                                 encoding="utf-8")
        print(json.dumps({k: v for k, v in report.items()
                          if k not in ("brackets", "segments")}, sort_keys=True))
    return 0 if report["status"] == STATUS else 2


if __name__ == "__main__":
    raise SystemExit(main())
