#!/usr/bin/env python3
"""Stage18 original-runtime, source-pinned Native gate; does not itself ACCEPT the stage."""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys

import stage18_drop_order_fixture as fixture

E = Path("evidence/stage18_native")
SOURCE = os.environ["SOURCE_PIN"]
RUNTIME = os.environ["RUNTIME_PIN"]
LOCKED = (
    "src/bigint.false",
    "src/monster_bootstrap.false",
    "test/stage18_drop_order_design_vectors.json",
    "tools/stage18_drop_order_design_oracle.mjs",
    "tools/stage18_drop_order_fixture.py",
    "tools/stage18_drop_order_ci.py",
)

def sha(b):
    return hashlib.sha256(b).hexdigest()

def source_bytes(path):
    expected = subprocess.check_output(["git", "show", f"{SOURCE}:{path}"])
    actual = Path(path).read_bytes()
    assert actual == expected, ("SOURCE_DRIFT", path)
    return actual

def execute(label, code, timeout_seconds):
    program = E / (label + ".false")
    program.write_bytes(code)
    try:
        proc = subprocess.run(["upstream/false_int", "-e", str(program)],
                              capture_output=True, timeout=timeout_seconds)
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
    blobs = {path: source_bytes(path) for path in LOCKED}
    assert "z;35=~" in blobs["src/monster_bootstrap.false"].decode()
    prefix = blobs["src/bigint.false"] + b"\n" + blobs["src/monster_bootstrap.false"] + b"\n"
    summary = fixture.integrity()
    assert len(summary) == 5 and sum(row["cases"] for row in summary) == 750
    positive_rows = []
    verified = True
    for start, cases in fixture.chunks():
        program, expected, final, checks = fixture.fixture(cases, start)
        assert sha(program.encode()) == next(row["sha256"] for row in summary if row["start"] == start)
        code, output, stderr = execute("positive_" + str(start), prefix + program.encode(), 300)
        text = output.decode("utf-8", "replace")
        labels = re.findall(r"STAGE18_DROP_\d{4}_OK", text)
        errors = re.findall(r"STAGE18_DROP_[A-Z0-9_]+_FAIL", text)
        passed = (code == 0 and stderr == b"" and labels == expected
                  and not errors and text.count(final) == 1 and text.rstrip().endswith(final))
        positive_rows.append(dict(start=start, cases=len(cases), assertions=checks,
                                  exit_code=code, labels_seen=len(labels), passed=passed,
                                  generated_fixture_sha256=sha(program.encode())))
        verified = verified and passed
        if not passed:
            break
    mutants = {}
    first_start, first_cases = fixture.chunks()[0]
    for name, expected_error in (
        ("bad_order", "STAGE18_DROP_0000_OUTPUT_1_FAIL"),
        ("bad_sign", "STAGE18_DROP_0000_SIGN_FAIL"),
    ):
        program, labels, final, checks = fixture.fixture(first_cases[:1], first_start, mutant=name)
        code, output, stderr = execute("mutant_" + name, prefix + program.encode(), 30)
        text = output.decode("utf-8", "replace")
        mutants[name] = dict(exit_code=code,
                             rejected=(code == 1 and expected_error in text and final not in text),
                             expected_error=expected_error, observed_stdout=text)
    passed = verified and len(positive_rows) == 5 and all(x["passed"] for x in positive_rows)
    passed = passed and all(x["rejected"] for x in mutants.values())
    receipt = dict(project_id=os.environ["PROJECT_ID"], stage=18,
                   github_sha=os.getenv("GITHUB_SHA"), github_run_id=os.getenv("GITHUB_RUN_ID"),
                   source_pin=SOURCE, runtime_pin=RUNTIME, source_sha256={p: sha(v) for p, v in blobs.items()},
                   combined_source_sha256=sha(prefix), fixture_generation=summary,
                   positive=positive_rows, positive_cases=sum(x["cases"] for x in positive_rows),
                   output_assertions=sum(x["assertions"] for x in positive_rows),
                   mutants=mutants, native_gate_passed=passed,
                   stage18_accepted=False, independent_offline_artifact_audit=False,
                   physical_bad_pointer_safety_assessed=False)
    (E / "evidence.json").write_text(json.dumps(receipt, sort_keys=True, indent=2) + "\n")
    print(json.dumps(receipt, sort_keys=True))
    if not passed:
        sys.exit("STAGE18_NATIVE_GATE_NOT_VERIFIED")

if __name__ == "__main__":
    main()
