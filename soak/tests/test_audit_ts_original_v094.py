"""v094 tests of strict TypeScript/Python raw five-field comparison; synthetic only."""
from __future__ import annotations
import copy
from pathlib import Path
import sys
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
import audit_ts_original_v094 as a


class TypeScriptMarathiRawAuditV094(unittest.TestCase):
    def setUp(self):
        self.catalog={"cutlets":["c"+str(i) for i in range(1,18)],
                      "months":["m"+str(i) for i in range(1,48)]}
        self.ts={"calculation_day":a.C,"target_day":a.DAYS[0],
                 "native_tuple":["5000","c14","11","m1","42"]}
        self.py={"calculation_day":a.C,"target_day":a.DAYS[0],
                 "native_date_ids":{"year_number":"5000","cutlet_name_index":14,
                                    "day_in_cutlet":11,"month_name_index":1,
                                    "day_in_month":42},
                 "native_names":{"cutlet":"C","month":"M"}}
        self.norm={"calculation_day":a.C,"target_day":a.DAYS[0],
                   "year":"5000","cutlet_index":14,"day_in_cutlet":11,
                   "month_index":1,"day_in_month":42,
                   "cutlet_name_raw":"C","month_name_raw":"M"}
        self.raw=b'{"synthetic":true}\n'
        self.norm["source_raw_sha256"]=a.sha(self.raw)

    def compare(self,ts=None,py=None,norm=None,raw=None,catalog=None,t=None):
        return a.audit_pair(ts if ts is not None else self.ts,
                            b'{"synthetic-ts":true}\n',
                            py if py is not None else self.py,
                            raw if raw is not None else self.raw,
                            norm if norm is not None else self.norm,
                            b'{"synthetic-normalized":true}\n',
                            catalog if catalog is not None else self.catalog,
                            t if t is not None else a.DAYS[0])

    def test_synthetic_one_pair_matches_numerically(self):
        row=self.compare()
        self.assertEqual(row["five_fields"],["5000",14,11,1,42])

    def test_changed_native_month_is_first_mismatch(self):
        ts=copy.deepcopy(self.ts)
        ts["native_tuple"][3]="m2"
        with self.assertRaisesRegex(ValueError,"FIRST_ORIGINAL_NATIVE_MISMATCH"):
            self.compare(ts=ts)

    def test_changed_native_year_is_first_mismatch(self):
        ts=copy.deepcopy(self.ts);ts["native_tuple"][0]="4999"
        with self.assertRaisesRegex(ValueError,"FIRST_ORIGINAL_NATIVE_MISMATCH"):
            self.compare(ts=ts)

    def test_unmapped_native_name_rejected(self):
        ts=copy.deepcopy(self.ts);ts["native_tuple"][1]="unmapped"
        with self.assertRaisesRegex(ValueError,"missing from original catalog"):
            self.compare(ts=ts)

    def test_python_normalized_tamper_rejected(self):
        norm=copy.deepcopy(self.norm);norm["month_index"]=2
        with self.assertRaisesRegex(ValueError,"provenance mismatch"):
            self.compare(norm=norm)

    def test_original_python_raw_hash_tamper_rejected(self):
        with self.assertRaisesRegex(ValueError,"provenance mismatch"):
            self.compare(raw=b'{"changed":true}\n')

    def test_wrong_coordinates_rejected(self):
        ts=copy.deepcopy(self.ts);ts["target_day"]=a.DAYS[1]
        with self.assertRaisesRegex(ValueError,"identity"):
            self.compare(ts=ts)

    def test_native_duplicate_keys_rejected(self):
        with self.assertRaisesRegex(ValueError,"duplicate"):
            a._line(b'{"year":"5000","year":"5000"}\n')

    def test_noncanonical_integer_rejected(self):
        for bad in ("+1","-0","01","3.0",0,False):
            with self.subTest(value=bad),self.assertRaises(ValueError):
                a._canonical(bad)

    def test_missing_newline_rejected(self):
        with self.assertRaisesRegex(ValueError,"one canonical"):
            a._line(b'{"a":1}')

    def test_invalid_native_tuple_length_rejected(self):
        ts=copy.deepcopy(self.ts);ts["native_tuple"]=ts["native_tuple"][:4]
        with self.assertRaisesRegex(ValueError,"tuple malformed"):
            self.compare(ts=ts)

    def test_year_claim_not_present_in_pure_comparison(self):
        row=self.compare()
        self.assertNotIn("full_original_years_certified",row)
        self.assertEqual(len(row["five_fields"]),5)


if __name__=="__main__":
    unittest.main()
