import pathlib
import tempfile
import unittest
import hashlib
import json
import subprocess
import sys

from stage01_import_workspace import (
    SOURCE_COMMIT, SOURCE_FILES, EXPECTED_TOTAL_FUNCTIONS,
    load_locked_sources, build_inner_program, make_stage01_candidate,
    fx_definition_lines, HELPER_LINES, COUNT_HELPER_LINES, _nested_fx_expression,
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

    def test_native_fx_excludes_editor_delimiters_for_all_95_functions(self):
        self.assertFalse(any("∇" in line for line in HELPER_LINES))
        self.assertFalse(any("∇" in line for line in COUNT_HELPER_LINES))
        for block in self.loaded["blocks"]:
            native = fx_definition_lines(block)
            self.assertEqual(native[0], block["lines"][0][1:].strip())
            self.assertEqual(native[1:], block["lines"][1:-1])
            self.assertFalse(native[0].startswith("∇"))
            self.assertNotEqual(native[-1], "∇")
        self.assertEqual(len(self.loaded["blocks"]), 95)

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
        # Function bodies are serialized into numeric ⎕UCS vectors, so
        # their German error messages do not occur as plaintext in inner.
        for message in ("STAGE01_FX_IMPORT_FAILED", "STAGE01_FX_COUNT_MISMATCH"):
            numeric = " ".join(str(ord(c)) for c in message)
            self.assertIn(numeric, inner)
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


    def test_full_stage01_uses_verified_nested_fx_transport(self):
        lines = ["z←Test x", "", "  z←x+1"]
        expression = _nested_fx_expression(lines)
        self.assertEqual(expression.count("⎕UCS"), 3)
        self.assertIn("(0⍴⎕UCS 32)", expression)
        self.assertIn(") (⎕UCS ", expression)
        outer, _ = build_inner_program(self.loaded, MARKER)
        inner = "".join(chr(int(x)) for x in outer[len("⎕EC ⎕UCS "):].split())
        self.assertIn("⎕FX ((⎕UCS ", inner)
        self.assertEqual(inner.count("Stage01Fix ((⎕UCS "), EXPECTED_TOTAL_FUNCTIONS)
        self.assertNotIn("⍴⎕UCS", inner.replace("(0⍴⎕UCS 32)", ""))
        _, _, receipt = make_stage01_candidate(BASE, MARKER, REPO)
        self.assertEqual(receipt["fx_transport"], "NESTED_CHARACTER_VECTOR_STRAND_V1")
        self.assertFalse(receipt["native_executed"])

    def test_empty_fx_input_fails_closed(self):
        with self.assertRaisesRegex(ValueError, "EMPTY_APL_FUNCTION"):
            _nested_fx_expression([])

    def test_cli_emits_exact_lf_manifest_bytes_on_current_os(self):
        with tempfile.TemporaryDirectory() as root:
            d = pathlib.Path(root)
            source_workspace = d / "reference.ws.nars"
            candidate = d / "candidate.ws.nars"
            manifest_path = d / "source_manifest.json"
            receipt_path = d / "workspace_candidate_receipt.json"
            source_workspace.write_bytes(BASE)
            proc = subprocess.run(
                [sys.executable, str(REPO / "qa/nars-interface/stage01_import_workspace.py"),
                 "--repo-root", str(REPO), "--source-workspace", str(source_workspace),
                 "--candidate", str(candidate), "--manifest", str(manifest_path),
                 "--receipt", str(receipt_path), "--marker-path", MARKER],
                capture_output=True, text=True, timeout=60, check=False,
            )
            self.assertEqual(proc.returncode, 0, proc.stderr[:1000])
            raw = manifest_path.read_bytes()
            self.assertNotIn(b"\r\n", raw)
            self.assertTrue(raw.endswith(b"\n"))
            receipt = json.loads(receipt_path.read_bytes())
            self.assertEqual(hashlib.sha256(raw).hexdigest(), receipt["source_manifest_sha256"])
            self.assertEqual(hashlib.sha256(candidate.read_bytes()).hexdigest(), receipt["candidate_sha256"])
            self.assertFalse(receipt["native_executed"])

    def test_program_is_bounded_and_bmp_only(self):
        outer, _ = build_inner_program(self.loaded, MARKER)
        self.assertLess(len(outer), 3_000_000)
        self.assertTrue(all(ord(ch) <= 0xFFFF for ch in outer))


if __name__ == "__main__":
    unittest.main()
