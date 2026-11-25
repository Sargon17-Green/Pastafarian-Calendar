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
        self.assertEqual(r["probe_count"],8)
        self.assertEqual([p["first_line"] for p in r["probes"]],[218,219,221,222,223,225,226,227])
        self.assertEqual(r["instrumentation_mode"],"statements218_219_221_223_225_227_after_v20_208_217")
        self.assertEqual(r["candidate_bytes"],len(self.data))
        self.assertEqual([p["index"] for p in r["probes"]],list(range(1,r["probe_count"]+1)))
        self.assertEqual(r["source_manifest_sha256"],load_locked_sources(ROOT)["manifest"]["manifest_sha256"])
        self.assertFalse(r["source_statements_preserved"])
        self.assertEqual([p["source_line"] for p in r["qa_only_patches"]],[180,181])
        for p,value in zip(r["qa_only_patches"],(17,47)):
            self.assertEqual(p["counterfactual"],p["original"].replace(f"(⊂{value})",f"(⊂,{value})",1))
        self.assertEqual(r["prior_line181_witness_run"],45551684196)
        self.assertEqual(r["prior_v17_run"],45658001179)
        self.assertEqual(r["prior_v17_artifact_sha256"],"ea8b494fac8ea7d4813301df22edd48b60343210afbaa824ec3c5ed5808e7c5e")
        self.assertEqual(r["prior_v18_run"],45671179161)
        self.assertEqual(r["prior_v18_artifact_sha256"],"26fdd18a8a1a2ac32a3f979a966556f98c938edc68c438edd7e6e7593b36ef89")
        self.assertEqual(r["prior_v19_run"],45671767802)
        self.assertEqual(r["prior_v19_artifact_sha256"],"a268f6e439d8023de8261036b814642f11b54ed08556cb565e5fe6c2ce68faf5")
        self.assertEqual(r["prior_residual_run"],45672323607)
        self.assertEqual(r["prior_residual_artifact_sha256"],"aab79c9d52ceab9193338b4fa4e560441c32db13d59ed30cb66cad8fcc22f391")
        self.assertEqual(hashlib.sha256(self.data).hexdigest(),r["candidate_sha256"])
        self.assertEqual([p["kind"] for p in r["probes"]],["statement"]*8)
        self.assertEqual(len([p for p in r["probes"] if p["kind"]=="bounded_for_block"]),0)

    def test_line181_exact_counterfactual(self):
        _,w=probe.line181_witness(ROOT,MARKER)
        self.assertEqual(w["source_line"],181)
        self.assertTrue(w["original"].startswith("AssertEqual (⊂47) (⊂⍴MONTH_NAMES) "))
        self.assertEqual(w["counterfactual"],w["original"].replace("(⊂47)","(⊂,47)",1))
        self.assertEqual(len(set(w["paths"].values())),7)
        self.assertIn("⍴⍴⍴MONTH_NAMES",w["metrics_expression"])
        self.assertIn("≢MONTH_NAMES",w["metrics_expression"])
        self.assertIn("NOT_PASS",w["captured_token"])

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
            self.assertIn(p["kind"],("statement",))
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
