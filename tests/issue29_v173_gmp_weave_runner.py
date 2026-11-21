#!/usr/bin/env python3
"""One-shot, source-locked test of production GMP full-weave count/unrank.

The test compares 216 small-family ranks against Month_Weaving and exercises
the 45-month GMP boundary. It never calls Normative_Oracle.Calendar_Date.
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
V172_PARENT = "f90fdf9e9b6dad0d4afabbbdede8b93f3f8ec80f"
BRANCH = "qa/issue29-ada-gmp-weave-component-v173"
ACTIVATION_MESSAGE = "test(issue29-v173): execute production GMP weave component checks once; no Calendar_Date"
GPR = Path("issue29_v173_gmp_weave_component.gpr")
TEST = Path("tests/issue29_v173_gmp_weave_tests.adb")
TEST_BLOB = "63b0c0ae85102cfc8ecca6f0351c9a79255e7193"
GPR_BLOB = "3dd08b80ada6d1939eac3b0d4a379c4bb71fb338"
SCHEMA = "ISSUE29_V173_PRODUCTION_GMP_WEAVE_COMPONENT/1"

SOURCE_BLOBS = {
    "src/normative_oracle.adb": "0be8f8ab4ddef26d34963d5567707a511ebda50b",
    "src/normative_oracle.ads": "c4588566076798dd394feeab580ebc3d38c09744",
    "src/exact_math.adb": "4b014d2e6a467ec606493c6c977e8cc184fea40a",
    "src/exact_math.ads": "3ab9c5325858e5ef2d7fa59ab6d30d0c1ff523aa",
    "src/month_weaving.adb": "9b02c62dfbc7d8b3b532aba8cd9f1ad0f8b28fef",
    "src/month_weaving.ads": "183c0e4d9538ae1defe1b63eb3871ffe7feee991",
    "src/canonical_full_weave_gmp_v164.adb": "845bd8905943a54e63d6aba0334404a5051fe666",
    "src/canonical_full_weave_gmp_v164.ads": "0b68edf7eddbc33869358bcfcc21e32465fc591e",
    "tests/stage13_weave_tests.adb": "91e61635f7c78cb0f7d44dcd75709fa998b952a1",
}
ALLOWED_QA_FILES = {
    ".github/workflows/issue29-v173-gmp-weave-component.yml",
    "issue29_v173_gmp_weave_component.gpr",
    "tests/issue29_v173_gmp_weave_tests.adb",
    "tests/issue29_v173_gmp_weave_runner.py",
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
        ["git", "merge-base", "--is-ancestor", V172_PARENT, head],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False
    )
    insist(ancestry.returncode == 0, "v173 branch does not descend from v172")
    changed = git("diff", "--name-only", V172_PARENT + "...HEAD").decode().splitlines()
    insist(set(changed) == ALLOWED_QA_FILES and len(changed) == len(ALLOWED_QA_FILES),
           "unexpected v173 changed paths: " + repr(changed))
    return {
        "run_id":run_id,"run_attempt":1,"head":head,"branch":BRANCH,
        "event_name":"push","activation_commit_message":ACTIVATION_MESSAGE,
        "v172_parent":V172_PARENT,"source_baseline":SOURCE_BASE,"changed_paths":changed,
    }


def source_guard() -> dict:
    receipts = {}
    for name, expected in SOURCE_BLOBS.items():
        data = Path(name).read_bytes()
        actual = blob_sha(data)
        baseline = git("rev-parse", SOURCE_BASE + ":" + name).decode().strip()
        insist(actual == expected and baseline == expected, "locked source changed: " + name)
        receipts[name] = {"git_blob_sha1":actual,"sha256":sha256(data),"bytes":len(data)}

    test_bytes = TEST.read_bytes()
    gpr_bytes = GPR.read_bytes()
    insist(blob_sha(test_bytes) == TEST_BLOB, "v173 test source blob changed")
    insist(blob_sha(gpr_bytes) == GPR_BLOB, "v173 GPR source blob changed")
    test_text = test_bytes.decode("utf-8")
    insist("Calendar_Date" not in test_text, "v173 test references Calendar_Date")
    insist("Normative_Oracle" not in test_text and "Sauce" not in test_text
           and "Ask_Bowl" not in test_text, "v173 test unexpectedly imports full F components")
    for required in (
        "Canonical_Full_Weave_GMP_V164", "Month_Weaving",
        "Full.Build", "Full.Count", "Full.Unrank",
        "Ref.Unrank_Canonical_Weave", "Large_Lengths", "2_846"
    ):
        insist(required in test_text, "required GMP/reference test feature missing: " + required)

    matches = git(
        "grep","-n","-F","Calendar_Date","--","src",
        "tests/issue29_v173_gmp_weave_tests.adb","tests/stage13_weave_tests.adb"
    ).decode().splitlines()
    expected_matches = [
        "src/normative_oracle.adb:1113:   function Calendar_Date",
        "src/normative_oracle.adb:1199:   end Calendar_Date;",
        "src/normative_oracle.ads:68:   function Calendar_Date",
    ]
    insist(matches == expected_matches, "unexpected Calendar_Date call/reference: " + repr(matches))
    gpr = gpr_bytes.decode("utf-8")
    insist('with "gnatcoll_gmp.gpr";' in gpr, "GMP project import missing")
    insist('for Exec_Dir use "bin_v173";' in gpr, "unexpected executable directory")
    insist('issue29_v173_gmp_weave_tests.adb' in gpr, "wrong test main")
    return {
        "locked_sources":receipts,
        "test_blob_sha1":TEST_BLOB,
        "gpr_blob_sha1":GPR_BLOB,
        "calendar_date_reference_audit":{
            "source_references":matches,"test_direct_calls":0,
            "calendar_date_invocations_authorized":0,"full_calendar_F_invocations":0,"soak_years":0,
        },
        "scope":{
            "production_component":"Canonical_Full_Weave_GMP_V164",
            "independent_reference":"Month_Weaving.Unrank_Canonical_Weave",
            "small_family_ranks_compared":6,
            "three_month_family_ranks_compared":210,
            "large_family":"45 months x 94 days; first and last global ranks",
            "expected_assertions":2846,
        },
    }


def verify_all():
    return environment_guard(),source_guard()


def run_bounded(command,stdout_path,stderr_path,wall,cpu,memory,output_limit,file_size_limit=None):
    insist(not stdout_path.exists() and not stderr_path.exists(),"output exists; no retry")
    start=time.monotonic()
    with stdout_path.open("xb") as out,stderr_path.open("xb") as err:
        child=subprocess.Popen(
            command,stdin=subprocess.DEVNULL,stdout=out,stderr=err,
            cwd=str(Path.cwd()),env=dict(os.environ,LC_ALL="C.UTF-8"),
            start_new_session=True,preexec_fn=child_limits(cpu,memory,file_size_limit or output_limit),
            shell=False,
        )
        violation=None
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
        "exit_code":child.returncode,"limit_violation":violation,
        "stdout_bytes":stdout_path.stat().st_size,"stderr_bytes":stderr_path.stat().st_size,
        "stdout_sha256":sha256(stdout_path.read_bytes()),"stderr_sha256":sha256(stderr_path.read_bytes()),
    }


def preflight():
    EVIDENCE.mkdir(exist_ok=True)
    env,source=verify_all()
    insist(Path("/usr/bin/time").is_file(),"GNU time unavailable")
    write_exclusive(EVIDENCE/"preflight.json",json_bytes({
        "schema":SCHEMA,"status":"SOURCE_LOCK_AND_NO_CALENDAR_DATE_AUDIT_PASS",
        "workflow":env,"source_audit":source,
        "native_date_calls_authorized":0,"soak_years":0,
        "main_modified":False,"ada_development_branch_modified":False,
        "limits":{"wall_seconds":WALL_SECONDS,"cpu_seconds":CPU_SECONDS,
                  "address_space_bytes":ADDRESS_SPACE_BYTES,"output_bytes":OUTPUT_LIMIT_BYTES},
    }))
    print("V173_SOURCE_LOCK_AND_NO_CALENDAR_DATE_AUDIT_PASS")


def build():
    EVIDENCE.mkdir(exist_ok=True)
    env,source=verify_all()
    pre=json.loads((EVIDENCE/"preflight.json").read_bytes())
    insist(pre["status"]=="SOURCE_LOCK_AND_NO_CALENDAR_DATE_AUDIT_PASS"
           and pre["workflow"]==env and pre["source_audit"]==source,"stale preflight")
    stdout=EVIDENCE/"gmp-weave.build.stdout"
    stderr=EVIDENCE/"gmp-weave.build.stderr"
    result=run_bounded(
        ["gprbuild","-p","-j2","-P",str(GPR)],
        stdout,stderr,BUILD_WALL_SECONDS,BUILD_CPU_SECONDS,
        BUILD_ADDRESS_SPACE_BYTES,BUILD_OUTPUT_LIMIT_BYTES,BUILD_FILE_SIZE_LIMIT_BYTES
    )
    insist(result["exit_code"]==0 and result["limit_violation"] is None,
           "GMP weave compile/link failed: "+repr(result))
    binary=Path("bin_v173/issue29_v173_gmp_weave_tests")
    insist(binary.is_file() and os.access(binary,os.X_OK),"GMP weave test binary missing")
    write_exclusive(EVIDENCE/"build-manifest.json",json_bytes({
        "schema":SCHEMA,"status":"PRODUCTION_GMP_WEAVE_TEST_LINKED_NOT_EXECUTED",
        "workflow":env,"binary":str(binary),"binary_bytes":binary.stat().st_size,
        "binary_sha256":sha256(binary.read_bytes()),"build_process":result,
        "executed_during_build":False,"calendar_date_invocations":0,
    }))
    print("V173_PRODUCTION_GMP_WEAVE_BUILD_LINK_PASS_NO_EXECUTION")


def run_once():
    EVIDENCE.mkdir(exist_ok=True)
    env,source=verify_all()
    pre=json.loads((EVIDENCE/"preflight.json").read_bytes())
    manifest=json.loads((EVIDENCE/"build-manifest.json").read_bytes())
    insist(pre["status"]=="SOURCE_LOCK_AND_NO_CALENDAR_DATE_AUDIT_PASS"
           and pre["workflow"]==env and pre["source_audit"]==source,"stale preflight")
    insist(manifest["status"]=="PRODUCTION_GMP_WEAVE_TEST_LINKED_NOT_EXECUTED"
           and manifest["workflow"]==env,"stale build manifest")
    insist(not (EVIDENCE/"RUN_STARTED_GMP_WEAVE").exists(),"GMP weave test already attempted")
    binary=Path(manifest["binary"])
    insist(binary.is_file() and sha256(binary.read_bytes())==manifest["binary_sha256"],
           "GMP weave binary changed after build")
    write_exclusive(EVIDENCE/"RUN_STARTED_GMP_WEAVE",json_bytes({
        "schema":SCHEMA,"run_id":env["run_id"],"run_attempt":1,
        "head":env["head"],"binary_sha256":manifest["binary_sha256"],
        "max_invocations":1,"retry_allowed":False,"calendar_date_invocations":0,
    }))
    stdout=EVIDENCE/"gmp-weave.stdout"
    stderr=EVIDENCE/"gmp-weave.stderr"
    timing=EVIDENCE/"gmp-weave.time"
    process=run_bounded(
        ["/usr/bin/time","-f","%e %M %x","-o",str(timing),str(binary.resolve())],
        stdout,stderr,WALL_SECONDS,CPU_SECONDS,ADDRESS_SPACE_BYTES,OUTPUT_LIMIT_BYTES
    )
    output=stdout.read_bytes().decode("utf-8",errors="strict")
    error=stderr.read_bytes()
    insist(process["exit_code"]==0 and process["limit_violation"] is None,
           "GMP weave process failed or exceeded limits: "+repr(process))
    insist(not error,"GMP weave test emitted stderr: "+repr(error[:1000]))
    match=re.search(r"STAGE13_GMP_WEAVE_ASSERTIONS=\s*(\d+)",output)
    insist(match is not None,"GMP weave assertion marker missing")
    assertions=int(match.group(1))
    insist(assertions==2846,"GMP weave assertion count mismatch: "+str(assertions))
    t=timing.read_text(encoding="ascii").strip().split()
    insist(len(t)==3,"GNU time receipt malformed")
    result={
        "schema":SCHEMA,"status":"PASS_PRODUCTION_GMP_FULL_WEAVE_COMPONENT_ONLY",
        "workflow":env,"assertions":assertions,"process":process,
        "gnu_time":{"elapsed_seconds":float(t[0]),"max_rss_kib":int(t[1]),"exit_code":int(t[2])},
        "binary_sha256":manifest["binary_sha256"],
        "calendar_date_invocations":0,"full_calendar_F_invocations":0,
        "original_historical_source_invocations":0,"soak_years":0,
        "production_certified":False,"rerun_or_retry_allowed":False,
        "limits":{"wall_seconds":WALL_SECONDS,"cpu_seconds":CPU_SECONDS,
                  "address_space_bytes":ADDRESS_SPACE_BYTES,"output_bytes":OUTPUT_LIMIT_BYTES},
    }
    write_exclusive(EVIDENCE/"result.json",json_bytes(result))
    print("V173_PRODUCTION_GMP_FULL_WEAVE_2846_ASSERTIONS_PASS_ZERO_F_ZERO_SOAK")


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
