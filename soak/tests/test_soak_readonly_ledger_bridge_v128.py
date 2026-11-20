"""Purely synthetic read-only ledger audit tests; no original F(c,t)."""
from __future__ import annotations

import copy
import json
from pathlib import Path
import sqlite3
import sys
import tempfile
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
from recovery_store import CrashStore, sha256
from native_execution_receipt_v038 import make_receipt
from source_identity_gate_v036 import PROVENANCE_CONTRACT, IDENTITY_SCHEMA
from soak_scope_coverage_v127 import digest
from soak_readonly_ledger_bridge_v128 import audit


def plan():
    def eng(i):
        source = str(i+1)*64
        return {
            "id":"e"+str(i),
            "algorithm_id":"family"+str(i),
            "source_sha256":source,"binary_sha256":chr(97+i)*64,
            "name_map_sha256":"f"*64,
            "provenance":{
                "schema":IDENTITY_SCHEMA,
                "source_class":"reference" if i==0 else "original",
                "source_commit":str(i+1)*40,
                "repository":"Sargon17-Green/Pastafarian-Calendar",
                "source_path":"synthetic/e"+str(i)+".py",
                "source_family":"family"+str(i),
                "native_entrypoint":"e"+str(i)+".F(c,t)",
                "execution_method":"unchanged_reference_Fct" if i==0 else "unchanged_original_Fct",
                "derived_from":None,"original_source_sha256":source,
            }}
    return {"contract":PROVENANCE_CONTRACT,
            "identity_contract":IDENTITY_SCHEMA,
            "soak_purpose":"EXPERIMENTAL_NATIVE_DIFFERENTIAL_UNCERTIFIED",
            "independence_audit_status":"NOT_CERTIFIED",
            "calculation_day":"-15055671",
            "chunk_days":1,
            "years":[{"year":"5000","first_target_day":"-15055671",
                      "last_target_day":"-15055670",
                      "boundary_evidence_sha256":"a"*64}],
            "engines":[eng(0),eng(1)]}


def scope_for(p):
    inv = {"schema":"PASTAFARI_SOAK_SOURCE_ROSTER_V127/1",
           "records":[{"record_id":e["id"],"engine_id":e["id"],
                       "algorithm_id":e["algorithm_id"],
                       "source_kind":"reference" if i==0 else "production_candidate"}
                      for i,e in enumerate(p["engines"])]}
    scope = {"schema":"PASTAFARI_SOAK_SCOPE_PLAN_V127/1",
             "inventory_sha256":digest(inv),
             "years":copy.deepcopy(p["years"]),
             "dispositions":[{"record_id":e["id"],"decision":"IN_SCOPE",
                              "duplicate_of":None,"review_evidence_sha256":None}
                             for e in p["engines"]],
             "incident_status":"OPEN",
             "dispatch_halt":True,
             "independence_audit":"NOT_CERTIFIED"}
    return inv, scope


def raw_and_normalized(engine, day, *, altered=False):
    source=(engine+"\t"+str(day)+"\n").encode("utf8")
    row={
        "calculation_day":"-15055671","target_day":str(day),
        "year":"5000","cutlet_index":10,
        "day_in_cutlet":1 if day==-15055671 else 2,
        "month_index":21 if altered else 20,
        "day_in_month":1 if day==-15055671 else 2,
        "cutlet_name_raw":"קטע" if engine=="e0" else "cutlet",
        "month_name_raw":"חודש" if engine=="e0" else "month",
        "source_raw_sha256":sha256(source)}
    return source, (json.dumps(row,sort_keys=True,ensure_ascii=False)+"\n").encode("utf8")


def commit_one(store,engine,ordinal,*,altered=False):
    c=store._chunk(engine,"5000",ordinal)
    raw,norm=raw_and_normalized(engine,int(c.first_day),altered=altered)
    receipt=make_receipt(store.plan,store.plan_sha,engine,"5000",
                         c.first_day,c.last_day,ordinal,norm,raw)
    store.commit_chunk(engine,"5000",ordinal,norm,raw_stdout=raw,native_receipt=receipt)
    return c


class ReadonlyBridgeV128Tests(unittest.TestCase):
    def setUp(self):
        temp=tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root=Path(temp.name)/"ledger"
        self.p=plan()
        self.inventory,self.scope=scope_for(self.p)

    def populate(self):
        with CrashStore(self.root,self.p) as store:
            for engine in ("e0","e1"):
                for ordinal in (0,1):
                    commit_one(store,engine,ordinal)

    def test_full_original_bytes_linked_but_incident_lock_remains(self):
        self.populate()
        receipts,coverage=audit(self.root,self.inventory,self.scope)
        self.assertEqual([x["status"] for x in receipts["engine_years"]],
                         ["UPSTREAM_VERIFIED","UPSTREAM_VERIFIED"])
        self.assertEqual(receipts["engine_years"][0]["daystream_sha256"],
                         receipts["engine_years"][1]["daystream_sha256"])
        self.assertEqual(coverage["status"],"INCIDENT_HALT")
        self.assertTrue(coverage["structural_coverage_complete"])
        self.assertEqual(coverage["official_years_certified_by_this_gate"],0)
        self.assertFalse(coverage["official_soak_10000_pass"])

    def test_reader_does_not_change_existing_sqlite_or_receipt_bytes(self):
        self.populate()
        db=self.root/"ledger.sqlite"
        files=[db,*list((self.root/"chunks").iterdir()),
               *list((self.root/"evidence").iterdir())]
        before={p.name:sha256(p.read_bytes()) for p in files}
        audit(self.root,self.inventory,self.scope)
        after={p.name:sha256(p.read_bytes()) for p in files}
        self.assertEqual(before,after)

    def test_incomplete_year_is_pending_not_complete(self):
        with CrashStore(self.root,self.p) as store:
            commit_one(store,"e0",0)
        receipts,coverage=audit(self.root,self.inventory,self.scope)
        self.assertEqual([r["status"] for r in receipts["engine_years"]],
                         ["PENDING","PENDING"])
        self.assertEqual(coverage["structurally_equal_engine_year_pairs"],0)
        self.assertEqual(coverage["missing_or_pending_engine_years"],2)

    def test_tampered_normalized_chunk_fails_closed(self):
        with CrashStore(self.root,self.p) as store:
            c=commit_one(store,"e0",0)
            p=store._chunk_path(c)
        p.write_bytes(p.read_bytes()+b"extra\n")
        with self.assertRaisesRegex(ValueError,"checksum"):
            audit(self.root,self.inventory,self.scope)

    def test_missing_native_stdout_or_receipt_fails_closed(self):
        with CrashStore(self.root,self.p) as store:
            c=commit_one(store,"e0",0)
            raw,receipt=store._native_receipt_paths(c)
        for missing in (raw,receipt):
            original=missing.read_bytes()
            missing.unlink()
            with self.assertRaisesRegex(ValueError,"missing"):
                audit(self.root,self.inventory,self.scope)
            missing.write_bytes(original)

    def test_forged_receipt_sha_in_db_fails_closed(self):
        with CrashStore(self.root,self.p) as store:
            commit_one(store,"e0",0)
        db=sqlite3.connect(self.root/"ledger.sqlite")
        try:
            db.execute("UPDATE native_receipts SET receipt_sha256=? WHERE engine='e0'",("f"*64,))
            db.commit()
        finally:
            db.close()
        with self.assertRaisesRegex(ValueError,"atomic registration"):
            audit(self.root,self.inventory,self.scope)

    def test_scope_source_order_change_fails_closed(self):
        self.populate()
        # Freeze a source plan in the opposite engine order while keeping the\n        # original v127 dispositions order unchanged.
        other=copy.deepcopy(self.p)
        other["engines"].reverse()
        self.scope["inventory_sha256"]=digest(self.inventory)
        temp=tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        with CrashStore(Path(temp.name)/"other",other):
            pass
        with self.assertRaisesRegex(ValueError,"engine order"):
            audit(Path(temp.name)/"other",self.inventory,self.scope)

    def test_db_incident_cannot_be_laundered_as_match(self):
        with CrashStore(self.root,self.p) as store:
            commit_one(store,"e0",0)
            commit_one(store,"e0",1)
            commit_one(store,"e1",0,altered=True)
            self.assertIsNotNone(store.incident())
        with self.assertRaisesRegex(ValueError,"ledger incident"):
            audit(self.root,self.inventory,self.scope)

    def test_foreign_sqlite_comparison_claim_fails_closed(self):
        self.populate()
        db=sqlite3.connect(self.root/"ledger.sqlite")
        try:
            db.execute("UPDATE comparisons SET stream_sha256=?",("e"*64,))
            db.commit()
        finally:
            db.close()
        with self.assertRaisesRegex(ValueError,"comparison lacks exact"):
            audit(self.root,self.inventory,self.scope)

    def test_rogue_sqlite_chunk_not_in_scope_fails_closed(self):
        self.populate()
        db=sqlite3.connect(self.root/"ledger.sqlite")
        try:
            db.execute("INSERT INTO chunks VALUES (?,?,?,?,?,?,?)",
                       ("unplanned","5000",0,"1","1","a"*64,1))
            db.commit()
        finally:
            db.close()
        with self.assertRaisesRegex(ValueError,"unexpected/missing"):
            audit(self.root,self.inventory,self.scope)


if __name__=="__main__":
    unittest.main()
