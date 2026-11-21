#!/usr/bin/env python3
"""Bounded no-retry runner for low-level Ada Stage02/04/06-12 tests.

Static guard scans all src plus the nine selected test units and proves there
are no Calendar_Date call sites. This runner never invokes the full calendar F.
"""
from __future__ import annotations

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

SOURCE_BASE = "e17ab44aa3fd1d08eb14644164735a7c5c87721d"
V171_PARENT = "c6a605a8aaf1e2cfa815240c322527fd0c53ebb1"
BRANCH = "qa/issue29-ada-low-level-stage-tests-v172"
ACTIVATION_MESSAGE = "test(issue29-v172): execute bounded low-level Stage02/04/06-12 suites once; no Calendar_Date"
GPR = Path("issue29_v172_gmp_aware_component_tests.gpr")
SCHEMA = "ISSUE29_V172_LOW_LEVEL_ADA_COMPONENT_TESTS/1"

SOURCE_BLOBS = {
    "src/normative_oracle.adb": "0be8f8ab4ddef26d34963d5567707a511ebda50b",
    "src/normative_oracle.ads": "c4588566076798dd394feeab580ebc3d38c09744",
    "src/monster_bootstrap.adb": "603f860216979391d5ceae1fc6680a6bdb71a562",
    "src/monster_bootstrap.ads": "ff7ff628e592ab8133e8a120033cf97b9b3c865b",
    "tests/stage02_discovery01_tests.adb": "6585faeafde810b319e2cd91b6f92d977d4dc30e",
    "tests/stage04_discovery02_tests.adb": "750e8584ca7f51068a479178bac826918cdc35b0",
    "tests/stage06_discovery03_tests.adb": "e8dfd8f2a534d25ea61189beb9ed86c0fe545d2e",
    "tests/stage07_discovery04_tests.adb": "01488a4fb33d3f21ad2795f1f618fe21c448ddd9",
    "tests/stage08_discovery05_tests.adb": "0040c6a17f7373967af21a28b9dc3356ac487c0d",
    "tests/stage09_discovery06_tests.adb": "ff5c1c40f3fbead9082ac472502cbd2c3a0aa0c6",
    "tests/stage10_discovery07_tests.adb": "2776eff178cf4eab45a02a506ed7de9a53531b63",
    "tests/stage11_discovery08_tests.adb": "a019f55f3870f421f56317a2b3fc2712d2d2cd15",
    "tests/stage12_discovery09_tests.adb": "f810340c1796dbcd3374368b0cc97def62a84ab2",
}
TESTS = [
    {"name":"stage02","unit":"stage02_discovery01_tests.adb",
     "binary":Path("bin_v172/stage02_discovery01_tests"),
     "success_text":"Stage 2 DISCOVERY01: 8 పరిమిత పరీక్షలు విజయవంతమయ్యాయి",
     "assertion_pattern":None},
    {"name":"stage04","unit":"stage04_discovery02_tests.adb",
     "binary":Path("bin_v172/stage04_discovery02_tests"),
     "success_text":"STAGE04_DISCOVERY02_ASSERTIONS=",
     "assertion_pattern":r"STAGE04_DISCOVERY02_ASSERTIONS=\s*(\d+)"},
    {"name":"stage06","unit":"stage06_discovery03_tests.adb",
     "binary":Path("bin_v172/stage06_discovery03_tests"),
     "success_text":"STAGE06_DISCOVERY03_ASSERTIONS=",
     "assertion_pattern":r"STAGE06_DISCOVERY03_ASSERTIONS=\s*(\d+)"},
    {"name":"stage07","unit":"stage07_discovery04_tests.adb",
     "binary":Path("bin_v172/stage07_discovery04_tests"),
     "success_text":"STAGE07_DISCOVERY04_ASSERTIONS=",
     "assertion_pattern":r"STAGE07_DISCOVERY04_ASSERTIONS=\s*(\d+)"},
    {"name":"stage08","unit":"stage08_discovery05_tests.adb",
     "binary":Path("bin_v172/stage08_discovery05_tests"),
     "success_text":"STAGE08_DISCOVERY05_ASSERTIONS=",
     "assertion_pattern":r"STAGE08_DISCOVERY05_ASSERTIONS=\s*(\d+)"},
    {"name":"stage09","unit":"stage09_discovery06_tests.adb",
     "binary":Path("bin_v172/stage09_discovery06_tests"),
     "success_text":"STAGE09_DISCOVERY06_ASSERTIONS=",
     "assertion_pattern":r"STAGE09_DISCOVERY06_ASSERTIONS=\s*(\d+)"},
    {"name":"stage10","unit":"stage10_discovery07_tests.adb",
     "binary":Path("bin_v172/stage10_discovery07_tests"),
     "success_text":"STAGE10_DISCOVERY07_ASSERTIONS=",
     "assertion_pattern":r"STAGE10_DISCOVERY07_ASSERTIONS=\s*(\d+)"},
    {"name":"stage11","unit":"stage11_discovery08_tests.adb",
     "binary":Path("bin_v172/stage11_discovery08_tests"),
     "success_text":"STAGE11_DISCOVERY08_ASSERTIONS=",
     "assertion_pattern":r"STAGE11_DISCOVERY08_ASSERTIONS=\s*(\d+)",
     "expected_assertions":368},
    {"name":"stage12","unit":"stage12_discovery09_tests.adb",
     "binary":Path("bin_v172/stage12_discovery09_tests"),
     "success_text":"STAGE12_DISCOVERY09_ASSERTIONS=",
     "assertion_pattern":r"STAGE12_DISCOVERY09_ASSERTIONS=\s*(\d+)",
     "expected_assertions":1344},
]
ALLOWED_QA_FILES = {
    ".github/workflows/issue29-v172-low-level-component-tests.yml",
    "issue29_v172_gmp_aware_component_tests.gpr",
    "tests/issue29_v172_component_test_runner.py",
}
EVIDENCE = Path("evidence")
WALL_SECONDS = 90
CPU_SECONDS = 90
ADDRESS_SPACE_BYTES = 768 * 1024 * 1024
OUTPUT_LIMIT_BYTES = 128 * 1024
BUILD_WALL_SECONDS = 120
BUILD_CPU_SECONDS = 120
BUILD_ADDRESS_SPACE_BYTES = 1024 * 1024 * 1024
BUILD_OUTPUT_LIMIT_BYTES = 1024 * 1024
BUILD_FILE_SIZE_LIMIT_BYTES = 128 * 1024 * 1024


def insist(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def git(*args: str) -> bytes:
    return subprocess.check_output(["git", *args], stderr=subprocess.DEVNULL)


def blob_sha(data: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def json_bytes(data: dict) -> bytes:
    return (json.dumps(data, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n").encode("utf-8")


def write_exclusive(path: Path, data: bytes) -> None:
    with path.open("xb") as f:
        f.write(data)
        f.flush()
        os.fsync(f.fileno())


def child_limits(cpu: int, address_space: int, file_size: int):
    def apply() -> None:
        resource.setrlimit(resource.RLIMIT_CPU, (cpu, cpu))
        resource.setrlimit(resource.RLIMIT_AS, (address_space, address_space))
        resource.setrlimit(resource.RLIMIT_FSIZE, (file_size, file_size))
        resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
    return apply


def environment_guard() -> dict:
    insist(os.environ.get("GITHUB_RUN_ATTEMPT") == "1", "rerun attempt refused")
    insist(os.environ.get("GITHUB_EVENT_NAME") == "push", "only exact QA push allowed")
    insist(os.environ.get("GITHUB_REF") == "refs/heads/" + BRANCH, "wrong branch")
    event_path = os.environ.get("GITHUB_EVENT_PATH", "")
    insist(bool(event_path) and Path(event_path).is_file(), "GitHub event receipt missing")
    event = json.loads(Path(event_path).read_bytes())
    insist(event.get("head_commit", {}).get("message") == ACTIVATION_MESSAGE,
           "not the exact one-time activation commit")
    run_id = os.environ.get("GITHUB_RUN_ID", "")
    insist(run_id.isdigit() and int(run_id) > 0, "GitHub run identity missing")
    head = git("rev-parse", "HEAD").decode().strip()
    insist(os.environ.get("GITHUB_SHA") == head, "workflow HEAD drift")
    ancestry = subprocess.run(
        ["git", "merge-base", "--is-ancestor", V171_PARENT, head],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False
    )
    insist(ancestry.returncode == 0, "v172 branch does not descend from accepted v171")
    changed = git("diff", "--name-only", V171_PARENT + "...HEAD").decode().splitlines()
    insist(set(changed) == ALLOWED_QA_FILES and len(changed) == len(ALLOWED_QA_FILES),
           "unexpected v172 changed paths: " + repr(changed))
    return {
        "run_id":run_id,"run_attempt":1,"head":head,"branch":BRANCH,
        "event_name":"push","activation_commit_message":ACTIVATION_MESSAGE,
        "v171_parent":V171_PARENT,"source_baseline":SOURCE_BASE,"changed_paths":changed,
    }


def extract_function(text: str, name: str) -> str:
    start = re.search(r"\bfunction\s+" + re.escape(name) + r"\b", text)
    insist(start is not None, "function missing from static source audit: " + name)
    end = re.search(r"\bend\s+" + re.escape(name) + r"\s*;", text[start.end():])
    insist(end is not None, "function end missing: " + name)
    return text[start.start():start.end() + end.end()]


def source_guard() -> dict:
    receipts = {}
    for name, expected in SOURCE_BLOBS.items():
        data = Path(name).read_bytes()
        actual = blob_sha(data)
        baseline = git("rev-parse", SOURCE_BASE + ":" + name).decode().strip()
        insist(actual == expected and baseline == expected, "locked source changed: " + name)
        receipts[name] = {"git_blob_sha1":actual,"sha256":sha256(data),"bytes":len(data)}

    test_paths = [p for p in SOURCE_BLOBS if p.startswith("tests/")]
    test_text = {p:Path(p).read_text(encoding="utf-8") for p in test_paths}
    for name, text in test_text.items():
        insist("Calendar_Date" not in text, "selected test directly references Calendar_Date: " + name)

    oracle = Path("src/normative_oracle.adb").read_text(encoding="utf-8")
    spec = Path("src/normative_oracle.ads").read_text(encoding="utf-8")
    bootstrap = Path("src/monster_bootstrap.adb").read_text(encoding="utf-8")
    matches = git(
        "grep","-n","-F","Calendar_Date","--","src",
        *test_paths
    ).decode().splitlines()
    expected_matches = [
        "src/normative_oracle.adb:1113:   function Calendar_Date",
        "src/normative_oracle.adb:1199:   end Calendar_Date;",
        "src/normative_oracle.ads:68:   function Calendar_Date",
    ]
    insist(matches == expected_matches, "unexpected Calendar_Date call/reference: " + repr(matches))
    insist(oracle.count("Calendar_Date") == 2 and spec.count("Calendar_Date") == 1,
           "Calendar_Date definition/declaration changed")
    insist("Calendar_Date" not in bootstrap, "bootstrap unexpectedly references Calendar_Date")
    safe_functions = [
        extract_function(oracle,"Day_Count"),
        extract_function(oracle,"Compute_Work_Counts"),
        extract_function(oracle,"Sauce"),
        extract_function(oracle,"Ask_Bowl"),
        extract_function(oracle,"Choose_Rank"),
    ]
    insist(all("Calendar_Date" not in f for f in safe_functions),
           "component function unexpectedly calls Calendar_Date")
    insist("368" in test_text["tests/stage11_discovery08_tests.adb"]
           and "1344" in test_text["tests/stage12_discovery09_tests.adb"],
           "fixed Stage11/Stage12 acceptance counts missing")
    gpr = GPR.read_text(encoding="utf-8")
    insist('with "gnatcoll_gmp.gpr";' in gpr, "GMP GPR import missing")
    insist('for Exec_Dir use "bin_v172";' in gpr, "unexpected binary directory")
    insist('Main_Unit := external ("NATIVE_MAIN"' in gpr, "GPR main selector missing")

    return {
        "locked_sources":receipts,
        "calendar_date_reference_audit":{
            "source_references":matches,"selected_test_direct_calls":0,
            "calendar_date_invocations_authorized":0,"full_calendar_F_invocations":0,"soak_years":0,
        },
        "selected_stages":[2,4,6,7,8,9,10,11,12],
        "fixed_assertion_gates":{"stage11":368,"stage12":1344},
        "scope":"low-level selection, bowl, sauce, stones and drop components only",
    }


def verify_all():
    return environment_guard(),source_guard()


def run_bounded(command,stdout_path,stderr_path,wall,cpu,memory,output_limit,file_size_limit=None):
    insist(not stdout_path.exists() and not stderr_path.exists(),"output exists; no retry")
    start=time.monotonic()
    child=None
    violation=None
    with stdout_path.open("xb") as out,stderr_path.open("xb") as err:
        child=subprocess.Popen(
            command,stdin=subprocess.DEVNULL,stdout=out,stderr=err,
            cwd=str(Path.cwd()),env=dict(os.environ,LC_ALL="C.UTF-8"),
            start_new_session=True,preexec_fn=child_limits(cpu,memory,file_size_limit or output_limit),
            shell=False,
        )
        while True:
            total=stdout_path.stat().st_size+stderr_path.stat().st_size
            if total>output_limit:
                violation="OUTPUT_LIMIT"
                try: os.killpg(child.pid,signal.SIGKILL)
                except ProcessLookupError: pass
                break
            if time.monotonic()-start>wall:
                violation="WALL_LIMIT"
                try: os.killpg(child.pid,signal.SIGKILL)
                except ProcessLookupError: pass
                break
            if child.poll() is not None:
                break
            time.sleep(0.05)
        try:
            child.wait(timeout=5)
        except subprocess.TimeoutExpired:
            try: os.killpg(child.pid,signal.SIGKILL)
            except ProcessLookupError: pass
            child.wait(timeout=3)
    return {
        "elapsed_seconds":round(time.monotonic()-start,4),
        "exit_code":child.returncode if child else None,
        "limit_violation":violation,
        "stdout_bytes":stdout_path.stat().st_size,"stderr_bytes":stderr_path.stat().st_size,
        "stdout_sha256":sha256(stdout_path.read_bytes()),"stderr_sha256":sha256(stderr_path.read_bytes()),
    }


def preflight():
    EVIDENCE.mkdir(exist_ok=True)
    env,source=verify_all()
    insist(Path("/usr/bin/time").is_file(),"GNU time unavailable")
    write_exclusive(EVIDENCE/"preflight.json",json_bytes({
        "schema":SCHEMA,"status":"STATIC_NO_CALENDAR_DATE_CALLS_AND_SOURCE_LOCKS_PASS",
        "workflow":env,"source_audit":source,
        "tests_to_build_and_run_once":[x["name"] for x in TESTS],
        "full_calendar_F_invocations":0,"soak_years":0,
        "main_modified":False,"ada_development_branch_modified":False,
        "limits":{"wall_seconds":WALL_SECONDS,"cpu_seconds":CPU_SECONDS,
                  "address_space_bytes":ADDRESS_SPACE_BYTES,"output_bytes":OUTPUT_LIMIT_BYTES},
    }))
    print("V172_STATIC_NO_CALENDAR_DATE_CALLS_AND_SOURCE_LOCKS_PASS")


def build():
    EVIDENCE.mkdir(exist_ok=True)
    env,source=verify_all()
    pre=json.loads((EVIDENCE/"preflight.json").read_bytes())
    insist(pre["status"]=="STATIC_NO_CALENDAR_DATE_CALLS_AND_SOURCE_LOCKS_PASS"
           and pre["workflow"]==env and pre["source_audit"]==source,"stale preflight")
    entries=[]
    for test in TESTS:
        name=test["name"]
        stdout=EVIDENCE/(name+".build.stdout")
        stderr=EVIDENCE/(name+".build.stderr")
        command=["gprbuild","-p","-j2","-P",str(GPR),"-XNATIVE_MAIN="+test["unit"]]
        result=run_bounded(command,stdout,stderr,BUILD_WALL_SECONDS,BUILD_CPU_SECONDS,
                           BUILD_ADDRESS_SPACE_BYTES,BUILD_OUTPUT_LIMIT_BYTES,
                           BUILD_FILE_SIZE_LIMIT_BYTES)
        insist(result["exit_code"]==0 and result["limit_violation"] is None,
               name+" compile/link failed: "+repr(result))
        binary=test["binary"]
        insist(binary.is_file() and os.access(binary,os.X_OK),name+" binary missing")
        entries.append({
            "name":name,"unit":test["unit"],"binary":str(binary),
            "binary_bytes":binary.stat().st_size,"binary_sha256":sha256(binary.read_bytes()),
            "build_process":result,"executed_during_build":False,
        })
    write_exclusive(EVIDENCE/"build-manifest.json",json_bytes({
        "schema":SCHEMA,"status":"NINE_GMP_AWARE_BINARIES_LINKED_NOT_EXECUTED",
        "workflow":env,"entries":entries,"native_test_executions":0,"calendar_date_invocations":0,
    }))
    print("V172_STAGE02_STAGE04_STAGE06_TO_12_BUILD_LINK_PASS_NO_EXECUTION")


def run_once():
    EVIDENCE.mkdir(exist_ok=True)
    env,source=verify_all()
    pre=json.loads((EVIDENCE/"preflight.json").read_bytes())
    manifest=json.loads((EVIDENCE/"build-manifest.json").read_bytes())
    insist(pre["status"]=="STATIC_NO_CALENDAR_DATE_CALLS_AND_SOURCE_LOCKS_PASS"
           and pre["workflow"]==env and pre["source_audit"]==source,"stale preflight")
    insist(manifest["status"]=="NINE_GMP_AWARE_BINARIES_LINKED_NOT_EXECUTED"
           and manifest["workflow"]==env,"stale build manifest")
    insist(not any(EVIDENCE.glob("RUN_STARTED_*")),"a test execution was already attempted")
    built={x["name"]:x for x in manifest["entries"]}
    insist(set(built)=={x["name"] for x in TESTS},"build manifest test set mismatch")
    results=[]
    for test in TESTS:
        name=test["name"]
        item=built[name]
        binary=test["binary"]
        insist(binary.is_file() and sha256(binary.read_bytes())==item["binary_sha256"],
               name+" binary changed after build")
        write_exclusive(EVIDENCE/("RUN_STARTED_"+name.upper()),json_bytes({
            "schema":SCHEMA,"run_id":env["run_id"],"run_attempt":1,"head":env["head"],
            "test":name,"binary_sha256":item["binary_sha256"],"max_invocations":1,
            "retry_allowed":False,"calendar_date_invocations":0,
        }))
        stdout=EVIDENCE/(name+".stdout")
        stderr=EVIDENCE/(name+".stderr")
        timing=EVIDENCE/(name+".time")
        command=["/usr/bin/time","-f","%e %M %x","-o",str(timing),str(binary.resolve())]
        process=run_bounded(command,stdout,stderr,WALL_SECONDS,CPU_SECONDS,
                            ADDRESS_SPACE_BYTES,OUTPUT_LIMIT_BYTES)
        output=stdout.read_bytes().decode("utf-8",errors="strict")
        error=stderr.read_bytes()
        insist(process["exit_code"]==0 and process["limit_violation"] is None,
               name+" failed or exceeded limits: "+repr(process))
        insist(not error,name+" emitted stderr: "+repr(error[:1000]))
        insist(test["success_text"] in output,name+" success marker missing")
        assertions=None
        if test["assertion_pattern"]:
            m=re.search(test["assertion_pattern"],output)
            insist(m is not None,name+" assertion marker missing")
            assertions=int(m.group(1))
            insist(assertions>0,name+" reported zero assertions")
            if "expected_assertions" in test:
                insist(assertions==test["expected_assertions"],
                       name+" fixed assertion count mismatch: "+str(assertions))
        t=timing.read_text(encoding="ascii").strip().split()
        insist(len(t)==3,name+" GNU time receipt malformed")
        results.append({
            "name":name,"status":"PASS","assertions_reported":assertions,
            "process":process,
            "gnu_time":{"elapsed_seconds":float(t[0]),"max_rss_kib":int(t[1]),"exit_code":int(t[2])},
            "binary_sha256":item["binary_sha256"],
        })
    receipt={
        "schema":SCHEMA,"status":"PASS_STAGE02_STAGE04_STAGE06_TO_12_LOW_LEVEL_COMPONENTS_ONLY",
        "workflow":env,"results":results,
        "calendar_date_invocations":0,"full_calendar_F_invocations":0,
        "original_historical_source_invocations":0,"soak_years":0,
        "production_certified":False,"rerun_or_retry_allowed":False,
        "limits":{"wall_seconds_per_test":WALL_SECONDS,"cpu_seconds_per_test":CPU_SECONDS,
                  "address_space_bytes_per_test":ADDRESS_SPACE_BYTES,
                  "combined_output_bytes_per_test":OUTPUT_LIMIT_BYTES},
    }
    write_exclusive(EVIDENCE/"result.json",json_bytes(receipt))
    print("V172_STAGE02_STAGE04_STAGE06_TO_12_PASS_ZERO_CALENDAR_DATE_ZERO_SOAK")


def main():
    if len(sys.argv)!=2 or sys.argv[1] not in {"preflight","build","run-once"}:
        raise SystemExit("usage: runner.py {preflight|build|run-once}")
    if sys.argv[1]=="preflight": preflight()
    elif sys.argv[1]=="build": build()
    else: run_once()
    return 0


if __name__=="__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        EVIDENCE.mkdir(exist_ok=True)
        target=EVIDENCE/"failure.json"
        if not target.exists():
            write_exclusive(target,json_bytes({
                "schema":SCHEMA,"status":"FAIL_CLOSED","failure":repr(exc),
                "calendar_date_invocations":0,"soak_years":0,"automatic_retry_allowed":False,
            }))
        raise
