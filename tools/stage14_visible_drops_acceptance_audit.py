#!/usr/bin/env python3
"""Independent offline audit of the exact-source Stage 14 Native artifact."""

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
RUNTIME = "eb3135565a8670cced3f6bbca4dbf7b014c45634"
MOD = (1 << 127) - 1
FINAL = "STAGE14_VISIBLE_46_COMPLETE"


def require(ok, label):
    if not ok:
        raise ValueError(label)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def git(commit, path):
    return subprocess.check_output(["git", "show", f"{commit}:{path}"], cwd=ROOT)


def numbers():
    # Rebuild state from the recurrence and constants, with no imports from the
    # fixture generator, design oracle, or production FALSE implementation.
    rows = [(17, 29, 43, 71, 101)]
    for index in range(2, 47):
        a, b, c, d, e = rows[-1]
        rows.append(tuple((v - 1) % MOD + 1 for v in
                          (a*a + 3*b + index, b*b + 5*c + a,
                           c*c + 7*d + b, d*d + 11*e + c,
                           e*e + 13*a + d)))
    require(rows[-1][0] == 73799454308499791987382386781055001470,
            "last stone witness")
    counts = (1, 1, 1, 2, 1)
    hidden = []
    for i in range(1, 8):
        coefficients = (2*i + 1, 3*i + 1, 4*i + 2, 4*i + 4)
        value = (counts[0] + sum(coefficients[j]*counts[j+1] for j in range(4))
                 + sum(rows[i-1]) - 1) % MOD + 1
        for j in range(1, 8):
            value = (value*value + 3*value + rows[i-1][(j-1) % 5] + j - 1) % MOD + 1
        hidden.append(value)
    primes = [p for p in range(3, 48)
              if all(p % d for d in range(2, math.isqrt(p)+1))]
    require(len(primes) == 14 and primes[-1] == 47, "grind primes")
    visible = []
    for i in range(1, 47):
        def predecessor(back):
            offset = i - back
            return visible[offset-1] if offset > 0 else hidden[-offset]
        e, f, g = (predecessor(back) for back in (1, 3, 7))
        row = rows[i-1]
        value = (sum(row[j]*counts[j] for j in range(5)) + e + 3*f + 5*g + i - 1) % MOD + 1
        for round_number in range(1, 12):
            p1, p2, p3, p4 = primes[round_number-1:round_number+3]
            kind = (round_number-1) % 5
            value = (value*value + p1*value + p2*e + p3*f + p4*g
                     + row[kind] - 1) % MOD + 1
        visible.append(value)
    return visible


def verify(archive, checksum, run_id, workflow_sha, source_sha, overrides=None):
    require(digest(archive.read_bytes()) == checksum, "archive SHA")
    with zipfile.ZipFile(archive) as z:
        require(z.testzip() is None, "archive CRC")
        def raw(name):
            return overrides[name] if overrides and name in overrides else z.read(name)
        def read(name):
            return raw(name).decode("utf-8")
        receipt, oracle = json.loads(read("evidence.json")), json.loads(read("oracle.json"))
        fields = {"project_id": PROJECT, "github_run_id": run_id,
                  "github_sha": workflow_sha, "source_pin": source_sha,
                  "source_observed": source_sha, "runtime_pin": RUNTIME,
                  "runtime_observed": RUNTIME}
        require(all(receipt.get(k) == v for k, v in fields.items()), "identity pins")
        require(read("source_observed.txt").strip() == source_sha and
                read("runtime_observed.txt").strip() == RUNTIME,
                "observed commits")
        paths = ("src/bigint.false", "src/monster_bootstrap.false",
                 "test/stage14_visible_drops_46.false")
        locked = [git(source_sha, p) for p in paths]
        combined = b"\n".join(locked)+b"\n"
        require(raw("native.false") == combined and
                receipt.get("combined_sha256") == digest(combined) and
                receipt.get("fixture_sha256") == digest(locked[-1]),
                "executed source bytes")
        require(git(workflow_sha, "tools/stage14_visible_drops_ci.py") ==
                (ROOT/"tools/stage14_visible_drops_ci.py").read_bytes(),
                "Native runner bytes")
        expected = numbers()
        require([case.get("expected_decimal") for case in oracle.get("cases", [])] ==
                [str(n) for n in expected], "independent oracle")
        fixture = locked[-1].decode("utf-8")
        chunks = re.findall(r"z;s:1a;!(\d+)a;!((?:\d+a;!)+)\nv;(\d+)\+g;!d:", fixture)
        require(len(chunks) == 46, "fixture serialized values")
        for position, (length, cells, index) in enumerate(chunks):
            digits = [int(n) for n in re.findall(r"(\d+)a;!", cells)]
            actual = sum(d * 512**i for i, d in enumerate(digits))
            require((int(length), int(index), actual) ==
                    (len(digits), position+1, expected[position]),
                    f"fixture value {position+1}")
        labels = [f"STAGE14_VISIBLE_{i:02d}_OK" for i in range(1, 47)]
        output = read("native.stdout.txt")
        require(read("native.exit_code.txt").strip() == "0" and
                raw("native.stderr.txt") == b"" and
                re.findall(r"STAGE14_VISIBLE_\d{2}_OK", output) == labels and
                output.count(FINAL) == 1 and output.rstrip().endswith(FINAL),
                "Native 46 labels")
        require(receipt.get("visible_native_verified") is True and
                receipt.get("stage14_full_acceptance") is False and
                receipt.get("result_assertions") == 46 and
                receipt.get("case_labels") == labels, "receipt boundary")
        require(read("mutant.exit_code.txt").strip() == "1" and
                "STAGE14_VALUE_01_FAILURE" in read("mutant.stdout.txt") and
                FINAL not in read("mutant.stdout.txt"), "mutant rejection")
        for name, marker in (("short_counts", "E_VISIBLE_COUNTS"),
                             ("short_stones", "E_VISIBLE_STONES"),
                             ("short_hidden", "E_VISIBLE_HIDDEN")):
            require(read(name+".exit_code.txt").strip() == "1" and
                    marker in read(name+".stdout.txt") and
                    FINAL not in read(name+".stdout.txt"), name)
        require(read("compiler_exit_code.txt").strip() == "0" and
                read("preflight.txt").strip() == "ORIGINAL_UNICODE_PICK_PREFLIGHT_PASS",
                "original interpreter preflight")
    return {"project_id": PROJECT, "stage": 14, "status": "ACCEPTED",
            "run_id": run_id, "workflow_sha": workflow_sha,
            "source_sha": source_sha, "runtime_sha": RUNTIME,
            "artifact_sha256": checksum, "result_assertions": 46,
            "negative_controls": 4, "audit": "OFFLINE_INDEPENDENT",
            "next_stage": 15}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    parser.add_argument("--sha256", required=True)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--workflow-sha", required=True)
    parser.add_argument("--source-sha", required=True)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    result = verify(args.archive, args.sha256, args.run_id,
                    args.workflow_sha, args.source_sha)
    with zipfile.ZipFile(args.archive) as z:
        corrupt = json.loads(z.read("oracle.json"))
    corrupt["cases"][0]["expected_decimal"] = "1"
    try:
        verify(args.archive, args.sha256, args.run_id, args.workflow_sha,
               args.source_sha, {"oracle.json": json.dumps(corrupt).encode()})
    except ValueError:
        result["audit_negative_control"] = "REJECTED_CORRUPT_EXPECTED_VALUE"
    else:
        raise SystemExit("AUDIT_NEGATIVE_CONTROL_FAILED")
    payload = json.dumps(result, indent=2, sort_keys=True)+"\n"
    if args.output:
        args.output.write_text(payload)
    print(payload, end="")


if __name__ == "__main__":
    main()
