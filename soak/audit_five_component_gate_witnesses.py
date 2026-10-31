#!/usr/bin/env python3
"""Bounded independent gate-boundary FIVE-field differential near FOUNDATION.

A diagnostic only: Kotlin production bridge versus separately pinned Python.
Gate witnesses are constructed from a structurally independent sauce oracle,
then compared with pinned-source gaps. This is NOT a TABLETS full-date audit;
the production 8192-gate limit and all certification guards stay unchanged.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import time

FOUNDATION = -15055671
MIN_GAP, MAX_GAP = 42, 963
PINNED_SHA = "7cb12bf355461e5a179e0deadb7365689288bf29"
FIELDS = ("year_number", "cutlet_index", "day_in_cutlet", "month_index", "day_in_month")
STATUS = "PASS_INDEPENDENT_GATE_WITNESS_FIVE_FIELDS_NOT_CERTIFIED"


class WitnessError(ValueError):
    pass


def make_witnesses(oracle_gap, pinned_gap, *, foundation=FOUNDATION, deadline=None):
    """Two signed global gate indices, then three days around each boundary.

    Gate index is a globally signed index, never a calendar-day input to sauce.
    Returns (pairs, metadata); checkpoints are NEVER used as navigation seeds.
    """
    if type(foundation) is not int:
        raise WitnessError("E_WITNESS_ORIGIN_TYPE")
    pairs = [(foundation, foundation)]
    metadata = []
    for index in (-1, 1):
        if deadline is not None and time.monotonic() >= deadline:
            raise WitnessError("E_WITNESS_DEADLINE")
        independent = oracle_gap(index)
        source = pinned_gap(index)
        if type(independent) is not int or not MIN_GAP <= independent <= MAX_GAP:
            raise WitnessError(f"E_WITNESS_INDEPENDENT_RANGE_AT_{index}")
        if type(source) is not int or not MIN_GAP <= source <= MAX_GAP:
            raise WitnessError(f"E_WITNESS_SOURCE_RANGE_AT_{index}")
        if independent != source:
            raise WitnessError(f"E_WITNESS_GATE_MISMATCH_AT_{index}")
        day = foundation + (1 if index > 0 else -1) * independent
        metadata.append({"gate_index": index, "gap": independent, "gate_day": day})
        for offset in (-1, 0, 1):
            pairs.append((foundation, day + offset))
    if len(pairs) != 7 or len(set(pairs)) != 7:
        raise WitnessError("E_WITNESS_CASE_COUNT")
    return pairs, metadata


def compare_five_fields(pairs, kotlin, python):
    """Compare ALL five canonical components, fail at first unequal field."""
    if not pairs or len(pairs) != len(kotlin) or len(pairs) != len(python):
        raise WitnessError("E_WITNESS_ROW_COUNT")
    for row, (left, right) in enumerate(zip(kotlin, python)):
        if len(left) != len(FIELDS) or len(right) != len(FIELDS):
            raise WitnessError(f"E_WITNESS_FIELD_COUNT_AT_{row}")
        if tuple(left) != tuple(right):
            mismatches = [name for name, a, b in zip(FIELDS, left, right) if a != b]
            return {"index": row, "pair": list(pairs[row]),
                    "fields": mismatches,
                    "kotlin": dict(zip(FIELDS, left)),
                    "python": dict(zip(FIELDS, right))}
    return None


def save_evidence(path: Path, report: dict):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".partial")
    temporary.write_text(json.dumps(report, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    temporary.replace(path)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--kotlin-command", required=True)
    parser.add_argument("--python-command", required=True)
    parser.add_argument("--timeout-seconds", type=int, default=120)
    parser.add_argument("--total-seconds", type=int, default=540)
    parser.add_argument("--evidence", type=Path, required=True)
    args = parser.parse_args(argv)
    started = time.monotonic()
    report = {"status": "FAIL_FIVE_FIELD_GATE_WITNESSES", "source_sha": PINNED_SHA,
              "checkpoints_used_as_seeds": False, "independent_gate_oracle": True,
              "production_gate_limit_unchanged": 8192, "cases": 0,
              "completed": 0, "certifiable": False,
              "full_date_certified": False, "tablets_five_fields_verified": False,
              "error": None, "mismatch": None}
    exit_code = 3
    try:
        if not 1 <= args.timeout_seconds <= 180 or not 1 <= args.total_seconds <= 600:
            raise WitnessError("E_WITNESS_BUDGET")
        source = os.environ.get("PASTAFARIAN_PYTHON_SRC")
        if not source:
            raise WitnessError("E_WITNESS_PINNED_SOURCE_MISSING")
        from verify_pinned_gate_checkpoints import pinned_source
        from independent_sauce_oracle import evaluate, gap_from_witness
        from post55_differential import invoke
        deadline = started + args.total_seconds
        source_gap, checkpoints, source_digest, context = pinned_source(Path(source), PINNED_SHA)
        if checkpoints.get(0) != FOUNDATION:
            raise WitnessError("E_WITNESS_PINNED_FOUNDATION")
        report["source_module_sha256"] = source_digest
        def independent_gap(index):
            return gap_from_witness(evaluate(FOUNDATION, FOUNDATION + index, deadline=deadline))
        pairs, gates = make_witnesses(independent_gap, source_gap, deadline=deadline)
        if context.integration_gate_questions != 2:
            raise WitnessError("E_WITNESS_SOURCE_QUERY_ACCOUNTING")
        report["gates"] = gates
        report["cases"] = len(pairs)
        report["case_sha256"] = hashlib.sha256(
            "".join(f"{c}\t{t}\n" for c,t in pairs).encode("ascii")
        ).hexdigest()
        for case_index, pair in enumerate(pairs):
            observed = {}
            for label, command in (("KOTLIN", args.kotlin_command),
                                   ("PYTHON", args.python_command)):
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    raise WitnessError("E_WITNESS_DEADLINE")
                observed[label] = invoke(
                    command, [pair], min(args.timeout_seconds, remaining), label
                )
            mismatch = compare_five_fields(
                [pair], observed["KOTLIN"], observed["PYTHON"]
            )
            report["completed"] = case_index + 1
            if mismatch is not None:
                mismatch["index"] = case_index
                report["mismatch"] = mismatch
                report["status"] = "FAIL_FIVE_FIELD_MISMATCH"
                exit_code = 2
                break
        else:
            report["status"] = STATUS
            report["verified_fields"] = list(FIELDS)
            exit_code = 0
    except (WitnessError, OSError, RuntimeError, ValueError, ImportError,
            AssertionError, KeyError) as exc:
        report["error"] = str(exc)
        exit_code = 3
    finally:
        report["elapsed_seconds"] = round(time.monotonic() - started, 3)
        save_evidence(args.evidence, report)
        print(json.dumps({k:v for k,v in report.items() if k not in ("gates",)},
                         sort_keys=True))
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
