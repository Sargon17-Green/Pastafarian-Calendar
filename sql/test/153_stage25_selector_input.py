#!/usr/bin/env python3
"""Source-locked Slice25 selector baseline input generator (not a production oracle).

Exactly one real find_target_year call per CI job. The five expected year_rec
fields come from accepted Slice24 records / original Slice25 PG17 logs, not
from find_target_year. All 29 accepted ordinal cases are cross-checked.
"""
import argparse
import json
import re
from pathlib import Path

FIELDS = ("year_number", "open_gate_index", "close_gate_index",
          "open_gate_day", "close_gate_day")


def load(path):
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines()
            if line.strip()]


def check(records, goldens):
    if len(records) != 8 or len(goldens) != 29:
        raise AssertionError("source-lock cardinality: expected 8 year records and 29 goldens")
    years = {}
    for row in records:
        name = row["year_id"]
        if not re.fullmatch(r"[a-z][a-z0-9_]*", name) or name in years:
            raise AssertionError("invalid or duplicate year id")
        record = row["year_data"]
        if set(record) != set(FIELDS) or any(type(record[k]) is not int for k in FIELDS):
            raise AssertionError("year_rec fields must be five exact integers")
        if record["open_gate_day"] >= record["close_gate_day"]:
            raise AssertionError("invalid year boundaries")
        if record["open_gate_index"] >= record["close_gate_index"]:
            raise AssertionError("invalid gate indices")
        if row["oracle_text_year_number"] != record["year_number"]:
            raise AssertionError("independent ordinal year mismatch")
        if not row["case_id"].endswith("_first") or row["target_day"] != record["open_gate_day"] + 1:
            raise AssertionError("locked first-day mismatch")
        if abs(row["target_day"] - row["calculation_day"]) > 60000:
            raise AssertionError("selector domain mismatch")
        years[name] = row
    if len({r["year_data"]["year_number"] for r in records}) != 8:
        raise AssertionError("duplicate year number")
    seen = set()
    firsts = {}
    for row in goldens:
        case_id, name = row["case_id"], row["year_id"]
        if case_id in seen or name not in years:
            raise AssertionError("golden id or year mismatch")
        seen.add(case_id)
        expected = row["expected"]
        locked = years[name]
        rec = locked["year_data"]
        if (row["calculation_day"] != locked["calculation_day"]
                or expected["year_number"] != rec["year_number"]
                or not rec["open_gate_day"] < row["target_day"] <= rec["close_gate_day"]):
            raise AssertionError("golden outside source-locked year: " + case_id)
        if row["purpose"] == "year_first":
            if name in firsts or row["target_day"] != locked["target_day"] or case_id != locked["case_id"]:
                raise AssertionError("year-first selection mismatch")
            firsts[name] = case_id
    if len(firsts) != 8:
        raise AssertionError("missing year-first inputs")
    print("SLICE25_SELECTOR_INPUT_LOCK=29_goldens_8_years_8_first_days PASS")
    return years


def make_sql(row):
    values = [row["year_data"][key] for key in FIELDS]
    name = row["year_id"]
    # IDs have already been restricted to [a-z0-9_].
    return (
        "CREATE TEMP TABLE slice25_selector_input(\n"
        " year_id text PRIMARY KEY, calculation_day numeric NOT NULL,\n"
        " target_day numeric NOT NULL,\n"
        " expected_year_data pastafari_sql_tamil.year_rec NOT NULL);\n"
        "INSERT INTO slice25_selector_input VALUES\n"
        f" ('{name}',{row['calculation_day']},{row['target_day']},"
        f"ROW({','.join(map(str, values))})::pastafari_sql_tamil.year_rec);\n"
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--locked-records", required=True, type=Path)
    parser.add_argument("--goldens", required=True, type=Path)
    parser.add_argument("--year-case")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    years = check(load(args.locked_records), load(args.goldens))
    if args.year_case is None and args.output is None:
        return
    if args.year_case not in years or args.output is None:
        parser.error("--year-case must name a locked year and --output must be supplied")
    args.output.write_text(make_sql(years[args.year_case]), encoding="utf-8")
    print("SLICE25_SELECTOR_INPUT_GENERATED=" + args.year_case)


if __name__ == "__main__":
    main()
