#!/usr/bin/env python3
"""v048: quarantine one pinned original supervised day in CrashStore, NOT a year.

A pilot is stored in its own SQLite table and append-only files; never in
chunks/comparisons. Exact replay is idempotent. Damaged or missing committed
evidence cannot be recreated; partial witnesses require explicit replay.
"""
from __future__ import annotations

import hashlib
import os

from native_execution_receipt_v038 import canonical
from supervised_original_pair_artifact_v047 import (
    BOUNDARY_SHA,C,T,YEAR,ZIP_SHA,PY_COMMIT,KT_COMMIT,PY_SOURCE_SHA,
    verify_supervised_original_pair_archive,
)

def _sha(payload):
    return hashlib.sha256(payload).hexdigest()

def paths(store,zip_sha):
    root=store.root/"evidence"/"supervised_pilots"
    return root,root/(zip_sha+".zip"),root/(zip_sha+".report.json")

def check_plan(store,report):
    from source_identity_gate_v036 import PROVENANCE_CONTRACT
    store._assert_immutable_plan()
    if store.plan["contract"]!=PROVENANCE_CONTRACT or store.plan["calculation_day"]!=C:
        raise ValueError("wrong v2 experimental plan or calculation day")
    year=store.years.get(YEAR)
    if (not isinstance(year,dict) or year["first_target_day"]!="-15057702"
        or year["last_target_day"]!="-15053459"
        or year["boundary_evidence_sha256"]!=BOUNDARY_SHA
        or not int(year["first_target_day"])<=int(T)<=int(year["last_target_day"])):
        raise ValueError("pilot original date not within authentic pinned complete-year bounds")
    engines={x["id"]:x for x in store.plan["engines"]}
    if set(engines)!={"REF-41","PROD-KT-CY"}:
        raise ValueError("unrecognized/missing original pilot engine")
    expected={
        "REF-41":("reference","unchanged_reference_Fct",PY_COMMIT,
                  "tests/normative_reference.py",PY_SOURCE_SHA,
                  report["original_python_interpreter_sha256"]),
        "PROD-KT-CY":("original","unchanged_original_Fct",KT_COMMIT,
                     "soak/Post55ProductionDateBridge.kt",
                     report["original_kotlin_bridge_source_sha256"],
                     report["original_kotlin_jar_sha256"]),
    }
    for engine_id,want in expected.items():
        e=engines[engine_id];p=e["provenance"]
        got=(p["source_class"],p["execution_method"],p["source_commit"],
             p["source_path"],e["source_sha256"],e["binary_sha256"])
        if got!=want or p["derived_from"] is not None:
            raise ValueError("supervised original source/binary not bound to immutable plan")

def _publish(store,path,content):
    staging=path.with_name(path.name+".part")
    if path.parent.is_symlink() or path.is_symlink() or staging.is_symlink():
        raise ValueError("symlink cannot be used as original pilot evidence path")
    if path.exists() and not path.is_file():
        raise ValueError("non-file evidence path cannot be overwritten")
    if staging.exists() and not staging.is_file():
        raise ValueError("non-file staging path cannot be reused")
    if path.exists():
        if path.read_bytes()!=content or staging.exists():
            raise ValueError("existing supervised witness conflict; cannot overwrite")
        return
    if staging.exists():
        if staging.read_bytes()!=content:
            raise ValueError("conflicting incomplete pilot evidence")
    else:
        store._durable_write(staging,content)
    os.replace(staging,path)
    store._sync_dir(path.parent)

def register_one_day_pilot(store,blob:bytes,*,expected_sha256:str=ZIP_SHA):
    """Record one real source pilot as noncertifying evidence, not a chunk."""
    store._assert_immutable_plan()
    store._require_active()
    if expected_sha256!=ZIP_SHA:
        raise ValueError("only independently pinned v045 original artifact permitted")
    report=verify_supervised_original_pair_archive(blob,expected_sha256=expected_sha256)
    check_plan(store,report)
    witness=canonical(report)
    root,archive_path,report_path=paths(store,expected_sha256)
    if (store.root/"evidence").is_symlink() or root.is_symlink():
        raise ValueError("unsafe symlink pilot evidence directory")
    root.mkdir(parents=True,exist_ok=True)
    # Committed witnesses cannot be healed by replay.
    prior=store.db.execute(
        "SELECT plan_sha256,report_sha256,archive_bytes,year,target_day "
        "FROM supervised_pilot_witnesses WHERE artifact_sha256=?",
        (expected_sha256,)).fetchone()
    values=(store.plan_sha,_sha(witness),len(blob),YEAR,T)
    if prior is not None:
        if prior!=values:
            raise ValueError("prior pilot SQLite receipt is inconsistent")
        check_registered_pilot_witnesses(store)
        return {"outcome":"ALREADY_RECORDED","original_native_day_pair":1,
                "original_complete_years_certified":0}
    # Prior to SQLite commit: a crashed, unindexed file may be adopted only
    # by an explicit replay of the exact pinned original artifact.
    _publish(store,archive_path,blob)
    _publish(store,report_path,witness)
    store.db.execute("BEGIN IMMEDIATE")
    try:
        store.db.execute(
            "INSERT INTO supervised_pilot_witnesses "
            "(artifact_sha256,plan_sha256,report_sha256,archive_bytes,year,target_day) "
            "VALUES(?,?,?,?,?,?)",(expected_sha256,*values))
        store.db.execute("COMMIT")
    except BaseException:
        store.db.execute("ROLLBACK")
        raise
    return {"outcome":"QUARANTINED_PILOT_RECORDED","original_native_day_pair":1,
            "original_complete_years_certified":0}

def check_registered_pilot_witnesses(store)->int:
    """Rehash the exact ZIP and re-run v047. Never repair committed records."""
    store._assert_immutable_plan()
    root=store.root/"evidence"/"supervised_pilots"
    rows=store.db.execute(
        "SELECT artifact_sha256,plan_sha256,report_sha256,archive_bytes,year,target_day "
        "FROM supervised_pilot_witnesses ORDER BY artifact_sha256").fetchall()
    if (store.root/"evidence").is_symlink() or root.is_symlink():
        raise ValueError("unsafe symlink pilot evidence directory")
    if not root.exists():
        if rows: raise ValueError("committed pilot evidence directory missing")
        return 0
    expected_names=set()
    for artifact_sha,plan_sha,report_sha,size,year,target in rows:
        if (artifact_sha!=ZIP_SHA or plan_sha!=store.plan_sha or
            year!=YEAR or target!=T):
            raise ValueError("pilot SQLite coordinates/plan differ")
        _,archive_path,report_path=paths(store,artifact_sha)
        expected_names.update((archive_path.name,report_path.name))
        for path in (archive_path,report_path):
            if not path.is_file() or path.is_symlink() or \
               path.with_name(path.name+".part").exists():
                raise ValueError("committed pilot witness missing or partially staged")
        blob=archive_path.read_bytes();saved=report_path.read_bytes()
        if _sha(blob)!=artifact_sha or len(blob)!=size or _sha(saved)!=report_sha:
            raise ValueError("pilot ZIP/report altered since SQLite commit")
        report=verify_supervised_original_pair_archive(blob,expected_sha256=artifact_sha)
        check_plan(store,report)
        if canonical(report)!=saved:
            raise ValueError("pilot report cannot be reproduced from pinned original evidence")
    unindexed=sorted(p.name for p in root.iterdir() if p.name not in expected_names)
    if unindexed:
        raise ValueError("unindexed pilot files require explicit source replay: "+repr(unindexed))
    return len(rows)
