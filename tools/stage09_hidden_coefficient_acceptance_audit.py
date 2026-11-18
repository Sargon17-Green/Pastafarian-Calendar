#!/usr/bin/env python3
"""Audit exact Stage 9 Native artifact against independently computed 7x4 values."""

import argparse
import hashlib
import json
import re
import subprocess
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = "PC-BRANCH-FALSE-ARABIC"
RUN = "44361993055"
WORKFLOW = "9ddb883133f1a64cd1e12034bd23450eed8f6f0e"
SOURCE = "127ebedf45eeef25da673d1f6b33cdb003b65890"
RUNTIME = "eb3135565a8670cced3f6bbca4dbf7b014c45634"
COMBINED = "66bf60cf2bf090be76b20dd19c24f24e69afe103c6b0b5f6ffca6331bdbfe569"
FIXTURE = "c308fb57856a5147d7245d4ef5b5005f8f37c71ed7ab8505a63f092ad4a815cc"
ARCHIVE = "d42b7fc8316bf09d10f66b4b741af7b2c6143035679c38e046edc32947388f43"


def check(condition, reason):
    if not condition:
        raise ValueError(reason)


def sha(blob):
    return hashlib.sha256(blob).hexdigest()


def git(path, revision):
    return subprocess.check_output(["git", "show", f"{revision}:{path}"], cwd=ROOT)


def verify(path, overrides=None):
    check(sha(path.read_bytes()) == ARCHIVE, "artifact SHA256")
    with zipfile.ZipFile(path) as z:
        check(z.testzip() is None, "artifact CRC")

        def raw(name):
            return overrides[name] if overrides and name in overrides else z.read(name)

        def read(name):
            return raw(name).decode("utf-8")

        receipt = json.loads(read("evidence.json"))
        oracle = json.loads(read("oracle.json"))
        for key, expected in (("project_id", PROJECT), ("github_run_id", RUN),
                              ("github_sha", WORKFLOW), ("source_pin", SOURCE),
                              ("source_observed", SOURCE), ("runtime_pin", RUNTIME),
                              ("runtime_observed", RUNTIME), ("combined_sha256", COMBINED),
                              ("fixture_sha256", FIXTURE)):
            check(receipt.get(key) == expected, f"receipt {key}")
        check(receipt.get("hidden_coefficient_native_verified") is True
              and receipt.get("stage9_full_acceptance") is False, "receipt boundary")
        check(read("source_observed.txt").strip() == SOURCE
              and read("runtime_observed.txt").strip() == RUNTIME, "source/runtime observed")
        wf = ".github/workflows/false-arabic-stage09-native-hidden-coefficient.yml"
        check(git(wf, WORKFLOW) == (ROOT / wf).read_bytes(), "workflow pinned bytes")
        paths = ("src/bigint.false", "src/monster_bootstrap.false",
                 "test/stage09_hidden_coefficient_28.false")
        pinned = [git(p, SOURCE) for p in paths]
        combined = b"\n".join(pinned) + b"\n"
        check(sha(pinned[-1]) == FIXTURE and sha(combined) == COMBINED,
              "pinned source SHA")
        check(raw("stage09_hidden_coefficient_exact.false") == combined,
              "executed exact source")
        check(pinned[-1].count(b"26h;!!v:") == 28, "fixture coverage")
        check(oracle.get("project_id") == PROJECT and oracle.get("stage") == 9
              and oracle.get("native_evidence") is False
              and (oracle.get("case_count"), oracle.get("result_assertions"),
                   oracle.get("input_assertions")) == (28, 28, 56)
              and oracle.get("fixture_sha256") == FIXTURE
              and oracle.get("invalid_indices") == [[0, 1], [8, 1], [1, 0], [1, 5]],
              "oracle metadata")
        expected = []
        labels = []
        for k in range(1, 8):
            for column in range(1, 5):
                label = f"STAGE9_HIDDEN_CASE_{k}_{column}_OK"
                value = (k * 2 + 1, k * 3 + 1, k * 4 + 2, k * 4 + 4)[column - 1]
                expected.append({"k": k, "column": column, "expected": value, "label": label})
                labels.append(label)
        check(oracle.get("cases") == expected, "independent 7x4 arithmetic")
        out = read("native.stdout.txt")
        final = "STAGE9_HIDDEN_28_RESULTS_56_INPUTS_VERIFIED"
        check(re.findall(r"STAGE9_HIDDEN_CASE_[1-7]_[1-4]_OK", out) == labels
              and out.count(final) == 1 and out.rstrip().endswith(final)
              and "STAGE9_HIDDEN_COEFFICIENT_FAILURE" not in out, "Native labels/final")
        check(read("native.exit_code.txt").strip() == "0"
              and raw("native.stderr.txt") == b"", "Native exit/stderr")
        check(read("compiler_exit_code.txt").strip() == "0"
              and read("preflight.txt").strip() == "ORIGINAL_UNICODE_PICK_PREFLIGHT_PASS",
              "compiler/Unicode preflight")
        negatives = ("mutant", "invalid_0_1", "invalid_8_1", "invalid_1_0", "invalid_1_5")
        for name in negatives:
            nout = read(f"{name}.stdout.txt")
            marker = ("STAGE9_HIDDEN_COEFFICIENT_FAILURE" if name == "mutant"
                      else "E_HIDDEN_K" if name in ("invalid_0_1", "invalid_8_1")
                      else "E_HIDDEN_COLUMN")
            check(read(f"{name}.exit_code.txt").strip() == "1"
                  and marker in nout and final not in nout, f"{name} rejected")
        check(receipt.get("case_labels") == labels
              and (receipt.get("result_assertions"), receipt.get("input_assertions")) == (28, 56)
              and receipt.get("native_exit_code") == 0
              and receipt.get("negative_exit_codes") == [1] * 5,
              "receipt counts")
    return {"project_id": PROJECT, "stage": 9, "status": "ACCEPTED",
            "audit": "OFFLINE_INDEPENDENT", "run_id": RUN, "workflow_sha": WORKFLOW,
            "source_sha": SOURCE, "runtime_sha": RUNTIME, "archive_sha256": ARCHIVE,
            "combined_sha256": COMBINED, "fixture_sha256": FIXTURE,
            "cases": 28, "result_assertions": 28, "input_assertions": 56,
            "negative_controls": ["mutant", "invalid_0_1", "invalid_8_1",
                                  "invalid_1_0", "invalid_1_5"], "next_stage": 10}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    result = verify(args.archive)
    with zipfile.ZipFile(args.archive) as z:
        damaged = json.loads(z.read("oracle.json"))
    damaged["cases"][0]["expected"] = 4
    try:
        verify(args.archive, {"oracle.json": json.dumps(damaged).encode()})
    except ValueError:
        result["audit_negative_control"] = "REJECTED_CORRUPTED_EXPECTED_VALUE"
    else:
        raise SystemExit("AUDIT_NEGATIVE_CONTROL_FAILED")
    report = json.dumps(result, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.write_text(report)
    print(report, end="")


if __name__ == "__main__":
    main()
