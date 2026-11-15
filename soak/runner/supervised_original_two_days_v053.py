#!/usr/bin/env python3
"""v053: supervised TWO-day original Python + production Kotlin differential pilot.

Only on ephemeral GitHub Linux. Actual unchanged original F(c,t) is called
for t=-15055672 and -15055671 sequentially per engine. The old source
transport adapter is NOT rewritten; Kotlin production stdout is raw TSV.
No native conversion is terminated for elapsed wall time by this supervisor.
Results are NOT complete-year soak, not an independent oracle, and not
an algorithmic-independence certificate. All evidence is append-only.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import resource
import shutil
import subprocess
import sys

from native_execution_receipt_v038 import canonical,sha
from native_raw_pair_gate_v018 import verify_locked_sources,name_maps,verify_stream
from original_bounded_chunk_gate_v050 import (
    verify_bounded_original_chunk,BOUNDARY_SHA,C,YEAR,
)
from supervised_original_one_day_v043 import _guard_year,_ram_available
from supervised_original_python_kotlin_day_v045 import (
    _original_tree, PINNED_KOTLIN_COMMIT, JVM_VIRTUAL_LIMIT,
)
from supervised_process_observation_v041 import (
    _admit,_pid_start_id,_durable_exclusive,_read_limited,sha_file,
)

SCHEMA="PASTAFARI_SUPERVISED_TWO_ORIGINAL_DAYS_V053/1"
FIRST="-15055672"
LAST="-15055671"
N=2
PY_AS_LIMIT=1536*1024*1024
RAM_FLOOR=5*1024*1024*1024
DISK_FLOOR=500*1024*1024
CLASS="pastafari.Post55ProductionDateBridge"


def _linux_limits(address_bytes):
    os.nice(19)
    resource.setrlimit(resource.RLIMIT_AS,(address_bytes,address_bytes))
    os.umask(0o077)
    # NO RLIMIT_CPU; NO per-date subprocess timeout for original F(c,t).


def _resources(root:Path,mode:str):
    free=_ram_available()
    disk=shutil.disk_usage(root).free
    if free<RAM_FLOOR or disk<DISK_FLOOR:
        raise RuntimeError(f"{mode}: original-source resource admission blocked; "
                           "neither a F(c,t) result nor a mismatch")
    return {"free_ram_at_launch_bytes":free,"free_disk_at_launch_bytes":disk,
            "resident_memory_hard_cap_enforced":False,
            "original_calculation_wall_timeout_seconds":None}


def _observe_python(root:Path,sources:Path,boundary:str):
    engine,source_files=verify_locked_sources(sources,"REF-41")
    cutlets,months=name_maps("REF-41",source_files)
    if engine["commit"]!="0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4":
        raise ValueError("not frozen REF-41 original commit")
    adapter=Path(__file__).resolve().parent/"pilot_python_transport_v017.py"
    runtime=Path(sys.executable).resolve(strict=True)
    pre_hashes={"adapter_sha256":sha_file(adapter),
                "interpreter_sha256":sha_file(runtime)}
    work=root/"REF-41"
    work.mkdir(mode=0o700,exist_ok=False)
    raw,norm,transport=(work/"native-raw.jsonl",
                        work/"native-normalized.jsonl",
                        work/"transport-receipt.json")
    command=[
        str(runtime),"-I","-B",str(adapter),"--sources-root",str(sources),
        "--calculation-day",C,
        "--first-target-day",FIRST,
        "--last-target-day",LAST,
        "--allow-whole-year",
        "--boundary-evidence-sha256",boundary,
        "--raw-out",str(raw),"--normalized-out",str(norm),
        "--receipt-out",str(transport),
    ]
    resource_evidence=_resources(root,"REF-41")
    env=os.environ.copy()
    env["PASTAFARI_SOAK_RESOURCE_ADMITTED"]="1"
    receipt={
        "schema":SCHEMA,"engine":"REF-41","status":"UNVERIFIED",
        "source_commit":engine["commit"],
        "source_shas":[item["sha256"] for item in engine["sources"]],
        "adapter_path":str(adapter),"adapter_sha256":pre_hashes["adapter_sha256"],
        "runtime_path":str(runtime),"runtime_sha256":pre_hashes["interpreter_sha256"],
        "argv":command,"argv_sha256":sha(canonical(command)),
        "calculation_day":C,"first_target_day":FIRST,"last_target_day":LAST,
        "year":YEAR,"boundary_evidence_sha256":boundary,
        "pid":None,"process_creation_id":None,"exit_code":None,
        "native_rows_validated":0,
        "os_stdout_sha256":None,"os_stderr_sha256":None,
        "native_raw_sha256":None,"native_normalized_sha256":None,
        "native_transport_receipt_sha256":None,
        "os_stdout_contains_native_data":False,
        "vmem_limit_bytes":PY_AS_LIMIT,"cpu_nice_requested":19,
        **resource_evidence,
        "independent_process_execution_attested":False,
        "source_lineage_certified":False,"canonical_oracle_certified":False,
        "whole_original_year_soak_passes":0,
    }
    failure=None
    with (work/"os-stdout.log").open("xb") as stdout, (work/"os-stderr.log").open("xb") as stderr:
        child=subprocess.Popen(
            command,stdin=subprocess.DEVNULL,stdout=stdout,stderr=stderr,
            cwd=str(work),env=env,close_fds=True,start_new_session=True,
            preexec_fn=lambda:_linux_limits(PY_AS_LIMIT),
        )
        receipt["pid"]=child.pid
        try:
            receipt["process_creation_id"]=_pid_start_id(child.pid)
            child.wait()
        except BaseException as ex:
            failure="PYTHON_ORIGINAL_PROCESS_OBSERVATION_FAILED:"+type(ex).__name__
        receipt["exit_code"]=child.poll()
    receipt["os_stdout_sha256"]=sha(_read_limited(work/"os-stdout.log"))
    receipt["os_stderr_sha256"]=sha(_read_limited(work/"os-stderr.log"))
    if not failure and receipt["exit_code"]!=0:
        failure="PYTHON_ORIGINAL_NATIVE_EXIT_NONZERO"
    if sha_file(adapter)!=pre_hashes["adapter_sha256"] or sha_file(runtime)!=pre_hashes["interpreter_sha256"]:
        failure="PYTHON_ORIGINAL_ADAPTER_OR_RUNTIME_CHANGED"
    try:
        after,_=verify_locked_sources(sources,"REF-41")
        if after!=engine:raise ValueError("source manifest altered")
    except BaseException:
        failure="PYTHON_ORIGINAL_SOURCE_BYTES_CHANGED"
    if failure is None:
        try:
            verdict=verify_stream("REF-41",sources,raw,norm,transport)
            tr=json.loads(_read_limited(transport))
            if (verdict["rows_verified"]!=N or
                verdict["status"]!="NATIVE_RAW_TRANSPORT_EVIDENCE_PASS_BOUNDED" or
                verdict["year_certified"] is not False or
                tr.get("boundary_evidence_sha256")!=boundary or
                tr.get("rows")!=N or
                tr.get("first_target_day")!=FIRST or tr.get("last_target_day")!=LAST):
                raise ValueError("native Python multi-day output/receipt not accepted")
            for key,source in (
                ("native_raw_sha256",raw),("native_normalized_sha256",norm),
                ("native_transport_receipt_sha256",transport),
            ):receipt[key]=sha(_read_limited(source))
            receipt["native_rows_validated"]=N
        except BaseException as ex:
            failure="PYTHON_ORIGINAL_NATIVE_SEMANTICS_INVALID:"+type(ex).__name__
    receipt["status"]=("ORIGINAL_PYTHON_TWO_DATE_SOURCE_PROVENANCE_CHECKED"
                      if failure is None else "ORIGINAL_PYTHON_PILOT_BLOCKED")
    receipt["blocked_reason"]=failure
    _durable_exclusive(work/"process-evidence.json",canonical(receipt))
    if failure:raise RuntimeError(failure)
    return receipt,cutlets,months


def _observe_kotlin(root:Path,source_repo:Path,jar:Path,boundary:str):
    original_closure_sha,source_inventory=_original_tree(source_repo)
    jar=jar.resolve(strict=True)
    if jar.is_symlink() or not jar.is_file():
        raise ValueError("Kotlin original compiled JAR not a regular file")
    runtime_name=shutil.which("java")
    if not runtime_name:
        raise RuntimeError("Kotlin original JVM missing")
    runtime=Path(runtime_name).resolve(strict=True)
    original_jar_sha=sha_file(jar)
    runtime_sha=sha_file(runtime)
    work=root/"PROD-KT-CY"
    work.mkdir(mode=0o700,exist_ok=False)
    stdin_file=work/"original-native-stdin.tsv"
    stream="".join(f"{C}\t{t}\n" for t in range(int(FIRST),int(LAST)+1)).encode("ascii")
    _durable_exclusive(stdin_file,stream)
    argv=[
        str(runtime),"-Xmx512m","-XX:MaxDirectMemorySize=128m",
        "-XX:MaxMetaspaceSize=192m","-XX:ReservedCodeCacheSize=64m",
        "-XX:ActiveProcessorCount=2","-cp",str(jar),CLASS,
    ]
    receipt={
        "schema":SCHEMA,"engine":"PROD-KT-CY","status":"UNVERIFIED",
        "source_commit":PINNED_KOTLIN_COMMIT,
        "source_closure_sha256":original_closure_sha,
        "source_inventory":source_inventory,
        "compiled_original_jar_sha256":original_jar_sha,
        "runtime_path":str(runtime),"runtime_sha256":runtime_sha,
        "argv":argv,"argv_sha256":sha(canonical(argv)),
        "stdin_sha256":sha(stream),
        "calculation_day":C,"year":YEAR,
        "first_target_day":FIRST,"last_target_day":LAST,
        "boundary_evidence_sha256":boundary,
        "pid":None,"process_creation_id":None,"exit_code":None,
        "native_rows_validated":0,
        "os_stdout_sha256":None,"os_stderr_sha256":None,
        "os_stdout_contains_native_data":True,
        "vmem_limit_bytes":JVM_VIRTUAL_LIMIT,
        "jvm_heap_limit_mib":512,"cpu_nice_requested":19,
        **_resources(root,"PROD-KT-CY"),
        "independent_process_execution_attested":False,
        "source_lineage_certified":False,"canonical_oracle_certified":False,
        "whole_original_year_soak_passes":0,
    }
    failure=None
    with stdin_file.open("rb") as stdin, \
         (work/"os-stdout.tsv").open("xb") as stdout, \
         (work/"os-stderr.log").open("xb") as stderr:
        child=subprocess.Popen(
            argv,stdin=stdin,stdout=stdout,stderr=stderr,
            cwd=str(work),close_fds=True,start_new_session=True,
            preexec_fn=lambda:_linux_limits(JVM_VIRTUAL_LIMIT),
        )
        receipt["pid"]=child.pid
        try:
            receipt["process_creation_id"]=_pid_start_id(child.pid)
            child.wait()
        except BaseException as ex:
            failure="KOTLIN_ORIGINAL_PROCESS_OBSERVATION_FAILED:"+type(ex).__name__
        receipt["exit_code"]=child.poll()
    raw=_read_limited(work/"os-stdout.tsv")
    receipt["os_stdout_sha256"]=sha(raw)
    receipt["os_stderr_sha256"]=sha(_read_limited(work/"os-stderr.log"))
    if not failure and receipt["exit_code"]!=0:
        failure="KOTLIN_ORIGINAL_NATIVE_EXIT_NONZERO"
    if sha_file(jar)!=original_jar_sha or sha_file(runtime)!=runtime_sha:
        failure="KOTLIN_JAR_OR_RUNTIME_CHANGED_DURING_COMPUTE"
    try:
        after,_=_original_tree(source_repo)
        if after!=original_closure_sha:
            raise ValueError("original Kotlin closure changed")
    except BaseException:
        failure="KOTLIN_ORIGINAL_SOURCE_CHANGED"
    if failure is None:
        if raw.count(b"\n")!=N or not raw.endswith(b"\n"):
            failure="KOTLIN_NATIVE_OUTPUT_NOT_EXACTLY_TWO_RECORDS"
        else:
            receipt["native_rows_validated"]=N
    receipt["status"]=("ORIGINAL_KOTLIN_TWO_DATE_SOURCE_PROVENANCE_CHECKED"
                      if failure is None else "ORIGINAL_KOTLIN_PILOT_BLOCKED")
    receipt["blocked_reason"]=failure
    _durable_exclusive(work/"process-evidence.json",canonical(receipt))
    if failure:raise RuntimeError(failure)
    return receipt


def run(sources:Path,kotlin_repo:Path,jar:Path,root:Path):
    _admit(root)
    root=root.resolve(strict=True)
    sources=sources.resolve(strict=True)
    kotlin_repo=kotlin_repo.resolve(strict=True)
    if (root==sources or root==kotlin_repo or root in sources.parents or
        root in kotlin_repo.parents or sources in root.parents or kotlin_repo in root.parents):
        raise ValueError("source tree and evidence directory must be separate")
    boundary=_guard_year()
    if boundary!=BOUNDARY_SHA:
        raise ValueError("original year 5000 boundary SHA changed")
    py,cutlets,months=_observe_python(root,sources,boundary)
    kt=_observe_kotlin(root,kotlin_repo,jar,boundary)
    verdict=verify_bounded_original_chunk(
        python_original_raw=(root/"REF-41/native-raw.jsonl").read_bytes(),
        python_original_normalized=(root/"REF-41/native-normalized.jsonl").read_bytes(),
        kotlin_original_stdout=(root/"PROD-KT-CY/os-stdout.tsv").read_bytes(),
        calculation_day=C,year=YEAR,
        first_target_day=FIRST,last_target_day=LAST,
        boundary_evidence_sha256=boundary,
        frozen_python_cutlets=cutlets,frozen_python_months=months,
    )
    normalized=verdict.pop("kotlin_index_only_normalized_jsonl")
    if normalized is not None:
        _durable_exclusive(root/"kotlin-index-only-normalized.jsonl",normalized)
    report={
        **verdict,
        "schema":SCHEMA,
        "status":("SUPERVISED_ORIGINAL_TWO_DAYS_MATCH_NOT_FULL_YEAR"
                  if not verdict["halt_new_dispatch"]
                  else "SUPERVISED_ORIGINAL_TWO_DAYS_FIRST_MISMATCH_HALT"),
        "python_process_receipt_sha256":sha((root/"REF-41/process-evidence.json").read_bytes()),
        "kotlin_process_receipt_sha256":sha((root/"PROD-KT-CY/process-evidence.json").read_bytes()),
        "python_original_source_commit":py["source_commit"],
        "kotlin_original_source_commit":kt["source_commit"],
        "kotlin_normalized_index_only_sha256":sha(normalized) if normalized is not None else None,
        "supervised_original_Fct_calls_per_engine":N,
        "original_complete_years_soak_passed":0,
        "long_soak_started":False,
        "windows_workload_started":False,
        "main_modified":False,
    }
    _durable_exclusive(root/"original-two-day-verdict.json",canonical(report))
    if verdict["halt_new_dispatch"]:
        raise RuntimeError("STOP: first original Python/Kotlin native mismatch, no further dispatch")
    return report


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--ci-original-two-days",action="store_true",required=True)
    parser.add_argument("--sources-root",type=Path,required=True)
    parser.add_argument("--original-kotlin-repo",type=Path,required=True)
    parser.add_argument("--original-kotlin-jar",type=Path,required=True)
    parser.add_argument("--evidence-root",type=Path,required=True)
    args=parser.parse_args()
    output=run(args.sources_root,args.original_kotlin_repo,args.original_kotlin_jar,args.evidence_root)
    print("SUPERVISED_ORIGINAL_TWO_DAY_V053="+json.dumps(output,sort_keys=True),flush=True)


if __name__=="__main__":
    main()
