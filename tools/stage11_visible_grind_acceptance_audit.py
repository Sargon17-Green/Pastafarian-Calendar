#!/usr/bin/env python3
"""Independent prime-derived audit of pinned Stage 11 Native artifact."""

import argparse
import hashlib
import json
import math
import re
import subprocess
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = "PC-BRANCH-FALSE-ARABIC"
RUN = "44364391828"
WORKFLOW = "8372aed80312f163a58615063df17f9b1237c268"
SOURCE = "34120b256d21ff5b931f17a5c97236076e2cfa98"
RUNTIME = "eb3135565a8670cced3f6bbca4dbf7b014c45634"
COMBINED = "ac1ec6efc77c34514853d3691660706a615d077fd31ce531a53b32f62788c51f"
FIXTURE = "2cdead9481eb2e8095300d321e08681b4756bc66c6f61aea4ddb25d4fd029a16"


def check(ok, reason):
    if not ok:
        raise ValueError(reason)


def sha(blob):
    return hashlib.sha256(blob).hexdigest()


def git(path, revision):
    return subprocess.check_output(["git", "show", f"{revision}:{path}"], cwd=ROOT)


def independent_cases():
    primes = []
    for candidate in range(3, 44):
        if not any(candidate % d == 0 for d in range(2, math.isqrt(candidate) + 1)):
            primes.append(candidate)
    check(len(primes) == 13, "prime count")
    result = []
    for grind in range(1, 11):
        for column in range(1, 6):
            value = ((grind - 1) % 5 + 1 if column == 5
                     else primes[grind + column - 2])
            result.append({"grind": grind, "column": column, "expected": value,
                           "label": f"STAGE11_VISIBLE_CASE_{grind:02d}_{column}_OK"})
    return result


def verify(path, archive_sha256, overrides=None):
    check(re.fullmatch(r"[0-9a-f]{64}", archive_sha256) is not None, "archive SHA syntax")
    check(sha(path.read_bytes()) == archive_sha256, "archive SHA")
    with zipfile.ZipFile(path) as z:
        check(z.testzip() is None, "archive CRC")

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
        check(receipt.get("visible_grind_native_verified") is True
              and receipt.get("stage11_full_acceptance") is False, "receipt boundary")
        check(read("source_observed.txt").strip() == SOURCE
              and read("runtime_observed.txt").strip() == RUNTIME, "observed commits")
        workflow = ".github/workflows/false-arabic-stage11-native-visible-grind.yml"
        script = "tools/stage11_visible_grind_ci.py"
        check(git(workflow, WORKFLOW) == (ROOT / workflow).read_bytes()
              and git(script, WORKFLOW) == (ROOT / script).read_bytes(),
              "workflow and runner bytes")
        paths = ("src/bigint.false", "src/monster_bootstrap.false",
                 "test/stage11_visible_grind_50.false")
        pinned = [git(p, SOURCE) for p in paths]
        combined = b"\n".join(pinned) + b"\n"
        check(sha(pinned[-1]) == FIXTURE and sha(combined) == COMBINED,
              "pinned source hashes")
        check(raw("stage11_visible_grind_exact.false") == combined
              and pinned[-1].count(b"28h;!!v:") == 50, "executed source/coverage")
        check(oracle.get("project_id") == PROJECT and oracle.get("stage") == 11
              and oracle.get("native_evidence") is False
              and (oracle.get("case_count"), oracle.get("result_assertions"),
                   oracle.get("input_assertions")) == (50, 50, 100)
              and oracle.get("fixture_sha256") == FIXTURE
              and oracle.get("invalid_indices") == [[0, 1], [11, 1], [1, 0], [1, 6]],
              "oracle metadata")
        cases = independent_cases()
        check(oracle.get("cases") == cases, "independent 10x5 arithmetic")
        output = read("native.stdout.txt")
        final = "STAGE11_VISIBLE_50_RESULTS_100_INPUTS_VERIFIED"
        labels = [case["label"] for case in cases]
        check(re.findall(r"STAGE11_VISIBLE_CASE_\d{2}_[1-5]_OK", output) == labels
              and output.count(final) == 1 and output.rstrip().endswith(final)
              and "STAGE11_VISIBLE_GRIND_FAILURE" not in output, "Native labels")
        check(read("native.exit_code.txt").strip() == "0"
              and raw("native.stderr.txt") == b"", "Native exit/stderr")
        check(read("compiler_exit_code.txt").strip() == "0"
              and read("preflight.txt").strip() == "ORIGINAL_UNICODE_PICK_PREFLIGHT_PASS",
              "compiler/preflight")
        negative = (("mutant", "STAGE11_VISIBLE_GRIND_FAILURE"),
                    ("invalid_0_1", "E_VISIBLE_GRIND"),
                    ("invalid_11_1", "E_VISIBLE_GRIND"),
                    ("invalid_1_0", "E_VISIBLE_COLUMN"),
                    ("invalid_1_6", "E_VISIBLE_COLUMN"))
        for name, marker in negative:
            out = read(f"{name}.stdout.txt")
            check(read(f"{name}.exit_code.txt").strip() == "1"
                  and marker in out and final not in out, f"{name} rejection")
        check(receipt.get("case_labels") == labels
              and (receipt.get("result_assertions"), receipt.get("input_assertions")) == (50, 100)
              and receipt.get("native_exit_code") == 0
              and receipt.get("negative_exit_codes") == [1] * 5, "receipt counts")
    return {"project_id": PROJECT, "stage": 11, "status": "ACCEPTED",
            "audit": "OFFLINE_INDEPENDENT", "run_id": RUN, "workflow_sha": WORKFLOW,
            "source_sha": SOURCE, "runtime_sha": RUNTIME, "archive_sha256": archive_sha256,
            "combined_sha256": COMBINED, "fixture_sha256": FIXTURE,
            "cases": 50, "result_assertions": 50, "input_assertions": 100,
            "negative_controls": [x[0] for x in negative], "next_stage": 12}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    parser.add_argument("--sha256", required=True)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    report = verify(args.archive, args.sha256)
    with zipfile.ZipFile(args.archive) as z:
        damaged = json.loads(z.read("oracle.json"))
    damaged["cases"][0]["expected"] = 4
    try:
        verify(args.archive, args.sha256,
               {"oracle.json": json.dumps(damaged).encode()})
    except ValueError:
        report["audit_negative_control"] = "REJECTED_CORRUPTED_EXPECTED_VALUE"
    else:
        raise SystemExit("AUDIT_NEGATIVE_CONTROL_FAILED")
    output = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.write_text(output)
    print(output, end="")


if __name__ == "__main__":
    main()
