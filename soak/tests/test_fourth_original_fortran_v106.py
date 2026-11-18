"""v106 strict one-original-Fortran native observation parser tests."""
from __future__ import annotations
from pathlib import Path
import sys
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
import audit_fourth_original_fortran_v106 as v
class OriginalFortranGuard(unittest.TestCase):
    def setUp(self):
        self.row="V106_FORTRAN_ORIGINAL_FCT_NATIVE -15055671 -15055671 5000 10 503 20 56\n"
    def test_exact_native_five_fields(self):
        self.assertEqual(v.parse_native(self.row),(5000,10,503,20,56))
    def test_changed_calculation_day_refused(self):
        with self.assertRaisesRegex(ValueError,"coordinate"):
            v.parse_native(self.row.replace("-15055671 -15055671","-15055672 -15055671"))
    def test_changed_target_day_refused(self):
        with self.assertRaisesRegex(ValueError,"coordinate"):
            v.parse_native(self.row.replace("-15055671 -15055671","-15055671 -15055670"))
    def test_duplicate_original_row_refused(self):
        with self.assertRaisesRegex(ValueError,"exactly one"):
            v.parse_native(self.row+self.row)
    def test_missing_native_row_refused(self):
        with self.assertRaisesRegex(ValueError,"exactly one"):
            v.parse_native("foo")
    def test_wrong_field_count_refused(self):
        with self.assertRaisesRegex(ValueError,"cardinality"):
            v.parse_native(self.row.replace(" 20 56"," 20"))
    def test_noncanonical_decimal_refused(self):
        with self.assertRaisesRegex(ValueError,"noncanonical"):
            v.parse_native(self.row.replace(" 5000 "," +5000 "))
    def test_impossible_native_month_index_refused(self):
        with self.assertRaisesRegex(ValueError,"domain"):
            v.parse_native(self.row.replace(" 20 56"," 48 56"))
if __name__=="__main__":
    unittest.main()
