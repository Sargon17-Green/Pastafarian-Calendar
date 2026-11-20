#!/usr/bin/env python3
"""Stage 16 exact-source Native gate: immutable remove-by-position (op33)."""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys

import stage16_sequence_remove_oracle as oracle

E = Path("evidence/stage16_native")
SOURCE = os.environ["SOURCE_PIN"]
RUNTIME = os.environ["RUNTIME_PIN"]
PATHS = ("src/bigint.false", "src/monster_bootstrap.false",
         "test/stage16_sequence_remove_14.false")
OTHER_LOCKS = ("tools/stage16_sequence_remove_oracle.py",
               "tools/stage16_sequence_remove_ci.py",
               "tools/stage16_sequence_remove_design_oracle.py",
               "evidence/stage16_sequence_remove_design_oracle_2026-11-19.json")

def sha(blob):
    return hashlib.sha256(blob).hexdigest()

def locked(path):
    recorded = subprocess.check_output(["git", "show", f"{SOURCE}:{path}"])
    assert Path(path).read_bytes() == recorded, ("SOURCE_DRIFT", path)
    return recorded

def run(label, program, seconds=30):
    file = E / (label+".false")
    file.write_bytes(program)
    try:
        p = subprocess.run(["upstream/false_int", "-e", str(file)],
                           capture_output=True, timeout=seconds)
        code, output, errors = p.returncode, p.stdout, p.stderr
    except subprocess.TimeoutExpired as ex:
        code, output, errors = 124, ex.stdout or b"", ex.stderr or b""
    (E/(label+".exit_code.txt")).write_text(str(code)+"\n")
    (E/(label+".stdout.txt")).write_bytes(output)
    (E/(label+".stderr.txt")).write_bytes(errors)
    return code, output.decode("utf-8", "replace"), errors

def main():
    E.mkdir(parents=True, exist_ok=True)
    assert (E/"source_observed.txt").read_text().strip() == SOURCE
    assert (E/"runtime_observed.txt").read_text().strip() == RUNTIME
    assert (E/"compiler_exit_code.txt").read_text().strip() == "0"
    assert (E/"preflight.txt").read_text().strip() == "ORIGINAL_UNICODE_PICK_PREFLIGHT_PASS"
    files = [locked(p) for p in PATHS]
    for p in OTHER_LOCKS:
        locked(p)
    generated, cases = oracle.build()
    assert generated.encode() == files[-1], "FIXTURE_NOT_REPRODUCIBLE"
    assert len(cases) == 14 and sum(c["replay"] for c in cases) == 2
    assert len(oracle.NEGATIVE_MARKERS) == 10
    assert files[-1].count(b'=~["STAGE16_REMOVE_') == 160
    combined = b"\n".join(files)+b"\n"
    prefix = b"\n".join(files[:2])+b"\n"
    positive = run("native", combined, 100)
    mutant, _ = oracle.build(mutant=True)
    mutation = run("mutant", prefix+mutant.encode(), 20)
    invalid = {name: run(name, prefix+oracle.invalid(name).encode(), 20)
               for name in oracle.NEGATIVE_MARKERS}
    labels = re.findall(r"STAGE16_REMOVE_\d{2}_OK", positive[1])
    expected = [c["label"] for c in cases]
    errors = [label for label in re.findall(r"STAGE16_REMOVE_[A-Z0-9_]+_FAIL",positive[1])]
    accepted_native = (
        positive[0] == 0 and positive[2] == b"" and not errors
        and labels == expected
        and positive[1].count(oracle.FINAL) == 1
        and positive[1].rstrip().endswith(oracle.FINAL)
        and mutation[0] == 1 and "STAGE16_REMOVE_00_RESULT_FAIL" in mutation[1]
        and oracle.FINAL not in mutation[1]
        and all(code == 1 and out == marker and oracle.FINAL not in out
                for name, marker in oracle.NEGATIVE_MARKERS.items()
                for code, out, _ in [invalid[name]])
    )
    receipt = {
        "project_id": os.environ["PROJECT_ID"], "stage": 16,
        "github_run_id": os.environ.get("GITHUB_RUN_ID"),
        "github_sha": os.environ.get("GITHUB_SHA"),
        "source_pin": SOURCE, "source_observed": SOURCE,
        "runtime_pin": RUNTIME, "runtime_observed": RUNTIME,
        "source_blob_sha256": {p: sha(b) for p,b in zip(PATHS,files)},
        "combined_sha256": sha(combined), "fixture_sha256": sha(files[-1]),
        "result_cases": 12, "deterministic_replays": 2,
        "positive_assertions_embedded": 160, "invalid_cases": 10,
        "negative_controls": 11, "expected_labels": expected,
        "actual_labels": labels, "native_exit_code": positive[0],
        "mutant_exit_code": mutation[0],
        "invalid_exit_codes": {n:r[0] for n,r in invalid.items()},
        "native_verified": accepted_native, "stage16_full_acceptance": False,
        "truncated_tuple_rejection_verified": False,
        "missing_field_semantics": "negative sentinel in exactly two allocated cells; physically truncated tuple excluded",
        "input_tuple_allocated_cells": 2, "truncated_tuple_in_scope": False,
        "negative_sentinel_values_tested": [-1, -2, -7],
        "bounded_contract_native_verified": accepted_native
    }
    (E/"oracle.json").write_text(json.dumps({
        "cases":cases, "negative_markers":oracle.NEGATIVE_MARKERS,
        "input_output_checks":160, "design_exhaustive_cases":5039,
        "fixture_sha256":sha(files[-1])
    },sort_keys=True,indent=2)+"\n")
    (E/"evidence.json").write_text(json.dumps(receipt,sort_keys=True,indent=2)+"\n")
    print(json.dumps(receipt,sort_keys=True))
    if not accepted_native:
        sys.exit("STAGE16_NATIVE_NOT_VERIFIED")

if __name__ == "__main__":
    main()
