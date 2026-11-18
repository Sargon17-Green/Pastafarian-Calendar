import unittest
from lx_workspace_probe import make_canary, CANARY

BASE = """[General]
Version=1
[Globals]
:0=V C 0 1 0 ''
:3=V C 0 1 0 ''
[Vars.0]
5={quad}lx=:3
[Fcns.0]
0=foo=:3
""".encode('cp1252')
PATH='D:\\a\\_temp\\LX_canary.txt'
class WorkspaceTests(unittest.TestCase):
  def test_canary_is_exact_mutation(self):
    out, meta=make_canary(BASE, PATH)
    self.assertIn(b':4=V C ',out)
    self.assertIn(b'{quad}NCREATE',out)
    self.assertIn(b'{quad}NAPPEND',out)
    self.assertIn(b'{quad}UCS ',out)
    self.assertNotIn(b'{diamond}',out)
    self.assertIn(b'5={quad}lx=:4',out)
    self.assertIn(b'0=foo=:3',out)
    self.assertEqual(meta['canary_token'], CANARY)
    self.assertFalse(meta['native_executed'])
  def test_lx_is_single_expression_and_does_not_reference_tn(self):
    out, meta = make_canary(BASE, PATH)
    self.assertNotIn('tn', meta['apl_statement'])
    self.assertNotIn('⋄', meta['apl_statement'])
    token_codes = ' '.join(str(ord(ch)) for ch in CANARY)
    path_codes = ' '.join(str(ord(ch)) for ch in PATH)
    expected = f"(⎕UCS {token_codes}) ⎕NAPPEND ((⎕UCS {path_codes}) ⎕NCREATE 0)"
    self.assertEqual(meta['apl_statement'], expected)
    self.assertNotIn("'", meta['apl_statement'])
    self.assertNotIn('"', meta['apl_statement'])
  def test_file_mode_uses_two_unicode_vectors(self):
    out, meta = make_canary(BASE, PATH, mode='file')
    statement = meta['apl_statement']
    self.assertEqual(statement.count('⎕UCS'), 2)
    self.assertEqual(statement.count('⎕NAPPEND'), 1)
    self.assertEqual(statement.count('⎕NCREATE'), 1)
    self.assertIn('⎕NAPPEND ((⎕UCS ', statement)
    self.assertTrue(statement.endswith(' ⎕NCREATE 0)'))
    self.assertFalse(any(ch in statement for ch in ["'", '"']))
    self.assertTrue(meta['canary_path'].endswith('LX_canary.txt'))
  def test_display_mode_roundtrip_lx_only(self):
    out, meta = make_canary(BASE, PATH, mode='display')
    self.assertEqual(meta['mode'], 'display')
    self.assertEqual(meta['apl_statement'], "⎕←⎕UCS " + " ".join(str(ord(ch)) for ch in CANARY))
    self.assertIn(b'{quad}{leftarrow}{quad}UCS ', out)
    self.assertNotIn(b"''APL_LX_", out)
    self.assertNotIn("'00'", meta['apl_statement'])
    self.assertNotIn(b'{assign}', out)
    self.assertNotIn(b'{quad}NCREATE', out)
    self.assertNotIn(b'{quad}NAPPEND', out)
  def test_reject_unknown_lx_mode(self):
    with self.assertRaisesRegex(ValueError, 'UNKNOWN_LX_PROBE_MODE'):
      make_canary(BASE, PATH, mode='typo')
  def test_file_payload_is_quote_free_in_workspace(self):
    out, meta = make_canary(BASE, PATH)
    lines = out.decode('cp1252').splitlines()
    glob = next(s for s in lines if s.startswith(':4=V C '))
    self.assertEqual(glob.count("'"), 2)
    payload = glob.split("'", 2)[1]
    self.assertNotIn("'", payload)
    self.assertNotIn('"', payload)
    self.assertIn('{quad}UCS ', payload)
    self.assertIn('{quad}NAPPEND', payload)
    self.assertIn('{quad}NCREATE', payload)
    self.assertTrue(glob.endswith("'"))
    self.assertEqual(meta['actual_apl_characters'], len(meta['apl_statement']))
    self.assertEqual(glob.split(' ', 5)[2], str(len(meta['apl_statement'])))
  def test_nonlocal_workspace_bytes_unchanged_after_escape(self):
    out, meta = make_canary(BASE, PATH)
    old = out.decode('cp1252').splitlines()
    self.assertEqual([x for x in old if x.startswith('0=foo')], ['0=foo=:3'])
    self.assertEqual(meta['lx_previous_global'], 3)
    self.assertEqual(meta['lx_new_global'], 4)
  def test_keep_crlf(self):
    raw=BASE.replace(b'\n',b'\r\n')
    out, _=make_canary(raw,PATH)
    self.assertIn(b':4=V C ',out)
    self.assertNotIn(b'\n',out.replace(b'\r\n',b''))
  def test_empty(self):
    with self.assertRaises(ValueError):make_canary(b'',PATH)
  def test_bad_path(self):
    with self.assertRaises(ValueError):make_canary(BASE, "C:\\a\\x';evil.txt")
  def test_relative_path(self):
    with self.assertRaises(ValueError):make_canary(BASE,'lx_canary.txt')
  def test_missing_globals(self):
    with self.assertRaises(ValueError):make_canary(BASE.replace(b'[Globals]',b'[Foo]'),PATH)
  def test_duplicate_lx(self):
    with self.assertRaises(ValueError):make_canary(BASE.replace(b'5={quad}lx=:3',b'5={quad}lx=:3\n6={quad}lx=:3'),PATH)
  def test_missing_lx(self):
    with self.assertRaises(ValueError):make_canary(BASE.replace(b'5={quad}lx=:3',b'5={quad}io=:3'),PATH)
  def test_max_global(self):
    with self.assertRaises(ValueError):make_canary(BASE.replace(b':3=V',b':1000000=V'),PATH)
  def test_non_ascii_original_preserved(self):
    raw=BASE.replace(b'Version=1',b'Version=\xe9')
    out,_=make_canary(raw,PATH)
    self.assertIn(b'Version=\xe9',out)
if __name__=='__main__':unittest.main()
