#!/usr/bin/env python3
"""v066: ingest frozen *original* Python chunk #1016, no Kotlin candidate/year credit.

Requires both unchanged source repositories and original v053+v061 Actions
ZIPs at registration. Offline recovery requires only persisted exact bytes.
The witness is not an externally authenticated OS process or an independent
algorithmic-lineage certificate. Never runs F(c,t) during import/recovery.
"""
from __future__ import annotations
import hashlib
from pathlib import Path
from native_execution_receipt_v038 import canonical,make_receipt
from quarantined_pilot_ledger_v048 import _publish
from original_ref41_year_chunk_import_v059 import (
    ENGINE,YEAR,locked_full_year_experimental_plan
)
from verify_next_original_chunk_v065 import (
    audit_next_two_original_dates,original_files,frozen_pin,json_unique
)

ORDINAL=1016
FIRST="-15055670"
LAST="-15055669"
SCHEMA="PASTAFARI_NEXT_ORIGINAL_PROCESS_CHUNK_LEDGER_V066/1"

def digest(data):
    return hashlib.sha256(data).hexdigest()

def paths(store):
    sha=frozen_pin()["artifact_zip_sha256"]
    root=store.root/"evidence"/"original_next_chunk1016"
    return root,root/(sha+".zip"),root/(sha+".report.json")

def _unsafe(store,root):
    return (store.root/"evidence").is_symlink() or root.is_symlink()

def offline_receipt(archive):
    """Only recheck byte-identical pinned source data, not source-tree lineage."""
    pin=frozen_pin()
    files=original_files(archive,pin)
    p=json_unique(files["REF-41/process-evidence.json"],canonical_bytes=True)
    k=json_unique(files["PROD-KT-CY/process-evidence.json"],canonical_bytes=True)
    v=json_unique(files["original-two-day-verdict.json"],canonical_bytes=True)
    norm=[json_unique(line) for line in files["REF-41/native-normalized.jsonl"].splitlines()]
    raws=files["REF-41/native-raw.jsonl"].splitlines(keepends=True)
    kt=files["PROD-KT-CY/os-stdout.tsv"].splitlines(keepends=True)
    if len(norm)!=len(raws)!=len(kt):
        raise ValueError("original next source row count differs")
    if len(norm)!=2 or len(raws)!=2 or len(kt)!=2:
        raise ValueError("not exactly two original source date rows")
    if not (p["exit_code"]==k["exit_code"]==0
            and p["native_rows_validated"]==k["native_rows_validated"]==2
            and p["boundary_evidence_sha256"]==k["boundary_evidence_sha256"]==
                pin["original_boundary_evidence_sha256"]
            and v["full_year_chunk_ordinal"]==ORDINAL
            and v["matched_original_day_pairs"]==2 and v["first_mismatch"] is None
            and v["original_complete_years_soak_passed"]==0
            and p["whole_original_year_soak_passes"]==0
            and k["whole_original_year_soak_passes"]==0):
        raise ValueError("original process receipt or false year claim")
    for i,expected in enumerate(pin["native_date_rows"]):
        row=norm[i]
        if (row["target_day"]!=expected["target_day"]
            or row["calculation_day"]!=pin["calculation_day"]
            or row["source_raw_sha256"]!=digest(raws[i])
            or row["source_raw_sha256"]!=expected["python_raw_line_sha256"]
            or row["cutlet_name_raw"]!=expected["python_cutlet_name"]
            or row["month_name_raw"]!=expected["python_month_name"]):
            raise ValueError("original Python native fields or raw bytes changed")
        keys=("year","cutlet_index","day_in_cutlet","month_index","day_in_month")
        values=[row[k] for k in keys]
        if values!=[expected[k] for k in keys]:
            raise ValueError("original pinned date fields changed")
        tokens=kt[i].decode("ascii").rstrip("\n").split("\t")
        if (not kt[i].endswith(b"\n") or len(tokens)!=7
            or tokens[:3]!=[pin["calculation_day"],expected["target_day"],YEAR]
            or not all(x.isdecimal() for x in tokens[3:])
            or values!=[YEAR,*map(int,tokens[3:])]):
            raise ValueError("original Kotlin native stdout does not match Python")
    return {"schema":SCHEMA,"status":"TWO_ORIGINAL_SOURCE_DAYS_INTEGRITY_ONLY",
            "year":YEAR,"ordinal":ORDINAL,"first":FIRST,"last":LAST,
            "archive_sha256":pin["artifact_zip_sha256"],
            "python_raw_sha256":digest(files["REF-41/native-raw.jsonl"]),
            "python_normalized_sha256":digest(files["REF-41/native-normalized.jsonl"]),
            "python_process_receipt_sha256":digest(files["REF-41/process-evidence.json"]),
            "source_lineage_certified":False,"host_process_attested":False,
            "canonical_oracle_certified":False,"original_years_certified":0}

def check_registered_next_chunk_witnesses(store):
    store._assert_immutable_plan()
    root,zipped,report=paths(store)
    if _unsafe(store,root):
        raise ValueError("next chunk ZIP directory symlink rejected")
    records=store.db.execute(
        "SELECT artifact_sha256,plan_sha256,report_sha256,artifact_bytes,year,ordinal "
        "FROM original_next_chunk_witnesses ORDER BY artifact_sha256").fetchall()
    if not root.exists():
        if records:raise ValueError("original next ZIP witness directory disappeared")
        return 0
    if not root.is_dir():
        raise ValueError("original next source ZIP directory invalid")
    expected=set()
    for artifact_sha,plan_sha,report_sha,size,year,ordinal in records:
        if (artifact_sha!=frozen_pin()["artifact_zip_sha256"]
            or plan_sha!=store.plan_sha or year!=YEAR or ordinal!=ORDINAL):
            raise ValueError("original next source witness SQLite identity tampered")
        expected.update((zipped.name,report.name))
        if any(not x.is_file() or x.is_symlink() or x.with_name(x.name+".part").exists()
               for x in (zipped,report)):
            raise ValueError("original next source witness file missing or staged")
        original=zipped.read_bytes();saved=report.read_bytes()
        if len(original)!=size or digest(original)!=artifact_sha or digest(saved)!=report_sha:
            raise ValueError("original next source witness file changed since commit")
        r=json_unique(saved,canonical_bytes=True)
        if (r["schema"]!=SCHEMA or r["not_year_chunk"] is not True
            or r["offline_recheck"]!=offline_receipt(original)
            or r["source_replay"]["status"]!="PINNED_NEXT_TWO_REAL_ORIGINAL_DATES_REVALIDATED_NOT_YEAR"
            or r["source_replay"]["original_full_year_soak_passes_certified"]!=0):
            raise ValueError("original next source witness report not reproducible")
    if {p.name for p in root.iterdir()}!=expected:
        raise ValueError("unindexed original next chunk ZIP files require explicit replay")
    return len(records)

def verify_next_process_link(store,row):
    engine,year,ordinal,artifact,raw_sha,norm_sha,process_sha=row
    pin=frozen_pin()
    if (engine!=ENGINE or year!=YEAR or ordinal!=ORDINAL
        or artifact!=pin["artifact_zip_sha256"]):
        raise ValueError("unknown next source process link identity")
    if check_registered_next_chunk_witnesses(store)!=1:
        raise ValueError("next original source-process link missing witness")
    _,zipped,_=paths(store)
    files=original_files(zipped.read_bytes(),pin)
    raw=files["REF-41/native-raw.jsonl"]
    norm=files["REF-41/native-normalized.jsonl"]
    process=files["REF-41/process-evidence.json"]
    if (raw_sha!=digest(raw) or norm_sha!=digest(norm)
        or process_sha!=digest(process)):
        raise ValueError("next original source process link SHA differs")
    chunk=store._chunk(engine,year,ordinal)
    registered=store._chunk_registered(chunk)
    if registered!=(norm_sha,len(norm)):
        raise ValueError("next original source chunk registration absent or corrupted")
    store._check_registered_file(chunk,registered)
    raw_path,receipt_path=store._native_receipt_paths(chunk)
    if (raw_path.is_symlink() or receipt_path.is_symlink()
        or raw_path.read_bytes()!=raw or not receipt_path.is_file()):
        raise ValueError("next original source chunk raw or native receipt altered")

def import_next_original_python_chunk(store,previous_original_zip,original_next_zip,
                                      sources:Path,kotlin_repo:Path):
    """Source-bound insertion, crash-replayable, no F(c,t) calls and no year PASS."""
    store._require_active()
    pin=frozen_pin()
    # Must validate pinned sources and both real archives BEFORE any persistent write.
    audited=audit_next_two_original_dates(original_next_zip,sources,kotlin_repo,
                                          expected_sha256=pin["artifact_zip_sha256"])
    expected_plan=locked_full_year_experimental_plan(sources,kotlin_repo,
                                                      previous_original_zip)
    if store.plan_bytes!=canonical(expected_plan):
        raise ValueError("original full-year source plan changed between chunks")
    chunk=store._chunk(ENGINE,YEAR,ORDINAL)
    if (chunk.first_day,chunk.last_day)!=(FIRST,LAST):
        raise ValueError("next original source dates not aligned with year chunk")
    offline=offline_receipt(original_next_zip)
    files=original_files(original_next_zip,pin)
    receipt=canonical({"schema":SCHEMA,"source_replay":audited,
                       "offline_recheck":offline,"not_year_chunk":True})
    root,zipped,report=paths(store)
    if _unsafe(store,root):
        raise ValueError("next original source symlink directory")
    root.mkdir(parents=True,exist_ok=True)
    previous=store.db.execute(
        "SELECT plan_sha256,report_sha256,artifact_bytes,year,ordinal "
        "FROM original_next_chunk_witnesses WHERE artifact_sha256=?",
        (pin["artifact_zip_sha256"],)).fetchone()
    identity=(store.plan_sha,digest(receipt),len(original_next_zip),YEAR,ORDINAL)
    if previous is not None:
        if previous!=identity:
            raise ValueError("prior next-original source ZIP witness changed")
        check_registered_next_chunk_witnesses(store)
    else:
        _publish(store,zipped,original_next_zip)
        _publish(store,report,receipt)
        store.db.execute("BEGIN IMMEDIATE")
        try:
            store.db.execute(
                "INSERT INTO original_next_chunk_witnesses "
                "(artifact_sha256,plan_sha256,report_sha256,artifact_bytes,year,ordinal)"
                " VALUES(?,?,?,?,?,?)",(pin["artifact_zip_sha256"],*identity))
            store.db.execute("COMMIT")
        except BaseException:
            store.db.execute("ROLLBACK")
            raise
    raw=files["REF-41/native-raw.jsonl"]
    norm=files["REF-41/native-normalized.jsonl"]
    process=files["REF-41/process-evidence.json"]
    native=make_receipt(store.plan,store.plan_sha,ENGINE,YEAR,FIRST,LAST,
                        ORDINAL,norm,raw)
    status=store.commit_chunk(ENGINE,YEAR,ORDINAL,norm,
                              raw_stdout=raw,native_receipt=native)
    link=(ENGINE,YEAR,ORDINAL,pin["artifact_zip_sha256"],
          digest(raw),digest(norm),digest(process))
    existing=store.db.execute(
        "SELECT engine,year,ordinal,artifact_sha256,native_raw_sha256,"
        "normalized_sha256,process_receipt_sha256 "
        "FROM original_process_chunk_links "
        "WHERE engine=? AND year=? AND ordinal=?",
        (ENGINE,YEAR,ORDINAL)).fetchone()
    if existing is not None and existing!=link:
        raise ValueError("prior original source chunk 1016 process link altered")
    if existing is None:
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
    verify_next_process_link(store,link)
    progress=store.progress()
    if (progress["fully_verified_years"]!=0
        or progress["verified_day_pair_comparisons"]!=0
        or progress["original_native_full_year_soak_passes_certified"]!=0):
        raise ValueError("partial original source chunk was falsely certified as a year")
    return {"schema":SCHEMA,"outcome":status,"chunk_ordinal":ORDINAL,
            "original_reference_source_rows":2,
            "new_witness_registered":previous is None,
            "original_full_years_certified":0,
            "kotlin_candidate_chunk_committed":False,
            "source_lineage_certified":False,
            "new_native_Fct_calls_during_import":0}
