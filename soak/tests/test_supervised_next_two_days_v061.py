"""Static/pure admission tests for original NEXT two-date supervisor v061.

No original F(c,t) is launched by tests. Live execution is restricted to
the isolated v061 GitHub Linux Actions workflow and separate CI artifact.
"""
from __future__ import annotations

from pathlib import Path
import os
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
import supervised_next_two_days_v061 as s


class TwoDaySupervisorPreflightTests(unittest.TestCase):
    def test_only_fixed_two_source_dates_and_original_year_candidate(self):
        self.assertEqual(s.C,"-15055671")
        self.assertEqual(s.YEAR,"5000")
        self.assertEqual((s.FIRST,s.LAST),("-15055670","-15055669"))
        self.assertEqual(s.N,2)
        self.assertEqual(s.YEAR_CHUNK_ORDINAL,1016)
        self.assertEqual(int(s.FIRST),-15057702+2*s.YEAR_CHUNK_ORDINAL)
        self.assertEqual(int(s.LAST)-int(s.FIRST)+1,2)
        self.assertEqual(s.BOUNDARY_SHA,
                         "ad64cc51522d7f19cb8a238e2a6a418e75203c6cbfe017c394f623edeb882e78")

    def test_linux_resource_gate_requires_free_ram(self):
        with tempfile.TemporaryDirectory() as temp:
            with patch.object(s,"_ram_available",return_value=s.RAM_FLOOR-1):
                with self.assertRaisesRegex(RuntimeError,"admission blocked"):
                    s._resources(Path(temp),"REF-41")

    def test_linux_resource_gate_requires_free_disk(self):
        with tempfile.TemporaryDirectory() as temp:
            class Disk:
                free=s.DISK_FLOOR-1
            with patch.object(s,"_ram_available",return_value=s.RAM_FLOOR+1), \
                 patch.object(s.shutil,"disk_usage",return_value=Disk()):
                with self.assertRaisesRegex(RuntimeError,"admission blocked"):
                    s._resources(Path(temp),"PROD-KT-CY")

    def test_resource_report_does_not_claim_rss_cap(self):
        with tempfile.TemporaryDirectory() as temp:
            class Disk:
                free=s.DISK_FLOOR+1
            with patch.object(s,"_ram_available",return_value=s.RAM_FLOOR+1), \
                 patch.object(s.shutil,"disk_usage",return_value=Disk()):
                r=s._resources(Path(temp),"REF-41")
                self.assertFalse(r["resident_memory_hard_cap_enforced"])
                self.assertIsNone(r["original_calculation_wall_timeout_seconds"])

    def test_non_ci_environment_never_dispatches(self):
        with tempfile.TemporaryDirectory() as temp:
            with patch.dict(os.environ,{"GITHUB_ACTIONS":"false"},clear=False):
                with self.assertRaisesRegex(RuntimeError,"only allowed in GitHub Actions"):
                    s.run(Path(temp),Path(temp),Path(temp),Path(temp))

    def test_missing_boundary_rejected_before_original_source_launch(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp)
            sources=root/"sources";sources.mkdir()
            kotlin=root/"kotlin";kotlin.mkdir()
            evidence=root/"evidence";evidence.mkdir()
            with patch.object(s,"_admit",return_value=None),\
                 patch.object(s,"_guard_year",return_value="0"*64):
                with self.assertRaisesRegex(ValueError,"boundary SHA changed"):
                    s.run(sources,kotlin,root/"no.jar",evidence)
            self.assertFalse((evidence/"REF-41").exists())
            self.assertFalse((evidence/"PROD-KT-CY").exists())


if __name__=="__main__":
    unittest.main()
