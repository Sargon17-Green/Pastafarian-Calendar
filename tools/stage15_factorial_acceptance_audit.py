#!/usr/bin/env python3
"""Independent offline Stage 15 factorial Native artifact audit."""

import argparse
import hashlib
import json
import re
import subprocess
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = "PC-BRANCH-FALSE-ARABIC"
RUNTIME = "eb3135565a8670cced3f6bbca4dbf7b014c45634"
FINAL = "STAGE15_FACTORIAL_SEVEN_PLUS_TWO_REPLAYS_OK"


def require(ok, label):
    if not ok:
        raise ValueError(label)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def git(commit, path):
    return subprocess.check_output(["git", "show", f"{commit}:{path}"], cwd=ROOT)


def expected():
    state = 1
    answer = [1]
    for n in range(1, 7):
        state *= n
        answer.append(state)
    require(answer == [1, 1, 2, 6, 24, 120, 720], "factorial recurrence")
    return [(n, answer[n]) for n in tuple(range(7))+(0, 6)]


def verify(archive, checksum, run_id, workflow_sha, source_sha, overrides=None):
    require(sha(archive.read_bytes()) == checksum, "artifact SHA")
    with zipfile.ZipFile(archive) as z:
        require(z.testzip() is None, "ZIP CRC")
        def raw(name):
            return overrides[name] if overrides and name in overrides else z.read(name)
        def read(name):
            return raw(name).decode("utf-8")
        receipt, oracle = json.loads(read("evidence.json")), json.loads(read("oracle.json"))
        fields = {"project_id": PROJECT, "github_run_id": run_id,
                  "github_sha": workflow_sha, "source_pin": source_sha,
                  "source_observed": source_sha, "runtime_pin": RUNTIME,
                  "runtime_observed": RUNTIME}
        require(all(receipt.get(k) == value for k, value in fields.items()), "receipt pins")
        require(read("source_observed.txt").strip() == source_sha and
                read("runtime_observed.txt").strip() == RUNTIME,
                "observed source and interpreter")
        paths = ("src/bigint.false", "src/monster_bootstrap.false",
                 "test/stage15_factorial_7.false")
        blobs = [git(source_sha, p) for p in paths]
        combined = b"\n".join(blobs)+b"\n"
        require(raw("native.false") == combined and
                receipt.get("combined_sha256") == sha(combined) and
                receipt.get("fixture_sha256") == sha(blobs[-1]),
                "exact source and fixture")
        require(git(workflow_sha, "tools/stage15_factorial_ci.py") ==
                (ROOT/"tools/stage15_factorial_ci.py").read_bytes(),
                "CI script pin")
        cases = expected()
        require([(v.get("input"), v.get("expected")) for v in oracle.get("cases", [])]
                == cases, "independent oracle")
        fixture_cases = re.findall(r"z;b:(\d+)a;!b;32h;!!(\d+)=~", blobs[-1].decode())
        require([(int(n), int(v)) for n, v in fixture_cases] == cases,
                "fixture expectations")
        labels = [f"STAGE15_FACTORIAL_{i:02d}_OK" for i in range(9)]
        output = read("native.stdout.txt")
        require(read("native.exit_code.txt").strip() == "0" and
                raw("native.stderr.txt") == b"" and
                re.findall(r"STAGE15_FACTORIAL_\d{2}_OK", output) == labels and
                output.count(FINAL) == 1 and output.rstrip().endswith(FINAL),
                "Native nine assertions")
        require(receipt.get("factorial_native_verified") is True and
                receipt.get("stage15_full_acceptance") is False and
                receipt.get("result_assertions") == 7 and
                receipt.get("replay_assertions") == 2 and
                receipt.get("case_labels") == labels, "receipt boundary")
        require(read("mutant.exit_code.txt").strip() == "1" and
                "STAGE15_FACTORIAL_00_FAIL" in read("mutant.stdout.txt") and
                FINAL not in read("mutant.stdout.txt"), "mutant rejection")
        for name in ("below", "above", "missing_argument"):
            require(read(name+".exit_code.txt").strip() == "1" and
                    FINAL not in read(name+".stdout.txt"), name)
        for name in ("below", "above"):
            require("E_FACTORIAL_DOMAIN" in read(name+".stdout.txt"), name+" domain")
        require(read("compiler_exit_code.txt").strip() == "0" and
                read("preflight.txt").strip() == "ORIGINAL_UNICODE_PICK_PREFLIGHT_PASS",
                "original runtime preflight")
    return {"project_id": PROJECT, "stage": 15, "status": "ACCEPTED",
            "run_id": run_id, "workflow_sha": workflow_sha,
            "source_sha": source_sha, "runtime_sha": RUNTIME,
            "artifact_sha256": checksum, "result_assertions": 7,
            "replay_assertions": 2, "negative_controls": 4,
            "audit": "OFFLINE_INDEPENDENT", "next_stage": 16}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    parser.add_argument("--sha256", required=True)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--workflow-sha", required=True)
    parser.add_argument("--source-sha", required=True)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    report = verify(args.archive, args.sha256, args.run_id,
                    args.workflow_sha, args.source_sha)
    with zipfile.ZipFile(args.archive) as z:
        corrupt = json.loads(z.read("oracle.json"))
    corrupt["cases"][0]["expected"] = 0
    try:
        verify(args.archive, args.sha256, args.run_id,
               args.workflow_sha, args.source_sha,
               {"oracle.json": json.dumps(corrupt).encode()})
    except ValueError:
        report["audit_negative_control"] = "REJECTED_CORRUPTED_FACTORIAL"
    else:
        raise SystemExit("AUDIT_NEGATIVE_CONTROL_FAILED")
    value = json.dumps(report, indent=2, sort_keys=True)+"\n"
    if args.output:
        args.output.write_text(value)
    print(value, end="")


if __name__ == "__main__":
    main()
