#!/usr/bin/env python3
"""Offline independent audit of the exact-source Stage 5 Native archive."""

import argparse
import hashlib
import json
import re
import subprocess
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = "PC-BRANCH-FALSE-ARABIC"
RUN = "44319896000"
WORKFLOW = "a968489f0b1ff8ab586af2a56caf96832174620c"
SOURCE = "2dd1003a2ecaf457e29baad038b5f89e8d9ea2fb"
RUNTIME = "eb3135565a8670cced3f6bbca4dbf7b014c45634"
ARCHIVE = "7b9151b99ebb6ff8f4265c58e36563f80227129c6dc65ef8429ef4619a048a3d"
COMBINED = "12a92dcb790cd79f72bf1aa9f36c2f03cb99c0a013f27a277bdef5d4dc7a31d8"
FIXTURE = "269af91c68a4e16829f2e97ea513f37b5b820a81146b2f5fff798917d88a4ea2"
POSITIONS = ((1, 1), (1, 5), (2, 2), (12, 5), (13, 3), (14, 1),
             (25, 4), (27, 2), (32, 3), (40, 5), (45, 4), (46, 5), (46, 1))
NEGATIVES = (("mutant", "STAGE5_STONE_FAILURE"), ("row_0", "E_STONE_ROW"),
             ("row_47", "E_STONE_ROW"), ("kind_0", "E_STONE_KIND"),
             ("kind_6", "E_STONE_KIND"), ("short_kind_4", "E_STONE_KIND"))


def require(ok, label):
    if not ok:
        raise ValueError(label)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def git(path, rev):
    return subprocess.check_output(["git", "show", f"{rev}:{path}"], cwd=ROOT)


def expected_value(pattern, kind):
    if pattern == 0 and kind == 1:
        return 0
    if (pattern, kind) in {(0, 5), (5, 3), (6, 5), (11, 5)}:
        magnitude = 2**127 + 101 * pattern + kind
        return -magnitude if pattern % 2 else magnitude
    magnitude = 1_000_003 * (pattern + 1) + 37 * kind
    return -magnitude if (pattern + kind) % 2 else magnitude


def verify(path, overrides=None):
    require(sha(path.read_bytes()) == ARCHIVE, "archive digest")
    with zipfile.ZipFile(path) as z:
        require(z.testzip() is None, "archive CRC")

        def raw(name):
            return overrides[name] if overrides and name in overrides else z.read(name)

        def read(name):
            return raw(name).decode("utf-8")

        evidence = json.loads(read("evidence.json"))
        oracle = json.loads(read("oracle.json"))
        for key, val in (("project_id", PROJECT), ("github_run_id", RUN),
                         ("github_sha", WORKFLOW), ("source_pin", SOURCE),
                         ("source_observed", SOURCE), ("runtime_pin", RUNTIME),
                         ("runtime_observed", RUNTIME), ("combined_sha256", COMBINED),
                         ("fixture_sha256", FIXTURE)):
            require(evidence.get(key) == val, f"receipt {key}")
        require(evidence.get("stone_type_native_verified") is True
                and evidence.get("stage5_full_acceptance") is False, "receipt decision boundary")
        require(read("source_observed.txt").strip() == SOURCE
                and read("runtime_observed.txt").strip() == RUNTIME, "observed immutable commits")
        wf = ".github/workflows/false-arabic-stage05-native-stone-type.yml"
        require(git(wf, WORKFLOW) == (ROOT / wf).read_bytes(), "workflow pinned bytes")
        files = ("src/bigint.false", "src/monster_bootstrap.false", "test/stage05_stone_type_13.false")
        source = [git(p, SOURCE) for p in files]
        require(sha(source[-1]) == FIXTURE, "pinned fixture")
        require(sha(b"\n".join(source) + b"\n") == COMBINED, "pinned combined source")
        require(raw("stage05_stone_type_exact.false") == b"\n".join(source) + b"\n",
                "executed source bytes")
        require(oracle.get("project_id") == PROJECT and oracle.get("stage") == 5
                and oracle.get("native_evidence") is False and
                (oracle.get("row_count"), oracle.get("distinct_row_patterns"), oracle.get("case_count"),
                 oracle.get("value_assertions"), oracle.get("handle_assertions"),
                 oracle.get("structural_assertions")) == (46, 13, 13, 13, 13, 26)
                and oracle.get("fixture_sha256") == FIXTURE, "oracle shape")
        require(len(oracle["cases"]) == 13 and len(oracle["negative_cases"]) == 5, "oracle cases")
        labels = []
        for i, ((row, kind), case) in enumerate(zip(POSITIONS, oracle["cases"])):
            pattern = (row - 1) % 13
            label = f"STAGE5_STONE_CASE_{i:02d}_OK"
            require((case["index"], case["row"], case["kind"], case["pattern"],
                     case["value"], case["label"]) ==
                    (i, row, kind, pattern, str(expected_value(pattern, kind)), label),
                    f"independent expected value {i}")
            labels.append(label)
        require(oracle["negative_cases"] ==
                [["row_0", 0, 1, "E_STONE_ROW"], ["row_47", 47, 1, "E_STONE_ROW"],
                 ["kind_0", 1, 0, "E_STONE_KIND"], ["kind_6", 1, 6, "E_STONE_KIND"],
                 ["short_kind_4", 13, 4, "E_STONE_KIND"]], "invalid index cases")
        stdout = read("native_stdout.txt")
        final = "STAGE5_STONE_13_VALUES_13_HANDLES_VERIFIED"
        require(re.findall(r"STAGE5_STONE_CASE_\d{2}_OK", stdout) == labels,
                "native ordered receipts")
        require(stdout.count(final) == 1 and stdout.rstrip().endswith(final)
                and "STAGE5_STONE_FAILURE" not in stdout, "native final receipt")
        require(read("native_exit_code.txt").strip() == "0" and raw("native_stderr.txt") == b"",
                "native exit/stderr")
        require(read("compiler_exit_code.txt").strip() == "0" and
                read("preflight.txt").strip() == "ORIGINAL_UNICODE_PICK_PREFLIGHT_PASS",
                "compiler/Unicode preflight")
        for name, marker in NEGATIVES:
            require(read(f"{name}.exit_code.txt").strip() == "1", f"{name} exit")
            out = read(f"{name}.stdout.txt")
            require(marker in out and final not in out and
                    "STAGE5_NEGATIVE_WRONGLY_ACCEPTED" not in out, f"{name} rejection")
        require(evidence.get("case_labels") == labels
                and (evidence.get("value_assertions"), evidence.get("handle_assertions"),
                     evidence.get("structural_assertions")) == (13, 13, 26)
                and evidence.get("native_exit_code") == 0
                and evidence.get("negative_exit_codes") == [1] * 6, "receipt counters")
    return {"project_id": PROJECT, "stage": 5, "status": "ACCEPTED",
            "audit": "OFFLINE_INDEPENDENT", "run_id": RUN, "workflow_sha": WORKFLOW,
            "source_sha": SOURCE, "runtime_sha": RUNTIME, "archive_sha256": ARCHIVE,
            "combined_sha256": COMBINED, "fixture_sha256": FIXTURE,
            "rows": 46, "distinct_row_patterns": 13, "native_cases": 13,
            "value_assertions": 13, "handle_assertions": 13,
            "structural_assertions": 26, "negative_controls": [n for n, _ in NEGATIVES],
            "next_stage": 6}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("archive", type=Path)
    p.add_argument("--output", type=Path)
    args = p.parse_args()
    result = verify(args.archive)
    with zipfile.ZipFile(args.archive) as z:
        corrupted = json.loads(z.read("oracle.json"))
    corrupted["cases"][0]["value"] = "1"
    try:
        verify(args.archive, {"oracle.json": json.dumps(corrupted).encode()})
    except ValueError:
        result["audit_negative_control"] = "REJECTED_CORRUPTED_ORACLE_VALUE"
    else:
        raise SystemExit("audit accepted a corrupted oracle")
    encoded = json.dumps(result, sort_keys=True, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(encoded, encoding="utf-8")
    print(encoded, end="")


if __name__ == "__main__":
    main()
