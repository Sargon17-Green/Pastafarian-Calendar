"""Synthetic wiring tests for v039 pilot-to-ledger import.

The actual original source/name-map verification is implemented and separately
unit-tested by native_raw_pair_gate_v018. This test injects a verifier stub
solely to test the new *glue*, not to claim a real F(c,t) was executed.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/"runner"))
import import_verified_pilot_chunk_v039 as importer
from native_execution_receipt_v038 import canonical,sha
from recovery_store import CrashStore
from source_identity_gate_v036 import IDENTITY_SCHEMA, PROVENANCE_CONTRACT


def fake_maps():
    return [
        {"c"+str(i):i for i in range(1,18)},
        {"m"+str(i):i for i in range(1,48)},
    ]


def fixture_engine(identifier:str, adapter_sha:str, name_map_sha:str):
    python = identifier=="REF-41"
    commit=("1" if python else "2")*40
    source_sha=("3" if python else "4")*64
    source_path=("tests/normative_reference.py" if python else
                 "tests/normative-reference.js")
    entrypoint=("NormativeCalendar().calendar_date_ids(calculation_day,target_day)"
                if python else
                "calendarDate(BigInt(calculation_day),BigInt(target_day))")
    return {
        "id":identifier, "algorithm_id":"algo-"+identifier,
        "source_sha256":source_sha,"binary_sha256":adapter_sha,
        "name_map_sha256":name_map_sha,
        "provenance":{
            "schema":IDENTITY_SCHEMA, "source_class":"reference",
            "source_commit":commit,
            "repository":"Sargon17-Green/Pastafarian-Calendar",
            "source_path":source_path, "source_family":"family-"+identifier,
            "native_entrypoint":entrypoint,
            "execution_method":"unchanged_reference_Fct",
            "derived_from":None,
            "original_source_sha256":source_sha,
        }
    }


def stream_fixture(engine_id):
    raw=[]
    normalized=[]
    for i,t in enumerate(("100","101")):
        row=(json.dumps({"engine":engine_id,"c":"-15055672","t":t},
                        separators=(",",":"),sort_keys=True)+"\n").encode("utf8")
        raw.append(row)
        normalized.append({
            "calculation_day":"-15055672", "target_day":t,
            "year":"5000", "cutlet_index":5,"day_in_cutlet":i+1,
            "month_index":7,"day_in_month":i+1,
            "cutlet_name_raw":"c5","month_name_raw":"m7",
            "source_raw_sha256":sha(row),
        })
    norm="".join(json.dumps(x,sort_keys=True)+"\n" for x in normalized).encode("utf8")
    return b"".join(raw),norm


class PilotV039WiringTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        self.adapters={}
        names=importer.catalog_digest(fake_maps())
        self.engines=[]
        self.manifests={}
        self.inputs={}
        for engine_id,profile in importer.PILOT_PROFILES.items():
            adapter=self.root/profile["transport"]
            adapter.write_bytes((engine_id+" mock adapter\n").encode())
            self.adapters[engine_id]=adapter
            entry=fixture_engine(engine_id,sha(adapter.read_bytes()),names)
            self.engines.append(entry)
            self.manifests[engine_id]={
                "id":engine_id, "commit":entry["provenance"]["source_commit"],
                "repository":entry["provenance"]["repository"],
                "entrypoint":entry["provenance"]["native_entrypoint"],
                "sources":[{
                    "path":entry["provenance"]["source_path"],
                    "sha256":entry["source_sha256"],
                }],
            }
            raw,norm=stream_fixture(engine_id)
            folder=self.root/engine_id
            folder.mkdir()
            (folder/"raw.jsonl").write_bytes(raw)
            (folder/"normalized.jsonl").write_bytes(norm)
            (folder/"transport-receipt.json").write_text(json.dumps({
                "calculation_day":"-15055672",
                "first_target_day":"100","last_target_day":"101",
                "boundary_evidence_sha256":"f"*64,
            }))
            self.inputs[engine_id]=folder
        self.plan={
            "contract":PROVENANCE_CONTRACT,
            "identity_contract":IDENTITY_SCHEMA,
            "soak_purpose":"EXPERIMENTAL_NATIVE_DIFFERENTIAL_UNCERTIFIED",
            "independence_audit_status":"NOT_CERTIFIED",
            "calculation_day":"-15055672","chunk_days":2,
            "years":[{"year":"5000","first_target_day":"100",
                      "last_target_day":"101","boundary_evidence_sha256":"f"*64}],
            "engines":self.engines,
        }

    def mocked_verifiers(self,*,verdict="NATIVE_RAW_TRANSPORT_EVIDENCE_PASS_BOUNDED"):
        def source(root,identity):
            return self.manifests[identity],{}
        def maps(identity,contents):
            return fake_maps()
        def verified(identity,source_root,raw,norm,receipt):
            return {"status":verdict,"rows_verified":2,"year_certified":False}
        return (patch.object(importer,"verify_locked_sources",side_effect=source),
                patch.object(importer,"name_maps",side_effect=maps),
                patch.object(importer,"verify_stream",side_effect=verified))

    def admit(self,store,engine_id):
        folder=self.inputs[engine_id]
        return importer.import_pilot_chunk(
            store,engine_id=engine_id,year="5000",ordinal=0,
            source_root=self.root,adapter=self.adapters[engine_id],
            raw_file=folder/"raw.jsonl",
            normalized_file=folder/"normalized.jsonl",
            transport_receipt=folder/"transport-receipt.json",
        )

    def test_two_original_pilot_streams_import_into_v2_without_native_certification(self):
        p1,p2,p3=self.mocked_verifiers()
        with p1,p2,p3:
            with CrashStore(self.root/"ledger",self.plan) as s:
                a=self.admit(s,"REF-41")
                b=self.admit(s,"REF-24")
                self.assertEqual(a["ledger_result"],"COMMITTED")
                self.assertEqual(b["ledger_result"],"COMMITTED")
                self.assertFalse(a["trusted_process_execution_attested"])
                self.assertEqual(b["official_original_soak_years_certified"],0)
                self.assertEqual(s.progress()["native_receipt_rows_recorded_without_revalidation"],2)
                self.assertEqual(s.progress()["verified_comparisons_completed"],1)
                self.assertEqual(s.progress()["original_native_full_year_soak_passes_certified"],0)
            with CrashStore(self.root/"ledger",self.plan) as s:
                self.assertEqual(s.verify_and_recover()["verified_existing_chunks"],2)

    def test_wrong_calculation_day_transport_rejected_before_chunk(self):
        folder=self.inputs["REF-41"]
        p=folder/"transport-receipt.json"
        data=json.loads(p.read_text())
        data["calculation_day"]="-15055671"
        p.write_text(json.dumps(data))
        a,b,c=self.mocked_verifiers()
        with a,b,c,CrashStore(self.root/"ledger",self.plan) as s:
            with self.assertRaisesRegex(ValueError,"not scoped"):
                self.admit(s,"REF-41")
            self.assertEqual(s.progress()["committed_chunks"],0)

    def test_modified_pilot_adapter_artifact_rejected(self):
        adapter=self.adapters["REF-41"]
        adapter.write_bytes(adapter.read_bytes()+b"tamper")
        a,b,c=self.mocked_verifiers()
        with a,b,c,CrashStore(self.root/"ledger",self.plan) as s:
            with self.assertRaisesRegex(ValueError,"transport artifact SHA"):
                self.admit(s,"REF-41")

    def test_native_semantic_validator_rejection_is_not_bypassed(self):
        a,b,c=self.mocked_verifiers(verdict="INVALID_NATIVE_NORMALIZATION")
        with a,b,c,CrashStore(self.root/"ledger",self.plan) as s:
            with self.assertRaisesRegex(ValueError,"validation not passed"):
                self.admit(s,"REF-41")
            self.assertEqual(s.progress()["committed_chunks"],0)

    def test_wrong_original_source_commit_is_rejected(self):
        self.manifests["REF-41"]["commit"]="9"*40
        a,b,c=self.mocked_verifiers()
        with a,b,c,CrashStore(self.root/"ledger",self.plan) as s:
            with self.assertRaisesRegex(ValueError,"source_commit"):
                self.admit(s,"REF-41")

    def test_native_raw_record_line_mismatch_cannot_be_overridden_by_stub(self):
        raw_path=self.inputs["REF-41"]/"raw.jsonl"
        raw_path.write_bytes(raw_path.read_bytes()+b"extra\n")
        a,b,c=self.mocked_verifiers()
        with a,b,c,CrashStore(self.root/"ledger",self.plan) as s:
            with self.assertRaisesRegex(ValueError,"day count"):
                self.admit(s,"REF-41")

    def test_native_source_names_digest_is_enforced(self):
        self.engines[0]["name_map_sha256"]="9"*64
        a,b,c=self.mocked_verifiers()
        with a,b,c,CrashStore(self.root/"ledger",self.plan) as s:
            with self.assertRaisesRegex(ValueError,"name-map"):
                self.admit(s,"REF-41")


if __name__=="__main__":
    unittest.main()
