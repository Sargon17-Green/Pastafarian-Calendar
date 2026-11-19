#!/usr/bin/env python3
"""Bounded exact-source Native gate for all 46 Stage 14 visible drops."""

import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys

import stage14_visible_drops_oracle as oracle

E = Path("evidence")
SOURCE = os.environ["SOURCE_PIN"]
RUNTIME = os.environ["RUNTIME_PIN"]
PATHS = ("src/bigint.false", "src/monster_bootstrap.false",
         "test/stage14_visible_drops_46.false")


def sha(data):
    return hashlib.sha256(data).hexdigest()


def locked(path):
    blob = subprocess.check_output(["git", "show", f"{SOURCE}:{path}"])
    assert Path(path).read_bytes() == blob, ("source drift", path)
    return blob


def run(label, program, seconds):
    path = E / f"{label}.false"
    path.write_bytes(program)
    try:
        result = subprocess.run(["upstream/false_int", "-e", str(path)],
                                capture_output=True, timeout=seconds)
        code, stdout, stderr = result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired as exc:
        code, stdout, stderr = 124, exc.stdout or b"", exc.stderr or b""
    (E/f"{label}.exit_code.txt").write_text(f"{code}\n")
    (E/f"{label}.stdout.txt").write_bytes(stdout)
    (E/f"{label}.stderr.txt").write_bytes(stderr)
    return code, stdout.decode("utf-8"), stderr


def main():
    assert (E/"source_observed.txt").read_text().strip() == SOURCE
    assert (E/"runtime_observed.txt").read_text().strip() == RUNTIME
    assert (E/"compiler_exit_code.txt").read_text().strip() == "0"
    assert (E/"preflight.txt").read_text().strip() == "ORIGINAL_UNICODE_PICK_PREFLIGHT_PASS"
    files = [locked(path) for path in PATHS]
    locked("tools/stage14_visible_drops_oracle.py")
    locked("tools/stage14_visible_drops_design_oracle.py")
    assert sha(files[-1]) == os.environ["FIXTURE_SHA256"]
    combined = b"\n".join(files) + b"\n"
    assert sha(combined) == os.environ["COMBINED_SHA256"]
    generated, cases = oracle.build()
    assert generated.encode() == files[-1] and len(cases) == 46
    assert generated.count('"STAGE14_VISIBLE_') == 47
    prefix = b"\n".join(files[:2]) + b"\n"
    mutant, _ = oracle.build(mutant=True)
    assert mutant != generated
    positives = run("native", combined, 1000)
    mutated = run("mutant", prefix + mutant.encode(), 1000)
    negatives = {}
    for name, counts, stones, hidden, marker in oracle.NEGATIVE:
        negatives[name] = run(name, prefix + oracle.invalid(counts, stones, hidden).encode(), 20)
    labels = re.findall(r"STAGE14_VISIBLE_\d{2}_OK", positives[1])
    expected = [case["label"] for case in cases]
    passed = (positives[0] == 0 and positives[2] == b"" and labels == expected
              and positives[1].count(oracle.FINAL) == 1
              and positives[1].rstrip().endswith(oracle.FINAL)
              and mutated[0] == 1 and "STAGE14_VALUE_01_FAILURE" in mutated[1]
              and oracle.FINAL not in mutated[1]
              and all(negatives[name][0] == 1 and marker in negatives[name][1]
                      and oracle.FINAL not in negatives[name][1]
                      for name, _, _, _, marker in oracle.NEGATIVE))
    receipt = {"project_id": os.environ["PROJECT_ID"], "stage": 14,
               "github_run_id": os.environ.get("GITHUB_RUN_ID"),
               "github_sha": os.environ.get("GITHUB_SHA"),
               "source_pin": SOURCE, "source_observed": SOURCE,
               "runtime_pin": RUNTIME, "runtime_observed": RUNTIME,
               "combined_sha256": sha(combined), "fixture_sha256": sha(files[-1]),
               "result_assertions": len(labels), "shape_assertions": 4,
               "negative_assertions": 4, "case_labels": labels,
               "native_exit_code": positives[0], "mutant_exit_code": mutated[0],
               "invalid_exit_codes": {name: result[0] for name, result in negatives.items()},
               "visible_native_verified": passed,
               "stage14_full_acceptance": False}
    (E/"oracle.json").write_text(json.dumps({"cases": cases, "anchor_pairs": 3,
        "seeded_python_pairs": 128, "negative_cases": oracle.NEGATIVE,
        "fixture_sha256": sha(files[-1])}, indent=2, sort_keys=True) + "\n")
    (E/"evidence.json").write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n")
    print(json.dumps(receipt, sort_keys=True))
    if not passed:
        sys.exit("STAGE14_VISIBLE_NATIVE_NOT_VERIFIED")


if __name__ == "__main__":
    main()
