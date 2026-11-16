"""v070 tests: source ordinal arithmetic and non-dispatch fail-closed checks.

These tests DO NOT execute F(c,t), access user Windows, or certify a year.
"""
from __future__ import annotations
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
import supervised_original_ordinal_v070 as m


class OriginalOrdinalScopeTests(unittest.TestCase):
    def test_next_original_chunk_1017_exact_dates(self):
        self.assertEqual(m.bounds_for_original_ordinal(1017),
                         ("-15055668","-15055667"))

    def test_final_original_chunk_2121_within_year(self):
        self.assertEqual(m.bounds_for_original_ordinal(2121),
                         ("-15053460","-15053459"))

    def test_previous_proven_chunk_1016_never_reexecuted(self):
        with self.assertRaisesRegex(ValueError,"1017..2121"):
            m.bounds_for_original_ordinal(1016)

    def test_first_year_chunk_zero_not_queued_as_next(self):
        with self.assertRaises(ValueError):
            m.bounds_for_original_ordinal(0)

    def test_after_last_year_chunk_2122_rejected(self):
        with self.assertRaises(ValueError):
            m.bounds_for_original_ordinal(2122)

    def test_non_int_or_boolean_ordinal_cannot_trick_scope(self):
        for val in (True,1017.0,"1017",None,-1,2**63):
            with self.subTest(value=str(val)):
                with self.assertRaises(ValueError):
                    m.bounds_for_original_ordinal(val)

    def test_configure_does_not_change_locked_original_engine_source(self):
        with patch.object(m.legacy,"C","-15055671"), \
             patch.object(m.legacy,"YEAR","5000"), \
             patch.object(m.legacy,"N",2), \
             patch.object(m.legacy,"FIRST","-15055670"), \
             patch.object(m.legacy,"LAST","-15055669"), \
             patch.object(m.legacy,"YEAR_CHUNK_ORDINAL",1016), \
             patch.object(m.legacy,"SCHEMA","PASTAFARI_SUPERVISED_NEXT_TWO_ORIGINAL_DAYS_V061/1"):
            self.assertEqual(m.configure(1017),("-15055668","-15055667"))
            self.assertEqual(m.legacy.YEAR_CHUNK_ORDINAL,1017)
            self.assertEqual(m.legacy.FIRST,"-15055668")
            self.assertEqual(m.legacy.LAST,"-15055667")
            self.assertEqual(m.legacy.SCHEMA,m.SCHEMA)
            self.assertEqual(m.legacy.C,"-15055671")
            self.assertEqual(m.legacy.YEAR,"5000")

    def test_rejected_changed_calculation_day_before_source_execution(self):
        with patch.object(m.legacy,"C","-15055670"), \
             patch.object(m.legacy,"_observe_python") as py:
            with self.assertRaisesRegex(ValueError,"witness constants changed"):
                m.configure(1017)
            py.assert_not_called()

    def test_non_matching_source_gate_result_cannot_emit_dispatch_receipt(self):
        with tempfile.TemporaryDirectory() as tmp, \
             patch.object(m.legacy,"run",return_value={
                 "schema":m.SCHEMA,
                 "status":"SUPERVISED_ORIGINAL_TWO_DAYS_FIRST_MISMATCH_HALT",
                 "first_target_day":"-15055668",
                 "last_target_day":"-15055667",
                 "full_year_chunk_ordinal":1017,
                 "matched_original_day_pairs":0,
                 "first_mismatch":{"field":"month_index"},
                 "original_complete_years_soak_passed":0
             }):
            with self.assertRaisesRegex(ValueError,"NOT accepted"):
                m.run_chunk(1017,Path(tmp),Path(tmp),Path(tmp),Path(tmp))
            self.assertFalse((Path(tmp)/"original-ordinal-dispatch.json").exists())


if __name__=="__main__":
    unittest.main()
