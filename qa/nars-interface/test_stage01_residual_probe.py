"""Fail-closed tests for the QA-only residual Stage1 statement instrumentor."""
import copy
import hashlib
import pathlib
import unittest
from unittest.mock import patch

import stage01_residual_probe as probe
from stage01_import_workspace import SOURCE_COMMIT, load_locked_sources

ROOT=pathlib.Path(__file__).resolve().parents[2]
BASE=b"""[General]
Version=1
[Globals]
:0=V C 0 1 0 ''
:3=V C 0 1 0 ''
[Vars.0]
5={quad}lx=:3
[Fcns.0]
0=foo=:3
"""
MARKER=r"D:\a\_temp\apl_german_residual_v1.txt"

class ResidualTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data, cls.receipt=probe.build_residual(BASE,ROOT,MARKER)

    def test_locked_prerequisites_and_source(self):
        r=self.receipt
        self.assertEqual(r["source_commit"],SOURCE_COMMIT)
        self.assertEqual((r["function_count"],r["chunk_count"],r["program_count"]),(95,23,28))
        self.assertEqual(len(r["locked_prerequisite_program_sha256"]),25)
        self.assertEqual(r["probe_count"],len(r["probes"]))
        self.assertGreater(r["probe_count"],90)
        self.assertEqual([p["index"] for p in r["probes"]],list(range(1,r["probe_count"]+1)))
        self.assertEqual(r["source_manifest_sha256"],load_locked_sources(ROOT)["manifest"]["manifest_sha256"])
        self.assertTrue(r["source_statements_preserved"])
        self.assertEqual(hashlib.sha256(self.data).hexdigest(),r["candidate_sha256"])
        self.assertEqual(len([p for p in r["probes"] if p["kind"]=="bounded_for_block"]),2)

    def test_no_acceptance_possible(self):
        r=self.receipt
        self.assertEqual(r["stage01"],"NOT_ACCEPTED")
        self.assertFalse(r["production_source_modified"])
        self.assertFalse(r["original_entrypoint_invoked"])
        self.assertFalse(r["original_unmodified_suite_proven"])
        self.assertFalse(r["original_stage01_acceptance_token_present"])
        self.assertTrue(r["paired_qa_overrides"])
        self.assertNotIn("STAGE01_NATIVE_PASS",r["marker_token"])
        self.assertIn("DIAGNOSTIC",r["marker_token"])
        self.assertIn("NOT_STAGE01",r["marker_token"])

    def test_statement_receipt_anchors_and_paths(self):
        r=self.receipt
        starts=set()
        for p in r["probes"]:
            self.assertIn(p["kind"],("statement","bounded_for_block"))
            self.assertGreaterEqual(p["last_line"],p["first_line"])
            self.assertIn("PHASE=START",p["start_token"])
            self.assertIn("PHASE=END",p["end_token"])
            for field in ("start_path","end_path"):
                self.assertNotIn(p[field],starts)
                starts.add(p[field])
        self.assertEqual(len(starts),2*r["probe_count"])
        self.assertEqual(r["compiled"]["alias"],probe.ALIAS)

    def test_determinism(self):
        d,r=probe.build_residual(BASE,ROOT,MARKER)
        self.assertEqual((d,r),(self.data,self.receipt))
        changed,_=probe.build_residual(BASE.replace(b"\n",b"\r\n"),ROOT,MARKER)
        self.assertNotIn(b"\n",changed.replace(b"\r\n",b""))

    def test_source_mismatch_is_not_silent(self):
        modified=copy.deepcopy(load_locked_sources(ROOT))
        b=next(x for x in modified["blocks"] if x["name"]=="RunStage01Tests")
        b["path"]="wrong/stage01_tests.apl"
        with patch.object(probe,"load_locked_sources",return_value=modified):
            with self.assertRaisesRegex(ValueError,"ORIGINAL_SUITE_SOURCE_NOT_UNIQUE"):
                probe.build_residual(BASE,ROOT,MARKER)

if __name__=="__main__":
    unittest.main()
