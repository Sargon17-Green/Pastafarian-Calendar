#!/usr/bin/env python3
"""Independent Stage46 v002 HANDOFF structure verifier; NOT a Native attestation.

Accepting this receipt proves internal consistency, not that Windows tests ran.
Requires separate verification of original logs, machine and signed provenance.
Never runs Codesh/Java or writes to the repository.
"""
import argparse
import hashlib
import io
import json
from pathlib import Path
import re
import sys
import zipfile

FAMILY = "CODESH_STAGE46_DISCOVERY23"
RUN_ID = "20261021T155519Z_c4c6ea55"
BASE = "f35a6efd79b830810c8a33140ce8eb949b2c8671"
CANDIDATE = "98fc6f964f7f986fb672bb94fae96c0ffbff46f5aa119bc2cc4abd727846ef5c"
ORACLE = "8d75a665925d2b88aa2bbb82fb71157c515b24babd5db7889a14c508eb7911ee"
MANIFEST = "871ca2ee3aa4ebaf7686334aaba7a641831cf18663f01d58afbd6f5983a734f4"
EXITS = {"CODESH_NATIVE_COMPILE": 0, "JAVAC_PROBES": 0,
         "STAGE46_CLOSING_GATE_EXPECTED_RED": 0, "STAGE46_ORACLE_TAMPER": 1}
for number in range(29, 46):
    EXITS[f"STAGE{number}_{'PATCH' if number % 2 else 'OLD'}_REGRESSION"] = 0
# Execution order is grounded in RUN_STAGE46_NATIVE_v001.py: each child exits
# before the next child starts, and the regressions run 45 down through 29.
RUN_ORDER = (
    ["CODESH_NATIVE_COMPILE", "JAVAC_PROBES",
     "STAGE46_CLOSING_GATE_EXPECTED_RED", "STAGE46_ORACLE_TAMPER"]
    + [f"STAGE{n}_{'PATCH' if n % 2 else 'OLD'}_REGRESSION"
       for n in range(45, 28, -1)]
)
MARKERS = {
    "STAGE46_CLOSING_GATE_EXPECTED_RED": (
        "CODESH_STAGE46_DISCOVERY23_EXPECTED_RED_CONFIRMED",
        "FROZEN_SELECTED_YEAR_MATCHES=48", "CANONICAL_CLOSE_GATE_MATCHES=48",
        "OLD_NEXT_GATE_AS_CLOSING_MISMATCHES=48", "STAGE45_PATCH_OPENING_GATE_MATCHES=48",
        "PATCH_OBJECTS_DETACHED=48", "PATCH_REPEATED_AND_ORDER_STABLE=48",
        "OLD_INSTANCES_DETACHED=48", "REPEATED_AND_ORDER_STABLE=48",
        "CALLER_AND_SELECTED_UNCHANGED=48", "FIRST_LAST_DAY_MATCHES=48",
        "SIGNED_GATE_SPANS_MATCHES=48", "STAGE43_PATCH_REGRESSION_MATCHES=48",
        "NEXT_CASES=24", "PREVIOUS_CASES=24"),
    "STAGE46_ORACLE_TAMPER": ("FROZEN_SELECTED_CLOSE_GATE_ORACLE_FAIL idx=0",),
    "STAGE45_PATCH_REGRESSION": ("CODESH_STAGE45_PATCH22_GREEN_CONFIRMED", "PATCH_OPENING_GATE_MATCHES=48"),
    "STAGE44_OLD_REGRESSION": ("CODESH_STAGE44_DISCOVERY22_EXPECTED_RED_CONFIRMED", "OLD_CLOSING_GATE_AS_OPENING_MISMATCHES=48"),
    "STAGE43_PATCH_REGRESSION": ("CODESH_STAGE43_PATCH21_GREEN_CONFIRMED", "PATCH_INCLUSIVE_LENGTH_MATCHES=48"),
    "STAGE42_OLD_REGRESSION": ("CODESH_STAGE42_DISCOVERY21_EXPECTED_RED_CONFIRMED", "OLD_EXCLUSIVE_LENGTH_MISMATCHES=48"),
    "STAGE41_PATCH_REGRESSION": ("CODESH_STAGE41_PATCH20_GREEN_CONFIRMED", "PATCH_GATE_SPANS_MATCHES=48"),
    "STAGE40_OLD_REGRESSION": ("CODESH_STAGE40_DISCOVERY20_EXPECTED_RED_CONFIRMED", "OLD_INCLUSIVE_GATE_SPANS_MISMATCHES=48"),
    "STAGE39_PATCH_REGRESSION": ("CODESH_STAGE39_PATCH19_GREEN_CONFIRMED", "PATCH_YEAR_NUMBER_MATCHES=48"),
    "STAGE38_OLD_REGRESSION": ("CODESH_STAGE38_DISCOVERY19_EXPECTED_RED_CONFIRMED", "OLD_STALE_YEAR_NUMBER_MISMATCHES=48"),
    "STAGE37_PATCH_REGRESSION": ("CODESH_STAGE37_PATCH18_GREEN_CONFIRMED", "PATCH_SELECTED_MATCHES=48"),
    "STAGE36_OLD_REGRESSION": ("CODESH_STAGE36_DISCOVERY18_EXPECTED_RED_CONFIRMED", "OLD_FIRST_CANDIDATE_MISMATCHES=43"),
    "STAGE35_PATCH_REGRESSION": ("CODESH_STAGE35_PATCH17_GREEN_CONFIRMED", "PATCH_ERA_MATCHES=393"),
    "STAGE34_OLD_REGRESSION": ("CODESH_STAGE34_DISCOVERY17_EXPECTED_RED_CONFIRMED", "OLD_ERA_MISMATCH_PAIRS=184"),
    "STAGE33_PATCH_REGRESSION": ("CODESH_STAGE33_PATCH16_GREEN_CONFIRMED", "PATCH_DIRECTION_MATCHES=393"),
    "STAGE32_OLD_REGRESSION": ("CODESH_STAGE32_DISCOVERY16_EXPECTED_RED_CONFIRMED", "OLD_DIRECTION_MISMATCHES=170"),
    "STAGE31_PATCH_REGRESSION": ("CODESH_STAGE31_PATCH15_GREEN_CONFIRMED", "PATCH_COUPLING_MATCHES=393"),
    "STAGE30_OLD_REGRESSION": ("CODESH_STAGE30_DISCOVERY15_EXPECTED_RED_CONFIRMED", "OLD_COUPLING_MISMATCHES=393"),
    "STAGE29_PATCH_REGRESSION": ("CODESH_STAGE29_PATCH14_GREEN_CONFIRMED", "PATCH_REMAINING_DAYS_MATCHES=192"),
}

class InvalidReceipt(ValueError):
    pass

def ensure(condition, reason):
    if not condition:
        raise InvalidReceipt(reason)

def digest(data):
    return hashlib.sha256(data).hexdigest()

def verify(path):
    with zipfile.ZipFile(path) as archive:
        infos = archive.infolist()
        names = [entry.filename for entry in infos]
        ensure(len(names) == len(set(names)) == len({n.casefold() for n in names}), "duplicate ZIP entry")
        ensure(all(not n.startswith("/") and "\\" not in n and ":" not in n and
                   all(part not in ("", ".", "..") for part in n.split("/")) for n in names), "unsafe ZIP path")
        ensure(all((entry.external_attr >> 16) & 0o170000 != 0o120000 for entry in infos), "ZIP symlink")
        ensure(len(names) <= 120 and sum(entry.file_size for entry in infos) <= 150_000_000, "ZIP size bound")
        ensure(archive.testzip() is None, "ZIP CRC mismatch")
        members = set(names)
        required = {
            "RESULT.json", "MANIFEST.json", "SHA256SUMS.txt", "PROVENANCE/RECOVERY_RECEIPT.json",
            "EVIDENCE/native-stage46-candidate.jar", "EVIDENCE/DISCOVERY23_CANDIDATE.אמן",
            "EVIDENCE/FROZEN_ORACLE.tsv", "PINNED_INPUTS/PACKAGE_MANIFEST.json",
            "PINNED_INPUTS/DISCOVERY23_CANDIDATE.אמן",
            "PINNED_INPUTS/Stage16AdjacentSelectedVectors.tsv", "LOGS/runner.log",
        }
        for task in EXITS:
            required.update({f"LOGS/{task}.stdout.log", f"LOGS/{task}.stderr.log"})
        ensure(required <= members, "missing evidence: " + ",".join(sorted(required - members)))
        lines = archive.read("SHA256SUMS.txt").decode("utf-8").splitlines()
        checks = {}
        for line in lines:
            match = re.fullmatch(r"([0-9a-f]{64})  (.+)", line)
            ensure(match is not None, "bad checksum line")
            value, filename = match.groups()
            ensure(filename not in checks, "duplicate checksum name")
            checks[filename] = value
        ensure(set(checks) == members - {"SHA256SUMS.txt"}, "checksums not exhaustive")
        for filename, value in checks.items():
            ensure(digest(archive.read(filename)) == value, "checksum mismatch: " + filename)
        def load_json(filename):
            return json.loads(archive.read(filename).decode("utf-8-sig"))
        receipt = load_json("RESULT.json")
        header = load_json("MANIFEST.json")
        provenance = load_json("PROVENANCE/RECOVERY_RECEIPT.json")
        ensure(receipt.get("schema_version") == "WINDOWS-EXEC-PACK/2.1" and
               receipt.get("family_id") == FAMILY and receipt.get("package_version") == "v002",
               "wrong HANDOFF contract")
        ensure(receipt.get("status") == receipt.get("work_status") == "PASS" and
               receipt.get("process_exit_code") == 0 and
               receipt.get("expected_repository_state") == "EXPECTED_RED", "not successful recovery")
        ensure(receipt.get("stage") == 46 and receipt.get("last_completed_stage") == 45 and
               receipt.get("stage46_discovery_committed") is False and
               receipt.get("credited_new_windows_assertions") == 0, "premature stage credit")
        ensure(receipt.get("recovered_without_reexecution") is True and
               receipt.get("native_processes_reexecuted") == 0 and
               receipt.get("native_run_id") == RUN_ID, "not original Native run")
        source = receipt.get("source", {})
        ensure(source.get("pinned_branch_head") == BASE and
               source.get("candidate_discovery_source_sha256") == CANDIDATE and
               source.get("git_writes") is False, "source provenance conflict")
        ensure(header.get("family_id") == FAMILY and header.get("recovery") is True and
               header.get("native_run_id") == RUN_ID and header.get("work_status") == "PASS",
               "MANIFEST.json inconsistency")
        ensure(provenance.get("source_run_id") == RUN_ID and
               provenance.get("candidate_source_sha256") == CANDIDATE and
               provenance.get("oracle_sha256") == ORACLE, "recovery provenance inconsistency")
        ensure(digest(archive.read("PINNED_INPUTS/PACKAGE_MANIFEST.json")) == MANIFEST, "original manifest SHA")
        for filename in ("EVIDENCE/DISCOVERY23_CANDIDATE.אמן", "PINNED_INPUTS/DISCOVERY23_CANDIDATE.אמן"):
            ensure(digest(archive.read(filename)) == CANDIDATE, "candidate SHA: " + filename)
        for filename in ("EVIDENCE/FROZEN_ORACLE.tsv", "PINNED_INPUTS/Stage16AdjacentSelectedVectors.tsv"):
            ensure(digest(archive.read(filename)) == ORACLE, "frozen oracle SHA: " + filename)
        jar_bytes = archive.read("EVIDENCE/native-stage46-candidate.jar")
        ensure(len(jar_bytes) > 10000, "Native JAR too small")
        with zipfile.ZipFile(io.BytesIO(jar_bytes)) as jar:
            ensure(jar.testzip() is None and any(n.endswith(".class") for n in jar.namelist()),
                   "Native JAR invalid")
        gates = receipt.get("gates", [])
        ensure(len(gates) == len(EXITS) and len({gate["name"] for gate in gates}) == len(gates),
               "gate count/identity")
        ensure({gate["name"]: gate["exit_code"] for gate in gates} == EXITS, "gate exits")
        ensure(all(gate["outcome"] == ("EXPECTED_FAILURE" if gate["name"] == "STAGE46_ORACLE_TAMPER" else "PASS")
                   for gate in gates), "gate outcomes")
        runner = archive.read("LOGS/runner.log").decode("utf-8", "replace")
        ensure("ENGINE_ENTERED v001" in runner and RUN_ID in runner and
               "PACKAGE_SHA_AND_40_SIGNED_BASELINE_SOURCE_PASS" in runner and
               "JDK_VERSION_VERIFIED" in runner and "CODESH_COMPILER_SELECTED" in runner, "runner provenance")
        starts = re.findall(r"\bCHILD_START\s+([A-Z0-9_]+)\b", runner)
        exits = re.findall(r"\bCHILD_EXIT\s+([A-Z0-9_]+)\s+(-?\d+)", runner)
        ensure(len(starts) == len(exits) == len(EXITS) and
               set(starts) == set(EXITS) and len(set(starts)) == len(EXITS),
               "runner task set")
        ensure(len({name for name, _ in exits}) == len(EXITS) and
               {name: int(value) for name, value in exits} == EXITS, "runner task exits")
        # Reject impossible/forged chronologies even when the multiset of
        # tasks, individual exit codes and all semantic markers agree.
        observed_events = re.findall(r"\bCHILD_(START|EXIT)\s+([A-Z0-9_]+)\b", runner)
        expected_events = [
            (kind, name) for name in RUN_ORDER for kind in ("START", "EXIT")
        ]
        ensure(observed_events == expected_events, "runner event order/overlap")
        for task, markers in MARKERS.items():
            suffix = "stderr" if task == "STAGE46_ORACLE_TAMPER" else "stdout"
            content = archive.read(f"LOGS/{task}.{suffix}.log").decode("utf-8", "replace")
            ensure(all(marker in content for marker in markers), "semantic marker: " + task)
        ensure(receipt.get("provenance", {}).get("signed_baseline_count") == 40 and
               receipt.get("provenance", {}).get("run_count") == 21, "source/task count provenance")
    return {"status": "STRUCTURE_PASS_NOT_NATIVE_ATTESTATION", "gates": len(EXITS)}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("handoff", type=Path)
    args = parser.parse_args()
    try:
        print(json.dumps(verify(args.handoff), sort_keys=True))
        return 0
    except (InvalidReceipt, ValueError, KeyError, AssertionError, OSError, zipfile.BadZipFile) as exc:
        print("REJECTED: " + str(exc), file=sys.stderr)
        return 2

if __name__ == "__main__":
    raise SystemExit(main())
