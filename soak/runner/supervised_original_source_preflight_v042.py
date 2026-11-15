#!/usr/bin/env python3
"""v042: observe REAL pinned v017 source transports in --check-only mode.

The OS process is real; the original sources are imported/required and hashed.
Every command is --check-only: ZERO F(c,t) calls and ZERO year calculations.
This does not certify source/algorithmic independence, native execution, or
Windows resource behavior. Linux GitHub Actions only; one process at a time.
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

from native_execution_receipt_v038 import sha,canonical
from native_raw_pair_gate_v018 import verify_locked_sources,name_maps
from supervised_process_observation_v041 import (
    _admit,_pid_start_id,_durable_exclusive,_read_limited,sha_file
)

SCHEMA="PASTAFARI_SUPERVISED_SOURCE_PREFLIGHT_V042/1"
SUCCESS="TWO_ORIGINAL_SOURCE_TRANSPORT_PROCESSES_OBSERVED_WITH_ZERO_FCT_CALLS"
FILE_LIMIT=65536
PYTHON_ADDRESS_SPACE_BYTES=640*1024*1024
NODE_ADDRESS_SPACE_BYTES=8*1024*1024*1024
NODE_MAX_OLD_SPACE_MB=128
NODE_MAX_SEMI_SPACE_MB=16
MIN_AVAILABLE_RAM_BYTES=1024*1024*1024
PYTHON_COMMIT="0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4"
JS_COMMIT="03ac0c7f4db3c35487993dd31982faa37dd3948e"
ADAPTERS={"REF-41":"pilot_python_transport_v017.py",
          "REF-24":"pilot_javascript_transport_v017.cjs"}


def _child_limits(address_space_bytes:int):
    os.nice(19)
    resource.setrlimit(resource.RLIMIT_AS,(address_space_bytes,address_space_bytes))
    resource.setrlimit(resource.RLIMIT_CPU,(12,12))
    os.umask(0o077)


def _available_ram_bytes() -> int:
    for line in Path('/proc/meminfo').read_text(encoding='ascii').splitlines():
        if line.startswith('MemAvailable:'):
            return int(line.split()[1])*1024
    return 0


def _capture_one(root:Path,source_root:Path,engine_id:str) -> dict:
    if engine_id not in ADAPTERS:
        raise ValueError("unexpected source pilot engine")
    work=root/engine_id
    work.mkdir(mode=0o700,exist_ok=False)
    source,contents=verify_locked_sources(source_root,engine_id)
    names=name_maps(engine_id,contents)
    if [len(names[0]),len(names[1])]!=[17,47]:
        raise ValueError("pinned original native names invalid")
    if source["commit"]!=(PYTHON_COMMIT if engine_id=="REF-41" else JS_COMMIT):
        raise ValueError("original source commit changed")
    for info in source["sources"]:
        if engine_id=="REF-41":
            folder=source_root/"Python-Turkce"
        else:
            folder=source_root/"JavaScript-Interlingue"
        path=(folder/source["commit"]/info["path"]).resolve(strict=True)
        if sha_file(path)!=info["sha256"]:
            raise ValueError("original source bytes changed before process launch")
    adapter=Path(__file__).resolve().parent/ADAPTERS[engine_id]
    if not adapter.is_file():
        raise ValueError("missing exact v017 transport")
    appsha=sha_file(adapter)
    if engine_id=="REF-41":
        address_space_bytes=PYTHON_ADDRESS_SPACE_BYTES
        binary=Path(sys.executable).resolve(strict=True)
        cmd=[str(binary),"-I","-B",str(adapter),
             "--sources-root",str(source_root),"--check-only"]
    else:
        address_space_bytes=NODE_ADDRESS_SPACE_BYTES
        node=shutil.which("node")
        if not node:
            raise RuntimeError("Node required for pinned JS original preflight")
        binary=Path(node).resolve(strict=True)
        # V8 reserves a large *virtual* address range. 640MiB RLIMIT_AS
        # prevents startup despite tiny resident use. Keep a larger virtual
        # cap while independently restricting the JS heap and RAM admission.
        cmd=[str(binary),f"--max-old-space-size={NODE_MAX_OLD_SPACE_MB}",
             f"--max-semi-space-size={NODE_MAX_SEMI_SPACE_MB}",str(adapter),
             "--sources-root",str(source_root),"--check-only"]
    free_ram=_available_ram_bytes()
    if free_ram<MIN_AVAILABLE_RAM_BYTES:
        raise RuntimeError('Linux CI available RAM insufficient for source-only probe')
    interpreter_sha=sha_file(binary)
    record={
        "schema":SCHEMA,
        "status":"SOURCE_PROCESS_PREFLIGHT_NOT_CONFIRMED",
        "engine_id":engine_id,
        "source_commit":source["commit"],
        "original_source_sha256":[entry["sha256"] for entry in source["sources"]],
        "language":"Python" if engine_id=="REF-41" else "JavaScript",
        "source_class":"reference",
        "transport_adapter_path":str(adapter),
        "transport_adapter_sha256":appsha,
        "runtime_executable_path":str(binary),
        "runtime_executable_sha256":interpreter_sha,
        "launch_argv":cmd,
        "launch_argv_sha256":sha(canonical(cmd)),
        "pid":None,"process_creation_id":None,
        "exit_code":None,"stdout_sha256":None,"stderr_sha256":None,
        "output_preflight_status":None,
        "converter_calls":0,
        "os_stdout_is_native_raw_date_data":False,
        "actual_native_date_execution_proven":False,
        "independence_certified":False,
        "full_original_soak_years_approved":0,
        "windows_processes_started":0,
        "limits":{"linux_rlimit_as_bytes":address_space_bytes,
                  "linux_rlimit_cpu_seconds":12,"nice":19,
                  "ram_admission_min_bytes":MIN_AVAILABLE_RAM_BYTES,
                  "ram_available_before_launch_bytes":free_ram,
                  "node_max_old_space_mb":NODE_MAX_OLD_SPACE_MB if engine_id=='REF-24' else None,
                  "node_max_semi_space_mb":NODE_MAX_SEMI_SPACE_MB if engine_id=='REF-24' else None},
    }
    failed=None
    with (work/"os-stdout.log").open("xb") as out, (work/"os-stderr.log").open("xb") as err:
        proc=subprocess.Popen(cmd,stdin=subprocess.DEVNULL,
                              stdout=out,stderr=err,cwd=str(work),
                              close_fds=True,start_new_session=True,
                              preexec_fn=lambda:_child_limits(address_space_bytes))
        record["pid"]=proc.pid
        try:
            record["process_creation_id"]=_pid_start_id(proc.pid)
            # This is a bounded *no-calculation preflight*, not a native
            # calculation. Real slow F(c,t) tasks must not be timed out.
            proc.wait(timeout=20)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait(timeout=5)
            failed="CHECK_ONLY_PREFLIGHT_TIMEOUT"
        except BaseException as exc:
            if proc.poll() is None:
                proc.kill()
                proc.wait(timeout=5)
            failed="PROCESS_IDENTITY_OBSERVATION_BLOCKED:"+type(exc).__name__
        record["exit_code"]=proc.returncode
    record["stdout_sha256"]=sha(_read_limited(work/"os-stdout.log"))
    record["stderr_sha256"]=sha(_read_limited(work/"os-stderr.log"))
    if failed is None and record["exit_code"]!=0:
        failed="SOURCE_CHECK_ONLY_RETURNED_NONZERO"
    if (appsha!=sha_file(adapter) or interpreter_sha!=sha_file(binary)):
        failed="RUNTIME_OR_ADAPTER_MUTATED_DURING_PROBE"
    if failed is None:
        try:
            after,files=verify_locked_sources(source_root,engine_id)
            if after!=source:
                raise ValueError("source lock changed after process")
            name_maps(engine_id,files)
            native=_read_limited(work/"os-stdout.log")
            def no_dupes(pairs):
                obj={}
                for k,v in pairs:
                    if k in obj:raise ValueError("duplicate source preflight output field")
                    obj[k]=v
                return obj
            if not native.endswith(b"\n") or native.count(b"\n")!=1:
                raise ValueError("not a single bounded source preflight result")
            report=json.loads(native,object_pairs_hook=no_dupes)
            expected_source=(source["sources"][0]["sha256"] if engine_id=="REF-41"
                             else [x["sha256"] for x in source["sources"]])
            if (not isinstance(report,dict)
                    or report.get("status")!="SOURCE_AND_TRANSPORT_PREFLIGHT_ONLY"
                    or report.get("engine")!=engine_id
                    or report.get("converter_calls")!=0
                    or type(report.get("converter_calls")) is not int
                    or report.get("sha256")!=expected_source):
                raise ValueError("original check-only transport output fails native source contract")
            record["output_preflight_status"]=report["status"]
        except BaseException as exc:
            failed="INVALID_CHECK_ONLY_OR_PINNED_SOURCE:"+type(exc).__name__
    record["status"]=(
        "ORIGINAL_PINNED_SOURCE_CHECK_ONLY_PROCESS_OBSERVED_NO_DATE_CALLS"
        if failed is None else "ORIGINAL_PINNED_SOURCE_PREFLIGHT_BLOCKED")
    record["blocked_reason"]=failed
    _durable_exclusive(work/"process-evidence.json",canonical(record))
    if failed:
        raise RuntimeError(engine_id+": "+failed)
    return record


def run_ci_source_preflights(root:Path,source_root:Path) -> dict:
    _admit(root)
    root=root.resolve(strict=True)
    source_root=source_root.resolve(strict=True)
    if root==source_root or root in source_root.parents or source_root in root.parents:
        raise ValueError("preflight evidence directory must not contain source tree or vice versa")
    reports=[_capture_one(root,source_root,engine) for engine in ("REF-41","REF-24")]
    summary={
        "schema":SCHEMA,
        "status":SUCCESS,
        "source_preflight_processes":len(reports),
        "pinned_engine_ids":[d["engine_id"] for d in reports],
        "pinned_commits":[d["source_commit"] for d in reports],
        "all_os_process_exit_codes_zero":all(d["exit_code"]==0 for d in reports),
        "all_natively_loaded_source_closures_checked":True,
        "all_stdout_and_stderr_saved_separately":True,
        "native_converter_Fct_calls":0,
        "original_native_full_years_approved":0,
        "algorithmic_independence_certified":False,
        "windows_workloads_started":0,
    }
    _durable_exclusive(root/"summary.json",canonical(summary))
    return summary


def _cli():
    p=argparse.ArgumentParser()
    p.add_argument("--ci-sources-preflight",action="store_true",required=True)
    p.add_argument("--source-root",type=Path,required=True)
    p.add_argument("--output-root",type=Path,required=True)
    a=p.parse_args()
    result=run_ci_source_preflights(a.output_root,a.source_root)
    print("ORIGINAL_SOURCE_SUPERVISED_CHECK_ONLY_V042="+
          json.dumps(result,sort_keys=True),flush=True)


if __name__=="__main__":
    _cli()
