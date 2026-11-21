#!/usr/bin/env python3
"""Nine real seven-column dates: FOUNDATION neighborhood and year-5000 edges.

Project PC-BRANCH-KOTLIN-CYMRAEG, QA only, NOT CERTIFIED.
Production: actual JDK21/Kotlin1.9 bridge, one JVM and nine independently checked
convert() requests, including both sides of year-5000 boundaries. Oracle: branch-local, separately authored Python sauce,
year geometry, composition and combinatorial month weaving; no pinned Python
reference, checkpoint, production output seed or cross-branch fixture.
The independent techniques are not proof of GLOBAL algorithmic independence.
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
from time import monotonic

from independent_five_field_date import date_with_independent_sauce, independent_signed_gap, independent_rank
from independent_year_geometry_oracle import FOUNDATION, GateLedger, IndependentYearGeometry, Year
import independent_date_combinatorics
import independent_month_weaving_oracle
import independent_sauce_oracle
import independent_year_geometry_oracle
import independent_five_field_date

PROJECT_ID = "PC-BRANCH-KOTLIN-CYMRAEG"
BRANCH = "Kotlin+Cymraeg"
TARGETS = tuple(FOUNDATION + offset for offset in (-2, -1, 0, 1, 2))
HALF_WIDTH = 280
QUESTION_COUNT = HALF_WIDTH * 2
GATE_LIMIT = 8192
PASS = "PASS_BOUNDED_UNSEEDED_YEAR_EDGE_NINE_DATES_NOT_CERTIFIED"
DECIMAL = re.compile(r"(?:0|-?[1-9][0-9]*)\Z", re.ASCII)
MODULES = (independent_date_combinatorics, independent_month_weaving_oracle,
           independent_sauce_oracle, independent_year_geometry_oracle,
           independent_five_field_date)


class SevenFieldAuditError(ValueError):
    pass


def canonical_number(field: str) -> int:
    if not isinstance(field, str) or DECIMAL.fullmatch(field) is None:
        raise SevenFieldAuditError("E_SEVEN_NONCANONICAL")
    return int(field)


def parse_production(raw: str, targets: tuple[int, ...] = TARGETS) -> list[list[int]]:
    if not isinstance(raw, str) or not raw.endswith("\n") or "\r" in raw:
        raise SevenFieldAuditError("E_SEVEN_PROTOCOL")
    lines = raw.splitlines()
    if len(lines) != len(targets):
        raise SevenFieldAuditError("E_SEVEN_ROW_COUNT")
    rows = []
    for target, line in zip(targets, lines):
        cells = line.split("\t")
        if len(cells) != 7:
            raise SevenFieldAuditError("E_SEVEN_COLUMN_COUNT")
        values = [canonical_number(c) for c in cells]
        if values[:2] != [FOUNDATION, target]:
            raise SevenFieldAuditError("E_SEVEN_INPUT_ECHO")
        year, cutlet, cutlet_day, month, month_day = values[2:]
        if not (year >= 1 and 1 <= cutlet <= 17 and cutlet_day >= 1
                and 1 <= month <= 47 and 1 <= month_day <= 123):
            raise SevenFieldAuditError("E_SEVEN_BOUNDS")
        rows.append(values)
    return rows


def expected_indices() -> list[int]:
    return list(range(-1, -HALF_WIDTH - 1, -1)) + list(range(1, HALF_WIDTH + 1))


def validate_ledger_trace(pairs: list[tuple[int, int]], count: int = QUESTION_COUNT) -> None:
    if (len(pairs) != count or
            [index for index, _ in pairs] != expected_indices() or
            any(type(index) is not int or type(gap) is not int
                or not 42 <= gap <= 963 for index, gap in pairs)):
        raise SevenFieldAuditError("E_UNSEEDED_SIGNED_TRACE")


def boundary_targets(year: Year) -> tuple[int, int, int, int]:
    """Last/first day across both independently located year-5000 edges."""
    if (not isinstance(year, Year) or year.number != 5000
            or not year.open_day < FOUNDATION <= year.close_day
            or year.close_day - year.open_day < 252):
        raise SevenFieldAuditError("E_INDEPENDENT_YEAR_BOUNDARY")
    result = (year.open_day, year.open_day + 1, year.close_day, year.close_day + 1)
    if len(set(result)) != 4:
        raise SevenFieldAuditError("E_YEAR_BOUNDARY_DUPLICATE")
    return result


def verified_source(root: Path, jar: Path) -> dict:
    root = root.resolve(strict=True)
    sha = subprocess.check_output(
        ["git", "-C", str(root), "rev-parse", "HEAD"],
        text=True, timeout=15).strip()
    if (os.getenv("GITHUB_REF_NAME") != BRANCH or
            os.getenv("GITHUB_SHA") != sha or
            re.fullmatch(r"[0-9a-f]{40}", sha) is None):
        raise SevenFieldAuditError("E_EXACT_SOURCE_REF")
    source = root / "src/main/kotlin/pastafari/ProductionYearNavigator.kt"
    bridge = root / "soak/Post55ProductionDateBridge.kt"
    if ("maxGateAbsIndex: Int = 8192" not in source.read_text(encoding="utf-8")
            or "ProductionYearNavigator()" not in bridge.read_text(encoding="utf-8")
            or "E_POST55_GATE_GEOMETRIC_LIMIT" not in bridge.read_text(encoding="utf-8")):
        raise SevenFieldAuditError("E_PRODUCTION_BUDGET_OR_BRIDGE_DRIFT")
    fingerprints = {}
    for module in MODULES:
        source_path = Path(module.__file__).resolve(strict=True)
        if not source_path.is_relative_to(root / "soak"):
            raise SevenFieldAuditError("E_ORACLE_MODULE_ESCAPE")
        fingerprints[source_path.name] = hashlib.sha256(source_path.read_bytes()).hexdigest()
    if not jar.is_file() or jar.stat().st_size == 0:
        raise SevenFieldAuditError("E_PRODUCTION_JAR")
    return {"git_sha": sha, "jar_sha256": hashlib.sha256(jar.read_bytes()).hexdigest(),
            "oracle_module_sha256": fingerprints,
            "bridge_sha256": hashlib.sha256(bridge.read_bytes()).hexdigest(),
            "production_navigator_sha256": hashlib.sha256(source.read_bytes()).hexdigest()}


def compare_rows(production: list[list[int]], oracle: list[tuple[int, ...]],
                 targets: tuple[int, ...] = TARGETS) -> list[dict]:
    if len(production) != len(targets) or len(oracle) != len(targets):
        raise SevenFieldAuditError("E_COMPARE_CASE_COUNT")
    out = []
    for i, target in enumerate(targets):
        reference = oracle[i]
        if (type(reference) is not tuple or len(reference) != 5
                or any(type(x) is not int for x in reference)):
            raise SevenFieldAuditError("E_ORACLE_FIVE_FIELD_SHAPE")
        exact = production[i][2:] == list(reference)
        out.append({"target": target, "production_seven": production[i],
                    "oracle_five": list(reference), "equal": exact})
        if not exact:
            raise SevenFieldAuditError("E_SEVEN_UNSEEDED_DIFFERENTIAL_" + str(target))
    return out


def atomic_text(path: Path, value: str) -> str:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(value, encoding="utf-8")
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def audit(jar: Path, timeout_seconds: int, evidence: Path,
          transcript: Path, gaps_file: Path) -> dict:
    if type(timeout_seconds) is not int or not 60 <= timeout_seconds <= 1200:
        raise SevenFieldAuditError("E_TOTAL_BUDGET")
    begun = monotonic()
    deadline = begun + timeout_seconds
    root = Path(__file__).resolve().parent.parent
    provenance = verified_source(root, jar)
    trace: list[tuple[int, int]] = []

    def independent_gap(index: int) -> int:
        if monotonic() >= deadline:
            raise SevenFieldAuditError("E_INDEPENDENT_TIME_BUDGET")
        value = independent_signed_gap(index, deadline=deadline)
        trace.append((index, value))
        return value

    ledger = GateLedger(FOUNDATION, -HALF_WIDTH, HALF_WIDTH, independent_gap,
                        max_questions=QUESTION_COUNT, segment_limit=HALF_WIDTH,
                        deadline=deadline)
    validate_ledger_trace(trace)
    choose_year = independent_rank(FOUNDATION, deadline=deadline)
    year5000 = IndependentYearGeometry(ledger).year5000(
        FOUNDATION, lambda day, seal, count: choose_year(day, 1, seal, count))
    edges = boundary_targets(year5000)
    targets = TARGETS + edges
    # Reuse five accepted neighborhood dates as a regression baseline.
    # Four additional questions cross the independently selected year edges.
    if len(targets) != 9:
        raise SevenFieldAuditError("E_NINE_DATE_SCOPE")
    cmd = ["java", "-XX:ActiveProcessorCount=1", "-Xmx1200m", "-Xss8m",
           "-cp", str(jar.resolve()), "pastafari.Post55ProductionDateBridge"]
    input_text = "".join(f"{FOUNDATION}\t{target}\n" for target in targets)
    remaining = max(1, int(deadline - monotonic()))
    try:
        proc = subprocess.run(cmd, input=input_text, capture_output=True,
                              text=True, timeout=min(remaining, 480), check=False)
    except subprocess.TimeoutExpired as exc:
        raise SevenFieldAuditError("E_NATIVE_TIMEOUT") from exc
    atomic_text(transcript, proc.stdout)
    if proc.returncode != 0:
        raise SevenFieldAuditError("E_NATIVE_EXIT_" + str(proc.returncode) +
                                   "_STDERR_" + proc.stderr[-300:])
    rows = parse_production(proc.stdout, targets)
    trace_raw = "".join(f"{index}\t{width}\n" for index, width in trace)
    trace_digest = atomic_text(gaps_file, trace_raw)
    references = []
    for target in targets:
        if monotonic() >= deadline:
            raise SevenFieldAuditError("E_INDEPENDENT_TIME_BUDGET")
        references.append(date_with_independent_sauce(ledger, target, deadline=deadline))
    matches = compare_rows(rows, references, targets)
    return {
        "status": PASS, "project_id": PROJECT_ID, "branch": BRANCH,
        "source": provenance, "calculation_day": FOUNDATION,
        "target_offsets": [t - FOUNDATION for t in targets],
        "year5000_edges": list(edges),
        "year5000_open_close": [year5000.open_day, year5000.close_day],
        "production_calls": len(rows), "production_columns": 7,
        "independent_five_field_comparisons": len(matches) * 5,
        "matches": matches, "mismatches": 0,
        "signed_gate_gap_questions": ledger.question_count,
        "signed_gate_gap_sha256": trace_digest,
        "production_stdout_sha256": hashlib.sha256(proc.stdout.encode("utf-8")).hexdigest(),
        "production_configured_gate_limit": GATE_LIMIT,
        "production_actual_gate_count_exposed": False,
        "checkpoint_seed_used": False, "pinned_reference_used": False,
        "shared_cross_branch_fixture_used": False,
        "full_date_certified": False, "tablets_certified": False,
        "global_algorithmic_independence_certified": False,
        "certifiable": False,
        "elapsed_seconds": round(monotonic() - begun, 3),
    }


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--jar", type=Path, required=True)
    ap.add_argument("--evidence", type=Path, required=True)
    ap.add_argument("--transcript", type=Path, required=True)
    ap.add_argument("--gaps", type=Path, required=True)
    ap.add_argument("--timeout-seconds", type=int, default=900)
    args = ap.parse_args(argv)
    try:
        result = audit(args.jar, args.timeout_seconds, args.evidence,
                       args.transcript, args.gaps)
    except Exception as exc:
        result = {"status": "FAIL_SEVEN_FIELD_UNSEEDED_DIFFERENTIAL",
                  "project_id": PROJECT_ID,
                  "github_sha": os.getenv("GITHUB_SHA", "UNVERIFIED"),
                  "error_type": type(exc).__name__, "error": str(exc)[:1000],
                  "full_date_certified": False, "tablets_certified": False,
                  "global_algorithmic_independence_certified": False,
                  "certifiable": False}
    atomic_text(args.evidence, json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(json.dumps(result, sort_keys=True))
    return 0 if result["status"] == PASS else 2


if __name__ == "__main__":
    raise SystemExit(main())
