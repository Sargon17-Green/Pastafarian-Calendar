#!/usr/bin/env python3
"""v045: one real original Python F(c,t) and Kotlin production F(c,t), Linux CI.

Sequential observed OS children, zero wall timeout for native computations.
OS stdout is LOG for Python transport, but real numeric DATA for Kotlin bridge.
Not a canonical oracle, not an independence certificate and not a full year.
"""
from __future__ import annotations
import argparse
import json
import os
from pathlib import Path
import resource
import shutil
import subprocess

from supervised_original_one_day_v043 import C,T,YEAR,_guard_year,_run_one,_ram_available
from supervised_process_observation_v041 import (
    _admit,_pid_start_id,_durable_exclusive,_read_limited,sha_file
)
from native_execution_receipt_v038 import sha,canonical
from year_validator import YearCase,parse_line,SIGNED

SCHEMA="PASTAFARI_ORIGINAL_PYTHON_KOTLIN_ONE_DAY_V045/1"
PINNED_KOTLIN_COMMIT="0c703446d8a3b7435698bd16402ac5fa30e461c9"
JVM_VIRTUAL_LIMIT=8*1024*1024*1024


def _child_limits():
    os.nice(19)
    resource.setrlimit(resource.RLIMIT_AS,(JVM_VIRTUAL_LIMIT,JVM_VIRTUAL_LIMIT))
    os.umask(0o077)


def _original_tree(repo:Path):
    p=repo.resolve(strict=True)
    commit=subprocess.run(["git","-C",str(p),"rev-parse","HEAD"],
              check=True,capture_output=True,text=True).stdout.strip()
    dirty=subprocess.run(["git","-C",str(p),"status","--porcelain"],
              check=True,capture_output=True,text=True).stdout
    if commit!=PINNED_KOTLIN_COMMIT or dirty:
        raise ValueError("pinned Kotlin original commit/source is not immutable")
    files=sorted((p/"src/main/kotlin/pastafari").glob("*.kt"))
    files.append(p/"soak/Post55ProductionDateBridge.kt")
    if len(files)<11 or any(not f.is_file() or f.is_symlink() for f in files):
        raise ValueError("Kotlin original source closure missing or unsafe")
    locks=[{"path":f.relative_to(p).as_posix(),"sha256":sha_file(f)} for f in files]
    return sha(canonical(locks)),locks


def _kotlin(original_repo:Path,jar:Path,work_root:Path,boundary_sha:str):
    source_hash,locks=_original_tree(original_repo)
    jar=jar.resolve(strict=True)
    if not jar.is_file() or jar.is_symlink():
        raise ValueError("original Kotlin JAR missing or symlinked")
    jar_hash=sha_file(jar)
    java=shutil.which("java")
    if not java:raise RuntimeError("Java runtime missing")
    java=Path(java).resolve(strict=True)
    java_hash=sha_file(java)
    ram=_ram_available()
    if ram<5*1024*1024*1024 or shutil.disk_usage(work_root).free<500*1024*1024:
        raise RuntimeError("original Kotlin process resource BLOCKED before launch")
    work=work_root/"PROD-KT-CY"
    work.mkdir(mode=0o700,exist_ok=False)
    inp=work/"stdin.tsv"
    _durable_exclusive(inp,(C+"\t"+T+"\n").encode("ascii"))
    argv=[str(java),"-Xmx512m","-XX:MaxDirectMemorySize=128m",
          "-XX:MaxMetaspaceSize=192m","-XX:ReservedCodeCacheSize=64m",
          "-XX:ActiveProcessorCount=2","-cp",str(jar),
          "pastafari.Post55ProductionDateBridge"]
    report={
        "schema":SCHEMA,"status":"BLOCKED_UNVERIFIED",
        "source_commit":PINNED_KOTLIN_COMMIT,
        "original_source_hashes":locks,"source_closure_sha256":source_hash,
        "compiled_original_jar_sha256":jar_hash,
        "java_runtime_binary_sha256":java_hash,
        "java_runtime_binary_path":str(java),
        "argv":argv,"argv_sha256":sha(canonical(argv)),
        "stdin_sha256":sha(inp.read_bytes()),
        "calculation_day":C,"target_day":T,"boundary_evidence_sha256":boundary_sha,
        "pid":None,"process_creation_id":None,"return_code":None,
        "stdout_sha256":None,"stderr_sha256":None,
        "available_ram_bytes":ram,"jvm_heap_limit_megabytes":512,
        "virtual_address_limit_bytes":JVM_VIRTUAL_LIMIT,
        "resident_memory_hard_cap_verified":False,
        "explicit_native_wall_timeout":None,"cpu_priority_nice_requested":19,
        "os_stdout_contains_native_date_data":True,
        "native_original_date_rows_verified":0,
        "algorithmic_independence_certified":False,
        "canonical_oracle_certified":False,
        "full_original_year_soak_passes":0,
        "windows_processes_started":0,
    }
    failure=None
    with inp.open("rb") as stdin, \
         (work/"os-stdout.tsv").open("xb") as stdout, \
         (work/"os-stderr.log").open("xb") as stderr:
        child=subprocess.Popen(argv,stdin=stdin,stdout=stdout,stderr=stderr,
                     cwd=str(work),close_fds=True,start_new_session=True,
                     preexec_fn=_child_limits)
        report["pid"]=child.pid
        try:
            report["process_creation_id"]=_pid_start_id(child.pid)
            child.wait()  # No time-based cancellation of a slow native F(c,t).
        except BaseException as e:
            failure="PROCESS_IDENTITY_OR_WAIT_FAILED:"+type(e).__name__
        report["return_code"]=child.poll()
    raw=_read_limited(work/"os-stdout.tsv")
    report["stdout_sha256"]=sha(raw)
    report["stderr_sha256"]=sha(_read_limited(work/"os-stderr.log"))
    if failure is None and report["return_code"]!=0:
        failure="KOTLIN_ORIGINAL_NATIVE_EXIT_NONZERO"
    if jar_hash!=sha_file(jar) or java_hash!=sha_file(java):
        failure="JAVA_OR_JAR_CHANGED_DURING_COMPUTATION"
    try:
        after,_=_original_tree(original_repo)
        if source_hash!=after:failure="ORIGINAL_KOTLIN_SOURCE_CHANGED"
    except BaseException:
        failure="ORIGINAL_SOURCE_UNREADABLE_AFTER_COMPUTATION"
    fields=None
    if failure is None:
        try:
            if not raw.endswith(b"\n") or raw.count(b"\n")!=1:
                raise ValueError("not exactly one native date line")
            fields=raw[:-1].decode("utf8").split("\t")
            if (len(fields)!=7 or any(not SIGNED.fullmatch(x) for x in fields)
                or fields[:3]!=[C,T,YEAR] or any(int(x)<=0 for x in fields[3:])):
                raise ValueError("native Kotlin original seven fields invalid")
            report["native_original_date_rows_verified"]=1
        except BaseException as e:
            failure="ORIGINAL_KOTLIN_OUTPUT_INVALID:"+type(e).__name__
    report["status"]=(
        "ORIGINAL_KOTLIN_ONE_NATIVE_DATE_OBSERVED_NOT_YEAR"
        if failure is None else "BLOCKED_NO_FULL_YEAR_CREDIT")
    report["blocked_reason"]=failure
    _durable_exclusive(work/"process-evidence.json",canonical(report))
    if failure:raise RuntimeError(failure)
    return report,fields


def run(source_root:Path,kotlin_repo:Path,jar:Path,output:Path)->dict:
    _admit(output)
    output=output.resolve(strict=True)
    boundary=_guard_year()
    py=_run_one("REF-41",output,source_root.resolve(strict=True),boundary)
    kt,fields=_kotlin(kotlin_repo,jar,output,boundary)
    normalized=_read_limited(output/"REF-41/native-normalized.jsonl")
    if not normalized.endswith(b"\n") or normalized.count(b"\n")!=1:
        raise ValueError("Python source did not return exactly one native F(c,t)")
    case=YearCase(C,YEAR,T,T,boundary)
    pyfields=parse_line(normalized.decode("utf8").strip(),1,case,int(T)).normalized
    ktfields=(fields[2],*(int(x) for x in fields[3:]))
    match=pyfields==ktfields
    verdict={
        "schema":SCHEMA,
        "status":("ONE_ORIGINAL_PYTHON_KOTLIN_FCT_DAY_MATCH_NOT_YEAR_SOAK"
                  if match else "ONE_ORIGINAL_PYTHON_KOTLIN_FCT_DAY_MISMATCH_HALT"),
        "calculation_day":C,"target_day":T,"year":YEAR,
        "python_commit":py["native_source_commit"],
        "kotlin_commit":kt["source_commit"],
        "original_python_fct_calls_validated":1,
        "original_kotlin_fct_calls_validated":1,
        "matching_native_date_fields":5 if match else 0,
        "python_native_five_fields":list(pyfields),
        "kotlin_native_five_fields":list(ktfields),
        "first_mismatch_target_day":None if match else T,
        "independent_source_family_audit_certified":False,
        "independent_canonical_oracle_certified":False,
        "original_complete_years_soak_passed":0,
        "ten_thousand_year_soak_started":False,
        "windows_processes_started":0,"main_modified":False,
    }
    _durable_exclusive(output/"one-day-original-py-kt-verdict.json",canonical(verdict))
    if not match:raise RuntimeError("ORIGINAL_PYTHON_KOTLIN_DATE_MISMATCH_HALT")
    return verdict


def main():
    p=argparse.ArgumentParser()
    p.add_argument("--ci-original-single-day",action="store_true",required=True)
    p.add_argument("--python-sources",type=Path,required=True)
    p.add_argument("--original-kotlin",type=Path,required=True)
    p.add_argument("--kotlin-jar",type=Path,required=True)
    p.add_argument("--evidence-root",type=Path,required=True)
    a=p.parse_args()
    r=run(a.python_sources,a.original_kotlin,a.kotlin_jar,a.evidence_root)
    print("ORIGINAL_PYTHON_KOTLIN_ONE_DAY_V045="+json.dumps(r,sort_keys=True),flush=True)


if __name__=="__main__":
    main()
