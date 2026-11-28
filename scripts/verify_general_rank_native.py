#!/usr/bin/env python3
"""Bounded QA-only native rank gate for five non-Foundation fixtures.

Requires fixtures created by scripts/prepare_general_lex_ranks.js.
Compiles only tests/pcal_stage1_oracle_pkg.sv + tests/tb_weave_general_rank.sv.
Does not run Foundation H45, select years/cutlets/months, or claim Stage1 acceptance.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import shutil
import subprocess
import time

PACKAGE_BLOB = "89b59176033b8b9808f6a5f7d8cc4bbe998fdd1d"
BENCH_BLOB = "9befa35ae6b4c02ff371083057159eb138533746"
ORACLE_BLOB = "e228f43f2d33b9af59c5fb232281ca403455ca5c"
CASES = (
    "year4999",
    "year5001",
    "creation_minus1234",
    "creation_plus1234",
    "year5002",
)
WORD_PINS = {
    "year4999": "6a1f8b7536eb8fa908c9472a289c36b6c2e80ab8a882110b2fa39f95a742d675",
    "year5001": "48065ca44d184f2fe002edfcc79ff4ba1612b828dfed71a8afbacf4be1dcee24",
    "creation_minus1234": "705e7e4245ddde6b91291e1d78789b78243127a68d40621d2c256b81035c132a",
    "creation_plus1234": "13fe3563f6f829f1af164b11c847a24f3ba59302a1a4805a92daedfb7daa839b",
    "year5002": "93a05ffb9b7d66bf5d06e5e229fc69bc73bfba19ec5b3324247ef4f8a14ca200",
}
RANK_PINS = {
    "year4999": "1f1db813c0d3c7932b7ce4d106f57e68af1ff29d87a50f1484e094d7c892abb7",
    "year5001": "5b18428fecea6764dc90476754a2d54c4b22d90bdc075b829797e6d15f8d6efe",
    "creation_minus1234": "0488e6cd82f84be3f32cd008d15de6bc492187c65982855333099fac95b02182",
    "creation_plus1234": "6312280c94133462d4604997cfd632115216af7992358b53d887dc78a6af2b2b",
    "year5002": "c64b94729890ca9773c115f48e0fbfaa60d4ee6c0aa917295714f9b623c8f211",
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def git_blob_sha(path: pathlib.Path) -> str:
    data = path.read_bytes()
    return hashlib.sha1(f"blob {len(data)}\0".encode() + data).hexdigest()


def run(command: list[str], log_path: pathlib.Path, seconds: int) -> str:
    start = time.monotonic()
    try:
        completed = subprocess.run(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=seconds,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        output = exc.stdout or b""
        if isinstance(output, str):
            output = output.encode()
        log_path.write_bytes(output + b"\nTIMEOUT\n")
        raise RuntimeError(f"timeout after {seconds}s: {' '.join(command)}") from exc
    output = completed.stdout or b""
    elapsed = time.monotonic() - start
    log_path.write_bytes(output + f"\nELAPSED_SECONDS={elapsed:.3f}\n".encode())
    if completed.returncode != 0:
        raise RuntimeError(
            f"exit={completed.returncode}: {' '.join(command)}; log={log_path}"
        )
    return output.decode("utf-8", errors="replace") + f"\nELAPSED_SECONDS={elapsed:.3f}\n"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("fixtures", type=pathlib.Path)
    parser.add_argument("output", type=pathlib.Path)
    args = parser.parse_args()
    fixtures = args.fixtures.resolve()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)

    manifest_path = fixtures / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    require(manifest.get("oracleBlob") == ORACLE_BLOB, "oracle blob pin mismatch")
    require(manifest.get("foundationSkipped") is True, "Foundation fixture must be skipped")
    cases = manifest.get("cases")
    require(isinstance(cases, list) and len(cases) == len(CASES), "fixture case count mismatch")
    by_name = {entry.get("name"): entry for entry in cases}
    require(len(by_name) == len(cases) and set(by_name) == set(CASES), "fixture case set mismatch")

    tests = pathlib.Path(__file__).resolve().parent.parent / "tests"
    package = tests / "pcal_stage1_oracle_pkg.sv"
    bench = tests / "tb_weave_general_rank.sv"
    require(git_blob_sha(package) == PACKAGE_BLOB, "oracle package blob mismatch")
    require(git_blob_sha(bench) == BENCH_BLOB, "native rank bench blob mismatch")
    require(shutil.which("iverilog") and shutil.which("vvp"), "Icarus/vvp absent; Native NOT_RUN")
    require(shutil.disk_usage(output).free >= 2 * 1024**3, "less than 2 GiB free")

    results: dict[str, object] = {
        "scope": "NATIVE_SAUCE_RANK_ONLY_HOST_GEOMETRY_AND_ROOT_STAGE1_NOT_ACCEPTED",
        "oracleBlob": ORACLE_BLOB,
        "packageBlob": PACKAGE_BLOB,
        "benchBlob": BENCH_BLOB,
        "foundationSkipped": True,
        "cases": [],
    }
    result_path = output / "native_rank_manifest.json"
    result_path.write_text(json.dumps(results, indent=2) + "\n", encoding="utf-8")

    executable = output / "general_rank.vvp"
    compile_log = output / "compile.log"
    run(
        [
            "iverilog",
            "-g2012",
            "-s",
            "tb_weave_general_rank",
            "-o",
            str(executable),
            str(package),
            str(bench),
        ],
        compile_log,
        60,
    )
    results["compile"] = "PASS"
    result_path.write_text(json.dumps(results, indent=2) + "\n", encoding="utf-8")

    for name in CASES:
        entry = by_name[name]
        require(entry.get("wordSHA256") == WORD_PINS[name], f"word SHA pin mismatch: {name}")
        require(entry.get("rankSHA256") == RANK_PINS[name], f"rank SHA pin mismatch: {name}")
        geometry = fixtures / f"{name}.geometry"
        expected_root = fixtures / f"{name}.expected"
        expected_rank = fixtures / f"{name}.rank"
        require(sha256(geometry.read_bytes()) == entry.get("geometrySHA256"), f"geometry SHA mismatch: {name}")
        require(sha256(expected_root.read_bytes()) == entry.get("rootSHA256"), f"root SHA mismatch: {name}")
        require(sha256(expected_rank.read_bytes()) == RANK_PINS[name], f"rank fixture SHA mismatch: {name}")
        require(len(expected_root.read_bytes()) == 4096, f"root byte length mismatch: {name}")
        require(len(expected_rank.read_bytes()) == 4096, f"rank byte length mismatch: {name}")

        case_dir = output / name
        case_dir.mkdir()
        actual_rank = case_dir / "native.rank"
        log_path = case_dir / "native.log"
        command = [
            "vvp",
            str(executable),
            f"+creation={int(entry['c'])}",
            f"+opening={int(entry['open'])}",
            f"+root={expected_root}",
            f"+rank={actual_rank}",
        ]
        creation = int(entry["c"])
        opening = int(entry["open"])
        foundation = -15055671
        require(foundation - 50000 <= creation <= foundation + 50000, f"creation out of bound: {name}")
        require(foundation - 55778 <= opening <= foundation + 50000, f"opening out of bound: {name}")
        started = time.monotonic()
        case_result = {
            "name": name,
            "creation": creation,
            "opening": opening,
            "year": entry["year"],
            "days": entry["days"],
            "months": entry["months"],
            "native": "RUNNING",
        }
        results["cases"].append(case_result)
        result_path.write_text(json.dumps(results, indent=2) + "\n", encoding="utf-8")
        try:
            log = run(command, log_path, 120)
            require("GENERAL_NATIVE_RANK_PASS" in log, f"native rank marker missing: {name}")
            actual = actual_rank.read_bytes()
            expected = expected_rank.read_bytes()
            digest = sha256(actual)
            require(len(actual) == 4096, f"native rank byte length mismatch: {name}")
            require(actual == expected, f"native rank differs from pinned host rank: {name}")
            require(digest == RANK_PINS[name], f"native rank SHA mismatch: {name}")
        except Exception as exc:
            case_result["native"] = "FAIL"
            case_result["error"] = str(exc)
            result_path.write_text(json.dumps(results, indent=2) + "\n", encoding="utf-8")
            raise
        case_result.update(
            {
                "rankSHA256": digest,
                "native": "PASS",
                "elapsedSeconds": round(time.monotonic() - started, 3),
            }
        )
        result_path.write_text(json.dumps(results, indent=2) + "\n", encoding="utf-8")

    require(len(results["cases"]) == 5, "native rank coverage incomplete")
    results["status"] = "NATIVE_GENERAL_RANK_PASS"
    result_path.write_text(json.dumps(results, indent=2) + "\n", encoding="utf-8")
    print("NATIVE_GENERAL_RANK_PASS cases=5 days=20763 FOUNDATION_SKIPPED STAGE1_NOT_ACCEPTED")


if __name__ == "__main__":
    main()
