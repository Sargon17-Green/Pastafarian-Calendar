import hashlib,pathlib,unittest
from stage01_statement_probe import build_statement_probe,decode_programs,TARGETS,FINAL
from stage01_ec_probe import build_error_code_probe
from stage01_import_workspace import SOURCE_COMMIT
ROOT=pathlib.Path(__file__).resolve().parents[2]
MARKER=r"D:\a\_temp\apl_german_stmt_probe.txt"
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
class StatementProbeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.result,cls.receipt=build_statement_probe(BASE,ROOT,MARKER)
    def test_source_lock_and_never_stage01(self):
        r=self.receipt
        self.assertEqual(r["source_commit"],SOURCE_COMMIT)
        self.assertEqual((r["function_count"],r["chunk_count"],len(r["tests"])),(95,23,3))
        self.assertEqual(r["stage01"],"NOT_ACCEPTED")
        self.assertFalse(r["final_original_stage01_tests_executed"])
        self.assertFalse(r["original_stage01_acceptance_token_present"])
        self.assertEqual(r["marker_token"],FINAL)
        self.assertTrue(all(len(t["statements"])>5 for t in r["tests"]))
    def test_frozen_95fx_prefix_and_renamed_copies(self):
        original,_=build_error_code_probe(BASE,ROOT,MARKER)
        a=decode_programs(original)[3];b=decode_programs(self.result)[3]
        self.assertEqual(a[:23],b[:23])
        self.assertEqual(len(b),34)
        self.assertEqual(sum(x.count(" Stage01PrefixFix ") for x in b[:23]),95)
        self.assertTrue(all("⎕FX " in b[23+i] for i in range(3)))
        self.assertEqual([x["name"] for x in self.receipt["tests"]],[x[0] for x in TARGETS])
        self.assertNotIn("RunStage01Tests ⋄",b[-1])
        self.assertNotIn("STAGE01_NATIVE_PASS",b[-1])
    def test_statement_receipts_keep_original_hashes(self):
        all_items=[i for t in self.receipt["tests"] for i in t["statements"]]
        self.assertEqual(len({x["start_path"] for x in all_items}),len(all_items))
        for s in all_items:
            self.assertEqual(hashlib.sha256(s["source_text"].encode()).hexdigest(),s["source_sha256"])
            self.assertIn("PHASE=START",s["start_token"])
            self.assertIn("PHASE=END",s["end_token"])
            self.assertNotEqual(s["start_path"],s["end_path"])
    def test_determinism_and_line_endings(self):
        a,r=build_statement_probe(BASE,ROOT,MARKER)
        self.assertEqual(a,self.result);self.assertEqual(r,self.receipt)
        self.assertEqual(hashlib.sha256(a).hexdigest(),r["candidate_sha256"])
        w,_=build_statement_probe(BASE.replace(b"\n",b"\r\n"),ROOT,MARKER)
        self.assertNotIn(b"\n",w.replace(b"\r\n",b""))
if __name__=="__main__":
    unittest.main()
