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
    self.assertIn(b'{diamond}',out)
    self.assertIn(b'5={quad}lx=:4',out)
    self.assertIn(b'0=foo=:3',out)
    self.assertEqual(meta['canary_token'], CANARY)
    self.assertFalse(meta['native_executed'])
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
