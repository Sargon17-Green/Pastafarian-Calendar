#!/usr/bin/env python3
"""Issue #29 v188: independent original Python witness versus corrected Ada F(c,t).

One signed date only; no other source date calls, no mutation of either original.
The original Python source is pinned to REF-41. The corrected Ada source is
pinned separately by the GitHub workflow and linked into the real Ada binary.
"""
from __future__ import annotations

import hashlib
import importlib.util
import json
import re
import sys
from collections import Counter
from pathlib import Path

DAY = -15055671
EXPECTED = (5000, 10, 503, 20, 56)
SOURCE_SHA256 = "75d56765b45892940326f67bd85a2c7c9874c01e43b49ee3553c9f6192d94378"
ORIGINAL_COMMIT = "0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4"
PREFIX = "ISSUE29_V188_CORRECTED_ADA"

def extract_ada(stdout: str) -> tuple[int, int, int, int, int]:
    if len(stdout) > 16384:
        raise ValueError("unexpected Ada stdout size")
    records = [line.strip() for line in stdout.splitlines()
               if line.startswith(PREFIX)]
    if len(records) != 1 or stdout.count(PREFIX) != 1:
        raise ValueError("expected exactly one corrected Ada date record")
    m = re.fullmatch(
        r"ISSUE29_V188_CORRECTED_ADA\s+(-?\d+)\s+(-?\d+)\s+"
        r"(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)", records[0])
    if m is None:
        raise ValueError("malformed native result")
    numbers = [int(x) for x in m.groups()]
    if numbers[:2] != [DAY, DAY]:
        raise ValueError("native observation for wrong date")
    return tuple(numbers[2:])

def selftest() -> None:
    valid = PREFIX + " -15055671 -15055671  5000  10  503  20  56\n"
    assert extract_ada(valid) == EXPECTED
    for malformed in [
        "", valid+valid,
        valid.replace("-15055671", "-15055670", 1),
        valid.replace("503", "abc"),
        valid.replace(PREFIX, "WRONG"),
        valid.rstrip()+" 9\n",
    ]:
        try:
            extract_ada(malformed)
        except ValueError:
            continue
        raise AssertionError("invalid transcript was accepted")
    print("ISSUE29_V188_PARSER_NEGATIVE_CASES_PASS=6")

def load_original(path: Path):
    content = path.read_bytes()
    digest = hashlib.sha256(content).hexdigest()
    if digest != SOURCE_SHA256:
        raise RuntimeError("frozen original Python source SHA-256 mismatch: "+digest)
    spec = importlib.util.spec_from_file_location("issue29_original_python_v188", path)
    if spec is None or spec.loader is None:
        raise RuntimeError("import failure")
    original = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = original
    spec.loader.exec_module(original)
    return original, digest

def compute_independent_original(path: Path):
    ref, digest = load_original(path)
    observer = ref.NormativeCalendar()
    saved_year = []
    saved_structure = []
    find = observer.find_target_year
    build = observer.build_year_structure

    def selected_year(c, t):
        year = find(c, t)
        saved_year.append(year)
        return year

    def selected_structure(c, year):
        structure = build(c, year)
        saved_structure.append(structure)
        return structure

    observer.find_target_year = selected_year
    observer.build_year_structure = selected_structure
    ids = observer.calendar_date_ids(DAY, DAY)  # exactly one reference date call
    if len(saved_year) != 1 or len(saved_structure) != 1:
        raise AssertionError("unexpected original date-call count")
    year, structure = saved_year[0], saved_structure[0]
    values = (ids.year_number, ids.cutlet_name_index, ids.day_in_cutlet,
              ids.month_name_index, ids.day_in_month)
    if values != EXPECTED:
        raise AssertionError("frozen reference date result changed: "+str(values))
    n = structure.month_count
    lengths = list(structure.month_lengths)
    weave = list(structure.month_weaving)
    names = list(structure.month_name_indices)
    offset0 = DAY - year.open_gate_day - 1
    if not (3 <= n <= 47 and len(names) == n == len(lengths)):
        raise AssertionError("invalid month structure")
    if sum(lengths) != len(weave) or not 0 <= offset0 < len(weave):
        raise AssertionError("invalid full year length or offset")
    if not all(Counter(weave)[i] == lengths[i-1] for i in range(1, n+1)):
        raise AssertionError("weave multiplicity violation")
    month_id = weave[offset0]
    if names[month_id-1] != values[3]:
        raise AssertionError("wrong month-name projection")
    if sum(int(x == month_id) for x in weave[:offset0+1]) != values[4]:
        raise AssertionError("wrong day-in-month projection")
    first,last = {}, {}
    for i,month in enumerate(weave):
        first.setdefault(month,i)
        last[month] = i
    if [first[i] for i in range(1,n+1)] != sorted(first.values()):
        raise AssertionError("month first-occurrence order violation")
    if [last[i] for i in range(1,n+1)] != sorted(last.values()):
        raise AssertionError("month last-occurrence order violation")
    return {
        "sha256":digest, "commit":ORIGINAL_COMMIT, "calls":1,
        "year":year.number, "length":len(weave),
        "month_count":n, "month_lengths":lengths, "month_name_indices":names,
        "offset0":offset0, "month_id":month_id,
        "first_twelve_month_ids":weave[:12], "date":list(values),
        "full_weave_sha256":hashlib.sha256(
            (",".join(map(str,weave))+"\n").encode("ascii")).hexdigest(),
        "projection_invariants_passed":True,
    }

def main() -> None:
    if len(sys.argv) == 2 and sys.argv[1] == "selftest":
        selftest()
        return
    if len(sys.argv) != 5 or sys.argv[1] != "compare":
        raise SystemExit("usage: oracle.py selftest | compare ADA_STDOUT PINNED_PYTHON.py OUT.json")
    ada_path, py_path, out_path = map(Path, sys.argv[2:])
    native_bytes = ada_path.read_bytes()
    native = extract_ada(native_bytes.decode("utf-8"))
    python = compute_independent_original(py_path)
    reference = tuple(python["date"])
    if native != reference:
        status = "CORRECTED_ADA_VS_ORIGINAL_PYTHON_NUMERIC_MISMATCH"
    else:
        status = "ONE_CORRECTED_ADA_DATE_MATCHES_ORIGINAL_PYTHON_NOT_YEAR"
    report = {
        "schema":"ISSUE29_V188_CORRECTED_ONE_DAY_DIFFERENTIAL/1",
        "status":status, "calculation_day":DAY, "target_day":DAY,
        "ada_source_commit":"1160096aa847c54cbef27c232771ce1549d7ba8f",
        "source_scope":"corrected existing single GMP full-family weave patch",
        "ada_date_calls":1, "python_original_date_calls":python["calls"],
        "ada_final":list(native), "python_original":python,
        "native_stdout_sha256":hashlib.sha256(native_bytes).hexdigest(),
        "historical_original_ada_fail":[5000,10,503,30,52],
        "full_years_accepted":0,
        "whole_year_or_algorithm_proof":False,
    }
    raw = (json.dumps(report,sort_keys=True,ensure_ascii=False,indent=2)+"\n").encode("utf-8")
    if len(raw) > 2_000_000:
        raise RuntimeError("receipt too large")
    out_path.write_bytes(raw)
    print("ISSUE29_V188_ADA_FIVE_FIELDS="+json.dumps(list(native)))
    print("ISSUE29_V188_PYTHON_FIVE_FIELDS="+json.dumps(list(reference)))
    print("ISSUE29_V188_STATUS="+status)
    print("ISSUE29_V188_VERDICT_SHA256="+hashlib.sha256(raw).hexdigest())
    if native != reference:
        raise SystemExit(6)

if __name__ == "__main__":
    main()
