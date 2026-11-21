import hashlib
import pathlib
import unittest
from stage01_ec_probe import FINAL_TOKEN, build_error_code_probe
from stage01_import_workspace import SOURCE_COMMIT
from stage01_subtest_probe import PROBES, build_diagnostic

ROOT = pathlib.Path(__file__).resolve().parents[2]
MARKER = r"D:\a\_temp\apl_german_ec_probe.txt"
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


def programs(candidate):
    s = candidate.decode("cp1252")
    line = next(x for x in s.splitlines() if x.startswith(":4=V C "))
    outer = line.split("'", 2)[1].replace("{diamond}", "⋄").replace("{quad}", "⎕")
    return ["".join(chr(int(c)) for c in x[len("⎕EC ⎕UCS "):].split())
            for x in outer.split(" ⋄ ")]


class ErrorCodeProbeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.candidate, cls.receipt = build_error_code_probe(BASE, ROOT, MARKER)

    def test_source_lock_and_fail_closed(self):
        r = self.receipt
        self.assertEqual(r["source_commit"], SOURCE_COMMIT)
        self.assertEqual((r["function_count"],r["chunk_count"],r["probe_count"]),(95,23,7))
        self.assertEqual(r["stage01"], "NOT_ACCEPTED")
        self.assertFalse(r["final_original_stage01_tests_executed"])
        self.assertFalse(r["original_stage01_acceptance_token_present"])
        self.assertEqual(r["marker_token"], FINAL_TOKEN)
        self.assertIn("NOT_STAGE01", FINAL_TOKEN)

    def test_original_fx_prefix_identical(self):
        prev, old = build_diagnostic(BASE, ROOT, MARKER)
        a, b = programs(prev), programs(self.candidate)
        self.assertEqual(len(b),31)
        self.assertEqual(a[:23],b[:23])
        self.assertEqual(b[0].count(" Stage01PrefixFix "),5)
        self.assertEqual(sum(p.count(" Stage01PrefixFix ") for p in b[:23]),95)
        self.assertEqual(self.receipt["base_candidate_sha256"],old["candidate_sha256"])

    def test_original_calls_and_status_capture_are_distinct_from_pass(self):
        b=programs(self.candidate)
        for i,name in enumerate(PROBES,1):
            p=b[22+i]
            with self.subTest(name=name):
                self.assertIn("⎕EC ⎕UCS ",p)
                self.assertIn("⍕Stage01EC",p)
                self.assertIn(f"Stage01EC{i:02d}[1]",p)
                self.assertIn("CAPTURED_NOT_PASS",self.receipt["probes"][i-1]["captured_token"])
                self.assertEqual(p.count("⎕NAPPEND"),4 if i >= 5 else 3)
                if i >= 5:
                    self.assertIn("⍕⎕UCS ⊃Stage01EC",p)
                    self.assertTrue(self.receipt["probes"][i-1]["message_code_path"].endswith(f"ec_{i:02d}_message_codes.txt"))
                else:
                    self.assertIsNone(self.receipt["probes"][i-1]["message_code_path"])
                self.assertNotIn("RunStage01Tests",p)
        self.assertNotIn("RunStage01Tests",b[-1])
        self.assertNotIn("STAGE01_NATIVE_PASS",b[-1])

    def test_deterministic_preserves_line_endings(self):
        x, r=build_error_code_probe(BASE, ROOT, MARKER)
        self.assertEqual(x,self.candidate)
        self.assertEqual(r,self.receipt)
        self.assertEqual(hashlib.sha256(x).hexdigest(),r["candidate_sha256"])
        win,_=build_error_code_probe(BASE.replace(b"\n",b"\r\n"),ROOT,MARKER)
        self.assertNotIn(b"\n",win.replace(b"\r\n",b""))


if __name__=="__main__":
    unittest.main()
