#!/usr/bin/env python3
"""Bounded exact-source Native gate for Stage 12; acceptance requires a later audit."""

import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys

import stage12_hidden_drops_oracle as oracle_module

E = Path("evidence")
SOURCE = os.environ["SOURCE_PIN"]
RUNTIME = os.environ["RUNTIME_PIN"]
COMBINED = os.environ["COMBINED_SHA256"]
FIXTURE = os.environ["FIXTURE_SHA256"]
PATHS = ("src/bigint.false", "src/monster_bootstrap.false",
         "test/stage12_hidden_drops_21.false")
FINAL = "STAGE12_HIDDEN_21_RESULTS_15_INPUTS_6_REPLAYS_VERIFIED"


def sha(blob):
    return hashlib.sha256(blob).hexdigest()


def locked(path):
    blob = subprocess.check_output(["git", "show", f"{SOURCE}:{path}"])
    assert blob == Path(path).read_bytes(), ("source drift", path)
    return blob


def run(label, program, seconds):
    try:
        p = subprocess.run(["upstream/false_int", "-e", str(program)],
                           capture_output=True, timeout=seconds)
        code, stdout, stderr = p.returncode, p.stdout, p.stderr
    except subprocess.TimeoutExpired as exc:
        code, stdout, stderr = 124, exc.stdout or b"", exc.stderr or b""
    (E / f"{label}.exit_code.txt").write_text(str(code) + "\n")
    (E / f"{label}.stdout.txt").write_bytes(stdout)
    (E / f"{label}.stderr.txt").write_bytes(stderr)
    return code, stdout.decode("utf-8"), stderr


def main():
    assert (E / "source_observed.txt").read_text().strip() == SOURCE
    assert (E / "runtime_observed.txt").read_text().strip() == RUNTIME
    assert (E / "compiler_exit_code.txt").read_text().strip() == "0"
    assert (E / "preflight.txt").read_text().strip() == "ORIGINAL_UNICODE_PICK_PREFLIGHT_PASS"
    files = [locked(path) for path in PATHS]
    locked("tools/stage12_hidden_drops_oracle.py")
    locked("tools/stage12_hidden_drops_design_oracle.py")
    assert sha(files[-1]) == FIXTURE
    combined = b"\n".join(files) + b"\n"
    assert sha(combined) == COMBINED
    exact = E / "stage12_hidden_drops_exact.false"
    exact.write_bytes(combined)
    program, cases = oracle_module.build()
    assert program.encode() == files[-1]
    oracle = {"project_id": os.environ["PROJECT_ID"], "stage": 12,
              "native_evidence": False, "anchor_pairs": 3,
              "result_assertions": 21, "input_assertions": 15,
              "shape_assertions": 3, "replay_assertions": 6,
              "fixture_sha256": FIXTURE, "cases": cases}
    (E / "oracle.json").write_text(json.dumps(oracle, indent=2, sort_keys=True) + "\n")
    assert files[-1].count(b"29h;!!q:") == 3
    needle = b"5h;!!0=e;!"
    assert files[-1].count(needle) >= 21
    mutant = E / "mutant.false"
    mutant.write_bytes(b"\n".join(files[:2]) + b"\n" +
                       files[-1].replace(needle, b"5h;!!1=e;!", 1) + b"\n")
    positive = run("native", exact, 240)
    negative = run("mutant", mutant, 120)
    labels = re.findall(r"STAGE12_HIDDEN_CASE_\d{2}_[1-7]_OK", positive[1])
    expected = [f"STAGE12_HIDDEN_CASE_{index:02d}_{kind}_OK"
                for index in range(3) for kind in range(1, 8)]
    good = (positive[0] == 0 and positive[2] == b""
            and labels == expected and positive[1].count(FINAL) == 1
            and positive[1].rstrip().endswith(FINAL)
            and "STAGE12_HIDDEN_DROPS_FAILURE" not in positive[1]
            and negative[0] == 1
            and "STAGE12_HIDDEN_DROPS_FAILURE" in negative[1]
            and FINAL not in negative[1])
    receipt = {"project_id": os.environ["PROJECT_ID"],
               "github_run_id": os.environ.get("GITHUB_RUN_ID"),
               "github_sha": os.environ.get("GITHUB_SHA"),
               "source_pin": SOURCE, "source_observed": SOURCE,
               "runtime_pin": RUNTIME, "runtime_observed": RUNTIME,
               "combined_sha256": COMBINED, "fixture_sha256": FIXTURE,
               "case_labels": labels, "result_assertions": 21,
               "input_assertions": 15, "shape_assertions": 3,
               "replay_assertions": 6, "native_exit_code": positive[0],
               "mutant_exit_code": negative[0],
               "hidden_drops_native_verified": good,
               "stage12_full_acceptance": False}
    (E / "evidence.json").write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n")
    print(json.dumps(receipt, sort_keys=True))
    if not good:
        sys.exit("STAGE12_HIDDEN_DROPS_NATIVE_NOT_VERIFIED")


if __name__ == "__main__":
    main()
