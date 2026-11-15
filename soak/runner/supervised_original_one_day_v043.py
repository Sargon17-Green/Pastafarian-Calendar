#!/usr/bin/env python3
"""v043: ONE exact native F(c,t) for each of two ORIGINAL pinned reference branches.

Runs ONLY on ephemeral Linux GitHub Actions, sequentially, with current RAM/disk
admission, low OS priority, virtual-memory and JS heap caps. Actual original
native F(c,t) calls are NOT killed for being slow; no explicit wall timeout.
This is a one-day pilot, NEVER a full-year soak or independent canonical proof.

The OS stdout/stderr logs and the transport's --raw-out/--normalized-out date
data are distinct evidence files. Native source/normalization is checked with
the independent v018 source gate, then the 5 numeric fields are compared.
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

from native_raw_pair_gate_v018 import verify_locked_sources, verify_stream, name_maps
from supervised_process_observation_v041 import (
    _admit,_pid_start_id,_durable_exclusive,_read_limited,sha_file
)
from native_execution_receipt_v038 import sha,canonical
from year_validator import YearCase,parse_line

C="-15055671"
T="-15055671"
YEAR="5000"
SCHEMA="PASTAFARI_SUPERVISED_ORIGINAL_REFERENCE_ONE_DAY_V043/1"
RUNTIME_LIMITS={
    "REF-41":{"as_bytes":1536*1024*1024},
    "REF-24":{"as_bytes":8*1024*1024*1024,"old_space_mb":384,"semi_space_mb":16},
}
MAX_OUTPUT_BYTES=256*1024
BOUNDARY_FILE=Path(__file__).resolve().parents[1]/"control/adjacent_three_original_year_boundaries_v030.json"


def _ram_available():
    for line in Path("/proc/meminfo").read_text().splitlines():
        if line.startswith("MemAvailable:"):
            return int(line.split()[1])*1024
    return 0


def _low_priority_limits(as_bytes:int):
    os.nice(19)
    resource.setrlimit(resource.RLIMIT_AS,(as_bytes,as_bytes))
    os.umask(0o077)
    # Intentionally NO CPU-time or wall-time termination for genuine F(c,t).


def _guard_year():
    original=BOUNDARY_FILE.read_bytes()
    p=json.loads(original)
    if (p["schema"]!="PASTAFARI_THREE_ADJACENT_ORIGINAL_YEAR_BOUNDARY_WITNESS_V030/1"
            or p["status"]!="ORIGINAL_PYTHON_AND_KOTLIN_BOUNDARY_CANDIDATES_MATCH_NOT_CERTIFIED"
            or p["calculation_day"]!=C
            or p["native_boundary_columns_compared"]!=27
            or p["first_mismatch"] is not None
            or p["algorithmic_independence_certified"] is not False):
        raise ValueError("native original year boundary evidence not acceptable")
    y=[row for row in p["years"] if row["year"]==5000]
    if len(y)!=1 or not int(y[0]["first_target_day"])<=int(T)<=int(y[0]["last_target_day"]):
        raise ValueError("single target not inside independently sourced year-5000 boundaries")
    return sha(original)


def _run_one(engine_id:str,root:Path,sources:Path,boundary_sha:str)->dict:
    engine,source_files=verify_locked_sources(sources,engine_id)
    catalogs=name_maps(engine_id,source_files)
    if [len(x) for x in catalogs]!=[17,47]:
        raise ValueError("native names source malformed")
    adapter=Path(__file__).resolve().parent/(
        "pilot_python_transport_v017.py" if engine_id=="REF-41"
        else "pilot_javascript_transport_v017.cjs")
    adapter_sha=sha_file(adapter)
    if engine_id=="REF-41":
        program=Path(sys.executable).resolve(strict=True)
        cmd=[str(program),"-I","-B",str(adapter)]
    else:
        node=shutil.which("node")
        if node is None:raise RuntimeError("node executable unavailable")
        program=Path(node).resolve(strict=True)
        cmd=[str(program),"--max-old-space-size=384","--max-semi-space-size=16",
             str(adapter)]
    binary_sha=sha_file(program)
    d=root/engine_id
    d.mkdir(mode=0o700,exist_ok=False)
    raw=d/"native-raw.jsonl"
    norm=d/"native-normalized.jsonl"
    trans=d/"native-transport-receipt.json"
    cmd += ["--sources-root",str(sources),"--calculation-day",C,
            "--first-target-day",T,"--last-target-day",T,
            "--raw-out",str(raw),"--normalized-out",str(norm),
            "--receipt-out",str(trans)]
    if (len(set([raw,norm,trans]))!=3 or any(p.exists() for p in (raw,norm,trans))):
        raise RuntimeError("native output paths not unique or not write-once")
    free_ram=_ram_available()
    if free_ram<2*1024*1024*1024:
        raise RuntimeError("CI RAM admission blocked, no original date process launched")
    if shutil.disk_usage(root).free<500*1024*1024:
        raise RuntimeError("CI disk admission blocked, no original date process launched")
    rec={
        "schema":SCHEMA,"engine":engine_id,
        "status":"NATIVE_SINGLE_DAY_UNCONFIRMED",
        "native_source_commit":engine["commit"],
        "original_source_sha256":[src["sha256"] for src in engine["sources"]],
        "adapter_sha256":adapter_sha,
        "runtime_executable_sha256":binary_sha,
        "runtime_executable_path":str(program),
        "exact_argv":cmd,"exact_argv_sha256":sha(canonical(cmd)),
        "calculation_day":C,"target_day":T,"boundary_evidence_sha256":boundary_sha,
        "pid":None,"process_creation_id":None,"exit_code":None,
        "run_environment_resource_admitted":"EPHEMERAL_LINUX_CI_ONLY",
        "rss_cap_enforced":False,
        "memory_virtual_address_cap_bytes":RUNTIME_LIMITS[engine_id]["as_bytes"],
        "available_ram_before_launch_bytes":free_ram,
        "cpu_nice_requested":19,"explicit_wall_timeout_seconds":None,
        "native_date_calls_expected":1,
        "validated_native_date_calls":0,
        "stdout_sha256":None,"stderr_sha256":None,
        "native_raw_sha256":None,"native_normalized_sha256":None,
        "transport_receipt_sha256":None,
        "os_stdout_is_native_data":False,
        "independent_source_lineage_certified":False,
        "canonical_oracle_certified":False,
        "official_native_full_year_soak_passes":0,
        "windows_processes_started":0,
    }
    failure=None
    env=os.environ.copy()
    env["PASTAFARI_SOAK_RESOURCE_ADMITTED"]="1"
    with (d/"os-stdout.log").open("xb") as stdout, (d/"os-stderr.log").open("xb") as stderr:
        proc=subprocess.Popen(cmd,stdin=subprocess.DEVNULL,
                              stdout=stdout,stderr=stderr,
                              cwd=str(d),close_fds=True,
                              start_new_session=True,env=env,
                              preexec_fn=lambda:_low_priority_limits(RUNTIME_LIMITS[engine_id]["as_bytes"]))
        rec["pid"]=proc.pid
        try:
            rec["process_creation_id"]=_pid_start_id(proc.pid)
            proc.wait()  # NEVER kill a real slow converter merely due elapsed time
        except BaseException as exc:
            failure="PROCESS_IDENTITY_OR_WAIT_FAILED:"+type(exc).__name__
        rec["exit_code"]=proc.poll()
    for field,path in (("stdout_sha256",d/"os-stdout.log"),
                       ("stderr_sha256",d/"os-stderr.log")):
        rec[field]=sha(_read_limited(path))
    if failure is None and rec["exit_code"]!=0:
        failure="ORIGINAL_NATIVE_CHILD_EXIT_NONZERO"
    if (adapter_sha!=sha_file(adapter) or binary_sha!=sha_file(program)):
        failure="RUNTIME_OR_ADAPTER_CHANGED_DURING_NATIVE_COMPUTE"
    try:
        engine2,_=verify_locked_sources(sources,engine_id)
        if engine2!=engine:
            failure="ORIGINAL_SOURCE_METADATA_CHANGED_AFTER_NATIVE_COMPUTE"
    except BaseException:
        failure="ORIGINAL_SOURCE_BYTES_CHANGED_AFTER_NATIVE_COMPUTE"
    if failure is None:
        try:
            checked=verify_stream(engine_id,sources,raw,norm,trans)
            if (checked["status"]!="NATIVE_RAW_TRANSPORT_EVIDENCE_PASS_BOUNDED"
                or checked["rows_verified"]!=1 or checked["year_certified"] is not False):
                raise ValueError("v018 pilot original raw semantic result not approved")
            for key,file in (("native_raw_sha256",raw),
                             ("native_normalized_sha256",norm),
                             ("transport_receipt_sha256",trans)):
                rec[key]=sha(_read_limited(file))
            if _read_limited(d/"os-stdout.log")==_read_limited(raw):
                raise ValueError("OS stdout incorrectly equated to original native data")
            rec["validated_native_date_calls"]=1
        except BaseException as exc:
            failure="NATIVE_DATA_SEMANTIC_OR_TRANSPORT_FAILURE:"+type(exc).__name__
    rec["status"]=(
        "SINGLE_ORIGINAL_FCT_DAY_OBSERVED_AND_NATIVE_RAW_VERIFIED_NOT_YEAR"
        if failure is None else "ORIGINAL_NATIVE_PILOT_BLOCKED")
    rec["blocked_reason"]=failure
    _durable_exclusive(d/"process-evidence.json",canonical(rec))
    if failure:
        raise RuntimeError(engine_id+":"+failure)
    return rec


def run_one_day_pilot(source_root:Path,output_root:Path)->dict:
    _admit(output_root)
    source_root=source_root.resolve(strict=True)
    output_root=output_root.resolve(strict=True)
    if source_root==output_root or source_root in output_root.parents or output_root in source_root.parents:
        raise ValueError("owned output and source directory must be distinct")
    boundary_sha=_guard_year()
    records=[_run_one(engine,output_root,source_root,boundary_sha)
             for engine in ("REF-41","REF-24")]
    case=YearCase(C,YEAR,T,T,boundary_sha)
    values=[]
    for rec in records:
        file=output_root/rec["engine"]/"native-normalized.jsonl"
        data=_read_limited(file)
        lines=data.decode("utf8").splitlines()
        if len(lines)!=1:raise ValueError("single-day original normalized transcript missing")
        day=parse_line(lines[0],1,case,int(T))
        values.append(day.normalized)
    if values[0]!=values[1]:
        result="NATIVE_ONE_DAY_MISMATCH_STOP"
    else:
        result="ONE_NATIVE_FCT_DAY_EACH_ENGINE_MATCH_NOT_FULL_YEAR"
    report={
        "schema":SCHEMA,"status":result,
        "calculation_day":C,"target_day":T,
        "year":YEAR,"boundary_evidence_sha256":boundary_sha,
        "two_unchanged_original_reference_commits":[x["native_source_commit"] for x in records],
        "one_original_date_call_per_engine":all(x["validated_native_date_calls"]==1 for x in records),
        "original_date_rows_compared":1,
        "matching_numeric_date_fields":5 if values[0]==values[1] else 0,
        "python_native_fields":list(values[0]),
        "javascript_native_fields":list(values[1]),
        "complete_years_compared":0,
        "independent_algorithm_lineage_certified":False,
        "canonical_oracle_certified":False,
        "original_full_year_soak_passes":0,
        "long_soak_started":False,
        "windows_processes_started":0,
    }
    _durable_exclusive(output_root/"one-day-verdict.json",canonical(report))
    if result!="ONE_NATIVE_FCT_DAY_EACH_ENGINE_MATCH_NOT_FULL_YEAR":
        raise RuntimeError("first native F(c,t) pilot disagreement; no further dispatch")
    return report


def main():
    p=argparse.ArgumentParser()
    p.add_argument("--ci-original-one-day",action="store_true",required=True)
    p.add_argument("--sources-root",type=Path,required=True)
    p.add_argument("--output-root",type=Path,required=True)
    a=p.parse_args()
    result=run_one_day_pilot(a.sources_root,a.output_root)
    print("PINNED_ORIGINAL_REFERENCE_ONE_DAY_V043="+json.dumps(result,sort_keys=True),flush=True)


if __name__=="__main__":
    main()
