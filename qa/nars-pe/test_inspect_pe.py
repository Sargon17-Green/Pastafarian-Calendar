import hashlib
from pathlib import Path
import struct
import sys
import tempfile
import unittest
sys.path.insert(0,str(Path(__file__).parent))
from inspect_pe import parse_pe, inspect

def sample_pe(overlay=b'',tweak=None):
    b=bytearray(0x400+len(overlay));b[:2]=b'MZ'
    struct.pack_into('<I',b,0x3c,0x80)
    b[0x80:0x84]=b'PE\0\0'
    struct.pack_into('<H',b,0x84,0x8664)
    struct.pack_into('<H',b,0x86,1)
    struct.pack_into('<H',b,0x94,0xf0)
    opt=0x98;struct.pack_into('<H',b,opt,0x20b)
    struct.pack_into('<I',b,opt+108,16)
    s=opt+0xf0;b[s:s+5]=b'.text'
    struct.pack_into('<IIII',b,s+8,0x100,0x1000,0x200,0x200)
    b[0x400:]=overlay
    if tweak:tweak(b)
    return bytes(b)
class PEUnit(unittest.TestCase):
    def test_structure_overlay(self):
        r=parse_pe(sample_pe(b'abcdefPK\x03\x04MZ'))
        self.assertEqual(r['section_count'],1)
        self.assertEqual(r['machine_hex'],'8664')
        self.assertEqual(r['overlay']['start'],0x400)
        self.assertEqual(r['overlay']['size'],12)
        self.assertEqual(r['signature_candidates']['zip_local_PK0304']['first_offsets'],[0x406])
        self.assertFalse(r['nested_pe_candidates'])
    def test_not_mz(self):
        with self.assertRaisesRegex(ValueError,'NOT_MZ'):parse_pe(b'XX'+sample_pe()[2:])
    def test_not_pe(self):
        with self.assertRaisesRegex(ValueError,'NOT_PE_SIGNATURE'):parse_pe(sample_pe(tweak=lambda b:b.__setitem__(slice(0x80,0x84),b'WRNG')))
    def test_invalid_header(self):
        with self.assertRaisesRegex(ValueError,'INVALID_PE_OFFSET'):parse_pe(sample_pe(tweak=lambda b:struct.pack_into('<I',b,0x3c,0xffffffff)))
    def test_bad_section(self):
        with self.assertRaisesRegex(ValueError,'SECTION_OUT_OF_FILE'):parse_pe(sample_pe(tweak=lambda b:struct.pack_into('<I',b,0x198,0xffff)))
    def test_pin_required(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'x.exe';p.write_bytes(sample_pe())
            with self.assertRaisesRegex(ValueError,'PINNED_SIZE_MISMATCH'):inspect(p)
            self.assertTrue(inspect(p,require_pinned=False)['valid_pe'])
    def test_unbounded_input_reject(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'x.exe'
            with p.open('wb') as out:out.truncate(30_000_001)
            with self.assertRaisesRegex(ValueError,'FILE_EXCEEDS_BOUNDED_SIZE'):inspect(p)
if __name__=='__main__':unittest.main()
