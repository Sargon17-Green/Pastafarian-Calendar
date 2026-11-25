#!/usr/bin/env python3
"""Source/runtime-pinned Stage22 Native acceptance gate; does not accept the stage itself."""
import json
import os
from pathlib import Path
import subprocess
import sys
import stage22_native_diagnostic as d

E = Path("evidence/stage22_acceptance")
RUNTIME_PIN = "eb3135565a8670cced3f6bbca4dbf7b014c45634"
LOCKED = d.FILES


def git(*args):
    return subprocess.check_output(["git", *args]).decode().strip()


def main():
    source = Path("src/monster_bootstrap.false").read_bytes()
    d.self_check(source)
    if "--self-check" in sys.argv:
        return
    E.mkdir(parents=True, exist_ok=True)
    pin = os.environ["SOURCE_PIN"]
    runtime = os.environ["RUNTIME_PIN"]
    assert runtime == RUNTIME_PIN
    assert git("rev-parse", "HEAD") == pin
    assert (E / "source_observed.txt").read_text().strip() == pin
    assert (E / "runtime_observed.txt").read_text().strip() == runtime
    assert (E / "compiler_exit_code.txt").read_text().strip() == "0"
    assert (E / "preflight.txt").read_text().strip() == "ORIGINAL_UNICODE_PICK_PREFLIGHT_PASS"
    assert git("rev-parse", f"{pin}:test/normative_reference.false") == "3e9acc012bedf83294a6ec3cccb081a069556b5b"

    blobs = {}
    for path in LOCKED:
        actual = Path(path).read_bytes()
        assert actual == subprocess.check_output(["git", "show", f"{pin}:{path}"]), path
        blobs[path] = actual
    snapshot = E / "source_snapshot"
    for path, content in blobs.items():
        target = snapshot / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(content)

    base_prefix = blobs["src/bigint.false"] + b"\n"
    report = {
        "project_id": "PC-BRANCH-FALSE-ARABIC",
        "stage": 22,
        "branch": "FALSE+العربية",
        "source_pin": pin,
        "runtime_pin": runtime,
        "run_id": os.getenv("GITHUB_RUN_ID"),
        "source_sha256": {path: d.sha(content) for path, content in blobs.items()},
        "source_git_blob_sha1": {path: git("rev-parse", f"{pin}:{path}") for path in blobs},
        "production_prefix_sha256": d.sha(base_prefix + source + b"\n"),
        "normative_reference_blob_sha1": "3e9acc012bedf83294a6ec3cccb081a069556b5b",
        "positive": {},
        "invalid": {},
        "mutants": {},
        "native_gate_passed": False,
        "independent_offline_audit": False,
        "stage22_accepted": False,
        "physical_pointer_safety_assessed": False,
    }

    def persist():
        (E / "evidence.json").write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")

    def run(group, label, initial, steps, variant, seconds, invalid=None, want=d.MARKER, exitcode=0, mutation=None):
        body, expected, checks, record = d.fixture(initial, steps, invalid=invalid)
        record.update({
            "expected_marker": want,
            "expected_exit_code": exitcode,
            "mutation": mutation,
            "source_variant_sha256": d.sha(variant),
        })
        (E / (label + ".fixture.json")).write_text(json.dumps(record, indent=2) + "\n")
        program = base_prefix + variant + b"\n" + body.encode()
        observation = d.execute(label, program, seconds, want, exitcode)
        report[group][label] = {"record": record, **observation}
        persist()
        return observation["passed"]

    persist()
    cases = ("ones", "witness", "boundary")
    for name in cases:
        for steps in (1, 6):
            label = f"probe{steps}_{name}"
            if not run("positive", label, d.case(name), steps, d.instrument(source, steps), 180):
                sys.exit("STAGE22_PROBE_" + label.upper() + "_NOT_VERIFIED")
    for name in cases:
        if not run("positive", "full_" + name, d.case(name), 12, source, 600):
            sys.exit("STAGE22_FULL_" + name.upper() + "_NOT_VERIFIED")
    if not run("positive", "replay_witness", d.case("witness"), 12, source, 600):
        sys.exit("STAGE22_REPLAY_NOT_VERIFIED")

    for name, reason in d.INVALIDS.items():
        marker = "E_BOWL_BATCH_" + reason
        if not run("invalid", "invalid_" + name, d.case("witness"), 12, source, 30,
                   invalid=name, want=marker, exitcode=1):
            sys.exit("STAGE22_INVALID_" + name.upper() + "_NOT_REJECTED")

    for name in d.MUTANTS:
        variant = d.instrument(d.mutate(source, name), 1)
        marker = d.mutant_marker(name)
        if not run("mutants", "mutant_" + name, d.MUTANT_INPUT, 1, variant, 180,
                   want=marker, exitcode=1, mutation=name):
            sys.exit("STAGE22_MUTANT_" + name.upper() + "_NOT_REJECTED_NUMERICALLY")

    replay_equal = all(
        (E / ("full_witness" + ext)).read_bytes() == (E / ("replay_witness" + ext)).read_bytes()
        for ext in (".false", ".stdout.txt", ".stderr.txt", ".exit_code.txt", ".fixture.json")
    )
    report["replay_byte_identical"] = replay_equal
    report["native_gate_passed"] = (
        replay_equal
        and all(item["passed"] for item in report["positive"].values())
        and all(item["passed"] for item in report["invalid"].values())
        and all(item["passed"] for item in report["mutants"].values())
    )
    persist()
    print("STAGE22_BOUNDED_NATIVE_GATE_" + ("PASS" if report["native_gate_passed"] else "FAIL"))
    if not report["native_gate_passed"]:
        sys.exit(1)


if __name__ == "__main__":
    main()
