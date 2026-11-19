"""v123 pure arithmetic checks of wide-source rejection-loop risk."""
from __future__ import annotations
from pathlib import Path
import sys
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
import wide_rank_rejection_static_v123 as v


class WideSourceSelectionBoundV123(unittest.TestCase):
    def test_small_cyclic_source_semantics_equal_exact_shortcut(self):
        for m in (5,7,11):
            for n in (1,2,m-1,m,m+1,m+2,2*m,m*m-1,m*m+1):
                for first in (1,2,m//2,m-1,m):
                    for direction in (-1,1):
                        with self.subTest(m=m,n=n,first=first,direction=direction):
                            exact=v.exact_endpoint(m,n,first,direction)
                            naive=v.bounded_source_loop(m,n,first,direction)
                            self.assertEqual(naive,(exact["resulting_rank"],
                                                    exact["stepwise_rejections_avoided"]))

    def test_rejected_step_positive_exactly_wraps_to_rank_one(self):
        result=v.proof()
        self.assertTrue(result["direction_plus_one"]["rejected"])
        self.assertEqual(result["direction_plus_one"]["exact_shortcut_rank"],"1")

    def test_rejected_step_negative_exactly_selects_last_rank(self):
        result=v.proof()
        self.assertTrue(result["direction_minus_one"]["rejected"])
        self.assertEqual(result["direction_minus_one"]["exact_shortcut_rank_bits"],
                         result["family_count_bits"])

    def test_47_month_wide_count_has_248_base_digits(self):
        result=v.proof()
        self.assertEqual(result["wide_base_places"],248)
        self.assertEqual(result["family_total_days"],5778)
        self.assertEqual(result["family_count_bits"],31483)

    def test_positive_rejected_loop_would_need_over_2_to_31479_steps(self):
        result=v.proof()
        self.assertEqual(result["direction_plus_one"]["unoptimized_iterations_bits"],
                         31480)

    def test_negative_rejected_loop_would_need_over_2_to_31481_steps(self):
        result=v.proof()
        self.assertEqual(result["direction_minus_one"]["unoptimized_iterations_bits"],
                         31482)

    def test_unbounded_source_loop_diagnostic_is_explicitly_forbidden(self):
        with self.assertRaises(ValueError):
            v.bounded_source_loop(2**127-1,2**130,1,1)

    def test_invalid_first_modulus_and_direction_rejected(self):
        for args in ((1,5,1,1),(7,0,2,1),(7,2,0,1),(7,2,8,1),
                     (7,2,2,0),(7,2,2,True),(7,2.0,2,1)):
            with self.subTest(args=args),self.assertRaises(ValueError):
                v.exact_endpoint(*args)

    def test_no_calendar_claim_or_source_dispatch_in_report(self):
        result=v.proof()
        self.assertFalse(result["synthetic_answer_stream_proven_reachable_from_actual_sauce"])
        self.assertFalse(result["source_converter_Fct_executed"])
        self.assertFalse(result["original_Python_or_Ada_source_modified"])
        self.assertTrue(result["new_native_soak_dispatch_halted"])
        self.assertEqual(result["full_original_years_certified"],0)
        self.assertEqual(result["ten_thousand_years_certified"],0)


if __name__=="__main__":
    unittest.main()
