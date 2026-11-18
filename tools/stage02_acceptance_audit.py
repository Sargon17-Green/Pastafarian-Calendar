#!/usr/bin/env python3
"""Audit two immutable Stage 2 CI artifacts against independent math and git bytes.

Usage: python3 tools/stage02_acceptance_audit.py DISCOVERY.zip DIFF13.zip
The repository must contain the two historical source commits. No network is used.
"""

from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = "PC-BRANCH-FALSE-ARABIC"
RUNTIME = "eb3135565a8670cced3f6bbca4dbf7b014c45634"
DISCOVERY = {
    "run": "44104586872",
    "workflow": "bc29e97ac0a74c8d511ee5f6931798cb5ef8aa01",
    "source": "c71a380353400001ccf9fd3296a7eab63530badf",
    "combined": "44c26ba01dc7edd1e3637c79047e3cf6bb76c13b45079ff603af744f0d0b94e4",
    "artifact": "4cc6d320d81da46f24963bdaa9733e434337f7454478609fb2df703858720e4b",
}
DIFF = {
    "run": "44159278435",
    "workflow": "eea547c641c94b0fca222604dc1ae404b325c6bb",
    "source": "acba6e0c4ca4cd94424661273bf3158175e3b9b5",
    "combined": "a9aac441521ebfcfd20b111e566dda0e9ce848162abca16e1f7e96ab8aa82983",
    "fixture": "e4d535c03f9fb3a504ff3ef8fef58b2cad17cee34a3571e79ae609d67a94510f",
    "artifact": "be325ef511080310ebfc74091b8bab18da9a1acdbca03402b84963f5b668b225",
}
SHARED = ("src/bigint.false", "test/normative_reference.false", "src/monster_bootstrap.false")
M = (1 << 127) - 1
ANCHORS = (0, 1, M - 1, M, M + 1, 2 * M, 2 * M + 1, 3 * M,
           3 * M - 1, -1, -M, -2 * M, -M - 1)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def git_blob(commit: str, path: str) -> bytes:
    return subprocess.check_output(["git", "show", f"{commit}:{path}"], cwd=ROOT)


def combined(commit: str, tail: str) -> bytes:
    return b"\n".join(git_blob(commit, path) for path in (*SHARED, tail)) + b"\n"


def open_artifact(path: Path, pin: dict[str, str]) -> zipfile.ZipFile:
    require(sha(path.read_bytes()) == pin["artifact"], f"artifact SHA-256 mismatch: {path}")
    z = zipfile.ZipFile(path)
    require(z.testzip() is None, f"artifact CRC failure: {path}")
    require(len(z.namelist()) == len(set(z.namelist())), f"duplicate ZIP names: {path}")
    return z


def member(z: zipfile.ZipFile, name: str) -> bytes:
    return z.read(name)


def receipt(z: zipfile.ZipFile, pin: dict[str, str]) -> dict[str, object]:
    e = json.loads(member(z, "evidence.json"))
    for key, expected in (("project_id", PROJECT), ("github_run_id", pin["run"]),
                          ("github_sha", pin["workflow"]),
                          ("source_pin", pin["source"]), ("source_observed", pin["source"]),
                          ("runtime_pin", RUNTIME), ("runtime_observed", RUNTIME)):
        require(e.get(key) == expected, f"{pin['run']}: {key} mismatch")
    require(e.get("native_exit_code") == 0, f"{pin['run']}: Native exit nonzero")
    require(e.get("stage2_full_acceptance") is False, "receipt must not assert full acceptance")
    require(e.get("stage3_authorized") is False, "receipt must not authorize Stage 3")
    require(member(z, "native_exit_code.txt").strip() == b"0", "exit-code file mismatch")
    require(member(z, "native_stderr.txt") == b"", "Native stderr not empty")
    require(member(z, "compiler_exit_code.txt").strip() == b"0", "compiler failed")
    return e


def audit_discovery(z: zipfile.ZipFile) -> dict[str, object]:
    e = receipt(z, DISCOVERY)
    body = member(z, "stage02_discovery01_combined.false")
    require(body == combined(DISCOVERY["source"], "test/stage02_discovery01_tests.false"),
            "discovery source bytes differ from historical git")
    require(sha(body) == e.get("combined_observed_sha256") == DISCOVERY["combined"],
            "discovery source SHA-256 mismatch")
    test = git_blob(DISCOVERY["source"], "test/stage02_discovery01_tests.false")
    require(test.count(b"30o;!n:n;") == 6 and test.count(b"36o;!n:n;") == 6,
            "discovery fixture does not contain exactly 12 operation assertions")
    out = member(z, "native_stdout.txt").decode("utf-8")
    require(out.count("DISCOVERY01_SHAPE_M0_2M0_3M0_MPLUS1_1") == 1,
            "discovery shape marker missing or duplicated")
    require(out.count("DISCOVERY01_RECREATED_NATIVE_SHAPE_VERIFIED") == 1,
            "discovery end marker missing or duplicated")
    require("فشل استقصاء المرحلة الثانية" not in out, "discovery failure marker present")
    require(e.get("discovery01_native_verified") is True and e.get("unicode_preflight_pass") is True,
            "discovery receipt did not verify Native/preflight")
    return {"run_id": DISCOVERY["run"], "artifact_sha256": DISCOVERY["artifact"],
            "combined_sha256": sha(body), "native_assertions": 12, "exit_code": 0}


def audit_diff(z: zipfile.ZipFile) -> dict[str, object]:
    e = receipt(z, DIFF)
    body = member(z, "stage02_diff13_exact.false")
    require(body == combined(DIFF["source"], "test/stage02_differential_13.false"),
            "differential source bytes differ from historical git")
    require(sha(body) == e.get("combined_sha256_observed") == DIFF["combined"],
            "differential combined source SHA-256 mismatch")
    fixture = git_blob(DIFF["source"], "test/stage02_differential_13.false")
    require(sha(fixture) == e.get("fixture_sha256") == DIFF["fixture"],
            "committed fixture SHA-256 mismatch")
    require(fixture.count(b"30o;!n:n;") == fixture.count(b"36o;!n:n;") == 13,
            "fixture does not contain 26 operation assertions")
    o = json.loads(member(z, "oracle.json"))
    cases = o.get("cases", [])
    require(o.get("case_count") == 13 and o.get("assertion_count") == 26 and len(cases) == 13,
            "oracle manifest shape mismatch")
    require(o.get("native_evidence") is False, "Python oracle claims Native execution")
    require(o.get("fixture_sha256") == DIFF["fixture"], "oracle fixture SHA mismatch")
    distinct = 0
    for index, (x, case) in enumerate(zip(ANCHORS, cases)):
        quotient, remainder = divmod(x, M)
        require(quotient * M + remainder == x and 0 <= remainder < M, "division invariant")
        saved = M if x != 0 and remainder == 0 else remainder
        distinct += saved != remainder
        for key, expected in (("index", index), ("input", str(x)),
                              ("regular", str(remainder)), ("save", str(saved)),
                              ("label", f"DIFF13_CASE_{index:02d}_OK")):
            require(case.get(key) == expected, f"oracle case {index}: {key} mismatch")
    require(distinct == o.get("distinct_save_cases") == 5, "SAVE contrast case count mismatch")
    out = member(z, "native_stdout.txt").decode("utf-8")
    labels = re.findall(r"DIFF13_CASE_\d{2}_OK", out)
    require(labels == [case["label"] for case in cases] == e.get("case_labels_observed"),
            "Native case labels do not match oracle order")
    require(out.count("DIFF13_26_CHECKS_VERIFIED") == 1 and "DIFF13_FAILURE" not in out,
            "differential end marker/failure mismatch")
    require(e.get("native_differential_verified") is True, "Native differential receipt false")
    return {"run_id": DIFF["run"], "artifact_sha256": DIFF["artifact"],
            "combined_sha256": sha(body), "fixture_sha256": sha(fixture),
            "native_cases": len(labels), "native_assertions": 26,
            "distinct_save_cases": distinct, "exit_code": 0}


def main() -> None:
    require(len(sys.argv) == 3, "usage: stage02_acceptance_audit.py DISCOVERY.zip DIFF13.zip")
    for path in SHARED:
        require(git_blob(DISCOVERY["source"], path) == git_blob(DIFF["source"], path),
                f"production/reference source drift: {path}")
    for pin, path in ((DISCOVERY, "tools/stage02_discovery01_oracle.py"),
                      (DIFF, "tools/stage02_native_differential_oracle.py")):
        require((ROOT / path).read_bytes() == git_blob(pin["source"], path),
                f"local oracle drift: {path}")
    with open_artifact(Path(sys.argv[1]), DISCOVERY) as native:
        first = audit_discovery(native)
    with open_artifact(Path(sys.argv[2]), DIFF) as differential:
        second = audit_diff(differential)
    oracle = json.loads(subprocess.check_output(
        [sys.executable, str(ROOT / "tools/stage02_discovery01_oracle.py")], cwd=ROOT))
    require(oracle.get("checked_anchor_cases") == 13 and
            oracle.get("deterministic_property_cases") == 384 and
            oracle.get("native_false_pass") is False, "discovery Python oracle gate failed")
    require(oracle.get("false_test_sha256") == sha(git_blob(
        DISCOVERY["source"], "test/stage02_discovery01_tests.false")),
        "discovery Python oracle source mismatch")
    result = {
        "project_id": PROJECT,
        "decision_scope": "INDEPENDENT_STAGE2_RECONSTRUCTION_NOT_HISTORICAL_ARCHIVE",
        "discovery": first,
        "differential": second,
        "python_anchor_cases": 13,
        "python_seeded_property_cases": 384,
        "shared_source_paths_byte_identical": list(SHARED),
        "historical_archive_recovered": False,
        "reconstructed_stage2_evidence_gates": "PASS",
        "stage3_authorized_by_this_audit": False,
    }
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, KeyError, subprocess.CalledProcessError, zipfile.BadZipFile) as exc:
        print(f"STAGE2_ACCEPTANCE_AUDIT_FAILED: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
