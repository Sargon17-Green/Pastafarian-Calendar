#!/usr/bin/env python3
"""Reconcile PINNED v045 original Python/Kotlin process artifact without altering receipts.

This gate re-verifies an observed CI ZIP (including real native one-day raw
output), but CANNOT independently attest which OS process executed, certify
source independence, or count a whole year. The v045 Python transport receipt
has boundary_evidence_sha256=null; the separate process observation has the
pinned boundary. Preserve both unchanged. This is pilot evidence, not a chunk.
"""
from __future__ import annotations

import hashlib
from io import BytesIO
import json
from pathlib import Path
import re
import stat
import zipfile

SCHEMA="PASTAFARI_ORIGINAL_PROCESS_ARTIFACT_RECONCILIATION_V047/1"
ZIP_SHA="2bcf3c15cc98c977e500caa7432f15e9bce17557f6292d4aae3d6ed9d5704c4d"
PY_COMMIT="0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4"
KT_COMMIT="0c703446d8a3b7435698bd16402ac5fa30e461c9"
PY_SOURCE_SHA="75d56765b45892940326f67bd85a2c7c9874c01e43b49ee3553c9f6192d94378"
BOUNDARY_SHA="ad64cc51522d7f19cb8a238e2a6a418e75203c6cbfe017c394f623edeb882e78"
C=T="-15055671"
YEAR="5000"
ALLOWED={
    "PROD-KT-CY/os-stderr.log","PROD-KT-CY/process-evidence.json",
    "PROD-KT-CY/os-stdout.tsv","PROD-KT-CY/stdin.tsv",
    "REF-41/native-normalized.jsonl","REF-41/native-raw.jsonl",
    "REF-41/native-transport-receipt.json","REF-41/os-stderr.log",
    "REF-41/os-stdout.log","REF-41/process-evidence.json",
    "gate.log","kotlin-compile-resources.txt","kotlin-compiler-v1.9.0.sha256",
    "one-day-original-py-kt-verdict.json","one-native-day-resources.txt",
    "original-kotlin-production-v045.jar","original-kotlin-production-v045.jar.sha256",
}
HEX64=re.compile(r"^[0-9a-f]{64}$")
INTEGER=re.compile(r"^(?:0|-?[1-9][0-9]*)$")

def canonical(v):
    return json.dumps(v,sort_keys=True,ensure_ascii=False,allow_nan=False,
                      separators=(",",":")).encode("utf8")

def sha(b):
    return hashlib.sha256(b).hexdigest()

def need(condition,msg):
    if not condition: raise ValueError(msg)

def json_object(blob,canonical_only=False):
    def unique(pairs):
        out={}
        for k,v in pairs:
            if k in out: raise ValueError("duplicate JSON property")
            out[k]=v
        return out
    data=json.loads(blob.decode("utf8"),object_pairs_hook=unique,
                    parse_constant=lambda _: (_ for _ in ()).throw(ValueError("nonfinite JSON")))
    need(type(data) is dict,"expected JSON record")
    if canonical_only: need(canonical(data)==blob,"process receipt not canonical")
    return data

def load_archive(blob):
    need(type(blob) is bytes and 0<len(blob)<16*1024*1024,"oversized or empty pilot archive")
    with zipfile.ZipFile(BytesIO(blob)) as z:
        infos=z.infolist()
        names=[i.filename for i in infos]
        need(len(names)==len(set(names)) and set(names)==ALLOWED,
             "ZIP names missing, duplicate, or unexpected")
        need(sum(i.file_size for i in infos)<25*1024*1024,"ZIP expanded size unsafe")
        for i in infos:
            need(i.file_size<16*1024*1024 and not i.is_dir() and not i.flag_bits&1,
                 "ZIP member size/framing invalid")
            need(".." not in i.filename.split("/") and not i.filename.startswith("/") and
                 not stat.S_ISLNK(i.external_attr>>16),"ZIP unsafe path")
        need(z.testzip() is None,"ZIP CRC corrupt")
        return {name:z.read(name) for name in names}

def checkhash(files,name,expected):
    need(type(expected) is str and HEX64.fullmatch(expected) is not None,
         "noncanonical hash: "+name)
    need(sha(files[name])==expected,"modified observed bytes: "+name)

def common(record,exit_field):
    need(type(record.get(exit_field)) is int and record[exit_field]==0,
         "original native process did not exit 0")
    need(type(record.get("pid")) is int and record["pid"]>0 and
         isinstance(record.get("process_creation_id"),str) and
         bool(record["process_creation_id"]),"PID/creation ID absent")
    need(record.get("blocked_reason") is None and
         record.get("calculation_day")==C and record.get("target_day")==T and
         record.get("boundary_evidence_sha256")==BOUNDARY_SHA,
         "process coordinates or boundary SHA unbound")
    need(record.get("windows_processes_started")==0,"Windows workload incorrectly claimed")

def original_python(files):
    prefix="REF-41/"
    p=json_object(files[prefix+"process-evidence.json"],True)
    common(p,"exit_code")
    need(p.get("schema")=="PASTAFARI_SUPERVISED_ORIGINAL_REFERENCE_ONE_DAY_V043/1" and
         p.get("status")=="SINGLE_ORIGINAL_FCT_DAY_OBSERVED_AND_NATIVE_RAW_VERIFIED_NOT_YEAR" and
         p.get("engine")=="REF-41" and p.get("native_source_commit")==PY_COMMIT and
         p.get("original_source_sha256")==[PY_SOURCE_SHA],
         "Python source or status differs from pinned observation")
    need(p.get("native_date_calls_expected")==1 and
         p.get("validated_native_date_calls")==1 and
         p.get("official_native_full_year_soak_passes")==0 and
         p.get("canonical_oracle_certified") is False and
         p.get("independent_source_lineage_certified") is False and
         p.get("os_stdout_is_native_data") is False and
         p.get("explicit_wall_timeout_seconds") is None,
         "Python Fct call count or certification/status invalid")
    for name,key in (
        ("native-raw.jsonl","native_raw_sha256"),
        ("native-normalized.jsonl","native_normalized_sha256"),
        ("native-transport-receipt.json","transport_receipt_sha256"),
        ("os-stdout.log","stdout_sha256"),
        ("os-stderr.log","stderr_sha256"),
    ): checkhash(files,prefix+name,p.get(key))
    need(all(type(p.get(key)) is str and HEX64.fullmatch(p[key]) for key in
             ("runtime_executable_sha256","adapter_sha256")),
         "Python interpreter/adapter digest absent")
    argv=p.get("exact_argv")
    need(type(argv) is list and len(argv)==18 and
         all(type(x) is str for x in argv) and
         argv[1:3]==["-I","-B"] and
         argv[3].endswith("/pilot_python_transport_v017.py") and
         p.get("exact_argv_sha256")==sha(canonical(argv)),
         "Python native Fct invocation identity invalid")
    need(argv[4]=="--sources-root" and
         argv[6:]==[
            "--calculation-day",C,"--first-target-day",T,
            "--last-target-day",T,"--raw-out",argv[13],
            "--normalized-out",argv[15],"--receipt-out",argv[17]
         ] and
         argv[13].endswith("/REF-41/native-raw.jsonl") and
         argv[15].endswith("/REF-41/native-normalized.jsonl") and
         argv[17].endswith("/REF-41/native-transport-receipt.json"),
         "Python input/output path or coordinates altered")
    raw=files[prefix+"native-raw.jsonl"]
    normalized=files[prefix+"native-normalized.jsonl"]
    need(raw.endswith(b"\n") and raw.count(b"\n")==1 and
         normalized.endswith(b"\n") and normalized.count(b"\n")==1,
         "Python raw/normalized day count not exactly one")
    source=json_object(raw);row=json_object(normalized)
    ids=source.get("native_date_ids");names=source.get("native_names")
    need(type(ids) is dict and type(names) is dict and
         set(row)=={"calculation_day","target_day","year","cutlet_index",
                    "day_in_cutlet","month_index","day_in_month",
                    "cutlet_name_raw","month_name_raw","source_raw_sha256"},
         "Python original native structure incomplete")
    need(source.get("calculation_day")==C and source.get("target_day")==T and
         row.get("calculation_day")==C and row.get("target_day")==T and
         row.get("source_raw_sha256")==sha(raw) and row.get("year")==YEAR,
         "Python original raw row hash or c/t mismatch")
    for normalized_key,source_key in (
        ("year","year_number"),("cutlet_index","cutlet_name_index"),
        ("day_in_cutlet","day_in_cutlet"),("month_index","month_name_index"),
        ("day_in_month","day_in_month"),
    ):
        need(row[normalized_key]==ids.get(source_key),
             "Python native raw-to-normalized mapping altered: "+normalized_key)
    need(row["cutlet_name_raw"]==names.get("cutlet") and
         row["month_name_raw"]==names.get("month") and
         all(type(row[key]) is int and row[key]>0 for key in
             ("cutlet_index","day_in_cutlet","month_index","day_in_month")),
         "Python native names/indices corrupt")
    transport=json_object(files[prefix+"native-transport-receipt.json"])
    need(transport.get("status")=="NATIVE_TRANSPORT_OUTPUT_COMPLETE_NOT_COMPARED" and
         transport.get("engine")=="REF-41" and
         transport.get("source_commit")==PY_COMMIT and
         transport.get("source_sha256")==PY_SOURCE_SHA and
         transport.get("calculation_day")==C and
         transport.get("first_target_day")==T and
         transport.get("last_target_day")==T and
         type(transport.get("rows")) is int and transport["rows"]==1 and
         transport.get("raw_stream_sha256")==sha(raw) and
         transport.get("normalized_stream_sha256")==sha(normalized),
         "Python transport receipt fails exact native evidence binding")
    # Never silently backfill this null in the original transport receipt.
    need("boundary_evidence_sha256" in transport and
         transport["boundary_evidence_sha256"] is None,
         "original Python transport boundary field unexpectedly rewritten")
    return p,[row["year"],row["cutlet_index"],row["day_in_cutlet"],
              row["month_index"],row["day_in_month"]]

def original_kotlin(files):
    prefix="PROD-KT-CY/"
    k=json_object(files[prefix+"process-evidence.json"],True)
    common(k,"return_code")
    need(k.get("schema")=="PASTAFARI_ORIGINAL_PYTHON_KOTLIN_ONE_DAY_V045/1" and
         k.get("status")=="ORIGINAL_KOTLIN_ONE_NATIVE_DATE_OBSERVED_NOT_YEAR" and
         k.get("source_commit")==KT_COMMIT and
         k.get("native_original_date_rows_verified")==1 and
         k.get("os_stdout_contains_native_date_data") is True and
         k.get("algorithmic_independence_certified") is False and
         k.get("canonical_oracle_certified") is False and
         k.get("full_original_year_soak_passes")==0 and
         k.get("explicit_native_wall_timeout") is None,
         "Kotlin original process/source status or claims invalid")
    for name,key in (
        ("os-stdout.tsv","stdout_sha256"),("os-stderr.log","stderr_sha256"),
        ("stdin.tsv","stdin_sha256"),
    ): checkhash(files,prefix+name,k.get(key))
    need(files[prefix+"stdin.tsv"]==(C+"\t"+T+"\n").encode("ascii"),
         "original Kotlin stdin coordinates altered")
    checkhash(files,"original-kotlin-production-v045.jar",k.get("compiled_original_jar_sha256"))
    need(files["original-kotlin-production-v045.jar.sha256"]==
         (k["compiled_original_jar_sha256"]+
          "  evidence/original-kotlin-production-v045.jar\n").encode("ascii"),
         "original Kotlin JAR manifest digest altered")
    items=k.get("original_source_hashes")
    need(type(items) is list and len(items)>=10 and
         all(type(x) is dict and set(x)=={"path","sha256"} for x in items),
         "Kotlin native source closure missing")
    paths=[i["path"] for i in items]
    need(paths[:-1]==sorted(paths[:-1]) and
         len(paths)==len(set(paths)) and
         paths[-1]=="soak/Post55ProductionDateBridge.kt" and
         all(path.startswith("src/main/kotlin/pastafari/") and
             path.endswith(".kt") for path in paths[:-1]) and
         all(type(i["sha256"]) is str and HEX64.fullmatch(i["sha256"]) for i in items) and
         sha(canonical(items))==k.get("source_closure_sha256"),
         "Kotlin source closure digest or inventory invalid")
    argv=k.get("argv")
    need(type(argv) is list and len(argv)==9 and
         all(type(x) is str for x in argv) and
         argv[-3]=="-cp" and
         argv[-2].endswith("/original-kotlin-production-v045.jar") and
         argv[-1]=="pastafari.Post55ProductionDateBridge" and
         sha(canonical(argv))==k.get("argv_sha256"),
         "Kotlin original JVM command or digest altered")
    need(type(k.get("java_runtime_binary_sha256")) is str and
         HEX64.fullmatch(k["java_runtime_binary_sha256"]),
         "Kotlin original JVM binary digest absent")
    out=files[prefix+"os-stdout.tsv"]
    need(out.endswith(b"\n") and out.count(b"\n")==1 and b"\r" not in out,
         "Kotlin stdout not exactly one native original row")
    fields=out[:-1].decode("ascii").split("\t")
    need(len(fields)==7 and all(INTEGER.fullmatch(x) for x in fields) and
         fields[:3]==[C,T,YEAR] and all(int(x)>0 for x in fields[3:]),
         "Kotlin native 7-field F(c,t) output malformed")
    return k,[fields[2],*(int(x) for x in fields[3:])]

def verify_supervised_original_pair_archive(blob:bytes,*,expected_sha256:str) -> dict:
    """Externally pinned ZIP plus source/process/raw/native comparison consistency."""
    need(type(expected_sha256) is str and HEX64.fullmatch(expected_sha256),
         "external source archive SHA256 pin missing")
    need(type(blob) is bytes and sha(blob)==expected_sha256,
         "original CI artifact ZIP violates independent pin")
    files=load_archive(blob)
    py,a=original_python(files)
    kt,b=original_kotlin(files)
    v=json_object(files["one-day-original-py-kt-verdict.json"],True)
    need(v.get("schema")=="PASTAFARI_ORIGINAL_PYTHON_KOTLIN_ONE_DAY_V045/1" and
         v.get("status")=="ONE_ORIGINAL_PYTHON_KOTLIN_FCT_DAY_MATCH_NOT_YEAR_SOAK" and
         v.get("calculation_day")==C and v.get("target_day")==T and
         v.get("year")==YEAR and v.get("python_commit")==PY_COMMIT and
         v.get("kotlin_commit")==KT_COMMIT and
         v.get("original_python_fct_calls_validated")==1 and
         v.get("original_kotlin_fct_calls_validated")==1 and
         v.get("matching_native_date_fields")==5 and
         v.get("first_mismatch_target_day") is None and
         v.get("original_complete_years_soak_passed")==0 and
         v.get("ten_thousand_year_soak_started") is False and
         v.get("independent_canonical_oracle_certified") is False and
         v.get("independent_source_family_audit_certified") is False and
         v.get("python_native_five_fields")==a and
         v.get("kotlin_native_five_fields")==b and a==b and
         a==["5000",10,503,20,56],
         "pinned original Python/Kotlin numeric date comparison is not verified")
    return {
        "schema":SCHEMA,"status":"ONE_NATIVE_DATE_PAIR_RECHECKED_NOT_YEAR_SOAK",
        "artifact_zip_sha256":expected_sha256,"artifact_size_bytes":len(blob),
        "process_receipt_sha256":{
            "REF-41":sha(files["REF-41/process-evidence.json"]),
            "PROD-KT-CY":sha(files["PROD-KT-CY/process-evidence.json"])
        },
        "native_raw_sha256":{
            "REF-41":sha(files["REF-41/native-raw.jsonl"]),
            "PROD-KT-CY":sha(files["PROD-KT-CY/os-stdout.tsv"])
        },
        "original_commits":{"REF-41":PY_COMMIT,"PROD-KT-CY":KT_COMMIT},
        "original_kotlin_jar_sha256":kt["compiled_original_jar_sha256"],
        "original_python_interpreter_sha256":py["runtime_executable_sha256"],
        "original_kotlin_jvm_sha256":kt["java_runtime_binary_sha256"],
        "original_python_adapter_sha256":py["adapter_sha256"],
        "original_kotlin_bridge_source_sha256":next(
            x["sha256"] for x in kt["original_source_hashes"]
            if x["path"]=="soak/Post55ProductionDateBridge.kt"),
        "original_kotlin_source_closure_sha256":kt["source_closure_sha256"],
        "calculation_day":C,"target_day":T,"year":YEAR,
        "original_native_five_fields":a,"compared_native_five_fields":5,
        "original_native_date_pairs_verified":1,
        "transport_boundary_sha256":None,
        "supervisor_boundary_sha256":BOUNDARY_SHA,
        "transport_receipt_unchanged":True,
        "host_process_identity_independently_attested":False,
        "algorithmic_independence_certified":False,
        "canonical_oracle_certified":False,
        "original_complete_year_soak_passes_certified":0,
        "ten_thousand_year_soak_started":False,
        "windows_processes_started":0,
    }

if __name__=="__main__":
    import argparse
    q=argparse.ArgumentParser()
    q.add_argument("--artifact",type=Path,required=True)
    q.add_argument("--expected-sha256",required=True)
    args=q.parse_args()
    print(json.dumps(verify_supervised_original_pair_archive(args.artifact.read_bytes(),
           expected_sha256=args.expected_sha256),sort_keys=True))
