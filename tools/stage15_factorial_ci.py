#!/usr/bin/env python3
"""Exact-source bounded original-FALSE gate for Stage 15."""

import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys

import stage15_factorial_oracle as oracle

E = Path("evidence")
SOURCE = os.environ["SOURCE_PIN"]
RUNTIME = os.environ["RUNTIME_PIN"]
PATHS = ("src/bigint.false", "src/monster_bootstrap.false",
         "test/stage15_factorial_7.false")


def sha(data):
    return hashlib.sha256(data).hexdigest()


def locked(path):
    value = subprocess.check_output(["git", "show", f"{SOURCE}:{path}"])
    assert Path(path).read_bytes() == value, ("source drift", path)
    return value


def run(label, program):
    path = E/f"{label}.false"
    path.write_bytes(program)
    try:
        p = subprocess.run(["upstream/false_int", "-e", str(path)],
                           capture_output=True, timeout=25)
        code, stdout, stderr = p.returncode, p.stdout, p.stderr
    except subprocess.TimeoutExpired as exc:
        code, stdout, stderr = 124, exc.stdout or b"", exc.stderr or b""
    (E/f"{label}.exit_code.txt").write_text(f"{code}\n")
    (E/f"{label}.stdout.txt").write_bytes(stdout)
    (E/f"{label}.stderr.txt").write_bytes(stderr)
    return code, stdout.decode(), stderr


def main():
    assert (E/"source_observed.txt").read_text().strip() == SOURCE
    assert (E/"runtime_observed.txt").read_text().strip() == RUNTIME
    assert (E/"compiler_exit_code.txt").read_text().strip() == "0"
    assert (E/"preflight.txt").read_text().strip() == "ORIGINAL_UNICODE_PICK_PREFLIGHT_PASS"
    files = [locked(path) for path in PATHS]
    locked("tools/stage15_factorial_oracle.py")
    assert sha(files[-1]) == os.environ["FIXTURE_SHA256"]
    combined = b"\n".join(files) + b"\n"
    assert sha(combined) == os.environ["COMBINED_SHA256"]
    generated, cases = oracle.build()
    assert generated.encode() == files[-1] and len(cases) == 9
    prefix = b"\n".join(files[:2]) + b"\n"
    mutated, _ = oracle.build(mutant=True)
    positive = run("native", combined)
    mutant = run("mutant", prefix + mutated.encode())
    invalid = {name: run(name, prefix + oracle.invalid(name).encode())
               for name in ("below", "above", "missing_argument")}
    labels = re.findall(r"STAGE15_FACTORIAL_\d{2}_OK", positive[1])
    good = (positive[0] == 0 and positive[2] == b"" and
            labels == [case["label"] for case in cases] and
            positive[1].count(oracle.FINAL) == 1 and
            positive[1].rstrip().endswith(oracle.FINAL) and
            mutant[0] == 1 and "STAGE15_FACTORIAL_00_FAIL" in mutant[1] and
            oracle.FINAL not in mutant[1] and
            all(invalid[name][0] == 1 and "E_FACTORIAL_DOMAIN" in invalid[name][1]
                for name in ("below", "above")) and
            invalid["missing_argument"][0] == 1 and
            oracle.FINAL not in invalid["missing_argument"][1])
    receipt = {"project_id": os.environ["PROJECT_ID"], "stage": 15,
               "github_run_id": os.environ.get("GITHUB_RUN_ID"),
               "github_sha": os.environ.get("GITHUB_SHA"),
               "source_pin": SOURCE, "source_observed": SOURCE,
               "runtime_pin": RUNTIME, "runtime_observed": RUNTIME,
               "combined_sha256": sha(combined), "fixture_sha256": sha(files[-1]),
               "result_assertions": 7, "replay_assertions": 2,
               "negative_controls": 4, "case_labels": labels,
               "native_exit_code": positive[0], "mutant_exit_code": mutant[0],
               "invalid_exit_codes": {n: v[0] for n, v in invalid.items()},
               "factorial_native_verified": good,
               "stage15_full_acceptance": False}
    (E/"oracle.json").write_text(json.dumps({"cases": cases, "fixture_sha256": sha(files[-1]),
        "domain": [0, 6], "invalid_cases": list(invalid)}, indent=2, sort_keys=True)+"\n")
    (E/"evidence.json").write_text(json.dumps(receipt, indent=2, sort_keys=True)+"\n")
    print(json.dumps(receipt, sort_keys=True))
    if not good:
        sys.exit("STAGE15_FACTORIAL_NATIVE_NOT_VERIFIED")


if __name__ == "__main__":
    main()
