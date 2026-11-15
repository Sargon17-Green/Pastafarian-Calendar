#!/usr/bin/env python3
"""v055: independently replay ORIGINAL v053 2-day ZIP evidence, never call F(c,t).

The archive SHA and content hashes are frozen in v054. Both original sources
are checked out at pinned commits; the source-name map and the Kotlin source
closure are verified against those real bytes. This replays raw-date
semantics/coordinates, not the expensive native calculations. It is still NOT
a cryptographic independent host process attestation or a full-year soak.
"""
from __future__ import annotations

import argparse
import hashlib
from io import BytesIO
import json
from pathlib import Path
import re
import stat
import zipfile

from native_raw_pair_gate_v018 import verify_locked_sources,name_maps
from original_bounded_chunk_gate_v050 import verify_bounded_original_chunk
from supervised_original_python_kotlin_day_v045 import _original_tree

PIN=Path(__file__).resolve().parents[1]/"control/supervised_two_original_dates_v054.json"
EXPECTED_NAMES=frozenset((
    "PROD-KT-CY/original-native-stdin.tsv",
    "PROD-KT-CY/os-stdout.tsv",
    "PROD-KT-CY/os-stderr.log",
    "PROD-KT-CY/process-evidence.json",
    "REF-41/native-raw.jsonl",
    "REF-41/native-normalized.jsonl",
    "REF-41/os-stderr.log",
    "REF-41/os-stdout.log",
    "REF-41/process-evidence.json",
    "REF-41/transport-receipt.json",
    "gate.log",
    "kotlin-compile-resources.txt",
    "kotlin-compiler-v1.9.0.sha256",
    "kotlin-index-only-normalized.jsonl",
    "original-kotlin-v053.jar",
    "original-kotlin-v053.jar.sha256",
    "original-two-day-verdict.json",
    "two-native-day-resources.txt",
))
C="-15055671"
FIRST="-15055672"
LAST="-15055671"
YEAR="5000"
HEX64=re.compile(r"^[a-f0-9]{64}$")


def sha(payload:bytes)->str:
    return hashlib.sha256(payload).hexdigest()


def canonical(obj)->bytes:
    return json.dumps(obj,sort_keys=True,ensure_ascii=False,
                      separators=(",",":"),allow_nan=False).encode("utf8")


def checked(ok:bool,msg:str):
    if not ok:raise ValueError("v055: "+msg)


def json_strict(blob:bytes,*,canonical_check=False):
    def unique(pairs):
        d={}
        for key,v in pairs:
            if key in d:raise ValueError("duplicate JSON key in immutable evidence")
            d[key]=v
        return d
    obj=json.loads(blob.decode("utf8"),object_pairs_hook=unique,
                   parse_constant=lambda _:(_ for _ in ()).throw(ValueError("nonfinite JSON")))
    checked(type(obj) is dict,"source evidence must be JSON object")
    if canonical_check:
        checked(blob==canonical(obj),"canonical process receipt bytes changed")
    return obj


def load_zip(blob:bytes):
    checked(type(blob) is bytes and 100<=len(blob)<=10*1024*1024,
            "original artifact size not bounded")
    with zipfile.ZipFile(BytesIO(blob)) as archive:
        info=archive.infolist()
        names=[x.filename for x in info]
        checked(len(names)==len(set(names)) and set(names)==EXPECTED_NAMES,
                "original evidence ZIP members differ from pinned witness")
        checked(all(not x.is_dir() and not (x.flag_bits&1) and
                    not stat.S_ISLNK(x.external_attr>>16) and
                    ".." not in x.filename.split("/") and
                    not x.filename.startswith("/") and x.file_size<=8*1024*1024
                    for x in info),"original evidence ZIP unsafe")
        checked(sum(x.file_size for x in info)<12*1024*1024,
                "original evidence exceeds decompressed size budget")
        checked(archive.testzip() is None,"original evidence ZIP CRC invalid")
        return {name:archive.read(name) for name in names}


def replay_native_witness(payload:bytes,sources:Path,kotlin_repo:Path,
                          *,expected_zip_sha256:str)->dict:
    pin=json_strict(PIN.read_bytes())
    checked(expected_zip_sha256==pin["artifact_sha256"] and
            sha(payload)==expected_zip_sha256,
            "original artifact bytes changed from independent v054 pin")
    files=load_zip(payload)
    for filename,digest in pin["sha256"].items():
        checked(filename in files and HEX64.fullmatch(digest) is not None and
                sha(files[filename])==digest,
                "pinned original file changed: "+filename)
    p=json_strict(files["REF-41/process-evidence.json"],canonical_check=True)
    k=json_strict(files["PROD-KT-CY/process-evidence.json"],canonical_check=True)
    v=json_strict(files["original-two-day-verdict.json"],canonical_check=True)
    t=json_strict(files["REF-41/transport-receipt.json"])
    source,objects=verify_locked_sources(sources.resolve(strict=True),"REF-41")
    cutlets,months=name_maps("REF-41",objects)
    kotlin_closure,kotlin_files=_original_tree(kotlin_repo)
    checked(p["source_commit"]==pin["source_commits"]["REF-41"]==
            source["commit"] and
            p["source_shas"]==[pin["source_sha256_ref41"]],
            "Python original commit/sha differs from pin")
    checked(k["source_commit"]==pin["source_commits"]["PROD-KT-CY"] and
            k["source_closure_sha256"]==pin["original_kotlin_source_closure_sha256"]==
            kotlin_closure and k["source_inventory"]==kotlin_files,
            "original Kotlin production source closure differs")
    checked(sha(files["original-kotlin-v053.jar"])==
            k["compiled_original_jar_sha256"]==
            pin["original_kotlin_jar_sha256"],
            "Kotlin production JAR bytes differ")
    checked(files["original-kotlin-v053.jar.sha256"]==
            (pin["original_kotlin_jar_sha256"]+
             "  evidence/original-kotlin-v053.jar\n").encode("ascii"),
            "compiled Kotlin JAR external manifest differs")
    for engine,receipt in (("REF-41",p),("PROD-KT-CY",k)):
        checked(receipt["schema"]=="PASTAFARI_SUPERVISED_TWO_ORIGINAL_DAYS_V053/1" and
                receipt["engine"]==engine and
                receipt["exit_code"]==0 and
                type(receipt["native_rows_validated"]) is int and
                receipt["native_rows_validated"]==2 and
                type(receipt["pid"]) is int and receipt["pid"]>0 and
                type(receipt["process_creation_id"]) is str and
                bool(receipt["process_creation_id"]) and
                receipt["calculation_day"]==C and
                receipt["year"]==YEAR and
                receipt["first_target_day"]==FIRST and
                receipt["last_target_day"]==LAST and
                receipt["boundary_evidence_sha256"]==pin["boundary_evidence_sha256"] and
                receipt["blocked_reason"] is None and
                receipt["resident_memory_hard_cap_enforced"] is False and
                receipt["original_calculation_wall_timeout_seconds"] is None and
                receipt["whole_original_year_soak_passes"]==0 and
                receipt["canonical_oracle_certified"] is False and
                receipt["source_lineage_certified"] is False and
                receipt["independent_process_execution_attested"] is False,
                engine+" original native process receipt invalid or falsely certified")
        checked(receipt["os_stderr_sha256"]==sha(files[engine+"/os-stderr.log"]),
                engine+" original stderr SHA mismatch")
        raw_stream=("os-stdout.log" if engine=="REF-41" else "os-stdout.tsv")
        checked(receipt["os_stdout_sha256"]==sha(files[engine+"/"+raw_stream]),
                engine+" original stdout SHA mismatch")
        checked(receipt["argv_sha256"]==sha(canonical(receipt["argv"])),
                engine+" original argv SHA mismatch")
    checked(p["status"]=="ORIGINAL_PYTHON_TWO_DATE_SOURCE_PROVENANCE_CHECKED" and
            k["status"]=="ORIGINAL_KOTLIN_TWO_DATE_SOURCE_PROVENANCE_CHECKED",
            "original source check-only or failed process promoted to execution")
    checked(t.get("status")=="NATIVE_TRANSPORT_OUTPUT_COMPLETE_NOT_COMPARED" and
            t.get("boundary_evidence_sha256")==pin["boundary_evidence_sha256"] and
            t.get("engine")=="REF-41" and t.get("rows")==2 and
            t.get("calculation_day")==C and t.get("first_target_day")==FIRST and
            t.get("last_target_day")==LAST and
            t.get("raw_stream_sha256")==sha(files["REF-41/native-raw.jsonl"]) and
            t.get("normalized_stream_sha256")==sha(files["REF-41/native-normalized.jsonl"]),
            "Python original two-day transport receipt not source-bound")
    checked(p["native_raw_sha256"]==sha(files["REF-41/native-raw.jsonl"]) and
            p["native_normalized_sha256"]==sha(files["REF-41/native-normalized.jsonl"]) and
            p["native_transport_receipt_sha256"]==
            sha(files["REF-41/transport-receipt.json"]),
            "Python two-day original raw/normalized transport changed")
    checked(k["stdin_sha256"]==sha(files["PROD-KT-CY/original-native-stdin.tsv"]) and
            files["PROD-KT-CY/original-native-stdin.tsv"]==
            (f"{C}\t{FIRST}\n{C}\t{LAST}\n").encode("ascii"),
            "original Kotlin input bytes or day order altered")
    checked(p["argv"][0]==p["runtime_path"] and
            p["argv"][1:4]==["-I","-B",p["adapter_path"]] and
            p["argv"][-9:]==[
                "--allow-whole-year","--boundary-evidence-sha256",
                pin["boundary_evidence_sha256"],"--raw-out",p["argv"][-5],
                "--normalized-out",p["argv"][-3],
                "--receipt-out",p["argv"][-1]
            ] and
            p["argv"][-5].endswith("/REF-41/native-raw.jsonl") and
            p["argv"][-3].endswith("/REF-41/native-normalized.jsonl") and
            p["argv"][-1].endswith("/REF-41/transport-receipt.json"),
            "Python original multi-day invocation was not pinned")
    checked(k["argv"][0]==k["runtime_path"] and
            k["argv"][-3:] == ["-cp",k["argv"][-2],
                               "pastafari.Post55ProductionDateBridge"] and
            k["argv"][-2].endswith("/original-kotlin-v053.jar"),
            "Kotlin original bridge command changed")
    tested=verify_bounded_original_chunk(
        python_original_raw=files["REF-41/native-raw.jsonl"],
        python_original_normalized=files["REF-41/native-normalized.jsonl"],
        kotlin_original_stdout=files["PROD-KT-CY/os-stdout.tsv"],
        calculation_day=C,year=YEAR,first_target_day=FIRST,
        last_target_day=LAST,
        boundary_evidence_sha256=pin["boundary_evidence_sha256"],
        frozen_python_cutlets=cutlets,
        frozen_python_months=months,
    )
    derived=tested.pop("kotlin_index_only_normalized_jsonl")
    checked(tested["status"]=="BOUNDED_ORIGINAL_CHUNK_MATCH_NOT_FULL_YEAR" and
            tested["matched_original_day_pairs"]==2 and
            tested["first_mismatch"] is None and derived is not None and
            files["kotlin-index-only-normalized.jsonl"]==derived and
            sha(derived)==pin["sha256"]["kotlin-index-only-normalized.jsonl"],
            "raw Python/Kotlin native two-day equality not reproducible")
    checked(v["status"]=="SUPERVISED_ORIGINAL_TWO_DAYS_MATCH_NOT_FULL_YEAR" and
            v["first_mismatch"] is None and v["matched_original_day_pairs"]==2 and
            v["original_full_year_length"]==4244 and
            v["original_complete_years_soak_passed"]==0 and
            v["algorithmic_independence_certified"] is False and
            v["canonical_oracle_certified"] is False and
            v["python_raw_sha256"]==tested["python_raw_sha256"] and
            v["kotlin_os_stdout_sha256"]==tested["kotlin_os_stdout_sha256"],
            "original two-date supervisor final verdict not reproducible")
    normalized=[json_strict(x) for x in
                files["REF-41/native-normalized.jsonl"].splitlines()]
    expected=pin["canonical_five_fields_per_day"]
    checked(len(normalized)==len(expected)==2,"incomplete native two-day output")
    for actual,selected in zip(normalized,expected):
        checked(actual["target_day"]==selected["target_day"] and
                [actual[x] for x in ("year","cutlet_index","day_in_cutlet",
                                  "month_index","day_in_month")]==
                [selected[x] for x in ("year","cutlet_index","day_in_cutlet",
                                    "month_index","day_in_month")] and
                actual["cutlet_name_raw"]==selected["python_native_names"]["cutlet"] and
                actual["month_name_raw"]==selected["python_native_names"]["month"],
                "original native field changed from pinned v054 date receipt")
    return {
        "schema":"PASTAFARI_ORIGINAL_TWO_DAY_ARTIFACT_RECHECK_V055/1",
        "status":"PINNED_REAL_TWO_NATIVE_DAYS_REVALIDATED_NOT_YEAR_SOAK",
        "original_artifact_sha256":expected_zip_sha256,
        "original_python_commit":source["commit"],
        "original_kotlin_commit":k["source_commit"],
        "original_native_day_pairs_matched":2,
        "original_native_five_fields_matched_per_day":5,
        "original_year_length_days":4244,
        "kotlin_native_names_output":False,
        "original_process_observation_independently_attested":False,
        "source_lineage_certified":False,
        "canonical_oracle_certified":False,
        "official_full_year_soak_passes":0,
        "ten_thousand_year_soak_started":False,
        "windows_workload_started":False,
    }


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--artifact",type=Path,required=True)
    parser.add_argument("--sources-root",type=Path,required=True)
    parser.add_argument("--kotlin-original-repo",type=Path,required=True)
    parser.add_argument("--expected-sha256",required=True)
    opts=parser.parse_args()
    result=replay_native_witness(
        opts.artifact.read_bytes(),opts.sources_root,opts.kotlin_original_repo,
        expected_zip_sha256=opts.expected_sha256)
    print("V055_ORIGINAL_TWO_DAY_AUDIT="+json.dumps(result,sort_keys=True))
