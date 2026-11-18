import pathlib
import re
import unittest

from fx_probe_workspace import FX_LINES, FX_NAME, FX_TOKEN, make_fx_probe

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
PATH = "D:\\a\\_temp\\apl_fx_probe.txt"


class FxProbeWorkspaceTests(unittest.TestCase):
    def test_outer_lx_is_quote_free_ec_ucs(self):
        out, meta = make_fx_probe(BASE, PATH)
        self.assertTrue(meta["apl_statement"].startswith("⎕EC ⎕UCS "))
        self.assertNotIn("'", meta["apl_statement"])
        self.assertNotIn('"', meta["apl_statement"])
        self.assertIn(b"{quad}EC {quad}UCS ", out)
        self.assertEqual(meta["canary_token"], FX_TOKEN)
        self.assertEqual(meta["mode"], "fx_probe")
        self.assertFalse(meta["native_executed"])

    def test_ec_numeric_vector_decodes_to_exact_inner_program(self):
        _, meta = make_fx_probe(BASE, PATH)
        prefix = "⎕EC ⎕UCS "
        codes = [int(x) for x in meta["apl_statement"][len(prefix):].split()]
        self.assertEqual("".join(chr(x) for x in codes), meta["inner_apl_statement"])

    def test_inner_program_fixes_and_executes_function_before_file_write(self):
        _, meta = make_fx_probe(BASE, PATH)
        inner = meta["inner_apl_statement"]
        self.assertIn("⎕FX (3 ", inner)
        self.assertIn("⍴⎕UCS ", inner)
        self.assertIn("⋄ (⍕" + FX_NAME + " 41) ⎕NAPPEND", inner)
        self.assertIn("⎕NCREATE 0)", inner)
        self.assertIn("APL_GERMAN_FX_PROBE_20261118", inner)
        self.assertEqual(meta["fx_matrix_shape"][0], len(FX_LINES))

    def test_matrix_codes_reconstruct_exact_function_lines(self):
        _, meta = make_fx_probe(BASE, PATH)
        inner = meta["inner_apl_statement"]
        m = re.search(r"⎕FX \((\d+) (\d+)⍴⎕UCS ([0-9 ]+)\)", inner)
        self.assertIsNotNone(m)
        rows, cols = int(m.group(1)), int(m.group(2))
        chars = "".join(chr(int(x)) for x in m.group(3).split())
        self.assertEqual(len(chars), rows * cols)
        recovered = [chars[i * cols:(i + 1) * cols].rstrip() for i in range(rows)]
        self.assertEqual(recovered, FX_LINES)

    def test_workspace_only_changes_new_lx_global(self):
        out, meta = make_fx_probe(BASE, PATH)
        lines = out.decode("cp1252").splitlines()
        glob = next(x for x in lines if x.startswith(f":{meta['lx_new_global']}=V C "))
        self.assertEqual(glob.count("'"), 2)
        payload = glob.split("'", 2)[1]
        self.assertNotIn("'", payload)
        self.assertIn("{quad}EC {quad}UCS ", payload)
        self.assertIn("0=foo=:3", lines)

    def test_crlf_is_preserved(self):
        raw = BASE.replace(b"\n", b"\r\n")
        out, _ = make_fx_probe(raw, PATH)
        self.assertNotIn(b"\n", out.replace(b"\r\n", b""))

    def test_bad_path_is_rejected(self):
        with self.assertRaises(ValueError):
            make_fx_probe(BASE, "C:\\a\\bad';.txt")


if __name__ == "__main__":
    unittest.main()
