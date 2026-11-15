"""Pure tests: v038 native raw stdout receipts integrated in crash ledger.

Only synthetic source bytes are used. This never executes native converters,
and a self-reported receipt is NOT an authenticated process execution record.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

RUNNER = Path(__file__).resolve().parents[1] / "runner"
sys.path.insert(0, str(RUNNER))

from recovery_store import CrashStore, Halted, sha256
from native_execution_receipt_v038 import (
    SCHEMA, STATUS, make_receipt, verify_receipt
)
from source_identity_gate_v036 import IDENTITY_SCHEMA, PROVENANCE_CONTRACT


def plan():
    def engine(key, source, binary, family, cls):
        return {
            "id":key, "algorithm_id":family,
            "source_sha256":source * 64, "binary_sha256":binary * 64,
            "name_map_sha256":"d"*64,
            "provenance":{
                "schema":IDENTITY_SCHEMA, "source_class":cls,
                "source_commit":("1" if key=="native-a" else "2")*40,
                "repository":"Sargon17-Green/Pastafarian-Calendar",
                "source_path":"tests/"+key+".py",
                "source_family":family,
                "native_entrypoint":key+".F(c,t)",
                "execution_method":("unchanged_reference_Fct" if cls=="reference"
                                    else "unchanged_original_Fct"),
                "derived_from":None,
                "original_source_sha256":source * 64,
            }
        }
    return {
        "contract":PROVENANCE_CONTRACT, "identity_contract":IDENTITY_SCHEMA,
        "soak_purpose":"EXPERIMENTAL_NATIVE_DIFFERENTIAL_UNCERTIFIED",
        "independence_audit_status":"NOT_CERTIFIED",
        "calculation_day":"-15055672", "chunk_days":2,
        "years":[{"year":"5000","first_target_day":"-15056173",
                  "last_target_day":"-15056172",
                  "boundary_evidence_sha256":"f"*64}],
        "engines":[engine("native-a","1","a","original-a","reference"),
                   engine("native-b","2","b","original-b","original")],
    }


def payload(engine):
    raw=[]
    normalized=[]
    for i,t in enumerate(("-15056173", "-15056172")):
        row=(engine+"\t"+t+"\t5000\t5\t1\t7\t1\n").encode("utf8")
        raw.append(row)
        normalized.append({
            "calculation_day":"-15055672","target_day":t,
            "year":"5000","cutlet_index":5,"day_in_cutlet":i+1,
            "month_index":7,"day_in_month":i+1,
            "cutlet_name_raw":"קטע","month_name_raw":"חודש",
            "source_raw_sha256":sha256(row),
        })
    return b"".join(raw),("".join(
        json.dumps(item,ensure_ascii=False,sort_keys=True)+"\n"
        for item in normalized)).encode("utf8")


def commit(store, engine):
    raw,content=payload(engine)
    chunk=store._chunk(engine,"5000",0)
    receipt=make_receipt(store.plan,store.plan_sha,engine,"5000",
                         chunk.first_day,chunk.last_day,chunk.ordinal,
                         content,raw)
    result=store.commit_chunk(engine,"5000",0,content,
                              raw_stdout=raw,native_receipt=receipt)
    return result,chunk,receipt,raw,content


class NativeExecutionReceiptTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)/"ledger"
        self.plan=plan()

    def test_raw_stdout_bound_to_each_normalized_row_and_untrusted_status(self):
        with CrashStore(self.root,self.plan) as store:
            value,chunk,receipt,raw,content=commit(store,"native-a")
            self.assertEqual(value,"COMMITTED")
            self.assertEqual(receipt["schema"],SCHEMA)
            self.assertEqual(receipt["status"],STATUS)
            self.assertEqual(receipt["raw_rows"],2)
            self.assertEqual(receipt["exit_code"],0)
            self.assertFalse(receipt["trusted_execution_attested"])
            self.assertFalse(receipt["independent_algorithm_attested"])
            self.assertFalse(receipt["official_soak_authorized"])
            self.assertEqual(receipt["raw_stdout_sha256"],sha256(raw))
            self.assertEqual(receipt["normalized_chunk_sha256"],sha256(content))
            self.assertEqual(store.progress()["raw_native_chunk_receipts_integrity_linked"],1)
            self.assertFalse(store.progress()["native_receipt_execution_attestation_verified"])
            self.assertEqual(store.progress()["original_native_full_year_soak_passes_certified"],0)
        with CrashStore(self.root,self.plan) as store:
            result=store.verify_and_recover()
            self.assertEqual(result["verified_existing_chunks"],1)
            self.assertEqual(result["progress"]["raw_native_chunk_receipts_integrity_linked"],1)
            self.assertEqual(result["progress"]["verified_comparisons_completed"],0)

    def test_both_engines_technical_match_with_no_soak_certification(self):
        with CrashStore(self.root,self.plan) as store:
            commit(store,"native-a")
            commit(store,"native-b")
            info=store.progress()
            self.assertEqual(info["raw_native_chunk_receipts_integrity_linked"],2)
            self.assertEqual(info["verified_comparisons_completed"],1)
            self.assertEqual(info["verified_day_pair_comparisons"],2)
            self.assertTrue(info["all_verified"])
            self.assertTrue(info["technical_comparisons_only"])
            self.assertEqual(info["original_native_full_year_soak_passes_certified"],0)
        with CrashStore(self.root,self.plan) as store:
            self.assertEqual(store.verify_and_recover()["verified_existing_chunks"],2)
            self.assertEqual(store.progress()["verified_comparisons_completed"],1)

    def test_missing_receipt_rejected_before_chunk_publication(self):
        with CrashStore(self.root,self.plan) as store:
            raw,content=payload("native-a")
            with self.assertRaisesRegex(ValueError,"requires raw native stdout"):
                store.commit_chunk("native-a","5000",0,content)
            self.assertEqual(store.progress()["committed_chunks"],0)

    def test_wrong_raw_stdout_fails_on_per_line_source_digest(self):
        with CrashStore(self.root,self.plan) as store:
            raw,content=payload("native-a")
            chunk=store._chunk("native-a","5000",0)
            altered=raw.replace(b"native-a\t",b"fake\tx\t",1)
            with self.assertRaisesRegex(ValueError,"source_raw_sha256"):
                make_receipt(store.plan,store.plan_sha,"native-a","5000",
                             chunk.first_day,chunk.last_day,0,content,altered)

    def test_modified_receipt_binary_sha_fails_before_storage(self):
        with CrashStore(self.root,self.plan) as store:
            raw,content=payload("native-a")
            chunk=store._chunk("native-a","5000",0)
            receipt=make_receipt(store.plan,store.plan_sha,"native-a","5000",
                                 chunk.first_day,chunk.last_day,0,content,raw)
            receipt["binary_sha256"]="f"*64
            with self.assertRaisesRegex(ValueError,"receipt contradicts"):
                store.commit_chunk("native-a","5000",0,content,
                                   raw_stdout=raw,native_receipt=receipt)
            self.assertEqual(store.progress()["committed_chunks"],0)

    def test_receipt_chunk_forged_calculation_day_is_rejected(self):
        with CrashStore(self.root,self.plan) as store:
            raw,content=payload("native-a")
            chunk=store._chunk("native-a","5000",0)
            receipt=make_receipt(store.plan,store.plan_sha,"native-a","5000",
                                 chunk.first_day,chunk.last_day,0,content,raw)
            receipt["calculation_day"]="-15055671"
            with self.assertRaisesRegex(ValueError,"receipt contradicts"):
                store.commit_chunk("native-a","5000",0,content,
                                   raw_stdout=raw,native_receipt=receipt)

    def test_tampered_raw_bytes_detected_on_recovery(self):
        with CrashStore(self.root,self.plan) as store:
            _,chunk,receipt,raw,content=commit(store,"native-a")
            raw_path,_=store._native_receipt_paths(chunk)
        raw_path.write_bytes(raw+b"tampered\n")
        with CrashStore(self.root,self.plan) as store:
            with self.assertRaisesRegex(ValueError,"raw native stdout"):
                store.verify_and_recover()

    def test_deleted_receipt_cannot_be_ignored_on_recovery(self):
        with CrashStore(self.root,self.plan) as store:
            _,chunk,receipt,raw,content=commit(store,"native-a")
            _,path=store._native_receipt_paths(chunk)
        path.unlink()
        with CrashStore(self.root,self.plan) as store:
            with self.assertRaises((FileNotFoundError,ValueError)):
                store.verify_and_recover()

    def test_replay_same_stdout_receipt_is_idempotent(self):
        with CrashStore(self.root,self.plan) as store:
            _,chunk,receipt,raw,content=commit(store,"native-a")
            self.assertEqual(
                store.commit_chunk("native-a","5000",0,content,
                                   raw_stdout=raw,native_receipt=receipt),
                "ALREADY_COMMITTED")
            self.assertEqual(store.progress()["raw_native_chunk_receipts_integrity_linked"],1)

    def test_replay_altered_stdout_is_rejected(self):
        with CrashStore(self.root,self.plan) as store:
            _,chunk,receipt,raw,content=commit(store,"native-a")
            changed=raw.replace(b"native-a\t",b"native-x\t",1)
            with self.assertRaisesRegex(ValueError,"source_raw_sha256"):
                store.commit_chunk("native-a","5000",0,content,
                                   raw_stdout=changed,native_receipt=receipt)
            self.assertEqual(store.progress()["committed_chunks"],1)

    def test_missing_committed_receipt_cannot_be_recreated_by_idempotent_replay(self):
        with CrashStore(self.root,self.plan) as store:
            _,chunk,receipt,raw,content=commit(store,"native-a")
            _,path=store._native_receipt_paths(chunk)
            path.unlink()
            with self.assertRaises((FileNotFoundError,ValueError)):
                store.commit_chunk("native-a","5000",0,content,
                                   raw_stdout=raw,native_receipt=receipt)
            self.assertFalse(path.exists())
            self.assertEqual(store.progress()["committed_chunks"],1)

    def test_existing_receipt_conflicting_normalized_replay_preserves_first_incident(self):
        with CrashStore(self.root,self.plan) as store:
            _,chunk,receipt,raw,content=commit(store,"native-a")
            modified=content.replace(b'"cutlet_index": 5',b'"cutlet_index": 6',1)
            with self.assertRaisesRegex(Halted,"conflicting replay"):
                store.commit_chunk("native-a","5000",0,modified,
                                   raw_stdout=raw,native_receipt=receipt)
            incident=store.incident()
            self.assertEqual(incident["kind"],"CONFLICTING_REPLAY")
            with self.assertRaises(Halted):
                store.pending_jobs()

    def test_recovery_of_orphaned_v2_payload_reuses_sidecars_without_recompute(self):
        script = r'''import json, pathlib, sys
sys.path.insert(0,sys.argv[1])
from recovery_store import CrashStore
from native_execution_receipt_v038 import make_receipt
p=json.loads(pathlib.Path(sys.argv[2]).read_text())
raw=pathlib.Path(sys.argv[3]).read_bytes()
content=pathlib.Path(sys.argv[4]).read_bytes()
with CrashStore(pathlib.Path(sys.argv[5]),p) as s:
    c=s._chunk("native-a","5000",0)
    receipt=make_receipt(s.plan,s.plan_sha,"native-a","5000",c.first_day,c.last_day,0,content,raw)
    s.commit_chunk("native-a","5000",0,content,raw_stdout=raw,
                   native_receipt=receipt,inject_crash_at="after_payload_publish")
'''
        base=Path(self.tmp.name)
        script_path=base/"crash.py"
        source_path=base/"plan.json"
        raw_path=base/"raw"
        normalized_path=base/"normalized"
        script_path.write_text(script,encoding="utf8")
        source_path.write_text(json.dumps(self.plan),encoding="utf8")
        raw,content=payload("native-a")
        raw_path.write_bytes(raw)
        normalized_path.write_bytes(content)
        result=subprocess.run([sys.executable,str(script_path),str(RUNNER),
                               str(source_path),str(raw_path),str(normalized_path),
                               str(self.root)],
                              stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=15)
        self.assertEqual(result.returncode,74,result.stderr.decode("utf8","replace"))
        with CrashStore(self.root,self.plan) as store:
            recovered=store.verify_and_recover()
            self.assertEqual(recovered["recovered_chunks"],1)
            self.assertEqual(recovered["progress"]["raw_native_chunk_receipts_integrity_linked"],1)
            self.assertEqual(recovered["progress"]["original_native_full_year_soak_passes_certified"],0)


if __name__=="__main__":
    unittest.main()
