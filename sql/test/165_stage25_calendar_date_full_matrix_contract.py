#!/usr/bin/env python3
"""Validate exact Slice25 full matrix breadth using source-locked independent records."""
from __future__ import annotations
import json
import re
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github/workflows/sql-tamil-stage02-calendar-date-matrix-full.yml"
CORPUS = ROOT / "sql/test/151_stage25_calendar_date_locked_goldens_44701320191.jsonl"
FIELDS = ("year_number", "cutlet_name", "day_in_cutlet", "month_name", "day_in_month")


def verify() -> None:
    cases = [json.loads(line) for line in CORPUS.read_text(encoding="utf-8").splitlines() if line.strip()]
    assert len(cases) == 29, "immutable corpus count"
    by_name = {row["case_id"]: row for row in cases}
    assert len(by_name) == 29, "immutable unique cases"
    years = {row["year_id"] for row in cases}
    assert len(years) == 8, "eight locked years"
    assert all(set(row["expected"]) == set(FIELDS) for row in cases)
    workflow = WORKFLOW.read_text(encoding="utf-8")
    entries = re.findall(r"(?m)^\s+- \{mode: (native|isolation|differential), case_id: ([a-z0-9_]+)\}$", workflow)
    assert len(entries) == 56, f"expected 56 cases, got {len(entries)}"
    assert len(set(entries)) == 56, "duplicate mode/case matrix entry"
    assert all(name in by_name for _, name in entries), "unknown source-locked case"
    groups = defaultdict(list)
    for mode, name in entries:
        groups[mode].append(by_name[name])
    assert {mode: len(rows) for mode, rows in groups.items()} == {"native": 24, "isolation": 8, "differential": 24}
    assert {row["case_id"] for row in groups["native"]} == {row["case_id"] for row in groups["differential"]}
    for mode in ("native", "isolation", "differential"):
        assert {row["year_id"] for row in groups[mode]} == years, (mode, "year coverage")
    assert all(row["purpose"] == "year_first" for row in groups["isolation"])
    for mode in ("native", "differential"):
        coverage = {(row["year_id"], row["purpose"]) for row in groups[mode]}
        assert all((year, "year_first") in coverage and (year, "year_last") in coverage for year in years)
        purposes = Counter(row["purpose"] for row in groups[mode])
        for purpose in ("cutlet_boundary_minus", "cutlet_boundary",
                        "cutlet_boundary_plus", "month_first_occurrence",
                        "month_repeated_occurrence", "year_middle"):
            assert purposes[purpose] >= 1, (mode, purpose)
    assert "timeout-minutes: 15" in workflow
    assert "max-parallel: 4" in workflow
    assert "postgres:17" in workflow
    assert "git rev-parse HEAD" in workflow and "GITHUB_SHA" in workflow
    assert "ON_ERROR_STOP=1" in workflow
    assert "SLICE25_NATIVE_FIELD_PASS=" in workflow
    assert "SLICE25_DIFFERENTIAL_FIELD_PASS=" in workflow
    assert "SLICE25_ISOLATION_SCHEMA_PASS=" in workflow
    assert "SLICE25_ISOLATION_BODY_PASS=" in workflow
    print("SLICE25_FULL_MATRIX=56/56 STATIC_PASS")
    print("SLICE25_NATIVE=24_CASES_120_FIELD_ASSERTIONS_8_YEARS STATIC_PLAN")
    print("SLICE25_ISOLATION=8_FRESH_DATABASE_JOBS_8_YEARS STATIC_PLAN")
    print("SLICE25_DIFFERENTIAL=24_CASES_120_FIELD_ASSERTIONS_8_YEARS STATIC_PLAN")
    print("SLICE25_BOUNDARIES=FIRST_LAST_CUTLET_MINUS_ZERO_PLUS_MONTH_FIRST_REPEAT STATIC_PLAN")
    print("SLICE25_NATIVE_PG17=NOT_YET_VERIFIED")


if __name__ == "__main__":
    verify()
