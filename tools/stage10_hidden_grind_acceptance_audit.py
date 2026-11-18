#!/usr/bin/env python3
"""Independent byte and arithmetic audit of Stage 10 Native artifact."""

import argparse
import hashlib
import json
import re
import subprocess
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = "PC-BRANCH-FALSE-ARABIC"
RUN = "44363249164"
WORKFLOW = "bace9bf4f704096564ac75540f2f1502688f806a"
SOURCE = "ab5046ecff16139fefd7eb5c0ea09dfc8daafadf"
RUNTIME = "eb3135565a8670cced3f6bbca4dbf7b014c45634"
COMBINED = "53073a3ec73ec355c6eedba5d8737a125105b1a69fe732be445a7e15b4bc8cb4"
FIXTURE = "afe4ee2f7823107005e903fa4a9ac56821fb101fbc8b2de97e98cdafe170ec4f"


def check(ok, reason):
    if not ok:
        raise ValueError(reason)


def sha(blob):
    return hashlib.sha256(blob).hexdigest()


def git(path, revision):
    return subprocess.check_output(["git", "show", f"{revision}:{path}"], cwd=ROOT)


def verify(path, archive_sha256, overrides=None):
    check(re.fullmatch(r"[0-9a-f]{64}", archive_sha256) is not None, "archive SHA syntax")
    check(sha(path.read_bytes()) == archive_sha256, "artifact SHA")
    with zipfile.ZipFile(path) as z:
        check(z.testzip() is None, "artifact CRC")

        def raw(name):
            return overrides[name] if overrides and name in overrides else z.read(name)

        def read(name):
            return raw(name).decode("utf-8")

        receipt = json.loads(read("evidence.json"))
        oracle = json.loads(read("oracle.json"))
        for key, value in (("project_id", PROJECT), ("github_run_id", RUN),
                           ("github_sha", WORKFLOW), ("source_pin", SOURCE),
                           ("source_observed", SOURCE), ("runtime_pin", RUNTIME),
                           ("runtime_observed", RUNTIME), ("combined_sha256", COMBINED),
                           ("fixture_sha256", FIXTURE)):
            check(receipt.get(key) == value, f"receipt {key}")
        check(receipt.get("hidden_grind_native_verified") is True
              and receipt.get("stage10_full_acceptance") is False, "receipt boundary")
        check(read("source_observed.txt").strip() == SOURCE
              and read("runtime_observed.txt").strip() == RUNTIME, "observed commits")
        workflow = ".github/workflows/false-arabic-stage10-native-hidden-grind.yml"
        check(git(workflow, WORKFLOW) == (ROOT / workflow).read_bytes(), "workflow bytes")
        paths = ("src/bigint.false", "src/monster_bootstrap.false", "test/stage10_hidden_grind_7.false")
        pinned = [git(p, SOURCE) for p in paths]
        combined = b"\n".join(pinned) + b"\n"
        check(sha(pinned[-1]) == FIXTURE and sha(combined) == COMBINED, "source hashes")
        check(raw("stage10_hidden_grind_exact.false") == combined
              and pinned[-1].count(b"27h;!!v:") == 7, "executed fixture coverage")
        check(oracle.get("project_id") == PROJECT and oracle.get("stage") == 10
              and oracle.get("native_evidence") is False
              and (oracle.get("case_count"), oracle.get("result_assertions"),
                   oracle.get("input_assertions")) == (7, 7, 7)
              and oracle.get("invalid_grind") == [0, 8]
              and oracle.get("fixture_sha256") == FIXTURE, "oracle metadata")
        cases = [{"grind": n, "kind": ((n - 1) % 5) + 1,
                  "label": f"STAGE10_HIDDEN_GRIND_{n}_OK"} for n in range(1, 8)]
        check(oracle.get("cases") == cases, "independent seven results")
        out = read("native.stdout.txt")
        final = "STAGE10_HIDDEN_GRIND_7_RESULTS_7_INPUTS_VERIFIED"
        check(re.findall(r"STAGE10_HIDDEN_GRIND_[1-7]_OK", out)
              == [case["label"] for case in cases]
              and out.count(final) == 1 and out.rstrip().endswith(final)
              and "STAGE10_HIDDEN_GRIND_FAILURE" not in out, "Native output")
        check(read("native.exit_code.txt").strip() == "0"
              and raw("native.stderr.txt") == b"", "Native exit/stderr")
        check(read("compiler_exit_code.txt").strip() == "0"
              and read("preflight.txt").strip() == "ORIGINAL_UNICODE_PICK_PREFLIGHT_PASS",
              "compiler/preflight")
        for name, marker in (("mutant", "STAGE10_HIDDEN_GRIND_FAILURE"),
                             ("invalid_0", "E_HIDDEN_GRIND"),
                             ("invalid_8", "E_HIDDEN_GRIND")):
            bad = read(f"{name}.stdout.txt")
            check(read(f"{name}.exit_code.txt").strip() == "1"
                  and marker in bad and final not in bad, f"{name} rejection")
        check(receipt.get("case_labels") == [case["label"] for case in cases]
              and (receipt.get("result_assertions"), receipt.get("input_assertions")) == (7, 7)
              and receipt.get("native_exit_code") == 0
              and receipt.get("negative_exit_codes") == [1, 1, 1], "receipt counts")
    return {"project_id": PROJECT, "stage": 10, "status": "ACCEPTED",
            "audit": "OFFLINE_INDEPENDENT", "run_id": RUN, "workflow_sha": WORKFLOW,
            "source_sha": SOURCE, "runtime_sha": RUNTIME, "archive_sha256": archive_sha256,
            "combined_sha256": COMBINED, "fixture_sha256": FIXTURE,
            "cases": 7, "result_assertions": 7, "input_assertions": 7,
            "negative_controls": ["mutant", "invalid_0", "invalid_8"], "next_stage": 11}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("archive", type=Path)
    p.add_argument("--sha256", required=True)
    p.add_argument("--output", type=Path)
    a = p.parse_args()
    report = verify(a.archive, a.sha256)
    with zipfile.ZipFile(a.archive) as z:
        damaged = json.loads(z.read("oracle.json"))
    damaged["cases"][0]["kind"] = 2
    try:
        verify(a.archive, a.sha256, {"oracle.json": json.dumps(damaged).encode()})
    except ValueError:
        report["audit_negative_control"] = "REJECTED_CORRUPTED_EXPECTED_VALUE"
    else:
        raise SystemExit("AUDIT_NEGATIVE_CONTROL_FAILED")
    output = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if a.output:
        a.output.write_text(output)
    print(output, end="")


if __name__ == "__main__":
    main()
