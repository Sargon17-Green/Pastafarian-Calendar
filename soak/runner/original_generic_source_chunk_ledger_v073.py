#!/usr/bin/env python3
"""v073: source-bound generic import of FROZEN ORIGINAL REF-41 two-day chunks.

New chunks 1017..2121 use ONE implementation, per-ordinal SHA-pinned,
independently audited original process ZIPs, a separate immutable witness
table and original_process_chunk_links. This module never runs F(c,t).

Trust boundary: first import requires the two unchanged original source
checkouts and validates native OS process receipts through v072. Recovery
checks exact archived bytes/semantic rows, NOT renewed independent
algorithmic provenance or externally signed OS process identity.

A source ZIP witness and a committed chunk/link are separate transactions:
default crash recovery fails closed when a committed chunk loses its link.
Only explicit re-import of the SAME source archive and frozen source
snapshots may restore the link. Kotlin candidate cannot commit until
the whole Python source year has completed.
"""
from __future__ import annotations

import hashlib
from pathlib import Path
from native_execution_receipt_v038 import canonical,make_receipt
from quarantined_pilot_ledger_v048 import _publish
from original_chunk_artifact_gate_v072 import (
    archive_files,audit_pinned_original_chunk,validate_coordinates,json_unique
)
from original_ref41_year_chunk_import_v059 import (
    ENGINE,YEAR,locked_full_year_experimental_plan
)

SCHEMA="PASTAFARI_GENERIC_ORIGINAL_SOURCE_CHUNK_LEDGER_V073/1"
FIRST_NEW=1017
LAST_NEW=2121
TABLE="original_generic_source_chunk_witnesses"


def digest(data:bytes)->str:
    return hashlib.sha256(data).hexdigest()


def manifest_for(ordinal:int)->tuple[dict,str]:
    """One *checked-in* externally pinned control document per new chunk."""
    if type(ordinal) is not int or not FIRST_NEW<=ordinal<=LAST_NEW:
        raise ValueError("original generic chunk ordinal outside 1017..2121")
    control=Path(__file__).resolve().parents[1]/"control"
    files=list(control.glob(f"original_native_chunk{ordinal}_pin_v*.json"))
    if len(files)!=1 or files[0].is_symlink() or not files[0].is_file():
        raise ValueError("exactly one committed SHA-pinned original chunk manifest required")
    raw=files[0].read_bytes()
    pin=json_unique(raw)
    _,year,first,last,actual=validate_coordinates(pin)
    if actual!=ordinal or year!=YEAR:
        raise ValueError("original pin ordinal and source-year identity differ")
    return pin,digest(raw)


def witness_paths(store,ordinal:int,pin:dict):
    root=store.root/"evidence"/"original_generic_source_chunks"
    folder=root/str(ordinal)
    sha=pin["artifact_sha256"]
    return root,folder,folder/(sha+".zip"),folder/(sha+".report.json")


def _check_paths(store,root:Path,folder:Path):
    if (store.root/"evidence").is_symlink() or root.is_symlink() or folder.is_symlink():
        raise ValueError("generic source evidence symlink directory prohibited")


def offline_original_chunk(archive:bytes,pin:dict)->dict:
    """Integrity replay only. Source checkouts are needed at initial import."""
    c,year,first,last,ordinal=validate_coordinates(pin)
    files=archive_files(archive,pin)
    original=files["REF-41/native-raw.jsonl"].splitlines(keepends=True)
    normalized=files["REF-41/native-normalized.jsonl"].splitlines(keepends=True)
    kotlin=files["PROD-KT-CY/os-stdout.tsv"].splitlines(keepends=True)
    if not(len(original)==len(normalized)==len(kotlin)==2):
        raise ValueError("generic original chunk has incomplete native date rows")
    py=json_unique(files["REF-41/process-evidence.json"],canonical_bytes=True)
    kt=json_unique(files["PROD-KT-CY/process-evidence.json"],canonical_bytes=True)
    verdict=json_unique(files["original-two-day-verdict.json"],canonical_bytes=True)
    dispatch=json_unique(files["original-ordinal-dispatch.json"],canonical_bytes=True)
    if not (py["source_commit"]==pin["original_source_commits"]["REF-41"] and
            kt["source_commit"]==pin["original_source_commits"]["PROD-KT-CY"] and
            py["exit_code"]==kt["exit_code"]==0 and
            py["native_rows_validated"]==kt["native_rows_validated"]==2 and
            py["boundary_evidence_sha256"]==kt["boundary_evidence_sha256"]==
                pin["original_source_year"]["boundary_evidence_sha256"] and
            py["whole_original_year_soak_passes"]==kt["whole_original_year_soak_passes"]==0 and
            verdict["schema"]=="PASTAFARI_SUPERVISED_ORIGINAL_ORDINAL_CHUNK_V070/1" and
            verdict["full_year_chunk_ordinal"]==ordinal and
            verdict["matched_original_day_pairs"]==2 and
            verdict["first_mismatch"] is None and
            verdict["original_complete_years_soak_passed"]==0 and
            dispatch["schema"]=="PASTAFARI_SUPERVISED_ORDINAL_DISPATCH_RECEIPT_V070/1" and
            dispatch["ordinal"]==ordinal and
            dispatch["native_verdict_sha256"]==digest(files["original-two-day-verdict.json"])):
        raise ValueError("generic original process/output source receipts mismatched")
    for i,target in enumerate((first,last)):
        src=json_unique(original[i])
        norm=json_unique(normalized[i])
        expected=pin["native_rows"][i]
        line=kotlin[i]
        try:
            fields=line.decode("ascii").rstrip("\n").split("\t")
        except UnicodeError as ex:
            raise ValueError("original Kotlin source row non-ASCII") from ex
        values=[norm[k] for k in ("year","cutlet_index","day_in_cutlet","month_index","day_in_month")]
        if (not line.endswith(b"\n") or b"\r" in line or len(fields)!=7 or
            fields[:3]!=[c,target,year] or
            not all(t.isdecimal() for t in fields[3:]) or
            values!=[year,*[int(t) for t in fields[3:]]] or
            norm["calculation_day"]!=c or norm["target_day"]!=target or
            src["calculation_day"]!=c or src["target_day"]!=target or
            norm["source_raw_sha256"]!=digest(original[i]) or
            norm["source_raw_sha256"]!=expected["source_raw_sha256"] or
            values!=[expected[k] for k in ("year","cutlet_index","day_in_cutlet",
                                           "month_index","day_in_month")] or
            norm["cutlet_name_raw"]!=expected["cutlet_name_raw"] or
            norm["month_name_raw"]!=expected["month_name_raw"] or
            src["native_names"]["cutlet"]!=norm["cutlet_name_raw"] or
            src["native_names"]["month"]!=norm["month_name_raw"]):
            raise ValueError("original chunk native Python/Kotlin fields differ")
    return {
        "schema":SCHEMA,"status":"PINNED_ORIGINAL_SOURCE_CHUNK_INTEGRITY_REPLAY_ONLY",
        "ordinal":ordinal,"year":year,
        "first_target_day":first,"last_target_day":last,
        "original_native_date_pairs":2,
        "python_normalized_sha256":digest(files["REF-41/native-normalized.jsonl"]),
        "python_raw_sha256":digest(files["REF-41/native-raw.jsonl"]),
        "python_os_process_receipt_sha256":digest(files["REF-41/process-evidence.json"]),
        "source_lineage_certified":False,"canonical_oracle_certified":False,
        "independently_attested_OS_process":False,"original_full_years_certified":0
    }


def check_generic_witnesses(store,*,explicit_replay_ordinal:int|None=None)->int:
    """Crash-safe immutable archive verification without original source trees.

    When a committed chunk exists, its original_process_chunk_links row MUST
    exist except during an explicit re-import authorized only for that chunk.
    """
    store._assert_immutable_plan()
    root=store.root/"evidence"/"original_generic_source_chunks"
    if (store.root/"evidence").is_symlink() or root.is_symlink():
        raise ValueError("generic original archive evidence root symlink")
    rows=store.db.execute(
        "SELECT ordinal,artifact_sha256,plan_sha256,manifest_sha256,"
        "report_sha256,archive_bytes FROM original_generic_source_chunk_witnesses "
        "ORDER BY ordinal").fetchall()
    if not root.exists():
        if rows:
            raise ValueError("registered original generic ZIP root disappeared")
        return 0
    if not root.is_dir():
        raise ValueError("generic original source archive root is not a directory")
    expected_directories=set()
    for ordinal,archive_sha,plan_sha,manifest_sha,report_sha,size in rows:
        pin,actual_manifest_sha=manifest_for(ordinal)
        root2,folder,zipped,report=witness_paths(store,ordinal,pin)
        _check_paths(store,root2,folder)
        if (root2!=root or archive_sha!=pin["artifact_sha256"] or
            plan_sha!=store.plan_sha or manifest_sha!=actual_manifest_sha or
            not folder.is_dir()):
            raise ValueError("generic original witness manifest/plan/dir changed")
        expected_directories.add(str(ordinal))
        if any(not p.is_file() or p.is_symlink() or
               p.with_name(p.name+".part").exists() for p in (zipped,report)):
            raise ValueError("generic original witness missing or staged file")
        archive=zipped.read_bytes()
        saved=report.read_bytes()
        if len(archive)!=size or digest(archive)!=archive_sha or digest(saved)!=report_sha:
            raise ValueError("generic original witness archive/report SHA differs")
        record=json_unique(saved,canonical_bytes=True)
        if (record.get("schema")!=SCHEMA or
            record.get("not_a_year_certificate") is not True or
            record.get("source_replay",{}).get("status")!=
                "PINNED_ORIGINAL_ORDINAL_TWO_DAYS_MATCH_NOT_YEAR" or
            record["source_replay"].get("original_years_soak_certified")!=0 or
            record.get("offline_replay")!=offline_original_chunk(archive,pin)):
            raise ValueError("generic original witness semantic proof not reproducible")
        if set(p.name for p in folder.iterdir())!={zipped.name,report.name}:
            raise ValueError("orphan generic source ZIP file, explicit replay required")
        chunk=store._chunk(ENGINE,YEAR,ordinal)
        if store._chunk_registered(chunk) is not None:
            link=store.db.execute(
                "SELECT artifact_sha256 FROM original_process_chunk_links "
                "WHERE engine=? AND year=? AND ordinal=?",
                (ENGINE,YEAR,ordinal)).fetchone()
            if link is None and explicit_replay_ordinal!=ordinal:
                raise ValueError("committed generic source chunk lost original process ZIP link")
    if set(p.name for p in root.iterdir())!=expected_directories:
        raise ValueError("unindexed generic original evidence directory requires explicit replay")
    return len(rows)


def verify_generic_source_link(
        store,row:tuple,*,generic_witnesses_prevalidated:bool=False)->None:
    engine,year,ordinal,archive_sha,raw_sha,norm_sha,receipt_sha=row
    if engine!=ENGINE or year!=YEAR:
        raise ValueError("generic source process link engine/year not original Python")
    pin,_=manifest_for(ordinal)
    if archive_sha!=pin["artifact_sha256"]:
        raise ValueError("generic original process link artifact SHA altered")
    # The standalone entrypoint remains fail-closed. The batch verifier may
    # skip only when the caller has ALREADY audited the entire witness ledger.
    if not generic_witnesses_prevalidated:
        check_generic_witnesses(store)
    _,_,archive_path,_=witness_paths(store,ordinal,pin)
    files=archive_files(archive_path.read_bytes(),pin)
    raw=files["REF-41/native-raw.jsonl"]
    norm=files["REF-41/native-normalized.jsonl"]
    process=files["REF-41/process-evidence.json"]
    if (raw_sha!=digest(raw) or norm_sha!=digest(norm) or
        receipt_sha!=digest(process)):
        raise ValueError("generic original source process link checksum altered")
    chunk=store._chunk(engine,year,ordinal)
    saved=store._chunk_registered(chunk)
    if saved!=(norm_sha,len(norm)):
        raise ValueError("generic original source chunk missing or altered")
    store._check_registered_file(chunk,saved)
    raw_path,receipt_path=store._native_receipt_paths(chunk)
    if (not raw_path.is_file() or raw_path.is_symlink() or
        raw_path.read_bytes()!=raw or receipt_path.is_symlink() or
        not receipt_path.is_file()):
        raise ValueError("generic source native process stdout/receipt sidecar changed")


def import_generic_original_ref41_chunk(
        store,ordinal:int,original_archive:bytes,
        original_v053_archive:bytes,source_root:Path,kotlin_repo:Path)->dict:
    """Exact first source import or explicit byte-identical replay after crash."""
    store._require_active()
    pin,manifest_sha=manifest_for(ordinal)
    audited=audit_pinned_original_chunk(original_archive,source_root,kotlin_repo,
                                         manifest=pin)
    require_keys=(audited["status"]=="PINNED_ORIGINAL_ORDINAL_TWO_DAYS_MATCH_NOT_YEAR"
                  and audited["ordinal"]==ordinal and
                  audited["original_years_soak_certified"]==0)
    if not require_keys:
        raise ValueError("original independent source audit did not accept manifest")
    expected_plan=locked_full_year_experimental_plan(source_root,kotlin_repo,
                                                      original_v053_archive)
    if store.plan_bytes!=canonical(expected_plan):
        raise ValueError("source year plan differs from frozen prior original source snapshot")
    year=pin["original_source_year"]
    chunk=store._chunk(ENGINE,YEAR,ordinal)
    if (chunk.first_day,chunk.last_day)!=(year["first_chunk_target_day"],
                                          year["last_chunk_target_day"]):
        raise ValueError("original source ordinal target days misaligned to year plan")
    previous=store._chunk(ENGINE,YEAR,ordinal-1)
    if store._chunk_registered(previous) is None:
        raise ValueError("generic original source chunk cannot leap over previous source chunk")
    prev_link=store.db.execute(
        "SELECT artifact_sha256 FROM original_process_chunk_links "
        "WHERE engine=? AND year=? AND ordinal=?",
        (ENGINE,YEAR,ordinal-1)).fetchone()
    if prev_link is None:
        raise ValueError("previous original source chunk has no source process link")
    # For the first generic chunk, independently verify the preceding v061 ZIP.
    if ordinal==FIRST_NEW:
        from original_next_chunk_import_v066 import verify_next_process_link
        prev_row=store.db.execute(
            "SELECT engine,year,ordinal,artifact_sha256,native_raw_sha256,"
            "normalized_sha256,process_receipt_sha256 FROM original_process_chunk_links "
            "WHERE engine=? AND year=? AND ordinal=?",
            (ENGINE,YEAR,ordinal-1)).fetchone()
        verify_next_process_link(store,prev_row)
    else:
        verify_generic_source_link(store,store.db.execute(
            "SELECT engine,year,ordinal,artifact_sha256,native_raw_sha256,"
            "normalized_sha256,process_receipt_sha256 FROM original_process_chunk_links "
            "WHERE engine=? AND year=? AND ordinal=?",
            (ENGINE,YEAR,ordinal-1)).fetchone())
    offline=offline_original_chunk(original_archive,pin)
    report=canonical({"schema":SCHEMA,"source_replay":audited,
                      "offline_replay":offline,"not_a_year_certificate":True})
    root,folder,zipped,report_path=witness_paths(store,ordinal,pin)
    _check_paths(store,root,folder)
    folder.mkdir(parents=True,exist_ok=True)
    prior=store.db.execute(
        "SELECT artifact_sha256,plan_sha256,manifest_sha256,report_sha256,archive_bytes "
        "FROM original_generic_source_chunk_witnesses WHERE ordinal=?",
        (ordinal,)).fetchone()
    expected=(pin["artifact_sha256"],store.plan_sha,manifest_sha,
              digest(report),len(original_archive))
    if prior is not None:
        if prior!=expected:
            raise ValueError("immutable generic source witness SQLite row changed")
        check_generic_witnesses(store,explicit_replay_ordinal=ordinal)
    else:
        _publish(store,zipped,original_archive)
        _publish(store,report_path,report)
        store.db.execute("BEGIN IMMEDIATE")
        try:
            store.db.execute(
                "INSERT INTO original_generic_source_chunk_witnesses "
                "(ordinal,artifact_sha256,plan_sha256,manifest_sha256,report_sha256,archive_bytes) "
                "VALUES(?,?,?,?,?,?)",(ordinal,*expected))
            store.db.execute("COMMIT")
        except BaseException:
            store.db.execute("ROLLBACK")
            raise
    files=archive_files(original_archive,pin)
    raw=files["REF-41/native-raw.jsonl"]
    norm=files["REF-41/native-normalized.jsonl"]
    process=files["REF-41/process-evidence.json"]
    native=make_receipt(store.plan,store.plan_sha,ENGINE,YEAR,
                        chunk.first_day,chunk.last_day,ordinal,norm,raw)
    result=store.commit_chunk(ENGINE,YEAR,ordinal,norm,
                              raw_stdout=raw,native_receipt=native)
    link=(ENGINE,YEAR,ordinal,pin["artifact_sha256"],
          digest(raw),digest(norm),digest(process))
    linked=store.db.execute(
        "SELECT engine,year,ordinal,artifact_sha256,native_raw_sha256,"
        "normalized_sha256,process_receipt_sha256 FROM original_process_chunk_links "
        "WHERE engine=? AND year=? AND ordinal=?",(ENGINE,YEAR,ordinal)).fetchone()
    if linked is not None and linked!=link:
        raise ValueError("existing original generic source link differs")
    if linked is None:
        store.db.execute("BEGIN IMMEDIATE")
        try:
            store.db.execute(
                "INSERT INTO original_process_chunk_links "
                "(engine,year,ordinal,artifact_sha256,native_raw_sha256,"
                "normalized_sha256,process_receipt_sha256) VALUES(?,?,?,?,?,?,?)",link)
            store.db.execute("COMMIT")
        except BaseException:
            store.db.execute("ROLLBACK")
            raise
    verify_generic_source_link(store,link)
    progress=store.progress()
    if (progress["fully_verified_years"]!=0 or
        progress["verified_day_pair_comparisons"]!=0 or
        progress["original_native_full_year_soak_passes_certified"]!=0):
        raise ValueError("partial generic original source falsely certified whole year")
    return {"schema":SCHEMA,"outcome":result,"ordinal":ordinal,
            "source_archive_sha256":pin["artifact_sha256"],
            "original_python_source_dates_imported":2,
            "candidate_kotlin_chunk_imported":False,
            "original_complete_years_soak_certified":0,
            "source_lineage_independent_certified":False,
            "canonical_oracle_certified":False,"native_Fct_calls_during_import":0}
