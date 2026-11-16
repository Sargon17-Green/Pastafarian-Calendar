#!/usr/bin/env python3
"""v059 original two-day REF-41 baseline chunk: integrity and source-process link.

Only the exact pinned REAL v053 ZIP can enter a full 4244-day YEAR plan.
Source original checkouts are required for first import; no F(c,t) is run.
REF-41 TWO days at ordinal 1015 is imported using v038 native receipt.
Kotlin remains in separate quarantine UNTIL the full Python source year
completes; do not bypass the engine-order gate. Does not certify a year,
a canonical oracle, algorithmic independence, or OS execution attestation.

Post-commit linking is a distinct crash-replayable step: if a crash happens
after the chunk and before the source link, the chunk is unlinked, never
passed off as externally attested. Explicit replay can install the link.
"""
from __future__ import annotations

import json
from pathlib import Path

from import_verified_pilot_chunk_v039 import catalog_digest
from native_raw_pair_gate_v018 import name_maps,verify_locked_sources
from native_execution_receipt_v038 import canonical, make_receipt,sha
from quarantined_two_day_pilot_v057 import (
    ARCHIVE_SHA,FIRST,LAST,YEAR,C,verify_plan,
    check_registered_two_day_pilots
)
from recovery_store import CrashStore
from source_identity_gate_v036 import PROVENANCE_CONTRACT,IDENTITY_SCHEMA
from verify_original_two_day_artifact_v055 import (
    PIN,load_zip,json_strict,replay_native_witness
)
from supervised_original_python_kotlin_day_v045 import _original_tree

SCHEMA="PASTAFARI_REAL_ORIGINAL_REF41_TWO_DAY_YEAR_CHUNK_V059/1"
ENGINE="REF-41"
CANDIDATE="PROD-KT-CY"
CHUNK_ORDINAL=1015
CHUNK_DAYS=2
YEAR_FIRST="-15057702"
YEAR_LAST="-15053459"
YEAR_DAYS=4244


def _source_data(source_root:Path,kotlin_repo:Path,original_zip:bytes):
    pin=json_strict(PIN.read_bytes())
    if pin["artifact_sha256"]!=ARCHIVE_SHA or sha(original_zip)!=ARCHIVE_SHA:
        raise ValueError("original v053 archive is not the locked native two-day artifact")
    files=load_zip(original_zip)
    p=json_strict(files["REF-41/process-evidence.json"])
    k=json_strict(files["PROD-KT-CY/process-evidence.json"])
    orig_py,objects=verify_locked_sources(source_root,"REF-41")
    kotlin_closure,kotlin_inventory=_original_tree(kotlin_repo)
    bridge=[x for x in kotlin_inventory if x["path"]=="soak/Post55ProductionDateBridge.kt"]
    if len(bridge)!=1 or kotlin_closure!=k["source_closure_sha256"]:
        raise ValueError("original Kotlin production bridge or closure changed")
    if orig_py["commit"]!=pin["source_commits"]["REF-41"] or \
       orig_py["sources"][0]["sha256"]!=pin["source_sha256_ref41"]:
        raise ValueError("REF41 source commit and hash are no longer pinned")
    return pin,p,k,orig_py,catalog_digest(list(name_maps("REF-41",objects))),bridge[0]["sha256"],files


def locked_full_year_experimental_plan(source_root:Path,kotlin_repo:Path,
                                        original_zip:bytes)->dict:
    """A complete *planned* year; only a 2-day baseline is actually observed.

    Kotlin has no emitted Cymraeg names; its name_map_sha256 is merely a pinned
    metadata digest saying INDEX_ONLY and MUST NOT be interpreted as a native
    language catalog or evidence of independent algorithmic provenance.
    """
    pin,p,k,orig_py,py_names_sha,bridge_sha,_ =_source_data(
        source_root,kotlin_repo,original_zip)
    def engine(engine_id,alg,cls,method,source_sha,binary_sha,
               name_sha,commit,source_path,source_family,entrypoint):
        return {
            "id":engine_id,"algorithm_id":alg,"source_sha256":source_sha,
            "binary_sha256":binary_sha,"name_map_sha256":name_sha,
            "provenance":{
                "schema":IDENTITY_SCHEMA,"source_class":cls,
                "source_commit":commit,
                "repository":"Sargon17-Green/Pastafarian-Calendar",
                "source_path":source_path,"source_family":source_family,
                "native_entrypoint":entrypoint,"execution_method":method,
                "derived_from":None,"original_source_sha256":source_sha
            }
        }
    kotlin_index_metadata=sha(canonical({
        "native_bridge":"Post55ProductionDateBridge",
        "source_bridge_sha256":bridge_sha,
        "source_output":"INDEX_ONLY_NO_CYMRAEG_NAMES"
    }))
    plan={
        "contract":PROVENANCE_CONTRACT,
        "identity_contract":IDENTITY_SCHEMA,
        "soak_purpose":"EXPERIMENTAL_NATIVE_DIFFERENTIAL_UNCERTIFIED",
        "independence_audit_status":"NOT_CERTIFIED",
        "calculation_day":C,
        "chunk_days":CHUNK_DAYS,
        "years":[{
            "year":YEAR,"first_target_day":YEAR_FIRST,
            "last_target_day":YEAR_LAST,
            "boundary_evidence_sha256":pin["boundary_evidence_sha256"]
        }],
        "engines":[
            engine("REF-41","original-python-normative-41","reference",
                   "unchanged_reference_Fct",orig_py["sources"][0]["sha256"],
                   p["runtime_sha256"],py_names_sha,orig_py["commit"],
                   "tests/normative_reference.py","Python-Turkce-REF41",
                   "NormativeCalendar.calendar_date_ids"),
            engine("PROD-KT-CY","original-kotlin-production-cymraeg","original",
                   "unchanged_original_Fct",bridge_sha,
                   k["compiled_original_jar_sha256"],kotlin_index_metadata,
                   pin["source_commits"]["PROD-KT-CY"],
                   "soak/Post55ProductionDateBridge.kt","Kotlin-Cymraeg-PROD",
                   "Post55ProductionDateBridge.convert"),
        ]
    }
    from recovery_store import validate_plan
    validate_plan(plan)
    return plan


def _check_locked_plan(store:CrashStore,sources:Path,kotlin:Path,blob:bytes):
    plan=locked_full_year_experimental_plan(sources,kotlin,blob)
    if store.plan_bytes!=canonical(plan):
        raise ValueError("original year v2 plan differs from exact source hashes and native process evidence")
    chunk=store._chunk(ENGINE,YEAR,CHUNK_ORDINAL)
    if (chunk.first_day,chunk.last_day)!=(FIRST,LAST):
        raise ValueError("source two-day pilot not aligned to original complete-year chunk ordinal")
    return chunk


def check_original_process_chunk_links(store:CrashStore)->int:
    """Crash integrity: provenance link points to true original archived bytes.

    This is not a new source-repo replay, a proof of child process identity,
    or a license for whole-year completion.
    """
    store._assert_immutable_plan()
    rows=store.db.execute(
        "SELECT engine,year,ordinal,artifact_sha256,native_raw_sha256,"
        "normalized_sha256,process_receipt_sha256 "
        "FROM original_process_chunk_links ORDER BY engine,year,ordinal").fetchall()
    # Once the true pinned source process artifact and its baseline chunk
    # are both committed, the corresponding link is mandatory. A crash
    # between chunk commit and link insertion requires EXPLICIT replay.
    if (store.plan.get("contract")==PROVENANCE_CONTRACT and
        store.plan.get("calculation_day")==C and
        store.plan.get("chunk_days")==CHUNK_DAYS and
        [e["id"] for e in store.plan["engines"]]==[ENGINE,CANDIDATE] and
        YEAR in store.years and
        store.years[YEAR]["first_target_day"]==YEAR_FIRST and
        store.years[YEAR]["last_target_day"]==YEAR_LAST):
        chunk=store._chunk(ENGINE,YEAR,CHUNK_ORDINAL)
        if (chunk.first_day,chunk.last_day)==(FIRST,LAST):
            archived=store.db.execute(
                "SELECT artifact_sha256 FROM supervised_two_day_pilot_witnesses "
                "WHERE artifact_sha256=?",(ARCHIVE_SHA,)).fetchone()
            if archived is not None and store._chunk_registered(chunk) is not None:
                link=store.db.execute(
                    "SELECT artifact_sha256 FROM original_process_chunk_links "
                    "WHERE engine=? AND year=? AND ordinal=?",
                    (ENGINE,YEAR,CHUNK_ORDINAL)).fetchone()
                if link is None:
                    raise ValueError(
                        "committed original reference chunk lost source process link; "
                        "explicit exact original artifact replay required")
    # The second original chunk is also source-bound; unlike the old
    # single-chunk implementation, it has an independently sealed v061 ZIP.
    from original_next_chunk_import_v066 import (
        frozen_pin as next_pin, verify_next_process_link
    )
    if (store.plan.get("contract")==PROVENANCE_CONTRACT and
        store.plan.get("calculation_day")==C and
        store.plan.get("chunk_days")==CHUNK_DAYS and
        [e["id"] for e in store.plan["engines"]]==[ENGINE,CANDIDATE] and
        YEAR in store.years and
        store.years[YEAR]["first_target_day"]==YEAR_FIRST and
        store.years[YEAR]["last_target_day"]==YEAR_LAST):
        next_chunk=store._chunk(ENGINE,YEAR,1016)
        witness=store.db.execute(
            "SELECT artifact_sha256 FROM original_next_chunk_witnesses WHERE artifact_sha256=?",
            (next_pin()["artifact_zip_sha256"],)).fetchone()
        if witness is not None and store._chunk_registered(next_chunk) is not None:
            link=store.db.execute(
                "SELECT artifact_sha256 FROM original_process_chunk_links "
                "WHERE engine=? AND year=? AND ordinal=?",
                (ENGINE,YEAR,1016)).fetchone()
            if link is None:
                raise ValueError(
                    "original next source chunk lost process ZIP link; explicit replay required")
    if not rows:
        return 0
    # Only load first ZIP when there actually is a v059 source link.
    files=None
    if any(r[2]==CHUNK_ORDINAL for r in rows):
        check_registered_two_day_pilots(store)
        root=store.root/"evidence"/"supervised_two_day_pilots"
        zipped=root/(ARCHIVE_SHA+".zip")
        if not zipped.is_file() or zipped.is_symlink():
            raise ValueError("source process link has no immutable original artifact")
        files=load_zip(zipped.read_bytes())
    for engine,year,ordinal,artifact,raw_sha,normalized_sha,process_sha in rows:
        if ordinal==1016:
            verify_next_process_link(
                store,(engine,year,ordinal,artifact,raw_sha,normalized_sha,process_sha))
            continue
        if (engine!=ENGINE or year!=YEAR or ordinal!=CHUNK_ORDINAL or
            artifact!=ARCHIVE_SHA or files is None):
            raise ValueError("source process chunk-link engine/year/ordinal changed")
        orig_raw=files["REF-41/native-raw.jsonl"]
        orig_norm=files["REF-41/native-normalized.jsonl"]
        orig_process=files["REF-41/process-evidence.json"]
        if (sha(orig_raw)!=raw_sha or sha(orig_norm)!=normalized_sha or
            sha(orig_process)!=process_sha):
            raise ValueError("real source-process raw/normalized/receipt link mutated")
        chunk=store._chunk(engine,year,ordinal)
        row=store._chunk_registered(chunk)
        if row is None or row!=(normalized_sha,len(orig_norm)):
            raise ValueError("linked original baseline chunk is uncommitted or differs from native ZIP")
        store._check_registered_file(chunk,row)
        raw_path,receipt_path=store._native_receipt_paths(chunk)
        if raw_path.read_bytes()!=orig_raw or receipt_path.is_symlink():
            raise ValueError("native chunk source sidecar differs from true process ZIP")
    return len(rows)


def import_real_original_ref41_baseline(
        store:CrashStore,original_zip:bytes,source_root:Path,
        kotlin_repo:Path,*,expected_sha256:str=ARCHIVE_SHA)->dict:
    """One exact real source chunk: 2 of 4244 days, not year certification."""
    store._require_active()
    if expected_sha256!=ARCHIVE_SHA:
        raise ValueError("only frozen v053 native original process artifact admitted")
    source_root=source_root.resolve(strict=True)
    kotlin_repo=kotlin_repo.resolve(strict=True)
    checked=replay_native_witness(original_zip,source_root,kotlin_repo,
                                  expected_zip_sha256=ARCHIVE_SHA)
    if (checked["original_native_day_pairs_matched"]!=2 or
        checked["official_full_year_soak_passes"]!=0):
        raise ValueError("two original engine dates did not both pass independent replay")
    chunk=_check_locked_plan(store,source_root,kotlin_repo,original_zip)
    files=load_zip(original_zip)
    raw=files["REF-41/native-raw.jsonl"]
    normalized=files["REF-41/native-normalized.jsonl"]
    process=files["REF-41/process-evidence.json"]
    # Register and audit independently pinned process ZIP before any chunk
    # that might later count toward a full planned year.
    pilot=store.record_quarantined_original_two_day_pilot(
        original_zip,source_root,kotlin_repo,expected_sha256=ARCHIVE_SHA)
    if check_registered_two_day_pilots(store)!=1:
        raise ValueError("original two-day process witness was not registered")
    receipt=make_receipt(store.plan,store.plan_sha,ENGINE,YEAR,
                         FIRST,LAST,CHUNK_ORDINAL,normalized,raw)
    committed=store.commit_chunk(ENGINE,YEAR,CHUNK_ORDINAL,normalized,
                                 raw_stdout=raw,native_receipt=receipt)
    process_link=(ENGINE,YEAR,CHUNK_ORDINAL,ARCHIVE_SHA,
                  sha(raw),sha(normalized),sha(process))
    prior=store.db.execute(
        "SELECT engine,year,ordinal,artifact_sha256,native_raw_sha256,"
        "normalized_sha256,process_receipt_sha256 "
        "FROM original_process_chunk_links "
        "WHERE engine=? AND year=? AND ordinal=?",
        (ENGINE,YEAR,CHUNK_ORDINAL)).fetchone()
    if prior is not None and prior!=process_link:
        raise ValueError("original source process link conflicts with immutable prior entry")
    if prior is None:
        store.db.execute("BEGIN IMMEDIATE")
        try:
            store.db.execute(
                "INSERT INTO original_process_chunk_links "
                "(engine,year,ordinal,artifact_sha256,native_raw_sha256,"
                "normalized_sha256,process_receipt_sha256) VALUES(?,?,?,?,?,?,?)",
                process_link)
            store.db.execute("COMMIT")
        except BaseException:
            store.db.execute("ROLLBACK")
            raise
    if check_original_process_chunk_links(store)!=1:
        raise ValueError("newly committed original process chunk-link failed replay")
    p=store.progress()
    if (p["fully_verified_years"]!=0 or
        p["verified_day_pair_comparisons"]!=0 or
        p["original_native_full_year_soak_passes_certified"]!=0 or
        p["committed_chunks"]!=1 or
        p["original_process_linked_chunks_not_years"]!=1):
        raise ValueError("source baseline chunk unexpectedly promoted to a full-year result")
    return {
        "schema":SCHEMA,
        "outcome":committed,
        "native_artifact_registration":pilot["outcome"],
        "year":YEAR,"calculation_day":C,
        "source_engine":ENGINE,"chunk_ordinal":CHUNK_ORDINAL,
        "first_target_day":FIRST,"last_target_day":LAST,
        "reference_original_rows_committed":2,
        "reference_original_year_days_planned":YEAR_DAYS,
        "candidate_kotlin_year_chunk_committed":False,
        "native_process_archive_sha256":ARCHIVE_SHA,
        "native_ref41_raw_sha256":sha(raw),
        "native_ref41_normalized_sha256":sha(normalized),
        "native_ref41_process_receipt_sha256":sha(process),
        "source_process_link_rows_verified":1,
        "algorithmic_lineage_independent_certified":False,
        "canonical_oracle_certified":False,
        "externally_attested_host_execution":False,
        "official_complete_year_soak_passes":0,
        "ten_thousand_year_soak_started":False,
        "windows_host_used":False,
    }
