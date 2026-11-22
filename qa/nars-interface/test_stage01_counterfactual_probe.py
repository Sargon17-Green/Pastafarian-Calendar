"""Fail-closed deterministic checks for the QA-only six-witness candidate."""
import copy
import hashlib
import pathlib
import unittest
from unittest.mock import patch

import stage01_counterfactual_probe as candidate
from stage01_import_workspace import SOURCE_COMMIT, load_locked_sources

ROOT = pathlib.Path(__file__).resolve().parents[2]
BASE = """[General]
Version=1
[Globals]
:0=V C 0 1 0 ''
:3=V C 0 1 0 ''
[Vars.0]
5={quad}lx=:3
[Fcns.0]
0=foo=:3
""".encode("cp1252")
MARKER = r"D:\a\_temp\apl_german_counterfactual.txt"

class CounterfactualTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data, cls.receipt = candidate.build_counterfactual(BASE, ROOT, MARKER)

    def test_source_lock_and_only_six_witnesses(self):
        r=self.receipt
        self.assertEqual(r["source_commit"],SOURCE_COMMIT)
        self.assertEqual(r["function_count"],95)
        self.assertEqual(r["chunk_count"],23)
        self.assertEqual(len(r["chunk_records"]),23)
        self.assertEqual(len(r["import_program_sha256"]),23)
        self.assertEqual(r["program_count"],32)
        self.assertEqual(r["stage01"],"NOT_ACCEPTED")
        self.assertFalse(r["original_stage01_acceptance_token_present"])
        self.assertFalse(r["final_original_stage01_tests_executed"])
        self.assertEqual(r["marker_token"],candidate.FINAL)
        self.assertEqual(r["candidate_sha256"],hashlib.sha256(self.data).hexdigest())
        self.assertEqual([v["name"] for v in r["probes"]],
                         [p[0] for p in candidate.WITNESSES])
        self.assertEqual([v["expected_values"] for v in r["probes"]],
                         [p[2] for p in candidate.WITNESSES])
        self.assertEqual([a["line"] for a in r["source_anchors"]],[39,225,226])
        for a in r["source_anchors"]:
            self.assertEqual(a["sha256"],hashlib.sha256(a["text"].encode()).hexdigest())
        for w in r["probes"]:
            self.assertTrue(w["start_token"].endswith("START"))
            self.assertTrue(w["captured_token"].endswith("CAPTURED_NOT_PASS"))
            self.assertNotEqual(w["start_path"],w["captured_path"])
            self.assertEqual(len(w["sha256"]),64)

    def test_determinism_and_line_endings(self):
        data2, r2=candidate.build_counterfactual(BASE, ROOT, MARKER)
        self.assertEqual((data2,r2),(self.data,self.receipt))
        data3,_=candidate.build_counterfactual(BASE.replace(b"\n",b"\r\n"),ROOT,MARKER)
        self.assertNotIn(b"\n",data3.replace(b"\r\n",b""))

    def test_source_anchor_mutation_rejected(self):
        locked=load_locked_sources(ROOT)
        changed=copy.deepcopy(locked)
        b=next(x for x in changed["blocks"] if x["name"]=="PostStirSavedSum")
        b["lines"][1]=b["lines"][1].replace("⊃args[1]","⊃⊃args[1]")
        with patch.object(candidate,"load_locked_sources",return_value=changed):
            with self.assertRaisesRegex(ValueError,"ANCHOR_LINE_CHANGED"):
                candidate.build_counterfactual(BASE,ROOT,MARKER)

    def test_non_acceptance_and_bounded_receipt_paths(self):
        r=self.receipt
        self.assertEqual(r["status"],"GENERATED_NOT_NATIVE_VALIDATED")
        self.assertEqual(len({w["value_path"] for w in r["probes"]}),6)
        self.assertEqual(len({w["code_path"] for w in r["probes"]}),6)
        self.assertEqual(r["probes"][2]["expected_values"],[150,151,152,153,154,155])
        self.assertEqual(r["probes"][3]["expected_values"],[170])
        self.assertEqual(r["probes"][4]["expected_values"],[1])
        self.assertEqual(r["probes"][5]["expected_values"],[0])

if __name__=="__main__":
    unittest.main()
