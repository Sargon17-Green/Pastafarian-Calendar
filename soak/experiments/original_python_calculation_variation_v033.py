#!/usr/bin/env python3
"""Pinned Python ORIGINAL year-5000 navigator for new calculation coordinates.

This only invokes NormativeCalendar.year5000(c), not F(c,t), and proves
neither canonical correctness nor algorithmic source independence.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import sys

ORIGINAL_SHA = "75d56765b45892940326f67bd85a2c7c9874c01e43b49ee3553c9f6192d94378"
CASES = (-15055672, -15055670, -15054671)
HEADERS = ("calculation_day", "year", "open_gate_index", "close_gate_index",
           "open_gate_day", "close_gate_day", "first_target_day",
           "last_target_day", "length_days")


def original(path: Path):
    if hashlib.sha256(path.read_bytes()).hexdigest() != ORIGINAL_SHA:
        raise ValueError("original normative Python source hash mismatch")
    sys.dont_write_bytecode = True
    spec = importlib.util.spec_from_file_location("_native_calculation_variation_v033", path.resolve())
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    return mod


def boundary_row(c: int, y):
    length = y.close_gate_day - y.open_gate_day
    if not (252 <= length <= 5778 and
            y.open_gate_day < c <= y.close_gate_day and
            y.close_gate_index - y.open_gate_index >= 6):
        raise ValueError("native original 5000 calculation year invalid")
    values = (c, y.number, y.open_gate_index, y.close_gate_index,
              y.open_gate_day, y.close_gate_day,
              y.open_gate_day + 1, y.close_gate_day, length)
    if y.number != 5000 or any(type(v) is not int for v in values):
        raise ValueError("unexpected native year or noninteger original fields")
    return dict(zip(HEADERS, (str(v) for v in values)))


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--original-source", type=Path, required=True)
    p.add_argument("--output", type=Path, required=True)
    args = p.parse_args()
    if args.output.exists():
        raise FileExistsError("original source evidence no-overwrite")
    mod = original(args.original_source)
    out = []
    for c in CASES:
        row = boundary_row(c, mod.NormativeCalendar().year5000(c))
        out.append(row)
        print("PY_NATIVE_ALTERNATE_CALCULATION_BOUNDARY=" +
              json.dumps(row, sort_keys=True), flush=True)
    args.output.write_text(json.dumps(out, sort_keys=True, indent=2) + "\n", encoding="utf8")
    print("PY_NATIVE_YEAR5000_CHANGED_CALCULATION_CASES="+str(len(out)), flush=True)


if __name__ == "__main__":
    main()
