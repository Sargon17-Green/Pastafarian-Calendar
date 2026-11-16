#!/usr/bin/env python3
"""v072: evidence-only replay for individually pinned original source chunks.

The verifier accepts a manifest for any 2-day ordinal in frozen year 5000,
but its normal public entrypoint reads a checked-in immutable v071 pin.
The original Python and Kotlin source repositories are required, and NO
original F(c,t) is ever executed by this code. A source process receipt is
not a third-party attestation; matching sources are not certified independent.
"""
from __future__ import annotations

import argparse
from hashlib import sha256
from io import BytesIO
import json
from pathlib import Path
import re
import stat
import zipfile

from native_execution_receipt_v038 import canonical
from native_raw_pair_gate_v018 import verify_locked_sources,name_maps
from original_bounded_chunk_gate_v050 import verify_bounded_original_chunk
from supervised_original_python_kotlin_day_v045 import _original_tree
from verify_next_original_chunk_v065 import json_unique

PIN_PATH=Path(__file__).resolve().parents[1]/"control/original_native_chunk1017_pin_v071.json"
SCHEMA="PASTAFARI_ORIGINAL_GENERALIZED_CHUNK_AUDIT_V072/1"
ENGINE_SCHEMA="PASTAFARI_SUPERVISED_ORIGINAL_ORDINAL_CHUNK_V070/1"
DISPATCH_SCHEMA="PASTAFARI_SUPERVISED_ORDINAL_DISPATCH_RECEIPT_V070/1"
BOUNDARY="ad64cc51522d7f19cb8a238e2a6a418e75203c6cbfe017c394f623edeb882e78"
DIGEST=re.compile(r"[0-9a-f]{64}\Z")


def sha(b:bytes)->str:
    return sha256(b).hexdigest()


def require(cond,reason):
    if not cond:
        raise ValueError("original chunk provenance invalid: "+reason)


def pinned_manifest()->dict:
    return json_unique(PIN_PATH.read_bytes())


def archive_files(original_zip:bytes,pin:dict)->dict:
    require(type(original_zip) is bytes and
            1<=len(original_zip)<=10*1024*1024 and
            len(original_zip)==pin["artifact_size_bytes"] and
            sha(original_zip)==pin["artifact_sha256"],
            "pinned original ZIP digest or size mismatch")
    with zipfile.ZipFile(BytesIO(original_zip)) as z:
        entries=z.infolist()
        names=[i.filename for i in entries]
        expected=pin["artifacts_file_sha256"]
        require(len(names)==len(set(names)) and set(names)==set(expected) and
                len(names)>=16 and len(names)<=64,
                "original artifact member inventory changed")
        require(all(not i.is_dir() and not (i.flag_bits&1) and
                    not stat.S_ISLNK(i.external_attr>>16) and
                    not i.filename.startswith("/") and
                    all(p not in ("",".","..") for p in i.filename.split("/")) and
                    i.file_size<=8*1024*1024 for i in entries),
                "original archive unsafe member path/type")
        require(sum(i.file_size for i in entries)<=12*1024*1024,
                "original archive inflated size exceeds cap")
        require(z.testzip() is None,"original artifact CRC failed")
        result={n:z.read(n) for n in names}
    for path,expected in pin["artifacts_file_sha256"].items():
        require(type(expected) is str and DIGEST.fullmatch(expected) is not None
                and sha(result[path])==expected,
                "original evidence member digest changed: "+path)
    return result


def validate_coordinates(pin:dict)->tuple[str,str,str,str,int]:
    year=pin["original_source_year"]
    ordinal=year["ordinal"]
    require(type(ordinal) is int and 1017<=ordinal<=2121,
            "original chunk ordinal outside never-before-run block")
    require(year["year"]=="5000" and
            year["calculation_day"]=="-15055671" and
            year["first_target_day"]=="-15057702" and
            year["last_target_day"]=="-15053459" and
            year["chunk_days"]==2 and
            year["boundary_evidence_sha256"]==BOUNDARY,
            "locked native year coordinates have changed")
    first=-15057702+2*ordinal
    require(year["first_chunk_target_day"]==str(first) and
            year["last_chunk_target_day"]==str(first+1) and
            first+1<=-15053459,
            "target days not aligned to pinned original year/chunk ordinal")
    return year["calculation_day"],year["year"],str(first),str(first+1),ordinal


def audit_pinned_original_chunk(original_zip:bytes,sources:Path,kotlin_repo:Path,
                                *,manifest:dict|None=None)->dict:
    # manifest override is for adversarial CI tests; production should rely
    # exclusively on checked-in pinned_manifest(), never metadata inside ZIP.
    pin=pinned_manifest() if manifest is None else manifest
    c,year,first,last,ordinal=validate_coordinates(pin)
    blobs=archive_files(original_zip,pin)
    py=json_unique(blobs["REF-41/process-evidence.json"],canonical_bytes=True)
    kt=json_unique(blobs["PROD-KT-CY/process-evidence.json"],canonical_bytes=True)
    tr=json_unique(blobs["REF-41/transport-receipt.json"])
    final=json_unique(blobs["original-two-day-verdict.json"],canonical_bytes=True)
    dispatch=json_unique(blobs["original-ordinal-dispatch.json"],canonical_bytes=True)

    original_py,py_sources=verify_locked_sources(sources.resolve(strict=True),"REF-41")
    cutlets,months=name_maps("REF-41",py_sources)
    kotlin_closure,kotlin_files=_original_tree(kotlin_repo.resolve(strict=True))
    require(original_py["commit"]==pin["original_source_commits"]["REF-41"]==
            py["source_commit"],"REF-41 immutable Python commit differs")
    require(len(original_py["sources"])==1 and
            original_py["sources"][0]["sha256"]==pin["python_source_sha256"] and
            py["source_shas"]==[pin["python_source_sha256"]],
            "REF-41 original source bytes differ")
    require(kt["source_commit"]==pin["original_source_commits"]["PROD-KT-CY"] and
            kotlin_closure==pin["kotlin_source_closure_sha256"]==
            kt["source_closure_sha256"] and kotlin_files==kt["source_inventory"],
            "Kotlin unchanged original source closure differs")
    require(sha(blobs["original-kotlin-v070.jar"])==
            kt["compiled_original_jar_sha256"]==pin["kotlin_jar_sha256"],
            "original Kotlin compiler JAR differs")
    require(blobs["original-kotlin-v070.jar.sha256"]==
            (pin["kotlin_jar_sha256"]+"  evidence/original-kotlin-v070.jar\n").encode(),
            "original Kotlin JAR manifest differs")
    for engine,r in (("REF-41",py),("PROD-KT-CY",kt)):
        name="ORIGINAL_PYTHON_TWO_DATE_SOURCE_PROVENANCE_CHECKED" if engine=="REF-41" \
             else "ORIGINAL_KOTLIN_TWO_DATE_SOURCE_PROVENANCE_CHECKED"
        require(r["schema"]==ENGINE_SCHEMA and r["engine"]==engine and
                r["source_commit"]==pin["original_source_commits"][engine] and
                r["status"]==name and r["blocked_reason"] is None and
                r["calculation_day"]==c and r["year"]==year and
                r["first_target_day"]==first and r["last_target_day"]==last and
                r["boundary_evidence_sha256"]==BOUNDARY and
                type(r["pid"]) is int and r["pid"]>0 and
                type(r["process_creation_id"]) is str and bool(r["process_creation_id"]) and
                r["exit_code"]==0 and r["native_rows_validated"]==2 and
                r["whole_original_year_soak_passes"]==0 and
                r["source_lineage_certified"] is False and
                r["canonical_oracle_certified"] is False and
                r["independent_process_execution_attested"] is False and
                r["resident_memory_hard_cap_enforced"] is False and
                r["original_calculation_wall_timeout_seconds"] is None,
                engine+" original process receipt or scientific status changed")
        osout=(engine+"/os-stdout.log" if engine=="REF-41"
               else engine+"/os-stdout.tsv")
        require(r["os_stdout_sha256"]==sha(blobs[osout]) and
                r["os_stderr_sha256"]==sha(blobs[engine+"/os-stderr.log"]) and
                r["argv_sha256"]==sha(canonical(r["argv"])) and
                r["argv"][0]==r["runtime_path"],
                engine+" OS process stdout/stderr or native argv modified")
    require(py["native_raw_sha256"]==sha(blobs["REF-41/native-raw.jsonl"]) and
            py["native_normalized_sha256"]==sha(blobs["REF-41/native-normalized.jsonl"]) and
            py["native_transport_receipt_sha256"]==sha(blobs["REF-41/transport-receipt.json"]),
            "original Python raw/normalized transport SHA chain broken")
    require(tr["status"]=="NATIVE_TRANSPORT_OUTPUT_COMPLETE_NOT_COMPARED" and
            tr["engine"]=="REF-41" and tr["source_commit"]==pin["original_source_commits"]["REF-41"] and
            tr["source_sha256"]==pin["python_source_sha256"] and
            tr["calculation_day"]==c and tr["first_target_day"]==first and
            tr["last_target_day"]==last and tr["rows"]==2 and
            tr["boundary_evidence_sha256"]==BOUNDARY and
            tr["raw_stream_sha256"]==sha(blobs["REF-41/native-raw.jsonl"]) and
            tr["normalized_stream_sha256"]==sha(blobs["REF-41/native-normalized.jsonl"]),
            "original native Python source transport does not match process")
    require(kt["stdin_sha256"]==sha(blobs["PROD-KT-CY/original-native-stdin.tsv"]) and
            blobs["PROD-KT-CY/original-native-stdin.tsv"]==
            (f"{c}\t{first}\n{c}\t{last}\n").encode("ascii"),
            "Kotlin source OS stdin target sequence changed")
    require(py["argv"][1:4]==["-I","-B",py["adapter_path"]] and
            "--allow-whole-year" in py["argv"] and
            "--boundary-evidence-sha256" in py["argv"] and
            BOUNDARY in py["argv"] and
            py["argv"][-5].endswith("/REF-41/native-raw.jsonl") and
            py["argv"][-3].endswith("/REF-41/native-normalized.jsonl") and
            py["argv"][-1].endswith("/REF-41/transport-receipt.json"),
            "original Python direct adapter invocation differs")
    require(kt["argv"][-3]=="-cp" and
            kt["argv"][-2].endswith("/original-kotlin-v070.jar") and
            kt["argv"][-1]=="pastafari.Post55ProductionDateBridge",
            "original Kotlin bridge invocation differs")

    gate=verify_bounded_original_chunk(
        python_original_raw=blobs["REF-41/native-raw.jsonl"],
        python_original_normalized=blobs["REF-41/native-normalized.jsonl"],
        kotlin_original_stdout=blobs["PROD-KT-CY/os-stdout.tsv"],
        calculation_day=c,year=year,first_target_day=first,last_target_day=last,
        boundary_evidence_sha256=BOUNDARY,
        frozen_python_cutlets=cutlets,frozen_python_months=months)
    kotlin_normalized=gate.pop("kotlin_index_only_normalized_jsonl")
    require(gate["status"]=="BOUNDED_ORIGINAL_CHUNK_MATCH_NOT_FULL_YEAR" and
            gate["matched_original_day_pairs"]==2 and gate["first_mismatch"] is None and
            kotlin_normalized is not None and
            blobs["kotlin-index-only-normalized.jsonl"]==kotlin_normalized,
            "unchanged original Python/Kotlin numeric date fields mismatch")
    raw_rows=blobs["REF-41/native-raw.jsonl"].splitlines(keepends=True)
    norm_rows=[json_unique(x) for x in blobs["REF-41/native-normalized.jsonl"].splitlines()]
    require(len(raw_rows)==len(norm_rows)==len(pin["native_rows"])==2,
            "native two-day original row count differs from witnessed structure")
    for original_raw,actual,expected in zip(raw_rows,norm_rows,pin["native_rows"]):
        for field in ("target_day","year","cutlet_index","day_in_cutlet","month_index","day_in_month"):
            require(actual[field]==expected[field],"original date field mismatch: "+field)
        require(actual["source_raw_sha256"]==sha(original_raw)==expected["source_raw_sha256"] and
                actual["cutlet_name_raw"]==expected["cutlet_name_raw"] and
                actual["month_name_raw"]==expected["month_name_raw"],
                "unchanged Python raw name/line SHA differs from external pin")
    require(final["schema"]==ENGINE_SCHEMA and
            final["status"]=="SUPERVISED_ORIGINAL_TWO_DAYS_MATCH_NOT_FULL_YEAR" and
            final["matched_original_day_pairs"]==2 and
            final["first_mismatch"] is None and
            final["halt_new_dispatch"] is False and
            final["full_year_chunk_ordinal"]==ordinal and
            final["first_target_day"]==first and final["last_target_day"]==last and
            final["original_complete_years_soak_passed"]==0 and
            final["original_full_year_soak_passes_certified"]==0 and
            final["canonical_oracle_certified"] is False and
            final["algorithmic_independence_certified"] is False and
            final["python_raw_sha256"]==gate["python_raw_sha256"] and
            final["kotlin_os_stdout_sha256"]==gate["kotlin_os_stdout_sha256"],
            "final original two-day supervisor verdict invalid")
    require(dispatch["schema"]==DISPATCH_SCHEMA and
            dispatch["status"]=="TWO_REAL_ORIGINAL_SOURCE_DAYS_NOT_YEAR" and
            dispatch["ordinal"]==ordinal and
            dispatch["first_target_day"]==first and dispatch["last_target_day"]==last and
            dispatch["calculation_day"]==c and dispatch["year"]==year and
            dispatch["runner_wrapper_sha256"]==pin["process_runner_sha256"] and
            dispatch["inherited_supervisor_v061_sha256"]==pin["inherited_supervisor_sha256"] and
            dispatch["native_verdict_sha256"]==sha(blobs["original-two-day-verdict.json"]) and
            dispatch["ref41_native_process_sha256"]==sha(blobs["REF-41/process-evidence.json"]) and
            dispatch["kotlin_native_process_sha256"]==sha(blobs["PROD-KT-CY/process-evidence.json"]) and
            dispatch["original_native_date_pairs_compared"]==2 and
            dispatch["full_original_years_soak_certified"]==0 and
            dispatch["source_lineage_independence_certified"] is False and
            dispatch["canonical_oracle_certified"] is False,
            "original ordinal dispatch receipt not bound to original source processes")
    return {
        "schema":SCHEMA,"status":"PINNED_ORIGINAL_ORDINAL_TWO_DAYS_MATCH_NOT_YEAR",
        "ordinal":ordinal,"calculation_day":c,"year":year,
        "first_target_day":first,"last_target_day":last,
        "original_source_pairs":2,"original_numeric_date_fields_per_pair":5,
        "original_raw_sha256":sha(blobs["REF-41/native-raw.jsonl"]),
        "original_normalized_sha256":sha(blobs["REF-41/native-normalized.jsonl"]),
        "original_ref41_process_sha256":sha(blobs["REF-41/process-evidence.json"]),
        "original_kotlin_stdout_sha256":sha(blobs["PROD-KT-CY/os-stdout.tsv"]),
        "artifact_sha256":pin["artifact_sha256"],
        "original_years_soak_certified":0,
        "independent_lineage_certified":False,
        "canonical_oracle_certified":False,
        "external_host_attestation_certified":False,
        "windows_workload_started":False
    }


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--archive",type=Path,required=True)
    parser.add_argument("--source-root",type=Path,required=True)
    parser.add_argument("--kotlin-repo",type=Path,required=True)
    args=parser.parse_args()
    result=audit_pinned_original_chunk(args.archive.read_bytes(),
                                       args.source_root,args.kotlin_repo)
    print("V072_ORIGINAL_CHUNK_REAUDIT="+json.dumps(result,sort_keys=True))


if __name__=="__main__":
    main()
