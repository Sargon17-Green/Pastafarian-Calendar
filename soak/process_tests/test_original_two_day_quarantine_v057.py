"""v057: REAL pinned v053 two-day original source ZIP into quarantined ledger.

No F(c,t) is executed. The real GitHub Actions artifact and unchanged original
source git checkouts are mandatory. All checks fail closed; no partial-year
native-soak credit. Do not replace with synthetic evidence.
"""
from __future__ import annotations

from io import BytesIO
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
from recovery_store import CrashStore
from quarantined_two_day_pilot_v057 import (
    ARCHIVE_SHA,SCHEMA, register_two_day_pilot,check_registered_two_day_pilots,
    frozen_offline_recheck,get_paths,digest
)
from verify_original_two_day_artifact_v055 import load_zip
from native_execution_receipt_v038 import canonical

# Reuse exactly the v2 original source plan shape already accepted in v048,
# substituting binaries/bridge source hashes from the real v053 receipt.
from test_quarantined_actual_pilot_v048 import make_plan


class RealOriginalTwoDayQuarantineTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        f=os.environ.get("PASTAFARI_V053_REAL_ZIP")
        source=os.environ.get("PASTAFARI_ORIGINAL_PYTHON_ROOT")
        kotlin=os.environ.get("PASTAFARI_ORIGINAL_KOTLIN_GIT")
        if not all([f,source,kotlin]):
            raise RuntimeError("real v053 artifact and both original source roots are REQUIRED")
        cls.real=Path(f).read_bytes()
        cls.sources=Path(source).resolve(strict=True)
        cls.kotlin=Path(kotlin).resolve(strict=True)
        if digest(cls.real)!=ARCHIVE_SHA:
            raise RuntimeError("original v053 ZIP not the pinned bytes")
        files=load_zip(cls.real)
        py=json.loads(files["REF-41/process-evidence.json"])
        kt=json.loads(files["PROD-KT-CY/process-evidence.json"])
        bridge=[x["sha256"] for x in kt["source_inventory"]
                if x["path"]=="soak/Post55ProductionDateBridge.kt"]
        if len(bridge)!=1:
            raise RuntimeError("Kotlin original bridge absent from source closure")
        cls.plan=make_plan({
            "original_python_interpreter_sha256":py["runtime_sha256"],
            "original_kotlin_bridge_source_sha256":bridge[0],
            "original_kotlin_jar_sha256":kt["compiled_original_jar_sha256"],
        })
        cls.offline=frozen_offline_recheck(cls.real)

    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)/"ledger"

    def ingest(self,store,payload=None):
        return store.record_quarantined_original_two_day_pilot(
            self.real if payload is None else payload,
            self.sources,self.kotlin,expected_sha256=ARCHIVE_SHA)

    def test_actual_two_day_original_artifact_isolated_no_year_chunk(self):
        with CrashStore(self.root,self.plan) as store:
            before=store.progress()
            self.assertEqual(before["quarantined_two_day_pilot_records_not_year_chunks"],0)
            result=self.ingest(store)
            self.assertEqual(result["outcome"],"QUARANTINED_TWO_DAY_PILOT_RECORDED")
            self.assertEqual(result["original_native_day_pairs"],2)
            after=store.progress()
            self.assertEqual(after["quarantined_two_day_pilot_records_not_year_chunks"],1)
            self.assertEqual(after["quarantined_pilot_records_not_year_chunks"],0)
            self.assertEqual(after["committed_chunks"],0)
            self.assertEqual(after["verified_comparisons_completed"],0)
            self.assertEqual(after["verified_day_pair_comparisons"],0)
            self.assertEqual(after["fully_verified_years"],0)
            self.assertEqual(after["original_native_full_year_soak_passes_certified"],0)
            self.assertFalse(after["all_verified"])
            self.assertEqual(check_registered_two_day_pilots(store),1)
        with CrashStore(self.root,self.plan) as store:
            verdict=store.verify_and_recover()
            self.assertEqual(verdict["quarantined_two_day_pilots_revalidated"],1)
            self.assertEqual(verdict["verified_existing_chunks"],0)
            self.assertEqual(verdict["recovered_chunks"],0)
            self.assertEqual(verdict["progress"]["committed_chunks"],0)

    def test_byte_identical_replay_idempotent(self):
        with CrashStore(self.root,self.plan) as store:
            self.ingest(store)
            second=self.ingest(store)
            self.assertEqual(second["outcome"],"ALREADY_RECORDED")
            self.assertEqual(store.progress()["quarantined_two_day_pilot_records_not_year_chunks"],1)
            self.assertEqual(store.progress()["fully_verified_years"],0)

    def test_zip_byte_mutation_cannot_register(self):
        tampered=self.real[:-1]+bytes([self.real[-1]^1])
        with CrashStore(self.root,self.plan) as store:
            with self.assertRaises(ValueError):
                self.ingest(store,tampered)
            self.assertEqual(store.progress()["quarantined_two_day_pilot_records_not_year_chunks"],0)

    def test_committed_archive_tamper_detected_before_any_chunk_recovery(self):
        with CrashStore(self.root,self.plan) as store:
            self.ingest(store)
            _,archive,_=get_paths(store)
        archive.write_bytes(archive.read_bytes()+b"forged data")
        with CrashStore(self.root,self.plan) as store:
            with self.assertRaisesRegex(ValueError,"corrupt"):
                store.verify_and_recover()
            with self.assertRaises(ValueError):
                self.ingest(store)
        self.assertNotEqual(digest(archive.read_bytes()),ARCHIVE_SHA)

    def test_missing_committed_report_not_recreated_on_replay(self):
        with CrashStore(self.root,self.plan) as store:
            self.ingest(store)
            _,_,report=get_paths(store)
        report.unlink()
        with CrashStore(self.root,self.plan) as store:
            with self.assertRaises(ValueError):
                store.verify_and_recover()
            with self.assertRaises(ValueError):
                self.ingest(store)
        self.assertFalse(report.exists())

    def test_writable_report_mutation_detected(self):
        with CrashStore(self.root,self.plan) as store:
            self.ingest(store)
            _,_,path=get_paths(store)
        path.write_bytes(path.read_bytes().replace(b'"not_a_year_chunk":true',b'"not_a_year_chunk":false'))
        with CrashStore(self.root,self.plan) as store:
            with self.assertRaises(ValueError):
                store.verify_and_recover()

    def test_symlinked_archive_outside_ledger_rejected(self):
        with CrashStore(self.root,self.plan) as store:
            folder,p,_=get_paths(store)
            folder.mkdir(parents=True)
            outside=Path(self.tmp.name)/"external-original.zip"
            outside.write_bytes(self.real)
            p.symlink_to(outside)
            with self.assertRaisesRegex(ValueError,"symlink"):
                self.ingest(store)
            self.assertEqual(store.progress()["committed_chunks"],0)

    def test_symlinked_directory_outside_ledger_rejected(self):
        with CrashStore(self.root,self.plan) as store:
            folder,_,_=get_paths(store)
            outside=Path(self.tmp.name)/"outside-folder"
            outside.mkdir()
            folder.symlink_to(outside,target_is_directory=True)
            with self.assertRaisesRegex(ValueError,"symlink"):
                self.ingest(store)

    def test_bad_original_year_boundaries_rejected(self):
        edited=json.loads(json.dumps(self.plan))
        edited["years"][0]["last_target_day"]="-15053460"
        with CrashStore(self.root,edited) as store:
            with self.assertRaisesRegex(ValueError,"full original year"):
                self.ingest(store)

    def test_bad_original_binary_refused(self):
        edited=json.loads(json.dumps(self.plan))
        edited["engines"][1]["binary_sha256"]="f"*64
        with CrashStore(self.root,edited) as store:
            with self.assertRaisesRegex(ValueError,"source/binary descriptors"):
                self.ingest(store)

    def test_bad_calculation_day_refused(self):
        edited=json.loads(json.dumps(self.plan))
        edited["calculation_day"]="-15055672"
        with CrashStore(self.root,edited) as store:
            with self.assertRaisesRegex(ValueError,"exact v2 experimental c"):
                self.ingest(store)

    def test_sqlite_report_digest_mutation_detected(self):
        with CrashStore(self.root,self.plan) as store:
            self.ingest(store)
            store.db.execute(
                "UPDATE supervised_two_day_pilot_witnesses SET report_sha256=?",
                ("0"*64,))
            with self.assertRaises(ValueError):
                store.verify_and_recover()

    def test_crash_before_sqlite_commit_must_replay_explicit_same_source(self):
        from quarantined_pilot_ledger_v048 import _publish
        with CrashStore(self.root,self.plan) as store:
            root,a,r=get_paths(store)
            root.mkdir(parents=True)
            record={
                "schema":SCHEMA,
                "source_replay":{
                    "status":"PINNED_REAL_TWO_NATIVE_DAYS_REVALIDATED_NOT_YEAR_SOAK",
                    "official_full_year_soak_passes":0
                },
                "frozen_offline_replay":self.offline,
                "not_a_year_chunk":True,
            }
            _publish(store,a,self.real)
            # Only the archive exists when crash hits, not the complete report.
            with self.assertRaisesRegex(ValueError,"unindexed"):
                store.verify_and_recover()
        with CrashStore(self.root,self.plan) as store:
            res=self.ingest(store)
            self.assertEqual(res["outcome"],"QUARANTINED_TWO_DAY_PILOT_RECORDED")
            self.assertEqual(store.verify_and_recover()["quarantined_two_day_pilots_revalidated"],1)

    def test_original_source_git_identity_required_before_any_registration(self):
        outside=Path(self.tmp.name)/"not-a-git-repo"
        outside.mkdir()
        with CrashStore(self.root,self.plan) as store:
            with self.assertRaises(Exception):
                register_two_day_pilot(store,self.real,self.sources,outside,
                                       expected_sha256=ARCHIVE_SHA)
            self.assertEqual(store.progress()["quarantined_two_day_pilot_records_not_year_chunks"],0)

    def test_recovery_succeeds_without_sources_repo_available(self):
        with CrashStore(self.root,self.plan) as store:
            self.ingest(store)
        # Recovery API takes no source-root path; rehashes immutable ZIP.
        with CrashStore(self.root,self.plan) as store:
            v=store.verify_and_recover()
            self.assertEqual(v["quarantined_two_day_pilots_revalidated"],1)
            self.assertEqual(v["progress"]["original_native_full_year_soak_passes_certified"],0)

    def test_recovery_never_invokes_full_original_source_replay(self):
        with CrashStore(self.root,self.plan) as store:
            self.ingest(store)
        # An offline replay must NOT depend on GitHub, original git checkout,
        # or a new F(c,t) call after the original archive was committed.
        with patch("quarantined_two_day_pilot_v057.replay_native_witness",
                   side_effect=AssertionError("original source replay during recovery")):
            with CrashStore(self.root,self.plan) as store:
                result=store.verify_and_recover()
                self.assertEqual(result["quarantined_two_day_pilots_revalidated"],1)
                self.assertEqual(result["progress"]["fully_verified_years"],0)

    def test_orphaned_part_file_not_implicitly_adopted_by_recovery(self):
        with CrashStore(self.root,self.plan) as store:
            folder,archive,_=get_paths(store)
            folder.mkdir(parents=True)
            staged=archive.with_name(archive.name+".part")
            staged.write_bytes(self.real)
            with self.assertRaisesRegex(ValueError,"unindexed"):
                store.verify_and_recover()
            self.assertEqual(store.progress()["committed_chunks"],0)
            outcome=self.ingest(store)
            self.assertEqual(outcome["outcome"],"QUARANTINED_TWO_DAY_PILOT_RECORDED")
            self.assertEqual(store.verify_and_recover()["quarantined_two_day_pilots_revalidated"],1)

    def test_offline_frozen_receipt_proves_only_integrity_not_source_lineage(self):
        rec=frozen_offline_recheck(self.real)
        self.assertEqual(rec["original_native_date_pairs_verified"],2)
        self.assertEqual(rec["complete_year_day_count"],4244)
        self.assertFalse(rec["source_lineage_certified"])
        self.assertFalse(rec["host_process_execution_independently_attested"])
        self.assertFalse(rec["canonical_oracle_certified"])
        self.assertEqual(rec["official_original_years_certified"],0)

if __name__=="__main__":
    unittest.main()
