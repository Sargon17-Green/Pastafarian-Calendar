#!/usr/bin/env python3
"""Source-locked, one-hop PostgreSQL selector diagnostic; never produces oracle data."""
import argparse
import json
from pathlib import Path

EXPECTED_YEARS = {
    "prev_3_prev": 4996, "prev_3": 4997, "prev_2": 4998,
    "anchor": 5000, "next_1": 5001, "next_2": 5002,
    "next_3": 5003, "next_3_next": 5004,
}
FIELDS = ("year_number", "open_gate_index", "close_gate_index", "open_gate_day", "close_gate_day")
PAIRS = {
    "seed": ("seed", "anchor", "anchor"),
    "next_1": ("next", "anchor", "next_1"),
    "next_2": ("next", "next_1", "next_2"),
    "next_3": ("next", "next_2", "next_3"),
    "next_3_next": ("next", "next_3", "next_3_next"),
    "prev_3": ("previous", "prev_2", "prev_3"),
    "prev_3_prev": ("previous", "prev_3", "prev_3_prev"),
}
GOLDENS_BLOB = "21f38cd280498070b08b6c3074780f1742c36957"


def load_records(path: Path):
    entries = [json.loads(s) for s in path.read_text(encoding="utf-8").splitlines() if s.strip()]
    if len(entries) != 8:
        raise ValueError("exactly eight source-locked year records required")
    records = {}
    calc_values = set()
    for e in entries:
        ident = e["year_id"]
        if ident not in EXPECTED_YEARS or ident in records:
            raise ValueError("unknown or duplicate year ID")
        if e.get("locked_goldens_sha") != GOLDENS_BLOB or not e.get("provenance"):
            raise ValueError("missing source provenance/golden blob lock")
        calc, target = e["calculation_day"], e["target_day"]
        y = e["year_data"]
        if type(calc) is not int or type(target) is not int:
            raise ValueError("integer calculation/target days required")
        if set(y) != set(FIELDS) or any(type(y[k]) is not int for k in FIELDS):
            raise ValueError("exact five-field integer year record required")
        if y["year_number"] != EXPECTED_YEARS[ident] or e.get("oracle_text_year_number") != EXPECTED_YEARS[ident]:
            raise ValueError("wrong source-locked year identity")
        if target != y["open_gate_day"] + 1 or not (0 < y["close_gate_day"] - y["open_gate_day"] <= 5778):
            raise ValueError("year first day or span mismatch")
        if not (6 <= y["close_gate_index"] - y["open_gate_index"]):
            raise ValueError("gate index bounds invalid")
        if abs(calc - target) > 60000:
            raise ValueError("out-of-domain source-locked target")
        calc_values.add(calc)
        records[ident] = e
    if set(records) != set(EXPECTED_YEARS) or len(calc_values) != 1:
        raise ValueError("incomplete year catalog or inconsistent calculation day")
    for pair_id, (mode, src_id, dst_id) in PAIRS.items():
        a, b = records[src_id]["year_data"], records[dst_id]["year_data"]
        if mode == "next" and not (
            a["year_number"] + 1 == b["year_number"]
            and a["close_gate_index"] == b["open_gate_index"]
            and a["close_gate_day"] == b["open_gate_day"]
        ):
            raise ValueError("next-year boundary mismatch on " + pair_id)
        if mode == "previous" and not (
            a["year_number"] - 1 == b["year_number"]
            and a["open_gate_index"] == b["close_gate_index"]
            and a["open_gate_day"] == b["close_gate_day"]
        ):
            raise ValueError("previous-year boundary mismatch on " + pair_id)
    return records


def row_values(year):
    return "ROW(" + ",".join(str(year[k]) for k in FIELDS) + ")::pastafari_sql_tamil.year_rec"


def make_sql(pair_id, records):
    if pair_id not in PAIRS:
        raise ValueError("unknown diagnostic pair")
    mode, src_id, dst_id = PAIRS[pair_id]
    src, dst = records[src_id], records[dst_id]
    return (
        "CREATE TEMP TABLE slice25_hop_input (\n"
        "  pair_id text PRIMARY KEY, mode text NOT NULL, calculation_day numeric NOT NULL,\n"
        "  source_year pastafari_sql_tamil.year_rec NOT NULL,\n"
        "  expected_year pastafari_sql_tamil.year_rec NOT NULL\n"
        ");\n"
        "INSERT INTO slice25_hop_input VALUES ("
        + "'" + pair_id + "','" + mode + "'," + str(src["calculation_day"]) + ","
        + row_values(src["year_data"]) + "," + row_values(dst["year_data"]) + ");\n"
    )


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--locked-records", required=True, type=Path)
    p.add_argument("--pair", choices=sorted(PAIRS))
    p.add_argument("--output", type=Path)
    p.add_argument("--self-test", action="store_true")
    args = p.parse_args()
    records = load_records(args.locked_records)
    if args.self_test:
        for pair_id in PAIRS:
            text = make_sql(pair_id, records)
            if text.count("INSERT INTO slice25_hop_input VALUES") != 1 or text.count("::pastafari_sql_tamil.year_rec") != 2:
                raise AssertionError("bad SQL fixture generation: " + pair_id)
        print("SLICE25_HOP_GENERATOR_SELF_TEST=7/7 PASS")
        return
    if not args.pair or not args.output:
        p.error("--pair and --output required unless --self-test")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(make_sql(args.pair, records), encoding="utf-8")
    print("SLICE25_HOP_SOURCE_LOCK=8_years_7_pairs PASS")
    print("SLICE25_HOP_INPUT_GENERATED=" + args.pair)


if __name__ == "__main__":
    main()
