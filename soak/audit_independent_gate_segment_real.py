#!/usr/bin/env python3
"""Bounded unseeded real-index differential using an independently derived sauce.

This diagnostic does not alter the Kotlin 8192-gate production bound and does
not certify dates, TABLETS, or full-calendar algorithmic independence.
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
    FOUNDATION, PRODUCTION_SEGMENT_LIMIT, SegmentProofError, locate_unseeded,
)
from independent_sauce_oracle import SauceOracleError, evaluate, gap_from_witness
from verify_pinned_gate_checkpoints import PINNED_SHA, ProofError, pinned_source

STATUS = "PASS_INDEPENDENT_SMALL_INDEX_SEGMENT_DIAGNOSTIC_NOT_CERTIFIED"
MAX_INDEX = 64


class RealSegmentAuditError(ValueError):
    pass


def independent_gap(index: int, *, deadline: float) -> int:
    """A question uses the *signed global gate index*, not a gate date."""
    if type(index) is not int or index == 0 or abs(index) > MAX_INDEX:
        raise RealSegmentAuditError("E_REAL_INDEX_BUDGET")
    return gap_from_witness(evaluate(FOUNDATION, FOUNDATION + index, deadline=deadline))


def audit(oracle_gap, source_gap, *, max_index: int = 32,
          segment_limit: int = 8, deadline: float) -> dict:
    if (type(max_index) is not int or not 1 <= max_index <= MAX_INDEX or
            type(segment_limit) is not int or not 1 <= segment_limit <= 8192):
        raise RealSegmentAuditError("E_REAL_AUDIT_BUDGET")
    if PRODUCTION_SEGMENT_LIMIT != 8192:
        raise RealSegmentAuditError("E_PRODUCTION_BOUND_DRIFT")
    cached: dict[int, int] = {}
    rows = []
    probes = []
    for direction in (-1, 1):
        independent_day = source_day = FOUNDATION
        reference_positions = {0: FOUNDATION}
        for magnitude in range(1, max_index + 1):
            if time.monotonic() >= deadline:
                raise RealSegmentAuditError("E_REAL_AUDIT_DEADLINE")
            index = direction * magnitude
            gap = oracle_gap(index)
            reference = source_gap(index)
            if type(gap) is not int or not 42 <= gap <= 963:
                raise RealSegmentAuditError(f"E_REAL_GAP_RANGE_AT_{index}")
            if type(reference) is not int or not 42 <= reference <= 963:
                raise RealSegmentAuditError(f"E_SOURCE_GAP_RANGE_AT_{index}")
            if gap != reference:
                raise RealSegmentAuditError(f"E_REAL_GAP_MISMATCH_AT_{index}")
            cached[index] = gap
            independent_day += direction * gap
            source_day += direction * reference
            if independent_day != source_day:
                raise RealSegmentAuditError(f"E_REAL_DAY_MISMATCH_AT_{index}")
            reference_positions[index] = source_day
            rows.append((index, gap, independent_day))
            if magnitude in (1, 8, 32, max_index):
                for offset in (0, -direction):
                    target = independent_day + offset
                    proof = locate_unseeded(
                        target, lambda n: cached[n],
                        expected_anchors=reference_positions,
                        segment_limit=segment_limit, total_limit=max_index,
                        deadline=deadline,
                    )
                    if (proof.bracket_index != index or proof.steps != magnitude
                            or not proof.bracket_low <= target <= proof.bracket_high
                            or proof.independent_sauce or proof.certified):
                        raise RealSegmentAuditError(f"E_REAL_BRACKET_AT_{index}")
                    if 0 not in proof.anchor_checks or index not in proof.anchor_checks:
                        raise RealSegmentAuditError(f"E_REAL_ANCHOR_AT_{index}")
                    probes.append({
                        "index": index, "target": target, "steps": proof.steps,
                        "segments": len(proof.segments),
                        "bracket": [proof.bracket_low, proof.bracket_high],
                        "anchor_checks": list(proof.anchor_checks),
                        "terminal_sha256": proof.segments[-1].chain_sha256,
                    })
    canonical = "".join(f"{i}:{g}:{d}\n" for i, g, d in rows)
    return {
        "status": STATUS, "sample_count": len(rows),
        "negative_pairs": max_index, "positive_pairs": max_index,
        "navigation_probes": len(probes),
        "max_index": max_index, "segment_limit": segment_limit,
        "production_gate_limit_unchanged": 8192,
        "trace_sha256": hashlib.sha256(canonical.encode("ascii")).hexdigest(),
        "probes": probes, "checkpoint_seed_used": False,
        "independent_sauce": True, "independent_source_gate": True,
        "full_date_verified": False, "certifiable": False,
        "tablets_verified": False,
    }


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--max-index", type=int, default=32)
    parser.add_argument("--segment-limit", type=int, default=8)
    parser.add_argument("--timeout-seconds", type=int, default=120)
    parser.add_argument("--evidence", type=Path, required=True)
    args = parser.parse_args(argv)
    started = time.monotonic()
    report = {
        "status": "FAIL_INDEPENDENT_SMALL_INDEX_SEGMENT",
        "source_sha": PINNED_SHA, "full_date_verified": False,
        "certifiable": False, "checkpoint_seed_used": False,
        "tablets_verified": False, "production_gate_limit_unchanged": 8192,
    }
    try:
        if not 1 <= args.timeout_seconds <= 180:
            raise RealSegmentAuditError("E_REAL_TIME_BUDGET")
        source = os.environ.get("PASTAFARIAN_PYTHON_SRC")
        if not source:
            raise RealSegmentAuditError("E_PINNED_SOURCE_MISSING")
        source_gap, _, module_digest, source_ctx = pinned_source(Path(source), PINNED_SHA)
        deadline = started + args.timeout_seconds
        report["source_module_sha256"] = module_digest
        report.update(audit(
            lambda i: independent_gap(i, deadline=deadline),
            source_gap, max_index=args.max_index,
            segment_limit=args.segment_limit, deadline=deadline,
        ))
        if source_ctx.integration_gate_questions != report["sample_count"]:
            raise RealSegmentAuditError("E_SOURCE_QUERY_ACCOUNTING")
        report["source_gate_questions"] = source_ctx.integration_gate_questions
    except (RealSegmentAuditError, SauceOracleError, SegmentProofError,
            ProofError, OSError, ValueError, ImportError, AssertionError,
            KeyError) as exc:
        report["status"] = "FAIL_INDEPENDENT_SMALL_INDEX_SEGMENT"
        report["error"] = str(exc)
    finally:
        report["elapsed_seconds"] = round(time.monotonic() - started, 3)
        args.evidence.parent.mkdir(parents=True, exist_ok=True)
        args.evidence.write_text(
            json.dumps(report, sort_keys=True, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(json.dumps({k: v for k, v in report.items() if k != "probes"},
                         sort_keys=True))
    return 0 if report["status"] == STATUS else 2


if __name__ == "__main__":
    raise SystemExit(main())
