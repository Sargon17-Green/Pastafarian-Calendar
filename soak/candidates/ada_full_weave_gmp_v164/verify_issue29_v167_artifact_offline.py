#!/usr/bin/env python3
"""Read-only independent verification of v167 one-shot GitHub evidence ZIP.

Never imports or executes any calendar code. Does not infer a PASS from CI
status; checks receipt, hashes, program output, resource caps and run identity.
"""
from __future__ import annotations

from hashlib import sha256
from io import BytesIO
import json
from pathlib import Path
import sys
from zipfile import ZipFile

EXPECTED = [5000, 10, 503, 20, 56]
MAIN_SHA = "56bc4173aae4975ded019ef5ab5a36249f1424df"


def die(msg: str) -> None:
    raise RuntimeError(msg)


def sha(raw: bytes) -> str:
    return sha256(raw).hexdigest()


def main() -> None:
    if len(sys.argv) != 4:
        die("usage: audit.py ZIP_PATH EXPECTED_ZIP_SHA256 NEW_AUDIT_JSON")
    archive, expected, output = Path(sys.argv[1]), sys.argv[2], Path(sys.argv[3])
    if archive.stat().st_size > 4_000_000:
        die("archive exceeds bounded evidence size")
    actual_zip = sha(archive.read_bytes())
    if actual_zip != expected:
        die("artifact zip not equal to exact reported GitHub SHA256")
    with ZipFile(BytesIO(archive.read_bytes())) as z:
        index = {i.filename for i in z.infolist()}
        required = {
            "v167-evidence-member-hashes.json",
            "v167-foundation-run-receipt.json",
            "v167-preflight.json",
            "v167-corrected-ada.stdout",
            "v167-corrected-ada.stderr",
            "RUN_STARTED_ONCE",
            "v164-qa-integration-receipt.json",
            "issue29_v167_preflight_accepted.json",
        }
        if not required.issubset(index) or any("/" in name or ".." in name for name in index):
            die("required artifact members missing, duplicated or unexpectedly nested")
        if len(index) != len(z.infolist()):
            die("duplicate names inside GitHub artifact")
        hashes = json.loads(z.read("v167-evidence-member-hashes.json"))
        if set(hashes) != index - {"v167-evidence-member-hashes.json"}:
            die("member hashes do not cover exactly the complete prior evidence set")
        for name, info in hashes.items():
            b = z.read(name)
            if sha(b) != info["sha256"] or len(b) != info["bytes"]:
                die("evidence tamper detected: " + name)
        receipt = json.loads(z.read("v167-foundation-run-receipt.json"))
        preflight = json.loads(z.read("v167-preflight.json"))
        adapter = json.loads(z.read("v164-qa-integration-receipt.json"))
        gate = json.loads(z.read("issue29_v167_preflight_accepted.json"))
        run_marker = json.loads(z.read("RUN_STARTED_ONCE"))
        stdout = z.read("v167-corrected-ada.stdout").decode("utf-8")
        stderr = z.read("v167-corrected-ada.stderr")
    if receipt["status"] != "PASS" or not receipt["process_completed_exit0"]:
        die("corrected QA process did not finish successfully")
    if receipt["observed_five_fields"] != EXPECTED or receipt["expected_five_fields"] != EXPECTED:
        die("full corrected Ada output not equal canonical five-field vector")
    if receipt["matches_original_failed_ada"]:
        die("output still equals historical Ada mismatch")
    if not receipt["matches_canonical_reference"] or receipt["parse_error"] is not None:
        die("missing canonical equality or parse error")
    if receipt["actual_qa_calendar_calls_attempted"] != 1 or receipt["original_historical_calendar_calls"] != 0:
        die("not exactly one corrected QA call or original call detected")
    if receipt["full_year_soak_years"] != 0 or receipt["production_certified"] is not False:
        die("incorrect promotion to Soak or production")
    p = receipt["process_receipt"]
    if p["status"] != "completed" or p["exit_code"] != 0:
        die("process exit/runtime gates failed")
    if p["combined_output_cap_bytes"] != 131072 or p["wall_seconds_cap"] != 90 or p["address_space_cap_bytes"] != 768 * 1024 * 1024:
        die("runtime resource bounds changed")
    if p["stdout_sha256"] != sha(stdout.encode()) or p["stderr_sha256"] != sha(stderr):
        die("run receipt and raw streams disagree")
    lines = [s for s in stdout.splitlines() if s.startswith("V160_ADA_RESULT|")]
    if len(lines) != 1 or [int(x.strip()) for x in lines[0].split("|")[1:]] != EXPECTED:
        die("raw numeric output differs or multiple date result lines")
    if preflight != receipt["locked_preflight"]:
        die("preflight mutated between seal and invocation")
    if preflight["source_commit"] != adapter["source_commit"] or preflight["qa_oracle_sha256"] != adapter["qa_oracle_sha256"]:
        die("adapter source lock not equal final preflight")
    if preflight["github_run_attempt"] != 1 or preflight["source_historical_blob_sha1"] != "923733d4f8face03586aee304640bf7540c28b4c":
        die("historical source or one-shot attempt not locked")
    if run_marker["run_id"] != preflight["github_run_id"] or run_marker["sha256"] != preflight["linked_binary_sha256"]:
        die("exclusive marker and binary/run identity differ")
    if gate["source_preflight_commit"] != "f8cd2e9f3cb42fc70146225202efb257693129b1" or gate["preflight_status"] != "SUCCESS":
        die("source preflight was not accepted")
    if receipt["STOP_NEW_NATIVE_SOAK_DISPATCH"] is not True or receipt["new_run_attempts_forbidden"] is not True:
        die("Soak halt or no-retry condition not maintained")

    if output.exists():
        die("refusing to overwrite independent audit")
    proof = {
        "schema": "ISSUE29_V167_INDEPENDENT_OFFLINE_ARTIFACT_AUDIT/1",
        "zip_sha256": actual_zip,
        "github_run_id": preflight["github_run_id"],
        "github_workflow_sha": preflight["git_sha_of_QA_workflow"],
        "binary_sha256": preflight["linked_binary_sha256"],
        "observed_canonical_five_fields": EXPECTED,
        "all_artifact_members_hashed_exactly": True,
        "original_F_calls": 0,
        "corrected_QA_F_calls_attempted": 1,
        "full_year_soak_years": 0,
        "production_approved": False,
        "single_invocation_scope_verified_from_receipts": True,
        "verdict": "QA_FOUNDATION_ONE_SHOT_PASS_NOT_PRODUCTION_RELEASE",
    }
    output.write_text(json.dumps(proof,indent=2,sort_keys=True)+"\n")
    print("V167_INDEPENDENT_FIVE_FIELDS_AND_PROVENANCE_AUDIT_PASS")


if __name__ == "__main__":
    main()
