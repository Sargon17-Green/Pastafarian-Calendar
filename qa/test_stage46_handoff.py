"""Synthetic tests for the Stage46 HANDOFF verifier; NEVER attest a Native run."""
import hashlib
import io
import json
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest import mock
from qa import verify_stage46_handoff as v

def json_bytes(value):
    return (json.dumps(value, ensure_ascii=False) + "\n").encode("utf-8")

def make_zip(records, existing_sums=None):
    files = dict(records)
    files["SHA256SUMS.txt"] = (existing_sums if existing_sums is not None else
        "".join(v.digest(files[name]) + "  " + name + "\n" for name in sorted(files)).encode("utf-8"))
    stream = io.BytesIO()
    with zipfile.ZipFile(stream, "w", zipfile.ZIP_DEFLATED) as archive:
        for name, data in sorted(files.items()):
            archive.writestr(name, data)
    return stream.getvalue()

def fixture():
    source = b"SYNTHETIC_NOT_NATIVE_SOURCE"
    oracle = b"SYNTHETIC_NOT_NATIVE_ORACLE"
    manifest = b"SYNTHETIC_NOT_NATIVE_MANIFEST"
    classbytes = hashlib.shake_256(b"synthetic-only").digest(20000)
    jar = io.BytesIO()
    with zipfile.ZipFile(jar, "w") as archive:
        for i in range(12):
            archive.writestr(f"Fixture{i:02d}.class", classbytes)
    runner = "\n".join([
        "ENGINE_ENTERED v001 " + v.RUN_ID,
        "PACKAGE_SHA_AND_40_SIGNED_BASELINE_SOURCE_PASS",
        "JDK_VERSION_VERIFIED CODESH_COMPILER_SELECTED",
    ] + [f"CHILD_START {name}\nCHILD_EXIT {name} {v.EXITS[name]}" for name in v.RUN_ORDER]).encode("utf-8")
    receipt = {
        "schema_version":"WINDOWS-EXEC-PACK/2.1", "family_id":v.FAMILY,
        "package_version":"v002", "native_run_id":v.RUN_ID, "stage":46,
        "original_package_version":"v001",
        "run_id":"20261023T000000Z_cafefeed",
        "reason_code":"RECOVERED_NATIVE_CODESH_EXPECTED_RED_48_NEXT_GATE_ERRORS_STAGE45_GREEN",
        "previous_windows_assertion_counter":777277,
        "recovery_cause":"STAGE46_v001 finalizer erroneously opened PINNED_INPUTS/PATCH22_CANDIDATE instead of DISCOVERY23_CANDIDATE",
        "status":"PASS", "work_status":"PASS", "process_exit_code":0,
        "expected_repository_state":"EXPECTED_RED", "last_completed_stage":45,
        "stage46_discovery_committed":False, "credited_new_windows_assertions":0,
        "recovered_without_reexecution":True, "native_processes_reexecuted":0,
        "source":{"branch":"Codesh+𐤉𐤄𐤅𐤃𐤉𐤕", "pinned_branch_head":v.BASE,
                  "candidate_discovery_source_sha256":v.digest(source), "git_writes":False},
        "gates":[{"name":name, "outcome":"EXPECTED_FAILURE" if code else "PASS",
                  "exit_code":code} for name,code in v.EXITS.items()],
        "provenance":{"signed_baseline_count":40, "run_count":21},
    }
    records = {
        "RESULT.json": json_bytes(receipt),
        "MANIFEST.json": json_bytes({"contract":"WINDOWS-EXEC-PACK/2.1",
                                    "family_id":v.FAMILY, "package_version":"v002",
                                    "run_id":"20261023T000000Z_cafefeed",
                                    "recovery":True, "native_run_id":v.RUN_ID,
                                    "work_status":"PASS"}),
        "PROVENANCE/RECOVERY_RECEIPT.json":json_bytes({
            "source_run_id":v.RUN_ID,
            "source_family":v.FAMILY,
            "failure":"native HANDOFF finalizer used wrong PINNED_INPUTS/PATCH22_CANDIDATE filename",
            "repair":"recovered original logs/compiled JAR/manifest/pinned inputs without rerunning",
            "validated":[],
            "candidate_source_sha256":v.digest(source),
            "oracle_sha256":v.digest(oracle)}),
        "PINNED_INPUTS/PACKAGE_MANIFEST.json":manifest,
        "PINNED_INPUTS/DISCOVERY23_CANDIDATE.אמן":source,
        "EVIDENCE/DISCOVERY23_CANDIDATE.אמן":source,
        "PINNED_INPUTS/Stage16AdjacentSelectedVectors.tsv":oracle,
        "EVIDENCE/FROZEN_ORACLE.tsv":oracle,
        "EVIDENCE/native-stage46-candidate.jar":jar.getvalue(),
        "LOGS/runner.log":runner,
        "LOGS/bootstrap.log":b"SYNTHETIC_ORIGINAL_BOOTSTRAP",
        "LOGS/recovery_bootstrap.log":b"SYNTHETIC_RECOVERY_BOOTSTRAP",
        "RESULT.txt":(
            "WORK=PASS\n"
            "REASON=RECOVERED_NATIVE_CODESH_EXPECTED_RED_48_NEXT_GATE_ERRORS_STAGE45_GREEN\n"
            "STAGE46=NOT_COMMITTED\nRECOVERY_ONLY=YES\n"
        ).encode("utf-8"),
        "00_START_HERE_HE.md":(
            "# Stage46 DISCOVERY23 recovery: PASS\n\n"
            "Original native run: " + v.RUN_ID +
            "; reason=RECOVERED_NATIVE_CODESH_EXPECTED_RED_48_NEXT_GATE_ERRORS_STAGE45_GREEN.\n"
        ).encode("utf-8"),
        "01_CONTINUE_PROMPT_HE.md":(
            "Validate Stage46 DISCOVERY23 recovered native HANDOFF v002. "
            "Do not open Stage47 or modify main.\n"
        ).encode("utf-8"),
    }
    for task in v.EXITS:
        for stream in ("stdout", "stderr"):
            use = ("stderr" if task == "STAGE46_ORACLE_TAMPER" else "stdout")
            lines = v.MARKERS.get(task, ()) if stream == use else ()
            records[f"LOGS/{task}.{stream}.log"] = "\n".join(lines).encode("utf-8")
    # Mirror all 26 record identities emitted by the actual v002 recovery producer.
    paths = {
        "STAGE46_ORIGINAL_MANIFEST": "PINNED_INPUTS/PACKAGE_MANIFEST.json",
        "PINNED_DISCOVERY23_CANDIDATE": "PINNED_INPUTS/DISCOVERY23_CANDIDATE.אמן",
        "COMPILED_CANDIDATE_SOURCE": "EVIDENCE/DISCOVERY23_CANDIDATE.אמן",
        "FROZEN_ORACLE": "PINNED_INPUTS/Stage16AdjacentSelectedVectors.tsv",
        "NATIVE_JAR": "EVIDENCE/native-stage46-candidate.jar",
        "ORIGINAL_NATIVE_RUNNER_LOG": "LOGS/runner.log",
    }
    for task in v.MARKERS:
        suffix = "stderr" if task == "STAGE46_ORACLE_TAMPER" else "stdout"
        paths["PROBE_LOG_" + task] = f"LOGS/{task}.{suffix}.log"
    validations = [{"name": name, "sha256": v.digest(records[p]), "bytes": len(records[p])}
                   for name, p in paths.items()]
    validations.insert(4, {"name":"SIGNED_SOURCES_40_PLUS_ISOLATED_OLD", "count":40, "status":"PASS"})
    with zipfile.ZipFile(io.BytesIO(records["EVIDENCE/native-stage46-candidate.jar"])) as compiled:
        next(x for x in validations if x["name"] == "NATIVE_JAR")["member_count"] = len(compiled.infolist())
    receipt["validation_records"] = validations
    receipt["provenance"].update({
        "jar_sha256": v.digest(records["EVIDENCE/native-stage46-candidate.jar"]),
        "expected_semantic_probes": len(v.MARKERS),
        "root_manifest_sha256": v.digest(manifest),
    })
    records["RESULT.json"] = json_bytes(receipt)
    signed = json.loads(records["PROVENANCE/RECOVERY_RECEIPT.json"])
    signed["validated"] = validations
    records["PROVENANCE/RECOVERY_RECEIPT.json"] = json_bytes(signed)
    return records, {"CANDIDATE":v.digest(source),
                     "ORACLE":v.digest(oracle), "MANIFEST":v.digest(manifest),
                     "RUNNER_SHA":v.digest(runner)}

class Stage46ReceiptTests(unittest.TestCase):
    def setUp(self):
        self.records, overrides = fixture()
        self.temp = tempfile.TemporaryDirectory(prefix="stage46-synthetic-")
        self.addCleanup(self.temp.cleanup)
        for name, value in overrides.items():
            patch = mock.patch.object(v, name, value)
            patch.start()
            self.addCleanup(patch.stop)

    def attempt(self, should_accept, use_old_sums=False):
        original = "".join(v.digest(self.records[name]) + "  " + name + "\n"
                           for name in sorted(self.records)).encode("utf-8")
        if use_old_sums:
            original = original.replace(b"0", b"1", 1)
        blob = make_zip(self.records, existing_sums=original if use_old_sums else None)
        path = Path(self.temp.name) / "fixture.zip"
        path.write_bytes(blob)
        if should_accept:
            self.assertEqual(v.verify(path)["status"], "STRUCTURE_PASS_NOT_NATIVE_ATTESTATION")
        else:
            with self.assertRaises((v.InvalidReceipt, ValueError, KeyError,
                                    AssertionError, zipfile.BadZipFile)):
                v.verify(path)

    def test_synthetic_consistency_does_not_attest_native(self):
        self.attempt(True)

    def test_missing_child_stream_rejected(self):
        del self.records["LOGS/STAGE45_PATCH_REGRESSION.stdout.log"]
        self.attempt(False)

    def test_forged_stage_credit_rejected_with_recomputed_sha256sums(self):
        result = json.loads(self.records["RESULT.json"])
        result["stage46_discovery_committed"] = True
        self.records["RESULT.json"] = json_bytes(result)
        self.attempt(False)

    def test_tamper_probe_wrong_exit_rejected(self):
        result = json.loads(self.records["RESULT.json"])
        next(x for x in result["gates"] if x["name"] == "STAGE46_ORACLE_TAMPER")["exit_code"] = 0
        self.records["RESULT.json"] = json_bytes(result)
        self.attempt(False)

    def test_changed_candidate_rejected_with_updated_checksums(self):
        self.records["EVIDENCE/DISCOVERY23_CANDIDATE.אמן"] = b"modified"
        self.attempt(False)

    def rewrite_probe_with_reconciled_receipt(self, task, new_content):
        # Adversarial logs that *also* have internally consistent ZIP hashes
        # and matching validation records must still fail semantic checks.
        suffix = "stderr" if task == "STAGE46_ORACLE_TAMPER" else "stdout"
        name = f"LOGS/{task}.{suffix}.log"
        self.records[name] = new_content
        label = "PROBE_LOG_" + task
        for receipt_path, field in (
            ("RESULT.json", "validation_records"),
            ("PROVENANCE/RECOVERY_RECEIPT.json", "validated"),
        ):
            document = json.loads(self.records[receipt_path])
            record = next(x for x in document[field] if x["name"] == label)
            record["sha256"] = v.digest(new_content)
            record["bytes"] = len(new_content)
            self.records[receipt_path] = json_bytes(document)

    def test_semantic_marker_removed_rejected(self):
        self.rewrite_probe_with_reconciled_receipt(
            "STAGE46_CLOSING_GATE_EXPECTED_RED", b"FORGED_SUCCESS")
        self.attempt(False)

    def test_semantic_counter_suffix_overflow_rejected(self):
        task = "STAGE46_CLOSING_GATE_EXPECTED_RED"
        name = f"LOGS/{task}.stdout.log"
        data = self.records[name]
        self.assertIn(b"FROZEN_SELECTED_YEAR_MATCHES=48", data)
        self.rewrite_probe_with_reconciled_receipt(
            task, data.replace(b"FROZEN_SELECTED_YEAR_MATCHES=48",
                               b"FROZEN_SELECTED_YEAR_MATCHES=480"))
        self.attempt(False)

    def test_semantic_field_prefix_spoof_rejected(self):
        task = "STAGE46_CLOSING_GATE_EXPECTED_RED"
        name = f"LOGS/{task}.stdout.log"
        data = self.records[name]
        self.assertIn(b"CANONICAL_CLOSE_GATE_MATCHES=48", data)
        self.rewrite_probe_with_reconciled_receipt(
            task, data.replace(b"CANONICAL_CLOSE_GATE_MATCHES=48",
                               b"FAKE_CANONICAL_CLOSE_GATE_MATCHES=48"))
        self.attempt(False)

    def test_negative_oracle_index_suffix_spoof_rejected(self):
        task = "STAGE46_ORACLE_TAMPER"
        name = f"LOGS/{task}.stderr.log"
        data = self.records[name]
        self.assertIn(b"FROZEN_SELECTED_CLOSE_GATE_ORACLE_FAIL idx=0", data)
        self.rewrite_probe_with_reconciled_receipt(
            task, data.replace(b"ORACLE_FAIL idx=0", b"ORACLE_FAIL idx=01"))
        self.attempt(False)

    def test_stage46_contradictory_numeric_line_rejected(self):
        task = "STAGE46_CLOSING_GATE_EXPECTED_RED"
        name = f"LOGS/{task}.stdout.log"
        data = self.records[name]
        self.rewrite_probe_with_reconciled_receipt(
            task, data + b"\nCANONICAL_CLOSE_GATE_MATCHES=0")
        self.attempt(False)

    def test_stage46_duplicate_success_line_rejected(self):
        task = "STAGE46_CLOSING_GATE_EXPECTED_RED"
        name = f"LOGS/{task}.stdout.log"
        data = self.records[name]
        self.rewrite_probe_with_reconciled_receipt(
            task, data + b"\nCODESH_STAGE46_DISCOVERY23_EXPECTED_RED_CONFIRMED")
        self.attempt(False)

    def test_stage46_result_line_reordering_rejected(self):
        task = "STAGE46_CLOSING_GATE_EXPECTED_RED"
        name = f"LOGS/{task}.stdout.log"
        lines = self.records[name].decode("utf-8").splitlines()
        lines[1], lines[2] = lines[2], lines[1]
        self.rewrite_probe_with_reconciled_receipt(
            task, "\n".join(lines).encode("utf-8"))
        self.attempt(False)

    def test_zip_traversal_rejected(self):
        self.records["../outside.txt"] = b"invalid"
        self.attempt(False)

    def test_runner_extra_exit_rejected(self):
        self.records["LOGS/runner.log"] += b"\nCHILD_EXIT FORGED 0"
        with mock.patch.object(v, "RUNNER_SHA", v.digest(self.records["LOGS/runner.log"])):
            self.attempt(False)

    def test_rewritten_runner_with_same_events_rejected(self):
        # Recomputed ZIP checksums cannot authenticate the original runner log.
        self.records["LOGS/runner.log"] += b"\nFORGED_EXTRA_RUN_METADATA"
        self.attempt(False)

    def test_runner_reordered_children_rejected(self):
        lines = self.records["LOGS/runner.log"].decode("utf-8").splitlines()
        # Swap the first two complete children: counts and exit codes stay valid.
        lines[3:7] = lines[5:7] + lines[3:5]
        self.records["LOGS/runner.log"] = "\n".join(lines).encode("utf-8")
        # Repin synthetic runner to ensure chronology check is reached.
        with mock.patch.object(v, "RUNNER_SHA", v.digest(self.records["LOGS/runner.log"])):
            self.attempt(False)

    def test_runner_overlapping_children_rejected(self):
        lines = self.records["LOGS/runner.log"].decode("utf-8").splitlines()
        # Next child starts before the preceding child has exited.
        lines[4], lines[5] = lines[5], lines[4]
        self.records["LOGS/runner.log"] = "\n".join(lines).encode("utf-8")
        # Repin synthetic runner to ensure chronology check is reached.
        with mock.patch.object(v, "RUNNER_SHA", v.digest(self.records["LOGS/runner.log"])):
            self.attempt(False)

    def test_changed_jar_provenance_rejected(self):
        receipt = json.loads(self.records["RESULT.json"])
        receipt["provenance"]["jar_sha256"] = "0" * 64
        self.records["RESULT.json"] = json_bytes(receipt)
        self.attempt(False)

    def test_changed_probe_validation_sha_rejected(self):
        receipt = json.loads(self.records["RESULT.json"])
        item = next(x for x in receipt["validation_records"]
                    if x["name"] == "PROBE_LOG_STAGE45_PATCH_REGRESSION")
        item["sha256"] = "0" * 64
        self.records["RESULT.json"] = json_bytes(receipt)
        self.attempt(False)

    def test_missing_validation_record_rejected(self):
        receipt = json.loads(self.records["RESULT.json"])
        receipt["validation_records"].pop()
        self.records["RESULT.json"] = json_bytes(receipt)
        self.attempt(False)

    def test_jar_too_few_members_rejected(self):
        small = io.BytesIO()
        with zipfile.ZipFile(small, "w") as archive:
            archive.writestr("Only.class", b"synthetic" * 2500)
        self.records["EVIDENCE/native-stage46-candidate.jar"] = small.getvalue()
        self.attempt(False)

    def test_recovery_run_id_mismatch_rejected(self):
        metadata = json.loads(self.records["MANIFEST.json"])
        metadata["run_id"] = "20261023T000001Z_cafefeed"
        self.records["MANIFEST.json"] = json_bytes(metadata)
        self.attempt(False)

    def test_provenance_validation_copy_mismatch_rejected(self):
        metadata = json.loads(self.records["PROVENANCE/RECOVERY_RECEIPT.json"])
        metadata["validated"][0]["sha256"] = "0" * 64
        self.records["PROVENANCE/RECOVERY_RECEIPT.json"] = json_bytes(metadata)
        self.attempt(False)

    def test_missing_provenance_validation_copy_rejected(self):
        metadata = json.loads(self.records["PROVENANCE/RECOVERY_RECEIPT.json"])
        del metadata["validated"]
        self.records["PROVENANCE/RECOVERY_RECEIPT.json"] = json_bytes(metadata)
        self.attempt(False)

    def test_wrong_native_recovery_reason_rejected(self):
        receipt = json.loads(self.records["RESULT.json"])
        receipt["reason_code"] = "SYNTHETIC_REPLACEMENT"
        self.records["RESULT.json"] = json_bytes(receipt)
        self.attempt(False)

    def test_wrong_original_package_version_rejected(self):
        receipt = json.loads(self.records["RESULT.json"])
        receipt["original_package_version"] = "v003"
        self.records["RESULT.json"] = json_bytes(receipt)
        self.attempt(False)

    def test_original_bootstrap_missing_rejected(self):
        del self.records["LOGS/bootstrap.log"]
        self.attempt(False)

    def test_recovery_bootstrap_missing_rejected(self):
        del self.records["LOGS/recovery_bootstrap.log"]
        self.attempt(False)

    def test_contradictory_plain_result_rejected(self):
        self.records["RESULT.txt"] = self.records["RESULT.txt"].replace(b"WORK=PASS", b"WORK=BLOCKED")
        self.attempt(False)

    def test_plain_result_reason_conflict_rejected(self):
        self.records["RESULT.txt"] = self.records["RESULT.txt"].replace(
            b"REASON=RECOVERED_NATIVE_CODESH", b"REASON=SYNTHETIC_CODESH")
        self.attempt(False)

    def test_handoff_guide_run_id_conflict_rejected(self):
        self.records["00_START_HERE_HE.md"] = self.records["00_START_HERE_HE.md"].replace(
            v.RUN_ID.encode("ascii"), b"20261021T000000Z_deadbeef")
        self.attempt(False)

    def test_continuation_guide_missing_rejected(self):
        del self.records["01_CONTINUE_PROMPT_HE.md"]
        self.attempt(False)

    def test_wrong_branch_identity_rejected(self):
        receipt = json.loads(self.records["RESULT.json"])
        receipt["source"]["branch"] = "Codesh+different"
        self.records["RESULT.json"] = json_bytes(receipt)
        self.attempt(False)

    def test_wrong_recovery_cause_rejected(self):
        receipt = json.loads(self.records["RESULT.json"])
        receipt["recovery_cause"] = "Invented successful run"
        self.records["RESULT.json"] = json_bytes(receipt)
        self.attempt(False)

    def test_duplicate_json_status_rejected_even_if_last_wins(self):
        text = self.records["RESULT.json"].decode("utf-8")
        self.assertIn('"status": "PASS"', text)
        self.records["RESULT.json"] = text.replace(
            '"status": "PASS"', '"status": "BLOCKED", "status": "PASS"', 1).encode("utf-8")
        self.attempt(False)

    def test_nested_duplicate_json_source_key_rejected(self):
        text = self.records["RESULT.json"].decode("utf-8")
        needle = '"pinned_branch_head": "' + v.BASE + '"'
        self.assertIn(needle, text)
        self.records["RESULT.json"] = text.replace(
            needle, '"pinned_branch_head": "forged", ' + needle, 1).encode("utf-8")
        self.attempt(False)

    def test_duplicate_manifest_run_id_rejected(self):
        text = self.records["MANIFEST.json"].decode("utf-8")
        needle = '"run_id": "20261023T000000Z_cafefeed"'
        self.assertIn(needle, text)
        self.records["MANIFEST.json"] = text.replace(
            needle, '"run_id": "forged", ' + needle, 1).encode("utf-8")
        self.attempt(False)

    def test_duplicate_provenance_source_run_rejected(self):
        text = self.records["PROVENANCE/RECOVERY_RECEIPT.json"].decode("utf-8")
        needle = '"source_run_id": "' + v.RUN_ID + '"'
        self.assertIn(needle, text)
        self.records["PROVENANCE/RECOVERY_RECEIPT.json"] = text.replace(
            needle, '"source_run_id": "forged", ' + needle, 1).encode("utf-8")
        self.attempt(False)

    def test_nonfinite_json_number_rejected(self):
        text = self.records["RESULT.json"].decode("utf-8")
        self.records["RESULT.json"] = text.replace(
            '"family_id": ', '"nonfinite": NaN, "family_id": ', 1).encode("utf-8")
        self.attempt(False)

    def test_boolean_exit_code_cannot_impersonate_zero(self):
        result = json.loads(self.records["RESULT.json"])
        result["gates"][0]["exit_code"] = False
        self.records["RESULT.json"] = json_bytes(result)
        self.attempt(False)

    def test_boolean_process_exit_cannot_impersonate_zero(self):
        result = json.loads(self.records["RESULT.json"])
        result["process_exit_code"] = False
        self.records["RESULT.json"] = json_bytes(result)
        self.attempt(False)

    def test_boolean_native_reexecution_cannot_impersonate_zero(self):
        result = json.loads(self.records["RESULT.json"])
        result["native_processes_reexecuted"] = False
        self.records["RESULT.json"] = json_bytes(result)
        self.attempt(False)

    def test_checksum_mismatch_rejected(self):
        self.attempt(False, use_old_sums=True)

if __name__ == "__main__":
    unittest.main()
