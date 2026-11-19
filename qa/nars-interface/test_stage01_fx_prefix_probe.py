import hashlib
import pathlib
import unittest

from stage01_fx_prefix_probe import create_prefix, nested_fx_expression
from stage01_import_workspace import load_locked_sources, fx_definition_lines

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
ROOT=pathlib.Path(__file__).resolve().parents[2]
MARKER="D:\\a\\_temp\\stage01_prefix_fx.txt"

class PrefixTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.locked=load_locked_sources(ROOT)

    def test_prefix_five_and_exact_names(self):
        a=self.locked["blocks"][:5]
        self.assertEqual(len(a),5)
        self.assertEqual(len(set(x["name"] for x in a)),5)
        self.assertTrue(all("∇" not in fx_definition_lines(x)[0] for x in a))

    def test_generated_candidate_binds_exact_five(self):
        c,r=create_prefix(BASE,MARKER,ROOT)
        self.assertEqual(r["fx_count"],5)
        self.assertEqual(r["fx_names"],[x["name"] for x in self.locked["blocks"][:5]])
        self.assertTrue(r["marker_token"].startswith("APL_GERMAN_PREFIX_5_FX_VERIFIED_SOURCE_"))
        self.assertEqual(r["candidate_sha256"],hashlib.sha256(c).hexdigest())
        self.assertFalse(r["native_executed"])
        self.assertIn(b"{quad}EC {quad}UCS ",c)
        self.assertIn(b"0=foo=:3",c)

    def test_size_below_large_stage1(self):
        c,r=create_prefix(BASE,MARKER,ROOT)
        self.assertLess(len(c),300000)
        self.assertLess(r["outer_lx_chars"],200000)

    def test_nested_character_strand_without_padding(self):
        expression=nested_fx_expression(["z←Test x", "z←x+1"])
        self.assertTrue(expression.startswith("((⎕UCS "))
        self.assertIn(") (⎕UCS ",expression)
        self.assertNotIn("⍴",expression)
        self.assertEqual(expression.count("⎕UCS"),2)
        _,receipt=create_prefix(BASE,MARKER,ROOT)
        self.assertEqual(receipt["fx_transport"],"NESTED_CHARACTER_VECTOR_STRAND_V1")

    def test_crlf_preserved(self):
        raw=BASE.replace(b"\n",b"\r\n")
        c,_=create_prefix(raw,MARKER,ROOT)
        self.assertNotIn(b"\n",c.replace(b"\r\n",b""))

if __name__=="__main__":
    unittest.main()
