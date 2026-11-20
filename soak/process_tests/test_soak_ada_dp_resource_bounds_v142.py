"""v142: original-source-constrained analytic math and bounded synthetic resource gates.

No native compilation, original calendar, F(c,t), or real-year DP calculations.
"""
from __future__ import annotations
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
import soak_ada_dp_resource_bounds_v142 as v

P=Path(__file__).resolve().parents[1]/"control"/"ada_dp_resource_bounds_v142.json"

PY_SOURCE=b"""
MAX_MONTHS = 47
MIN_MONTH_DAYS = 4
MAX_MONTH_DAYS = 123
self._h[self.month_count] = [1] * (prefix[-1] + 1)
row[x] = weighted_prefix[x + n - 1]
base_count *= comb(n + base_length - 1, base_length)
"""
ADA_SOURCE=b"""
Year_Min_Days  : constant Big_Integer := B (252);
Year_Max_Days  : constant Big_Integer := B (5_778);
Low_Months : constant Natural := (Year_Length + 122) / 123;
High_Months : constant Natural := Natural'Min (47, Year_Length / 4);
for X in 4 .. 123 loop
Month_Weaving.From_Choices (Lengths, Tickets)
"""
class FakeGH:
    def __init__(self):
        self.run={"id":v.V141_RUN,"head_sha":v.V141_SHA,
                  "status":"completed","conclusion":"success"}
        self.art={"total_count":1,"artifacts":[{
            "id":v.V141_ART,"digest":"sha256:"+v.V141_ART_SHA,
            "expired":False}]}
        self.issue={"number":29,"state":"open",
                    "body":"CONFIRMED_ORIGINAL_SOURCE_MISMATCH"}
    def get(self,path):
        pre="/repos/"+v.REPO
        if path==pre+"/actions/runs/"+str(v.V141_RUN):
            return self.run
        if path==pre+"/actions/runs/"+str(v.V141_RUN)+"/artifacts?per_page=100":
            return self.art
        if path==pre+"/issues/29":
            return self.issue
        raise AssertionError("unexpected readonly endpoint: "+path)

class BoundsTests(unittest.TestCase):
    def setUp(self):
        self.m=json.loads(P.read_text(encoding="utf-8"))
        self.gh=FakeGH()
        self.sources={v.PY_REF:PY_SOURCE,v.ADA_REF:ADA_SOURCE}
        self.blobs={v.PY_REF:v.PY_BLOB,v.ADA_REF:v.ADA_BLOB}
        def fake(gh,repo,rev,path):
            self.assertEqual(repo,v.REPO)
            self.assertEqual(path,"tests/normative_reference.py" if rev==v.PY_REF
                             else "src/normative_oracle.adb")
            return self.sources[rev],{"git_blob_sha1":self.blobs[rev]}
        self.p=patch.object(v,"checked_blob",side_effect=fake)
        self.p.start()
        self.addCleanup(self.p.stop)
    def test_01_original_resource_contract_locked(self):
        v.validate(self.m)
    def test_02_frozen_exact_two_original_git_source_blobs(self):
        self.assertEqual(v.source_check(self.m,self.gh)["pinned_source_blobs"],2)
    def test_03_completed_source_v141_CI_and_original_issue_stop(self):
        self.assertTrue(v.qa_check(self.gh)["original_dispatch_stop"])
    def test_04_global_maximum_H_cell_count_138789(self):
        maxrec,records=v.maximum_original_table_rows()
        self.assertEqual(maxrec["cells"],138789)
        self.assertEqual(maxrec["month_count"],47)
        self.assertEqual(len(records),45)
        self.assertTrue(all(r["cells"]<=138789 for r in records))
    def test_05_46_months_have_smaller_H_table(self):
        best,rows=v.maximum_original_table_rows()
        self.assertEqual(rows[-2]["month_count"],46)
        self.assertEqual(rows[-2]["cells"],133010)
        self.assertLess(rows[-2]["cells"],best["cells"])
    def test_06_full_domain_H_cell_bit_upper_bound(self):
        b=v.theoretical_bounds()
        self.assertEqual(b["max_H_cell_bits_in_conservative_encoding"],32270)
        self.assertTrue(b["full_domain_dp_not_evaluated"])
    def test_07_unrestricted_multinomial_max_rank_upper(self):
        self.assertEqual(
            v.theoretical_bounds()["full_legal_family_global_rank_bits_unconstrained_upper"],
            31877)
    def test_08_full_domain_global_rank_wide_stream_is_mandatory_capability(self):
        self.assertTrue(v.theoretical_bounds()[
            "rank_selection_possible_exceeds_original_stream_modulus_2_pow_127_minus_1"])
    def test_09_unrank_coarse_candidate_and_active_scan_bounds(self):
        x=v.theoretical_bounds()
        self.assertEqual(x["ranked_candidate_tests_coarse_upper"],277344)
        self.assertEqual(x["active_month_scans_coarse_upper"],13035168)
    def test_10_CPython_storage_model_not_Ada_measurement(self):
        x=v.theoretical_bounds()
        self.assertTrue(x["python_storage_model_upper_is_not_real_allocation_or_Ada_memory"])
        self.assertGreater(x["python_all_max_width_cells_plus_references_model_MiB"],500)
        self.assertLess(x["python_all_max_width_cells_plus_references_model_MiB"],650)
    def test_11_synthetic_8_times_4_bit_cells(self):
        x=v.SyntheticDP((4,)*8)
        self.assertEqual((x.count().bit_length(),sum(map(len,x.H))),(53,153))
    def test_12_synthetic_8_times_16_bit_cells(self):
        x=v.SyntheticDP((16,)*8)
        self.assertEqual((x.count().bit_length(),sum(map(len,x.H))),(332,585))
    def test_13_synthetic_8_times_32_bit_cells(self):
        x=v.SyntheticDP((32,)*8)
        self.assertEqual((x.count().bit_length(),sum(map(len,x.H))),(713,1161))
    def test_14_synthetic_12_times_12_bit_cells(self):
        x=v.SyntheticDP((12,)*12)
        self.assertEqual((x.count().bit_length(),sum(map(len,x.H))),(427,949))
    def test_15_synthetic_unrank_legal_first_last(self):
        x=v.SyntheticDP((4,)*8)
        first=x.unrank(1)
        last=x.unrank(x.count())
        self.assertNotEqual(first,last)
        self.assertEqual(len(first),32)
        self.assertEqual(len(last),32)
        self.assertEqual(sum(first.count(i) for i in range(1,9)),32)
        self.assertTrue(x.candidates>0)
    def test_16_synthetic_full_four_profiles_are_informational(self):
        x=v.synthetic_profiles(self.m)
        self.assertEqual(len(x),4)
        self.assertEqual([z["days"] for z in x],[32,128,256,144])
        self.assertTrue(all(z["sample_global_ranks"]==3 for z in x))
        self.assertTrue(all(z["timing_memory_not_Ada_and_not_pass_fail_gate"] for z in x))
    def test_17_original_5778_days_deny_synthetic_execution(self):
        with self.assertRaisesRegex(ValueError,"only tiny bounded"):
            v.SyntheticDP((123,)*46+(120,))
    def test_18_synthetic_month_count_47_deny(self):
        with self.assertRaisesRegex(ValueError,"only tiny bounded"):
            v.SyntheticDP((4,)*47)
    def test_19_synthetic_input_type_float_rejected(self):
        with self.assertRaisesRegex(ValueError,"only tiny bounded"):
            v.SyntheticDP((4.0,4))
    def test_20_bad_original_year_upper_bound_rejected(self):
        self.m["original_domain"]["max_days"]=6000
        with self.assertRaisesRegex(ValueError,"year/month bounds changed"):
            v.validate(self.m)
    def test_21_fake_10000_annual_acceptances_rejected(self):
        self.m["scientific_state"]["full_years_accepted"]=10000
        with self.assertRaisesRegex(ValueError,"dispatch stop"):
            v.validate(self.m)
    def test_22_original_dispatch_reopened_without_disposition_rejected(self):
        self.m["scientific_state"]["STOP_NEW_NATIVE_SOAK_DISPATCH"]=False
        with self.assertRaisesRegex(ValueError,"dispatch stop"):
            v.validate(self.m)
    def test_23_original_bigint_capacity_claim_cannot_be_certified(self):
        self.m["interpretation"]["production_Ada_implementation_not_certified"]=False
        with self.assertRaisesRegex(ValueError,"production Ada"):
            v.validate(self.m)
    def test_24_v141_source_receipt_queue_not_pass(self):
        self.gh.run["status"]="queued"
        with self.assertRaisesRegex(ValueError,"not completed success"):
            v.qa_check(self.gh)
    def test_25_v141_artifact_hash_mutated_rejected(self):
        self.gh.art["artifacts"][0]["digest"]="sha256:"+"0"*64
        with self.assertRaisesRegex(ValueError,"digest/availability"):
            v.qa_check(self.gh)
    def test_26_issue_29_closed_not_pass(self):
        self.gh.issue["state"]="closed"
        with self.assertRaisesRegex(ValueError,"missing/closed"):
            v.qa_check(self.gh)
    def test_27_original_source_blob_mutation_rejected(self):
        self.blobs[v.ADA_REF]="f"*40
        with self.assertRaisesRegex(ValueError,"Git blob mismatch"):
            v.source_check(self.m,self.gh)
    def test_28_dropped_source_month_limit_rejected(self):
        self.sources[v.PY_REF]=b"MAX_MONTHS = 47"
        with self.assertRaisesRegex(ValueError,"H-table rows"):
            v.source_check(self.m,self.gh)
    def test_29_bad_analytical_cell_bound_rejected(self):
        self.m["analytical_maximum"]["total_dp_H_entries"]=138788
        with self.assertRaisesRegex(ValueError,"analytical big integer"):
            v.validate(self.m)
    def test_30_no_full_domain_or_Ada_resources_claimed_in_complete_audit(self):
        r=v.audit(self.m,self.gh)
        self.assertEqual(r["original_calendar_Fct_executions"],0)
        self.assertEqual(r["original_full_years_certified"],0)
        self.assertFalse(r["production_Ada_resource_proven"])
        self.assertTrue(r["STOP_NEW_NATIVE_SOAK_DISPATCH"])

if __name__=="__main__":
    unittest.main()
