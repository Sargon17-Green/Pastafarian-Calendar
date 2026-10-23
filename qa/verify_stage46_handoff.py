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
# Pinned to the source script within the *original v001 package manifest*.
# This is NOT the hash of the dynamically generated LOGS/runner.log.
RUNNER_SCRIPT_SHA = "e8b318f1a6e5bc8b056461947f91cddc503a771b5a1ae2473c92be0be99f7b09"
STAGE45_HANDOFF_SHA = "e61649df2ad6b91f61be201fd26f5d943ee7b86032d15edb37cf265e5c175289"
OLD_CANDIDATE_MANIFEST_PATH = (
    "payload/CANDIDATE_SOURCE/מקור/מסלול־שער־סוגר־שנה־סמוכה־ישן.אמן"
)
MAX_JAR_UNCOMPRESSED = 200_000_000
MAX_JAR_MEMBER_UNCOMPRESSED = 50_000_000
MAX_JAR_ENTRIES = 4096
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
            "RESULT.json", "RESULT.txt", "MANIFEST.json", "SHA256SUMS.txt",
            "00_START_HERE_HE.md", "01_CONTINUE_PROMPT_HE.md",
            "PROVENANCE/RECOVERY_RECEIPT.json",
            "LOGS/bootstrap.log", "LOGS/recovery_bootstrap.log",
            "EVIDENCE/native-stage46-candidate.jar", "EVIDENCE/DISCOVERY23_CANDIDATE.אמן",
            "EVIDENCE/FROZEN_ORACLE.tsv", "PINNED_INPUTS/PACKAGE_MANIFEST.json",
            "PINNED_INPUTS/DISCOVERY23_CANDIDATE.אמן",
            "PINNED_INPUTS/Stage16AdjacentSelectedVectors.tsv", "LOGS/runner.log",
        }
        for task in EXITS:
            required.update({f"LOGS/{task}.stdout.log", f"LOGS/{task}.stderr.log"})
        ensure(members == required,
               "HANDOFF member set differs from v002 producer: missing=" +
               ",".join(sorted(required - members)) + " extra=" +
               ",".join(sorted(members - required)))
        ensure(len(members) == 58, "v002 PASS HANDOFF must contain exactly 58 members")
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
        def unique_json_fields(pairs):
            data = {}
            for key, value in pairs:
                ensure(key not in data, "ambiguous duplicate JSON key: " + key)
                data[key] = value
            return data

        def reject_json_nonfinite(token):
            raise InvalidReceipt("nonfinite JSON number: " + token)

        def load_json(filename):
            data = json.loads(
                archive.read(filename).decode("utf-8-sig"),
                object_pairs_hook=unique_json_fields,
                parse_constant=reject_json_nonfinite,
            )
            ensure(isinstance(data, dict), "JSON must be an object: " + filename)
            return data
        receipt = load_json("RESULT.json")
        header = load_json("MANIFEST.json")
        provenance = load_json("PROVENANCE/RECOVERY_RECEIPT.json")
        ensure(receipt.get("schema_version") == "WINDOWS-EXEC-PACK/2.1" and
               receipt.get("family_id") == FAMILY and receipt.get("package_version") == "v002",
               "wrong HANDOFF contract")
        for key in ("stage", "last_completed_stage", "process_exit_code",
                    "native_processes_reexecuted", "credited_new_windows_assertions",
                    "previous_windows_assertion_counter"):
            ensure(type(receipt.get(key)) is int,
                   "non-integer numeric receipt field: " + key)
        ensure(receipt.get("status") == receipt.get("work_status") == "PASS" and
               receipt.get("process_exit_code") == 0 and
               receipt.get("expected_repository_state") == "EXPECTED_RED", "not successful recovery")
        ensure(receipt.get("stage") == 46 and receipt.get("last_completed_stage") == 45 and
               receipt.get("stage46_discovery_committed") is False and
               receipt.get("credited_new_windows_assertions") == 0, "premature stage credit")
        ensure(receipt.get("recovered_without_reexecution") is True and
               receipt.get("native_processes_reexecuted") == 0 and
               receipt.get("native_run_id") == RUN_ID, "not original Native run")
        ensure(receipt.get("source", {}).get("branch") == "Codesh+𐤉𐤄𐤅𐤃𐤉𐤕",
               "wrong Codesh branch identity")
        ensure(receipt.get("recovery_cause") ==
               "STAGE46_v001 finalizer erroneously opened PINNED_INPUTS/PATCH22_CANDIDATE instead of DISCOVERY23_CANDIDATE",
               "recovery cause changed")
        ensure(receipt.get("original_package_version") == "v001" and
               receipt.get("previous_windows_assertion_counter") == 777277 and
               receipt.get("reason_code") ==
               "RECOVERED_NATIVE_CODESH_EXPECTED_RED_48_NEXT_GATE_ERRORS_STAGE45_GREEN",
               "recovery identity/credit fields mismatch")
        run_id = receipt.get("run_id")
        ensure(isinstance(run_id, str) and
               re.fullmatch(r"[0-9]{8}T[0-9]{6}Z_[0-9a-f]{8}", run_id) is not None,
               "malformed recovery run id")
        source = receipt.get("source", {})
        ensure(source.get("pinned_branch_head") == BASE and
               source.get("candidate_discovery_source_sha256") == CANDIDATE and
               source.get("git_writes") is False, "source provenance conflict")
        ensure(header.get("contract") == "WINDOWS-EXEC-PACK/2.1" and
               header.get("family_id") == FAMILY and
               header.get("package_version") == "v002" and
               header.get("run_id") == run_id and
               header.get("recovery") is True and
               header.get("native_run_id") == RUN_ID and
               header.get("work_status") == "PASS", "MANIFEST.json inconsistency")
        # The v002 packager generates a plaintext receipt and two handoff guides
        # in addition to the JSON records. Do not accept contradictory summaries.
        plain = archive.read("RESULT.txt").decode("utf-8")
        ensure(plain == (
            "WORK=PASS\n"
            "REASON=" + receipt["reason_code"] + "\n"
            "STAGE46=NOT_COMMITTED\nRECOVERY_ONLY=YES\n"
        ), "plaintext result contradicts signed receipt")
        guide = archive.read("00_START_HERE_HE.md").decode("utf-8")
        ensure(guide.startswith("# Stage46 DISCOVERY23 recovery: PASS\n") and
               "Original native run: " + RUN_ID + "; reason=" + receipt["reason_code"] in guide,
               "handoff guide does not match original run")
        continuation = archive.read("01_CONTINUE_PROMPT_HE.md").decode("utf-8")
        ensure("Validate Stage46 DISCOVERY23 recovered native HANDOFF v002" in continuation and
               "Do not open Stage47 or modify main." in continuation,
               "continuation instructions missing")
        ensure(provenance.get("source_run_id") == RUN_ID and
               provenance.get("source_family") == FAMILY and
               provenance.get("failure") ==
               "native HANDOFF finalizer used wrong PINNED_INPUTS/PATCH22_CANDIDATE filename" and
               provenance.get("repair") ==
               "recovered original logs/compiled JAR/manifest/pinned inputs without rerunning" and
               provenance.get("candidate_source_sha256") == CANDIDATE and
               provenance.get("oracle_sha256") == ORACLE, "recovery provenance inconsistency")
        ensure(digest(archive.read("PINNED_INPUTS/PACKAGE_MANIFEST.json")) == MANIFEST, "original manifest SHA")
        original = load_json("PINNED_INPUTS/PACKAGE_MANIFEST.json")
        assert_orig_fields = (
            original.get("schema") == "codesh-stage46-adjacent-closing-gate-discovery-v1"
            and original.get("family_id") == FAMILY
            and original.get("package_version") == "v001"
            and original.get("pinned_branch_head") == BASE
            and original.get("candidate_source_sha256") == CANDIDATE
            and original.get("oracle_sha256") == ORACLE
            and original.get("signed_stage45_handoff_sha256") == STAGE45_HANDOFF_SHA
        )
        ensure(assert_orig_fields, "original v001 manifest identity differs from pinned inputs")
        original_files = original.get("files")
        ensure(isinstance(original_files, dict) and len(original_files) == 62,
               "original v001 manifest member count mismatch")
        baseline_files = {name: value for name, value in original_files.items()
                          if name.startswith("payload/BASELINE_SOURCE/")}
        ensure(len(baseline_files) == 40 and
               all(re.fullmatch(r"[0-9a-f]{64}", value) for value in baseline_files.values()),
               "original v001 manifest signed source count/digest invalid")
        ensure(original_files.get("payload/RUN_STAGE46_NATIVE_v001.py") == RUNNER_SCRIPT_SHA,
               "original v001 Native runner script digest mismatch")
        ensure(original_files.get(OLD_CANDIDATE_MANIFEST_PATH) == CANDIDATE and
               original_files.get("payload/ORACLE/Stage16AdjacentSelectedVectors.tsv") == ORACLE and
               original_files.get("payload/PROVENANCE/STAGE45_WINDOWS_SIGNED_PASS.zip")
               == STAGE45_HANDOFF_SHA, "v001 manifest candidate/oracle/previous handoff inconsistent")
        for filename in ("EVIDENCE/DISCOVERY23_CANDIDATE.אמן", "PINNED_INPUTS/DISCOVERY23_CANDIDATE.אמן"):
            ensure(digest(archive.read(filename)) == CANDIDATE, "candidate SHA: " + filename)
        for filename in ("EVIDENCE/FROZEN_ORACLE.tsv", "PINNED_INPUTS/Stage16AdjacentSelectedVectors.tsv"):
            ensure(digest(archive.read(filename)) == ORACLE, "frozen oracle SHA: " + filename)
        jar_bytes = archive.read("EVIDENCE/native-stage46-candidate.jar")
        ensure(len(jar_bytes) > 10000, "Native JAR too small")
        with zipfile.ZipFile(io.BytesIO(jar_bytes)) as jar:
            jar_entries = jar.infolist()
            jar_count = len(jar_entries)
            jar_names = [entry.filename for entry in jar_entries]
            ensure(10 < jar_count <= MAX_JAR_ENTRIES and
                   len(jar_names) == len(set(jar_names)),
                   "Native JAR member count or duplicate name invalid")
            ensure(sum(entry.file_size for entry in jar_entries) <= MAX_JAR_UNCOMPRESSED and
                   all(entry.file_size <= MAX_JAR_MEMBER_UNCOMPRESSED for entry in jar_entries),
                   "Native JAR uncompressed size limit exceeded")
            ensure(all((entry.external_attr >> 16) & 0o170000 != 0o120000
                       for entry in jar_entries), "Native JAR must not contain symlinks")
            ensure(jar.testzip() is None and
                   any(name.endswith(".class") for name in jar_names), "Native JAR invalid")
        gates = receipt.get("gates", [])
        ensure(len(gates) == len(EXITS) and len({gate["name"] for gate in gates}) == len(gates),
               "gate count/identity")
        ensure(all(type(gate.get("exit_code")) is int for gate in gates),
               "gate exit code must be an integer, not a boolean")
        ensure({gate["name"]: gate["exit_code"] for gate in gates} == EXITS, "gate exits")
        ensure(all(gate["outcome"] == ("EXPECTED_FAILURE" if gate["name"] == "STAGE46_ORACLE_TAMPER" else "PASS")
                   for gate in gates), "gate outcomes")
        # The recovered log has no separately pinned original SHA-256;
        # the known RUNNER_SCRIPT_SHA applies only to the v001 Python source.
        runner_bytes = archive.read("LOGS/runner.log")
        runner = runner_bytes.decode("utf-8", "replace")
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
            # The native Java probes print scalar fields. A value such as
            # MATCHES=480 must not satisfy the expected MATCHES=48.
            ensure(all(re.search(r"(?<![A-Za-z0-9_])" + re.escape(marker) +
                                 r"(?![A-Za-z0-9_])", content) for marker in markers),
                   "semantic marker boundary/value: " + task)
            if task == "STAGE46_CLOSING_GATE_EXPECTED_RED":
                # Original Stage46AdjacentClosingGateDiscoveryProbe.java emits
                # exactly 15 stdout lines (129-143), in this order, once each.
                # Mere membership lets contradicting/doubled numeric counters pass.
                ensure(content.splitlines() == list(markers),
                       "Stage46 Native probe stdout lines/order/count differ from Java source")
        meta = receipt.get("provenance", {})
        ensure(meta.get("signed_baseline_count") == 40 and
               meta.get("run_count") == 21 and
               meta.get("expected_semantic_probes") == len(MARKERS) and
               meta.get("root_manifest_sha256") == MANIFEST and
               meta.get("jar_sha256") == digest(jar_bytes),
               "Native provenance fields differ from recovered artifacts")

        # The original recovery producer emits 26 independently computed
        # validation records: 4 pinned inputs, 40-source count, JAR, runner,
        # and 19 semantic probe logs. Verify the records, not just their presence.
        records = receipt.get("validation_records", [])
        ensure(isinstance(records, list) and len(records) == 7 + len(MARKERS),
               "missing or surplus validation records")
        ensure(provenance.get("validated") == records,
               "RESULT and PROVENANCE validation records disagree")
        ensure(all(isinstance(row, dict) and isinstance(row.get("name"), str)
                   for row in records), "malformed validation record")
        by_name = {row["name"]: row for row in records}
        ensure(len(by_name) == len(records), "duplicate validation record names")
        expected_inputs = {
            "STAGE46_ORIGINAL_MANIFEST": "PINNED_INPUTS/PACKAGE_MANIFEST.json",
            "PINNED_DISCOVERY23_CANDIDATE": "PINNED_INPUTS/DISCOVERY23_CANDIDATE.אמן",
            "COMPILED_CANDIDATE_SOURCE": "EVIDENCE/DISCOVERY23_CANDIDATE.אמן",
            "FROZEN_ORACLE": "PINNED_INPUTS/Stage16AdjacentSelectedVectors.tsv",
            "NATIVE_JAR": "EVIDENCE/native-stage46-candidate.jar",
            "ORIGINAL_NATIVE_RUNNER_LOG": "LOGS/runner.log",
        }
        for task in MARKERS:
            suffix = "stderr" if task == "STAGE46_ORACLE_TAMPER" else "stdout"
            expected_inputs["PROBE_LOG_" + task] = f"LOGS/{task}.{suffix}.log"
        ensure(set(by_name) == set(expected_inputs) | {"SIGNED_SOURCES_40_PLUS_ISOLATED_OLD"},
               "unexpected validation record identity")
        ensure(by_name["SIGNED_SOURCES_40_PLUS_ISOLATED_OLD"].get("count") == 40 and
               by_name["SIGNED_SOURCES_40_PLUS_ISOLATED_OLD"].get("status") == "PASS",
               "signed baseline record mismatch")
        for label, filename in expected_inputs.items():
            actual = archive.read(filename)
            row = by_name[label]
            ensure(row.get("sha256") == digest(actual) and row.get("bytes") == len(actual),
                   "validation record mismatch: " + label)
        ensure(by_name["NATIVE_JAR"].get("member_count") == jar_count,
               "Native JAR validation record member count mismatch")
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
