#!/usr/bin/env python3
"""Slice25 source-locked, one-case-per-job PostgreSQL test SQL generator.

The expected five-field records were generated earlier by the independent
ordinal oracle (150) from PG17 year-structure artifacts, not by calendar_date.
This generator does not compute goldens or import production/normative SQL.
"""
from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from pathlib import Path

FIELDS = ("year_number", "cutlet_name", "day_in_cutlet",
          "month_name", "day_in_month")
SOURCE = "1ddaef9a315f83402ececaf4dc31f96dbdd051bd"
LOCKED = Path("sql/test/151_stage25_calendar_date_locked_goldens_44701320191.jsonl")


def checked_cases(path: Path) -> dict[str, dict]:
    rows = [json.loads(s) for s in path.read_text(encoding="utf-8").splitlines()
            if s.strip()]
    assert len(rows) == 29, f"locked case count: {len(rows)}"
    ids: set[str] = set()
    years: dict[str, int] = {}
    for row in rows:
        name = row["case_id"]
        assert re.fullmatch(r"[a-z0-9_]+", name), name
        assert name not in ids, f"duplicate case: {name}"
        ids.add(name)
        year = row["year_id"]
        number = row["expected"]["year_number"]
        assert isinstance(number, int) and not isinstance(number, bool)
        assert year not in years or years[year] == number
        years[year] = number
        assert set(row["expected"]) == set(FIELDS), name
        for field in FIELDS:
            value = row["expected"][field]
            if field.endswith("name"):
                assert isinstance(value, str) and value != "", (name, field)
            else:
                assert type(value) is int, (name, field)
        assert row["expected"]["day_in_cutlet"] >= 1
        assert row["expected"]["day_in_month"] >= 1
        assert type(row["calculation_day"]) is int
        assert type(row["target_day"]) is int
        assert abs(row["calculation_day"] - row["target_day"]) <= 60000
        assert row["source_sha"] == SOURCE
        assert type(row["original_zip_artifact_id"]) is int
    assert len(years) == 8, f"locked year count: {len(years)}"
    assert len({r["target_day"] for r in rows}) == 29
    purposes = Counter(r["purpose"] for r in rows)
    for required in ("year_first", "year_last", "year_middle",
                     "cutlet_boundary_minus", "cutlet_boundary",
                     "cutlet_boundary_plus", "month_first_occurrence",
                     "month_repeated_occurrence"):
        assert purposes[required] >= 1, required
    return {r["case_id"]: r for r in rows}


def literal(value: object) -> str:
    if type(value) is int:
        return str(value) + "::numeric"
    if isinstance(value, str):
        return "'" + value.replace("'", "''") + "'::text"
    raise TypeError("unexpected locked field value")


def sql_for(row: dict, mode: str) -> str:
    case = row["case_id"]
    calc = literal(row["calculation_day"])
    target = literal(row["target_day"])
    expected = row["expected"]
    declarations = [
        "    v_prod pastafari_sql_tamil.calendar_result_text;",
        "    v_started timestamptz;",
    ]
    if mode == "differential":
        declarations.append("    v_ref pastafari_sql_tamil_test.calendar_result_text;")
    statements = [
        "    v_started := clock_timestamp();",
    ]
    if mode == "isolation":
        statements += [
            "    IF to_regnamespace('pastafari_sql_tamil_test') IS NOT NULL THEN",
            "        RAISE EXCEPTION 'reference schema present in production-only database';",
            "    END IF;",
            "    RAISE NOTICE 'SLICE25_ISOLATION_SCHEMA_PASS=%';" % case,
        ]
    statements += [
        f"    v_prod := pastafari_sql_tamil.calendar_date({calc},{target});",
        "    IF v_prod IS NULL THEN",
        f"        RAISE EXCEPTION 'production NULL: {case}';",
        "    END IF;",
    ]
    for field in FIELDS:
        statements += [
            f"    IF (v_prod).{field} IS DISTINCT FROM {literal(expected[field])} THEN",
            f"        RAISE EXCEPTION 'independent golden mismatch: {case}.{field}';",
            "    END IF;",
            f"    RAISE NOTICE 'SLICE25_NATIVE_FIELD_PASS={case}.{field}';",
        ]
    if mode == "differential":
        statements += [
            f"    v_ref := pastafari_sql_tamil_test.calendar_date({calc},{target});",
            "    IF v_ref IS NULL THEN",
            f"        RAISE EXCEPTION 'normative NULL: {case}';",
            "    END IF;",
        ]
        for field in FIELDS:
            statements += [
                f"    IF (v_ref).{field} IS DISTINCT FROM (v_prod).{field} THEN",
                f"        RAISE EXCEPTION 'typed differential mismatch: {case}.{field}';",
                "    END IF;",
                f"    RAISE NOTICE 'SLICE25_DIFFERENTIAL_FIELD_PASS={case}.{field}';",
            ]
    if mode == "isolation":
        statements += [
            "    IF to_regnamespace('pastafari_sql_tamil_test') IS NOT NULL THEN",
            "        RAISE EXCEPTION 'reference schema introduced by production';",
            "    END IF;",
            "    IF EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n",
            "               ON n.oid=p.pronamespace",
            "               WHERE n.nspname='pastafari_sql_tamil'",
            "                 AND p.proname='calendar_date'",
            "                 AND position('pastafari_sql_tamil_test'",
            "                   IN pg_get_functiondef(p.oid))>0) THEN",
            "        RAISE EXCEPTION 'production function depends on test schema';",
            "    END IF;",
            f"    RAISE NOTICE 'SLICE25_ISOLATION_BODY_PASS={case}';",
        ]
    statements += [
        f"    RAISE NOTICE 'SLICE25_CASE_ELAPSED_MS={case}:%',",
        "        round(extract(epoch FROM clock_timestamp()-v_started)*1000,3);",
        f"    RAISE NOTICE 'SLICE25_MATRIX_GREEN={mode}:{case}';",
    ]
    return ("\u005cset ON_ERROR_STOP on\n"
            "SET statement_timeout = '12min';\n"
            f"-- Source-locked oracle case: {case}; source {SOURCE}\n"
            "DO $slice25_matrix$\nDECLARE\n"
            + "\n".join(declarations)
            + "\nBEGIN\n"
            + "\n".join(statements)
            + "\nEND;\n$slice25_matrix$;\n")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--locked", type=Path, default=LOCKED)
    parser.add_argument("--audit", action="store_true")
    parser.add_argument("--mode", choices=("native", "isolation", "differential"))
    parser.add_argument("--case-id")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    cases = checked_cases(args.locked)
    if args.audit:
        print("SLICE25_LOCKED_CASES=29/29 PASS")
        print("SLICE25_LOCKED_YEARS=8/8 PASS")
        print("SLICE25_FIELD_EXPECTATIONS=145/145 PRESENT")
        print("ORACLE=HISTORICAL_INDEPENDENT_ORDINAL_PG17_STRUCTURES")
        if args.mode or args.case_id or args.output:
            parser.error("--audit cannot generate SQL")
        return
    if args.mode is None or args.case_id is None or args.output is None:
        parser.error("--mode, --case-id and --output are all required")
    if args.case_id not in cases:
        parser.error(f"case ID not in locked corpus: {args.case_id}")
    content = sql_for(cases[args.case_id], args.mode)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(content, encoding="utf-8")
    print(f"SLICE25_GENERATED={args.mode}:{args.case_id}")
    print("SLICE25_GENERATED_EXPECTED_FIELDS=5")
    print("SOURCE=IMMUTABLE_INDEPENDENT_GOLDENS_NOT_NORMATIVE_OUTPUT")


if __name__ == "__main__":
    main()
