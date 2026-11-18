"""v103 first-difference Ada source guard, synthetic parsing only."""
from __future__ import annotations
from pathlib import Path
import sys
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
import audit_ada_original_discriminator_v103 as v

class AdaOneOriginalDayGuardV103(unittest.TestCase):
    def setUp(self):
        self.good="V103_ADA_ORIGINAL_FCT_NATIVE -15055671 -15055671 5000 10 503 30 52\n"

    def test_exact_observed_historical_native_tuple_is_parseable(self):
        self.assertEqual(v.parse_ada(self.good),(5000,10,503,30,52))

    def test_refuse_different_calculation_coordinate(self):
        with self.assertRaisesRegex(ValueError,"coordinate"):
            v.parse_ada(self.good.replace("-15055671 -15055671","-15055672 -15055671"))

    def test_refuse_different_target_coordinate(self):
        with self.assertRaisesRegex(ValueError,"coordinate"):
            v.parse_ada(self.good.replace("-15055671 -15055671","-15055671 -15055670"))

    def test_refuse_duplicate_native_source_lines(self):
        with self.assertRaisesRegex(ValueError,"exactly one"):
            v.parse_ada(self.good+self.good)

    def test_refuse_missing_native_source_line(self):
        with self.assertRaisesRegex(ValueError,"exactly one"):
            v.parse_ada("GNAT compiled successfully\n")

    def test_refuse_partial_five_fields(self):
        with self.assertRaisesRegex(ValueError,"cardinality"):
            v.parse_ada(self.good.replace("30 52","30"))

    def test_refuse_noncanonical_numeric(self):
        with self.assertRaises(ValueError):v.parse_ada(self.good.replace(" 5000 "," +5000 "))

    def test_refuse_impossible_month_index(self):
        with self.assertRaisesRegex(ValueError,"domain"):
            v.parse_ada(self.good.replace(" 30 52"," 48 52"))

if __name__=="__main__":
    unittest.main()
