import pathlib
import tempfile
import unittest

from stage01_import_workspace import (
    SOURCE_COMMIT, SOURCE_FILES, EXPECTED_TOTAL_FUNCTIONS,
    load_locked_sources, build_inner_program, make_stage01_candidate,
)

REPO = pathlib.Path(__file__).resolve().parents[2]
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
MARKER = "D:\\a\\_temp\\apl_stage01_native_receipt.txt"


class Stage01ImportWorkspaceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.loaded = load_locked_sources(REPO)

    def test_five_ordered_locked_files_and_95_unique_functions(self):
        m = self.loaded["manifest"]
        self.assertEqual(m["source_commit"], SOURCE_COMMIT)
        self.assertEqual(len(m["ordered_files"]), 5)
        self.assertEqual(m["function_count"], EXPECTED_TOTAL_FUNCTIONS)
        self.assertEqual(m["unique_function_count"], EXPECTED_TOTAL_FUNCTIONS)
        self.assertEqual([x["path"] for x in m["ordered_files"]], [x[0] for x in SOURCE_FILES])
        self.assertEqual([x["git_blob_sha1"] for x in m["ordered_files"]], [x[1] for x in SOURCE_FILES])
        self.assertEqual([x["function_count"] for x in m["ordered_files"]], [x[2] for x in SOURCE_FILES])

    def test_runstage01tests_and_initializers_are_locked_in_source(self):
        m = self.loaded["manifest"]
        self.assertEqual(m["test_entrypoint"], "RunStage01Tests")
        self.assertEqual(m["test_initializers"], ["SourceLanguageCatalogInit", "MonsterBootstrapInit", "OracleInit", "Stage01FixturesInit"])
        self.assertIn("RunStage01Tests", m["ordered_function_names"])

    def test_inner_program_fixes_every_name_checks_count_runs_tests_then_writes_marker(self):
        outer, token = build_inner_program(self.loaded, MARKER)
        self.assertTrue(outer.startswith("⎕EC ⎕UCS "))
        self.assertNotIn("'", outer)
        self.assertNotIn('"', outer)
        self.assertEqual(token, "APL_GERMAN_STAGE01_NATIVE_PASS_V1|SOURCE=" + SOURCE_COMMIT + "|FILES=5|FX=95|TEST=STAGE01_PASS")
        prefix = "⎕EC ⎕UCS "
        inner = "".join(chr(int(x)) for x in outer[len(prefix):].split())
        self.assertEqual(inner.count("Stage01Fix ("), EXPECTED_TOTAL_FUNCTIONS)
        self.assertIn("Stage01FXCount←0", inner)
        self.assertIn("Stage01CheckFXCount", inner)
        self.assertLess(inner.index("RunStage01Tests"), inner.index("⎕NAPPEND"))
        for name in self.loaded["manifest"]["ordered_function_names"]:
            self.assertIn("⎕UCS " + " ".join(str(ord(c)) for c in name) + ") Stage01Fix", inner)

    def test_outer_unicode_vector_decodes_to_complete_inner_program(self):
        outer, _ = build_inner_program(self.loaded, MARKER)
        prefix = "⎕EC ⎕UCS "
        codes = [int(x) for x in outer[len(prefix):].split()]
        inner = "".join(chr(x) for x in codes)
        self.assertIn("RunStage01Tests", inner)
        self.assertIn("STAGE01_FX_IMPORT_FAILED", inner)
        self.assertIn("STAGE01_FX_COUNT_MISMATCH", inner)
        self.assertTrue(inner.endswith("⎕NCREATE 0)"))

    def test_candidate_changes_only_the_new_lx_global(self):
        candidate, manifest, receipt = make_stage01_candidate(BASE, MARKER, REPO)
        lines = candidate.decode("cp1252").splitlines()
        self.assertIn("0=foo=:3", lines)
        glob = next(x for x in lines if x.startswith(f":{receipt['lx_new_global']}=V C "))
        self.assertEqual(glob.count("'"), 2)
        payload = glob.split("'", 2)[1]
        self.assertIn("{quad}EC {quad}UCS ", payload)
        self.assertNotIn("'", payload)
        self.assertEqual(receipt["source_file_count"], 5)
        self.assertEqual(receipt["function_count"], 95)
        self.assertEqual(receipt["unique_function_count"], 95)
        self.assertFalse(receipt["native_executed"])
        self.assertEqual(receipt["candidate_sha256"], __import__("hashlib").sha256(candidate).hexdigest())
        self.assertEqual(manifest["manifest_sha256"], self.loaded["manifest"]["manifest_sha256"])

    def test_program_is_bounded_and_bmp_only(self):
        outer, _ = build_inner_program(self.loaded, MARKER)
        self.assertLess(len(outer), 3_000_000)
        self.assertTrue(all(ord(ch) <= 0xFFFF for ch in outer))


if __name__ == "__main__":
    unittest.main()
