#!/usr/bin/env python3
"""Source-pinned Stage20 native gate. Green result alone is not stage acceptance."""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys

import stage20_initial_bowls_fixture as fixture

E = Path("evidence/stage20_native")
SOURCE = os.environ["SOURCE_PIN"]
RUNTIME = os.environ["RUNTIME_PIN"]
LOCKED = (
    "src/bigint.false",
    "src/monster_bootstrap.false",
    "test/stage20_initial_bowls_design_vectors.json",
    "tools/stage20_initial_bowls_design_oracle.mjs",
    "tools/stage20_initial_bowls_fixture.py",
    "tools/stage20_initial_bowls_ci.py",
    "tools/stage20_initial_bowls_offline_audit.py",
    "RUN_STAGE20.md",
    "STAGE_20_EXECUTION_STATUS.txt",
    ".github/workflows/false-arabic-stage20-native-initial-bowls.yml",
    ".github/workflows/canonical-names-lock.yml",
)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def verified_source(path):
    locked = subprocess.check_output(["git", "show", f"{SOURCE}:{path}"])
    actual = Path(path).read_bytes()
    assert locked == actual, ("SOURCE_DRIFT", path)
    return actual


def marker_stream(data):
    # Original interpreter may inject CR/LF into an otherwise exact marker.
    return data.decode("utf-8", "replace").replace("\r", "").replace("\n", "")


def execute(label, body, seconds):
    program = E / (label + ".false")
    program.write_bytes(body)
    try:
        proc = subprocess.run(
            ["upstream/false_int", "-e", str(program)],
            capture_output=True, timeout=seconds, check=False,
        )
        result = (proc.returncode, proc.stdout, proc.stderr)
    except subprocess.TimeoutExpired as exc:
        result = (124, exc.stdout or b"", exc.stderr or b"")
    (E / (label + ".exit_code.txt")).write_text(str(result[0]) + "\n")
    (E / (label + ".stdout.txt")).write_bytes(result[1])
    (E / (label + ".stderr.txt")).write_bytes(result[2])
    return result


def main():
    E.mkdir(parents=True, exist_ok=True)
    assert (E / "source_observed.txt").read_text().strip() == SOURCE
    assert (E / "runtime_observed.txt").read_text().strip() == RUNTIME
    assert (E / "compiler_exit_code.txt").read_text().strip() == "0"
    assert (E / "preflight.txt").read_text().strip() == "ORIGINAL_UNICODE_PICK_PREFLIGHT_PASS"
    blobs = {path: verified_source(path) for path in LOCKED}
    source = blobs["src/monster_bootstrap.false"].decode()
    assert source.count('z;37=~["E_INITIAL_BOWLS_LAYOUT"') == 1
    prefix = blobs["src/bigint.false"] + b"\n" + blobs["src/monster_bootstrap.false"] + b"\n"
    fixture_summary = fixture.integrity()
    body, wanted, checks = fixture.positive()
    assert sha(body.encode()) == fixture_summary["body_sha256"]
    code, stdout, stderr = execute("positive", prefix + body.encode(), 300)
    text = marker_stream(stdout)
    labels = re.findall(r"STAGE20_CASE_\d{3}_OK", text)
    expected_stream = "".join(wanted) + fixture.FINAL
    positive_ok = (
        code == 0 and stderr == b"" and labels == wanted and
        text == expected_stream and
        not re.search(r"STAGE20_[A-Z0-9_]+_FAIL", text)
    )
    controls = {}
    for name in fixture_summary["invalid"]:
        expected = "E_INITIAL_BOWLS_LENGTH" if name.startswith("header") else "E_INITIAL_BOWLS_DIRECTION"
        ec, out, err = execute("invalid_" + name, prefix + fixture.invalid(name).encode(), 30)
        observed = marker_stream(out + err)
        controls[name] = dict(exit_code=ec, expected=expected,
                              rejected=ec == 1 and expected in observed and
                              "STAGE20_INVALID_ACCEPTED" not in observed)
    mutants = {}
    for name in fixture_summary["mutants"]:
        mb, _, _ = fixture.positive(mutant=name)
        # One complete case is enough; the mutation is applied to the first output.
        ec, out, err = execute("mutant_" + name, prefix + mb.encode(), 60)
        observed = marker_stream(out + err)
        expected = "STAGE20_CASE_000_OUT_1_CELL_0_FAIL" if name == "wrong_sign" else "STAGE20_CASE_000_OUT_1_CELL_2_FAIL"
        # wrong_numeric changes the first 512 digit (cell offset 2)
        mutants[name] = dict(exit_code=ec, expected=expected,
                             rejected=ec == 1 and expected in observed and
                             fixture.FINAL not in observed)
    passed = positive_ok and all(x["rejected"] for x in controls.values()) and all(x["rejected"] for x in mutants.values())
    evidence = {
        "project_id": os.environ["PROJECT_ID"], "stage": 20,
        "github_sha": os.getenv("GITHUB_SHA"), "github_run_id": os.getenv("GITHUB_RUN_ID"),
        "source_pin": SOURCE, "runtime_pin": RUNTIME,
        "source_sha256": {path: sha(blob) for path, blob in blobs.items()},
        "combined_source_sha256": sha(prefix),
        "fixture": fixture_summary,
        "positive": dict(exit_code=code, stderr_empty=not stderr,
                         cases=len(labels), expected_cases=len(wanted),
                         assertions=checks, passed=positive_ok,
                         body_sha256=sha(body.encode())),
        "invalid": controls, "mutants": mutants, "native_gate_passed": passed,
        "independent_offline_audit": False, "stage20_accepted": False,
        "physical_pointer_safety_assessed": False,
    }
    (E / "evidence.json").write_text(json.dumps(evidence, indent=2, sort_keys=True) + "\n")
    print(json.dumps(evidence, sort_keys=True))
    if not passed:
        sys.exit("STAGE20_NATIVE_GATE_NOT_VERIFIED")


if __name__ == "__main__":
    main()
