#!/usr/bin/env python3
"""Audit pinned Stage 8 CI artifact bytes and independently derive all stone values."""

import argparse
import hashlib
import json
import re
import subprocess
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = "PC-BRANCH-FALSE-ARABIC"
RUN = "44360322387"
WORKFLOW = "004f3b1be8bd4e99254b651e48f27742ea000a3f"
SOURCE = "07da4d7b99d804c25754a93eab1db7e5c156ab0d"
RUNTIME = "eb3135565a8670cced3f6bbca4dbf7b014c45634"
COMBINED = "d627910d98a9e3bb2c9df87a45e1f912035e76d9aa231a8c9e311456c85bc90f"
FIXTURE = "c5fe3f77d4c92b900e07a3f2a8dee01d0a2f8a9d0663c2d741e27fcd51e03c8b"
M = 2**127 - 1


def check(condition, reason):
    if not condition:
        raise ValueError(reason)


def sha(blob):
    return hashlib.sha256(blob).hexdigest()


def git(path, revision):
    return subprocess.check_output(["git", "show", f"{revision}:{path}"], cwd=ROOT)


def independent_rows():
    result = [(17, 29, 43, 71, 101)]
    for row_number in range(2, 47):
        old = result[-1]
        fresh = []
        for column, factor, offset in ((0, 3, 1), (1, 5, 2), (2, 7, 3),
                                       (3, 11, 4), (4, 13, 0)):
            raw = old[column] ** 2 + factor * old[offset]
            raw += row_number if column == 0 else old[(column - 1) % 5]
            fresh.append(1 + ((raw - 1) % M))
        result.append(tuple(fresh))
    return [[str(value) for value in row] for row in result]


def verify(path, archive_sha256, overrides=None):
    check(re.fullmatch(r"[0-9a-f]{64}", archive_sha256) is not None, "archive SHA syntax")
    check(sha(path.read_bytes()) == archive_sha256, "archive SHA256")
    with zipfile.ZipFile(path) as z:
        check(z.testzip() is None, "archive CRC")

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
        check(receipt.get("stones_native_verified") is True
              and receipt.get("stage8_full_acceptance") is False, "receipt boundary")
        check(read("source_observed.txt").strip() == SOURCE
              and read("runtime_observed.txt").strip() == RUNTIME, "source/runtime observed")
        workflow = ".github/workflows/false-arabic-stage08-native-stones.yml"
        check(git(workflow, WORKFLOW) == (ROOT / workflow).read_bytes(), "workflow bytes")
        paths = ("src/bigint.false", "src/monster_bootstrap.false", "test/stage08_stones_46.false")
        pinned = [git(p, SOURCE) for p in paths]
        combined = b"\n".join(pinned) + b"\n"
        check(sha(pinned[-1]) == FIXTURE and sha(combined) == COMBINED,
              "pinned source hashes")
        check(raw("stage08_stones_exact.false") == combined, "executed source bytes")
        check(pinned[-1].count(b"21h;!!v:") == 240
              and pinned[-1].count(b"21h;!!t:") == 10, "fixture read coverage")
        check(oracle.get("project_id") == PROJECT and oracle.get("stage") == 8
              and oracle.get("native_evidence") is False
              and (oracle.get("row_count"), oracle.get("kind_count"),
                   oracle.get("result_assertions"), oracle.get("shape_assertions"),
                   oracle.get("replay_assertions"), oracle.get("identity_assertions"))
              == (46, 5, 240, 47, 10, 10)
              and oracle.get("fixture_sha256") == FIXTURE
              and oracle.get("modulus") == str(M), "oracle metadata")
        check(oracle.get("rows") == independent_rows(), "independent 46x5 values")
        labels = [f"STAGE8_STONES_ROW_{i:02d}_OK" for i in range(1, 47)]
        output = read("native.stdout.txt")
        final = "STAGE8_STONES_46_ROWS_230_VALUES_VERIFIED"
        check(re.findall(r"STAGE8_STONES_ROW_\d{2}_OK", output) == labels
              and output.count(final) == 1 and output.rstrip().endswith(final)
              and "STAGE8_STONES_FAILURE" not in output, "Native labels/final")
        check(read("native.exit_code.txt").strip() == "0"
              and raw("native.stderr.txt") == b"", "Native exit/stderr")
        check(read("compiler_exit_code.txt").strip() == "0"
              and read("preflight.txt").strip() == "ORIGINAL_UNICODE_PICK_PREFLIGHT_PASS",
              "compiler/Unicode preflight")
        mutant = read("mutant.stdout.txt")
        check(read("mutant.exit_code.txt").strip() == "1"
              and "STAGE8_STONES_FAILURE" in mutant and final not in mutant,
              "mutant rejection")
        check(receipt.get("case_labels") == labels
              and (receipt.get("result_assertions"), receipt.get("shape_assertions"),
                   receipt.get("identity_assertions")) == (240, 47, 10)
              and (receipt.get("native_exit_code"), receipt.get("mutant_exit_code")) == (0, 1),
              "receipt counts")
    return {"project_id": PROJECT, "stage": 8, "status": "ACCEPTED",
            "audit": "OFFLINE_INDEPENDENT", "run_id": RUN, "workflow_sha": WORKFLOW,
            "source_sha": SOURCE, "runtime_sha": RUNTIME, "archive_sha256": archive_sha256,
            "combined_sha256": COMBINED, "fixture_sha256": FIXTURE,
            "rows": 46, "values": 230, "shape_assertions": 47,
            "replay_assertions": 10, "identity_assertions": 10,
            "negative_controls": ["mutant"], "next_stage": 9}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    parser.add_argument("--sha256", required=True)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    result = verify(args.archive, args.sha256)
    with zipfile.ZipFile(args.archive) as z:
        damaged = json.loads(z.read("oracle.json"))
    damaged["rows"][0][0] = "18"
    try:
        verify(args.archive, args.sha256,
               {"oracle.json": json.dumps(damaged).encode("utf-8")})
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
