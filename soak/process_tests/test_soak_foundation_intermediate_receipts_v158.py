#!/usr/bin/env python3
"""v158: synthetic-only hash-chain/receipt and original-provenance admission tests."""
from __future__ import annotations
import copy
import hashlib
import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
from native_execution_receipt_v038 import canonical
from soak_foundation_intermediate_receipts_v158 import (
    build,verify_both,verify_case,strict_json,sha,make_case,
    STAGES,STATUS,SCHEMA,REAL_NEEDED,ZERO
)


def reseal_case(c:dict) -> None:
    prev=ZERO
    for i,event in enumerate(c["events"]):
        event["stage_index"]=i
        event["previous_event_sha256"]=prev
        e={k:v for k,v in event.items() if k!="event_sha256"}
        event["event_sha256"]=sha(canonical(e))
        prev=event["event_sha256"]
    c["final_event_sha256"]=prev
    base={k:v for k,v in c.items() if k!="bundle_sha256"}
    c["bundle_sha256"]=sha(canonical(base))


class ReceiptChainTamperTests(unittest.TestCase):
    def setUp(self):
        self.b=build()
        self.c=self.b["cases"][0]

    def blocked(self):
        with self.assertRaises((ValueError,KeyError,TypeError,IndexError)):
            verify_both(self.b)

    def test_01_clean_two_complete_synthetic_cases(self):
        r=verify_both(self.b)
        self.assertTrue(r["two_complete_synthetic_receipts"])
        self.assertFalse(r["historical_foundation_intermediates_attested"])

    def test_02_canonical_bytes_roundtrip(self):
        self.assertEqual(strict_json(canonical(self.b)),self.b)

    def test_03_event_hash_chains_stable(self):
        prev=ZERO
        for event in self.c["events"]:
            self.assertEqual(event["previous_event_sha256"],prev)
            prev=event["event_sha256"]
        self.assertEqual(prev,self.c["final_event_sha256"])

    def test_04_duplicate_json_key_refused(self):
        with self.assertRaisesRegex(ValueError,"duplicate"):
            strict_json(b'{"a":1,"a":2}')

    def test_05_noncanonical_json_refused(self):
        with self.assertRaisesRegex(ValueError,"canonical"):
            strict_json(b'{ "a":1 }')

    def test_06_nonfinite_nan_refused(self):
        with self.assertRaises(ValueError):
            strict_json(b'{"v":NaN}')

    def test_07_noncanonical_unicode_escaping_refused(self):
        with self.assertRaises(ValueError):
            strict_json(b'{"x":"\\u05d0"}')

    def test_08_nonobject_refused(self):
        with self.assertRaisesRegex(ValueError,"canonical"):
            strict_json(b'[]')

    def test_09_bundle_digest_mutation_refused(self):
        self.c["bundle_sha256"]="e"*64
        self.blocked()

    def test_10_changed_stage_payload_without_reseal(self):
        self.c["events"][1]["payload"]["month_count"]=100
        self.blocked()

    def test_11_changed_stage_payload_with_reseal(self):
        self.c["events"][1]["payload"]["month_count"]=100
        reseal_case(self.c)
        self.blocked()

    def test_12_out_of_order_events_rejected(self):
        self.c["events"][3],self.c["events"][4] = self.c["events"][4],self.c["events"][3]
        self.blocked()

    def test_13_missing_stage_rejected(self):
        self.c["events"].pop(1)
        self.blocked()

    def test_14_extra_stage_rejected(self):
        self.c["events"].append(copy.deepcopy(self.c["events"][-1]))
        self.blocked()

    def test_15_event_previous_hash_forgery_rejected(self):
        self.c["events"][3]["previous_event_sha256"]="c"*64
        self.blocked()

    def test_16_final_event_sha_forgery_rejected(self):
        self.c["final_event_sha256"]="d"*64
        self.blocked()

    def test_17_original_provenance_claim_refused(self):
        self.c["native_process_provenance"]={"pid":123}
        self.blocked()

    def test_18_real_intermediate_claim_refused(self):
        self.c["real_source_intermediate_receipt"]={"month_count":4}
        self.blocked()

    def test_19_claimed_executed_original_refused(self):
        self.c["historical_source_code_executed"]=True
        self.blocked()

    def test_20_original_date_call_claim_refused(self):
        self.c["historical_original_Fct_calls"]=1
        self.blocked()

    def test_21_original_year_promotion_refused(self):
        self.c["original_full_years_certified"]=1
        self.blocked()

    def test_22_native_dispatch_permission_refused(self):
        self.b["native_original_dispatch_admitted"]=True
        self.blocked()

    def test_23_halt_flag_removal_refused(self):
        self.c["halt_new_native_soak_dispatch"]=False
        self.blocked()

    def test_24_main_branch_modification_permission_refused(self):
        self.c["main_changes_permitted"]=True
        self.blocked()

    def test_25_false_cryptographic_authentication_refused(self):
        self.c["cryptographically_authenticated_source_record"]=True
        self.blocked()

    def test_26_false_external_anchor_refused(self):
        self.c["external_sha256_anchor_exists"]=True
        self.blocked()

    def test_27_false_independent_source_identity_refused(self):
        self.c["independent_source_identity_proven"]=True
        self.blocked()

    def test_28_tampered_final_month_index_with_reseal_refused(self):
        self.c["synthetic_snapshot"]["month_index"]=30
        reseal_case(self.c)
        self.blocked()

    def test_29_tampered_day_count_with_reseal_refused(self):
        self.c["synthetic_snapshot"]["day_in_month"]=99
        reseal_case(self.c)
        self.blocked()

    def test_30_tampered_foundation_output_refused(self):
        self.b["historical_source_inputs"]["ADA-TELUGU"]=[5000,10,503,20,56]
        self.blocked()

    def test_31_attested_missing_field_removal_refused(self):
        self.b["real_intermediate_fields_missing"].remove("month_name_indices")
        self.blocked()

    def test_32_partial_dependency_drop_refused(self):
        self.b["field_dependencies"]["month_index"]=["month_id"]
        self.blocked()

    def test_33_case_swap_refused(self):
        self.b["cases"].reverse()
        self.blocked()

    def test_34_duplicate_case_refused(self):
        self.b["cases"][1]=copy.deepcopy(self.b["cases"][0])
        self.blocked()

    def test_35_claim_real_original_day_scope_refused(self):
        self.c["historical_foundation"]=True
        self.blocked()

    def test_36_case_event_unknown_field_refused(self):
        self.c["events"][0]["native_stdout_sha256"]="not attestable"
        self.blocked()

    def test_37_changed_status_refused(self):
        self.b["status"]="NATIVE_DATE_PASS"
        self.blocked()

    def test_38_unknown_bundle_key_refused(self):
        self.b["claimed_one_million_years"]=True
        self.blocked()

    def test_39_selector_rank_must_remain_null_synthetic(self):
        self.c["events"][3]["payload"]["global_rank_or_ada_tickets"]=1
        reseal_case(self.c)
        self.blocked()

    def test_40_synthetic_bundle_is_not_historical_native(self):
        self.assertEqual(len(self.b["cases"]),2)
        self.assertEqual(self.b["status"],STATUS)
        self.assertEqual(self.b["schema"],SCHEMA)
        self.assertIn("global_rank_or_ada_tickets",REAL_NEEDED)
        self.assertEqual(self.c["historical_original_Fct_calls"],0)


if __name__=="__main__":
    unittest.main()
