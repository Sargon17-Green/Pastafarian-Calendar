#!/usr/bin/env python3
"""Offline acceptance gates for the pinned Stage 3 dayCount Native artifact.

Usage: python3 tools/stage03_daycount_acceptance_audit.py artifact.zip
The source commit must be present in this repository. This does not query CI.
"""

from __future__ import annotations

import hashlib
import json
import random
import re
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EPOCH = 15055671
RUN = "44303526690"
WORKFLOW = "344838775b28a3841492e3280b076470040c4199"
SOURCE = "874656d7e855e530704356098943dd472cece187"
RUNTIME = "eb3135565a8670cced3f6bbca4dbf7b014c45634"
ZIP_SHA = "5174013b77af64e6403dc310cf21630167ad1448dde4293c94ae7abe66b23cd3"
COMBINED_SHA = "726954b9d84bfc19bd6bdacf1bd78489285029d72b83ea2c9454bce6a2f8228d"
FIXTURE_SHA = "36c6e80c00bff6f13e6945b4e25ff52ea3a05bd79cc69a46ba54735e57d42734"
PARTS = ("src/bigint.false", "src/monster_bootstrap.false", "test/stage03_daycount_13.false")
ANCHORS = (EPOCH - 2, EPOCH - 1, EPOCH, EPOCH + 1, EPOCH + 2,
           0, -1, 1, EPOCH - (1 << 31), EPOCH + (1 << 31),
           EPOCH - (1 << 127), EPOCH + (1 << 127), -EPOCH)


def require(ok: bool, reason: str) -> None:
    if not ok:
        raise ValueError(reason)


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def rank(day: int) -> int:
    distance = day - EPOCH
    return 2 * (-distance) if distance < 0 else 2 * distance + 1


def inverse(value: int) -> int:
    require(value > 0, "rank must be positive")
    return EPOCH + (value - 1) // 2 if value & 1 else EPOCH - value // 2


def source_blob(path: str) -> bytes:
    return subprocess.check_output(["git", "show", SOURCE + ":" + path], cwd=ROOT)


def audit(path: Path) -> dict[str, object]:
    require(digest(path.read_bytes()) == ZIP_SHA, "artifact ZIP SHA-256 mismatch")
    with zipfile.ZipFile(path) as z:
        require(z.testzip() is None, "artifact CRC failure")
        require(len(z.namelist()) == len(set(z.namelist())), "duplicate ZIP entry")
        e = json.loads(z.read("evidence.json"))
        o = json.loads(z.read("oracle.json"))
        for key, value in (("project_id", "PC-BRANCH-FALSE-ARABIC"),
                           ("github_run_id", RUN), ("github_sha", WORKFLOW),
                           ("source_pin", SOURCE), ("source_observed", SOURCE),
                           ("runtime_pin", RUNTIME), ("runtime_observed", RUNTIME),
                           ("combined_sha256_expected", COMBINED_SHA),
                           ("combined_sha256_observed", COMBINED_SHA),
                           ("fixture_sha256", FIXTURE_SHA)):
            require(e.get(key) == value, "receipt mismatch: " + key)
        require(e.get("daycount_native_verified") is True and e.get("native_exit_code") == 0,
                "Native result absent")
        require(e.get("stage3_full_acceptance") is False, "run receipt must not self-approve")
        require(z.read("native_exit_code.txt").strip() == b"0" and
                z.read("compiler_exit_code.txt").strip() == b"0" and
                z.read("native_stderr.txt") == b"", "exit/stderr gate failed")
        require(z.read("preflight.txt").strip() == b"ORIGINAL_UNICODE_PICK_PREFLIGHT_PASS",
                "original interpreter preflight failed")
        locked = b"\n".join(source_blob(part) for part in PARTS) + b"\n"
        require(z.read("stage03_daycount_exact.false") == locked and
                digest(locked) == COMBINED_SHA, "combined source differs from pinned git")
        fixture = source_blob(PARTS[-1])
        require(digest(fixture) == FIXTURE_SHA and
                fixture.count(b"5h;!!0=f;!") == 13, "fixture or assertion count mismatch")
        require(o.get("project_id") == e["project_id"] and o.get("native_evidence") is False and
                o.get("fixture_sha256") == FIXTURE_SHA and o.get("epoch") == EPOCH and
                o.get("anchor_count") == 13 and o.get("seeded_property_cases") == 384,
                "independent oracle manifest mismatch")
        cases = o.get("anchor_cases", [])
        require(len(cases) == 13, "missing oracle anchors")
        for index, (day, case) in enumerate(zip(ANCHORS, cases)):
            value = rank(day)
            require(inverse(value) == day, "inverse mismatch")
            require((case.get("index"), case.get("day"), case.get("expected"), case.get("label")) ==
                    (index, str(day), str(value), f"STAGE3_DAYCOUNT_CASE_{index:02d}_OK"),
                    f"anchor mismatch at {index}")
        rng = random.Random(20261118)
        for i in range(384):
            day = EPOCH + rng.randrange(-(1 << 192), 1 << 192)
            if i % 8 == 0:
                day = EPOCH + (i // 8 - 24) * (1 << 127)
            value = rank(day)
            require(value >= 1 and inverse(value) == day and
                    (value & 1) == int(day >= EPOCH), f"seeded property mismatch at {i}")
        stdout = z.read("native_stdout.txt").decode("utf-8")
        labels = re.findall(r"STAGE3_DAYCOUNT_CASE_\d{2}_OK", stdout)
        require(labels == [c["label"] for c in cases] == e.get("native_cases_observed"),
                "Native labels differ from independent oracle")
        require(stdout.count("STAGE3_DAYCOUNT_13_CHECKS_VERIFIED") == 1 and
                "STAGE3_DAYCOUNT_FAILURE" not in stdout, "completion/failure markers inconsistent")
    return {
        "project_id": "PC-BRANCH-FALSE-ARABIC",
        "stage": 3,
        "contract": "DAYCOUNT_AROUND_15055671",
        "source_commit": SOURCE,
        "workflow_commit": WORKFLOW,
        "runtime_commit": RUNTIME,
        "run_id": RUN,
        "artifact_id": 14426179505,
        "artifact_sha256": ZIP_SHA,
        "combined_sha256": COMBINED_SHA,
        "fixture_sha256": FIXTURE_SHA,
        "native_cases": 13,
        "independent_seeded_property_cases": 384,
        "zip_crc": "PASS",
        "offline_evidence_gates": "PASS",
        "ci_completed_success": "CHECK_SEPARATELY_IN_GITHUB",
        "main_merged": False,
    }


if __name__ == "__main__":
    try:
        require(len(sys.argv) == 2, "usage: stage03_daycount_acceptance_audit.py artifact.zip")
        print(json.dumps(audit(Path(sys.argv[1])), ensure_ascii=False, indent=2, sort_keys=True))
    except (ValueError, OSError, KeyError, subprocess.CalledProcessError, zipfile.BadZipFile) as exc:
        print("STAGE3_ACCEPTANCE_AUDIT_FAILED:", exc, file=sys.stderr)
        raise SystemExit(1) from exc
