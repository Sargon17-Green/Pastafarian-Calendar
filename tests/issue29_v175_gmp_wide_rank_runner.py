#!/usr/bin/env python3
"""One-shot direct GMP wide-rank / full-weave composition test; no calendar F."""
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

BASE_COMMIT = "1160096aa847c54cbef27c232771ce1549d7ba8f"
SOURCE_BASE = "e17ab44aa3fd1d08eb14644164735a7c5c87721d"
BRANCH = "qa/issue29-ada-gmp-wide-rank-v175"
ACTIVATION_MESSAGE = (
    "fix(issue29-v175): initialize limited GMP values through Set"
)
GPR = Path("issue29_v175_gmp_wide_rank.gpr")
TEST = Path("tests/issue29_v175_gmp_wide_rank_tests.adb")
GPR_BLOB = "ccd133d596bc625dfe2086d87450106bf83e26f2"
TEST_BLOB = "d6b70c30fdd7e780d6643a512b938921385b74fd"
SCHEMA = "ISSUE29_V175_GMP_WIDE_RANK_179_PLACE_COMPOSITION/1"
SOURCE_BLOBS = {
    "src/normative_oracle.adb": "0be8f8ab4ddef26d34963d5567707a511ebda50b",
    "src/normative_oracle.ads": "c4588566076798dd394feeab580ebc3d38c09744",
    "src/canonical_full_weave_gmp_v164.adb": "845bd8905943a54e63d6aba0334404a5051fe666",
    "src/canonical_full_weave_gmp_v164.ads": "0b68edf7eddbc33869358bcfcc21e32465fc591e",
    "src/canonical_wide_rank_gmp_v164.adb": "52b8814c2ab1924cdebafe893a65d97cd3ccfa61",
    "src/canonical_wide_rank_gmp_v164.ads": "14b94e81534e98cfdb07be3824076bd7082385ea",
}
ALLOWED_QA_FILES = {
    ".github/workflows/issue29-v175-gmp-wide-rank.yml",
    "issue29_v175_gmp_wide_rank.gpr",
    "tests/issue29_v175_gmp_wide_rank_tests.adb",
    "tests/issue29_v175_gmp_wide_rank_runner.py",
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
EXPECTED_ASSERTIONS = 31
EXPECTED_PLACES = 179
EXPECTED_CASES = 6


def insist(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def git(*args: str) -> bytes:
    return subprocess.check_output(["git", *args], stderr=subprocess.DEVNULL)


def blob_sha(data: bytes) -> str:
    return hashlib.sha1(
        b"blob " + str(len(data)).encode("ascii") + b"\0" + data
    ).hexdigest()


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def json_bytes(data: dict) -> bytes:
    return (
        json.dumps(data, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
        + "\n"
    ).encode("utf-8")


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
    insist(
        event.get("head_commit", {}).get("message") == ACTIVATION_MESSAGE,
        "not the exact one-time activation commit",
    )
    run_id = os.environ.get("GITHUB_RUN_ID", "")
    insist(run_id.isdigit() and int(run_id) > 0, "GitHub run identity missing")
    head = git("rev-parse", "HEAD").decode().strip()
    insist(os.environ.get("GITHUB_SHA") == head, "workflow HEAD drift")
    subprocess.run(
        ["git", "merge-base", "--is-ancestor", BASE_COMMIT, head],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=True,
    )
    changed = git("diff", "--name-only", BASE_COMMIT + "...HEAD").decode().splitlines()
    insist(
        set(changed) == ALLOWED_QA_FILES and len(changed) == len(ALLOWED_QA_FILES),
        "unexpected v175 changed paths: " + repr(changed),
    )
    return {
        "run_id": run_id,
        "run_attempt": 1,
        "head": head,
        "branch": BRANCH,
        "event_name": "push",
        "activation_commit_message": ACTIVATION_MESSAGE,
        "base_commit": BASE_COMMIT,
        "source_baseline": SOURCE_BASE,
        "changed_paths": changed,
    }


def source_guard() -> dict:
    receipts = {}
    for name, expected in SOURCE_BLOBS.items():
        data = Path(name).read_bytes()
        actual = blob_sha(data)
        baseline = git("rev-parse", SOURCE_BASE + ":" + name).decode().strip()
        insist(actual == expected and baseline == expected, "locked source changed: " + name)
        receipts[name] = {
            "git_blob_sha1": actual,
            "sha256": sha256(data),
            "bytes": len(data),
        }

    test_text = TEST.read_text(encoding="utf-8")
    gpr_text = GPR.read_text(encoding="utf-8")
    insist(blob_sha(TEST.read_bytes()) == TEST_BLOB, "v175 test source blob changed")
    insist(blob_sha(GPR.read_bytes()) == GPR_BLOB, "v175 GPR source blob changed")
    insist("Calendar_Date" not in test_text, "v175 test references Calendar_Date")
    insist("Normative_Oracle" not in test_text, "v175 test imports calendar oracle")
    insist("Month_Weaving" not in test_text, "v175 test imports legacy weave reference")
    for required in (
        "Canonical_Full_Weave_GMP_V164",
        "Canonical_Wide_Rank_GMP_V164",
        "Full.Build",
        "Full.Count",
        "Wide.Choose_Rank",
        "Full.Unrank",
        "Places = 179",
        "Assertions /= 31",
    ):
        insist(required in test_text, "required v175 test feature missing: " + required)
    insist('with "gnatcoll_gmp.gpr";' in gpr_text, "GMP project import missing")
    insist('for Exec_Dir use "bin_v175";' in gpr_text, "unexpected executable directory")

    matches = git(
        "grep", "-n", "-F", "Calendar_Date", "--",
        "src", "tests/issue29_v175_gmp_wide_rank_tests.adb",
    ).decode().splitlines()
    expected_matches = [
        "src/normative_oracle.adb:1113:   function Calendar_Date",
        "src/normative_oracle.adb:1199:   end Calendar_Date;",
        "src/normative_oracle.ads:68:   function Calendar_Date",
    ]
    insist(matches == expected_matches, "unexpected Calendar_Date call/reference: " + repr(matches))

    lock = Path(".github/workflows/canonical-names-lock.yml").read_text()
    insist(lock.count("    if: " + "$" + "{{ false }}") == 42,
           "all 42 legacy native auto-dispatch jobs must remain hard-disabled")
    insist(lock.count("  verify:\n") == 1, "canonical names verifier missing/duplicated")
    return {
        "locked_sources": receipts,
        "test_blob_sha1": TEST_BLOB,
        "gpr_blob_sha1": GPR_BLOB,
        "calendar_date_reference_audit": {
            "source_references": matches,
            "test_direct_calls": 0,
            "calendar_date_invocations": 0,
            "full_calendar_F_invocations": 0,
            "soak_years": 0,
        },
        "safety_gate": {
            "all_42_legacy_native_jobs_hard_disabled": True,
            "canonical_names_verifier_preserved": True,
        },
    }


def run_bounded(
    command: list[str],
    stdout_path: Path,
    stderr_path: Path,
    wall: int,
    cpu: int,
    memory: int,
    output_limit: int,
    file_size_limit: int | None = None,
) -> dict:
    insist(not stdout_path.exists() and not stderr_path.exists(), "output exists; no retry")
    start = time.monotonic()
    with stdout_path.open("xb") as out, stderr_path.open("xb") as err:
        child = subprocess.Popen(
            command,
            stdin=subprocess.DEVNULL,
            stdout=out,
            stderr=err,
            cwd=str(Path.cwd()),
            env=dict(os.environ, LC_ALL="C.UTF-8"),
            shell=False,
            start_new_session=True,
            preexec_fn=child_limits(cpu, memory, file_size_limit or output_limit),
        )
        violation = None
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
        "exit_code": child.returncode,
        "limit_violation": violation,
        "stdout_bytes": stdout_path.stat().st_size,
        "stderr_bytes": stderr_path.stat().st_size,
        "stdout_sha256": sha256(stdout_path.read_bytes()),
        "stderr_sha256": sha256(stderr_path.read_bytes()),
    }


def preflight() -> None:
    EVIDENCE.mkdir(exist_ok=True)
    env = environment_guard()
    source = source_guard()
    write_exclusive(
        EVIDENCE / "preflight.json",
        json_bytes(
            {
                "schema": SCHEMA,
                "status": "SOURCE_LOCK_AND_179_PLACE_TEST_GATES_PASS",
                "workflow": env,
                "source_audit": source,
                "test_family": {
                    "months": 45,
                    "days_per_month": 94,
                    "total_days": 4230,
                    "expected_radix_M_places": EXPECTED_PLACES,
                    "synthetic_stream_cases": EXPECTED_CASES,
                    "streams": [
                        {"first": "1", "step": -1, "expected_rejection": True},
                        {"first": "1", "step": 1, "expected_rejection": False},
                        {"first": "M", "step": -1, "expected_rejection": True},
                        {"first": "M", "step": 1, "expected_rejection": False},
                        {"first": "floor(M/2)", "step": -1, "expected_rejection": False},
                        {"first": "floor(M/2)", "step": 1, "expected_rejection": False},
                    ],
                },
                "calendar_date_invocations": 0,
                "full_calendar_F_invocations": 0,
                "soak_years": 0,
                "limits": {
                    "wall_seconds": WALL_SECONDS,
                    "cpu_seconds": CPU_SECONDS,
                    "address_space_bytes": ADDRESS_SPACE_BYTES,
                    "output_bytes": OUTPUT_LIMIT_BYTES,
                },
            }
        ),
    )
    print("V175_SOURCE_LOCK_AND_179_PLACE_TEST_GATES_PASS")


def read_preflight(env: dict, source: dict) -> dict:
    pre = json.loads((EVIDENCE / "preflight.json").read_bytes())
    insist(
        pre["status"] == "SOURCE_LOCK_AND_179_PLACE_TEST_GATES_PASS"
        and pre["workflow"] == env
        and pre["source_audit"] == source,
        "stale or mismatched preflight",
    )
    return pre


def build() -> None:
    EVIDENCE.mkdir(exist_ok=True)
    env = environment_guard()
    source = source_guard()
    read_preflight(env, source)
    process = run_bounded(
        ["gprbuild", "-p", "-j2", "-P", str(GPR)],
        EVIDENCE / "gmp-wide-rank.build.stdout",
        EVIDENCE / "gmp-wide-rank.build.stderr",
        BUILD_WALL_SECONDS,
        BUILD_CPU_SECONDS,
        BUILD_ADDRESS_SPACE_BYTES,
        BUILD_OUTPUT_LIMIT_BYTES,
        BUILD_FILE_SIZE_LIMIT_BYTES,
    )
    insist(process["exit_code"] == 0 and process["limit_violation"] is None,
           "GMP wide-rank compile/link failed: " + repr(process))
    binary = Path("bin_v175/issue29_v175_gmp_wide_rank_tests")
    insist(binary.is_file() and os.access(binary, os.X_OK), "v175 test binary missing")
    write_exclusive(
        EVIDENCE / "build-manifest.json",
        json_bytes(
            {
                "schema": SCHEMA,
                "status": "PRODUCTION_GMP_WIDE_RANK_TEST_LINKED_NOT_EXECUTED",
                "workflow": env,
                "binary": str(binary),
                "binary_bytes": binary.stat().st_size,
                "binary_sha256": sha256(binary.read_bytes()),
                "build_process": process,
                "executed_during_build": False,
                "calendar_date_invocations": 0,
            }
        ),
    )
    print("V175_PRODUCTION_GMP_WIDE_RANK_BUILD_LINK_PASS_NO_EXECUTION")


def run_once() -> None:
    EVIDENCE.mkdir(exist_ok=True)
    env = environment_guard()
    source = source_guard()
    read_preflight(env, source)
    manifest = json.loads((EVIDENCE / "build-manifest.json").read_bytes())
    insist(
        manifest["status"] == "PRODUCTION_GMP_WIDE_RANK_TEST_LINKED_NOT_EXECUTED"
        and manifest["workflow"] == env,
        "stale build manifest",
    )
    insist(not (EVIDENCE / "RUN_STARTED_WIDE_RANK").exists(),
           "wide-rank test already attempted; no retry")
    binary = Path(manifest["binary"])
    insist(binary.is_file() and sha256(binary.read_bytes()) == manifest["binary_sha256"],
           "wide-rank test binary changed after build")
    write_exclusive(
        EVIDENCE / "RUN_STARTED_WIDE_RANK",
        json_bytes(
            {
                "schema": SCHEMA,
                "run_id": env["run_id"],
                "run_attempt": 1,
                "head": env["head"],
                "binary_sha256": manifest["binary_sha256"],
                "max_invocations": 1,
                "retry_allowed": False,
                "calendar_date_invocations": 0,
            }
        ),
    )
    stdout = EVIDENCE / "gmp-wide-rank.stdout"
    stderr = EVIDENCE / "gmp-wide-rank.stderr"
    timing = EVIDENCE / "gmp-wide-rank.time"
    process = run_bounded(
        ["/usr/bin/time", "-f", "%e %M %x", "-o", str(timing), str(binary.resolve())],
        stdout, stderr, WALL_SECONDS, CPU_SECONDS, ADDRESS_SPACE_BYTES, OUTPUT_LIMIT_BYTES,
    )
    output = stdout.read_bytes().decode("utf-8", errors="strict")
    error = stderr.read_bytes()
    insist(process["exit_code"] == 0 and process["limit_violation"] is None,
           "GMP wide-rank process failed or exceeded limits: " + repr(process))
    insist(not error, "GMP wide-rank test emitted stderr: " + repr(error[:1000]))
    assertions = re.search(r"ISSUE29_V175_GMP_WIDE_RANK_ASSERTIONS=\s*(\d+)", output)
    places = re.search(r"ISSUE29_V175_GMP_WIDE_RANK_PLACES=\s*(\d+)", output)
    cases = re.search(r"ISSUE29_V175_GMP_WIDE_RANK_CASES=\s*(\d+)", output)
    insist(assertions and int(assertions.group(1)) == EXPECTED_ASSERTIONS,
           "v175 assertion marker/count mismatch")
    insist(places and int(places.group(1)) == EXPECTED_PLACES,
           "v175 places marker/count mismatch")
    insist(cases and int(cases.group(1)) == EXPECTED_CASES,
           "v175 case marker/count mismatch")
    timing_fields = timing.read_text(encoding="ascii").strip().split()
    insist(len(timing_fields) == 3, "GNU time receipt malformed")
    result = {
        "schema": SCHEMA,
        "status": "PASS_PRODUCTION_179_PLACE_GMP_WIDE_RANK_AND_UNRANK_COMPOSITION",
        "workflow": env,
        "assertions": int(assertions.group(1)),
        "radix_M_places": int(places.group(1)),
        "synthetic_stream_cases": int(cases.group(1)),
        "process": process,
        "gnu_time": {
            "elapsed_seconds": float(timing_fields[0]),
            "max_rss_kib": int(timing_fields[1]),
            "exit_code": int(timing_fields[2]),
        },
        "binary_sha256": manifest["binary_sha256"],
        "calendar_date_invocations": 0,
        "full_calendar_F_invocations": 0,
        "original_historical_source_invocations": 0,
        "soak_years": 0,
        "production_certified": False,
        "rerun_or_retry_allowed": False,
        "limits": {
            "wall_seconds": WALL_SECONDS,
            "cpu_seconds": CPU_SECONDS,
            "address_space_bytes": ADDRESS_SPACE_BYTES,
            "output_bytes": OUTPUT_LIMIT_BYTES,
        },
    }
    write_exclusive(EVIDENCE / "result.json", json_bytes(result))
    print("V175_PRODUCTION_179_PLACE_GMP_WIDE_RANK_AND_UNRANK_PASS_ZERO_F_ZERO_SOAK")


def main() -> int:
    if len(sys.argv) != 2 or sys.argv[1] not in {"preflight", "build", "run-once"}:
        raise SystemExit("usage: runner.py {preflight|build|run-once}")
    if sys.argv[1] == "preflight":
        preflight()
    elif sys.argv[1] == "build":
        build()
    else:
        run_once()
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        EVIDENCE.mkdir(exist_ok=True)
        target = EVIDENCE / "failure.json"
        if not target.exists():
            write_exclusive(
                target,
                json_bytes(
                    {
                        "schema": SCHEMA,
                        "status": "FAIL_CLOSED",
                        "failure": repr(exc),
                        "calendar_date_invocations": 0,
                        "soak_years": 0,
                        "automatic_retry_allowed": False,
                    }
                ),
            )
        raise
