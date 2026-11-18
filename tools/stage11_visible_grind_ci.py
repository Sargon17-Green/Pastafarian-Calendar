#!/usr/bin/env python3
"""Exact-source Stage 11 CI gate; writes bounded evidence and fails closed."""

import hashlib
import json
import os
import pathlib
import re
import subprocess
import sys

import stage11_visible_grind_oracle as oracle_module

E = pathlib.Path("evidence")
SOURCE = os.environ["SOURCE_PIN"]
RUNTIME = os.environ["RUNTIME_PIN"]
COMBINED = os.environ["COMBINED_SHA256"]
FIXTURE = os.environ["FIXTURE_SHA256"]
PATHS = ("src/bigint.false", "src/monster_bootstrap.false",
         "test/stage11_visible_grind_50.false")
FINAL = "STAGE11_VISIBLE_50_RESULTS_100_INPUTS_VERIFIED"


def sha(blob):
    return hashlib.sha256(blob).hexdigest()


def locked(path):
    blob = subprocess.check_output(["git", "show", f"{SOURCE}:{path}"])
    assert blob == pathlib.Path(path).read_bytes(), ("source drift", path)
    return blob


def run(label, program):
    try:
        p = subprocess.run(["upstream/false_int", "-e", str(program)],
                           capture_output=True, timeout=20)
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
    files = [locked(p) for p in PATHS]
    locked("tools/stage11_visible_grind_oracle.py")
    assert sha(files[-1]) == FIXTURE
    combined = b"\n".join(files) + b"\n"
    assert sha(combined) == COMBINED
    exact = E / "stage11_visible_grind_exact.false"
    exact.write_bytes(combined)
    program, cases = oracle_module.build()
    assert program.encode() == files[-1]
    oracle = {"project_id": os.environ["PROJECT_ID"], "stage": 11,
              "native_evidence": False, "case_count": 50,
              "result_assertions": 50, "input_assertions": 100,
              "invalid_indices": [[0, 1], [11, 1], [1, 0], [1, 6]],
              "fixture_sha256": FIXTURE, "cases": cases}
    (E / "oracle.json").write_text(json.dumps(oracle, indent=2, sort_keys=True) + "\n")
    assert files[-1].count(b"28h;!!v:") == 50
    needle = b"v;3=e;!"
    assert files[-1].count(needle) >= 1
    mutant = E / "mutant.false"
    mutant.write_bytes(b"\n".join(files[:2]) + b"\n" +
                       files[-1].replace(needle, b"v;4=e;!", 1) + b"\n")
    invalid = {}
    for grind, column in ((0, 1), (11, 1), (1, 0), (1, 6)):
        name = f"invalid_{grind}_{column}"
        path = E / f"{name}.false"
        path.write_bytes(b"\n".join(files[:2]) + b"\n" +
                         oracle_module.invalid(grind, column).encode())
        invalid[name] = path
    positive = run("native", exact)
    negatives = {"mutant": run("mutant", mutant)}
    negatives.update({name: run(name, path) for name, path in invalid.items()})
    labels = re.findall(r"STAGE11_VISIBLE_CASE_\d{2}_[1-5]_OK", positive[1])
    expected = [c["label"] for c in cases]
    good = (positive[0] == 0 and positive[2] == b""
            and labels == expected and positive[1].count(FINAL) == 1
            and positive[1].rstrip().endswith(FINAL)
            and "STAGE11_VISIBLE_GRIND_FAILURE" not in positive[1]
            and negatives["mutant"][0] == 1
            and "STAGE11_VISIBLE_GRIND_FAILURE" in negatives["mutant"][1]
            and all(negatives[name][0] == 1 and
                    ("E_VISIBLE_GRIND" if name in ("invalid_0_1", "invalid_11_1")
                     else "E_VISIBLE_COLUMN") in negatives[name][1] for name in invalid)
            and all(FINAL not in result[1] for result in negatives.values()))
    receipt = {"project_id": os.environ["PROJECT_ID"],
               "github_run_id": os.environ.get("GITHUB_RUN_ID"),
               "github_sha": os.environ.get("GITHUB_SHA"),
               "source_pin": SOURCE, "source_observed": SOURCE,
               "runtime_pin": RUNTIME, "runtime_observed": RUNTIME,
               "combined_sha256": COMBINED, "fixture_sha256": FIXTURE,
               "case_labels": labels, "result_assertions": 50,
               "input_assertions": 100, "native_exit_code": positive[0],
               "negative_exit_codes": [negatives[name][0]
                                       for name in ("mutant", *invalid)],
               "visible_grind_native_verified": good,
               "stage11_full_acceptance": False}
    (E / "evidence.json").write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n")
    print(json.dumps(receipt, sort_keys=True))
    if not good:
        sys.exit("STAGE11_VISIBLE_GRIND_NATIVE_NOT_VERIFIED")


if __name__ == "__main__":
    main()
