#!/usr/bin/env python3
"""SQL Tamil Slice25 QA-only, source-locked year/gap tracing.

Clones branch production SQL into *new*, volatile QA aliases; never replaces
production routines. Historical independent year-first/year-last records are
used only for output assertions, never as an implementation.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(".")
PREFIX = "pastafari_sql_tamil."
LOCKS = {
    "sql/10_stage02_sauce.sql": "c5c6be7c02c255382ae7c317bfbf17138a12788c",
    "sql/13_stage02_gate_gaps.sql": "d4044e6a4f2f2ae94795233dd3aa14a7d7edaf9e",
    "sql/16_stage02_year5000.sql": "b2fd62c17b133c639f8751fe2eaa03e93ae167f5",
    "sql/17_stage02_adjacent_year_navigation.sql": "116e330d0215f58e23e94b4b573071ad24d44664",
    "sql/18_stage02_target_year_navigation.sql": "c204a314972b22a4a38f06a02c2fe1bd5bde7acf",
    "sql/test/151_stage25_calendar_date_locked_goldens_44701320191.jsonl":
        "21f38cd280498070b08b6c3074780f1742c36957",
}


def git_blob(raw: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\\0" + raw).hexdigest()


def locked() -> dict[str, str]:
    source = {}
    for name, sha in LOCKS.items():
        raw = (ROOT / name).read_bytes()
        assert git_blob(raw) == sha, f"source lock changed: {name}"
        source[name] = raw.decode("utf-8")
    return source


def definition(source: str, name: str) -> str:
    anchor = "CREATE OR REPLACE FUNCTION " + PREFIX + name + "("
    assert source.count(anchor) == 1, f"function anchor changed: {name}"
    start = source.index(anchor)
    next_def = source.find("\\nCREATE OR REPLACE FUNCTION ", start + len(anchor))
    return source[start:next_def if next_def >= 0 else len(source)].strip() + "\\n"


def clone(source: str, name: str, replacements: list[tuple[str, str]]) -> str:
    original = definition(source, name)
    old = "CREATE OR REPLACE FUNCTION " + PREFIX + name + "("
    substitutions = [(old, "CREATE OR REPLACE FUNCTION " + PREFIX + "qa_" + name + "("),
                     ("LANGUAGE SQL STABLE STRICT", "LANGUAGE SQL VOLATILE STRICT")]
    substitutions += replacements
    candidate = original
    for src, dst in substitutions:
        assert src != dst and candidate.count(src) == 1, (name, src, candidate.count(src))
        candidate = candidate.replace(src, dst, 1)
    reverse = candidate
    for src, dst in reversed(substitutions):
        assert reverse.count(dst) == 1, (name, "inverse", dst)
        reverse = reverse.replace(dst, src, 1)
    assert reverse == original, f"nonreversible clone {name}"
    return candidate


def swap_call(name: str, count: int = 1) -> tuple[str, str]:
    assert count == 1
    return PREFIX + name + "(", PREFIX + "qa_trace_" + name + "("


def trace(name: str, signature: str, typ: str, call: str, tag: str) -> str:
    return f"""CREATE OR REPLACE FUNCTION {PREFIX}qa_trace_{name}({signature})
RETURNS {typ} LANGUAGE plpgsql VOLATILE STRICT AS $qa_trace$
DECLARE
    result_value {typ};
    started_at timestamptz := clock_timestamp();
BEGIN
    RAISE NOTICE 'SQL_TAMIL_S25_ENTER={name}:%', ({tag})::text;
    result_value := {call};
    RAISE NOTICE 'SQL_TAMIL_S25_EXIT={name}:%:%', ({tag})::text,
        round(extract(epoch FROM clock_timestamp()-started_at)*1000,3);
    RETURN result_value;
END;
$qa_trace$;
"""


def generate(source: dict[str, str]) -> str:
    gap = source["sql/13_stage02_gate_gaps.sql"]
    win = source["sql/16_stage02_year5000.sql"]
    adjacent = source["sql/17_stage02_adjacent_year_navigation.sql"]
    find = source["sql/18_stage02_target_year_navigation.sql"]
    out = ["-- New QA aliases only; original production definitions remain byte-identical."]
    out.append(trace("sauce", "p_calculation_day numeric,p_target_day numeric",
                     PREFIX + "sauce_result",
                     PREFIX + "sauce(p_calculation_day,p_target_day)", "p_target_day"))
    out.append(clone(gap, "gate_gap_signed", [swap_call("sauce")]))
    out.append(trace("gate_gap_signed", "p_offset numeric", "numeric",
                     PREFIX + "qa_gate_gap_signed(p_offset)", "p_offset"))
    for side in ("positive", "negative"):
        name = side + "_gate_gap"
        out.append(clone(gap, name, [swap_call("gate_gap_signed")]))
        out.append(trace(name, "p_n numeric", "numeric",
                         PREFIX + "qa_" + name + "(p_n)", "p_n"))
    out.append(clone(win, "year5000_gate_window",
                     [swap_call("positive_gate_gap"), swap_call("negative_gate_gap")]))
    out.append(clone(win, "year5000",
                     [(PREFIX + "year5000_gate_window(", PREFIX + "qa_year5000_gate_window("),
                      swap_call("sauce")]))
    out.append(trace("year5000", "p_calculation_day numeric", PREFIX + "year_rec",
                     PREFIX + "qa_year5000(p_calculation_day)", "p_calculation_day"))
    for name in ("next_year", "previous_year"):
        out.append(clone(adjacent, name,
                         [swap_call("negative_gate_gap"), swap_call("positive_gate_gap"),
                          swap_call("sauce")]))
        out.append(trace(name,
                         "p_calculation_day numeric,p_known " + PREFIX + "year_rec",
                         PREFIX + "year_rec",
                         PREFIX + "qa_" + name + "(p_calculation_day,p_known)",
                         "(p_known).year_number"))
    out.append(clone(find, "find_target_year",
                     [swap_call("year5000"), swap_call("next_year"),
                      swap_call("previous_year")]))
    result = "\\n".join(out)
    for name in ("gate_gap_signed", "positive_gate_gap", "negative_gate_gap",
                 "year5000_gate_window", "year5000", "next_year",
                 "previous_year", "find_target_year"):
        assert "CREATE OR REPLACE FUNCTION " + PREFIX + name + "(" not in result
        assert "CREATE OR REPLACE FUNCTION " + PREFIX + "qa_" + name + "(" in result
    return result


def boundaries(source: dict[str, str]) -> dict:
    lines = source["sql/test/151_stage25_calendar_date_locked_goldens_44701320191.jsonl"]
    entries = [json.loads(line) for line in lines.splitlines() if line.strip()]
    assert len(entries) == 29
    first = {}
    last = {}
    for row in entries:
        year = row["expected"]["year_number"]
        if row["purpose"] == "year_first":
            assert year not in first
            first[year] = row["target_day"]
        elif row["purpose"] == "year_last":
            assert year not in last
            last[year] = row["target_day"]
    assert len(first) == len(last) == 8 and set(first) == set(last)
    records = {year: (first[year]-1, last[year]) for year in first}
    assert all(left < right for left, right in records.values())
    for year in records:
        if year + 1 in records:
            assert records[year][1] == records[year+1][0], year
    assert records[4996] == (-15074038, -15070673)
    assert records[5000] == (-15057703, -15053459)
    assert records[4996][0] < -15072356 <= records[4996][1]
    return records


def sql_cases(records: dict) -> dict[str, str]:
    open_day, close_day = records[4996]
    common = "\\set ON_ERROR_STOP on\\n"
    gap = common + """SET statement_timeout = '60s';
DO $qagap$
DECLARE v_qa numeric; v_original numeric;
BEGIN
 RAISE NOTICE 'SQL_TAMIL_S25_GAP_START=negative:1';
 v_qa := pastafari_sql_tamil.qa_trace_negative_gate_gap(1);
 IF v_qa IS NULL OR v_qa <> trunc(v_qa) OR v_qa NOT BETWEEN 42 AND 963 THEN
    RAISE EXCEPTION 'negative gap outside accepted bounds';
 END IF;
 v_original := pastafari_sql_tamil.negative_gate_gap(1);
 IF v_original IS DISTINCT FROM v_qa THEN
    RAISE EXCEPTION 'QA alias differs from unchanged production gap';
 END IF;
 RAISE NOTICE 'SQL_TAMIL_S25_GAP_EQUIVALENCE=1/1 PASS';
END;
$qagap$;
"""
    nav = common + f"""SET statement_timeout = '180s';
DO $qanav$
DECLARE v_year pastafari_sql_tamil.year_rec;
BEGIN
 RAISE NOTICE 'SQL_TAMIL_S25_YEAR_START=prev_3_prev_middle';
 v_year := pastafari_sql_tamil.qa_find_target_year(-15055671,-15072356);
 IF v_year IS NULL THEN RAISE EXCEPTION 'QA target year NULL'; END IF;
 IF (v_year).year_number IS DISTINCT FROM 4996::numeric OR
    (v_year).open_gate_day IS DISTINCT FROM {open_day}::numeric OR
    (v_year).close_gate_day IS DISTINCT FROM {close_day}::numeric THEN
     RAISE EXCEPTION 'independent historical year-boundary mismatch';
 END IF;
 RAISE NOTICE 'SQL_TAMIL_S25_YEAR_BOUNDARY=3/3 PASS';
END;
$qanav$;
"""
    return {"gap.sql": gap, "navigation.sql": nav}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--out-dir", type=Path)
    args = parser.parse_args()
    if not args.self_test and args.out_dir is None:
        parser.error("choose --self-test or --out-dir")
    source = locked()
    sql = generate(source)
    record = boundaries(source)
    cases = sql_cases(record)
    assert sql == generate(source)
    assert len(record) == 8
    for name in ("gap.sql", "navigation.sql"):
        assert "SET statement_timeout" in cases[name]
    if args.self_test:
        damaged = dict(source)
        damaged["sql/13_stage02_gate_gaps.sql"] = damaged[
            "sql/13_stage02_gate_gaps.sql"].replace(
                PREFIX + "sauce(", PREFIX + "wrong(", 1)
        try:
            generate(damaged)
        except AssertionError:
            pass
        else:
            raise AssertionError("damaged source not rejected")
        print("SQL_TAMIL_S25_STATIC_SOURCE_LOCKS=6/6 PASS")
        print("SQL_TAMIL_S25_STATIC_BOUNDARY_RECORDS=8/8 PASS")
        print("SQL_TAMIL_S25_STATIC_REVERSIBILITY=PASS")
        print("SQL_TAMIL_S25_NATIVE=NOT_EXECUTED")
    if args.out_dir is not None:
        args.out_dir.mkdir(parents=True, exist_ok=True)
        for filename, content in {"aliases.sql": sql, **cases}.items():
            (args.out_dir / filename).write_text(content, encoding="utf-8")
        print("SQL_TAMIL_S25_GENERATED=3 FILES")
        print("PRODUCTION_MODIFIED=NO")


if __name__ == "__main__":
    main()
