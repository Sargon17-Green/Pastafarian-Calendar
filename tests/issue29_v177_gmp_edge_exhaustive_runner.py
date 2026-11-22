#!/usr/bin/env python3
"""Issue29 v177: deterministic exhaustive *independent* GMP edge-family witness.

The reference recursively visits every multiset permutation and filters by
only the normative two first/last occurrence rules at COMPLETE leaves.
It never imports production GMP code, month-weaving logic or calendar F(c,t).
The bounded Ada fixture compiles and calls ONLY Canonical_Full_Weave_GMP_V164.
"""
from __future__ import annotations

import hashlib
import json
import math
import os
from pathlib import Path
import re
import resource
import signal
import subprocess
import sys
import time

BRANCH = "qa/issue29-ada-gmp-edge-exhaustive-v177"
BASE = "1160096aa847c54cbef27c232771ce1549d7ba8f"
SOURCE_BASE = "e17ab44aa3fd1d08eb14644164735a7c5c87721d"
MAIN = "56bc4173aae4975ded019ef5ab5a36249f1424df"
MAIN_README_BLOB = "74c424b44eadd4ece3f29072ddbf873236557604"
ACTIVATION = "ci(issue29-v177): execute one source-locked exhaustive GMP edge fixture, zero calendar F"
TEST = Path("tests/issue29_v177_gmp_edge_exhaustive_tests.adb")
GPR = Path("issue29_v177_gmp_edge_exhaustive.gpr")
TEST_BLOB = "ef616a53f5d06a13f7e111ab97f60e63cfbd9ad6"
GPR_BLOB = "869e77830f95da37344d2161cbb2853142818084"
SOURCES = {
    "src/canonical_full_weave_gmp_v164.adb": "845bd8905943a54e63d6aba0334404a5051fe666",
    "src/canonical_full_weave_gmp_v164.ads": "0b68edf7eddbc33869358bcfcc21e32465fc591e",
    "src/normative_oracle.adb": "0be8f8ab4ddef26d34963d5567707a511ebda50b",
}
ALLOWED = {
    ".github/workflows/issue29-v177-gmp-edge-exhaustive.yml",
    "issue29_v177_gmp_edge_exhaustive.gpr",
    "tests/issue29_v177_gmp_edge_exhaustive_tests.adb",
    "tests/issue29_v177_gmp_edge_exhaustive_runner.py",
}
# Distinct cases from v174's (4,4) and (4,5,4); independently enumerated.
# Third field is an independently established count, NOT a code-under-test result.
FAMILIES = (
    ((2,), 1, 1),
    ((123,), 1, 1),
    ((2, 2), 6, 2),
    ((2, 3), 10, 3),
    ((3, 2), 10, 3),
    ((2, 2, 2), 90, 5),
    ((2, 3, 2, 2), 7560, 37),
    ((3, 2, 3, 2), 25200, 87),
    ((2, 2, 2, 2, 2), 113400, 42),
    ((2, 3, 2, 2, 2), 415800, 124),
)
EXPECTED_RANKS = 305
EXPECTED_CATALAN_47 = "33868773757191046886429490"
SCHEMA = "ISSUE29_V177_INDEPENDENT_EXHAUSTIVE_GMP_EDGE_NO_CALENDAR_DATE/1"
EVIDENCE = Path("evidence")
BINARY = Path("bin_v177/issue29_v177_gmp_edge_exhaustive_tests")
WALL = 90
CPU = 90
VM = 768 * 1024 * 1024
OUTPUT_MAX = 128 * 1024
BUILD_WALL = 120


def insist(ok: bool, reason: str) -> None:
    if not ok:
        raise ValueError(reason)


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def blob(data: bytes) -> str:
    return hashlib.sha1(
        b"blob " + str(len(data)).encode("ascii") + b"\0" + data
    ).hexdigest()


def git(*args: str) -> bytes:
    return subprocess.check_output(["git", *args], stderr=subprocess.DEVNULL)


def write_exclusive(path: Path, data: bytes) -> None:
    with path.open("xb") as output:
        output.write(data)
        output.flush()
        os.fsync(output.fileno())


def json_bytes(data: dict) -> bytes:
    return (json.dumps(data, sort_keys=True, ensure_ascii=False, indent=2) + "\n").encode()


def environment_guard() -> dict:
    insist(os.environ.get("GITHUB_RUN_ATTEMPT") == "1", "rerun forbidden")
    insist(os.environ.get("GITHUB_EVENT_NAME") == "push", "push only")
    insist(os.environ.get("GITHUB_REF") == "refs/heads/" + BRANCH, "wrong QA branch")
    event_path = os.environ.get("GITHUB_EVENT_PATH")
    insist(bool(event_path) and Path(event_path).is_file(), "event receipt absent")
    event = json.loads(Path(event_path).read_bytes())
    insist(event.get("head_commit", {}).get("message") == ACTIVATION,
           "exact one-shot activation commit message missing")
    head = git("rev-parse", "HEAD").decode().strip()
    insist(os.environ.get("GITHUB_SHA") == head, "head drift")
    run_id = os.environ.get("GITHUB_RUN_ID", "")
    insist(run_id.isdigit() and int(run_id) > 0, "run identity absent")
    insist(subprocess.run(
        ["git", "merge-base", "--is-ancestor", BASE, head],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    ).returncode == 0, "not from locked corrected Ada source")
    changed = git("diff", "--name-only", BASE + "...HEAD").decode().splitlines()
    insist(set(changed) == ALLOWED and len(changed) == 4,
           "unreviewed source change: " + repr(changed))
    return {"run_id": run_id, "run_attempt": 1, "head": head,
            "branch": BRANCH, "source_branch_baseline": BASE, "changed": changed}


def source_guard() -> dict:
    result = {}
    for name, pinned in SOURCES.items():
        b = Path(name).read_bytes()
        expected = git("rev-parse", SOURCE_BASE + ":" + name).decode().strip()
        insist(blob(b) == pinned and expected == pinned,
               "nonidentical production source: " + name)
        result[name] = {"git_blob_sha1": pinned, "sha256": digest(b), "bytes": len(b)}
    for path, expected in ((TEST, TEST_BLOB), (GPR, GPR_BLOB)):
        insist(blob(path.read_bytes()) == expected,
               "changed test harness source/GPR: " + str(path))
    t = TEST.read_text(encoding="utf-8")
    g = GPR.read_text(encoding="utf-8")
    insist("with Canonical_Full_Weave_GMP_V164;" in t, "GMP component import missing")
    insist("with Normative_Oracle" not in t
           and "Calendar_Date" not in t
           and "Month_Weaving" not in t, "forbidden original F or old weave imported")
    insist('with "gnatcoll_gmp.gpr";' in g,
           "GMP build context missing")
    lock = Path(".github/workflows/canonical-names-lock.yml").read_text()
    insist(lock.count("    if: " + "$" + "{{ false }}") == 42,
           "42 dangerous auto-dispatch jobs not disabled")
    insist(lock.count("  verify:\n") == 1, "name lock verifier damaged")
    canonical = git("show", MAIN + ":README.md")
    insist(blob(canonical) == MAIN_README_BLOB,
           "canonical math specification README drift")
    insist(math.comb(94, 47) // 48 == int(EXPECTED_CATALAN_47),
           "Catalan reference formula wrong")
    return {
        "locked_production": result,
        "test_git_blob": TEST_BLOB, "gpr_git_blob": GPR_BLOB,
        "main_sha": MAIN, "main_readme_blob": MAIN_README_BLOB,
        "42_date_capable_legacy_jobs_skipped": True,
        "native_calendar_date_authorized": 0,
        "original_soak_years": 0,
    }


def enumerate_reference(lengths: tuple[int, ...]):
    """Visit all unique multiset permutations without early validity pruning."""
    m = len(lengths)
    remaining = list(lengths)
    row: list[int] = []
    valid: list[tuple[int, ...]] = []
    expected_order = list(range(1, m + 1))
    expected_length = sum(lengths)
    leaf_count = 0

    def visit() -> None:
        nonlocal leaf_count
        if len(row) == expected_length:
            leaf_count += 1
            first: list[int] = []
            last: dict[int, int] = {}
            for i, month in enumerate(row):
                if month not in last:
                    first.append(month)
                last[month] = i
            if first == expected_order and sorted(last, key=last.get) == expected_order:
                valid.append(tuple(row))
            return
        for j in range(m):
            if remaining[j] > 0:
                remaining[j] -= 1
                row.append(j + 1)
                visit()
                row.pop()
                remaining[j] += 1

    visit()
    combinatorial_count = math.factorial(expected_length) // math.prod(
        math.factorial(n) for n in lengths
    )
    insist(leaf_count == combinatorial_count,
           "oracle did not enumerate every distinct multiset permutation")
    insist(valid == sorted(valid) and len(valid) == len(set(valid)),
           "reference is not strict lexicographic enumeration")
    return valid, leaf_count


def preflight() -> None:
    insist(EVIDENCE.is_dir(), "existing evidence folder needed")
    env = environment_guard()
    sources = source_guard()
    lines = [str(len(FAMILIES))]
    cases = []
    ranks = 0
    for lengths, total, count in FAMILIES:
        actual, leaves = enumerate_reference(lengths)
        insist(leaves == total and len(actual) == count,
               "independent fixture mismatch for family " + repr(lengths))
        lines.append(" ".join(map(str, (len(lengths), *lengths, count))))
        lines.extend(" ".join(map(str, row)) for row in actual)
        cases.append({"lengths": list(lengths), "distinct_permutations": leaves,
                      "legal_sequences": len(actual),
                      "total_days": sum(lengths)})
        ranks += len(actual)
    insist(ranks == EXPECTED_RANKS, "wrong aggregate exhaustive rank count")
    data = ("\n".join(lines) + "\n").encode("ascii")
    write_exclusive(EVIDENCE / "v177-reference.dat", data)
    receipt = {
        "schema": SCHEMA, "status": "PREFLIGHT_ONLY_ZERO_NATIVE_CALLS",
        "environment": env, "sources": sources, "families": cases,
        "families_checked": len(cases), "all_legal_ranks": ranks,
        "reference_sha256": digest(data), "reference_bytes": len(data),
        "catalan47_closed_form": EXPECTED_CATALAN_47,
        "calendar_date_calls": 0, "full_calendar_F_calls": 0,
        "soak_years": 0, "dispatch_halt_remains": True,
    }
    write_exclusive(EVIDENCE / "preflight.json", json_bytes(receipt))
    print("V177_TEN_INDEPENDENT_FULL_ENUMERATIONS_305_RANKS_READY_NO_F")


def build() -> None:
    insist(EVIDENCE.is_dir(), "missing evidence folder")
    source_guard()
    pre = json.loads((EVIDENCE / "preflight.json").read_bytes())
    insist(pre["status"] == "PREFLIGHT_ONLY_ZERO_NATIVE_CALLS"
           and pre["environment"] == environment_guard(),
           "source or checkout preflight drift")
    cmd = ["gprbuild", "-p", "-j2", "-P", str(GPR)]
    try:
        result = subprocess.run(
            cmd, capture_output=True, timeout=BUILD_WALL, check=False,
        )
        stdout, stderr, code = result.stdout, result.stderr, result.returncode
    except subprocess.TimeoutExpired as exc:
        stdout, stderr, code = exc.stdout or b"", exc.stderr or b"", -999
    write_exclusive(EVIDENCE / "build.stdout", stdout[:1_000_000])
    write_exclusive(EVIDENCE / "build.stderr", stderr[:1_000_000])
    insist(code == 0 and BINARY.is_file(), "GNAT/GMP compile or link failed")
    # The executable must not link the original full-calendar converter symbol.
    sym = subprocess.run(["nm", str(BINARY)], capture_output=True, check=True)
    insist(b"normative_oracle" not in sym.stdout.lower(),
           "unexpected original normative calendar linked into GMP-only test")
    manifest = {
        "schema": SCHEMA, "status": "COMPONENT_ONLY_BUILD_LINKED_NO_EXECUTION",
        "test_binary": str(BINARY), "test_binary_sha256": digest(BINARY.read_bytes()),
        "build_exit": code, "build_stdout_sha256": digest(stdout),
        "build_stderr_sha256": digest(stderr),
        "normative_oracle_symbols_linked": 0,
        "native_calendar_calls": 0,
    }
    write_exclusive(EVIDENCE / "build.json", json_bytes(manifest))
    print("V177_ISOLATED_NATIVE_GMP_TEST_COMPILED_LINKED_NO_F")


def _limits() -> None:
    resource.setrlimit(resource.RLIMIT_CPU, (CPU, CPU))
    resource.setrlimit(resource.RLIMIT_AS, (VM, VM))
    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))


def _kill(p) -> None:
    try:
        os.killpg(p.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass


def run_once() -> None:
    insist(EVIDENCE.is_dir(), "missing evidence")
    source_guard()
    pre = json.loads((EVIDENCE / "preflight.json").read_bytes())
    built = json.loads((EVIDENCE / "build.json").read_bytes())
    insist(pre["environment"] == environment_guard()
           and pre["reference_sha256"] == digest(
               (EVIDENCE / "v177-reference.dat").read_bytes()
           ), "fixture receipt/source identity drift")
    insist(built["status"] == "COMPONENT_ONLY_BUILD_LINKED_NO_EXECUTION"
           and built["test_binary_sha256"] == digest(BINARY.read_bytes()),
           "test binary drift after GMP build")
    insist(not (EVIDENCE / "RUN_STARTED_ONCE").exists(), "one-shot already attempted")
    write_exclusive(EVIDENCE / "RUN_STARTED_ONCE", json_bytes({
        "run_id": pre["environment"]["run_id"],
        "head": pre["environment"]["head"],
        "test_binary_sha256": built["test_binary_sha256"],
        "test_invocations": 1,
        "calendar_date_calls": 0, "soak_years": 0,
    }))
    out = EVIDENCE / "native.stdout"
    err = EVIDENCE / "native.stderr"
    result = {
        "schema": SCHEMA, "status": "FAIL_CLOSED",
        "test_binary_sha256": built["test_binary_sha256"],
        "reference_sha256": pre["reference_sha256"],
        "calendar_date_calls": 0, "soak_years": 0,
        "native_test_invocations": 1, "rerun_allowed": False,
        "catalan47": EXPECTED_CATALAN_47,
        "cases": None, "ranks": None, "assertions": None,
        "process_exit_code": None, "elapsed_seconds": None,
        "resource_violation": None,
    }
    child = None
    start = time.monotonic()
    try:
        with out.open("xb") as fo, err.open("xb") as fe:
            child = subprocess.Popen(
                [str(BINARY.resolve())], cwd=str(Path.cwd()),
                stdin=subprocess.DEVNULL, stdout=fo, stderr=fe,
                shell=False, start_new_session=True, preexec_fn=_limits
            )
            violation = None
            while True:
                code = child.poll()
                if out.stat().st_size + err.stat().st_size > OUTPUT_MAX:
                    violation = "OUTPUT_SIZE"
                    _kill(child)
                    break
                if time.monotonic() - start > WALL:
                    violation = "WALL_TIMEOUT"
                    _kill(child)
                    break
                if code is not None:
                    break
                time.sleep(.05)
            child.wait(timeout=5)
        raw, errors = out.read_bytes(), err.read_bytes()
        result.update({
            "elapsed_seconds": round(time.monotonic() - start, 4),
            "process_exit_code": child.returncode,
            "resource_violation": violation,
            "stdout_sha256": digest(raw), "stderr_sha256": digest(errors),
            "stdout_bytes": len(raw), "stderr_bytes": len(errors),
            "peak_rss_kib": resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss,
        })
        insist(child.returncode == 0 and violation is None and not errors,
               "test exited nonzero, stderr nonempty, or resource cap exceeded")
        txt = raw.decode("utf-8", errors="strict")
        def field(name: str) -> str:
            vals = re.findall(
                "^" + re.escape(name) + r"=\s*([0-9]+)\s*$", txt, re.M
            )
            insist(len(vals) == 1, "native field missing or ambiguous: " + name)
            return vals[0]
        cases = int(field("ISSUE29_V177_GMP_EDGE_CASES"))
        ranks = int(field("ISSUE29_V177_GMP_EDGE_RANKS"))
        assertions = int(field("ISSUE29_V177_GMP_EDGE_ASSERTIONS"))
        catalan = field("ISSUE29_V177_CATALAN47")
        insist(cases == 10 and ranks == EXPECTED_RANKS
               and assertions > 1000 and catalan == EXPECTED_CATALAN_47,
               "native GMP edge assertions, rank count, or Catalan mismatch")
        result.update({"cases": cases, "ranks": ranks, "assertions": assertions,
                       "status": "PASS_INDEPENDENT_EXHAUSTIVE_GMP_EDGE_NO_CALENDAR_F"})
    except Exception as exc:
        result["failure"] = str(exc)
        if child is not None and child.poll() is None:
            _kill(child)
            child.wait(timeout=5)
    finally:
        for name, path in (("stdout", out), ("stderr", err)):
            if path.exists():
                result[name + "_sha256"] = digest(path.read_bytes())
                result[name + "_bytes"] = path.stat().st_size
        write_exclusive(EVIDENCE / "result.json", json_bytes(result))
    insist(result["status"] == "PASS_INDEPENDENT_EXHAUSTIVE_GMP_EDGE_NO_CALENDAR_F",
           "GMP edge component regression failed; no automatic retry")
    print("V177_TEN_FAMILIES_305_EXHAUSTIVE_RANKS_CATALAN47_PASS_ZERO_F")


def main() -> None:
    insist(len(sys.argv) == 2 and sys.argv[1] in
           ("preflight", "build", "run-once"), "mode preflight|build|run-once")
    mode = sys.argv[1]
    if mode == "preflight":
        preflight()
    elif mode == "build":
        build()
    else:
        run_once()


if __name__ == "__main__":
    main()
