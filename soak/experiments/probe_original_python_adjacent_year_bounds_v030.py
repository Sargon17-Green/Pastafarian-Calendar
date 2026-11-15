#!/usr/bin/env python3
"""Native, unchanged original Python year5000 + previous/next year boundary probe.

No full date conversion; no independent oracle certification. Designed for
short isolated CI runs with pinned source and strict one-shot evidence.
"""
from __future__ import annotations
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import sys

SHA = "75d56765b45892940326f67bd85a2c7c9874c01e43b49ee3553c9f6192d94378"
C = -15055671

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--source", type=Path, required=True)
    p.add_argument("--output", type=Path, required=True)
    a = p.parse_args()
    if a.output.exists():
        raise FileExistsError("no-overwrite original-native boundary evidence")
    source = a.source.resolve()
    if hashlib.sha256(source.read_bytes()).hexdigest() != SHA:
        raise ValueError("pinned Python original hash mismatch")
    sys.dont_write_bytecode = True
    spec = importlib.util.spec_from_file_location("_pinned_py_v030", source)
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    cal = mod.NormativeCalendar()
    central = cal.year5000(C)
    prev = cal.previous_year(C, central)
    next_ = cal.next_year(C, central)
    ordered = (prev, central, next_)
    assert [y.number for y in ordered] == [4999, 5000, 5001]
    assert prev.close_gate_index == central.open_gate_index
    assert prev.close_gate_day == central.open_gate_day
    assert next_.open_gate_index == central.close_gate_index
    assert next_.open_gate_day == central.close_gate_day
    assert all(252 <= y.close_gate_day - y.open_gate_day <= 5778 for y in ordered)
    assert (
        central.open_gate_index,
        central.close_gate_index,
        central.open_gate_day,
        central.close_gate_day
    ) == (-4, 4, -15057703, -15053459)
    rows = []
    for y in ordered:
        row = {
            "calculation_day": str(C),
            "year": str(y.number),
            "open_gate_index": str(y.open_gate_index),
            "close_gate_index": str(y.close_gate_index),
            "open_gate_day": str(y.open_gate_day),
            "close_gate_day": str(y.close_gate_day),
            "first_target_day": str(y.open_gate_day + 1),
            "last_target_day": str(y.close_gate_day),
            "length_days": str(y.close_gate_day - y.open_gate_day)
        }
        rows.append(row)
        print("PINNED_PY_NATIVE_YEAR_BOUNDARY=" + json.dumps(row, sort_keys=True), flush=True)
    a.output.write_text(json.dumps(rows, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    print("PINNED_PY_THREE_YEAR_BOUNDARIES_NOT_YEAR_CONVERSIONS", flush=True)

if __name__ == "__main__":
    main()
