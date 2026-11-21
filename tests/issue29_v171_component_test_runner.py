#!/usr/bin/env python3
"""Bounded, no-retry runner for low-level Ada Stage01/03/05 component tests.

Static guard proves these test units and their compiled source package contain
no Calendar_Date call site. This runner never invokes the full calendar F.
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
V170_PARENT = "8e6a2bcb7782a9e1b276f1c5b6fd9ac0478a9b8a"
BRANCH = "qa/issue29-ada-low-level-stage-tests-v171"
ACTIVATION_MESSAGE = "test(issue29-v171): execute bounded low-level Stage01/03/05 suites once; no Calendar_Date"
GPR = Path("issue29_v171_gmp_aware_component_tests.gpr")
SCHEMA = "ISSUE29_V171_LOW_LEVEL_ADA_COMPONENT_TESTS/1"

SOURCE_BLOBS = {
    "src/normative_oracle.adb": "0be8f8ab4ddef26d34963d5567707a511ebda50b",
    "src/normative_oracle.ads": "c4588566076798dd394feeab580ebc3d38c09744",
    "src/monster_bootstrap.adb": "603f860216979391d5ceae1fc6680a6bdb71a562",
    "src/monster_bootstrap.ads": "ff7ff628e592ab8133e8a120033cf97b9b3c865b",
    "tests/stage01_tests.adb": "a4a5fd120390cf9fb8082e9343b4c1fe16bb1a9d",
    "tests/stage03_patch01_tests.adb": "71286209b4747b0505e926f18d83cc179a569b85",
    "tests/stage05_patch02_tests.adb": "f02abee387f8b0a543499cf70085606f8004c65e",
}
ALLOWED_QA_FILES = {
    ".github/workflows/issue29-v171-low-level-component-tests.yml",
    "issue29_v171_gmp_aware_component_tests.gpr",
    "tests/issue29_v171_component_test_runner.py",
}
TESTS = [
    {
        "name": "stage01",
        "unit": "stage01_tests.adb",
        "binary": Path("bin_v171/stage01_tests"),
        "success_text": "Stage 1 పరీక్షలు అన్నీ విజయవంతమయ్యాయి",
        "assertion_pattern": None,
    },
    {
        "name": "stage03",
        "unit": "stage03_patch01_tests.adb",
        "binary": Path("bin_v171/stage03_patch01_tests"),
        "success_text": "STAGE03_PATCH01_ASSERTIONS=",
        "assertion_pattern": r"STAGE03_PATCH01_ASSERTIONS=\s*(\d+)",
    },
    {
        "name": "stage05",
        "unit": "stage05_patch02_tests.adb",
        "binary": Path("bin_v171/stage05_patch02_tests"),
        "success_text": "STAGE05_PATCH02_ASSERTIONS=",
        "assertion_pattern": r"STAGE05_PATCH02_ASSERTIONS=\s*(\d+)",
        "expected_assertions": 1465,
    },
]
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


def git(*args: str, check: bool = True) -> bytes:
    return subprocess.check_output(["git", *args], stderr=subprocess.DEVNULL) if check else subprocess.run(
        ["git", *args], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, check=False
    ).stdout


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
    insist(os.environ.get("GITHUB_RUN_ATTEMPT") == "1", "rerun attempt refused; no native tests may be repeated")
    insist(os.environ.get("GITHUB_EVENT_NAME") == "push", "only the exact QA push event is allowed")
    insist(os.environ.get("GITHUB_REF") == "refs/heads/" + BRANCH, "wrong branch; execution refused")
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
        ["git", "merge-base", "--is-ancestor", V170_PARENT, head],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False
    )
    insist(ancestry.returncode == 0,
           "v171 branch does not descend from the reviewed v170 gated branch")
    changed = git("diff", "--name-only", V170_PARENT + "...HEAD").decode().splitlines()
    insist(set(changed) == ALLOWED_QA_FILES and len(changed) == len(ALLOWED_QA_FILES),
           "unexpected changed paths in v171 QA branch: " + repr(changed))
    return {
        "run_id": run_id,
        "run_attempt": 1,
        "head": head,
        "branch": BRANCH,
        "event_name": "push",
        "activation_commit_message": ACTIVATION_MESSAGE,
        "v170_parent": V170_PARENT,
        "source_baseline": SOURCE_BASE,
        "changed_paths": changed,
    }


def extract_function(text: str, name: str) -> str:
    start = re.search(r"\bfunction\s+" + re.escape(name) + r"\b", text)
    insist(start is not None, "function not found for static call-path audit: " + name)
    end = re.search(r"\bend\s+" + re.escape(name) + r"\s*;", text[start.end():])
    insist(end is not None, "function end not found: " + name)
    return text[start.start():start.end() + end.end()]


def source_guard() -> dict:
    receipts = {}
    for name, expected in SOURCE_BLOBS.items():
        data = Path(name).read_bytes()
        actual = blob_sha(data)
        baseline = git("rev-parse", SOURCE_BASE + ":" + name).decode().strip()
        insist(actual == expected and baseline == expected, "locked source bytes changed: " + name)
        receipts[name] = {"git_blob_sha1": actual, "sha256": sha256(data), "bytes": len(data)}

    tests_text = {name: Path(name).read_text(encoding="utf-8")
                  for name in ("tests/stage01_tests.adb", "tests/stage03_patch01_tests.adb",
                               "tests/stage05_patch02_tests.adb")}
    for name, text in tests_text.items():
        insist("Calendar_Date" not in text, "test entrypoint directly references Calendar_Date: " + name)

    oracle = Path("src/normative_oracle.adb").read_text(encoding="utf-8")
    spec = Path("src/normative_oracle.ads").read_text(encoding="utf-8")
    bootstrap = Path("src/monster_bootstrap.adb").read_text(encoding="utf-8")
    # The only Calendar_Date occurrences in the source package are its spec
    # declaration and its body definition; there is no call site in src/tests.
    matches = git("grep", "-n", "-F", "Calendar_Date", "--", "src", "tests/stage01_tests.adb", "tests/stage03_patch01_tests.adb", "tests/stage05_patch02_tests.adb").decode().splitlines()
    expected_matches = [
        "src/normative_oracle.adb:1113:    function Calendar_Date",
        "src/normative_oracle.ads:68:   function Calendar_Date",
    ]
    insist(matches == expected_matches, "unexpected Calendar_Date reference/call site: " + repr(matches))
    insist(oracle.count("Calendar_Date") == 1 and spec.count("Calendar_Date") == 1,
           "Calendar_Date source declaration/definition changed")
    insist("Calendar_Date" not in bootstrap, "bootstrap package unexpectedly references Calendar_Date")

    safe_functions = [
        extract_function(oracle, "Day_Count"),
        extract_function(oracle, "Compute_Work_Counts"),
        extract_function(oracle, "Sauce"),
        extract_function(oracle, "Ask_Bowl"),
        extract_function(oracle, "Choose_Rank"),
    ]
    insist(all("Calendar_Date" not in body for body in safe_functions),
           "a component function unexpectedly references Calendar_Date")
    insist("Calendar_Date" not in extract_function(bootstrap, "New_Context"),
           "bootstrap constructor unexpectedly references Calendar_Date")

    # Stage01 has three explicit Sauce call sites; Stage03 has one helper call
    # site invoked twice; Stage05 is Choose_Rank-only.
    sauce_sites = {
        "stage01": len(re.findall(r"\bSauce\s*\(", tests_text["tests/stage01_tests.adb"])),
        "stage03": len(re.findall(r"\bSauce\s*\(", tests_text["tests/stage03_patch01_tests.adb"])),
        "stage05": len(re.findall(r"\bSauce\s*\(", tests_text["tests/stage05_patch02_tests.adb"])),
    }
    insist(sauce_sites == {"stage01": 3, "stage03": 1, "stage05": 0},
           "low-level test Sauce call-site count changed: " + repr(sauce_sites))
    insist("Check_Real_Ask_Bowl" in tests_text["tests/stage03_patch01_tests.adb"],
           "Stage03 real Sauce/Ask_Bowl component check missing")
    insist("1456 comparisons" in tests_text["tests/stage05_patch02_tests.adb"],
           "Stage05 exhaustive mini-model fixture changed")

    gpr = GPR.read_text(encoding="utf-8")
    insist('with "gnatcoll_gmp.gpr";' in gpr, "GMP-aware GPR import missing")
    insist('for Exec_Dir use "bin_v171";' in gpr, "unexpected binary output directory")
    insist('Main_Unit := external ("NATIVE_MAIN"' in gpr, "independent GPR main selector missing")

    return {
        "locked_sources": receipts,
        "calendar_date_reference_audit": {
            "source_references": matches,
            "test_unit_direct_calls": 0,
            "calendar_date_invocations_authorized": 0,
            "full_calendar_F_invocations": 0,
            "soak_years": 0,
        },
        "component_scope": {
            "stage01": "Day_Count/Compute_Work_Counts/Build_Stones/bootstrap/Sauce",
            "stage01_explicit_sauce_call_sites": sauce_sites["stage01"],
            "stage03": "Choose_Rank plus real Sauce->Ask_Bowl->Choose_Rank",
            "stage03_explicit_sauce_call_sites_per_helper_call": sauce_sites["stage03"],
            "stage03_helper_invocations": 2,
            "stage05": "Choose_Rank and exhaustive bounded mini-model",
            "stage05_sauce_call_sites": sauce_sites["stage05"],
            "stage05_expected_assertions": 1465,
        },
    }


def verify_all() -> tuple[dict, dict]:
    return environment_guard(), source_guard()


def run_bounded(command: list[str], stdout_path: Path, stderr_path: Path,
                wall: int, cpu: int, memory: int, output_limit: int,
                file_size_limit: int | None = None) -> dict:
    insist(not stdout_path.exists() and not stderr_path.exists(), "output file already exists; no retry")
    start = time.monotonic()
    child = None
    violation = None
    with stdout_path.open("xb") as out, stderr_path.open("xb") as err:
        child = subprocess.Popen(
            command, stdin=subprocess.DEVNULL, stdout=out, stderr=err,
            cwd=str(Path.cwd()), env=dict(os.environ, LC_ALL="C.UTF-8"),
            start_new_session=True,
            preexec_fn=child_limits(cpu, memory, file_size_limit or output_limit),
            shell=False,
        )
        while True:
            total = stdout_path.stat().st_size + stderr_path.stat().st_size
            if total > output_limit:
                violation = "OUTPUT_LIMIT"
                try:
                    os.killpg(child.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                break
            if time.monotonic() - start > wall:
                violation = "WALL_LIMIT"
                try:
                    os.killpg(child.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                break
            if child.poll() is not None:
                break
            time.sleep(0.05)
        try:
            child.wait(timeout=5)
        except subprocess.TimeoutExpired:
            try:
                os.killpg(child.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            child.wait(timeout=3)
    return {
        "elapsed_seconds": round(time.monotonic() - start, 4),
        "exit_code": child.returncode if child else None,
        "limit_violation": violation,
        "stdout_bytes": stdout_path.stat().st_size,
        "stderr_bytes": stderr_path.stat().st_size,
        "stdout_sha256": sha256(stdout_path.read_bytes()),
        "stderr_sha256": sha256(stderr_path.read_bytes()),
    }


def preflight() -> None:
    EVIDENCE.mkdir(exist_ok=True)
    env, source = verify_all()
    insist(Path("/usr/bin/time").is_file(), "GNU time binary unavailable")
    write_exclusive(EVIDENCE / "preflight.json", json_bytes({
        "schema": SCHEMA,
        "status": "STATIC_COMPONENT_SCOPE_PASS_NO_NATIVE_EXECUTION",
        "workflow": env,
        "source_audit": source,
        "tests_to_build_and_run_once": [x["name"] for x in TESTS],
        "full_calendar_F_invocations": 0,
        "soak_years": 0,
        "main_modified": False,
        "ada_development_branch_modified": False,
        "limits": {
            "test_wall_seconds": WALL_SECONDS,
            "test_cpu_seconds": CPU_SECONDS,
            "test_address_space_bytes": ADDRESS_SPACE_BYTES,
            "test_combined_output_bytes": OUTPUT_LIMIT_BYTES,
        },
    }))
    print("V171_STATIC_NO_CALENDAR_DATE_CALLS_AND_SOURCE_LOCKS_PASS")


def build() -> None:
    EVIDENCE.mkdir(exist_ok=True)
    env, source = verify_all()
    preflight_path = EVIDENCE / "preflight.json"
    pre = json.loads(preflight_path.read_bytes())
    insist(pre["status"] == "STATIC_COMPONENT_SCOPE_PASS_NO_NATIVE_EXECUTION"
           and pre["workflow"] == env and pre["source_audit"] == source,
           "stale or missing preflight receipt")
    entries = []
    for test in TESTS:
        name = test["name"]
        stdout = EVIDENCE / (name + ".build.stdout")
        stderr = EVIDENCE / (name + ".build.stderr")
        command = [
            "gprbuild", "-p", "-j2", "-P", str(GPR),
            "-XNATIVE_MAIN=" + test["unit"],
        ]
        result = run_bounded(command, stdout, stderr, BUILD_WALL_SECONDS,
                             BUILD_CPU_SECONDS, BUILD_ADDRESS_SPACE_BYTES,
                             BUILD_OUTPUT_LIMIT_BYTES, BUILD_FILE_SIZE_LIMIT_BYTES)
        insist(result["exit_code"] == 0 and result["limit_violation"] is None,
               name + " compile/link failed: " + repr(result))
        binary = test["binary"]
        insist(binary.is_file() and os.access(binary, os.X_OK), name + " binary missing")
        entries.append({
            "name": name,
            "unit": test["unit"],
            "binary": str(binary),
            "binary_bytes": binary.stat().st_size,
            "binary_sha256": sha256(binary.read_bytes()),
            "build_process": result,
            "executed_during_build": False,
        })
    write_exclusive(EVIDENCE / "build-manifest.json", json_bytes({
        "schema": SCHEMA,
        "status": "THREE_GMP_AWARE_NATIVE_BINARIES_LINKED_NOT_EXECUTED",
        "workflow": env,
        "entries": entries,
        "native_test_executions": 0,
        "calendar_date_invocations": 0,
    }))
    print("V171_STAGE01_STAGE03_STAGE05_GMP_AWARE_BUILD_LINK_PASS_NO_EXECUTION")


def run_once() -> None:
    EVIDENCE.mkdir(exist_ok=True)
    env, source = verify_all()
    pre = json.loads((EVIDENCE / "preflight.json").read_bytes())
    manifest = json.loads((EVIDENCE / "build-manifest.json").read_bytes())
    insist(pre["status"] == "STATIC_COMPONENT_SCOPE_PASS_NO_NATIVE_EXECUTION"
           and pre["workflow"] == env and pre["source_audit"] == source,
           "stale preflight; execution refused")
    insist(manifest["status"] == "THREE_GMP_AWARE_NATIVE_BINARIES_LINKED_NOT_EXECUTED"
           and manifest["workflow"] == env,
           "stale build manifest; execution refused")
    insist(not any(EVIDENCE.glob("RUN_STARTED_*")), "one or more test executions already attempted")
    expected = {x["name"]: x for x in TESTS}
    built = {x["name"]: x for x in manifest["entries"]}
    insist(set(expected) == set(built), "build manifest test set mismatch")
    results = []
    overall = "FAIL_CLOSED"
    for test in TESTS:
        name = test["name"]
        item = built[name]
        binary = test["binary"]
        insist(binary.is_file() and sha256(binary.read_bytes()) == item["binary_sha256"],
               name + " binary changed after build")
        marker = {
            "schema": SCHEMA,
            "run_id": env["run_id"],
            "run_attempt": 1,
            "head": env["head"],
            "test": name,
            "binary_sha256": item["binary_sha256"],
            "max_invocations": 1,
            "retry_allowed": False,
            "calendar_date_invocations": 0,
        }
        write_exclusive(EVIDENCE / ("RUN_STARTED_" + name.upper()), json_bytes(marker))
        stdout = EVIDENCE / (name + ".stdout")
        stderr = EVIDENCE / (name + ".stderr")
        timing = EVIDENCE / (name + ".time")
        command = ["/usr/bin/time", "-f", "%e %M %x", "-o", str(timing), str(binary.resolve())]
        process = run_bounded(command, stdout, stderr, WALL_SECONDS, CPU_SECONDS,
                              ADDRESS_SPACE_BYTES, OUTPUT_LIMIT_BYTES)
        output = stdout.read_bytes().decode("utf-8", errors="strict")
        error = stderr.read_bytes()
        insist(process["exit_code"] == 0 and process["limit_violation"] is None,
               name + " process failed or exceeded a resource limit: " + repr(process))
        insist(not error, name + " emitted stderr: " + repr(error[:1000]))
        insist(test["success_text"] in output, name + " success marker missing")
        assertions = None
        if test["assertion_pattern"]:
            match = re.search(test["assertion_pattern"], output)
            insist(match is not None, name + " assertion-count marker missing")
            assertions = int(match.group(1))
            insist(assertions > 0, name + " reported zero assertions")
            if "expected_assertions" in test:
                insist(assertions == test["expected_assertions"],
                       name + " assertion count mismatch: " + str(assertions))
        time_fields = timing.read_text(encoding="ascii").strip().split()
        insist(len(time_fields) == 3, name + " GNU time receipt malformed")
        results.append({
            "name": name,
            "status": "PASS",
            "assertions_reported": assertions,
            "process": process,
            "gnu_time": {
                "elapsed_seconds": float(time_fields[0]),
                "max_rss_kib": int(time_fields[1]),
                "exit_code": int(time_fields[2]),
            },
            "binary_sha256": item["binary_sha256"],
        })
    overall = "PASS_STAGE01_STAGE03_STAGE05_LOW_LEVEL_COMPONENTS_ONLY"
    receipt = {
        "schema": SCHEMA,
        "status": overall,
        "workflow": env,
        "results": results,
        "calendar_date_invocations": 0,
        "full_calendar_F_invocations": 0,
        "original_historical_source_invocations": 0,
        "soak_years": 0,
        "production_certified": False,
        "rerun_or_retry_allowed": False,
        "limits": {
            "wall_seconds_per_test": WALL_SECONDS,
            "cpu_seconds_per_test": CPU_SECONDS,
            "address_space_bytes_per_test": ADDRESS_SPACE_BYTES,
            "combined_output_bytes_per_test": OUTPUT_LIMIT_BYTES,
        },
    }
    write_exclusive(EVIDENCE / "result.json", json_bytes(receipt))
    print("V171_STAGE01_STAGE03_STAGE05_PASS_ZERO_CALENDAR_DATE_ZERO_SOAK")


def main() -> int:
    if len(sys.argv) != 2 or sys.argv[1] not in {"preflight", "build", "run-once"}:
        raise SystemExit("usage: runner.py {preflight|build|run-once}")
    mode = sys.argv[1]
    if mode == "preflight":
        preflight()
    elif mode == "build":
        build()
    else:
        run_once()
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        EVIDENCE.mkdir(exist_ok=True)
        failure = {
            "schema": SCHEMA,
            "status": "FAIL_CLOSED",
            "failure": repr(exc),
            "calendar_date_invocations": 0,
            "soak_years": 0,
            "automatic_retry_allowed": False,
        }
        target = EVIDENCE / "failure.json"
        if not target.exists():
            write_exclusive(target, json_bytes(failure))
        raise
