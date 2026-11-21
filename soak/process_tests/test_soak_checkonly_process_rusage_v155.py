#!/usr/bin/env python3
"""v155 synthetic receipt/admission tamper tests; never execute native originals."""
from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "runner"))
from native_execution_receipt_v038 import canonical
from soak_checkonly_process_rusage_v155 import (
    SCHEMA, SUMMARY_SCHEMA, MAX_PEAK_RSS_KIB, SINGLE_PROCESS_ONLY,
    decode_canonical_bytes, verify_engine, summarize, no_duplicate_pairs
)
from supervised_original_source_preflight_v042 import SCHEMA as P_SCHEMA

ENGINES = {
    "REF-41": "0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4",
    "REF-24": "03ac0c7f4db3c35487993dd31982faa37dd3948e",
}


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


class TestCheckOnlyResourceReceipt(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="v155-rusage-synth-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.records = {}
        self.process = {}
        for eid in ENGINES:
            d = self.root / eid
            d.mkdir()
            stdout = canonical({
                "status": "SOURCE_AND_TRANSPORT_PREFLIGHT_ONLY",
                "engine": eid, "sha256": "1" * 64 if eid == "REF-41" else
                           ["2" * 64, "3" * 64],
                "converter_calls": 0
            }) + b"\n"
            (d / "os-stdout.log").write_bytes(stdout)
            (d / "os-stderr.log").write_bytes(b"")
            p = {
                "schema": P_SCHEMA,
                "status": "ORIGINAL_PINNED_SOURCE_CHECK_ONLY_PROCESS_OBSERVED_NO_DATE_CALLS",
                "engine_id": eid,
                "source_commit": ENGINES[eid],
                "exit_code": 0, "pid": 1234 if eid == "REF-41" else 2345,
                "process_creation_id": "987654",
                "runtime_executable_sha256": "b" * 64,
                "transport_adapter_sha256": "a" * 64,
                "stdout_sha256": sha(stdout), "stderr_sha256": sha(b""),
                "os_stdout_is_native_raw_date_data": False,
                "actual_native_date_execution_proven": False,
                "converter_calls": 0,
                "full_original_soak_years_approved": 0,
                "launch_argv": ["/usr/bin/python3" if eid == "REF-41" else "/usr/bin/node",
                                "adapter-file", "--sources-root", "/fixed/original",
                                "--check-only"],
            }
            self.process[eid] = p
            rr = {
                "elapsed_supervisor_plus_child_wall_ns": 5_000_000,
                "waited_child_user_cpu_seconds": 0.001,
                "waited_child_system_cpu_seconds": 0.001,
                "waited_child_peak_rss_kib_linux": 12000,
                "waited_child_minor_faults": 250,
                "waited_child_major_faults": 0,
                "rusage_origin":
                    "resource.getrusage(RUSAGE_CHILDREN) in fresh one-child supervisor",
                "rss_unit": "Linux ru_maxrss kilobytes, not address-space bytes",
                "includes_child_source_import_initialization": True,
                "isolates_module_import_cost_from_interpreter_startup": False,
            }
            self.records[eid] = {
                "schema": SCHEMA,
                "status": "MEASURED_REAL_CHECKONLY_PROCESS_NOT_NATIVE_DATE_EXECUTION",
                "engine_id": eid, "source_commit": ENGINES[eid],
                "source_process_evidence_sha256": sha(canonical(p)),
                "source_process_pid": p["pid"],
                "source_process_creation_id": p["process_creation_id"],
                "runtime_executable_sha256": p["runtime_executable_sha256"],
                "transport_adapter_sha256": p["transport_adapter_sha256"],
                "native_output_stdout_sha256": p["stdout_sha256"],
                "linux_resource_measurements": rr,
                "resource_bounds": {
                    "peak_rss_kib_max": MAX_PEAK_RSS_KIB,
                    "child_cpu_seconds_max_exclusive": 12.0,
                    "supervisor_plus_child_wall_seconds_max": 30.0,
                },
                "rusage_identity_scope": SINGLE_PROCESS_ONLY,
                "v042_process_exit_code": 0,
                "observed_source_import_checkonly": True,
                "observed_native_date_Fct_calls": 0,
                "source_import_side_effects_exhaustively_proven": False,
                "runtime_cost_without_interpreter_startup_proven": False,
                "independent_source_algorithms_certified": 0,
                "original_full_years_certified": 0,
                "halt_new_native_soak_dispatch": True,
                "main_changes_permitted": False,
            }
            self.write(eid)

    def write(self, eid):
        d = self.root / eid
        (d / "process-evidence.json").write_bytes(canonical(self.process[eid]))
        (self.root / (eid + "-rusage-v155.json")).write_bytes(
            canonical(self.records[eid])
        )

    def blocked(self, eid="REF-41"):
        with self.assertRaises((ValueError, KeyError, TypeError, OSError)):
            verify_engine(self.root, eid)

    def test_01_read_two_valid_synthetic_records(self):
        summary = summarize(self.root)
        self.assertEqual(summary["schema"], SUMMARY_SCHEMA)
        self.assertEqual(summary["original_source_import_processes_observed"], 2)
        self.assertEqual(summary["original_native_date_Fct_calls"], 0)
        self.assertEqual(summary["measured_peak_rss_kib_max"], 12000)

    def test_02_canonical_json_roundtrip(self):
        self.assertEqual(decode_canonical_bytes(canonical(self.records["REF-41"])),
                         self.records["REF-41"])

    def test_03_duplicate_source_keys_rejected(self):
        with self.assertRaisesRegex(ValueError, "duplicate"):
            no_duplicate_pairs([("x", 1), ("x", 2)])

    def test_04_canonical_whitespace_rejected(self):
        with self.assertRaisesRegex(ValueError, "canonical"):
            decode_canonical_bytes(b'{ "engine": "REF-41" }')

    def test_05_original_native_date_call_claim_rejected(self):
        self.records["REF-41"]["observed_native_date_Fct_calls"] = 1
        self.write("REF-41")
        self.blocked()

    def test_06_nonzero_original_year_promotion_rejected(self):
        self.records["REF-41"]["original_full_years_certified"] = 1
        self.write("REF-41")
        self.blocked()

    def test_07_bogus_independent_algo_claim_rejected(self):
        self.records["REF-41"]["independent_source_algorithms_certified"] = 1
        self.write("REF-41")
        self.blocked()

    def test_08_wrong_process_sha_rejected(self):
        self.records["REF-41"]["source_process_evidence_sha256"] = "f"*64
        self.write("REF-41")
        self.blocked()

    def test_09_changed_original_process_receipt_rejected(self):
        self.process["REF-41"]["pid"] = 10000
        self.write("REF-41")
        self.blocked()

    def test_10_process_original_fct_call_claim_rejected(self):
        self.process["REF-41"]["converter_calls"] = 1
        self.records["REF-41"]["source_process_evidence_sha256"] = sha(
            canonical(self.process["REF-41"]))
        self.write("REF-41")
        self.blocked()

    def test_11_process_source_commit_mismatch_rejected(self):
        self.process["REF-41"]["source_commit"] = "f"*40
        self.records["REF-41"]["source_process_evidence_sha256"] = sha(
            canonical(self.process["REF-41"]))
        self.write("REF-41")
        self.blocked()

    def test_12_process_source_pid_mismatch_rejected(self):
        self.records["REF-41"]["source_process_pid"] = 20000
        self.write("REF-41")
        self.blocked()

    def test_13_process_creation_id_mismatch_rejected(self):
        self.records["REF-41"]["source_process_creation_id"] = "12345"
        self.write("REF-41")
        self.blocked()

    def test_14_missing_checkonly_flag_rejected(self):
        self.process["REF-41"]["launch_argv"][-1] = "--unsafe"
        self.records["REF-41"]["source_process_evidence_sha256"] = sha(
            canonical(self.process["REF-41"]))
        self.write("REF-41")
        self.blocked()

    def test_15_native_date_argument_rejected(self):
        self.process["REF-41"]["launch_argv"].insert(-1, "--calculation-day")
        self.records["REF-41"]["source_process_evidence_sha256"] = sha(
            canonical(self.process["REF-41"]))
        self.write("REF-41")
        self.blocked()

    def test_16_modified_stdout_is_rejected(self):
        (self.root / "REF-41" / "os-stdout.log").write_bytes(b"forged\n")
        self.blocked()

    def test_17_modified_stderr_is_rejected(self):
        (self.root / "REF-41" / "os-stderr.log").write_bytes(b"unexpected stderr")
        self.blocked()

    def test_18_peak_rss_over_admission_rejected(self):
        self.records["REF-41"]["linux_resource_measurements"][
            "waited_child_peak_rss_kib_linux"] = MAX_PEAK_RSS_KIB + 1
        self.write("REF-41")
        self.blocked()

    def test_19_zero_peak_rss_rejected(self):
        self.records["REF-41"]["linux_resource_measurements"][
            "waited_child_peak_rss_kib_linux"] = 0
        self.write("REF-41")
        self.blocked()

    def test_20_cpu_over_limit_rejected(self):
        self.records["REF-41"]["linux_resource_measurements"][
            "waited_child_user_cpu_seconds"] = 12.001
        self.write("REF-41")
        self.blocked()

    def test_21_wall_over_limit_rejected(self):
        self.records["REF-41"]["linux_resource_measurements"][
            "elapsed_supervisor_plus_child_wall_ns"] = 31_000_000_000
        self.write("REF-41")
        self.blocked()

    def test_22_invalid_minor_faults_rejected(self):
        self.records["REF-41"]["linux_resource_measurements"][
            "waited_child_minor_faults"] = -1
        self.write("REF-41")
        self.blocked()

    def test_23_claimed_isolated_import_cost_rejected(self):
        self.records["REF-41"]["linux_resource_measurements"][
            "isolates_module_import_cost_from_interpreter_startup"] = True
        self.write("REF-41")
        self.blocked()

    def test_24_claimed_full_import_side_effect_proof_rejected(self):
        self.records["REF-41"]["source_import_side_effects_exhaustively_proven"] = True
        self.write("REF-41")
        self.blocked()

    def test_25_stop_flag_false_rejected(self):
        self.records["REF-41"]["halt_new_native_soak_dispatch"] = False
        self.write("REF-41")
        self.blocked()

    def test_26_no_main_change_allowed(self):
        self.records["REF-41"]["main_changes_permitted"] = True
        self.write("REF-41")
        self.blocked()

    def test_27_unknown_engine_blocked(self):
        self.blocked("UNPINNED")

    def test_28_process_exit_nonzero_rejected(self):
        self.process["REF-41"]["exit_code"] = 17
        self.records["REF-41"]["source_process_evidence_sha256"] = sha(
            canonical(self.process["REF-41"]))
        self.write("REF-41")
        self.blocked()

    def test_29_unbound_source_process_binary_rejected(self):
        self.records["REF-41"]["runtime_executable_sha256"] = "f"*64
        self.write("REF-41")
        self.blocked()

    def test_30_invalid_floating_faults_rejected(self):
        self.records["REF-41"]["linux_resource_measurements"][
            "waited_child_minor_faults"] = 0.5
        self.write("REF-41")
        self.blocked()


if __name__ == "__main__":
    unittest.main()
