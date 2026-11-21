#!/usr/bin/env python3
"""Issue29 v170: bounded, source-locked native Ada regressions that NEVER call Calendar_Date.

Runs only the exact corrected-development source Stage01/03/05 executable entrypoints.
Does NOT run Stage14, Stage41, any other F(c,t) date converter, or Soak.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import resource
import signal
import subprocess
import sys
import time

sys.path.insert(0, str(Path(__file__).resolve().parent))
from issue29_v168_single_native_guard import BASE, source_guard, digest, blob_sha

SCHEMA="ISSUE29_V170_GMP_AWARE_SOURCE_LOCKED_NO_F_REGRESSION/1"
TEST_BLOBS={
    "tests/stage01_tests.adb":"a4a5fd120390cf9fb8082e9343b4c1fe16bb1a9d",
    "tests/stage03_patch01_tests.adb":"71286209b4747b0505e926f18d83cc179a569b85",
    "tests/stage05_patch02_tests.adb":"f02abee387f8b0a543499cf70085606f8004c65e",
    "src/monster_bootstrap.adb":"603f860216979391d5ceae1fc6680a6bdb71a562",
}
BINARIES=("stage01_tests","stage03_patch01_tests","stage05_patch02_tests")
CAP_WALL=60
CAP_CPU=60
CAP_AS=768*1024*1024
CAP_OUTPUT=64*1024
PROJ="issue29_v169_gmp_aware_legacy_compile.gpr"
BIN_DIR=Path("bin_v169")
NO_F_TOKEN=re.compile(rb"\bCalendar_Date\s*\(",re.IGNORECASE)
EXPECTED={
    "stage01_tests": "Stage 1 పరీక్షలు అన్నీ విజయవంతమయ్యాయి",
    "stage03_patch01_tests":"STAGE03_PATCH01_ASSERTIONS=",
    "stage05_patch02_tests":"STAGE05_PATCH02_ASSERTIONS=",
}

def insist(cond, reason):
    if not cond: raise ValueError(reason)

def git(*args):
    return subprocess.check_output(["git",*args],stderr=subprocess.DEVNULL).decode().strip()

def verify_preflight():
    origin=source_guard()  # locks 7 corrected Ada sources and GMP GPR, canonical README
    head=git("rev-parse","HEAD")
    insist(subprocess.run(["git","merge-base","--is-ancestor",BASE,head],
                          stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL).returncode==0,
           "branch not descended from exact corrected Ada development source")
    locked={}
    for file,want in TEST_BLOBS.items():
        p=Path(file)
        raw=p.read_bytes()
        actual=blob_sha(raw)
        insist(actual==want and git("rev-parse",BASE+":"+file)==want,
               "source drift or unexpected test fixture: "+file)
        insist(not NO_F_TOKEN.search(raw),
               "prohibited native Calendar_Date call in no-F main/bootstrap: "+file)
        locked[file]={"git_blob":actual,"sha256":digest(raw)}
    project=Path(PROJ).read_text()
    insist('with "gnatcoll_gmp.gpr";' in project,
           "isolated build missing GMP project dependency")
    insist('for Source_Dirs use ("src", "tests");' in project,
           "isolated build must use unchanged development-branch source")
    binaries={}
    for name in BINARIES:
        p=BIN_DIR/name
        insist(p.is_file() and os.access(p,os.X_OK),"unbuilt binary: "+str(p))
        binaries[name]={"sha256":digest(p.read_bytes()),"bytes":p.stat().st_size}
    return {
        "schema":SCHEMA,"status":"SOURCE_LOCKS_AND_NO_F_ENTRYPOINT_CHECKS_PASS",
        "corrected_dev_baseline_commit":BASE,
        "head":head,"locked_source":origin,
        "locked_entrypoints":locked,"binaries":binaries,
        "native_date_calendar_calls_permitted":0,
        "original_soak_years":0,
        "soak_dispatch_enabled":False,
        "limits":{"wall_s":CAP_WALL,"cpu_s":CAP_CPU,
                  "virtual_address_bytes":CAP_AS,"combined_output_bytes":CAP_OUTPUT},
    }

def preexec_limits():
    resource.setrlimit(resource.RLIMIT_CPU,(CAP_CPU,CAP_CPU))
    resource.setrlimit(resource.RLIMIT_AS,(CAP_AS,CAP_AS))
    resource.setrlimit(resource.RLIMIT_CORE,(0,0))

def kill_process_group(p):
    try: os.killpg(p.pid,signal.SIGKILL)
    except ProcessLookupError:pass

def test_each(evidence):
    insist(evidence.is_dir(),"existing output directory required")
    pre=verify_preflight()
    (evidence/"v170-preflight.json").write_bytes(
        (json.dumps(pre,sort_keys=True,indent=2,ensure_ascii=False)+"\n").encode("utf-8"))
    summary={"schema":SCHEMA,"status":"FAIL_CLOSED","preflight_head":pre["head"],
             "tests":[],"date_calls":0,"original_soak_years":0,
             "soak_dispatch_enabled":False,"further_date_dispatch_authorized":False}
    for name in BINARIES:
        path=BIN_DIR/name
        out=evidence/(name+".stdout")
        err=evidence/(name+".stderr")
        entry={"name":name,"status":"NOT_STARTED",
               "binary_sha256":pre["binaries"][name]["sha256"],
               "elapsed_wall_s":None,"max_rss_kib":None,
               "exit_code":None,"exceeded":None}
        summary["tests"].append(entry)
        p=None
        try:
            with out.open("xb") as so,err.open("xb") as se:
                p=subprocess.Popen([str(path.resolve())],stdin=subprocess.DEVNULL,
                                   stdout=so,stderr=se,shell=False,
                                   start_new_session=True,preexec_fn=preexec_limits)
                start=time.monotonic()
                while True:
                    if out.stat().st_size+err.stat().st_size > CAP_OUTPUT:
                        entry["exceeded"]="OUTPUT_CAP"
                        kill_process_group(p); break
                    if time.monotonic()-start > CAP_WALL:
                        entry["exceeded"]="WALL_CAP"
                        kill_process_group(p); break
                    if p.poll() is not None: break
                    time.sleep(.05)
                p.wait(timeout=5)
            entry["elapsed_wall_s"]=round(time.monotonic()-start,4)
            entry["max_rss_kib"]=resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss
            entry["exit_code"]=p.returncode
            raw=out.read_bytes()
            errors=err.read_bytes()
            entry["stdout_sha256"]=digest(raw)
            entry["stderr_sha256"]=digest(errors)
            entry["stdout_bytes"]=len(raw)
            entry["stderr_bytes"]=len(errors)
            insist(p.returncode==0 and entry["exceeded"] is None,
                   "native no-F regression process error/resource cap")
            insist(len(errors)==0,"unexpected native stderr")
            msg=raw.decode("utf-8",errors="strict")
            insist(EXPECTED[name] in msg,"native expected test verdict missing")
            if name!="stage01_tests":
                matched=re.findall(r"STAGE0[35]_[A-Z0-9_]+_ASSERTIONS=\s*(\d+)",msg)
                insist(len(matched)==1 and int(matched[0])>0,
                       "missing unique positive assertion count")
                entry["assertions"]=int(matched[0])
            entry["status"]="PASS_NATIVE_NO_CALENDAR_F"
        except Exception as err_obj:
            entry["failure"]=str(err_obj)
            entry["status"]="FAIL_CLOSED"
            if p and p.poll() is None:
                kill_process_group(p)
                p.wait(timeout=5)
        finally:
            if out.exists():
                entry["stdout_sha256"]=digest(out.read_bytes())
            if err.exists():
                entry["stderr_sha256"]=digest(err.read_bytes())
            (evidence/"v170-progress.json").write_bytes(
                (json.dumps(summary,sort_keys=True,indent=2)+"\n").encode())
        if entry["status"]!="PASS_NATIVE_NO_CALENDAR_F":
            break  # no retry, no next native test after failure
    if len(summary["tests"])==3 and all(
        e["status"]=="PASS_NATIVE_NO_CALENDAR_F" for e in summary["tests"]
    ):
        summary["status"]="THREE_SOURCE_LOCKED_ADA_NO_F_REGRESSIONS_PASS"
    (evidence/"v170-final.json").write_bytes(
        (json.dumps(summary,sort_keys=True,indent=2)+"\n").encode())
    insist(summary["status"]=="THREE_SOURCE_LOCKED_ADA_NO_F_REGRESSIONS_PASS",
           "one or more targeted no-F Ada tests failed; no calendar run or retry")
    print("V170_STAGE01_STAGE03_STAGE05_NATIVE_NO_CALENDAR_DATE_PASS")

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--evidence",type=Path,required=True)
    args=p.parse_args()
    test_each(args.evidence)

if __name__=="__main__":
    main()
