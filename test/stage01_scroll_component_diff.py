#!/usr/bin/env python3
"""Compare exact independent Scroll components in Foundation context; not full Stage1."""
import argparse
import json
import subprocess
from pathlib import Path
from stage01_scroll_gate_independent import one_gate_step, foundation_year_5000
from stage01_scroll_cutlets_independent import foundation_cutlets
from stage01_scroll_months_independent import foundation_months
from stage01_scroll_month_names_independent import foundation_names

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--gate-exe", type=Path, required=True)
    p.add_argument("--candidate", type=Path, required=True)
    p.add_argument("--output", type=Path, required=True)
    a = p.parse_args()
    actual = json.loads(a.candidate.read_text(encoding="utf-8"))
    foundation = -15055671
    if actual["project_id"] != "PC-BRANCH-FORTRAN-ENGLISH" or any(int(actual[k]) != foundation for k in ("calculation_day", "target_day")):
        raise ValueError("wrong project or calculation/target context")
    run = subprocess.run([str(a.gate_exe.resolve())], capture_output=True, text=True, timeout=60, check=True)
    native = {}
    for line in run.stdout.splitlines():
        if not line.startswith("GATE="):
            raise ValueError("unexpected gate output")
        k, day = map(int, line[5:].split(","))
        if k in native:
            raise ValueError("duplicate gate index")
        native[k] = day
    if set(native) != set(range(-10, 11)):
        raise ValueError("missing or extra gate indices")
    expected = {0: 0}
    for sign in (-1, 1):
        day = 0
        for n in range(1, 11):
            day += sign * one_gate_step(sign, n)
            expected[sign*n] = day
    checks = []
    def compare(label, want, got):
        checks.append(dict(label=label, expected=want, actual=got, match=want == got))
    for k in sorted(expected):
        compare("gate_offset_" + str(k), expected[k], native[k])
    y = foundation_year_5000()["year_5000"]
    ny = actual["year"]
    compare("year_number", 5000, ny["number"])
    compare("year_open_gate", y["opening_gate_index"], ny["open_gate_index"])
    compare("year_close_gate", y["closing_gate_index"], ny["close_gate_index"])
    compare("year_open_offset", y["opening_gate_day_offset"], int(ny["open_gate_day"])-foundation)
    compare("year_close_offset", y["closing_gate_day_offset"], int(ny["close_gate_day"])-foundation)
    compare("year_day_count", y["calendar_day_count"], ny["day_count"])
    c = foundation_cutlets()
    nc = actual["cutlets"]
    compare("cutlet_partition", c["gate_steps_partition"], nc["partition_gate_intervals"])
    compare("cutlet_names", [v["name_index_1based"] for v in c["cutlets"]], nc["name_indices"])
    compare("cutlet_first_offsets", [v["first_day_offset"] for v in c["cutlets"]], [int(v)-foundation for v in nc["first_days"]])
    compare("cutlet_last_offsets", [v["last_day_offset"] for v in c["cutlets"]], [int(v)-foundation for v in nc["last_days"]])
    partial = c["foundation_day_partial_date"]
    compare("foundation_cutlet_position", partial["cutlet_index_1based"], actual["cutlet_position"])
    compare("foundation_day_in_cutlet", partial["day_in_cutlet"], actual["date_fields"]["day_in_cutlet"])
    compare("foundation_cutlet_name_index", c["cutlets"][partial["cutlet_index_1based"]-1]["name_index_1based"], actual["date_fields"]["cutlet_canonical_index"])
    m = foundation_months()
    compare("month_count", m["month_count"], ny["month_count"])
    compare("month_lengths", m["month_lengths"], actual["months"]["lengths"])
    compare("month_names", foundation_names()["month_name_indices_1based"], actual["months"]["name_indices"])
    if len(checks) != 37:
        raise AssertionError("unexpected check count")
    matched = sum(x["match"] for x in checks)
    report = dict(project_id=actual["project_id"], calculation_day=foundation, target_day=foundation,
                  matched=matched, total=len(checks), scroll_snapshot_hash_verified=False,
                  full_stage1_accepted=False, weaving_independently_compared=False, checks=checks)
    a.output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    for x in checks:
        if not x["match"]:
            print("MISMATCH", json.dumps(x))
    print(f"STAGE01_SCROLL_COMPONENT_EXACT_DIFF={matched}/{len(checks)}")
    print("STAGE01_SCROLL_COMPONENT_DIFF_NOT_FULL_STAGE1_ACCEPTANCE")
    return 0 if matched == len(checks) else 1

if __name__ == "__main__":
    raise SystemExit(main())
