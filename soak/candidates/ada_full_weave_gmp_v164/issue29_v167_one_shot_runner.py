#!/usr/bin/env python3
"""Issue29 v167: exactly ONE authorized foundation invocation in corrected QA Ada.

Not an original source run, not a Soak, not a range test. An exclusive attempt
marker is persisted before process creation, and the GitHub run attempt must be
one. Even on failure or mismatch the child is never retried by this script.
"""
from __future__ import annotations

import argparse
from hashlib import sha256
import json
import os
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "runner"))
from issue29_foundation_capture_v160 import run_bounded  # noqa: E402


EXPECTED = [5000, 10, 503, 20, 56]
HISTORICAL_ADA = [5000, 10, 503, 30, 52]
MAIN_SOURCE_LOCK = "56bc4173aae4975ded019ef5ab5a36249f1424df"
HISTORICAL_ORACLE_BLOB = "923733d4f8face03586aee304640bf7540c28b4c"
EXPECTED_SHADED_FILE = "normative_oracle.adb"
MAX_WALL_SECONDS = 90
MAX_CPU_SECONDS = 90
MAX_AS_BYTES = 768 * 1024 * 1024
MAX_OUTPUT_BYTES = 128 * 1024


def checksum(content: bytes) -> str:
    return sha256(content).hexdigest()


def fail_if_not(cond: bool, explanation: str) -> None:
    if not cond:
        raise RuntimeError(explanation)


def verify_preflight(root: Path) -> dict:
    prep = json.loads((root / "preparation.json").read_text(encoding="utf-8"))
    adapter = json.loads((root / "v164-qa-integration-receipt.json").read_text(encoding="utf-8"))
    binary = root / "ada-build" / "bin" / "issue29_foundation_probe"
    source = root / "ada-build" / "src" / EXPECTED_SHADED_FILE
    fail_if_not(prep["main_commit"] == MAIN_SOURCE_LOCK, "historical MAIN changed")
    fail_if_not(prep["source_dispatch_count"] == 0 and prep["soak_years"] == 0,
                "historical preparation is not zero-dispatch")
    fail_if_not(prep["case"] == {"c": "-15055671", "t": "-15055671"},
                "only the exact, previously diagnosed foundation case is authorized")
    fail_if_not(adapter["source_git_blob_sha1"] == HISTORICAL_ORACLE_BLOB,
                "historical Ada source lock mismatch")
    fail_if_not(adapter["exact_byte_reversibility"] is True
                and adapter["mode"] == "QA_COPY_COMPILE_ONLY"
                and adapter["source_calendar_F_calls"] == 0
                and adapter["qa_calendar_F_calls"] == 0
                and adapter["STOP_NEW_NATIVE_SOAK_DISPATCH"] is True,
                "QA candidate was not made by reversible source-locked adapter")
    fail_if_not(source.is_file() and checksum(source.read_bytes()) == adapter["qa_oracle_sha256"],
                "candidate Ada source changed after integration")
    fail_if_not(binary.is_file(), "linked integrated Ada QA binary absent")
    for filename, expected_sha in adapter["dependencies_sha256"].items():
        p = root / "ada-build" / "src" / filename
        fail_if_not(p.is_file() and checksum(p.read_bytes()) == expected_sha,
                    "candidate GMP dependency changed after integration: " + filename)
    fail_if_not(os.environ.get("GITHUB_RUN_ATTEMPT") == "1",
                "rerunning this workflow attempt is expressly forbidden")
    fail_if_not(os.environ.get("GITHUB_EVENT_NAME") == "push",
                "one-shot is only allowed on the exact QA branch push")
    fail_if_not(os.environ.get("GITHUB_REF") == "refs/heads/qa/issue29-ada-gmp-foundation-v167",
                "not the authorized isolated QA branch")
    run_id = os.environ.get("GITHUB_RUN_ID", "")
    fail_if_not(run_id.isdigit(), "no GitHub run ID to identify one-shot experiment")
    fail_if_not(not (root / "RUN_STARTED_ONCE").exists(),
                "prior attempt marker exists; no retry allowed")
    return {
        "schema": "ISSUE29_V167_ONE_SHOT_GMP_FOUNDATION_PREFLIGHT/1",
        "source_historical_blob_sha1": HISTORICAL_ORACLE_BLOB,
        "source_commit": adapter["source_commit"],
        "qa_oracle_sha256": adapter["qa_oracle_sha256"],
        "qa_dependencies_sha256": adapter["dependencies_sha256"],
        "linked_binary_sha256": checksum(binary.read_bytes()),
        "git_sha_of_QA_workflow": os.environ.get("GITHUB_SHA"),
        "github_run_id": run_id,
        "github_run_attempt": 1,
        "calendar_case": {"c": -15055671, "t": -15055671},
        "reference_result": EXPECTED,
        "known_historical_ada_mismatch": HISTORICAL_ADA,
        "binary_mode": "SINGLE_QA_CORRECTED_ADA_FOUNDATION_NOT_ORIGINAL",
        "wall_cap_seconds": MAX_WALL_SECONDS,
        "cpu_cap_seconds": MAX_CPU_SECONDS,
        "address_space_cap_bytes": MAX_AS_BYTES,
        "combined_output_cap_bytes": MAX_OUTPUT_BYTES,
        "rerun_allowed": False,
        "original_source_calls_this_workflow": 0,
        "soak_years_this_workflow": 0,
    }


def verify_no_duplicate_output(stdout: bytes) -> list[int]:
    data = stdout.decode("utf-8")
    accepted = [line for line in data.splitlines() if line.startswith("V160_ADA_RESULT|")]
    if len(accepted) != 1:
        raise RuntimeError("one-and-only-one corrected foundation result expected")
    parts = accepted[0].split("|")
    if len(parts) != 6:
        raise RuntimeError("unexpected corrected result field count")
    try:
        return [int(x.strip()) for x in parts[1:]]
    except ValueError as exc:
        raise RuntimeError("non-numeric field in corrected Ada result") from exc


def write_new_json(dest: Path, obj: dict) -> None:
    with dest.open("x", encoding="utf-8") as out:
        json.dump(obj, out, indent=2, sort_keys=True, ensure_ascii=False)
        out.write("\n")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", type=Path)
    parser.add_argument("mode", choices=("preflight", "run-once"))
    args = parser.parse_args()
    root = args.root.resolve()
    preflight = verify_preflight(root)
    receipt = root / "v167-foundation-run-receipt.json"

    if args.mode == "preflight":
        fail_if_not(not receipt.exists(), "prior run receipt present")
        write_new_json(root / "v167-preflight.json", preflight)
        print("V167_PREFLIGHT_LOCKED_CORRECTED_ADA_QA_BINARY_ONLY")
        print("V167_PREFER_ONE_ACTUAL_FOUNDATION_CALL_NOT_SOAK")
        return 0

    preflight_path = root / "v167-preflight.json"
    fail_if_not(preflight_path.is_file(), "preflight has not been recorded")
    before = json.loads(preflight_path.read_text(encoding="utf-8"))
    fail_if_not(before == preflight, "binary/source/commit changed after preflight")
    fail_if_not(not receipt.exists(), "prior attempt receipt present")
    binary = root / "ada-build" / "bin" / "issue29_foundation_probe"
    attempt = root / "RUN_STARTED_ONCE"

    # The exclusive marker is written BEFORE starting the child process.
    with attempt.open("x", encoding="utf-8") as out:
        out.write(json.dumps({
            "purpose": "single corrected QA Ada F(-15055671,-15055671), no retry",
            "run_id": os.environ["GITHUB_RUN_ID"],
            "sha256": preflight["linked_binary_sha256"],
        }, sort_keys=True) + "\n")

    env_old = os.environ.pop("PC_STAGE13_DIAGNOSTIC", None)
    try:
        process = run_bounded(
            [str(binary)],
            root / "ada-build",
            root / "v167-corrected-ada.stdout",
            root / "v167-corrected-ada.stderr",
            MAX_WALL_SECONDS,
            MAX_OUTPUT_BYTES,
            MAX_AS_BYTES,
            MAX_CPU_SECONDS,
        )
    finally:
        if env_old is not None:
            os.environ["PC_STAGE13_DIAGNOSTIC"] = env_old

    success = process["status"] == "completed" and process["exit_code"] == 0
    observed = None
    error = None
    if success:
        try:
            observed = verify_no_duplicate_output(
                (root / "v167-corrected-ada.stdout").read_bytes())
        except Exception as exc:
            error = type(exc).__name__ + ": " + str(exc)
    verdict = {
        "schema": "ISSUE29_V167_SINGLE_AUTHORIZED_QA_FOUNDATION_RESULT/1",
        "status": "PASS" if success and observed == EXPECTED else "FAIL",
        "process_completed_exit0": success,
        "observed_five_fields": observed,
        "expected_five_fields": EXPECTED,
        "matches_canonical_reference": observed == EXPECTED,
        "matches_original_failed_ada": observed == HISTORICAL_ADA,
        "parse_error": error,
        "process_receipt": process,
        "locked_preflight": preflight,
        "actual_qa_calendar_calls_attempted": 1,
        "original_historical_calendar_calls": 0,
        "full_year_soak_years": 0,
        "STOP_NEW_NATIVE_SOAK_DISPATCH": True,
        "new_run_attempts_forbidden": True,
        "production_certified": False,
    }
    write_new_json(receipt, verdict)
    print("V167_SINGLE_QA_FOUNDATION_ATTEMPT_FINISHED", verdict["status"])
    print("V167_CORRECTED_ADA_OBSERVED", observed)
    if verdict["status"] != "PASS":
        raise RuntimeError("v167 one-shot corrected QA run did not match canonical reference: "
                           + json.dumps({"observed": observed, "error": error, "process": process}))
    print("V167_SINGLE_QA_FOUNDATION_ALL_FIVE_FIELDS_EQUAL")
    print("V167_NO_ORIGINAL_SOURCE_F_NO_SOAK_NO_RERUN")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
