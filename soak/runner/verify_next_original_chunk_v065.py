#!/usr/bin/env python3
"""v065: independently replay pinned v061 NEXT TWO original F(c,t) process ZIP.

Reads original GitHub Actions ZIP and frozen Python and Kotlin source trees.
This is evidence-only; DOES NOT launch any original converter. No year PASS,
algorithmic independence or external host-process attestation can be inferred.
"""
from __future__ import annotations

import argparse
from hashlib import sha256 as _sha256
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

PIN_PATH=Path(__file__).resolve().parents[1]/"control/supervised_next_two_original_dates_v064.json"
SCHEMA="PASTAFARI_NEXT_TWO_ORIGINAL_ARTIFACT_RECHECK_V065/1"
HEX=re.compile(r"[a-f0-9]{64}\Z")


def sha(data:bytes)->str:
    return _sha256(data).hexdigest()


def insist(condition:bool,why:str)->None:
    if not condition:
        raise ValueError("v065 invalid original process evidence: "+why)


def json_unique(blob:bytes,*,canonical_bytes=False)->dict:
    def unique(items):
        result={}
        for key,value in items:
            if key in result:
                raise ValueError("duplicate original JSON key: "+key)
            result[key]=value
        return result
    row=json.loads(blob.decode("utf8"),object_pairs_hook=unique,
                   parse_constant=lambda x:(_ for _ in ()).throw(ValueError("nonfinite JSON "+x)))
    insist(type(row) is dict,"JSON not an object")
    if canonical_bytes:
        insist(blob==canonical(row),"process receipt bytes are not canonical")
    return row


def frozen_pin()->dict:
    return json_unique(PIN_PATH.read_bytes())


def original_files(original_zip:bytes,pin:dict)->dict[str,bytes]:
    insist(type(original_zip) is bytes and len(original_zip)==pin["artifact_zip_bytes"]
           and sha(original_zip)==pin["artifact_zip_sha256"],
           "original v061 ZIP size/SHA differs from independent pin")
    insist(len(original_zip)<10*1024*1024,"original ZIP size exceeds guard")
    with zipfile.ZipFile(BytesIO(original_zip)) as z:
        infos=z.infolist()
        names=[x.filename for x in infos]
        allowed=pin["artifact_files_sha256"]
        insist(set(names)==set(allowed) and len(names)==len(set(names))
               and len(names)==18,"original GitHub Actions ZIP members changed")
        insist(all(not x.is_dir() and not (x.flag_bits&1)
                   and not stat.S_ISLNK(x.external_attr>>16)
                   and not x.filename.startswith("/")
                   and not any(p in (".","..","") for p in x.filename.split("/"))
                   and x.file_size<=8*1024*1024 for x in infos),
               "unsafe original ZIP member path/type")
        insist(sum(x.file_size for x in infos)<=12*1024*1024,
               "ZIP inflated size limit exceeded")
        insist(z.testzip() is None,"ZIP CRC failed")
        blobs={name:z.read(name) for name in names}
    for name,digest in allowed.items():
        insist(isinstance(digest,str) and HEX.fullmatch(digest) is not None
               and sha(blobs[name])==digest,"pinned original file differs: "+name)
    return blobs


def audit_next_two_original_dates(original_zip:bytes,sources:Path,kotlin:Path,
                                  *,expected_sha256:str)->dict:
    pin=frozen_pin()
    insist(expected_sha256==pin["artifact_zip_sha256"],"caller ZIP checksum not independently pinned")
    blobs=original_files(original_zip,pin)
    p=json_unique(blobs["REF-41/process-evidence.json"],canonical_bytes=True)
    k=json_unique(blobs["PROD-KT-CY/process-evidence.json"],canonical_bytes=True)
    v=json_unique(blobs["original-two-day-verdict.json"],canonical_bytes=True)
    tr=json_unique(blobs["REF-41/transport-receipt.json"])
    orig_py,py_files=verify_locked_sources(sources.resolve(strict=True),"REF-41")
    py_cutlets,py_months=name_maps("REF-41",py_files)
    closure,inventory=_original_tree(kotlin.resolve(strict=True))
    insist(orig_py["commit"]==pin["original_source_commits"]["REF-41"]==p["source_commit"],
           "unchanged original Python commit mismatch")
    insist(len(orig_py["sources"])==1 and
           orig_py["sources"][0]["sha256"]==pin["python_original_source_sha256"]
           and p["source_shas"]==[pin["python_original_source_sha256"]],
           "original Python source bytes differ")
    insist(k["source_commit"]==pin["original_source_commits"]["PROD-KT-CY"] and
           closure==pin["kotlin_original_source_closure_sha256"]==
           k["source_closure_sha256"] and inventory==k["source_inventory"],
           "original Kotlin source closure differs")
    bridge=[f for f in inventory if f["path"]=="soak/Post55ProductionDateBridge.kt"]
    insist(len(bridge)==1 and bridge[0]["sha256"]==
           pin["kotlin_bridge_original_source_sha256"],"original production bridge source differs")
    insist(sha(blobs["original-kotlin-v061.jar"])==pin["kotlin_original_jar_sha256"]==
           k["compiled_original_jar_sha256"],"compiled original Kotlin JAR bytes differ")
    insist(blobs["original-kotlin-v061.jar.sha256"]==
           (pin["kotlin_original_jar_sha256"]+"  evidence/original-kotlin-v061.jar\n").encode(),
           "original JAR manifest differs")
    for name,r in (("REF-41",p),("PROD-KT-CY",k)):
        insist(r["schema"]=="PASTAFARI_SUPERVISED_NEXT_TWO_ORIGINAL_DAYS_V061/1"
               and r["engine"]==name and r["source_commit"]==pin["original_source_commits"][name]
               and type(r["pid"]) is int and r["pid"]>0
               and type(r["process_creation_id"]) is str and r["process_creation_id"]
               and r["exit_code"]==0 and r["native_rows_validated"]==2
               and r["status"]==("ORIGINAL_PYTHON_TWO_DATE_SOURCE_PROVENANCE_CHECKED"
                                if name=="REF-41" else "ORIGINAL_KOTLIN_TWO_DATE_SOURCE_PROVENANCE_CHECKED")
               and r["blocked_reason"] is None
               and r["calculation_day"]==pin["calculation_day"] and r["year"]==pin["year"]
               and r["first_target_day"]==pin["first_target_day"]
               and r["last_target_day"]==pin["last_target_day"]
               and r["boundary_evidence_sha256"]==pin["original_boundary_evidence_sha256"]
               and r["whole_original_year_soak_passes"]==0
               and r["source_lineage_certified"] is False
               and r["canonical_oracle_certified"] is False
               and r["independent_process_execution_attested"] is False
               and r["resident_memory_hard_cap_enforced"] is False
               and r["original_calculation_wall_timeout_seconds"] is None,
               name+" process receipt does not attest this precise original calculation")
        for receipt_key,stream in (
            ("os_stderr_sha256",name+"/os-stderr.log"),
            ("os_stdout_sha256",name+("/os-stdout.log" if name=="REF-41" else "/os-stdout.tsv"))
        ):
            insist(sha(blobs[stream])==r[receipt_key],name+" untrusted stdout/stderr bytes")
        insist(sha(canonical(r["argv"]))==r["argv_sha256"],name+" native process argv modified")
        insist(r["argv"][0]==r["runtime_path"],name+" native executable path differs")
    insist(p["runtime_sha256"]==pin["python_runtime_sha256"]
           and k["compiled_original_jar_sha256"]==pin["kotlin_original_jar_sha256"],
           "source binary identity mismatch")
    insist(p["native_raw_sha256"]==sha(blobs["REF-41/native-raw.jsonl"])
           and p["native_normalized_sha256"]==sha(blobs["REF-41/native-normalized.jsonl"])
           and p["native_transport_receipt_sha256"]==sha(blobs["REF-41/transport-receipt.json"]),
           "original Python native raw/normalized/transport receipts inconsistent")
    insist(tr["status"]=="NATIVE_TRANSPORT_OUTPUT_COMPLETE_NOT_COMPARED"
           and tr["boundary_evidence_sha256"]==pin["original_boundary_evidence_sha256"]
           and tr["engine"]=="REF-41"
           and tr["source_commit"]==pin["original_source_commits"]["REF-41"]
           and tr["source_sha256"]==pin["python_original_source_sha256"]
           and tr["calculation_day"]==pin["calculation_day"]
           and tr["first_target_day"]==pin["first_target_day"]
           and tr["last_target_day"]==pin["last_target_day"]
           and tr["rows"]==2 and tr["verified_comparisons_completed"]==0
           and tr["raw_stream_sha256"]==sha(blobs["REF-41/native-raw.jsonl"])
           and tr["normalized_stream_sha256"]==sha(blobs["REF-41/native-normalized.jsonl"]),
           "original Python transport source/boundary/rows changed")
    insist(blobs["PROD-KT-CY/original-native-stdin.tsv"]==
           "".join(f'{pin["calculation_day"]}\t{t}\n'
                   for t in range(int(pin["first_target_day"]),
                                  int(pin["last_target_day"])+1)).encode("ascii")
           and k["stdin_sha256"]==sha(blobs["PROD-KT-CY/original-native-stdin.tsv"]),
           "original Kotlin stdin target sequence not pinned")
    insist(p["argv"][1:4]==["-I","-B",p["adapter_path"]]
           and "--allow-whole-year" in p["argv"]
           and "--boundary-evidence-sha256" in p["argv"]
           and pin["original_boundary_evidence_sha256"] in p["argv"]
           and p["argv"][-5].endswith("/REF-41/native-raw.jsonl")
           and p["argv"][-3].endswith("/REF-41/native-normalized.jsonl")
           and p["argv"][-1].endswith("/REF-41/transport-receipt.json"),
           "Python original adapter invocation or outputs changed")
    insist(k["argv"][-3]=="-cp" and
           k["argv"][-2].endswith("/original-kotlin-v061.jar") and
           k["argv"][-1]=="pastafari.Post55ProductionDateBridge",
           "Kotlin original production main class changed")
    checked=verify_bounded_original_chunk(
        python_original_raw=blobs["REF-41/native-raw.jsonl"],
        python_original_normalized=blobs["REF-41/native-normalized.jsonl"],
        kotlin_original_stdout=blobs["PROD-KT-CY/os-stdout.tsv"],
        calculation_day=pin["calculation_day"],year=pin["year"],
        first_target_day=pin["first_target_day"],last_target_day=pin["last_target_day"],
        boundary_evidence_sha256=pin["original_boundary_evidence_sha256"],
        frozen_python_cutlets=py_cutlets,frozen_python_months=py_months)
    kotlin_normalized=checked.pop("kotlin_index_only_normalized_jsonl")
    insist(checked["matched_original_day_pairs"]==2
           and checked["first_mismatch"] is None
           and checked["status"]=="BOUNDED_ORIGINAL_CHUNK_MATCH_NOT_FULL_YEAR"
           and kotlin_normalized is not None
           and blobs["kotlin-index-only-normalized.jsonl"]==kotlin_normalized,
           "original two-date comparison not reproducible")
    rows=[json_unique(line) for line in blobs["REF-41/native-normalized.jsonl"].splitlines()]
    insist(len(rows)==len(pin["native_date_rows"])==2,"original date row count changed")
    for actual,pinned in zip(rows,pin["native_date_rows"]):
        for key in ("target_day","year","cutlet_index","day_in_cutlet","month_index","day_in_month"):
            insist(actual[key]==pinned[key],"original native date field "+key+" differs")
        insist(actual["cutlet_name_raw"]==pinned["python_cutlet_name"]
               and actual["month_name_raw"]==pinned["python_month_name"]
               and actual["source_raw_sha256"]==pinned["python_raw_line_sha256"],
               "original Python source names or native raw line SHA changed")
    insist(v["schema"]=="PASTAFARI_SUPERVISED_NEXT_TWO_ORIGINAL_DAYS_V061/1"
           and v["status"]=="SUPERVISED_ORIGINAL_TWO_DAYS_MATCH_NOT_FULL_YEAR"
           and v["matched_original_day_pairs"]==2
           and v["full_year_chunk_ordinal"]==1016 and v["chunk_days"]==2
           and v["original_full_year_length"]==4244 and v["first_mismatch"] is None
           and v["halt_new_dispatch"] is False
           and v["original_complete_years_soak_passed"]==0
           and v["python_raw_sha256"]==checked["python_raw_sha256"]
           and v["python_normalized_sha256"]==checked["python_normalized_sha256"]
           and v["kotlin_os_stdout_sha256"]==checked["kotlin_os_stdout_sha256"]
           and v["canonical_oracle_certified"] is False
           and v["algorithmic_independence_certified"] is False
           and v["windows_workload_started"] is False,
           "original v061 final supervisor verdict differs from observed rows")
    return {
        "schema":SCHEMA,"status":"PINNED_NEXT_TWO_REAL_ORIGINAL_DATES_REVALIDATED_NOT_YEAR",
        "artifact_sha256":pin["artifact_zip_sha256"],
        "year":pin["year"],"calculation_day":pin["calculation_day"],
        "chunk_ordinal":pin["chunk_ordinal"],"first_target_day":pin["first_target_day"],
        "last_target_day":pin["last_target_day"],
        "original_reference_rows":2,"original_native_day_pairs_compared":2,
        "python_original_raw_sha256":sha(blobs["REF-41/native-raw.jsonl"]),
        "python_original_normalized_sha256":sha(blobs["REF-41/native-normalized.jsonl"]),
        "kotlin_original_stdout_sha256":sha(blobs["PROD-KT-CY/os-stdout.tsv"]),
        "source_commits":pin["original_source_commits"],
        "independent_algorithmic_lineage_certified":False,
        "canonical_oracle_certified":False,
        "external_os_process_attestation_certified":False,
        "original_full_year_soak_passes_certified":0
    }


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--artifact",type=Path,required=True)
    parser.add_argument("--source-root",type=Path,required=True)
    parser.add_argument("--kotlin-repo",type=Path,required=True)
    args=parser.parse_args()
    pin=frozen_pin()
    result=audit_next_two_original_dates(args.artifact.read_bytes(),
                                         args.source_root,args.kotlin_repo,
                                         expected_sha256=pin["artifact_zip_sha256"])
    print("V065="+json.dumps(result,sort_keys=True))
