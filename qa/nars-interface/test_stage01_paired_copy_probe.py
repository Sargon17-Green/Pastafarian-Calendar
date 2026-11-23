"""Fail-closed deterministic checks for QA-only paired source-copy regression."""
import copy
import hashlib
import pathlib
import unittest
from unittest.mock import patch
import stage01_paired_copy_probe as target
from stage01_import_workspace import SOURCE_COMMIT, load_locked_sources

ROOT=pathlib.Path(__file__).resolve().parents[2]
BASE="""[General]
Version=1
[Globals]
:0=V C 0 1 0 ''
:3=V C 0 1 0 ''
[Vars.0]
5={quad}lx=:3
[Fcns.0]
0=foo=:3
""".encode("cp1252")
MARKER=r"D:\a\_temp\apl_german_paired_suite_v1.txt"

class PairedCopyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data,cls.receipt=target.build_paired_copy(BASE,ROOT,MARKER)
    def test_locked_95_fx_and_exact_two_copies(self):
        r=self.receipt
        self.assertEqual(r["source_commit"],SOURCE_COMMIT)
        self.assertEqual(r["source_manifest_sha256"],load_locked_sources(ROOT)["manifest"]["manifest_sha256"])
        self.assertEqual((r["function_count"],r["chunk_count"],r["program_count"]),(95,23,27))
        self.assertEqual(len(r["chunk_records"]),23)
        self.assertEqual(len(r["import_program_sha256"]),23)
        self.assertEqual([(x["name"],x["line"]) for x in r["source_anchors"]],
                         [(v[0],v[2]) for v in target.CHANGES])
        self.assertEqual([c["name"] for c in r["copies"]],[v[0] for v in target.CHANGES])
        self.assertEqual(len({c["path"] for c in r["copies"]}),2)
        self.assertEqual(r["candidate_sha256"],hashlib.sha256(self.data).hexdigest())
        for anchor in r["source_anchors"]:
            self.assertEqual(anchor["original_sha256"],hashlib.sha256(anchor["original_text"].encode()).hexdigest())
            self.assertEqual(anchor["replacement_sha256"],hashlib.sha256(anchor["replacement_text"].encode()).hexdigest())
    def test_no_false_stage1_acceptance(self):
        r=self.receipt
        self.assertEqual(r["stage01"],"NOT_ACCEPTED")
        self.assertEqual(r["status"],"GENERATED_NOT_NATIVE_VALIDATED")
        self.assertFalse(r["production_source_modified"])
        self.assertFalse(r["original_unmodified_suite_proven"])
        self.assertFalse(r["original_stage01_acceptance_token_present"])
        self.assertTrue(r["original_entrypoint_invoked_with_qa_overrides"])
        self.assertNotIn("STAGE01_NATIVE_PASS",r["marker_token"])
        self.assertIn("DIAGNOSTIC",r["marker_token"])
        self.assertTrue(r["suite"]["start_token"].endswith("START"))
        self.assertTrue(r["suite"]["captured_token"].endswith("CAPTURED_NOT_PASS"))
    def test_determinism_and_newline_preservation(self):
        data,rec=target.build_paired_copy(BASE,ROOT,MARKER)
        self.assertEqual((data,rec),(self.data,self.receipt))
        crlf,_=target.build_paired_copy(BASE.replace(b"\n",b"\r\n"),ROOT,MARKER)
        self.assertNotIn(b"\n",crlf.replace(b"\r\n",b""))
    def test_source_mutations_fail_closed(self):
        modified=copy.deepcopy(load_locked_sources(ROOT))
        block=next(b for b in modified["blocks"] if b["name"]=="PostStirSavedSum")
        block["lines"][1]=block["lines"][1].replace("⊃args[1]","⊃⊃args[1]")
        with patch.object(target,"load_locked_sources",return_value=modified):
            with self.assertRaisesRegex(ValueError,"SOURCE_COPY_ANCHOR_CHANGED"):
                target.build_paired_copy(BASE,ROOT,MARKER)
    def test_exact_source_changes_only(self):
        amended,anchors,_=target.source_copies(ROOT)
        originals={b["name"]:b for b in load_locked_sources(ROOT)["blocks"]}
        self.assertEqual(len(amended),2)
        for name,definition in amended:
            before=target.fx_definition_lines(originals[name])
            diff=[(i,x,y) for i,(x,y) in enumerate(zip(before,definition)) if x!=y]
            self.assertEqual(len(diff),1)
            self.assertEqual(len(before),len(definition))

if __name__=="__main__":
    unittest.main()
