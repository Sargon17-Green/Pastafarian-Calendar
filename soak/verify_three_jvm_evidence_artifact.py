#!/usr/bin/env python3
"""Standalone byte-level auditor for bounded post55 Kotlin+Cymraeg CI artifacts.

This validates archive integrity, recorded production transcripts, per-worker
and cross-worker consistency, but does NOT recompute the independent calendar
oracle or certify full-date behavior. No external dependencies or network calls.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys
import zipfile

PROJECT = "PC-BRANCH-KOTLIN-CYMRAEG"
BRANCH = "Kotlin+Cymraeg"
PASS = "PASS_BOUNDED_THREE_COLD_JVM_SESSIONS_NOT_CERTIFIED"
CHECK = "PASS_POST55_ARTIFACT_INTEGRITY_ONLY_NOT_CERTIFIED"
HEX40 = re.compile(r"[0-9a-f]{40}\Z")
HEX64 = re.compile(r"[0-9a-f]{64}\Z")
INTEGER = re.compile(r"(?:0|-?[1-9][0-9]*)\Z")
EXPECTED_PIDS = 3
EXPECTED_WORKER_ROWS = 33
EXPECTED_TARGETS = 11
EXPECTED_GAPS = 560
EXPECTED_METRICS = 33
EXPECTED_JAR_BUDGET = 8192
EXPECTED_SECONDS = 900
MAX_ZIP_SIZE = 2_000_000
MAX_MEMBER_SIZE = 2_000_000


class AuditError(ValueError):
    pass


def need(condition: bool, code: str) -> None:
    if not condition:
        raise AuditError(code)


def sha256(blob: bytes) -> str:
    return hashlib.sha256(blob).hexdigest()


def canonical_int(s: str) -> int:
    need(isinstance(s, str) and INTEGER.fullmatch(s) is not None, "E_CANONICAL_INT")
    return int(s)


def lines(blob: bytes, count: int, code: str) -> list[str]:
    try:
        s = blob.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise AuditError(code + "_UTF8") from exc
    need(s.endswith("\n") and "\r" not in s, code + "_LINE_ENDINGS")
    result = s.splitlines()
    need(len(result) == count, code + "_LINE_COUNT")
    return result


def load_json(blob: bytes) -> dict:
    try:
        obj = json.loads(blob.decode("utf-8"))
    except (UnicodeDecodeError, ValueError) as exc:
        raise AuditError("E_JSON") from exc
    need(type(obj) is dict, "E_JSON_OBJECT")
    return obj


def eq_int(obj: dict, key: str, wanted: int, code: str) -> None:
    need(type(obj.get(key)) is int and obj[key] == wanted, code)


def validate_worker(archive: dict[str, bytes], number: int, sha: str,
                    jar_sha: str) -> dict:
    prefix = f"cold-warm/process-{number}."
    report = load_json(archive[prefix + "json"])
    source = report.get("source")
    need(type(source) is dict and source.get("git_sha") == sha
         and source.get("jar_sha256") == jar_sha, "E_WORKER_PROVENANCE")
    need(report.get("status") == "PASS_BOUNDED_UNSEEDED_THREE_ORDER_YEAR_EDGE_NOT_CERTIFIED"
         and report.get("project_id") == PROJECT and report.get("branch") == BRANCH,
         "E_WORKER_SCOPE")
    for key, expected in (
        ("production_calls", 33), ("production_columns", 7),
        ("distinct_targets", 11), ("order_count", 3),
        ("independent_five_field_comparisons", 165),
        ("signed_gate_gap_questions", 560),
        ("production_gate_metric_count", 33),
        ("production_configured_gate_limit", EXPECTED_JAR_BUDGET),
        ("production_gate_metric_max_allowed", 16385), ("mismatches", 0),
    ):
        eq_int(report, key, expected, "E_WORKER_COUNT_" + key)
    for key in ("single_jvm_session", "order_invariance_verified",
                "production_actual_gate_count_exposed",
                "production_gate_metric_order_invariant"):
        need(report.get(key) is True, "E_WORKER_ASSERT_" + key)
    for key in ("checkpoint_seed_used", "pinned_reference_used",
                "shared_cross_branch_fixture_used", "full_date_certified",
                "tablets_certified", "global_algorithmic_independence_certified",
                "certifiable"):
        need(report.get(key) is False, "E_WORKER_CERTIFICATION_SCOPE")
    elapsed = report.get("elapsed_seconds")
    need(type(elapsed) in (int, float) and 0 <= elapsed <= EXPECTED_SECONDS,
         "E_WORKER_DURATION")

    stdout = archive[prefix + "production.tsv"]
    metrics = archive[prefix + "metrics.tsv"]
    gaps = archive[prefix + "gaps.tsv"]
    need(report.get("production_stdout_sha256") == sha256(stdout)
         and report.get("production_gate_metric_sha256") == sha256(metrics)
         and report.get("signed_gate_gap_sha256") == sha256(gaps),
         "E_WORKER_CONTENT_HASHES")

    rows = [tuple(canonical_int(v) for v in row.split("\t"))
            for row in lines(stdout, EXPECTED_WORKER_ROWS, "E_PRODUCTION")]
    need(all(len(row) == 7 and row[0] == report.get("calculation_day")
                 for row in rows), "E_PRODUCTION_COLUMNS_OR_ECHO")
    targets = [row[1] for row in rows[:EXPECTED_TARGETS]]
    need(len(set(targets)) == EXPECTED_TARGETS, "E_DISTINCT_TARGETS")
    order_targets = [targets, list(reversed(targets)),
                     [row[1] for row in rows[22:]]]
    need(set(order_targets[2]) == set(targets) and
         len(set(order_targets[2])) == EXPECTED_TARGETS,
         "E_INTERLEAVED_BIJECTION")
    for i, order in enumerate(order_targets):
        segment = rows[11 * i:11 * (i + 1)]
        need([row[1] for row in segment] == order, "E_ORDER")
    by_target = {}
    for row in rows:
        if row[1] in by_target:
            need(by_target[row[1]] == row, "E_PRODUCTION_ORDER_DRIFT")
        by_target[row[1]] = row

    entries = report.get("matches")
    need(type(entries) is list and len(entries) == 33, "E_MATCH_COUNT")
    for row, entry in zip(rows, entries):
        need(type(entry) is dict and entry.get("target") == row[1]
             and entry.get("production_seven") == list(row)
             and entry.get("oracle_five") == list(row[2:])
             and entry.get("equal") is True, "E_MATCH_EVIDENCE")

    rows_metrics = lines(metrics, EXPECTED_METRICS + 1, "E_METRICS")
    need(rows_metrics.pop(0) == "order\ttarget\texpanded_gate_count", "E_METRIC_HEADER")
    gate_counts = {}
    for pos, row in enumerate(rows_metrics):
        cells = row.split("\t")
        need(len(cells) == 3, "E_METRIC_COLUMNS")
        name, target, count = cells
        need(name == ("natural", "reverse", "interleaved")[pos // 11],
             "E_METRIC_ORDER")
        t, c = canonical_int(target), canonical_int(count)
        need(t == rows[pos][1] and 1 <= c <= 16385, "E_METRIC_VALUE")
        if t in gate_counts:
            need(gate_counts[t] == c, "E_METRIC_STATE_DRIFT")
        gate_counts[t] = c
    need(len(gate_counts) == EXPECTED_TARGETS, "E_METRIC_DISTINCT")
    reported = report.get("production_expanded_gate_counts")
    need(type(reported) is list and len(reported) == EXPECTED_TARGETS,
         "E_METRIC_REPORT_COUNT")
    for target, elem in zip(targets, reported):
        need(type(elem) is dict and elem.get("target") == target
             and elem.get("expanded_gate_count") == gate_counts[target],
             "E_METRIC_REPORT_DRIFT")

    gap_pairs = [tuple(canonical_int(n) for n in line.split("\t"))
                 for line in lines(gaps, EXPECTED_GAPS, "E_GAPS")]
    expected = list(range(-1, -281, -1)) + list(range(1, 281))
    need(all(len(pair) == 2 for pair in gap_pairs), "E_GAP_COLUMNS")
    need([idx for idx, _ in gap_pairs] == expected
         and all(42 <= gap <= 963 for _, gap in gap_pairs),
         "E_SIGNED_GAP_SEQUENCE")
    return {"production": stdout, "metrics": metrics, "gaps": gaps,
            "gate_counts": gate_counts, "elapsed": elapsed,
            "json_sha": sha256(archive[prefix + "json"])}


def audit_zip(path: Path, expected_sha: str, expected_digest: str) -> dict:
    need(HEX40.fullmatch(expected_sha) is not None, "E_EXPECTED_SHA")
    need(HEX64.fullmatch(expected_digest) is not None, "E_EXPECTED_DIGEST")
    need(path.is_file() and path.stat().st_size <= MAX_ZIP_SIZE, "E_ARCHIVE_SIZE")
    raw = path.read_bytes()
    need(sha256(raw) == expected_digest, "E_ARTIFACT_SHA256")
    try:
        with zipfile.ZipFile(path) as z:
            infos = z.infolist()
            names = [i.filename for i in infos]
            need(len(names) == len(set(names)) and len(names) == 22,
                 "E_MEMBER_COUNT_OR_DUPLICATE")
            need(all(not i.is_dir() and i.file_size <= MAX_MEMBER_SIZE
                     and not i.filename.startswith("/")
                     and ".." not in i.filename.split("/") for i in infos),
                 "E_UNSAFE_MEMBER")
            need(z.testzip() is None, "E_ZIP_CRC")
            content = {name: z.read(name) for name in names}
    except (zipfile.BadZipFile, RuntimeError) as exc:
        raise AuditError("E_ZIP_FORMAT") from exc

    manifest = lines(content.get("cold-warm/SHA256SUMS.txt", b""), 20, "E_MANIFEST")
    seen = set()
    for line in manifest:
        need("  " in line, "E_MANIFEST_FORMAT")
        sha, name = line.split("  ", 1)
        need(HEX64.fullmatch(sha) is not None and "/" not in name
             and name and name not in seen, "E_MANIFEST_RECORD")
        seen.add(name)
        need(sha256(content.get("cold-warm/" + name, b"")) == sha,
             "E_MANIFEST_CONTENT")
    need(set(content) == {"cold-warm/SHA256SUMS.txt", "cold-warm-run.log"} |
         {"cold-warm/" + name for name in seen}, "E_MANIFEST_COVERAGE")
    summary = load_json(content["cold-warm/cold-warm-report.json"])
    need(summary.get("project_id") == PROJECT
         and summary.get("branch") == BRANCH
         and summary.get("source_sha") == expected_sha
         and summary.get("status") == PASS
         and summary.get("qa_scope") == "bounded-post55-only",
         "E_SUMMARY_SCOPE")
    for key in ("certifiable", "full_date_certified", "tablets_certified",
                "global_algorithmic_independence_certified"):
        need(summary.get(key) is False, "E_SUMMARY_CERTIFICATION")
    for key, value in (("jvm_processes_required", 3), ("jvm_sessions", 3),
                       ("distinct_targets", 11), ("seven_column_rows", 99),
                       ("five_field_comparisons", 495),
                       ("ordered_gate_metrics", 99),
                       ("independent_signed_gaps", 1680), ("mismatches", 0)):
        eq_int(summary, key, value, "E_SUMMARY_COUNT_" + key)
    need(type(summary.get("worker_python_pids")) is list
         and len(summary["worker_python_pids"]) == 3
         and all(type(pid) is int and pid > 0 for pid in summary["worker_python_pids"])
         and len(set(summary["worker_python_pids"])) == 3,
         "E_WORKER_PID_EVIDENCE")
    jar = summary.get("jar_sha256")
    need(isinstance(jar, str) and HEX64.fullmatch(jar) is not None,
         "E_JAR_DIGEST")
    workers = [validate_worker(content, i, expected_sha, jar) for i in (1, 2, 3)]
    first = workers[0]
    for next_worker in workers[1:]:
        for key in ("production", "metrics", "gaps", "gate_counts"):
            need(next_worker[key] == first[key], "E_CROSS_WORKER_" + key)
    need(summary.get("worker_result_json_sha256") == [w["json_sha"] for w in workers]
         and summary.get("worker_elapsed_seconds") == [w["elapsed"] for w in workers],
         "E_WORKER_SUMMARY_READBACK")
    reported = summary.get("per_target_expanded_gates")
    need(type(reported) is list and len(reported) == EXPECTED_TARGETS,
         "E_GATE_SUMMARY_COUNT")
    for target, entry in zip(list(first["gate_counts"]), reported):
        need(type(entry) is dict and entry.get("target") == target
             and entry.get("count") == first["gate_counts"][target],
             "E_GATE_SUMMARY_CONTENT")
    need(type(summary.get("elapsed_seconds")) in (float, int)
         and 0 <= summary["elapsed_seconds"] <= 3 * EXPECTED_SECONDS + 60,
         "E_AGGREGATOR_DURATION")
    return {"status": CHECK, "project_id": PROJECT, "source_sha": expected_sha,
            "artifact_sha256": expected_digest, "manifest_entries": len(seen),
            "jvm_sessions_reported": 3, "python_worker_pids_distinct": 3,
            "production_rows": 99, "production_columns": 7,
            "gate_metric_rows": 99, "five_field_comparisons_reported": 495,
            "signed_gap_rows": 1680, "cross_worker_transcripts_identical": True,
            "mismatches": 0, "certifies_full_date": False,
            "independently_recomputes_oracle": False}


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--zip", type=Path, required=True)
    p.add_argument("--source-sha", required=True)
    p.add_argument("--artifact-sha256", required=True)
    args = p.parse_args(argv)
    try:
        report = audit_zip(args.zip, args.source_sha, args.artifact_sha256)
    except (AuditError, OSError, KeyError, TypeError) as exc:
        print(json.dumps({"status": "FAIL_POST55_ARTIFACT_INTEGRITY",
                          "error": str(exc)}, sort_keys=True))
        return 2
    print(json.dumps(report, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())