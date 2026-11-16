"""v059 REAL pinned original Python two-day source -> full 4244-day CrashStore.

The v053 ZIP and original checked-out git commits are REQUIRED.
No F(c,t) execution. A chunk can be *technically* stored only as an
un-certified source observation; independent canonical / lineage approval
remains explicitly false.
"""
from __future__ import annotations

import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
from original_ref41_year_chunk_import_v059 import (
    ARCHIVE_SHA,ENGINE,YEAR,FIRST,LAST,CHUNK_ORDINAL,
    locked_full_year_experimental_plan,
    import_real_original_ref41_baseline,
    check_original_process_chunk_links,
)
from verify_original_two_day_artifact_v055 import load_zip
from native_execution_receipt_v038 import make_receipt
from recovery_store import CrashStore


class RealOriginalSourceChunkLedgerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        paths=[os.environ.get(k) for k in (
            "PASTAFARI_V053_REAL_ZIP",
            "PASTAFARI_ORIGINAL_PYTHON_ROOT",
            "PASTAFARI_ORIGINAL_KOTLIN_GIT",
        )]
        if not all(paths):
            raise RuntimeError("real v053 ZIP and both locked source checkouts are mandatory")
        cls.zip_path=Path(paths[0])
        cls.sources=Path(paths[1]).resolve(strict=True)
        cls.kotlin=Path(paths[2]).resolve(strict=True)
        cls.zip_bytes=cls.zip_path.read_bytes()
        cls.plan=locked_full_year_experimental_plan(cls.sources,cls.kotlin,cls.zip_bytes)
        cls.files=load_zip(cls.zip_bytes)

    def setUp(self):
        t=tempfile.TemporaryDirectory()
        self.addCleanup(t.cleanup)
        self.root=Path(t.name)/"year-ledger"

    def import_ref(self,store,payload=None):
        return import_real_original_ref41_baseline(
            store,self.zip_bytes if payload is None else payload,
            self.sources,self.kotlin,expected_sha256=ARCHIVE_SHA)

    def test_actual_original_two_dates_attached_to_one_of_2122_reference_chunks(self):
        with CrashStore(self.root,self.plan) as store:
            chunk=store._chunk(ENGINE,YEAR,CHUNK_ORDINAL)
            self.assertEqual((chunk.first_day,chunk.last_day),(FIRST,LAST))
            self.assertEqual(len(store.expected_chunks(ENGINE,YEAR)),2122)
            self.assertEqual(len(store.expected_chunks("PROD-KT-CY",YEAR)),2122)
            x=self.import_ref(store)
            self.assertEqual(x["outcome"],"COMMITTED")
            self.assertEqual(x["source_process_link_rows_verified"],1)
            self.assertEqual(x["reference_original_rows_committed"],2)
            self.assertEqual(x["reference_original_year_days_planned"],4244)
            self.assertFalse(x["candidate_kotlin_year_chunk_committed"])
            p=store.progress()
            self.assertEqual(p["committed_chunks"],1)
            self.assertEqual(p["original_process_linked_chunks_not_years"],1)
            self.assertEqual(p["quarantined_two_day_pilot_records_not_year_chunks"],1)
            self.assertEqual(p["native_receipt_rows_recorded_without_revalidation"],1)
            self.assertEqual(p["verified_day_pair_comparisons"],0)
            self.assertEqual(p["verified_comparisons_completed"],0)
            self.assertEqual(p["fully_verified_years"],0)
            self.assertEqual(p["original_native_full_year_soak_passes_certified"],0)
            self.assertFalse(p["all_verified"])
            self.assertFalse(p["independent_source_lineage_certified"])
            self.assertEqual(check_original_process_chunk_links(store),1)
            path=store._chunk_path(chunk)
            self.assertEqual(path.read_bytes(),self.files["REF-41/native-normalized.jsonl"])
            raw,_=store._native_receipt_paths(chunk)
            self.assertEqual(raw.read_bytes(),self.files["REF-41/native-raw.jsonl"])

    def test_recovery_rechecks_source_process_link_without_original_checkout(self):
        with CrashStore(self.root,self.plan) as store:
            self.import_ref(store)
        with patch("original_ref41_year_chunk_import_v059.replay_native_witness",
                   side_effect=AssertionError("original source replay invoked during recovery")):
            with CrashStore(self.root,self.plan) as store:
                v=store.verify_and_recover()
                self.assertEqual(v["original_source_process_chunk_links_revalidated"],1)
                self.assertEqual(v["quarantined_two_day_pilots_revalidated"],1)
                self.assertEqual(v["verified_existing_chunks"],1)
                self.assertEqual(v["recovered_chunks"],0)
                self.assertEqual(v["progress"]["fully_verified_years"],0)

    def test_reimport_same_real_artifact_is_idempotent(self):
        with CrashStore(self.root,self.plan) as store:
            self.assertEqual(self.import_ref(store)["outcome"],"COMMITTED")
            r=self.import_ref(store)
            self.assertEqual(r["outcome"],"ALREADY_COMMITTED")
            self.assertEqual(store.progress()["original_process_linked_chunks_not_years"],1)
            self.assertEqual(store.progress()["committed_chunks"],1)

    def test_candidate_not_admitted_until_entire_original_reference_year(self):
        with CrashStore(self.root,self.plan) as store:
            self.import_ref(store)
            kt_norm=self.files["kotlin-index-only-normalized.jsonl"]
            kt_raw=self.files["PROD-KT-CY/os-stdout.tsv"]
            kt_chunk=store._chunk("PROD-KT-CY",YEAR,CHUNK_ORDINAL)
            kt_receipt=make_receipt(store.plan,store.plan_sha,"PROD-KT-CY",YEAR,
                                    kt_chunk.first_day,kt_chunk.last_day,
                                    kt_chunk.ordinal,kt_norm,kt_raw)
            with self.assertRaisesRegex(ValueError,"complete previous engine year"):
                store.commit_chunk("PROD-KT-CY",YEAR,CHUNK_ORDINAL,kt_norm,
                                   raw_stdout=kt_raw,native_receipt=kt_receipt)
            self.assertEqual(store.progress()["committed_chunks"],1)
            self.assertEqual(store.progress()["verified_day_pair_comparisons"],0)

    def test_zip_mutation_is_rejected_before_any_baseline_commit(self):
        bad=self.zip_bytes[:-1]+bytes([self.zip_bytes[-1]^0x01])
        with CrashStore(self.root,self.plan) as store:
            with self.assertRaises(ValueError):
                self.import_ref(store,bad)
            self.assertEqual(store.progress()["committed_chunks"],0)
            self.assertEqual(store.progress()["original_process_linked_chunks_not_years"],0)

    def test_modified_source_binary_in_plan_rejected_with_no_technical_credit(self):
        plan=json.loads(json.dumps(self.plan))
        plan["engines"][0]["binary_sha256"]="a"*64
        with CrashStore(self.root,plan) as store:
            with self.assertRaisesRegex(ValueError,"plan differs"):
                self.import_ref(store)
            self.assertEqual(store.progress()["committed_chunks"],0)

    def test_changed_year_boundaries_rejected_even_if_both_date_rows_in_year(self):
        plan=json.loads(json.dumps(self.plan))
        plan["years"][0]["last_target_day"]="-15053460"
        with CrashStore(self.root,plan) as store:
            with self.assertRaisesRegex(ValueError,"plan differs"):
                self.import_ref(store)
            self.assertEqual(store.progress()["committed_chunks"],0)

    def test_changed_chunk_length_rejected_without_silent_resegmentation(self):
        plan=json.loads(json.dumps(self.plan))
        plan["chunk_days"]=1
        with CrashStore(self.root,plan) as store:
            with self.assertRaisesRegex(ValueError,"plan differs"):
                self.import_ref(store)
            self.assertEqual(store.progress()["committed_chunks"],0)

    def test_changed_calculation_day_rejected(self):
        plan=json.loads(json.dumps(self.plan))
        plan["calculation_day"]="-15055672"
        with CrashStore(self.root,plan) as store:
            with self.assertRaisesRegex(ValueError,"plan differs"):
                self.import_ref(store)
            self.assertEqual(store.progress()["committed_chunks"],0)

    def test_original_raw_receipt_corruption_fails_recovery_before_adoption(self):
        with CrashStore(self.root,self.plan) as store:
            self.import_ref(store)
            chunk=store._chunk(ENGINE,YEAR,CHUNK_ORDINAL)
            raw,_=store._native_receipt_paths(chunk)
        raw.write_bytes(raw.read_bytes().replace(b"Akrep",b"FAKEK"))
        with CrashStore(self.root,self.plan) as store:
            with self.assertRaises(ValueError):
                store.verify_and_recover()

    def test_changed_process_link_sqlite_checksum_rejected(self):
        with CrashStore(self.root,self.plan) as store:
            self.import_ref(store)
            store.db.execute(
                "UPDATE original_process_chunk_links SET process_receipt_sha256=?",
                ("0"*64,))
            with self.assertRaisesRegex(ValueError,"link mutated"):
                store.verify_and_recover()

    def test_original_process_link_zero_if_link_row_removed_no_false_attestation(self):
        with CrashStore(self.root,self.plan) as store:
            self.import_ref(store)
            store.db.execute(
                "DELETE FROM original_process_chunk_links WHERE engine=? AND year=? AND ordinal=?",
                (ENGINE,YEAR,CHUNK_ORDINAL))
            p=store.progress()
            self.assertEqual(p["original_process_linked_chunks_not_years"],0)
            self.assertFalse(p["native_receipt_execution_attestation_verified"])
            self.assertEqual(p["original_native_full_year_soak_passes_certified"],0)

    def test_missing_quarantine_original_zip_blocks_source_link_recovery(self):
        from quarantined_two_day_pilot_v057 import get_paths
        with CrashStore(self.root,self.plan) as store:
            self.import_ref(store)
            _,path,_=get_paths(store)
        path.unlink()
        with CrashStore(self.root,self.plan) as store:
            with self.assertRaises(ValueError):
                store.verify_and_recover()

    def test_plan_cannot_relabel_source_as_independent_oracle(self):
        with CrashStore(self.root,self.plan) as store:
            self.import_ref(store)
            p=store.progress()
            self.assertFalse(p["independent_source_lineage_certified"])
            self.assertEqual(p["original_native_full_year_soak_passes_certified"],0)
            self.assertTrue(p["technical_comparisons_only"])
            self.assertEqual(p["verified_comparisons_completed"],0)

if __name__=="__main__":
    unittest.main()
