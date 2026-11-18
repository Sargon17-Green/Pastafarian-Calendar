"""Bounded original performance sample negative tests; fixtures are synthetic only."""
from __future__ import annotations
import copy
from pathlib import Path
import sys
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'runner'))
import audit_original_sample_v101 as v
import audit_ts_original_v094 as a

class ReadinessSampleContract(unittest.TestCase):
    def setUp(self):
        self.catalog={'cutlets':[f'c{i}' for i in range(1,18)],
                      'months':[f'm{i}' for i in range(1,48)]}
        self.day=v.SAMPLES[0]
        self.ts={'calculation_day':a.C,'target_day':self.day,
                 'native_tuple':['5000','c2','5','m3','8']}
        self.py={'calculation_day':a.C,'target_day':self.day,
                 'native_date_ids':{'year_number':'5000','cutlet_name_index':2,
                                    'day_in_cutlet':5,'month_name_index':3,'day_in_month':8},
                 'native_names':{'cutlet':'Turkish C','month':'Turkish M'}}
        self.raw=b'{"source":"synthetic"}\n'
        self.norm={'calculation_day':a.C,'target_day':self.day,'year':'5000',
                   'cutlet_index':2,'day_in_cutlet':5,'month_index':3,
                   'day_in_month':8,'cutlet_name_raw':'Turkish C',
                   'month_name_raw':'Turkish M','source_raw_sha256':a.sha(self.raw)}

    def check(self,ts=None,py=None,norm=None,day=None):
        return a.audit_pair(ts or self.ts,b'{"ts":"synthetic"}\n',py or self.py,
                            self.raw,norm or self.norm,b'{"norm":"synthetic"}\n',
                            self.catalog,day or self.day)

    def test_exact_four_distinct_signed_target_days(self):
        self.assertEqual(len(v.SAMPLES),4)
        self.assertEqual(len(set(v.SAMPLES)),4)
        self.assertTrue(any(int(x)<int(a.C) for x in v.SAMPLES))
        self.assertTrue(any(int(x)>int(a.C) for x in v.SAMPLES))

    def test_frozen_candidate_interval_all_samples(self):
        self.assertTrue(all(v.YEAR_FIRST<=int(x)<=v.YEAR_LAST for x in v.SAMPLES))
        self.assertEqual([v.sample_index(x) for x in v.SAMPLES],list(range(4)))

    def test_outside_scope_strictly_rejected(self):
        for x in ('-15055660','-15055659','-15057703','0','',None,0):
            with self.subTest(x=x),self.assertRaises(ValueError): v.sample_index(x)

    def test_synthetic_five_fields_match(self):
        self.assertEqual(self.check()['five_fields'],['5000',2,5,3,8])

    def test_python_raw_hash_mutation_rejected(self):
        norm=copy.deepcopy(self.norm);norm['source_raw_sha256']='0'*64
        with self.assertRaisesRegex(ValueError,'provenance mismatch'):self.check(norm=norm)

    def test_changed_typescript_source_year_rejected(self):
        ts=copy.deepcopy(self.ts);ts['native_tuple'][0]='4999'
        with self.assertRaisesRegex(ValueError,'FIRST_ORIGINAL_NATIVE_MISMATCH'):self.check(ts=ts)

    def test_changed_source_name_index_rejected(self):
        ts=copy.deepcopy(self.ts);ts['native_tuple'][1]='c10'
        with self.assertRaisesRegex(ValueError,'FIRST_ORIGINAL_NATIVE_MISMATCH'):self.check(ts=ts)

    def test_invalid_source_name_rejected(self):
        ts=copy.deepcopy(self.ts);ts['native_tuple'][1]='not-a-source-name'
        with self.assertRaisesRegex(ValueError,'missing from original catalog'):self.check(ts=ts)

    def test_wrong_ordered_input_coordinates_rejected(self):
        ts=copy.deepcopy(self.ts);ts['calculation_day']='-15055658'
        with self.assertRaisesRegex(ValueError,'input identity'):self.check(ts=ts)

    def test_python_raw_normalized_mismatch_rejected(self):
        norm=copy.deepcopy(self.norm);norm['day_in_month']=9
        with self.assertRaisesRegex(ValueError,'provenance mismatch'):self.check(norm=norm)

if __name__=='__main__':
    unittest.main()
