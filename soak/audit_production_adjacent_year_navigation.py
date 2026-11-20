#!/usr/bin/env python3
"""Compare Kotlin production adjacent-year navigation with an unseeded independent oracle.

This is a bounded structural diagnostic around FOUNDATION. It is not a full-date,
TABLETS, or algorithmic-independence certification.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time

from independent_year_geometry_oracle import (
    FOUNDATION, GateLedger, IndependentYearGeometry, YearGeometryError,
    independent_sauce_selector,
)
from independent_sauce_oracle import SauceOracleError, evaluate, gap_from_witness
from independent_date_combinatorics import DateCombinatoricsError

MAX_PRODUCTION_GATE_INDEX = 8192
ORACLE_HALF_WIDTH = 280
GATE_COUNT = ORACLE_HALF_WIDTH * 2 + 1
EXPECTED_INTERVAL_CASES = 18
EXPECTED_INTERIOR_CASES = 15
EXPECTED_ROWS = GATE_COUNT + 11 + EXPECTED_INTERVAL_CASES + EXPECTED_INTERIOR_CASES
EXPECTED_INTERIOR_KEYS = {(year, ordinal) for year in range(4998, 5003) for ordinal in (1, 2, 3)}
INTERVAL_KINDS = ("AFTER_OPEN", "AT_CLOSE", "AT_OPEN", "AFTER_CLOSE")
EXPECTED_INTERVAL_KEYS = {
    (year, kind) for year in range(4998, 5003)
    for kind in INTERVAL_KINDS
    if (kind != "AT_OPEN" or year > 4998)
    and (kind != "AFTER_CLOSE" or year < 5002)
}
PASS = "PASS_BOUNDED_REAL_PRODUCTION_INTERIOR_TARGETS_NOT_CERTIFIED"
CANONICAL = re.compile(r"(?:0|-?[1-9][0-9]*)\Z")


class AuditError(ValueError):
    pass


def number(value: str) -> int:
    if not isinstance(value, str) or not CANONICAL.fullmatch(value):
        raise AuditError("E_NONCANONICAL_INTEGER")
    return int(value)


def parse_transcript(raw: str) -> dict:
    if not isinstance(raw, str) or not raw.endswith("\n") or "\r" in raw:
        raise AuditError("E_TRANSCRIPT_FORMAT")
    lines = raw.splitlines()
    if len(lines) != EXPECTED_ROWS:
        raise AuditError("E_TRANSCRIPT_ROW_COUNT")

    observed = {
        "GATE": {},
        "INTERVAL": {},
        "INTERIOR_YEAR": {},
        "YEAR": None,
        "NEXT": None,
        "PREVIOUS": None,
        "NEXT2": None,
        "PREVIOUS2": None,
        "FIND_FORWARD": None,
        "FIND_BACKWARD": None,
        "FIND_FORWARD2": None,
        "FIND_BACKWARD2": None,
        "PRODUCTION_GATE_LIMIT": None,
        "PRODUCTION_EXPANDED_GATES": None,
    }
    for line in lines:
        columns = line.split("\t")
        kind = columns[0]
        if kind == "GATE" and len(columns) == 3:
            index, day = map(number, columns[1:])
            if not -ORACLE_HALF_WIDTH <= index <= ORACLE_HALF_WIDTH:
                raise AuditError("E_GATE_INDEX_RANGE")
            if index in observed["GATE"]:
                raise AuditError("E_DUPLICATE_GATE")
            observed["GATE"][index] = day
        elif kind == "INTERVAL" and len(columns) == 9:
            year_number = number(columns[1])
            endpoint_kind = columns[2]
            if endpoint_kind not in INTERVAL_KINDS:
                raise AuditError("E_INTERVAL_KIND")
            target = number(columns[3])
            resolved = tuple(map(number, columns[4:]))
            key = (year_number, endpoint_kind)
            if key in observed["INTERVAL"]:
                raise AuditError("E_DUPLICATE_INTERVAL_CASE")
            observed["INTERVAL"][key] = (target, resolved)
        elif kind == "INTERIOR_YEAR" and len(columns) == 9:
            year_number, ordinal, target = map(number, columns[1:4])
            resolved = tuple(map(number, columns[4:]))
            if ordinal not in (1, 2, 3):
                raise AuditError("E_INTERIOR_ORDINAL")
            key = (year_number, ordinal)
            if key in observed["INTERIOR_YEAR"]:
                raise AuditError("E_DUPLICATE_INTERIOR_CASE")
            observed["INTERIOR_YEAR"][key] = (target, resolved)
        elif kind in ("YEAR", "NEXT", "PREVIOUS", "NEXT2", "PREVIOUS2") and len(columns) == 6:
            if observed[kind] is not None:
                raise AuditError(f"E_DUPLICATE_{kind}")
            observed[kind] = tuple(map(number, columns[1:]))
        elif kind in ("FIND_FORWARD", "FIND_BACKWARD", "FIND_FORWARD2", "FIND_BACKWARD2") and len(columns) == 7:
            if observed[kind] is not None:
                raise AuditError(f"E_DUPLICATE_{kind}")
            observed[kind] = (number(columns[1]), tuple(map(number, columns[2:])))
        elif kind in ("PRODUCTION_GATE_LIMIT", "PRODUCTION_EXPANDED_GATES") and len(columns) == 2:
            if observed[kind] is not None:
                raise AuditError(f"E_DUPLICATE_{kind}")
            observed[kind] = number(columns[1])
        else:
            raise AuditError("E_UNKNOWN_TRANSCRIPT_ROW")

    if set(observed["GATE"]) != set(range(-ORACLE_HALF_WIDTH, ORACLE_HALF_WIDTH + 1)):
        raise AuditError("E_GATE_INDEX_SET")
    for key in ("YEAR", "NEXT", "PREVIOUS", "NEXT2", "PREVIOUS2",
                "FIND_FORWARD", "FIND_BACKWARD", "FIND_FORWARD2", "FIND_BACKWARD2",
                "PRODUCTION_GATE_LIMIT", "PRODUCTION_EXPANDED_GATES"):
        if observed[key] is None:
            raise AuditError(f"E_MISSING_{key}")
    if set(observed["INTERVAL"]) != EXPECTED_INTERVAL_KEYS:
        raise AuditError("E_INTERVAL_CASE_SET")
    if set(observed["INTERIOR_YEAR"]) != EXPECTED_INTERIOR_KEYS:
        raise AuditError("E_INTERIOR_CASE_SET")
    if observed["PRODUCTION_GATE_LIMIT"] != MAX_PRODUCTION_GATE_INDEX:
        raise AuditError("E_PRODUCTION_LIMIT_DRIFT")
    if observed["PRODUCTION_EXPANDED_GATES"] != GATE_COUNT:
        raise AuditError("E_PRODUCTION_EXPANDED_GATE_COUNT")
    if observed["PRODUCTION_EXPANDED_GATES"] > MAX_PRODUCTION_GATE_INDEX:
        raise AuditError("E_PRODUCTION_EXPANDED_GATE_BUDGET")
    return observed


def as_tuple(year) -> tuple[int, int, int, int, int]:
    return (year.number, year.open_index, year.close_index,
            year.open_day, year.close_day)


def independent_interior_targets(year) -> tuple[int, int, int]:
    """Strict internal quartile/median probes from independent interval boundaries."""
    span = year.close_day - year.open_day
    quarter = span // 4
    targets = (year.open_day + quarter, year.open_day + span // 2,
               year.close_day - quarter)
    if not (year.open_day < targets[0] < targets[1] <
            targets[2] < year.close_day):
        raise AuditError("E_INTERIOR_SAMPLE_COLLAPSE")
    return targets


def compare(parsed: dict, ledger, geometry, selector) -> dict:
    for index in range(-ORACLE_HALF_WIDTH, ORACLE_HALF_WIDTH + 1):
        if parsed["GATE"][index] != ledger.day(index):
            raise AuditError(f"E_REAL_GATE_MISMATCH_{index}")

    base = geometry.year5000(FOUNDATION, selector)
    if parsed["YEAR"] != as_tuple(base):
        raise AuditError("E_REAL_YEAR5000_MISMATCH")

    next_year = geometry.next(base, selector)
    previous_year = geometry.previous(base, selector)
    if parsed["NEXT"] != as_tuple(next_year):
        raise AuditError("E_REAL_NEXT_YEAR_MISMATCH")
    if parsed["PREVIOUS"] != as_tuple(previous_year):
        raise AuditError("E_REAL_PREVIOUS_YEAR_MISMATCH")
    next2 = geometry.next(next_year, selector)
    previous2 = geometry.previous(previous_year, selector)
    if parsed["NEXT2"] != as_tuple(next2):
        raise AuditError("E_REAL_NEXT2_YEAR_MISMATCH")
    if parsed["PREVIOUS2"] != as_tuple(previous2):
        raise AuditError("E_REAL_PREVIOUS2_YEAR_MISMATCH")
    if (next2.number != next_year.number + 1 or
            next2.open_index != next_year.close_index or
            next2.open_day != next_year.close_day or
            not next2.open_day < next2.close_day):
        raise AuditError("E_INDEPENDENT_FORWARD2_CONTIGUITY")
    if (previous2.number != previous_year.number - 1 or
            previous2.close_index != previous_year.open_index or
            previous2.close_day != previous_year.open_day or
            not previous2.open_day < previous2.close_day):
        raise AuditError("E_INDEPENDENT_BACKWARD2_CONTIGUITY")

    if (next_year.number != base.number + 1 or
            next_year.open_index != base.close_index or
            next_year.open_day != base.close_day or
            not next_year.open_day < next_year.close_day):
        raise AuditError("E_INDEPENDENT_FORWARD_CONTIGUITY")
    if (previous_year.number != base.number - 1 or
            previous_year.close_index != base.open_index or
            previous_year.close_day != base.open_day or
            not previous_year.open_day < previous_year.close_day):
        raise AuditError("E_INDEPENDENT_BACKWARD_CONTIGUITY")

    forward_target = base.close_day + 1
    backward_target = base.open_day
    if parsed["FIND_FORWARD"][0] != forward_target:
        raise AuditError("E_FIND_FORWARD_TARGET")
    if parsed["FIND_BACKWARD"][0] != backward_target:
        raise AuditError("E_FIND_BACKWARD_TARGET")

    expected_forward, forward_transitions = geometry.find(
        FOUNDATION, forward_target, selector
    )
    expected_backward, backward_transitions = geometry.find(
        FOUNDATION, backward_target, selector
    )
    if forward_transitions != 1 or expected_forward != next_year:
        raise AuditError("E_INDEPENDENT_FORWARD_TRANSITION")
    if backward_transitions != 1 or expected_backward != previous_year:
        raise AuditError("E_INDEPENDENT_BACKWARD_TRANSITION")
    if parsed["FIND_FORWARD"][1] != as_tuple(expected_forward):
        raise AuditError("E_REAL_FIND_FORWARD_MISMATCH")
    if parsed["FIND_BACKWARD"][1] != as_tuple(expected_backward):
        raise AuditError("E_REAL_FIND_BACKWARD_MISMATCH")

    forward_target2 = next_year.close_day + 1
    backward_target2 = previous_year.open_day
    if parsed["FIND_FORWARD2"][0] != forward_target2:
        raise AuditError("E_FIND_FORWARD2_TARGET")
    if parsed["FIND_BACKWARD2"][0] != backward_target2:
        raise AuditError("E_FIND_BACKWARD2_TARGET")
    found_forward2, forward_transitions2 = geometry.find(
        FOUNDATION, forward_target2, selector
    )
    found_backward2, backward_transitions2 = geometry.find(
        FOUNDATION, backward_target2, selector
    )
    if forward_transitions2 != 2 or found_forward2 != next2:
        raise AuditError("E_INDEPENDENT_FORWARD2_TRANSITION")
    if backward_transitions2 != 2 or found_backward2 != previous2:
        raise AuditError("E_INDEPENDENT_BACKWARD2_TRANSITION")
    if parsed["FIND_FORWARD2"][1] != as_tuple(found_forward2):
        raise AuditError("E_REAL_FIND_FORWARD2_MISMATCH")
    if parsed["FIND_BACKWARD2"][1] != as_tuple(found_backward2):
        raise AuditError("E_REAL_FIND_BACKWARD2_MISMATCH")

    # Independent expected endpoints from the unseeded Python year geometry.
    independent_years = [previous2, previous_year, base, next_year, next2]
    endpoint_count = 0
    for position, source in enumerate(independent_years):
        checks = [("AFTER_OPEN", source.open_day + 1, source),
                  ("AT_CLOSE", source.close_day, source)]
        if position > 0:
            checks.append(("AT_OPEN", source.open_day, independent_years[position - 1]))
        if position < len(independent_years) - 1:
            checks.append(("AFTER_CLOSE", source.close_day + 1,
                           independent_years[position + 1]))
        for kind, target, expected in checks:
            actual_target, actual_year = parsed["INTERVAL"][(source.number, kind)]
            if actual_target != target:
                raise AuditError(f"E_INTERVAL_TARGET_{source.number}_{kind}")
            oracle_year, transitions = geometry.find(FOUNDATION, target, selector)
            if (oracle_year != expected or
                    transitions != abs(expected.number - 5000) or
                    not oracle_year.open_day < target <= oracle_year.close_day):
                raise AuditError(f"E_INDEPENDENT_INTERVAL_SEMANTICS_{source.number}_{kind}")
            if actual_year != as_tuple(expected):
                raise AuditError(f"E_REAL_INTERVAL_MISMATCH_{source.number}_{kind}")
            endpoint_count += 1
    if endpoint_count != EXPECTED_INTERVAL_CASES:
        raise AuditError("E_INTERVAL_COMPARISON_COUNT")

    # All target days are derived from independent, unseeded year boundaries.
    # This does not compare the full-date conversion or prove global independence.
    interior_count = 0
    expected_year_numbers = list(range(4998, 5003))
    if [year.number for year in independent_years] != expected_year_numbers:
        raise AuditError("E_INDEPENDENT_INTERIOR_YEAR_SET")
    for previous, following in zip(independent_years, independent_years[1:]):
        if (previous.close_index != following.open_index or
                previous.close_day != following.open_day):
            raise AuditError("E_INDEPENDENT_INTERIOR_CONTIGUITY")
    for year in independent_years:
        for ordinal, target in enumerate(independent_interior_targets(year), 1):
            actual_target, actual_year = parsed["INTERIOR_YEAR"][(year.number, ordinal)]
            if actual_target != target:
                raise AuditError(f"E_INTERIOR_TARGET_{year.number}_{ordinal}")
            oracle_year, transitions = geometry.find(FOUNDATION, target, selector)
            if (oracle_year != year or transitions != abs(year.number - 5000)
                    or transitions > 8 or not year.open_day < target < year.close_day):
                raise AuditError(f"E_INDEPENDENT_INTERIOR_SEMANTICS_{year.number}_{ordinal}")
            if actual_year != as_tuple(year):
                raise AuditError(f"E_REAL_INTERIOR_MISMATCH_{year.number}_{ordinal}")
            interior_count += 1
    if interior_count != EXPECTED_INTERIOR_CASES:
        raise AuditError("E_INTERIOR_COMPARISON_COUNT")

    return {
        "interior_target_comparisons": interior_count,
        "independent_year_boundaries": len(independent_years),
        "strict_internal_samples": True,
        "interval_endpoint_comparisons": endpoint_count,
        "interior_endpoint_comparisons": 10,
        "shared_boundary_comparisons": 8,
        "max_interval_transitions": 2,
        "production_gate_day_comparisons": GATE_COUNT,
        "year5000_comparisons": 1,
        "adjacent_year_comparisons": 2,
        "two_hop_year_comparisons": 2,
        "find_target_transition_comparisons": 2,
        "find_two_hop_transition_comparisons": 2,
        "production_gate_limit_checks": 1,
        "production_expanded_gate_count_checks": 1,
        "forward_transitions": forward_transitions,
        "backward_transitions": backward_transitions,
        "forward_two_hop_transitions": forward_transitions2,
        "backward_two_hop_transitions": backward_transitions2,
        "base_year": as_tuple(base),
        "next_year": as_tuple(next_year),
        "previous_year": as_tuple(previous_year),
        "next2_year": as_tuple(next2),
        "previous2_year": as_tuple(previous2),
    }


def write_evidence(path: Path, report: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".partial")
    temporary.write_text(
        json.dumps(report, ensure_ascii=False, sort_keys=True, indent=2) + "\n",
        encoding="utf-8",
    )
    temporary.replace(path)


def run(jar: Path, evidence: Path, timeout: int) -> int:
    started = time.monotonic()
    report = {
        "schema": "post55-production-interior-targets-unseeded-v4-five-years",
        "status": "FAIL_BOUNDED_REAL_PRODUCTION_INTERVAL_ENDPOINTS",
        "project_id": "PC-BRANCH-KOTLIN-CYMRAEG",
        "github_sha": os.environ.get("GITHUB_SHA", "UNVERIFIED_LOCAL"),
        "probe_class": "pastafari.Post55ProductionAdjacentYearProbe",
        "oracle_provenance": "independent Python sauce witness, exact rank primitive, and year geometry enumeration",
        "comparison_provenance": "live Kotlin production JVM transcript versus unseeded Python ledger",
        "source_checkpoint_seed_used": False,
        "full_date_verified": False,
        "tablets_production_verified": False,
        "algorithmic_independence_certified": False,
        "certifiable": False,
        "production_gate_limit_unchanged": MAX_PRODUCTION_GATE_INDEX,
        "production_gate_index_abs_requested": ORACLE_HALF_WIDTH,
        "production_expanded_gate_count_expected": GATE_COUNT,
        "real_oracle_gate_queries_expected": ORACLE_HALF_WIDTH * 2,
        "interval_endpoint_comparisons_expected": EXPECTED_INTERVAL_CASES,
        "interior_target_comparisons_expected": EXPECTED_INTERIOR_CASES,
        "year_boundaries_independent_expected": 5,
    }
    try:
        if type(timeout) is not int or not 60 <= timeout <= 900:
            raise AuditError("E_TIME_BUDGET")
        if not jar.is_file():
            raise AuditError("E_MISSING_PRODUCTION_JAR")

        report["production_jar_sha256"] = hashlib.sha256(jar.read_bytes()).hexdigest()
        process = subprocess.run(
            ["java", "-Xmx1200m", "-Xss8m", "-cp", str(jar),
             "pastafari.Post55ProductionAdjacentYearProbe"],
            input="", text=True, capture_output=True,
            timeout=min(360, timeout), check=False,
        )
        report["production_elapsed_seconds"] = round(time.monotonic() - started, 3)
        if process.returncode != 0:
            raise AuditError("E_PRODUCTION_NONZERO:" + process.stderr[-500:])
        parsed = parse_transcript(process.stdout)
        report["production_transcript_sha256"] = hashlib.sha256(
            process.stdout.encode("utf-8")
        ).hexdigest()

        deadline = started + timeout
        calls = []

        def independent_gap(index: int) -> int:
            if time.monotonic() >= deadline:
                raise AuditError("E_ORACLE_DEADLINE")
            calls.append(index)
            witness = evaluate(
                FOUNDATION, FOUNDATION + index, deadline=deadline
            )
            return gap_from_witness(witness)

        ledger = GateLedger(
            FOUNDATION, -ORACLE_HALF_WIDTH, ORACLE_HALF_WIDTH,
            independent_gap,
            max_questions=ORACLE_HALF_WIDTH * 2,
            segment_limit=ORACLE_HALF_WIDTH,
            deadline=deadline,
        )
        expected_calls = (
            list(range(-1, -ORACLE_HALF_WIDTH - 1, -1)) +
            list(range(1, ORACLE_HALF_WIDTH + 1))
        )
        if calls != expected_calls or ledger.question_count != len(calls):
            raise AuditError("E_UNSEEDED_QUERY_SEQUENCE")

        selector = independent_sauce_selector(FOUNDATION, deadline=deadline)
        geometry = IndependentYearGeometry(ledger, max_transitions=8)
        report.update(compare(parsed, ledger, geometry, selector))
        report["real_oracle_gate_queries_actual"] = len(calls)
        report["signed_gate_trace_sha256"] = hashlib.sha256(
            "".join(
                f"{index}:{ledger.day(index)}\n"
                for index in expected_calls
            ).encode("ascii")
        ).hexdigest()
        report["production_expanded_gate_count_actual"] = parsed[
            "PRODUCTION_EXPANDED_GATES"
        ]
        report["status"] = PASS
    except (
        AuditError, YearGeometryError, SauceOracleError, DateCombinatoricsError,
        RuntimeError, ValueError, OSError, ImportError,
        subprocess.TimeoutExpired, AssertionError,
    ) as exc:
        report["error_type"] = type(exc).__name__
        report["error"] = str(exc)[-500:]
    finally:
        report["elapsed_seconds"] = round(time.monotonic() - started, 3)
        write_evidence(evidence, report)
        print(json.dumps(
            {key: value for key, value in report.items() if "sha256" not in key},
            sort_keys=True,
        ))
    return 0 if report["status"] == PASS else 2


def main(argv=None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--jar", type=Path, required=True)
    parser.add_argument("--evidence", type=Path, required=True)
    parser.add_argument("--timeout-seconds", type=int, default=780)
    args = parser.parse_args(argv)
    return run(args.jar, args.evidence, args.timeout_seconds)


if __name__ == "__main__":
    sys.exit(main())
