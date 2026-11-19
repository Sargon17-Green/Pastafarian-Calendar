#!/usr/bin/env python3
"""Exact-source bounded Native gate for Stage 13 predecessor lookup."""

import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys

import stage13_visible_predecessor_oracle as oracle_module

E = Path("evidence")
SOURCE = os.environ["SOURCE_PIN"]
RUNTIME = os.environ["RUNTIME_PIN"]
COMBINED = os.environ["COMBINED_SHA256"]
FIXTURE = os.environ["FIXTURE_SHA256"]
PATHS = ("src/bigint.false", "src/monster_bootstrap.false",
         "test/stage13_visible_predecessor_18.false")
FINAL = oracle_module.FINAL


def sha(blob):
    return hashlib.sha256(blob).hexdigest()


def locked(path):
    blob = subprocess.check_output(["git", "show", f"{SOURCE}:{path}"])
    assert blob == Path(path).read_bytes(), ("source drift", path)
    return blob


def run(label, path, seconds=20):
    try:
        p = subprocess.run(["upstream/false_int", "-e", str(path)],
                           capture_output=True, timeout=seconds)
        code, out, err = p.returncode, p.stdout, p.stderr
    except subprocess.TimeoutExpired as exc:
        code, out, err = 124, exc.stdout or b"", exc.stderr or b""
    (E/f"{label}.exit_code.txt").write_text(str(code)+"\n")
    (E/f"{label}.stdout.txt").write_bytes(out)
    (E/f"{label}.stderr.txt").write_bytes(err)
    return code, out.decode("utf-8"), err


def main():
    assert (E/"source_observed.txt").read_text().strip() == SOURCE
    assert (E/"runtime_observed.txt").read_text().strip() == RUNTIME
    assert (E/"compiler_exit_code.txt").read_text().strip() == "0"
    assert (E/"preflight.txt").read_text().strip() == "ORIGINAL_UNICODE_PICK_PREFLIGHT_PASS"
    files = [locked(p) for p in PATHS]
    locked("tools/stage13_visible_predecessor_oracle.py")
    locked("tools/stage13_visible_predecessor_design_oracle.py")
    assert sha(files[-1]) == FIXTURE
    combined = b"\n".join(files)+b"\n"
    assert sha(combined) == COMBINED
    exact = E/"stage13_visible_predecessor_exact.false"
    exact.write_bytes(combined)
    program, cases = oracle_module.build()
    assert program.encode() == files[-1] and len(cases) == 18
    oracle = {"project_id": os.environ["PROJECT_ID"], "stage": 13,
              "native_evidence": False, "handle_assertions": 18,
              "value_assertions": 18, "shape_assertions": 36,
              "negative_cases": [list(x) for x in oracle_module.NEGATIVE],
              "fixture_sha256": FIXTURE, "cases": cases}
    (E/"oracle.json").write_text(json.dumps(oracle, indent=2, sort_keys=True)+"\n")
    needle = b"q;r;=e;!"
    assert files[-1].count(needle) == 18
    prefix = b"\n".join(files[:2])+b"\n"
    mutant = E/"mutant.false"
    mutant.write_bytes(prefix+files[-1].replace(needle,b"q;s;=e;!",1)+b"\n")
    invalid = {}
    for name,index,back,hidden_length,prefix_length,marker in oracle_module.NEGATIVE:
        path = E/f"{name}.false"
        path.write_bytes(prefix+oracle_module.invalid(index,back,hidden_length,prefix_length).encode())
        invalid[name] = (path,marker)
    positive = run("native",exact)
    mutant_result = run("mutant",mutant)
    negatives = {name:run(name,path,10) for name,(path,_) in invalid.items()}
    labels = re.findall(r"STAGE13_PREDECESSOR_CASE_\d{2}_[137]_OK", positive[1])
    expected = [c["label"] for c in cases]
    good = (positive[0] == 0 and positive[2] == b"" and labels == expected
            and positive[1].count(FINAL) == 1
            and positive[1].rstrip().endswith(FINAL)
            and "STAGE13_PREDECESSOR_FAILURE" not in positive[1]
            and mutant_result[0] == 1
            and "STAGE13_PREDECESSOR_FAILURE" in mutant_result[1]
            and FINAL not in mutant_result[1]
            and all(negatives[name][0] == 1 and marker in negatives[name][1]
                    and FINAL not in negatives[name][1]
                    for name,(_,marker) in invalid.items()))
    receipt = {"project_id":os.environ["PROJECT_ID"],
               "github_run_id":os.environ.get("GITHUB_RUN_ID"),
               "github_sha":os.environ.get("GITHUB_SHA"),
               "source_pin":SOURCE,"source_observed":SOURCE,
               "runtime_pin":RUNTIME,"runtime_observed":RUNTIME,
               "combined_sha256":COMBINED,"fixture_sha256":FIXTURE,
               "case_labels":labels,"handle_assertions":18,
               "value_assertions":18,"shape_assertions":36,
               "native_exit_code":positive[0],
               "negative_exit_codes":[mutant_result[0]]+
                   [negatives[name][0] for name,*_ in oracle_module.NEGATIVE],
               "predecessor_native_verified":good,
               "stage13_full_acceptance":False}
    (E/"evidence.json").write_text(json.dumps(receipt,indent=2,sort_keys=True)+"\n")
    print(json.dumps(receipt,sort_keys=True))
    if not good:
        sys.exit("STAGE13_PREDECESSOR_NATIVE_NOT_VERIFIED")


if __name__ == "__main__":
    main()
