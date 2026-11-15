"""v041 Linux-CI-only real synthetic subprocess observation integration tests.

All converter calls are ZERO. These tests may ONLY launch a tiny fixture on
ephemeral GitHub Actions Linux hosts, never on a user's Windows machine.
"""
from __future__ import annotations

import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

RUNNER=Path(__file__).resolve().parents[1]/"runner"
sys.path.insert(0,str(RUNNER))
from supervised_process_observation_v041 import (
    STATUS, SCHEMA, WALL_LIMIT_SECONDS, _admit, canonical,
    run_synthetic_ci_once, verify_synthetic_evidence
)


class SyntheticObservedProcessTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base=Path(self.temp.name)

    def run_once(self):
        record=run_synthetic_ci_once(self.base,mode="ok")
        self.work=self.base/"process-observation-ok"
        return record

    def test_real_os_process_launch_observed_but_not_native_certified(self):
        d=self.run_once()
        self.assertEqual(d["schema"],SCHEMA)
        self.assertEqual(d["status"],STATUS)
        self.assertEqual(d["return_code"],0)
        self.assertTrue(d["process_exit_code_observed"])
        self.assertEqual(d["raw_data_rows"],2)
        self.assertIsInstance(d["pid"],int)
        self.assertGreater(d["pid"],0)
        self.assertTrue(d["proc_start_id"])
        self.assertEqual(d["linux_resource_controls"]["nice_target"],19)
        self.assertEqual(d["real_converter_calls"],0)
        self.assertFalse(d["actual_native_execution_certified"])
        self.assertFalse(d["independent_source_lineage_certified"])
        self.assertEqual(d["official_original_soak_years_certified"],0)
        self.assertIn(b"SYNTHETIC_PROGRESS_STDOUT_NOT_RAW_NATIVE_DATE_ROWS",
                      (self.work/"os-stdout.log").read_bytes())
        self.assertIn(b"SYNTHETIC_LOG_STDERR_CAPTURED",
                      (self.work/"os-stderr.log").read_bytes())
        self.assertNotEqual((self.work/"os-stdout.log").read_bytes(),
                            (self.work/"raw-data.jsonl").read_bytes())
        self.assertEqual(verify_synthetic_evidence(self.work)
                         ["original_native_full_years_certified"],0)

    def test_process_observation_source_file_corruption_detected(self):
        self.run_once()
        path=self.work/"child-fixture.py"
        path.write_bytes(path.read_bytes()+b"\n# modified after execution\n")
        with self.assertRaisesRegex(ValueError,"fixture source code|process evidence file altered"):
            verify_synthetic_evidence(self.work)

    def test_tampered_normalized_data_rejected(self):
        self.run_once()
        path=self.work/"normalized-data.jsonl"
        path.write_bytes(path.read_bytes().replace(b'"month_index":7',
                                                     b'"month_index":8',1))
        with self.assertRaisesRegex(ValueError,"process evidence file altered"):
            verify_synthetic_evidence(self.work)

    def test_tampered_os_stdout_rejected_separately_from_raw_data(self):
        self.run_once()
        with (self.work/"os-stdout.log").open("ab") as f:
            f.write(b"foreign-progress-line\n")
        with self.assertRaisesRegex(ValueError,"process evidence file altered"):
            verify_synthetic_evidence(self.work)

    def test_tampered_observation_receipt_rejected(self):
        self.run_once()
        path=self.work/"process-evidence.json"
        d=json.loads(path.read_bytes())
        d["official_original_soak_years_certified"]=1
        path.write_bytes(canonical(d))
        with self.assertRaisesRegex(ValueError,"overcertified"):
            verify_synthetic_evidence(self.work)

    def test_two_invocations_cannot_overwrite_same_work_directory(self):
        self.run_once()
        with self.assertRaises(FileExistsError):
            run_synthetic_ci_once(self.base,mode="ok")
        self.assertEqual(verify_synthetic_evidence(self.work)["linux_ci_only"],True)

    def test_nonzero_child_exit_fails_closed_and_preserves_logs(self):
        with self.assertRaisesRegex(RuntimeError,"NONZERO_CHILD_EXIT"):
            run_synthetic_ci_once(self.base,mode="nonzero")
        work=self.base/"process-observation-nonzero"
        d=json.loads((work/"process-evidence.json").read_bytes())
        self.assertEqual(d["status"],"SYNTHETIC_PROCESS_BLOCKED")
        self.assertEqual(d["return_code"],17)
        self.assertEqual(d["official_original_soak_years_certified"],0)
        self.assertEqual(d["real_converter_calls"],0)
        self.assertIn(b"SYNTHETIC_CHILD_ERROR_PATH",
                      (work/"os-stderr.log").read_bytes())
        with self.assertRaisesRegex(ValueError,"invalid or overcertified"):
            verify_synthetic_evidence(work)

    def test_synthetic_hang_is_bounded_without_affecting_real_slow_converters(self):
        with self.assertRaisesRegex(RuntimeError,"SYNTHETIC_TEST_TIMEOUT_CHILD_TERMINATED"):
            run_synthetic_ci_once(self.base,mode="sleep",wall_seconds=0.6)
        work=self.base/"process-observation-sleep"
        d=json.loads((work/"process-evidence.json").read_bytes())
        self.assertEqual(d["status"],"SYNTHETIC_PROCESS_BLOCKED")
        self.assertIsNotNone(d["return_code"])
        self.assertEqual(d["real_converter_calls"],0)
        self.assertEqual(d["official_original_soak_years_certified"],0)

    def test_running_outside_ephemeral_github_actions_is_refused(self):
        with patch.dict(os.environ,{"GITHUB_ACTIONS":"false"},clear=False):
            with self.assertRaisesRegex(RuntimeError,"only allowed in GitHub Actions"):
                _admit(self.base)
        self.assertFalse((self.base/"process-observation-ok").exists())

    def test_receipt_without_supervisor_go_is_invalid(self):
        self.run_once()
        (self.work/"go.json").unlink()
        with self.assertRaises((ValueError,FileNotFoundError)):
            verify_synthetic_evidence(self.work)

    def test_do_not_overwrite_interpreter_or_other_user_files(self):
        self.run_once()
        d=json.loads((self.work/"process-evidence.json").read_bytes())
        self.assertNotEqual(Path(d["interpreter_executable_path"]),
                            self.work/"child-fixture.py")
        self.assertTrue(Path(d["interpreter_executable_path"]).is_file())


if __name__=="__main__":
    unittest.main()
