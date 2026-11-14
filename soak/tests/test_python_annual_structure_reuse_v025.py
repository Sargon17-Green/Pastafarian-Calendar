from __future__ import annotations

import importlib.util
from pathlib import Path
from types import SimpleNamespace as NS
import unittest

P=Path(__file__).resolve().parents[1]/"experiments/python_annual_structure_reuse_v025.py"
spec=importlib.util.spec_from_file_location("annual_native_structure_v025",P)
mod=importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def model():
    year=NS(number=5000,open_gate_day=0,close_gate_day=7)
    cutlets=[
        NS(first_day=1,last_day=3,name_index=10),
        NS(first_day=4,last_day=7,name_index=14),
    ]
    s=NS(cutlet_count=2,cutlets=cutlets,
         month_count=2,month_lengths=(4,3),
         month_name_indices=(20,32),
         month_weaving=(1,2,1,2,1,2,1))
    return year,s


class AnnualStructureTests(unittest.TestCase):
    def test_native_structure_expanded_exactly_and_in_order(self):
        year,structure=model()
        x=mod.expand_structure(year,structure)
        self.assertEqual(len(x),7)
        self.assertEqual(x,[
            (5000,10,1,20,1),
            (5000,10,2,32,1),
            (5000,10,3,20,2),
            (5000,14,1,32,2),
            (5000,14,2,20,3),
            (5000,14,3,32,3),
            (5000,14,4,20,4)
        ] if False else [
            (5000,10,1,20,1),
            (5000,10,2,32,1),
            (5000,10,3,20,2),
            (5000,14,1,32,2),
            (5000,14,2,20,3),
            (5000,14,3,32,3),
            (5000,14,4,20,4)
        ])

    def test_month_count_mismatch_fails_closed(self):
        year,s=model()
        s.month_lengths=(3,4)
        with self.assertRaisesRegex(ValueError,"weaving counts differ"):
            mod.expand_structure(year,s)

    def test_gap_in_cutlet_intervals_fails_closed(self):
        year,s=model()
        s.cutlets[1].first_day=5
        with self.assertRaisesRegex(ValueError,"gap"):
            mod.expand_structure(year,s)

    def test_out_of_range_month_fails_closed(self):
        year,s=model()
        s.month_weaving=(1,2,1,2,1,2,3)
        with self.assertRaisesRegex(ValueError,"invalid month"):
            mod.expand_structure(year,s)

    def test_samples_prioritize_first_last_and_foundation(self):
        c=-15055671
        first=-15057702
        last=-15053459
        s=NS(cutlets=[NS(first_day=first,last_day=last)],
             month_weaving=(1,)*4244)
        result=mod.sample_targets(c,first,last,s,14)
        self.assertEqual(len(result),14)
        self.assertEqual(len(set(result)),14)
        for day in [first,first+1,first+2,last-2,last-1,last,c-1,c,c+1]:
            self.assertIn(day,result)
        self.assertTrue(all(first<=t<=last for t in result))

    def test_sample_cap_guard(self):
        c=-15055671;first=-15057702;last=-15053459
        s=NS(cutlets=[],month_weaving=())
        with self.assertRaisesRegex(ValueError,"at least 9"):
            mod.sample_targets(c,first,last,s,8)


if __name__=="__main__":
    unittest.main()
