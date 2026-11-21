import hashlib
import pathlib
import unittest

from stage01_chunked_import import build_stage01_chunked
from stage01_subtest_probe import PROBES, FINAL_TOKEN, build_diagnostic
from stage01_import_workspace import SOURCE_COMMIT

ROOT = pathlib.Path(__file__).resolve().parents[2]
MARKER = r"D:\a\_temp\apl_stage01_diag_probe.txt"
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


def outer_from_candidate(candidate):
    lines = candidate.decode("cp1252").splitlines()
    line = next(l for l in lines if l.startswith(":4=V C "))
    serialized = line.split("'", 2)[1]
    outer = serialized.replace("{diamond}", "⋄").replace("{quad}", "⎕")
    values = []
    for expression in outer.split(" ⋄ "):
        assert expression.startswith("⎕EC ⎕UCS ")
        values.append("".join(chr(int(x)) for x in expression[len("⎕EC ⎕UCS "):].split()))
    return outer, values


class Stage01SubtestDiagnosticTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.candidate, cls.receipt = build_diagnostic(BASE, ROOT, MARKER)

    def test_exact_locked_source_and_no_stage01_acceptance(self):
        c, r = self.candidate, self.receipt
        self.assertEqual(r["source_commit"], SOURCE_COMMIT)
        self.assertEqual(r["function_count"], 95)
        self.assertEqual(r["chunk_count"], 23)
        self.assertEqual(r["probe_count"], 7)
        self.assertEqual(r["status"], "GENERATED_NOT_NATIVE_VALIDATED")
        self.assertEqual(r["stage01"], "NOT_ACCEPTED")
        self.assertFalse(r["native_executed"])
        self.assertFalse(r["final_original_stage01_tests_executed"])
        self.assertFalse(r["original_stage01_acceptance_token_present"])
        self.assertEqual(r["candidate_sha256"], hashlib.sha256(c).hexdigest())
        self.assertEqual(r["marker_token"], FINAL_TOKEN)
        self.assertIn("NOT_STAGE01", FINAL_TOKEN)

    def test_95_imports_match_proven_original_candidate_byte_for_byte(self):
        c0, r0 = build_stage01_chunked(BASE, ROOT, MARKER)
        _, base_programs = outer_from_candidate(c0)
        _, diag_programs = outer_from_candidate(self.candidate)
        self.assertEqual(len(base_programs), 24)
        self.assertEqual(len(diag_programs), 31)
        self.assertEqual(diag_programs[:23], base_programs[:23])
        self.assertEqual(sum(p.count(" Stage01PrefixFix ") for p in diag_programs), 95)
        self.assertEqual(self.receipt["base_candidate_sha256"], r0["candidate_sha256"])

    def test_7_original_init_and_subtests_have_exact_start_end_markers(self):
        outer, programs = outer_from_candidate(self.candidate)
        self.assertEqual(self.receipt["program_count"], 31)
        self.assertEqual(self.receipt["outer_lx_chars"], len(outer))
        self.assertEqual([r["name"] for r in self.receipt["probes"]], list(PROBES))
        for i, (rec, name, program) in enumerate(zip(self.receipt["probes"], PROBES, programs[23:-1]), 1):
            with self.subTest(probe=name):
                self.assertEqual(rec["index"], i)
                self.assertEqual(program.count("⎕NAPPEND"), 2)
                self.assertEqual(program.count("Stage01ChunkAssert"), 1)
                self.assertIn(" ⋄ "+name+" ⋄ ", program)
                self.assertEqual(program.count("RunStage01Tests"), 0)
                for kind in ("start", "end"):
                    self.assertIn(f"PROBE={i:02d}", rec[kind+"_token"])
                    self.assertIn(f"NAME={name}", rec[kind+"_token"])
                    self.assertIn(f"PHASE={kind.upper()}", rec[kind+"_token"])
                    self.assertEqual(rec[kind+"_sha256"],
                                     hashlib.sha256(rec[kind+"_token"].encode("ascii")).hexdigest())
                    self.assertIn(f"_probe_{i:02d}_{kind}.txt", rec[kind+"_path"])

    def test_final_diagnostic_marker_is_not_original_stage01_receipt(self):
        _, programs = outer_from_candidate(self.candidate)
        self.assertIn("95 Stage01ChunkAssert 0", programs[-1])
        self.assertIn("⎕NAPPEND", programs[-1])
        self.assertNotIn("RunStage01Tests", programs[-1])
        self.assertEqual(programs[-1].count("⎕NAPPEND"), 1)
        self.assertNotIn("STAGE01_NATIVE_PASS", self.receipt["marker_token"])

    def test_reproducible_and_preserve_original_workspace_terminators(self):
        a, ra = build_diagnostic(BASE, ROOT, MARKER)
        b, rb = build_diagnostic(BASE, ROOT, MARKER)
        self.assertEqual(a, b)
        self.assertEqual(ra, rb)
        c, _ = build_diagnostic(BASE.replace(b"\n", b"\r\n"), ROOT, MARKER)
        self.assertNotIn(b"\n", c.replace(b"\r\n", b""))
        self.assertIn("0=foo=:3", c.decode("cp1252"))

if __name__ == "__main__":
    unittest.main()
