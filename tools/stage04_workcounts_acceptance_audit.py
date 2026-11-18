#!/usr/bin/env python3
"""Offline acceptance audit for the pinned Stage 4 Native artifact.

The archive receipt is treated as a claim. This program checks its bytes,
recomputes the arithmetic oracle, and binds the executed source to Git.
"""

import argparse
import hashlib
import json
import re
import subprocess
import zipfile
from pathlib import Path

PROJECT = "PC-BRANCH-FALSE-ARABIC"
RUN = "44316699851"
WORKFLOW = "70c26d48838ccf054aff98db0630a8250f889443"
SOURCE = "de7c5f1c21ce49293f48f83af0d043dd20926075"
RUNTIME = "eb3135565a8670cced3f6bbca4dbf7b014c45634"
ARCHIVE = "9f025bdec92f8edc64a31eeca5767e7b5521881f3ac4aed70f7954d74efeb4c9"
COMBINED = "0d111712efde79e9dc8a3ad503c41e71bdaf7c2d532f58ee5f9c4116fcc0b7a7"
FIXTURE = "7d716dab6d06eae04e92eb72c3f16f149f509d95d6a17602019830c5535524b6"
ROOT = Path(__file__).resolve().parents[1]


def sha(data):
    return hashlib.sha256(data).hexdigest()


def git(path, commit):
    return subprocess.check_output(["git", "show", f"{commit}:{path}"], cwd=ROOT)


def require(condition, description):
    if not condition:
        raise ValueError(description)


def verify(archive, overrides=None):
    require(sha(archive.read_bytes()) == ARCHIVE, "artifact digest")
    with zipfile.ZipFile(archive) as z:
        require(z.testzip() is None, "artifact CRC")

        def raw(name):
            if overrides and name in overrides:
                return overrides[name]
            return z.read(name)

        def read(name):
            return raw(name).decode("utf-8")

        receipt = json.loads(read("evidence.json"))
        oracle = json.loads(read("oracle.json"))
        for name, expected in (("project_id", PROJECT), ("github_run_id", RUN),
                               ("github_sha", WORKFLOW), ("source_pin", SOURCE),
                               ("source_observed", SOURCE), ("runtime_pin", RUNTIME),
                               ("runtime_observed", RUNTIME), ("combined_sha256", COMBINED),
                               ("fixture_sha256", FIXTURE)):
            require(receipt.get(name) == expected, f"receipt {name}")
        require(receipt.get("workcounts_native_verified") is True, "CI receipt")
        require(receipt.get("stage4_full_acceptance") is False, "CI cannot self-accept")
        require(read("source_observed.txt").strip() == SOURCE, "source observed")
        require(read("runtime_observed.txt").strip() == RUNTIME, "runtime observed")
        require(sha(git(".github/workflows/false-arabic-stage04-native-workcounts.yml", WORKFLOW))
                == sha((ROOT / ".github/workflows/false-arabic-stage04-native-workcounts.yml").read_bytes()),
                "workflow pin")
        paths = ("src/bigint.false", "src/monster_bootstrap.false", "test/stage04_workcounts_13.false")
        locked = [git(path, SOURCE) for path in paths]
        require(sha(locked[-1]) == FIXTURE, "fixture from source commit")
        require(sha(b"\n".join(locked) + b"\n") == COMBINED, "combined from source commit")
        require(raw("stage04_workcounts_exact.false") == b"\n".join(locked) + b"\n",
                "exact executed bytes")
        require(oracle.get("project_id") == PROJECT and oracle.get("native_evidence") is False,
                "oracle origin")
        require(oracle.get("stage") == "4_WORKCOUNTS" and oracle.get("epoch") == 15055671,
                "oracle domain")
        require((oracle.get("case_count"), oracle.get("field_assertions"),
                 oracle.get("input_integrity_assertions"), oracle.get("seeded_property_pairs"))
                == (13, 65, 26, 384), "oracle counts")
        require(oracle.get("fixture_sha256") == FIXTURE and len(oracle["cases"]) == 13,
                "oracle fixture")
        labels = []
        pairs = set()
        for i, c in enumerate(oracle["cases"]):
            a, b = int(c["calculation"]), int(c["target"])
            day = lambda v: -2 * (v - 15055671) if v < 15055671 else 2 * (v - 15055671) + 1
            expected = [day(a), day(b), abs(a - b) + 1, day(a) + day(b),
                        1 if a == b else 2 if b > a else 3]
            label = f"STAGE4_WORKCOUNTS_CASE_{i:02d}_OK"
            require(c["index"] == i and c["expected"] == list(map(str, expected))
                    and c["label"] == label, f"independent arithmetic case {i}")
            labels.append(label)
            pairs.add((a, b))
        require(len(pairs) == 13, "distinct pairs")
        stdout = read("native_stdout.txt")
        require(re.findall(r"STAGE4_WORKCOUNTS_CASE_\d{2}_OK", stdout) == labels,
                "positive case receipts")
        final = "STAGE4_WORKCOUNTS_65_FIELDS_26_INPUTS_VERIFIED"
        require(stdout.count(final) == 1 and stdout.rstrip().endswith(final), "final receipt")
        require("STAGE4_WORKCOUNTS_FAILURE" not in stdout, "positive failure marker")
        require(read("native_exit_code.txt").strip() == "0" and raw("native_stderr.txt") == b"",
                "positive exit/stderr")
        require(read("compiler_exit_code.txt").strip() == "0" and
                read("preflight.txt").strip() == "ORIGINAL_UNICODE_PICK_PREFLIGHT_PASS",
                "compiler/Unicode preflight")
        for label, marker in (("mutant", "STAGE4_WORKCOUNTS_FAILURE"),
                              ("reader_0", "E_WORK_FIELD"), ("reader_6", "E_WORK_FIELD")):
            require(read(f"{label}.exit_code.txt").strip() == "1", f"{label} exit")
            out = read(f"{label}.stdout.txt")
            require(marker in out and final not in out, f"{label} rejection")
        require(receipt.get("case_labels") == labels
                and (receipt.get("field_assertions"), receipt.get("input_integrity_assertions")) == (65, 26)
                and receipt.get("native_exit_code") == 0
                and receipt.get("negative_exit_codes") == [1, 1, 1], "receipt counts")
    return {"project_id": PROJECT, "stage": 4, "status": "ACCEPTED",
            "audit": "OFFLINE_INDEPENDENT", "run_id": RUN, "workflow_sha": WORKFLOW,
            "source_sha": SOURCE, "runtime_sha": RUNTIME, "archive_sha256": ARCHIVE,
            "combined_sha256": COMBINED, "fixture_sha256": FIXTURE,
            "native_pairs": 13, "native_field_assertions": 65,
            "native_input_integrity_assertions": 26, "seeded_python_pairs": 384,
            "negative_controls": ["mutant", "reader_0", "reader_6"],
            "next_stage": 5}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    result = verify(args.archive)
    # One changed positive receipt must make the acceptance gate fail.
    try:
        verify(args.archive, {"native_stdout.txt": b"STAGE4_WORKCOUNTS_CASE_00_OK"})
    except ValueError:
        result["audit_negative_control"] = "REJECTED_MUTATED_STDOUT"
    else:
        raise SystemExit("audit accepted a corrupted positive receipt")
    encoded = json.dumps(result, sort_keys=True, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(encoded, encoding="utf-8")
    print(encoded, end="")


if __name__ == "__main__":
    main()
