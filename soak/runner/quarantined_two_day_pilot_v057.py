#!/usr/bin/env python3
"""v057: original v053 TWO-day process ZIP in isolated crash-safe pilot ledger.

Registration requires an actual v055 original-source replay on checked-out
frozen Python and Kotlin git repositories. Later offline recovery verifies
the exact externally pinned source ZIP, all pinned byte hashes, raw/native
date semantics and saved report SHA. Offline recovery cannot re-attest host
process identity or rediscover source code lineage. Not a native-year chunk.
"""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path

from native_execution_receipt_v038 import canonical
from quarantined_pilot_ledger_v048 import _publish
from source_identity_gate_v036 import PROVENANCE_CONTRACT
from verify_original_two_day_artifact_v055 import (
    PIN, FIRST, LAST, C, YEAR, load_zip, json_strict, replay_native_witness
)

SCHEMA="PASTAFARI_QUARANTINED_ORIGINAL_TWO_DAY_WITNESS_V057/1"
ARCHIVE_SHA="f87b2e925b4a400cff2e2469be5b873b66c89ca35498e8fcda1090ab55d5d390"
SOURCE_YEAR_FIRST="-15057702"
SOURCE_YEAR_LAST="-15053459"
SOURCE_YEAR_DAYS=4244


def digest(data:bytes)->str:
    return hashlib.sha256(data).hexdigest()


def get_paths(store):
    root=store.root/"evidence"/"supervised_two_day_pilots"
    return root,root/(ARCHIVE_SHA+".zip"),root/(ARCHIVE_SHA+".report.json")


def frozen_offline_recheck(blob:bytes)->dict:
    """Recheck immutable bytes+native fields; does NOT rerun original sources.

    External v055 original-source verification is REQUIRED before first entry.
    On subsequent recovery, the exact pinned archive is still authenticated
    but source repos need not be present, allowing crash recovery offline.
    """
    pin=json_strict(PIN.read_bytes())
    if pin["artifact_sha256"]!=ARCHIVE_SHA or digest(blob)!=ARCHIVE_SHA:
        raise ValueError("two-day original ZIP differs from immutable source pin")
    files=load_zip(blob)
    for path,expected in pin["sha256"].items():
        if path not in files or digest(files[path])!=expected:
            raise ValueError("original two-day inner ZIP data digest invalid")
    p=json_strict(files["REF-41/process-evidence.json"],canonical_check=True)
    k=json_strict(files["PROD-KT-CY/process-evidence.json"],canonical_check=True)
    verdict=json_strict(files["original-two-day-verdict.json"],canonical_check=True)
    tr=json_strict(files["REF-41/transport-receipt.json"])
    if not (p["source_commit"]==pin["source_commits"]["REF-41"] and
            k["source_commit"]==pin["source_commits"]["PROD-KT-CY"] and
            p["native_rows_validated"]==k["native_rows_validated"]==2 and
            p["exit_code"]==k["exit_code"]==0 and
            p["boundary_evidence_sha256"]==k["boundary_evidence_sha256"]==
            pin["boundary_evidence_sha256"] and
            p["whole_original_year_soak_passes"]==
            k["whole_original_year_soak_passes"]==0 and
            tr["boundary_evidence_sha256"]==pin["boundary_evidence_sha256"] and
            verdict["matched_original_day_pairs"]==2 and
            verdict["first_mismatch"] is None and
            verdict["original_complete_years_soak_passed"]==0 and
            verdict["status"]=="SUPERVISED_ORIGINAL_TWO_DAYS_MATCH_NOT_FULL_YEAR"):
        raise ValueError("source/host native pilot receipt does not match two-day contract")
    raw=files["REF-41/native-raw.jsonl"].splitlines(keepends=True)
    normalized=files["REF-41/native-normalized.jsonl"].splitlines(keepends=True)
    kotlin=files["PROD-KT-CY/os-stdout.tsv"].splitlines(keepends=True)
    if len(raw)!=len(normalized)!=len(kotlin):
        raise ValueError("original native row count mismatch")
    if not (len(raw)==len(normalized)==len(kotlin)==2):
        raise ValueError("original native two-day row count invalid")
    observed=[]
    for i,t in enumerate(range(int(FIRST),int(LAST)+1)):
        r=json_strict(raw[i]);n=json_strict(normalized[i])
        try:
            kt=kotlin[i].decode("ascii")
        except UnicodeError as ex:
            raise ValueError("Kotlin source stdout not ASCII TSV") from ex
        expected_tokens=(C,str(t),YEAR)
        fields=kt.rstrip("\n").split("\t")
        if (not kotlin[i].endswith(b"\n") or b"\r" in kotlin[i] or
                len(fields)!=7 or tuple(fields[:3])!=expected_tokens or
                not all(x.isdecimal() for x in fields[3:])):
            raise ValueError("original Kotlin Fct row malformed")
        required=("year","cutlet_index","day_in_cutlet","month_index","day_in_month")
        vals=[n[field] for field in required]
        if (n["calculation_day"]!=C or n["target_day"]!=str(t) or
                r["calculation_day"]!=C or r["target_day"]!=str(t) or
                n["source_raw_sha256"]!=digest(raw[i]) or
                vals!=[YEAR,*[int(x) for x in fields[3:]]] or
                not all(type(n[x]) is int for x in required[1:])):
            raise ValueError("original Python vs Kotlin two-day numeric fields mismatch")
        pinned=pin["canonical_five_fields_per_day"][i]
        if (n["target_day"]!=pinned["target_day"] or
                vals!=[pinned[x] for x in required] or
                n["cutlet_name_raw"]!=pinned["python_native_names"]["cutlet"] or
                n["month_name_raw"]!=pinned["python_native_names"]["month"]):
            raise ValueError("original date does not match pinned independently audited witness")
        observed.append({"target_day":str(t),"native_five_fields":vals,
                         "python_raw_line_sha256":digest(raw[i]),
                         "kotlin_os_stdout_line_sha256":digest(kotlin[i])})
    return {
        "schema":SCHEMA,"status":"FROZEN_TWO_ORIGINAL_DATES_INTEGRITY_REPLAY_NOT_NATIVE_YEAR",
        "archive_sha256":ARCHIVE_SHA,
        "original_source_commits":pin["source_commits"],
        "boundary_evidence_sha256":pin["boundary_evidence_sha256"],
        "calculation_day":C,"year":YEAR,
        "first_target_day":FIRST,"last_target_day":LAST,
        "native_date_pairs":observed,"original_native_date_pairs_verified":2,
        "source_lineage_certified":False,
        "host_process_execution_independently_attested":False,
        "canonical_oracle_certified":False,
        "official_original_years_certified":0,
        "complete_year_day_count":SOURCE_YEAR_DAYS,
    }


def verify_plan(store,blob:bytes,report:dict):
    store._assert_immutable_plan()
    pin=json_strict(PIN.read_bytes())
    if store.plan["contract"]!=PROVENANCE_CONTRACT or store.plan["calculation_day"]!=C:
        raise ValueError("two-day witness requires exact v2 experimental c")
    year=store.years.get(YEAR)
    if (not isinstance(year,dict) or year["first_target_day"]!=SOURCE_YEAR_FIRST or
        year["last_target_day"]!=SOURCE_YEAR_LAST or
        year["boundary_evidence_sha256"]!=pin["boundary_evidence_sha256"]):
        raise ValueError("two-day pilot cannot alter full original year boundaries")
    engines={e["id"]:e for e in store.plan["engines"]}
    if set(engines)!={"REF-41","PROD-KT-CY"}:
        raise ValueError("two-day pilot engine identity/number differs")
    files=load_zip(blob)
    py=json_strict(files["REF-41/process-evidence.json"])
    kt=json_strict(files["PROD-KT-CY/process-evidence.json"])
    inventory=kt["source_inventory"]
    bridge=[x for x in inventory if x["path"]=="soak/Post55ProductionDateBridge.kt"]
    if len(bridge)!=1:
        raise ValueError("Kotlin original bridge missing from source closure")
    for engine_id,source_kind,method,commit,source_path,source_sha,binary_sha in (
        ("REF-41","reference","unchanged_reference_Fct",
         pin["source_commits"]["REF-41"],"tests/normative_reference.py",
         pin["source_sha256_ref41"],py["runtime_sha256"]),
        ("PROD-KT-CY","original","unchanged_original_Fct",
         pin["source_commits"]["PROD-KT-CY"],"soak/Post55ProductionDateBridge.kt",
         bridge[0]["sha256"],kt["compiled_original_jar_sha256"]),
    ):
        desc=engines[engine_id]
        prov=desc["provenance"]
        check=(prov["source_class"],prov["execution_method"],prov["source_commit"],
               prov["source_path"],desc["source_sha256"],desc["binary_sha256"])
        if (check!=(source_kind,method,commit,source_path,source_sha,binary_sha) or
                prov["derived_from"] is not None):
            raise ValueError("two-day source/binary descriptors not bound to original process")
    if (report["original_native_date_pairs_verified"]!=2 or
        report["official_original_years_certified"]!=0):
        raise ValueError("two-day pilot report falsely certified complete year")


def _check_root(store,root:Path):
    if (store.root/"evidence").is_symlink() or root.is_symlink():
        raise ValueError("symlink evidence folder not permitted")


def register_two_day_pilot(store,artifact:bytes,sources:Path,kotlin_repo:Path,
                           *,expected_sha256:str=ARCHIVE_SHA)->dict:
    """Requires source trees on first registration, never launches F(c,t)."""
    store._assert_immutable_plan()
    store._require_active()
    if expected_sha256!=ARCHIVE_SHA:
        raise ValueError("only frozen original two-day ZIP can be registered")
    # Full verified-source audit BEFORE any persistent output.
    full=replay_native_witness(artifact,sources,kotlin_repo,
                               expected_zip_sha256=ARCHIVE_SHA)
    offline=frozen_offline_recheck(artifact)
    verify_plan(store,artifact,offline)
    record={"schema":SCHEMA,
            "source_replay":full,
            "frozen_offline_replay":offline,
            "not_a_year_chunk":True}
    evidence=canonical(record)
    root,path,report_path=get_paths(store)
    _check_root(store,root)
    root.mkdir(parents=True,exist_ok=True)
    prior=store.db.execute(
        "SELECT plan_sha256, report_sha256, artifact_bytes, year, "
        "first_target_day, last_target_day, native_pairs "
        "FROM supervised_two_day_pilot_witnesses WHERE artifact_sha256=?",
        (ARCHIVE_SHA,)).fetchone()
    keys=(store.plan_sha,digest(evidence),len(artifact),YEAR,FIRST,LAST,2)
    if prior is not None:
        if prior!=keys:
            raise ValueError("prior two-day pilot immutable SQLite receipt differs")
        check_registered_two_day_pilots(store)
        return {"outcome":"ALREADY_RECORDED","original_native_day_pairs":2,
                "original_full_years_certified":0}
    # A partially staged crash may be resumed only with the exact source ZIP.
    _publish(store,path,artifact)
    _publish(store,report_path,evidence)
    store.db.execute("BEGIN IMMEDIATE")
    try:
        store.db.execute(
            "INSERT INTO supervised_two_day_pilot_witnesses "
            "(artifact_sha256,plan_sha256,report_sha256,artifact_bytes,year,"
            "first_target_day,last_target_day,native_pairs) VALUES(?,?,?,?,?,?,?,?)",
            (ARCHIVE_SHA,*keys))
        store.db.execute("COMMIT")
    except BaseException:
        store.db.execute("ROLLBACK")
        raise
    return {"outcome":"QUARANTINED_TWO_DAY_PILOT_RECORDED",
            "original_native_day_pairs":2,"original_full_years_certified":0}


def check_registered_two_day_pilots(store)->int:
    """Offline integrity + semantic replay, not renewed original source audit."""
    store._assert_immutable_plan()
    root,path,report_path=get_paths(store)
    _check_root(store,root)
    rows=store.db.execute(
        "SELECT artifact_sha256,plan_sha256,report_sha256,artifact_bytes,"
        "year,first_target_day,last_target_day,native_pairs "
        "FROM supervised_two_day_pilot_witnesses ORDER BY artifact_sha256"
    ).fetchall()
    if not root.exists():
        if rows:
            raise ValueError("registered two-day pilot archive directory missing")
        return 0
    if not root.is_dir():
        raise ValueError("two-day pilot archive directory not regular directory")
    expected=set()
    for artifact_sha,plan_sha,report_sha,size,year,first,last,pairs in rows:
        if (artifact_sha!=ARCHIVE_SHA or plan_sha!=store.plan_sha or
            year!=YEAR or first!=FIRST or last!=LAST or pairs!=2):
            raise ValueError("two-day pilot immutable SQLite coordinates altered")
        expected.update((path.name,report_path.name))
        for item in (path,report_path):
            if not item.is_file() or item.is_symlink() or item.with_name(item.name+".part").exists():
                raise ValueError("committed two-day pilot data missing or staged")
        artifact=path.read_bytes()
        saved=report_path.read_bytes()
        if len(artifact)!=size or digest(artifact)!=ARCHIVE_SHA or digest(saved)!=report_sha:
            raise ValueError("two-day pilot ZIP or registered report corrupt")
        info=json_strict(saved,canonical_check=True)
        if (info.get("schema")!=SCHEMA or info.get("not_a_year_chunk") is not True or
            info.get("frozen_offline_replay")!=frozen_offline_recheck(artifact) or
            info.get("source_replay",{}).get("status")!=
            "PINNED_REAL_TWO_NATIVE_DAYS_REVALIDATED_NOT_YEAR_SOAK" or
            info["source_replay"].get("official_full_year_soak_passes")!=0):
            raise ValueError("two-day pilot committed report not reproducible")
        verify_plan(store,artifact,info["frozen_offline_replay"])
    if set(x.name for x in root.iterdir())!=expected:
        raise ValueError("unindexed or partial two-day pilot files require exact replay")
    return len(rows)
