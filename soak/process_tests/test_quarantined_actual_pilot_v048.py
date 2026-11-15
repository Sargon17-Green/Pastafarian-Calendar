"""v048: actual pinned v045 GitHub artifact -> QUARANTINED pilot evidence ledger.

Requires PASTAFARI_ACTUAL_V045_ARTIFACT env on the dedicated v047 workflow.
This is one original day, NOT a 4244-day original year. Test-only pilot name
hashes describe observed native naming conventions, not a canonical name map.
No native F(c,t) is executed by these tests.
"""
from __future__ import annotations

import json
import os
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
from native_execution_receipt_v038 import canonical,sha
from recovery_store import CrashStore
from quarantined_pilot_ledger_v048 import check_registered_pilot_witnesses,paths
from source_identity_gate_v036 import PROVENANCE_CONTRACT,IDENTITY_SCHEMA
from supervised_original_pair_artifact_v047 import (
    ZIP_SHA,C,T,YEAR,BOUNDARY_SHA,PY_COMMIT,KT_COMMIT,PY_SOURCE_SHA,
    verify_supervised_original_pair_archive,
)

def make_plan(witness):
    def engine(name,commit,sourcepath,source_sha,binary_sha,source_class,
               source_family,method,entrypoint,names):
        return {
            "id":name,"algorithm_id":"original-algorithm-"+source_family,
            "source_sha256":source_sha,"binary_sha256":binary_sha,
            # Partial witness metadata only: NOT an independently verified
            # complete canonical 17/47 name map.
            "name_map_sha256":sha(canonical(names)),
            "provenance":{
                "schema":IDENTITY_SCHEMA,"source_class":source_class,
                "source_commit":commit,
                "repository":"Sargon17-Green/Pastafarian-Calendar",
                "source_path":sourcepath,
                "source_family":source_family,
                "native_entrypoint":entrypoint,
                "execution_method":method,"derived_from":None,
                "original_source_sha256":source_sha,
            }
        }
    py=engine("REF-41",PY_COMMIT,"tests/normative_reference.py",
              PY_SOURCE_SHA,witness["original_python_interpreter_sha256"],
              "reference","python-normative-41","unchanged_reference_Fct",
              "NormativeCalendar.calendar_date_ids",
              {"pilot_native_names_only":["Akrep","Kuyu"]})
    kt=engine("PROD-KT-CY",KT_COMMIT,"soak/Post55ProductionDateBridge.kt",
              witness["original_kotlin_bridge_source_sha256"],
              witness["original_kotlin_jar_sha256"],
              "original","kotlin-production-cymraeg","unchanged_original_Fct",
              "Post55ProductionDateBridge.convert",
              {"original_bridge_output":"numeric-index-only"})
    return {
        "contract":PROVENANCE_CONTRACT,"identity_contract":IDENTITY_SCHEMA,
        "soak_purpose":"EXPERIMENTAL_NATIVE_DIFFERENTIAL_UNCERTIFIED",
        "independence_audit_status":"NOT_CERTIFIED",
        "calculation_day":C,"chunk_days":512,
        "years":[{
            "year":YEAR,"first_target_day":"-15057702",
            "last_target_day":"-15053459",
            "boundary_evidence_sha256":BOUNDARY_SHA,
        }],
        "engines":[py,kt],
    }


class QuarantinedPilotLedgerTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        supplied=os.environ.get("PASTAFARI_ACTUAL_V045_ARTIFACT")
        if not supplied:
            raise unittest.SkipTest("original GitHub Actions artifact not supplied")
        cls.payload=Path(supplied).read_bytes()
        cls.witness=verify_supervised_original_pair_archive(
            cls.payload,expected_sha256=ZIP_SHA)
        cls.plan=make_plan(cls.witness)

    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)/"ledger"

    def register(self,store):
        return store.record_quarantined_original_pilot(
            self.payload,expected_sha256=ZIP_SHA)

    def test_actual_native_pilot_ledger_is_a_separate_table_not_one_full_year(self):
        with CrashStore(self.root,self.plan) as store:
            before=store.progress()
            self.assertEqual(before["committed_chunks"],0)
            self.assertEqual(before["verified_comparisons_completed"],0)
            self.assertEqual(before["quarantined_pilot_records_not_year_chunks"],0)
            result=self.register(store)
            self.assertEqual(result["outcome"],"QUARANTINED_PILOT_RECORDED")
            after=store.progress()
            self.assertEqual(after["quarantined_pilot_records_not_year_chunks"],1)
            self.assertEqual(after["verified_comparisons_completed"],0)
            self.assertEqual(after["committed_chunks"],0)
            self.assertEqual(after["fully_verified_years"],0)
            self.assertFalse(after["all_verified"])
            self.assertEqual(after["original_native_full_year_soak_passes_certified"],0)
            self.assertEqual(after["verified_day_pair_comparisons"],0)
            self.assertEqual(check_registered_pilot_witnesses(store),1)
        with CrashStore(self.root,self.plan) as store:
            recovered=store.verify_and_recover()
            self.assertEqual(recovered["quarantined_pilot_witnesses_revalidated"],1)
            self.assertEqual(recovered["verified_existing_chunks"],0)
            self.assertEqual(recovered["recovered_chunks"],0)
            self.assertEqual(recovered["progress"]["verified_comparisons_completed"],0)

    def test_replay_idempotent_without_creating_year_chunks(self):
        with CrashStore(self.root,self.plan) as store:
            self.register(store)
            result=self.register(store)
            self.assertEqual(result["outcome"],"ALREADY_RECORDED")
            self.assertEqual(store.progress()["quarantined_pilot_records_not_year_chunks"],1)
            self.assertEqual(store.progress()["committed_chunks"],0)

    def test_tampered_saved_zip_detected_on_crash_recovery_and_never_healed(self):
        with CrashStore(self.root,self.plan) as store:
            self.register(store)
            _,a,_=paths(store,ZIP_SHA)
        a.write_bytes(a.read_bytes()+b"adversarial alteration")
        with CrashStore(self.root,self.plan) as store:
            with self.assertRaisesRegex(ValueError,"altered|SHA"):
                store.verify_and_recover()
            with self.assertRaisesRegex(ValueError,"missing|overwritten|altered|ZIP"):
                self.register(store)

    def test_missing_receipt_detected_not_regenerated_on_registered_replay(self):
        with CrashStore(self.root,self.plan) as store:
            self.register(store)
            _,_,receipt=paths(store,ZIP_SHA)
        receipt.unlink()
        with CrashStore(self.root,self.plan) as store:
            with self.assertRaises(ValueError):
                store.verify_and_recover()
            with self.assertRaises(ValueError):
                self.register(store)
        self.assertFalse(receipt.exists())

    def test_invalid_plan_calculation_day_never_accepts_pilot(self):
        p=json.loads(json.dumps(self.plan))
        p["calculation_day"]="-15055672"
        with CrashStore(self.root,p) as store:
            with self.assertRaisesRegex(ValueError,"calculation day"):
                self.register(store)
            self.assertEqual(store.progress()["committed_chunks"],0)

    def test_wrong_source_binary_rejected_even_if_v2_metadata_is_well_formed(self):
        p=json.loads(json.dumps(self.plan))
        p["engines"][1]["binary_sha256"]="c"*64
        with CrashStore(self.root,p) as store:
            with self.assertRaisesRegex(ValueError,"source/binary"):
                self.register(store)
            self.assertEqual(store.progress()["quarantined_pilot_records_not_year_chunks"],0)

    def test_mutated_full_year_boundary_blocks_ingest(self):
        p=json.loads(json.dumps(self.plan))
        p["years"][0]["last_target_day"]="-15053460"
        with CrashStore(self.root,p) as store:
            with self.assertRaisesRegex(ValueError,"complete-year bounds"):
                self.register(store)

    def test_corrupt_sqlite_receipt_detected(self):
        with CrashStore(self.root,self.plan) as store:
            self.register(store)
            store.db.execute(
                "UPDATE supervised_pilot_witnesses SET report_sha256=?",
                ("a"*64,))
            with self.assertRaisesRegex(ValueError,"altered"):
                store.verify_and_recover()

    def test_crash_after_artifact_staging_before_sqlite_requires_replay(self):
        with CrashStore(self.root,self.plan) as store:
            from quarantined_pilot_ledger_v048 import _publish
            dir,a,b=paths(store,ZIP_SHA)
            dir.mkdir(parents=True,exist_ok=True)
            _publish(store,a,self.payload)
            _publish(store,b,canonical(self.witness))
            with self.assertRaisesRegex(ValueError,"unindexed"):
                store.verify_and_recover()
        with CrashStore(self.root,self.plan) as store:
            outcome=self.register(store)
            self.assertEqual(outcome["outcome"],"QUARANTINED_PILOT_RECORDED")
            self.assertEqual(store.verify_and_recover()["quarantined_pilot_witnesses_revalidated"],1)

    def test_symlinked_artifact_refused_before_sqlite_registration(self):
        with CrashStore(self.root,self.plan) as store:
            folder,archive,_=paths(store,ZIP_SHA)
            folder.mkdir(parents=True,exist_ok=True)
            target=Path(self.tmp.name)/"outside-original.zip"
            target.write_bytes(self.payload)
            archive.symlink_to(target)
            with self.assertRaisesRegex(ValueError,"symlink"):
                self.register(store)
            self.assertEqual(store.progress()["quarantined_pilot_records_not_year_chunks"],0)

    def test_symlinked_evidence_directory_is_never_used(self):
        with CrashStore(self.root,self.plan) as store:
            folder,_,_=paths(store,ZIP_SHA)
            target=Path(self.tmp.name)/"elsewhere"
            target.mkdir()
            folder.symlink_to(target,target_is_directory=True)
            with self.assertRaisesRegex(ValueError,"symlink"):
                self.register(store)
            self.assertEqual(store.progress()["committed_chunks"],0)

    def test_new_pilot_pair_not_counted_as_full_year_even_if_future_year_chunks_pending(self):
        with CrashStore(self.root,self.plan) as store:
            self.register(store)
            pending=store.pending_jobs()
            self.assertTrue(pending)
            self.assertTrue(all(x.year==YEAR and x.engine_id=="REF-41" for x in pending))
            self.assertEqual(store.progress()["original_native_full_year_soak_passes_certified"],0)


if __name__=="__main__":
    unittest.main()
