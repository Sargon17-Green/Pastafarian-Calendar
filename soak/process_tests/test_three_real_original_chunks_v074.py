"""v074: three genuinely executed original Python 2-day chunks in CrashStore.

All input is original precomputed GitHub Actions archive bytes:
v053 chunk1015, v061 chunk1016, v070 chunk1017. No F(c,t) is run here.
The candidate Kotlin whole year is not eligible to commit.
"""
from __future__ import annotations

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
from original_next_chunk_import_v066 import import_next_original_python_chunk
from original_generic_source_chunk_ledger_v073 import (
    import_generic_original_ref41_chunk,check_generic_witnesses,
    witness_paths,manifest_for,offline_original_chunk
)
from original_chunk_artifact_gate_v072 import archive_files


class ThreeActualOriginalSourceChunks(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        names=(
            "PASTAFARI_V053_REAL_ZIP",
            "PASTAFARI_V061_REAL_ZIP",
            "PASTAFARI_V070_REAL_ZIP",
            "PASTAFARI_ORIGINAL_PYTHON_ROOT",
            "PASTAFARI_ORIGINAL_KOTLIN_GIT"
        )
        v=[os.environ.get(name) for name in names]
        if any(x is None for x in v):
            raise RuntimeError("v053, v061, v070 REAL source ZIPs & two original trees mandatory")
        cls.v053=Path(v[0]).read_bytes()
        cls.v061=Path(v[1]).read_bytes()
        cls.v070=Path(v[2]).read_bytes()
        cls.source_root=Path(v[3]).resolve(strict=True)
        cls.kotlin_root=Path(v[4]).resolve(strict=True)
        cls.plan=locked_full_year_experimental_plan(
            cls.source_root,cls.kotlin_root,cls.v053)
        cls.pin,_=manifest_for(1017)
        cls.files=archive_files(cls.v070,cls.pin)

    def setUp(self):
        t=tempfile.TemporaryDirectory()
        self.addCleanup(t.cleanup)
        self.root=Path(t.name)/"soak-ledger"

    def prev(self,s):
        return import_real_original_ref41_baseline(
            s,self.v053,self.source_root,self.kotlin_root)

    def mid(self,s):
        return import_next_original_python_chunk(
            s,self.v053,self.v061,self.source_root,self.kotlin_root)

    def recent(self,s,payload=None):
        return import_generic_original_ref41_chunk(
            s,1017,self.v070 if payload is None else payload,
            self.v053,self.source_root,self.kotlin_root)

    def three(self,s):
        self.prev(s)
        self.mid(s)
        return self.recent(s)

    def test_three_frozen_real_python_chunks_original_byte_linked_in_one_year(self):
        with CrashStore(self.root,self.plan) as s:
            result=self.three(s)
            self.assertEqual(result["outcome"],"COMMITTED")
            self.assertEqual(result["ordinal"],1017)
            self.assertEqual(result["original_python_source_dates_imported"],2)
            self.assertFalse(result["candidate_kotlin_chunk_imported"])
            p=s.progress()
            self.assertEqual(p["committed_chunks"],3)
            self.assertEqual(p["native_receipt_rows_recorded_without_revalidation"],3)
            self.assertEqual(p["original_process_linked_chunks_not_years"],3)
            self.assertEqual(p["original_generic_source_witnesses_not_years"],1)
            self.assertEqual(p["original_next_source_witnesses_not_years"],1)
            self.assertEqual(p["quarantined_two_day_pilot_records_not_year_chunks"],1)
            self.assertEqual(p["verified_comparisons_completed"],0)
            self.assertEqual(p["verified_day_pair_comparisons"],0)
            self.assertEqual(p["fully_verified_years"],0)
            self.assertEqual(p["original_native_full_year_soak_passes_certified"],0)
            self.assertFalse(p["independent_source_lineage_certified"])
            self.assertFalse(p["all_verified"])
            self.assertEqual(check_generic_witnesses(s),1)
            self.assertEqual(check_original_process_chunk_links(s),3)
            chunk=s._chunk("REF-41","5000",1017)
            self.assertEqual((chunk.first_day,chunk.last_day),
                             ("-15055668","-15055667"))
            self.assertEqual(s._chunk_path(chunk).read_bytes(),
                             self.files["REF-41/native-normalized.jsonl"])
            self.assertEqual(len(s.expected_chunks("REF-41","5000")),2122)

    def test_offline_crash_recovery_rechecks_all_three_source_links(self):
        with CrashStore(self.root,self.plan) as s:
            self.three(s)
        with patch("original_generic_source_chunk_ledger_v073.audit_pinned_original_chunk",
                   side_effect=AssertionError("should not reexecute source audit on recovery")):
            with CrashStore(self.root,self.plan) as s:
                v=s.verify_and_recover()
                self.assertEqual(v["original_generic_source_witnesses_revalidated"],1)
                self.assertEqual(v["original_source_process_chunk_links_revalidated"],3)
                self.assertEqual(v["verified_existing_chunks"],3)
                self.assertEqual(v["recovered_chunks"],0)
                self.assertEqual(v["progress"]["fully_verified_years"],0)

    def test_duplicate_original_third_ZIP_is_idempotent(self):
        with CrashStore(self.root,self.plan) as s:
            self.three(s)
            r=self.recent(s)
            self.assertEqual(r["outcome"],"ALREADY_COMMITTED")
            self.assertEqual(s.progress()["committed_chunks"],3)
            self.assertEqual(s.progress()["original_process_linked_chunks_not_years"],3)

    def test_new_chunk_cannot_leapfrog_missing_original_mid_source(self):
        with CrashStore(self.root,self.plan) as s:
            self.prev(s)
            with self.assertRaisesRegex(ValueError,"cannot leap"):
                self.recent(s)
            self.assertEqual(s.progress()["committed_chunks"],1)

    def test_changed_original_v070_ZIP_refused_before_new_chunk(self):
        altered=self.v070[:-1]+bytes([self.v070[-1]^0x01])
        with CrashStore(self.root,self.plan) as s:
            self.prev(s);self.mid(s)
            with self.assertRaises(ValueError):
                self.recent(s,altered)
            self.assertEqual(s.progress()["committed_chunks"],2)
            self.assertEqual(s.progress()["original_process_linked_chunks_not_years"],2)

    def test_Kotlin_original_candidate_cannot_commit_before_full_Python_year(self):
        with CrashStore(self.root,self.plan) as s:
            self.three(s)
            chunk=s._chunk("PROD-KT-CY","5000",1017)
            norm=self.files["kotlin-index-only-normalized.jsonl"]
            raw=self.files["PROD-KT-CY/os-stdout.tsv"]
            receipt=make_receipt(s.plan,s.plan_sha,"PROD-KT-CY","5000",
                                 chunk.first_day,chunk.last_day,1017,norm,raw)
            with self.assertRaisesRegex(ValueError,"complete previous engine year"):
                s.commit_chunk("PROD-KT-CY","5000",1017,norm,
                               raw_stdout=raw,native_receipt=receipt)
            self.assertEqual(s.progress()["committed_chunks"],3)

    def test_tampered_archived_original_ZIP_blocks_source_recovery(self):
        with CrashStore(self.root,self.plan) as s:
            self.three(s)
            _,_,zip_path,_=witness_paths(s,1017,self.pin)
        zip_path.write_bytes(zip_path.read_bytes()+b"CORRUPTION")
        with CrashStore(self.root,self.plan) as s:
            with self.assertRaises(ValueError):
                s.verify_and_recover()
            self.assertEqual(s.progress()["original_native_full_year_soak_passes_certified"],0)

    def test_missing_process_link_blocks_recovery_explicit_replay_repairs_only_it(self):
        with CrashStore(self.root,self.plan) as s:
            self.three(s)
            s.db.execute("DELETE FROM original_process_chunk_links "
                         "WHERE engine='REF-41' AND year='5000' AND ordinal=1017")
            with self.assertRaisesRegex(ValueError,"lost original process ZIP link"):
                s.verify_and_recover()
        with CrashStore(self.root,self.plan) as s:
            r=self.recent(s)
            self.assertEqual(r["outcome"],"ALREADY_COMMITTED")
            self.assertEqual(s.verify_and_recover()["original_source_process_chunk_links_revalidated"],3)
            self.assertEqual(s.progress()["fully_verified_years"],0)

    def test_corrupted_source_process_link_digest_fails_closed(self):
        with CrashStore(self.root,self.plan) as s:
            self.three(s)
            s.db.execute(
                "UPDATE original_process_chunk_links SET native_raw_sha256=? "
                "WHERE engine='REF-41' AND year='5000' AND ordinal=1017",
                ("0"*64,))
            with self.assertRaisesRegex(ValueError,"checksum altered"):
                s.verify_and_recover()

    def test_registered_source_report_deleted_not_silently_healed(self):
        with CrashStore(self.root,self.plan) as s:
            self.three(s)
            _,_,_,report=witness_paths(s,1017,self.pin)
        report.unlink()
        with CrashStore(self.root,self.plan) as s:
            with self.assertRaises(ValueError):
                s.verify_and_recover()
            with self.assertRaises(ValueError):
                self.recent(s)

    def test_orphan_generic_zip_part_rejected_until_explicit_replay(self):
        with CrashStore(self.root,self.plan) as s:
            self.prev(s);self.mid(s)
            _,folder,archive,_=witness_paths(s,1017,self.pin)
            folder.mkdir(parents=True)
            orphan=archive.with_name(archive.name+".part")
            orphan.write_bytes(self.v070)
            with self.assertRaisesRegex(ValueError,"unindexed"):
                s.verify_and_recover()
            self.assertEqual(s.progress()["committed_chunks"],2)
            self.recent(s)
            self.assertEqual(s.verify_and_recover()["original_generic_source_witnesses_revalidated"],1)

    def test_offline_integrity_distinct_from_lineage_proof(self):
        result=offline_original_chunk(self.v070,self.pin)
        self.assertEqual(result["ordinal"],1017)
        self.assertEqual(result["original_native_date_pairs"],2)
        self.assertFalse(result["source_lineage_certified"])
        self.assertFalse(result["canonical_oracle_certified"])
        self.assertFalse(result["independently_attested_OS_process"])
        self.assertEqual(result["original_full_years_certified"],0)


if __name__=="__main__":
    unittest.main()
