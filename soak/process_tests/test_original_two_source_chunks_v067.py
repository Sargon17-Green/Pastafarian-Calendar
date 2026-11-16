"""v067: TWO real unchanged source chunks in the full 4244-day year ledger.

Requires v053 and v061 original GitHub Actions ZIPs + both frozen original
source git checkouts. No F(c,t) computation in this integration suite.
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
from recovery_store import CrashStore
from native_execution_receipt_v038 import make_receipt
from original_ref41_year_chunk_import_v059 import (
    locked_full_year_experimental_plan,import_real_original_ref41_baseline,
    check_original_process_chunk_links
)
from original_next_chunk_import_v066 import (
    import_next_original_python_chunk,check_registered_next_chunk_witnesses,
    paths,offline_receipt
)
from verify_next_original_chunk_v065 import frozen_pin,original_files


class TwoAuthenticOriginalSourceChunksTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        fields=["PASTAFARI_V053_REAL_ZIP","PASTAFARI_V061_REAL_ZIP",
                "PASTAFARI_ORIGINAL_PYTHON_ROOT","PASTAFARI_ORIGINAL_KOTLIN_GIT"]
        values=[os.environ.get(k) for k in fields]
        if any(not x for x in values):
            raise RuntimeError("both original process artifacts and source trees mandatory")
        cls.v053=Path(values[0]).read_bytes()
        cls.v061=Path(values[1]).read_bytes()
        cls.sources=Path(values[2]).resolve(strict=True)
        cls.kotlin=Path(values[3]).resolve(strict=True)
        cls.plan=locked_full_year_experimental_plan(cls.sources,cls.kotlin,cls.v053)
        cls.blobs=original_files(cls.v061,frozen_pin())

    def setUp(self):
        t=tempfile.TemporaryDirectory()
        self.addCleanup(t.cleanup)
        self.root=Path(t.name)/"year"

    def prev(self,store):
        return import_real_original_ref41_baseline(
            store,self.v053,self.sources,self.kotlin)

    def next(self,store,archive=None):
        return import_next_original_python_chunk(
            store,self.v053,self.v061 if archive is None else archive,
            self.sources,self.kotlin)

    def test_two_true_python_original_source_chunks_import_without_year_certificate(self):
        with CrashStore(self.root,self.plan) as store:
            self.assertEqual(self.prev(store)["outcome"],"COMMITTED")
            r=self.next(store)
            self.assertEqual(r["outcome"],"COMMITTED")
            self.assertEqual(r["chunk_ordinal"],1016)
            self.assertEqual(r["reference_original_source_rows"],2)
            self.assertFalse(r["kotlin_candidate_chunk_committed"])
            p=store.progress()
            self.assertEqual(p["committed_chunks"],2)
            self.assertEqual(p["original_process_linked_chunks_not_years"],2)
            self.assertEqual(p["original_next_source_witnesses_not_years"],1)
            self.assertEqual(p["native_receipt_rows_recorded_without_revalidation"],2)
            self.assertEqual(p["verified_comparisons_completed"],0)
            self.assertEqual(p["verified_day_pair_comparisons"],0)
            self.assertEqual(p["fully_verified_years"],0)
            self.assertEqual(p["original_native_full_year_soak_passes_certified"],0)
            self.assertFalse(p["independent_source_lineage_certified"])
            self.assertFalse(p["all_verified"])
            self.assertEqual(check_registered_next_chunk_witnesses(store),1)
            self.assertEqual(check_original_process_chunk_links(store),2)
            chunk=store._chunk("REF-41","5000",1016)
            self.assertEqual((chunk.first_day,chunk.last_day),
                             ("-15055670","-15055669"))
            self.assertEqual(store._chunk_path(chunk).read_bytes(),
                             self.blobs["REF-41/native-normalized.jsonl"])
            self.assertEqual(len(store.expected_chunks("REF-41","5000")),2122)

    def test_closed_source_recovery_rechecks_both_original_process_links(self):
        with CrashStore(self.root,self.plan) as store:
            self.prev(store);self.next(store)
        with patch("original_next_chunk_import_v066.audit_next_two_original_dates",
                   side_effect=AssertionError("source audit unexpectedly launched in offline recovery")):
            with CrashStore(self.root,self.plan) as store:
                r=store.verify_and_recover()
                self.assertEqual(r["original_next_chunk_witnesses_revalidated"],1)
                self.assertEqual(r["original_source_process_chunk_links_revalidated"],2)
                self.assertEqual(r["verified_existing_chunks"],2)
                self.assertEqual(r["recovered_chunks"],0)
                self.assertEqual(r["progress"]["fully_verified_years"],0)

    def test_exact_source_ZIP_replay_is_idempotent(self):
        with CrashStore(self.root,self.plan) as store:
            self.prev(store);self.next(store)
            second=self.next(store)
            self.assertEqual(second["outcome"],"ALREADY_COMMITTED")
            self.assertEqual(store.progress()["committed_chunks"],2)
            self.assertEqual(store.progress()["original_process_linked_chunks_not_years"],2)

    def test_next_chunk_cannot_run_before_previous_source_link(self):
        with CrashStore(self.root,self.plan) as store:
            with self.assertRaisesRegex(ValueError,"cannot precede"):
                self.next(store)
            self.assertEqual(store.progress()["committed_chunks"],0)

    def test_modified_source_next_original_zip_rejected_before_new_commit(self):
        modified=self.v061[:-1]+bytes([self.v061[-1]^0x01])
        with CrashStore(self.root,self.plan) as store:
            self.prev(store)
            with self.assertRaises(ValueError):
                self.next(store,modified)
            self.assertEqual(store.progress()["committed_chunks"],1)
            self.assertEqual(store.progress()["original_process_linked_chunks_not_years"],1)

    def test_Kotlin_cannot_commit_candidate_source_chunk_before_4244_Python_days(self):
        with CrashStore(self.root,self.plan) as store:
            self.prev(store);self.next(store)
            chunk=store._chunk("PROD-KT-CY","5000",1016)
            norm=self.blobs["kotlin-index-only-normalized.jsonl"]
            raw=self.blobs["PROD-KT-CY/os-stdout.tsv"]
            receipt=make_receipt(store.plan,store.plan_sha,"PROD-KT-CY","5000",
                                 chunk.first_day,chunk.last_day,chunk.ordinal,norm,raw)
            with self.assertRaisesRegex(ValueError,"complete previous engine year"):
                store.commit_chunk("PROD-KT-CY","5000",1016,norm,
                                   raw_stdout=raw,native_receipt=receipt)
            self.assertEqual(store.progress()["committed_chunks"],2)

    def test_tampered_new_zip_file_after_commit_breaks_recovery_without_healing(self):
        with CrashStore(self.root,self.plan) as store:
            self.prev(store);self.next(store)
            _,original,_=paths(store)
        original.write_bytes(original.read_bytes()+b"TAMPER")
        with CrashStore(self.root,self.plan) as store:
            with self.assertRaises(ValueError):
                store.verify_and_recover()
            self.assertEqual(store.progress()["fully_verified_years"],0)

    def test_lost_source_process_link_detected_and_explicit_replay_repairs(self):
        with CrashStore(self.root,self.plan) as store:
            self.prev(store);self.next(store)
            store.db.execute(
                "DELETE FROM original_process_chunk_links WHERE engine='REF-41' "
                "AND year='5000' AND ordinal=1016")
            with self.assertRaisesRegex(ValueError,"lost process ZIP link"):
                store.verify_and_recover()
        with CrashStore(self.root,self.plan) as store:
            self.assertEqual(self.next(store)["outcome"],"ALREADY_COMMITTED")
            self.assertEqual(store.verify_and_recover()["original_source_process_chunk_links_revalidated"],2)
            self.assertEqual(store.progress()["fully_verified_years"],0)

    def test_changed_original_process_link_digest_fails_closed(self):
        with CrashStore(self.root,self.plan) as store:
            self.prev(store);self.next(store)
            store.db.execute(
                "UPDATE original_process_chunk_links SET process_receipt_sha256=? "
                "WHERE engine='REF-41' AND year='5000' AND ordinal=1016",
                ("f"*64,))
            with self.assertRaisesRegex(ValueError,"link SHA differs"):
                store.verify_and_recover()

    def test_next_witness_part_file_requires_explicit_replay(self):
        with CrashStore(self.root,self.plan) as store:
            self.prev(store)
            root,original,_=paths(store)
            root.mkdir(parents=True)
            stage=original.with_name(original.name+".part")
            stage.write_bytes(self.v061)
            with self.assertRaisesRegex(ValueError,"unindexed"):
                store.verify_and_recover()
            self.assertEqual(store.progress()["committed_chunks"],1)
            self.next(store)
            self.assertEqual(store.verify_and_recover()["original_next_chunk_witnesses_revalidated"],1)

    def test_offline_witness_does_not_certify_source_lineage_or_year(self):
        r=offline_receipt(self.v061)
        self.assertEqual(r["status"],"TWO_ORIGINAL_SOURCE_DAYS_INTEGRITY_ONLY")
        self.assertFalse(r["source_lineage_certified"])
        self.assertFalse(r["host_process_attested"])
        self.assertFalse(r["canonical_oracle_certified"])
        self.assertEqual(r["original_years_certified"],0)

if __name__=="__main__":
    unittest.main()
