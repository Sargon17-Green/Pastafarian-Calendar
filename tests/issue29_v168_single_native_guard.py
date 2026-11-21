#!/usr/bin/env python3
"""Issue #29 v168: exactly ONE bounded date call from UNMODIFIED corrected Ada branch source.

Source baseline e17ab44... from Ada+Telugu, branch qa/issue29-ada-native-foundation-v168.
This is not a full-year Soak, not a Stage41 observer, and not release certification.

The runner has two explicit modes.  Preflight *does not* execute calendar code.
Run-once creates an exclusive marker BEFORE Popen and will never retry.
Original historical source a2fb... is never invoked.
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

BASE = "e17ab44aa3fd1d08eb14644164735a7c5c87721d"
MAIN = "56bc4173aae4975ded019ef5ab5a36249f1424df"
README_BLOB = "74c424b44eadd4ece3f29072ddbf873236557604"
BRANCH = "qa/issue29-ada-native-foundation-v168"
EXPECTED = [5000, 10, 503, 20, 56]
HISTORICAL_ADA = [5000, 10, 503, 30, 52]
WALL_LIMIT_SECONDS = 90
CPU_LIMIT_SECONDS = 90
ADDRESS_SPACE_LIMIT_BYTES = 768 * 1024 * 1024
COMBINED_OUTPUT_BYTES = 128 * 1024
SOURCE_BLOBS = {
    "src/normative_oracle.adb": "0be8f8ab4ddef26d34963d5567707a511ebda50b",
    "src/normative_oracle.ads": "c4588566076798dd394feeab580ebc3d38c09744",
    "src/canonical_full_weave_gmp_v164.ads": "0b68edf7eddbc33869358bcfcc21e32465fc591e",
    "src/canonical_full_weave_gmp_v164.adb": "845bd8905943a54e63d6aba0334404a5051fe666",
    "src/canonical_wide_rank_gmp_v164.ads": "14b94e81534e98cfdb07be3824076bd7082385ea",
    "src/canonical_wide_rank_gmp_v164.adb": "52b8814c2ab1924cdebafe893a65d97cd3ccfa61",
    "pastafari_calendar.gpr": "eb8ac4b64f8f1fddb22087a51c5f4ccd508684d7",
}
PROBE = Path("tests/issue29_v168_native_foundation_probe.adb")
PROJECT = Path("issue29_v168_native_foundation.gpr")
BINARY = Path("bin_v168/issue29_v168_native_foundation_probe")
SCHEMA = "ISSUE29_V168_NATIVE_ADA_DEVELOPMENT_BRANCH_FOUNDATION/1"


def insist(test: bool, message: str) -> None:
    if not test:
        raise ValueError(message)


def git(*args: str) -> bytes:
    return subprocess.check_output(["git", *args], stderr=subprocess.DEVNULL)


def blob_sha(data: bytes) -> str:
    header = b"blob " + str(len(data)).encode("ascii") + b"\0"
    return hashlib.sha1(header + data).hexdigest()


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha_file(path: Path) -> str:
    return digest(path.read_bytes())


def exact_json_bytes(payload: dict) -> bytes:
    return (json.dumps(payload, ensure_ascii=False, sort_keys=True,
                       separators=(",", ":"), allow_nan=False) + "\n").encode("utf-8")


def write_exclusive(path: Path, content: bytes) -> None:
    with path.open("xb") as stream:
        stream.write(content)
        stream.flush()
        os.fsync(stream.fileno())


def environment_guard() -> dict:
    insist(os.environ.get("GITHUB_RUN_ATTEMPT") == "1",
           "a rerun may not invoke the original-development-branch native F")
    insist(os.environ.get("GITHUB_REF") == "refs/heads/" + BRANCH,
           "wrong branch: no execution permitted")
    insist(os.environ.get("GITHUB_EVENT_NAME") == "push",
           "no manual/PR native F trigger permitted")
    run_id = os.environ.get("GITHUB_RUN_ID", "")
    insist(run_id.isdigit() and int(run_id) > 0, "missing GitHub run identity")
    head = git("rev-parse", "HEAD").decode().strip()
    insist(os.environ.get("GITHUB_SHA") == head, "workflow HEAD drift")
    result = subprocess.run(["git", "merge-base", "--is-ancestor", BASE, head],
                            check=False, stdout=subprocess.DEVNULL,
                            stderr=subprocess.DEVNULL)
    insist(result.returncode == 0, "branch not based on expected Ada development HEAD")
    return {
        "run_id": run_id, "run_attempt": 1,
        "head": head, "base_original_development_branch": BASE,
        "branch": BRANCH, "event_name": "push"
    }


def source_guard() -> dict:
    receipts = {}
    for name, expected in SOURCE_BLOBS.items():
        path = Path(name)
        insist(path.is_file(), "required source file missing: " + name)
        data = path.read_bytes()
        actual = blob_sha(data)
        baseline = git("rev-parse", BASE + ":" + name).decode().strip()
        insist(actual == expected and baseline == expected,
               "development source bytes changed or did not match baseline: " + name)
        receipts[name] = {
            "git_blob_sha1": actual, "sha256": digest(data),
            "bytes": len(data),
        }
    readme = git("show", MAIN + ":README.md")
    insist(blob_sha(readme) == README_BLOB,
           "canonical main README SHA-1 mismatch")
    insist(b"| 1 | -15,055,671 | -15,055,671 | 5000 | 10 | 503 | 20 | 56 |"
           in readme, "canonical foundation contract row missing")
    insist(Path(".github/workflows/ada-issue29-spaghetti-compile-only.yml").is_file(),
           "baseline Ada corrected branch compile-only evidence missing")
    probe = PROBE.read_bytes()
    insist(probe.count(b"Calendar_Date (Foundation_Day, Foundation_Day)") == 1
           and probe.count(b"Calendar_Date (") == 1,
           "probe MUST call Calendar_Date exactly once at foundation day")
    insist(b"ISSUE29_V168_NATIVE_FOUNDATION|" in probe,
           "probe output prefix drift")
    return {
        "locked_original_development_sources": receipts,
        "canonical_readme_commit": MAIN,
        "canonical_readme_git_blob_sha1": README_BLOB,
        "probe_git_blob_sha1": blob_sha(probe),
        "probe_sha256": digest(probe),
    }


def verify_all() -> tuple[dict, dict]:
    return environment_guard(), source_guard()


def preflight(root: Path) -> None:
    insist(root.is_dir(), "existing evidence directory required")
    env, sources = verify_all()
    insist(BINARY.is_file() and os.access(BINARY, os.X_OK),
           "built native binary missing")
    compiled = {
        "schema": SCHEMA,
        "mode": "CORRECTED_ADA_DEVELOPMENT_SOURCE_BYTES_UNMODIFIED_NOT_HISTORICAL",
        "status": "PREFLIGHT_ONLY_NO_F",
        "native_binary": str(BINARY),
        "binary_sha256": sha_file(BINARY),
        "binary_bytes": BINARY.stat().st_size,
        "workflow": env,
        "sources": sources,
        "expected_canonical": EXPECTED,
        "historical_original_mismatch": HISTORICAL_ADA,
        "original_historical_source_executed": False,
        "source_branch_native_executed": False,
        "soak_years": 0,
        "soak_dispatch_allowed": False,
        "main_modified": False,
        "limits": {
            "wall_seconds": WALL_LIMIT_SECONDS,
            "cpu_seconds": CPU_LIMIT_SECONDS,
            "address_space_bytes": ADDRESS_SPACE_LIMIT_BYTES,
            "combined_output_bytes": COMBINED_OUTPUT_BYTES,
        }
    }
    write_exclusive(root / "preflight.json", exact_json_bytes(compiled))
    print("ISSUE29_V168_SOURCE_PINNED_COMPILED_PRECHECK_NO_F")


def _child_caps() -> None:
    resource.setrlimit(resource.RLIMIT_CPU, (CPU_LIMIT_SECONDS, CPU_LIMIT_SECONDS))
    resource.setrlimit(resource.RLIMIT_AS,
                       (ADDRESS_SPACE_LIMIT_BYTES, ADDRESS_SPACE_LIMIT_BYTES))
    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))


def _kill_group(child: subprocess.Popen) -> None:
    try:
        os.killpg(child.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass


def run_once(root: Path) -> None:
    insist(root.is_dir(), "existing evidence directory required")
    env, sources = verify_all()
    preflight_path = root / "preflight.json"
    record = json.loads(preflight_path.read_bytes())
    insist(record["schema"] == SCHEMA
           and record["status"] == "PREFLIGHT_ONLY_NO_F"
           and record["workflow"] == env
           and record["sources"] == sources
           and record["native_binary"] == str(BINARY)
           and record["binary_sha256"] == sha_file(BINARY)
           and record["expected_canonical"] == EXPECTED
           and record["soak_dispatch_allowed"] is False,
           "stale/forged preflight: original-development date call refused")
    insist(not (root / "RUN_STARTED_ONCE").exists(),
           "date call has already been attempted")
    marker = {
        "schema": SCHEMA,
        "run_id": env["run_id"],
        "branch_source_commit": BASE,
        "workflow_head": env["head"],
        "binary_sha256": record["binary_sha256"],
        "date_call": [-15055671, -15055671],
        "max_calls": 1,
        "retry_allowed": False,
    }
    # Exclusive marker is fsynced *before* entering subprocess.Popen.
    write_exclusive(root / "RUN_STARTED_ONCE", exact_json_bytes(marker))
    outcome = {
        "schema": SCHEMA,
        "status": "FAIL_CLOSED",
        "mode": "CORRECTED_ADA_DEVELOPMENT_BRANCH_SOURCE_NOT_HISTORICAL",
        "workflow": env,
        "native_binary": str(BINARY),
        "binary_sha256": record["binary_sha256"],
        "reference_result": EXPECTED,
        "historical_original_mismatch": HISTORICAL_ADA,
        "observed_result": None,
        "date_call_attempts": 1,
        "rerun_or_retry_allowed": False,
        "original_historical_source_calls": 0,
        "soak_years": 0,
        "soak_dispatch_allowed": False,
        "production_certified": False,
        "process": {
            "elapsed_seconds": None, "exit_code": None,
            "peak_rss_kib": None,
            "limit_violation": None,
            "stdout_sha256": None,
            "stderr_sha256": None,
        },
    }
    outpath = root / "native-foundation.stdout"
    errpath = root / "native-foundation.stderr"
    child = None
    violation = None
    start = time.monotonic()
    try:
        with outpath.open("xb") as stdout, errpath.open("xb") as stderr:
            child = subprocess.Popen([str(BINARY.resolve())],
                                     cwd=str(Path.cwd()), stdin=subprocess.DEVNULL,
                                     stdout=stdout, stderr=stderr,
                                     start_new_session=True,
                                     preexec_fn=_child_caps,
                                     shell=False)
            while True:
                status = child.poll()
                total_size = outpath.stat().st_size + errpath.stat().st_size
                if total_size > COMBINED_OUTPUT_BYTES:
                    violation = "OUTPUT_LIMIT"
                    _kill_group(child)
                    break
                if time.monotonic() - start > WALL_LIMIT_SECONDS:
                    violation = "WALL_LIMIT"
                    _kill_group(child)
                    break
                if status is not None:
                    break
                time.sleep(0.05)
            child.wait(timeout=5)
        elapsed = time.monotonic() - start
        output = outpath.read_bytes()
        err = errpath.read_bytes()
        outcome["process"] = {
            "elapsed_seconds": round(elapsed, 4),
            "exit_code": child.returncode,
            "peak_rss_kib": resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss,
            "limit_violation": violation,
            "stdout_bytes": len(output),
            "stderr_bytes": len(err),
            "stdout_sha256": digest(output),
            "stderr_sha256": digest(err),
        }
        insist(child.returncode == 0 and violation is None and len(err) == 0,
               "native child failed, exceeded cap, or emitted stderr")
        lines = output.decode("utf-8", errors="strict").splitlines()
        insist(len(lines) == 1, "exactly one date-result line required")
        cells = lines[0].split("|")
        insist(len(cells) == 6
               and cells[0] == "ISSUE29_V168_NATIVE_FOUNDATION",
               "native date-result prefix/field count invalid")
        insist(all(re.fullmatch(r"\s*-?[0-9]+\s*", c) for c in cells[1:]),
               "nondecimal native result field")
        values = [int(v.strip()) for v in cells[1:]]
        outcome["observed_result"] = values
        insist(values == EXPECTED, "source-branch native mismatch vs canonical")
        insist(values != HISTORICAL_ADA, "source-branch still equals old faulty Ada")
        outcome["status"] = "PASS_SINGLE_CORRECTED_NATIVE_FOUNDATION_ONLY"
    except BaseException as failure:
        outcome["failure"] = str(failure)
        if child is not None and child.poll() is None:
            _kill_group(child)
            try:
                child.wait(timeout=3)
            except subprocess.TimeoutExpired:
                pass
    finally:
        if outpath.exists():
            outcome["process"]["stdout_sha256"] = sha_file(outpath)
            outcome["process"]["stdout_bytes"] = outpath.stat().st_size
        if errpath.exists():
            outcome["process"]["stderr_sha256"] = sha_file(errpath)
            outcome["process"]["stderr_bytes"] = errpath.stat().st_size
        write_exclusive(root / "result.json", exact_json_bytes(outcome))
    insist(outcome["status"] == "PASS_SINGLE_CORRECTED_NATIVE_FOUNDATION_ONLY",
           "single source-branch native date FAIL, no automatic retry")
    print("ISSUE29_V168_CORRECTED_ADA_NATIVE_FOUNDATION_FIVE_FIELDS_PASS")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("preflight", "run-once"))
    parser.add_argument("--evidence", type=Path, required=True)
    args = parser.parse_args()
    if args.mode == "preflight":
        preflight(args.evidence)
    else:
        run_once(args.evidence)
    return 0


if __name__ == "__main__":
    sys.exit(main())
