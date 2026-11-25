#!/usr/bin/env python3
"""Build, run and independently audit the Stage55 full-prefix inverse rank.

Requires Python 3.10+, g++ C++17 and GMP development headers/libraries.
The numerical core is a standalone GMP implementation in the companion .cpp.
"""
from __future__ import annotations
import argparse
import csv
import gzip
import hashlib
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

PROJECT_ID = "PC-BRANCH-MATLAB-POLSKI"
INPUT_COMMIT_LOCK = "2f56e8725229129c03b713c3a41bb751d1f431e5"
WORD_GIT_BLOB = "cb4983bcb15e4840b26b46ef2c0566ab870a111e"
WORD_SHA256 = "82042fef5a65cc8b08120d069fa9d8f31c05e6761040f82c3341328ded9b44e5"
FIXTURE_GIT_BLOB = "a1383b111a88203b0d652b8f0a0e9af1a8b75f25"
ROOT_COUNT_SHA256 = "c0c08ac89c8faaaf589d1b3e076fe1e96405f2ad7172a15efa9d028fb43fb6f8"
MIDDLE_RANK_SHA256 = "cd5ce4036fc8e99355a4bab5d48c3db473422083d035df5e0af25297be1be3b6"
EXPECTED_TINY = (16, 1172, 4253)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def git_blob_sha1(data: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()


def compiler_version() -> str:
    result = subprocess.run(["g++", "--version"], text=True, capture_output=True, check=True)
    return result.stdout.splitlines()[0]


def parse_summary(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in path.read_text(encoding="ascii").splitlines():
        key, value = line.split("=", 1)
        if key in result:
            raise AssertionError(f"duplicate summary key {key}")
        result[key] = value
    required = {
        "ROOT_COUNT", "FINAL_RANK", "PREFIX_INTERVALS",
        "ENDPOINT_ORDER_ONLY_AT_PREFIX", "ALL_LABELS_OPENED_AT_PREFIX", "REFERENCE_TRACE_MATCHED", "ELAPSED_SECONDS",
    }
    if set(result) != required:
        raise AssertionError(f"summary keys mismatch: {set(result)}")
    return result



def decimal_compare(a: str, b: str) -> int:
    a = a.lstrip("0") or "0"
    b = b.lstrip("0") or "0"
    if len(a) != len(b):
        return -1 if len(a) < len(b) else 1
    return (a > b) - (a < b)

def run(args: argparse.Namespace) -> dict:
    sys.set_int_max_str_digits(0)
    word_path = Path(args.word).resolve()
    fixture_path = Path(args.fixture).resolve()
    cpp_path = Path(args.cpp).resolve()
    out = Path(args.out).resolve()
    out.mkdir(parents=True, exist_ok=True)
    shutil.copy2(cpp_path, out / "stage55_full_prefix_inverse_rank.cpp")
    shutil.copy2(Path(__file__).resolve(), out / "run_stage55_full_prefix_inverse_rank.py")
    shutil.copy2(word_path, out / "word.json")
    shutil.copy2(fixture_path, out / "fixture.json")
    raw_trace = out / "prefix_intervals.tsv"
    summary_path = out / "core_summary.txt"
    run_log = out / "run.log"
    compressed_trace = out / "prefix_intervals.jsonl.gz"
    for p in (raw_trace, summary_path, run_log, compressed_trace):
        if p.exists():
            p.unlink()

    log_lines: list[str] = []
    def log(message: str) -> None:
        print(message, flush=True)
        log_lines.append(message)

    log("STAGE55_FULL_PREFIX_INVERSE_RANK_BEGIN")
    log(f"PROJECT_ID={PROJECT_ID}")
    log(f"INPUT_COMMIT_LOCK={INPUT_COMMIT_LOCK}")
    log(f"VERIFIER_COMMIT={os.environ.get('GITHUB_SHA', 'LOCAL_UNCOMMITTED')}")

    word_bytes = word_path.read_bytes()
    fixture_bytes = fixture_path.read_bytes()
    word_blob = git_blob_sha1(word_bytes)
    word_sha = sha256(word_bytes)
    fixture_blob = git_blob_sha1(fixture_bytes)
    fixture_sha = sha256(fixture_bytes)
    if word_blob != WORD_GIT_BLOB or word_sha != WORD_SHA256:
        raise AssertionError(f"word lock mismatch git={word_blob} sha256={word_sha}")
    if fixture_blob != FIXTURE_GIT_BLOB:
        raise AssertionError(f"fixture blob mismatch git={fixture_blob}")
    word = json.loads(word_bytes)
    fixture = json.loads(fixture_bytes)
    lengths = fixture.get("month_lengths")
    if fixture.get("year") != 5000 or fixture.get("months") != 45:
        raise AssertionError("fixture year/month header mismatch")
    if len(lengths) != 45 or len(word) != 4244 or sum(lengths) != 4244:
        raise AssertionError("fixture/word dimensions mismatch")
    if min(lengths) != 25 or max(lengths) != 122:
        raise AssertionError("fixture month-length range mismatch")
    counts = [0] * 45
    first = [None] * 45
    last = [None] * 45
    for pos, symbol in enumerate(word):
        if not isinstance(symbol, int) or not 1 <= symbol <= 45:
            raise AssertionError(f"invalid word symbol at {pos + 1}")
        counts[symbol - 1] += 1
        if first[symbol - 1] is None:
            first[symbol - 1] = pos
        last[symbol - 1] = pos
    if counts != lengths:
        raise AssertionError("word multiplicities do not match pinned month vector")
    if any(a >= b for a, b in zip(first, first[1:])):
        raise AssertionError("first-occurrence order failure")
    if any(a >= b for a, b in zip(last, last[1:])):
        raise AssertionError("last-occurrence order failure")
    log(f"INPUT_LOCK_PASS WORD_GIT_BLOB={word_blob} WORD_SHA256={word_sha}")
    log(f"FIXTURE_LOCK_PASS FIXTURE_GIT_BLOB={fixture_blob} FIXTURE_SHA256={fixture_sha} MONTHS=45 DAYS=4244 MIN=25 MAX=122")

    compiler = compiler_version()
    binary = out / "stage55_full_prefix_inverse_rank"
    compile_cmd = ["g++", "-std=c++17", "-O3", "-DNDEBUG", str(cpp_path), "-lgmpxx", "-lgmp", "-o", str(binary)]
    compile_result = subprocess.run(compile_cmd, text=True, capture_output=True, timeout=120)
    if compile_result.returncode != 0:
        raise RuntimeError("GMP C++ compile failed:\n" + compile_result.stdout + compile_result.stderr)
    log(f"COMPILE_PASS COMPILER={compiler}")
    log("COMPILE_COMMAND=" + " ".join(compile_cmd))

    core_cmd = [str(binary), "--word", str(word_path), "--fixture", str(fixture_path),
                "--trace", str(raw_trace), "--summary", str(summary_path),
                "--time-limit-seconds", str(args.time_limit_seconds)]
    if args.reference_trace:
        core_cmd.extend(["--reference-trace", str(Path(args.reference_trace).resolve())])
    started = time.perf_counter()
    core = subprocess.run(core_cmd, text=True, capture_output=True,
                          timeout=args.time_limit_seconds + 30)
    elapsed_wall = time.perf_counter() - started
    core_output = core.stdout + core.stderr
    log_lines.extend(core_output.rstrip().splitlines())
    print(core_output, end="" if core_output.endswith("\n") else "\n", flush=True)
    if core.returncode != 0:
        raise RuntimeError(f"GMP inverse core failed exit={core.returncode}")
    if "STAGE55_FULL_PREFIX_INVERSE_RANK_CORE_PASS" not in core.stdout:
        raise AssertionError("GMP core PASS marker missing")

    tiny_line = next((line for line in core.stdout.splitlines() if line.startswith("TINY_EXHAUSTIVE_PARTITIONS_PASS ")), None)
    if tiny_line is None:
        raise AssertionError("tiny exhaustive marker missing")
    tiny_fields = dict(item.split("=", 1) for item in tiny_line.split()[1:])
    tiny = tuple(int(tiny_fields[k]) for k in ("FAMILIES", "WORDS", "PREFIXES"))
    if tiny != EXPECTED_TINY:
        raise AssertionError(f"tiny exhaustive controls mismatch: {tiny}")

    summary = parse_summary(summary_path)
    root_text = summary["ROOT_COUNT"]
    rank_text = summary["FINAL_RANK"]
    root = int(root_text)
    rank = int(rank_text)
    if len(root_text) != 6765 or sha256(root_text.encode("ascii")) != ROOT_COUNT_SHA256:
        raise AssertionError("independent root count does not match exact pinned count")
    if len(rank_text) != 6764 or sha256(rank_text.encode("ascii")) != MIDDLE_RANK_SHA256:
        raise AssertionError("independent inverse rank does not match exact pinned rank")
    if rank != root // 2 + 1:
        raise AssertionError("middle-rank policy R=floor(T/2)+1 failed")
    if int(summary["PREFIX_INTERVALS"]) != 4244:
        raise AssertionError("core did not produce all 4,244 prefix intervals")
    reference = None
    reference_matched = int(summary["REFERENCE_TRACE_MATCHED"])
    if args.reference_trace:
        if reference_matched != 4244 or "REFERENCE_TRACE_DIFFERENTIAL_PASS MATCHED=4244/4244" not in core.stdout:
            raise AssertionError("GMP core did not match every archived reference interval")
        reference = {"performed": True, "matched_intervals": reference_matched,
                     "reference_trace_sha256": sha256(Path(args.reference_trace).read_bytes())}
    elif reference_matched != 0:
        raise AssertionError("unexpected reference trace match count without a reference input")
    endpoint_only_at = int(summary["ENDPOINT_ORDER_ONLY_AT_PREFIX"])
    all_labels_at = int(summary["ALL_LABELS_OPENED_AT_PREFIX"])
    if (endpoint_only_at, all_labels_at) != (202, 245):
        raise AssertionError(f"opening frontier transition mismatch: {(endpoint_only_at, all_labels_at)}")
    log(f"ROOT_COUNT_PASS DIGITS={len(root_text)} SHA256={sha256(root_text.encode('ascii'))}")
    log(f"FINAL_INVERSE_RANK_PASS DIGITS={len(rank_text)} SHA256={sha256(rank_text.encode('ascii'))}")
    log(f"MIDDLE_RANK_POLICY_PASS R=floor(T/2)+1")

    intervals: list[tuple[int, int, str, str]] = []
    remaining = list(lengths)
    opened = 0
    closed = 0
    previous: tuple[str, str] | None = None
    sequence_hash = hashlib.sha256()
    endpoint_transition_seen = None
    all_labels_seen = None
    with raw_trace.open("r", encoding="ascii", newline="") as src, \
         compressed_trace.open("wb") as gz_file:
        with gzip.GzipFile(filename="", mode="wb", compresslevel=9, fileobj=gz_file, mtime=0) as gz:
            reader = csv.DictReader(src, delimiter="\t")
            expected_header = ["prefix_length", "symbol", "rank_low", "rank_high", "legal_next_count", "method"]
            if reader.fieldnames != expected_header:
                raise AssertionError(f"trace header mismatch: {reader.fieldnames}")
            for position, row in enumerate(reader, 1):
                pos = int(row["prefix_length"])
                symbol = int(row["symbol"])
                low = row["rank_low"]
                high = row["rank_high"]
                legal_count = int(row["legal_next_count"])
                if pos != position or symbol != word[position - 1]:
                    raise AssertionError(f"prefix identity mismatch at {position}")
                if (not low.isdigit() or low.startswith("0") or not high.isdigit() or high.startswith("0")
                        or decimal_compare("1", low) > 0 or decimal_compare(low, high) > 0
                        or decimal_compare(high, root_text) > 0 or not 1 <= legal_count <= 45):
                    raise AssertionError(f"invalid interval bounds at {position}")
                if previous is not None and (decimal_compare(previous[0], low) > 0 or
                                             decimal_compare(high, previous[1]) > 0):
                    raise AssertionError(f"non-nested prefix interval at {position}")
                label = symbol - 1
                before = remaining[label]
                method_expected = "two-basis-first-letter-DP" if opened < 44 else "all-open-common-denominator"
                if row["method"] != method_expected:
                    raise AssertionError(f"method/frontier mismatch at prefix {position}")
                remaining[label] -= 1
                if before == lengths[label]:
                    if label != opened:
                        raise AssertionError(f"opening order mismatch at prefix {position}")
                    opened += 1
                    if endpoint_transition_seen is None and opened >= 44:
                        endpoint_transition_seen = position
                    if all_labels_seen is None and opened == 45:
                        all_labels_seen = position
                if remaining[label] == 0:
                    if label != closed:
                        raise AssertionError(f"closure order mismatch at prefix {position}")
                    closed += 1
                record = {
                    "prefix_length": pos,
                    "symbol": symbol,
                    "rank_low": low,
                    "rank_high": high,
                    "rank_low_sha256": sha256(low.encode("ascii")),
                    "rank_high_sha256": sha256(high.encode("ascii")),
                    "legal_next_count": legal_count,
                    "method": row["method"],
                }
                gz.write((json.dumps(record, separators=(",", ":")) + "\n").encode("ascii"))
                sequence_hash.update(f"{pos}\t{symbol}\t{low}\t{high}\n".encode("ascii"))
                intervals.append((pos, symbol, low, high))
                previous = (low, high)
    if len(intervals) != 4244 or any(remaining) or opened != 45 or closed != 45:
        raise AssertionError("trace did not cover all symbols/frontiers")
    if previous != (rank_text, rank_text):
        raise AssertionError("final prefix interval is not the singleton inverse rank")
    if (endpoint_transition_seen, all_labels_seen) != (endpoint_only_at, all_labels_at):
        raise AssertionError("frontier transition disagrees with core summary")
    log(f"PREFIX_INTERVALS_PASS COUNT={len(intervals)} NESTED=4244/4244 PARTITION_ASSERTIONS_CPP=4244")
    log(f"FRONTIER_TRANSITIONS_PASS ENDPOINT_ONLY={endpoint_transition_seen} ALL_45_OPEN={all_labels_seen}")
    log(f"INTERVAL_SEQUENCE_SHA256={sequence_hash.hexdigest()}")

    if reference:
        log(f"REFERENCE_TRACE_DIFFERENTIAL_PASS MATCHED={reference['matched_intervals']}/4244 SHA256={reference['reference_trace_sha256']}")

    compressed_sha = sha256(compressed_trace.read_bytes())
    cpp_sha = sha256(cpp_path.read_bytes())
    runner_sha = sha256(Path(__file__).read_bytes())
    report = {
        "project_id": PROJECT_ID,
        "input_commit_lock": INPUT_COMMIT_LOCK,
        "verifier_commit": os.environ.get("GITHUB_SHA", "LOCAL_UNCOMMITTED"),
        "word_git_blob_sha1": word_blob,
        "word_sha256": word_sha,
        "fixture_git_blob_sha1": fixture_blob,
        "fixture_sha256": fixture_sha,
        "word_symbols": len(word),
        "month_count": len(lengths),
        "month_lengths_sum": sum(lengths),
        "month_length_min": min(lengths),
        "month_length_max": max(lengths),
        "month_lengths_provenance": "canonical pinned Git fixture; independent normative rederivation remains a separate NEXT gate",
        "root_count_digits": len(root_text),
        "root_count_sha256": sha256(root_text.encode("ascii")),
        "root_count": root_text,
        "middle_rank_digits": len(rank_text),
        "middle_rank_sha256": sha256(rank_text.encode("ascii")),
        "middle_rank": rank_text,
        "middle_rank_policy": "floor(T/2)+1",
        "prefix_intervals_verified": len(intervals),
        "prefix_interval_sequence_sha256": sequence_hash.hexdigest(),
        "prefix_interval_trace_gzip_sha256": compressed_sha,
        "endpoint_order_only_after_prefix": endpoint_transition_seen,
        "all_45_labels_open_after_prefix": all_labels_seen,
        "tiny_exhaustive_controls": {"families": tiny[0], "words": tiny[1], "distinct_prefixes": tiny[2]},
        "reference_trace_differential": reference or {"performed": False},
        "gmp_cpp_sha256": cpp_sha,
        "python_runner_sha256": runner_sha,
        "compiler": compiler,
        "core_elapsed_seconds": float(summary["ELAPSED_SECONDS"]),
        "wall_elapsed_seconds": round(elapsed_wall, 3),
        "native_matlab": False,
        "normative_month_lengths_rederived": False,
        "stage55_accepted": False,
        "last_completed_stage": 54,
    }
    report_path = out / "report.json"
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (out / "source_lock.txt").write_text(
        f"PROJECT_ID={PROJECT_ID}\nINPUT_COMMIT_LOCK={INPUT_COMMIT_LOCK}\n"
        f"WORD_GIT_BLOB_SHA1={word_blob}\nWORD_SHA256={word_sha}\n"
        f"FIXTURE_GIT_BLOB_SHA1={fixture_blob}\nFIXTURE_SHA256={fixture_sha}\n"
        f"GMP_CPP_SHA256={cpp_sha}\nPYTHON_RUNNER_SHA256={runner_sha}\n",
        encoding="ascii")
    log("SCOPE NATIVE_MATLAB=NOT_RUN NORMATIVE_MONTH_LENGTHS=NOT_REDERIVED STAGE55=OPEN LAST_COMPLETED_STAGE=54")
    log(f"STAGE55_FULL_PREFIX_INVERSE_RANK_PASS PREFIXES=4244 ROOT_SHA256={report['root_count_sha256']} RANK_SHA256={report['middle_rank_sha256']}")
    run_log.write_text("\n".join(log_lines) + "\n", encoding="utf-8")

    sums = []
    for path in sorted(out.iterdir()):
        if path.is_file() and path.name != "SHA256SUMS.txt" and path.name != binary.name and path.name != raw_trace.name and path.name != summary_path.name:
            sums.append(f"{sha256(path.read_bytes())}  {path.name}")
    (out / "SHA256SUMS.txt").write_text("\n".join(sums) + "\n", encoding="ascii")
    if not args.keep_raw:
        raw_trace.unlink(missing_ok=True)
        summary_path.unlink(missing_ok=True)
        binary.unlink(missing_ok=True)
    return report


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--word", required=True)
    parser.add_argument("--fixture", required=True)
    parser.add_argument("--cpp", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--time-limit-seconds", type=float, default=270.0)
    parser.add_argument("--reference-trace")
    parser.add_argument("--keep-raw", action="store_true")
    args = parser.parse_args()
    try:
        report = run(args)
        print(json.dumps({k: report[k] for k in (
            "project_id", "prefix_intervals_verified", "root_count_sha256",
            "middle_rank_sha256", "endpoint_order_only_after_prefix",
            "all_45_labels_open_after_prefix", "reference_trace_differential",
            "core_elapsed_seconds", "stage55_accepted", "last_completed_stage")}, indent=2))
        return 0
    except Exception as exc:
        print(f"STAGE55_FULL_PREFIX_INVERSE_RANK_FAIL {type(exc).__name__}: {exc}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    raise SystemExit(main())
