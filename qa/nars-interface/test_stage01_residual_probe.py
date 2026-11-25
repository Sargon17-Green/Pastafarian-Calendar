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
        self.assertEqual(r["probe_count"],11)
        self.assertEqual([p["first_line"] for p in r["probes"]],[256,257,258,259,261,262,263,264,265,266,267])
        self.assertEqual(r["instrumentation_mode"],"statement_focus256_267_after_v25")
        self.assertEqual(r["candidate_bytes"],len(self.data))
        self.assertEqual([p["index"] for p in r["probes"]],list(range(1,r["probe_count"]+1)))
        self.assertEqual(r["source_manifest_sha256"],load_locked_sources(ROOT)["manifest"]["manifest_sha256"])
        self.assertFalse(r["source_statements_preserved"])
        self.assertEqual([p["source_line"] for p in r["qa_only_patches"]],[180,181,234,237])
        for p,value in zip(r["qa_only_patches"],(17,47,7,46)):
            self.assertEqual(p["counterfactual"],p["original"].replace(f"(⊂{value})",f"(⊂,{value})",1))
        self.assertEqual(r["prior_line181_witness_run"],45551684196)
        self.assertEqual(r["prior_v17_run"],45658001179)
        self.assertEqual(r["prior_v17_artifact_sha256"],"ea8b494fac8ea7d4813301df22edd48b60343210afbaa824ec3c5ed5808e7c5e")
        self.assertEqual(r["prior_v18_run"],45671179161)
        self.assertEqual(r["prior_v18_artifact_sha256"],"26fdd18a8a1a2ac32a3f979a966556f98c938edc68c438edd7e6e7593b36ef89")
        self.assertEqual(r["prior_v19_run"],45671767802)
        self.assertEqual(r["prior_v19_artifact_sha256"],"a268f6e439d8023de8261036b814642f11b54ed08556cb565e5fe6c2ce68faf5")
        self.assertEqual(r["prior_v20_run"],45672323607)
        self.assertEqual(r["prior_v20_artifact_sha256"],"aab79c9d52ceab9193338b4fa4e560441c32db13d59ed30cb66cad8fcc22f391")
        self.assertEqual(r["prior_v21_run"],45672648212)
        self.assertEqual(r["prior_v21_artifact_sha256"],"e6d9eeeaf55a90eef168504a8c64c04a34e4e93d33dc2d673ccacd757692daeb")
        self.assertEqual(r["prior_v22_run"],45673022324)
        self.assertEqual(r["prior_v22_artifact_sha256"],"6034e0bfe69400cd483ff7c45f5f8084f64bbe52e5b5316e3ece03c5c6899daf")
        self.assertEqual(r["prior_v23_run"],45676884530)
        self.assertEqual(r["prior_v23_artifact_sha256"],"366ef15ef999b790f1de55824f7d4f80b9525280447e2ec5ccb75423decc5b38")
        self.assertEqual(r["prior_residual_run"],45683881377)
        self.assertEqual(r["prior_residual_artifact_sha256"],"f24573eb3ea4fae5fa449c4dc26f7112aecfd91f5fa1be49565977b0bee3b297")
        self.assertEqual(r["prior_v25_run"],45683881377)
        self.assertEqual(r["prior_v25_artifact_sha256"],"f24573eb3ea4fae5fa449c4dc26f7112aecfd91f5fa1be49565977b0bee3b297")
        self.assertEqual(r["prior_v25_artifact_url"],"https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45683881377/artifacts/15055108970")
        self.assertEqual(r["prior_v25_native_summary"],{
            "fx_last_contiguous":95,"checkpoint_count":23,"statement_count":9,
            "statement_lines":[246,247,248,249,250,252,253,254,255],
            "first_incomplete":None,"suite_ec_first":0,
            "status":"RESIDUAL_SUITE_ERROR_DIAGNOSTIC_ONLY",
            "zip_crc_count":57,"manifest_verified_count":56})
        self.assertEqual(r["prior_v24_1_run"],45678986496)
        self.assertEqual(r["prior_v24_1_artifact_sha256"],"ab4ad4efeee432f57e5784069787882d71ee093afbfd32d849419458c0a57013")
        self.assertEqual(r["prior_v24_1_artifact_url"],"https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45678986496/artifacts/15052963589")
        self.assertEqual(hashlib.sha256(self.data).hexdigest(),r["candidate_sha256"])
        self.assertEqual([p["kind"] for p in r["probes"]],["statement"]*11)
        self.assertEqual(len([p for p in r["probes"] if p["kind"]=="bounded_for_block"]),0)
        w234=r["line234_witness"]
        w237=r["line237_witness"]
        for w,line,shape,msglen in ((w234,234,7,369),(w237,237,46,360)):
            self.assertEqual(w["source_line"],line)
            self.assertTrue(w["applied_to_suite_copy"])
            self.assertEqual(w["evidence_run"],45678986496)
            self.assertEqual(w["evidence_artifact_sha256"],"ab4ad4efeee432f57e5784069787882d71ee093afbfd32d849419458c0a57013")
            self.assertEqual(w["evidence_artifact_url"],"https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45678986496/artifacts/15052963589")
            self.assertEqual(w["rank"],[1])
            self.assertEqual(w["shape"],[shape])
            self.assertEqual(w["original_ec"],0)
            self.assertEqual(w["original_message_length"],msglen)
            self.assertEqual(w["counterfactual_ec"],3)
            self.assertEqual(w["counterfactual_message_length"],0)
            self.assertNotIn("paths",w)

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
