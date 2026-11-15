"""v051: actual 4244-day immutable plan, only ONE 2-day synthetic chunk.

Proves no accidental full-year credit and that baseline must be completed
BEFORE any second-engine chunk can be registered. No native F(c,t) is run.
"""
from __future__ import annotations

import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
sys.path.insert(0,str(Path(__file__).resolve().parent))
from test_original_bounded_chunk_gate_v050 import fixtures
from original_bounded_chunk_gate_v050 import (
    BOUNDARY_SHA,C,YEAR,verify_bounded_original_chunk,
)
from native_execution_receipt_v038 import make_receipt
from recovery_store import CrashStore
from source_identity_gate_v036 import PROVENANCE_CONTRACT,IDENTITY_SCHEMA

START="-15055672"
END="-15055671"
ORDINAL=1015


def synthetic_full_year_plan():
    def e(engine_id,cls,source,exe,commit,family):
        return {
            "id":engine_id,"algorithm_id":family,
            "source_sha256":source*64,"binary_sha256":exe*64,
            "name_map_sha256":"b"*64,
            "provenance":{
                "schema":IDENTITY_SCHEMA,
                "source_class":cls,"source_commit":commit*40,
                "repository":"Sargon17-Green/Pastafarian-Calendar",
                "source_path":"tests/"+engine_id+".synthetic",
                "source_family":family,
                "native_entrypoint":"synthetic_Fct(c,t)",
                "execution_method":("unchanged_reference_Fct" if cls=="reference"
                                   else "unchanged_original_Fct"),
                "derived_from":None,
                "original_source_sha256":source*64,
            },
        }
    return {
        "contract":PROVENANCE_CONTRACT,
        "identity_contract":IDENTITY_SCHEMA,
        "soak_purpose":"EXPERIMENTAL_NATIVE_DIFFERENTIAL_UNCERTIFIED",
        "independence_audit_status":"NOT_CERTIFIED",
        "calculation_day":C,"chunk_days":2,
        "years":[{
            "year":YEAR,
            "first_target_day":"-15057702",
            "last_target_day":"-15053459",
            "boundary_evidence_sha256":BOUNDARY_SHA,
        }],
        "engines":[e("REF-41","reference","1","a","1","synthetic-py-unique"),
                   e("PROD-KT-CY","original","2","c","2","synthetic-kt-unique")],
    }


class OriginalBoundedChunkLedgerIntegrationTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.ledger=Path(self.tmp.name)/"ledger"
        self.plan=synthetic_full_year_plan()
        self.fake=fixtures(2,start=-15055672)
        self.result=verify_bounded_original_chunk(**self.fake)
        self.assertEqual(self.result["status"],"BOUNDED_ORIGINAL_CHUNK_MATCH_NOT_FULL_YEAR")
        self.assertEqual(self.result["matched_original_day_pairs"],2)

    def store_source(self,store,engine,normalized,raw):
        chunk=store._chunk(engine,YEAR,ORDINAL)
        self.assertEqual((chunk.first_day,chunk.last_day),(START,END))
        receipt=make_receipt(
            store.plan,store.plan_sha,engine,YEAR,
            chunk.first_day,chunk.last_day,chunk.ordinal,normalized,raw)
        return store.commit_chunk(
            engine,YEAR,ORDINAL,normalized,raw_stdout=raw,native_receipt=receipt)

    def test_source_replay_and_candidate_order_preserved(self):
        with CrashStore(self.ledger,self.plan) as store:
            py=self.store_source(store,"REF-41",
                self.fake["python_original_normalized"],
                self.fake["python_original_raw"])
            self.assertEqual(py,"COMMITTED")
            out=store.progress()
            self.assertEqual(out["native_receipt_rows_recorded_without_revalidation"],1)
            self.assertEqual(out["committed_chunks"],1)
            self.assertEqual(out["verified_comparisons_completed"],0)
            self.assertEqual(out["fully_verified_years"],0)
            self.assertFalse(out["all_verified"])
            self.assertEqual(out["original_native_full_year_soak_passes_certified"],0)
            with self.assertRaisesRegex(ValueError,"complete previous engine year"):
                self.store_source(
                    store,"PROD-KT-CY",
                    self.result["kotlin_index_only_normalized_jsonl"],
                    self.fake["kotlin_original_stdout"])
            self.assertEqual(store.progress()["committed_chunks"],1)
        with CrashStore(self.ledger,self.plan) as store:
            recovered=store.verify_and_recover()
            self.assertEqual(recovered["verified_existing_chunks"],1)
            self.assertEqual(recovered["recovered_chunks"],0)
            self.assertEqual(recovered["progress"]["verified_day_pair_comparisons"],0)

    def test_exact_synthetic_baseline_chunk_replay_idempotent(self):
        with CrashStore(self.ledger,self.plan) as store:
            payload=self.fake["python_original_normalized"]
            raw=self.fake["python_original_raw"]
            self.assertEqual(self.store_source(store,"REF-41",payload,raw),"COMMITTED")
            self.assertEqual(self.store_source(store,"REF-41",payload,raw),"ALREADY_COMMITTED")
            self.assertEqual(store.progress()["committed_chunks"],1)

    def test_corrupt_raw_evidence_blocked_on_recovery(self):
        with CrashStore(self.ledger,self.plan) as store:
            self.store_source(store,"REF-41",
                self.fake["python_original_normalized"],
                self.fake["python_original_raw"])
            chunk=store._chunk("REF-41",YEAR,ORDINAL)
            raw_path,_=store._native_receipt_paths(chunk)
        raw_path.write_bytes(raw_path.read_bytes().replace(b"Akrep",b"FAKE"))
        with CrashStore(self.ledger,self.plan) as store:
            with self.assertRaises(ValueError):
                store.verify_and_recover()

    def test_mismatch_gate_provides_no_kotlin_commit_payload(self):
        tamper=dict(self.fake)
        tamper["kotlin_original_stdout"]=tamper["kotlin_original_stdout"].replace(
            b"\t503\t20\t56\n",b"\t503\t21\t56\n")
        status=verify_bounded_original_chunk(**tamper)
        self.assertEqual(status["status"],"ORIGINAL_NATIVE_FIRST_MISMATCH_HALT")
        self.assertTrue(status["halt_new_dispatch"])
        self.assertEqual(status["matched_original_day_pairs"],1)
        self.assertIsNone(status["kotlin_index_only_normalized_jsonl"])
        with CrashStore(self.ledger,self.plan) as store:
            self.assertEqual(store.progress()["committed_chunks"],0)
            self.assertEqual(store.progress()["original_native_full_year_soak_passes_certified"],0)

    def test_all_4244_original_dates_are_required_for_full_year(self):
        with CrashStore(self.ledger,self.plan) as store:
            self.assertEqual(len(store.expected_chunks("REF-41",YEAR)),2122)
            self.assertEqual(len(store.expected_chunks("PROD-KT-CY",YEAR)),2122)
            self.store_source(store,"REF-41",
                self.fake["python_original_normalized"],
                self.fake["python_original_raw"])
            self.assertEqual(store.progress()["fully_verified_years"],0)
            self.assertEqual(store.progress()["quarantined_pilot_records_not_year_chunks"],0)
            self.assertFalse(store.progress()["independent_source_lineage_certified"])

if __name__=="__main__":
    unittest.main()
