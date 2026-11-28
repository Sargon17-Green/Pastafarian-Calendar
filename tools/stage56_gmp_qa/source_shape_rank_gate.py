#!/usr/bin/env python3
"""QA-only GMP rank/unrank prefix qualification on the three real Stage56 vectors.

The Python oracle is independently derived from ordered-ending combinatorics.
The PHP worker uses a GMP suffix-row engine with an eight-row checkpoint budget.
No production class is wired, no provider/year is executed, and no stage is accepted.
"""
from __future__ import annotations

import argparse
import gc
import hashlib
import itertools
import json
import math
import os
import pathlib
import resource
import signal
import subprocess
import sys
import tempfile
import time
from collections import defaultdict
from typing import Iterable

if hasattr(sys, "set_int_max_str_digits"):
    sys.set_int_max_str_digits(0)

ROOT = pathlib.Path(__file__).resolve().parents[2]
QA_DIR = ROOT / "tools" / "stage56_gmp_qa"
WORKER = QA_DIR / "source_shape_gmp_worker.php"
sys.path.insert(0, str(QA_DIR))
import row_microgate  # noqa: E402 - exact in-branch real-vector fixture and production-source lock

BASE_SOURCE_SHA = "fcaf1674d2c4125b6794fd37312f68d11aa2a8dd"
EXTERNAL_RUN_ID = 46142645805
EXTERNAL_JOB_ID = 140971780911
EXTERNAL_ARTIFACT_ID = 15263468829
EXTERNAL_ARTIFACT_SHA256 = "27f6de6de2ff525e32d5d5f7bc55ce41ebeae9d488212f5c07a6a74ee800b500"

SOURCE_BLOBS = {
    "tools/stage56_gmp_qa/row_microgate.py": "17e2ce56b7c836eb65b69951a79c6e4afaaf6a53",
    "src/BigInt.php": "3ec9a816ed2c704998018abab36efa5a8e98d20c",
    "src/Patches/MonthWeavingInterleaving56.php": "05a348188f1752c8f10699ea7b76ecd24ad44238",
    "src/Patches/YearStructureProvider56.php": "8d4afe6838a31f76a8a94f5196c8f6c9e30fe73d",
}
EXPECTED = [
    {
        "year": 4999,
        "months": 34,
        "total": 4126,
        "cells": 67743,
        "max_width": 4093,
        "state_product_digits": 71,
        "vector_sha256": "a092a613e33081084cf685467877dc49c00f6a403826e6a9fa81159e25a7a95e",
    },
    {
        "year": 5000,
        "months": 45,
        "total": 4244,
        "cells": 97394,
        "max_width": 4200,
        "state_product_digits": 89,
        "vector_sha256": "6d64022344c04935e6423aa6f96b285098d35b9b5ecb4b8c57a4c7149773a134",
    },
    {
        "year": 5001,
        "months": 46,
        "total": 5567,
        "cells": 124263,
        "max_width": 5522,
        "state_product_digits": 96,
        "vector_sha256": "7a6dfeded28c46b96de176bbe836802c7f80b03aaa2a614401991add6afcc7c6",
    },
]
MEMORY_LIMIT_BYTES = 512 * 1024 * 1024
WORKER_TIMEOUT_SECONDS = 180
ROW_LIMIT = 8
ROW_REBUILD_CELL_FACTOR = 4


def emit(record: dict) -> None:
    print(json.dumps(record, sort_keys=True, separators=(",", ":")), flush=True)


def blob_sha(path: pathlib.Path) -> str:
    data = path.read_bytes()
    return hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()


def source_lock() -> None:
    ancestor = subprocess.run(
        ["git", "merge-base", "HEAD", BASE_SOURCE_SHA],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=True,
        timeout=5,
    ).stdout.strip()
    if ancestor != BASE_SOURCE_SHA:
        raise RuntimeError(f"BASE_SOURCE_SHA_NOT_ANCESTOR expected={BASE_SOURCE_SHA} got={ancestor}")
    for relative, expected in SOURCE_BLOBS.items():
        got = blob_sha(ROOT / relative)
        if got != expected:
            raise RuntimeError(f"SOURCE_BLOB_MISMATCH {relative} expected={expected} got={got}")
    row_microgate.source_lock()


def vector_widths(lengths: list[int]) -> list[int]:
    if not lengths or len(lengths) > 47 or any(type(x) is not int or not 1 <= x <= 123 for x in lengths):
        raise ValueError("invalid length vector")
    if sum(lengths) > 5778:
        raise ValueError("length vector exceeds source limit")
    widths = [lengths[0]]
    for value in lengths[1:]:
        widths.append(widths[-1] + value - 1)
    return widths


def vector_digest(lengths: list[int]) -> str:
    return hashlib.sha256(",".join(map(str, lengths)).encode("ascii")).hexdigest()


class OrderedEndingOracle:
    """Python-int oracle from the ordered-ending decomposition, not the PHP branch kernel."""

    def __init__(self, lengths: list[int]):
        self.lengths = list(lengths)
        self.month_count = len(lengths)
        self.total_length = sum(lengths)
        self.widths = vector_widths(lengths)
        self.rows: list[list[int] | None] = [None] * self.month_count
        self.rows[-1] = [1] * (self.widths[-1] + 1)
        for index in range(self.month_count - 2, -1, -1):
            month_length = self.lengths[index + 1]
            following = self.rows[index + 1]
            assert following is not None
            row = [0]
            for old_tokens in range(self.widths[index]):
                weight = (
                    1 if old_tokens == 0 else 0
                ) if month_length == 1 else math.comb(month_length + old_tokens - 2, old_tokens)
                row.append(row[-1] + weight * following[month_length + old_tokens])
            self.rows[index] = row

    def count(self) -> int:
        if self.month_count == 1:
            return 1
        row = self.rows[0]
        assert row is not None
        return row[self.lengths[0]]

    def completion_count(self, prefix: tuple[int, ...] | list[int]) -> int:
        if not prefix:
            return self.count()
        remaining = self.lengths.copy()
        high = -1
        for month in prefix:
            if (
                type(month) is not int
                or month < 0
                or month >= self.month_count
                or month > high + 1
                or remaining[month] == 0
            ):
                return 0
            if month == high + 1:
                high = month
            if remaining[month] == 1 and any(remaining[:month]):
                return 0
            remaining[month] -= 1

        if prefix[0] != 0:
            return 0
        low = next((i for i, count in enumerate(remaining) if count > 0), self.month_count)
        if low > high:
            if high >= self.month_count - 1:
                return 1
            following = self.rows[high + 1]
            assert following is not None
            return following[self.lengths[high + 1]]

        active_total = sum(remaining[low : high + 1])
        base = 1
        cumulative = 0
        for month in range(low, high + 1):
            if remaining[month] <= 0:
                return 0
            cumulative += remaining[month]
            if month > low:
                base *= math.comb(cumulative - 1, remaining[month] - 1)
        if high >= self.month_count - 1:
            return base
        row = self.rows[high]
        assert row is not None
        return base * row[active_total + 1]

    def rank_prefix(self, prefix: tuple[int, ...] | list[int]) -> tuple[int, int]:
        if not prefix or prefix[0] != 0:
            raise ValueError("prefix must start with zero")
        rank_start = 1
        walked: list[int] = []
        for wanted in prefix:
            if type(wanted) is not int or wanted < 0 or wanted >= self.month_count:
                raise ValueError("bad symbol")
            for candidate in range(wanted):
                rank_start += self.completion_count(walked + [candidate])
            walked.append(wanted)
            count = self.completion_count(walked)
            if count == 0:
                raise ValueError("invalid prefix")
        return rank_start, self.completion_count(prefix)

    def unrank_prefix(self, rank: int, depth: int) -> tuple[tuple[int, ...], int, int]:
        total = self.count()
        if type(rank) is not int or not 1 <= rank <= total or not 1 <= depth <= self.total_length:
            raise ValueError("rank/depth")
        prefix: list[int] = []
        for _ in range(depth):
            for candidate in range(self.month_count):
                block = self.completion_count(prefix + [candidate])
                if block > 0 and rank <= block:
                    prefix.append(candidate)
                    break
                rank -= block
            else:
                raise RuntimeError("oracle unrank exhausted")
        return tuple(prefix), rank, self.completion_count(prefix)


def enumerate_legal_words(lengths: list[int]) -> Iterable[tuple[int, ...]]:
    """Exhaustive multiset permutation enumerator; constraints are checked only at leaves."""
    remaining = list(lengths)
    prefix: list[int] = []
    n = len(lengths)
    total = sum(lengths)

    def visit() -> Iterable[tuple[int, ...]]:
        if len(prefix) == total:
            first = [None] * n
            last = [None] * n
            for position, month in enumerate(prefix):
                if first[month] is None:
                    first[month] = position
                last[month] = position
            if first == sorted(first) and last == sorted(last):
                yield tuple(prefix)
            return
        for month in range(n):
            if remaining[month] == 0:
                continue
            remaining[month] -= 1
            prefix.append(month)
            yield from visit()
            prefix.pop()
            remaining[month] += 1

    yield from visit()


def small_exhaustive_selftest() -> tuple[dict, list[dict]]:
    shapes = [list(x) for n in (1, 2, 3) for x in itertools.product((1, 2, 3), repeat=n)]
    shapes += [[1, 1, 1, 1], [2, 2, 2, 2], [3, 2, 1, 2], [2, 3, 2, 3]]
    total_words = 0
    total_prefixes = 0
    cases: list[dict] = []
    for lengths in shapes:
        oracle = OrderedEndingOracle(lengths)
        words = list(enumerate_legal_words(lengths))
        prefix_counts: dict[tuple[int, ...], int] = defaultdict(int)
        for word in words:
            for depth in range(len(word) + 1):
                prefix_counts[word[:depth]] += 1
        if oracle.count() != len(words):
            raise RuntimeError(f"small count mismatch lengths={lengths} oracle={oracle.count()} brute={len(words)}")
        for prefix, expected in prefix_counts.items():
            actual = oracle.completion_count(prefix)
            if actual != expected:
                raise RuntimeError(f"small prefix mismatch lengths={lengths} prefix={prefix} actual={actual} expected={expected}")
        for ordinal, word in enumerate(words, 1):
            if oracle.rank_prefix(word) != (ordinal, 1):
                raise RuntimeError(f"small rank mismatch lengths={lengths} ordinal={ordinal}")
            if oracle.unrank_prefix(ordinal, len(word)) != (word, 1, 1):
                raise RuntimeError(f"small unrank mismatch lengths={lengths} ordinal={ordinal}")
        total_words += len(words)
        total_prefixes += len(prefix_counts)
        cases.append(
            {
                "lengths": lengths,
                "count": str(len(words)),
                "words": [list(word) for word in words],
                "prefix_counts": [
                    {"prefix": list(prefix), "count": str(count)}
                    for prefix, count in sorted(prefix_counts.items(), key=lambda item: (len(item[0]), item[0]))
                ],
            }
        )
    summary = {"shapes": len(shapes), "legal_words": total_words, "distinct_prefixes": total_prefixes, "status": "PASS"}
    return summary, cases


def make_prefix_samples(
    lengths: list[int], oracle: OrderedEndingOracle, small_cases: list[dict] | None = None, small_summary: dict | None = None
) -> tuple[dict, dict]:
    total = oracle.count()
    depth = min(32, oracle.total_length)
    sample_ranks = sorted({2, (total + 1) // 2, total - 1, total})
    samples = []
    expected_samples = []
    for rank in sample_ranks:
        prefix, residual, completion = oracle.unrank_prefix(rank, depth)
        rank_start, rank_count = oracle.rank_prefix(prefix)
        if rank_start + residual - 1 != rank or rank_count != completion:
            raise RuntimeError("oracle rank/unrank prefix relation failed")
        samples.append({"rank": str(rank), "depth": depth})
        expected_samples.append(
            {
                "root_rank": str(rank),
                "prefix": list(prefix),
                "residual_rank": str(residual),
                "unrank_completion_count": str(completion),
                "rank_start": str(rank_start),
                "rank_completion_count": str(rank_count),
            }
        )

    boundary_indices = sorted(
        i for i in {0, 1, 7, 8, 9, 15, 16, 17, 23, 24, 25, 31, 32, 33, 39, 40, 41, len(lengths) - 2, len(lengths) - 1}
        if 0 <= i < len(lengths)
    )
    boundary_prefixes = []
    expected_boundaries = []
    for high in boundary_indices:
        prefix = tuple(month for month in range(high) for _ in range(lengths[month])) + (high,)
        count = oracle.completion_count(prefix)
        if count <= 0:
            raise RuntimeError(f"boundary prefix unexpectedly invalid high={high}")
        # All earlier IDs are closed before the first occurrence of high:
        # this is the lexicographically first prefix at that depth.
        boundary_prefixes.append({"high": high, "prefix": list(prefix)})
        expected_boundaries.append(
            {"high": high, "depth": len(prefix), "completion_count": str(count), "rank_start": "1"}
        )

    two_left = tuple(month for month in range(len(lengths)) for _ in range(lengths[month] - 2))
    one_left = tuple(month for month in range(len(lengths)) for _ in range(lengths[month] - 1))
    two_count = oracle.completion_count(two_left)
    one_count = oracle.completion_count(one_left)
    if two_count <= 0 or one_count != 1:
        raise RuntimeError("long-prefix oracle boundary mismatch")

    invalid_prefixes = [
        [1],
        [0, 2],
        [0, 1] + [1] * (lengths[1] - 1),
    ]
    for prefix in invalid_prefixes:
        if oracle.completion_count(prefix) != 0:
            raise RuntimeError(f"invalid prefix accepted by oracle: {prefix[:8]}")

    grouped_word = tuple(month for month in range(len(lengths)) for _ in range(lengths[month]))
    if oracle.completion_count(grouped_word) != 1:
        raise RuntimeError("grouped lexicographic-first word must have exactly one completion")

    payload = {
        "lengths": lengths,
        "samples": samples,
        "boundary_prefixes": boundary_prefixes,
        "two_left_prefix": list(two_left),
        "one_left_prefix": list(one_left),
        "invalid_prefixes": invalid_prefixes,
    }
    if small_cases is not None:
        payload["small_cases"] = small_cases
    expected = {
        "root_count": str(total),
        "samples": expected_samples,
        "boundary_prefixes": expected_boundaries,
        "two_left": {"depth": len(two_left), "completion_count": str(two_count)},
        "one_left": {"depth": len(one_left), "completion_count": "1"},
        "full_rank1": {
            "depth": len(grouped_word),
            "word_matches_grouped": True,
            "residual_rank": "1",
            "completion_count": "1",
            "rank_start": "1",
            "rank_completion_count": "1",
        },
        "invalid_prefixes": [
            {"completion_count": "0", "rank_rejected": True} for _ in invalid_prefixes
        ],
        "invalid_ranks_rejected": [True, True],
    }
    if small_summary is not None:
        expected["small_selftest"] = small_summary
    return payload, expected


def run_php_worker(payload: dict) -> tuple[dict, dict]:
    lint = subprocess.run(["php", "-l", str(WORKER)], cwd=ROOT, capture_output=True, text=True, timeout=10)
    if lint.returncode != 0 or lint.stderr:
        raise RuntimeError(f"PHP worker lint failed: {lint.stdout} {lint.stderr}")
    probe = subprocess.run(
        ["php", "-r", "echo extension_loaded('gmp') ? 'yes' : 'no';"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=5,
    )
    if probe.returncode != 0 or probe.stderr:
        raise RuntimeError("PHP GMP probe failed")
    if probe.stdout.strip() != "yes":
        return {"status": "NOT_RUN", "reason": "GMP extension missing"}, {"rss_bytes": 0, "elapsed_ns": 0}

    def limits() -> None:
        resource.setrlimit(resource.RLIMIT_AS, (MEMORY_LIMIT_BYTES, MEMORY_LIMIT_BYTES))
        resource.setrlimit(resource.RLIMIT_CPU, (WORKER_TIMEOUT_SECONDS, WORKER_TIMEOUT_SECONDS + 1))
        resource.setrlimit(resource.RLIMIT_CORE, (0, 0))

    payload_text = json.dumps(payload, separators=(",", ":"))
    with tempfile.TemporaryDirectory(prefix="stage56-source-shape-") as temporary:
        time_path = pathlib.Path(temporary) / "rss-kib.txt"
        command = [
            "/usr/bin/time",
            "-f",
            "%M",
            "-o",
            str(time_path),
            "php",
            "-d",
            "memory_limit=512M",
            str(WORKER),
        ]
        started = time.monotonic_ns()
        process = subprocess.Popen(
            command,
            cwd=ROOT,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            preexec_fn=limits,
            start_new_session=True,
        )
        try:
            stdout, stderr = process.communicate(payload_text, timeout=WORKER_TIMEOUT_SECONDS + 5)
        except subprocess.TimeoutExpired:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            process.communicate()
            raise RuntimeError(f"PHP worker exceeded {WORKER_TIMEOUT_SECONDS}s watchdog")
        elapsed = time.monotonic_ns() - started
        if process.returncode != 0 or stderr:
            raise RuntimeError(
                f"PHP worker exit={process.returncode} stderr={stderr[-2000:]} stdout={stdout[-2000:]}"
            )
        result = json.loads(stdout)
        rss_bytes = int(time_path.read_text(encoding="ascii").strip()) * 1024
        metrics = {
            "rss_bytes": rss_bytes,
            "elapsed_ns": elapsed,
            "stdout_sha256": hashlib.sha256(stdout.encode("utf-8")).hexdigest(),
            "stderr_bytes": len(stderr.encode("utf-8")),
        }
        return result, metrics


def compare_worker(year: int, lengths: list[int], result: dict, expected: dict, external_metrics: dict) -> dict:
    if result.get("status") != "SOURCE_SHAPE_GMP_RANK_RESULT":
        raise RuntimeError(f"worker status mismatch year={year}: {result.get('status')}")
    keys = ["root_count", "samples", "boundary_prefixes", "two_left", "one_left", "full_rank1", "invalid_prefixes", "invalid_ranks_rejected"]
    if "small_selftest" in expected:
        keys.append("small_selftest")
    for key in keys:
        if result.get(key) != expected[key]:
            raise RuntimeError(f"worker/oracle mismatch year={year} field={key}")
    if result.get("php_int_size") != 8:
        raise RuntimeError(f"PHP is not 64-bit year={year}")
    metrics = result.get("metrics") or {}
    if metrics.get("planned_cells") != expected["cells"]:
        raise RuntimeError(f"planned DP cells mismatch year={year}")
    if metrics.get("max_live_rows", ROW_LIMIT + 1) > ROW_LIMIT:
        raise RuntimeError(f"live row budget exceeded year={year}: {metrics.get('max_live_rows')}")
    if metrics.get("max_stored_rows", ROW_LIMIT + 1) > ROW_LIMIT:
        raise RuntimeError(f"stored row budget exceeded year={year}: {metrics.get('max_stored_rows')}")
    if metrics.get("cells_built", 10**30) > ROW_REBUILD_CELL_FACTOR * expected["cells"]:
        raise RuntimeError(f"row rebuild cell budget exceeded year={year}: {metrics.get('cells_built')}")
    if metrics.get("php_peak_bytes", MEMORY_LIMIT_BYTES + 1) > MEMORY_LIMIT_BYTES:
        raise RuntimeError(f"PHP allocated-memory cap exceeded year={year}")
    if external_metrics["rss_bytes"] > MEMORY_LIMIT_BYTES:
        raise RuntimeError(f"OS RSS cap exceeded year={year}")
    if metrics.get("elapsed_ns", 10**30) > WORKER_TIMEOUT_SECONDS * 1_000_000_000:
        raise RuntimeError(f"worker internal time cap exceeded year={year}")
    if external_metrics["elapsed_ns"] > (WORKER_TIMEOUT_SECONDS + 5) * 1_000_000_000:
        raise RuntimeError(f"worker watchdog time cap exceeded year={year}")
    return {
        "year": year,
        "months": len(lengths),
        "total": sum(lengths),
        "vector_sha256": vector_digest(lengths),
        "oracle_cells": expected["cells"],
        "state_product_digits": expected["state_product_digits"],
        "root_count_digits": len(expected["root_count"]),
        "sample_count": len(expected["samples"]),
        "boundary_prefix_count": len(expected["boundary_prefixes"]),
        "metrics": metrics,
        "process_metrics": external_metrics,
        "php_version": result["php_version"],
        "gmp_version": result["gmp_version"],
        "gmp_library": result["gmp_library"],
        "status": "PASS",
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", required=True)
    args = parser.parse_args()
    output_dir = pathlib.Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    if not sys.platform.startswith("linux"):
        raise RuntimeError("Linux is required for the process RSS and address-space caps")
    source_lock()
    selftest, small_cases = small_exhaustive_selftest()
    emit({"type": "small_exhaustive_selftest", **selftest})

    probe = subprocess.run(
        ["php", "-r", "echo extension_loaded('gmp') ? 'yes' : 'no';"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=5,
    )
    if probe.returncode != 0 or probe.stderr:
        raise RuntimeError("PHP GMP probe failed")
    if probe.stdout.strip() != "yes":
        record = {
            "status": "NOT_RUN",
            "reason": "GMP extension missing; no fallback is permitted",
            "project_id": "PC-BRANCH-PHP-MALAY",
            "base_source_sha": BASE_SOURCE_SHA,
            "small_exhaustive_selftest": selftest,
        }
        (output_dir / "result.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
        emit(record)
        return 77

    vector_results = []
    for meta, lengths in zip(EXPECTED, row_microgate.LARGE, strict=True):
        widths = vector_widths(lengths)
        product_states = math.prod(value + 1 for value in lengths)
        actual = {
            "year": meta["year"],
            "months": len(lengths),
            "total": sum(lengths),
            "cells": sum(widths[:-1]),
            "max_width": max(widths),
            "state_product_digits": len(str(product_states)),
            "vector_sha256": vector_digest(lengths),
        }
        for key in ("year", "months", "total", "cells", "max_width", "state_product_digits", "vector_sha256"):
            if actual[key] != meta[key]:
                raise RuntimeError(f"source vector mismatch {meta['year']} field={key} got={actual[key]} expected={meta[key]}")

        oracle = OrderedEndingOracle(lengths)
        payload, expected = make_prefix_samples(
            lengths, oracle, small_cases if meta["year"] == 4999 else None, selftest if meta["year"] == 4999 else None
        )
        expected["cells"] = actual["cells"]
        expected["state_product_digits"] = actual["state_product_digits"]
        oracle_memory = sum(
            sys.getsizeof(row) + sum(sys.getsizeof(value) for value in row)
            for row in oracle.rows
            if row is not None
        )
        oracle_count_digits = len(str(oracle.count()))
        result, process_metrics = run_php_worker(payload)
        if result.get("status") == "NOT_RUN":
            record = {"status": "NOT_RUN", "reason": result.get("reason"), "year": meta["year"]}
            (output_dir / f"worker-{meta['year']}.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
            (output_dir / "result.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
            emit(record)
            return 77
        summary = compare_worker(meta["year"], lengths, result, expected, process_metrics)
        summary["oracle_rows_memory_bytes"] = oracle_memory
        summary["oracle_rows_memory_mib"] = round(oracle_memory / (1024 * 1024), 3)
        summary["oracle_root_count_digits"] = oracle_count_digits
        summary["source_artifact"] = {
            "run_id": EXTERNAL_RUN_ID,
            "job_id": EXTERNAL_JOB_ID,
            "artifact_id": EXTERNAL_ARTIFACT_ID,
            "artifact_sha256": EXTERNAL_ARTIFACT_SHA256,
        }
        vector_results.append(summary)
        (output_dir / f"worker-{meta['year']}.json").write_text(
            json.dumps({"summary": summary, "worker": result}, indent=2) + "\n", encoding="utf-8"
        )
        emit({"type": "source_shape", **summary})
        del oracle
        gc.collect()

    record = {
        "status": "SOURCE_SHAPE_GMP_RANK_PASS",
        "qualification": "BOUNDED_PREFIX_AND_RANK_ONLY_NOT_STAGE56_ACCEPTANCE",
        "project_id": "PC-BRANCH-PHP-MALAY",
        "base_source_sha": BASE_SOURCE_SHA,
        "external_source_evidence": {
            "run_id": EXTERNAL_RUN_ID,
            "job_id": EXTERNAL_JOB_ID,
            "artifact_id": EXTERNAL_ARTIFACT_ID,
            "artifact_sha256": EXTERNAL_ARTIFACT_SHA256,
        },
        "small_exhaustive_selftest": selftest,
        "resource_gates": {
            "php_memory_limit_bytes": MEMORY_LIMIT_BYTES,
            "os_address_space_limit_bytes": MEMORY_LIMIT_BYTES,
            "os_rss_limit_bytes": MEMORY_LIMIT_BYTES,
            "worker_timeout_seconds": WORKER_TIMEOUT_SECONDS,
            "max_live_dp_rows": ROW_LIMIT,
            "max_stored_dp_rows": ROW_LIMIT,
            "max_row_rebuild_cells_factor": ROW_REBUILD_CELL_FACTOR,
        },
        "vectors": vector_results,
        "explicitly_not_run": [
            "full-year provider execution",
            "paired full-year comparison",
            "production source modification or dependency wiring",
            "PATCH22/PATCH23/main/merge/publication",
        ],
    }
    (output_dir / "result.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    emit({"status": record["status"], "vectors": len(vector_results), "selftest": selftest})
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (RuntimeError, ValueError, OSError, subprocess.TimeoutExpired) as error:
        emit({"status": "FAIL", "error": str(error)})
        sys.exit(1)
