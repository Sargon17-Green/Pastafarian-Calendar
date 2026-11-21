#!/usr/bin/env python3
"""Issue #29 v160: one-date, fail-closed diagnostic on QA-only instrumented copies.

This is NOT a canonical converter and does NOT rewrite historical source.
"prepare" and "build" never call F(c,t). "run" allows one call per language
only after original Git-blob pinning, reversible instrumentation and Ada build.
"""
from __future__ import annotations

import argparse
import ast
import base64
from collections import Counter
from difflib import unified_diff
from hashlib import sha1, sha256
from itertools import combinations
import json
import os
from pathlib import Path
import resource
import selectors
import shutil
import signal
import subprocess
import sys
import time
import urllib.parse
import urllib.request

sys.path.insert(0, str(Path(__file__).resolve().parent))
from soak_ada_month_family_divergence_v156 import SOURCE_LOCKS, blob_sha
from soak_foundation_diagnostic_patchplan_v159 import (
    strip_insertions, generate, verify,
)

REPO = "Sargon17-Green/Pastafarian-Calendar"
MAIN = "56bc4173aae4975ded019ef5ab5a36249f1424df"
README_BLOB = "74c424b44eadd4ece3f29072ddbf873236557604"
DAY = "-15055671"
MAX_RSS_BYTES = 256 * 1024 * 1024
MAX_OUTPUT_BYTES = 256 * 1024
RUN_TIMEOUT_SECONDS = 30
ADA_BUILD_TIMEOUT_SECONDS = 120
MAX_BUILD_LOG = 1024 * 1024


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def digest(data: bytes) -> str:
    return sha256(data).hexdigest()


def git_blob(data: bytes) -> str:
    return sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()


def read_github(path: str, commit: str, expected: str | None = None) -> tuple[bytes, str]:
    require(bool(os.environ.get("GITHUB_TOKEN")), "no GitHub token; no source dispatch")
    url = (f"https://api.github.com/repos/{REPO}/contents/"
           + urllib.parse.quote(path, safe="/") + "?ref=" + commit)
    req = urllib.request.Request(url, headers={
        "Authorization": "Bearer " + os.environ["GITHUB_TOKEN"],
        "Accept": "application/vnd.github+json",
        "User-Agent": "issue29-v160-immutable-diagnostic",
    })
    with urllib.request.urlopen(req, timeout=25) as response:
        result = json.load(response)
    require(result.get("type") == "file" and result.get("encoding") == "base64",
            "not a regular pinned GitHub source file")
    raw = base64.b64decode("".join(result["content"].split()), validate=True)
    actual = git_blob(raw)
    require(actual == result["sha"], "GitHub reported blob and raw bytes differ")
    if expected:
        require(actual == expected, f"original immutable source SHA mismatch: {path}")
    return raw, actual


def list_ada_sources(commit: str) -> dict[str, str]:
    req = urllib.request.Request(
        f"https://api.github.com/repos/{REPO}/contents/src?ref={commit}",
        headers={"Authorization": "Bearer " + os.environ["GITHUB_TOKEN"],
                 "Accept": "application/vnd.github+json",
                 "User-Agent": "issue29-v160-immutable-diagnostic"},
    )
    with urllib.request.urlopen(req, timeout=25) as response:
        data = json.load(response)
    require(isinstance(data, list) and len(data) == 10, "unexpected Ada source directory")
    out = {}
    for x in data:
        require(x["type"] == "file" and x["name"].endswith((".adb", ".ads")),
                "unexpected Ada source entry")
        out[x["name"]] = x["sha"]
    return out


def synthetic_math_witnesses() -> dict:
    cases = {}
    for n1, n2, want_general, want_rail in [(2, 2, 2, 1), (4, 4, 20, 6), (4, 5, 35, 10)]:
        legal, rail = [], []
        for positions in combinations(range(n1 + n2), n1):
            chosen = set(positions)
            seq = tuple(1 if p in chosen else 2 for p in range(n1 + n2))
            if seq.index(1) < seq.index(2) and (
                len(seq) - 1 - seq[::-1].index(1)
                < len(seq) - 1 - seq[::-1].index(2)
            ):
                legal.append(seq)
                if seq[:2] == (1, 2) and seq[-2:] == (1, 2):
                    rail.append(seq)
        require(len(legal) == want_general and len(rail) == want_rail,
                "mathematical independent witness changed")
        require(set(rail) < set(legal), "Ada two-rail not strict subset")
        cases[f"{n1},{n2}"] = {
            "full_spec_family": len(legal), "ada_two_rail_family": len(rail),
            "independent_brute_force_no_calendar_calls": True,
        }
    return cases


def json_write_new(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("x", encoding="utf-8") as output:
        json.dump(value, output, ensure_ascii=False, indent=2, sort_keys=True)
        output.write("\n")


def prepare(base: Path) -> None:
    require(not base.exists(), "existing work root: refusing to overwrite or rerun")
    base.mkdir(parents=True)
    srcroot = base / "sources"
    exact = {}
    for key, spec in SOURCE_LOCKS.items():
        data, gitsha = read_github(spec["path"], spec["commit"], spec["git_blob_sha1"])
        directory = "Python-Turkce" if key == "REF-41" else "Ada-Telugu"
        dst = srcroot / directory / spec["commit"] / spec["path"]
        dst.parent.mkdir(parents=True, exist_ok=True)
        dst.write_bytes(data)
        exact[key] = {"git_blob_sha1": gitsha, "sha256": digest(data),
                      "commit": spec["commit"], "path": spec["path"]}
    reference, refsha = read_github("README.md", MAIN, README_BLOB)
    spec_text = reference.decode("utf-8")
    require("# V. L-Insiġ tax-Xhur" in spec_text
            and "Tintgħażel in-**nisġa kollha**" in spec_text
            and "| 1 | -15,055,671 | -15,055,671 | 5000 | 10 | 503 | 20 | 56 |" in spec_text
            and "openGate  = -15,057,703" in spec_text
            and "closeGate = -15,053,459" in spec_text,
            "canonical spec changed; refuse to execute")
    (base / "canonical_README_locked.md").write_bytes(reference)

    ada_src_dir = base / "ada-build" / "src"
    ada_src_dir.mkdir(parents=True)
    for filename, expected in list_ada_sources(SOURCE_LOCKS["ADA-TELUGU"]["commit"]).items():
        data, actual = read_github("src/" + filename, SOURCE_LOCKS["ADA-TELUGU"]["commit"], expected)
        (ada_src_dir / filename).write_bytes(data)
    evidence = base / "v159-raw-copies"
    manifest = generate(srcroot, evidence)
    require(verify(srcroot, evidence), "v159 deterministic reversibility check failed")
    py = (evidence / "instrumented_normative_reference_v159.py").read_bytes()
    ast.parse(py.decode("utf-8"))
    (base / "instrumented_normative_reference_v159.py").write_bytes(py)

    ada_copy = (evidence / "instrumented_normative_oracle_v159.adb").read_bytes()
    for old, new in [(b"V159_ADA_DIAG|ticket|", b"T|"),
                     (b"V159_ADA_DIAG|weave|", b"W|")]:
        require(ada_copy.count(old) == 1, "compact stderr prefix anchor not unique")
        ada_copy = ada_copy.replace(old, new, 1)
    original_ada = (ada_src_dir / "normative_oracle.adb").read_bytes()
    require(strip_insertions(
        ada_copy,
        ("ADA_MONTH_LENGTH_RANK", "ADA_INTERIOR_TICKETS", "ADA_FINAL_NAME_AND_WEAVE"),
        "ADA",
    ) == original_ada, "instrumented Ada differs outside explicitly added blocks")
    (ada_src_dir / "normative_oracle.adb").write_bytes(ada_copy)
    review = "".join(unified_diff(
        original_ada.decode().splitlines(True), ada_copy.decode().splitlines(True),
        fromfile="historical/original/normative_oracle.adb",
        tofile="QA-instrumented-only/src/normative_oracle.adb",
    ))
    (base / "ada-instrumentation-review.diff").write_text(review, encoding="utf-8")
    main = """with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Text_IO;
with Normative_Oracle;
procedure Issue29_Foundation_Probe is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   X : constant Normative_Oracle.Calendar_Result :=
     Normative_Oracle.Calendar_Date
       (Normative_Oracle.Foundation_Day, Normative_Oracle.Foundation_Day);
begin
   Ada.Text_IO.Put_Line
     ("V160_ADA_RESULT|" & To_String (X.Year_Number) &
      "|" & Positive'Image (X.Cutlet_Canonical) &
      "|" & To_String (X.Day_In_Cutlet) &
      "|" & Positive'Image (X.Month_Canonical) &
      "|" & To_String (X.Day_In_Month));
end Issue29_Foundation_Probe;
"""
    tests = base / "ada-build" / "tests"
    tests.mkdir()
    (tests / "issue29_foundation_probe.adb").write_text(main, encoding="utf-8")
    json_write_new(base / "preparation.json", {
        "status": "QA_COPIES_ONLY_NO_FCT_EXECUTION",
        "main_commit": MAIN, "canonical_readme_blob": refsha,
        "case": {"c": DAY, "t": DAY},
        "historical_sources": exact,
        "v159_generated_manifest_status": manifest.get("status"),
        "python_qa_sha256": digest(py), "ada_compacted_qa_sha256": digest(ada_copy),
        "synthesized_probe_sha256": digest(main.encode()),
        "math_witnesses": synthetic_math_witnesses(),
        "year_open_normative": -15057703, "year_close_normative": -15053459,
        "year_length_normative": 4244, "target_offset0_normative": 2031,
        "source_dispatch_count": 0, "soak_years": 0,
    })


def run_bounded(command: list[str], cwd: Path, out: Path, err: Path,
                timeout_seconds: int, output_limit: int, as_limit: int,
                cpu_seconds: int) -> dict:
    out.parent.mkdir(parents=True, exist_ok=True)
    start = time.monotonic()
    def limits():
        resource.setrlimit(resource.RLIMIT_AS, (as_limit, as_limit))
        resource.setrlimit(resource.RLIMIT_CPU, (cpu_seconds, cpu_seconds + 1))
        resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
    proc = subprocess.Popen(command, cwd=cwd, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, preexec_fn=limits,
                            start_new_session=True)
    poller = selectors.DefaultSelector()
    poller.register(proc.stdout, selectors.EVENT_READ, "stdout")
    poller.register(proc.stderr, selectors.EVENT_READ, "stderr")
    total, reason = 0, "completed"
    with out.open("xb") as stdout, err.open("xb") as stderr:
        while poller.get_map():
            remaining = timeout_seconds - (time.monotonic() - start)
            if remaining <= 0:
                reason = "TIME_LIMIT"
                os.killpg(proc.pid, signal.SIGKILL)
                break
            for key, _ in poller.select(timeout=min(remaining, 0.2)):
                block = os.read(key.fileobj.fileno(), 8192)
                if not block:
                    poller.unregister(key.fileobj)
                    continue
                total += len(block)
                (stdout if key.data == "stdout" else stderr).write(block)
                if total > output_limit:
                    reason = "OUTPUT_LIMIT"
                    os.killpg(proc.pid, signal.SIGKILL)
                    break
            if reason != "completed":
                break
    poller.close()
    try:
        rc = proc.wait(timeout=3)
    except subprocess.TimeoutExpired:
        os.killpg(proc.pid, signal.SIGKILL)
        rc = proc.wait(timeout=3)
    elapsed = time.monotonic() - start
    receipt = {
        "status": reason, "exit_code": rc, "elapsed_seconds": round(elapsed, 4),
        "stdout_sha256": digest(out.read_bytes()), "stderr_sha256": digest(err.read_bytes()),
        "stdout_bytes": out.stat().st_size, "stderr_bytes": err.stat().st_size,
        "command": command, "cwd": str(cwd),
        "address_space_cap_bytes": as_limit, "cpu_seconds_cap": cpu_seconds,
        "wall_seconds_cap": timeout_seconds, "combined_output_cap_bytes": output_limit,
        "source_mode": "QA_INSTRUMENTED_COPY_NOT_ORIGINAL",
    }
    require(reason == "completed" and rc == 0, "bounded process failed: " + json.dumps(receipt))
    return receipt


def compile_ada(base: Path) -> None:
    require((base / "preparation.json").exists(), "unverified source-preparation")
    require(not (base / "build.json").exists(), "build already attempted; no overwrite")
    require(shutil.which("gnatmake"), "GNAT not installed; no diagnostic dispatch")
    root = base / "ada-build"
    (root / "bin").mkdir(exist_ok=True)
    version = subprocess.run(["gnatmake", "--version"], capture_output=True,
                             text=True, timeout=3, check=True).stdout.strip()
    command = ["gnatmake", "-gnat2022", "-gnatW8", "-gnata", "-Isrc",
               "-o", "bin/issue29_foundation_probe",
               "tests/issue29_foundation_probe.adb"]
    result = run_bounded(command, root, base / "gnat-build.stdout",
                         base / "gnat-build.stderr", ADA_BUILD_TIMEOUT_SECONDS,
                         MAX_BUILD_LOG, 1024 * 1024 * 1024, 120)
    binary = root / "bin" / "issue29_foundation_probe"
    require(binary.is_file(), "Ada executable missing after claimed compilation")
    result["gnatmake_version"] = version
    result["binary_sha256"] = digest(binary.read_bytes())
    result["instrumented_ada_sha256"] = digest((root / "src/normative_oracle.adb").read_bytes())
    result["compile_only_Fct_calls"] = 0
    json_write_new(base / "build.json", result)


def python_command(base: Path) -> list[str]:
    script = (
        "import importlib.util,sys;"
        f"p={str(base / 'instrumented_normative_reference_v159.py')!r};"
        "spec=importlib.util.spec_from_file_location('v160_pinned_qa_copy',p);"
        "m=importlib.util.module_from_spec(spec);sys.modules[spec.name]=m;"
        "spec.loader.exec_module(m);"
        f"x=m.NormativeCalendar().calendar_date_ids({DAY},{DAY});"
        "print('V160_PY_RESULT|'+ '|'.join(map(str,(x.year_number,"
        "x.cutlet_name_index,x.day_in_cutlet,x.month_name_index,x.day_in_month))))"
    )
    return [sys.executable, "-B", "-c", script]


def run_one_date(base: Path) -> None:
    prep = json.loads((base / "preparation.json").read_text())
    build = json.loads((base / "build.json").read_text())
    require(prep["source_dispatch_count"] == 0 and prep["soak_years"] == 0,
            "unsafe previous dispatch state")
    require(not (base / "RUN_STARTED_ONCE").exists(), "one-shot authorization already used")
    require(digest((base / "instrumented_normative_reference_v159.py").read_bytes())
            == prep["python_qa_sha256"], "Python QA copy changed after preflight")
    ada = base / "ada-build/src/normative_oracle.adb"
    binary = base / "ada-build/bin/issue29_foundation_probe"
    require(digest(ada.read_bytes()) == prep["ada_compacted_qa_sha256"]
            and digest(binary.read_bytes()) == build["binary_sha256"],
            "Ada QA copy or executable changed since build")
    (base / "RUN_STARTED_ONCE").open("x").write("one foundation day per QA lineage only\n")
    env_old = os.environ.get("PC_FOUNDATION_DIAG_V159")
    require(env_old == "1", "diagnostic stderr must be explicitly enabled")
    results = {}
    commands = [
        ("python", python_command(base), base),
        ("ada", [str(binary)], base / "ada-build"),
    ]
    for lang, command, cwd in commands:
        stdout = base / f"run-{lang}.stdout"
        stderr = base / f"run-{lang}.stderr"
        receipt = run_bounded(command, cwd, stdout, stderr,
                              RUN_TIMEOUT_SECONDS, MAX_OUTPUT_BYTES,
                              MAX_RSS_BYTES, RUN_TIMEOUT_SECONDS)
        results[lang] = receipt
        json_write_new(base / f"run-{lang}.receipt.json", receipt)
    json_write_new(base / "run-results.json", {
        "status": "TWO_QA_INSTRUMENTED_FOUNDATION_CALLS_NOT_ORIGINAL",
        "case": {"c": DAY, "t": DAY}, "original_calls": 0,
        "qa_calls": {"python": 1, "ada": 1},
        "runs": results, "original_soak_years_certified": 0,
        "STOP_NEW_NATIVE_SOAK_DISPATCH": True,
    })


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=("prepare", "compile", "run"))
    parser.add_argument("--root", type=Path, required=True)
    args = parser.parse_args()
    base = args.root.resolve()
    if args.action == "prepare":
        prepare(base)
    elif args.action == "compile":
        compile_ada(base)
    elif args.action == "run":
        run_one_date(base)
    print("V160_ACTION_COMPLETE", args.action, str(base))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:
        print("V160_FAIL_CLOSED:", type(exc).__name__, str(exc), file=sys.stderr)
        raise
