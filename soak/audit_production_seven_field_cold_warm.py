#!/usr/bin/env python3
"""Cold/warm, cross-process QA for the existing bounded post-55 date bridge.

Three independent Python workers each start a fresh JVM, recompute an independent
560-gap signed oracle, and make the previously accepted 33 requests (11 targets
in 3 orders). Novel assertion: outputs, metric traces and independently derived
gaps remain identical ACROSS fresh JVM/worker lifecycles. This is not Stage56,
TABLETS, full-date, or global algorithmic independence certification.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
from time import monotonic

import audit_production_seven_field_unseeded as original

PROJECT_ID = "PC-BRANCH-KOTLIN-CYMRAEG"
BRANCH = "Kotlin+Cymraeg"
GOOD = "PASS_BOUNDED_THREE_COLD_JVM_SESSIONS_NOT_CERTIFIED"
BAD = "FAIL_BOUNDED_THREE_COLD_JVM_SESSIONS"
WORKERS = 3
ROWS_PER_WORKER = 33
GAPS_PER_WORKER = 560
FIELDS_PER_WORKER = 165
TIMEOUT_PER_WORKER = 900


class ColdWarmError(ValueError):
    pass


def require(condition: bool, code: str) -> None:
    if not condition:
        raise ColdWarmError(code)


def digest(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


def strict_lines(raw: str, count: int, error: str) -> list[str]:
    require(isinstance(raw, str) and raw.endswith("\n") and "\r" not in raw,
            error + "_NEWLINE")
    lines = raw.splitlines()
    require(len(lines) == count, error + "_COUNT")
    return lines


def inspect_records(report: dict, stdout: str, gaps: str, metrics: str,
                    expected_sha: str) -> dict:
    """Validate a real worker's complete recorded evidence, fail closed."""
    require(type(report) is dict and report.get("status") == original.PASS,
            "E_WORKER_NOT_GREEN")
    source = report.get("source")
    require(type(source) is dict and source.get("git_sha") == expected_sha,
            "E_WORKER_SHA")
    require(report.get("project_id") == PROJECT_ID and report.get("branch") == BRANCH,
            "E_WORKER_PROJECT")
    for key, value in (
        ("production_calls", ROWS_PER_WORKER),
        ("production_columns", 7),
        ("distinct_targets", 11),
        ("order_count", 3),
        ("independent_five_field_comparisons", FIELDS_PER_WORKER),
        ("signed_gate_gap_questions", GAPS_PER_WORKER),
        ("production_gate_metric_count", ROWS_PER_WORKER),
        ("production_configured_gate_limit", 8192),
        ("production_gate_metric_max_allowed", 16385),
        ("mismatches", 0),
    ):
        require(type(report.get(key)) is int and report[key] == value,
                "E_WORKER_COUNT_" + key)
    for key in ("single_jvm_session", "order_invariance_verified",
                "production_actual_gate_count_exposed",
                "production_gate_metric_order_invariant"):
        require(report.get(key) is True, "E_WORKER_GATE_" + key)
    for key in ("checkpoint_seed_used", "pinned_reference_used",
                "shared_cross_branch_fixture_used", "full_date_certified",
                "tablets_certified", "global_algorithmic_independence_certified",
                "certifiable"):
        require(report.get(key) is False, "E_WORKER_SCOPE_" + key)
    elapsed = report.get("elapsed_seconds")
    require(type(elapsed) in (int, float) and 0 <= elapsed <= TIMEOUT_PER_WORKER,
            "E_WORKER_TIME_BUDGET")
    require(report.get("production_stdout_sha256") == digest(stdout.encode()),
            "E_WORKER_STDOUT_DIGEST")
    require(report.get("signed_gate_gap_sha256") == digest(gaps.encode()),
            "E_WORKER_GAPS_DIGEST")
    require(report.get("production_gate_metric_sha256") == digest(metrics.encode()),
            "E_WORKER_METRICS_DIGEST")

    offsets = report.get("target_offsets")
    edges = report.get("year5000_edges")
    ends = report.get("year5000_open_close")
    require(type(offsets) is list and len(offsets) == 11
            and all(type(n) is int for n in offsets), "E_TARGET_OFFSETS")
    targets = tuple(original.FOUNDATION + n for n in offsets)
    require(targets[:5] == original.TARGETS and len(set(targets)) == 11,
            "E_TARGET_SCOPE")
    require(type(edges) is list and len(edges) == 6
            and all(type(n) is int for n in edges)
            and type(ends) is list and len(ends) == 2
            and all(type(n) is int for n in ends), "E_EDGE_SHAPE")
    open_day, close_day = ends
    require(tuple(edges) == (open_day - 1, open_day, open_day + 1,
                             close_day - 1, close_day, close_day + 1)
            and targets[5:] == tuple(edges), "E_EDGE_ORDER")
    orders = original.target_orders(targets)

    output = strict_lines(stdout, ROWS_PER_WORKER, "E_STDOUT")
    groups: list[list[list[int]]] = []
    for i, order in enumerate(orders):
        group = "\n".join(output[i * 11:(i + 1) * 11]) + "\n"
        groups.append(original.parse_production(group, order))
    original.validate_order_invariance(groups, orders)
    matches = report.get("matches")
    require(type(matches) is list and len(matches) == ROWS_PER_WORKER,
            "E_MATCH_ROWS")
    position = 0
    five_by_target: dict[int, tuple[int, ...]] = {}
    seven_by_target: dict[int, tuple[int, ...]] = {}
    for group, order in zip(groups, orders):
        for row, target in zip(group, order):
            entry = matches[position]
            require(type(entry) is dict and entry.get("equal") is True
                    and entry.get("target") == target
                    and entry.get("production_seven") == row
                    and entry.get("oracle_five") == row[2:],
                    "E_MATCH_EVIDENCE")
            five = tuple(row[2:])
            seven = tuple(row)
            require(target not in five_by_target or
                    (five_by_target[target] == five and seven_by_target[target] == seven),
                    "E_INTRA_WORKER_STATE_DRIFT")
            five_by_target[target] = five
            seven_by_target[target] = seven
            position += 1
    require(len(five_by_target) == 11, "E_DISTINCT_ROWS")

    gap_pairs = []
    for line in strict_lines(gaps, GAPS_PER_WORKER, "E_GAPS"):
        parts = line.split("\t")
        require(len(parts) == 2, "E_GAP_COLS")
        gap_pairs.append((original.canonical_number(parts[0]),
                          original.canonical_number(parts[1])))
    original.validate_ledger_trace(gap_pairs)

    metric_lines = strict_lines(metrics, ROWS_PER_WORKER + 1, "E_METRICS")
    require(metric_lines.pop(0) == "order\ttarget\texpanded_gate_count",
            "E_METRIC_HEADER")
    per_target: dict[int, int] = {}
    for i, (name, order) in enumerate(zip(original.ORDER_NAMES, orders)):
        for j, target in enumerate(order):
            fields = metric_lines[i * 11 + j].split("\t")
            require(len(fields) == 3 and fields[0] == name, "E_METRIC_COLS")
            day = original.canonical_number(fields[1])
            count = original.canonical_number(fields[2])
            require(day == target and 1 <= count <= 16385,
                    "E_METRIC_ORDER_OR_BOUNDS")
            require(target not in per_target or per_target[target] == count,
                    "E_METRIC_STATE_DRIFT")
            per_target[target] = count
    require(len(per_target) == 11, "E_METRIC_DISTINCT_TARGETS")
    reported = report.get("production_expanded_gate_counts")
    require(type(reported) is list and len(reported) == 11
            and all(type(e) is dict and e.get("target") == target
                    and e.get("expanded_gate_count") == per_target[target]
                    for e, target in zip(reported, targets)), "E_METRIC_REPORT")
    return {"source": source, "five": five_by_target, "seven": seven_by_target,
            "gate_counts": per_target, "targets": targets,
            "stdout_sha256": digest(stdout.encode()),
            "gaps_sha256": digest(gaps.encode()),
            "metrics_sha256": digest(metrics.encode())}


def verify_workers(workers: list[dict]) -> dict:
    require(type(workers) is list and len(workers) == WORKERS,
            "E_WORKER_GROUP_COUNT")
    baseline = workers[0]
    for worker in workers[1:]:
        for key in ("source", "five", "seven", "gate_counts", "targets",
                    "stdout_sha256", "gaps_sha256", "metrics_sha256"):
            require(worker[key] == baseline[key], "E_CROSS_PROCESS_" + key)
    return {"distinct_targets": 11, "jvm_sessions": WORKERS,
            "seven_column_rows": ROWS_PER_WORKER * WORKERS,
            "five_field_comparisons": FIELDS_PER_WORKER * WORKERS,
            "ordered_gate_metrics": ROWS_PER_WORKER * WORKERS,
            "independent_signed_gaps": GAPS_PER_WORKER * WORKERS,
            "mismatches": 0, "per_target_expanded_gates": [
                {"target": target, "count": baseline["gate_counts"][target]}
                for target in baseline["targets"]]}


def save(path: Path, content: str) -> str:
    path.write_text(content, encoding="utf-8")
    require(path.read_text(encoding="utf-8") == content, "E_EVIDENCE_READBACK")
    return digest(content.encode())


def run(jar: Path, output_dir: Path) -> int:
    output_dir.mkdir(parents=True, exist_ok=True)
    sha = os.getenv("GITHUB_SHA", "")
    result = {"status": BAD, "project_id": PROJECT_ID, "branch": BRANCH,
              "source_sha": sha, "qa_scope": "bounded-post55-only",
              "jvm_processes_required": WORKERS, "certifiable": False,
              "full_date_certified": False, "tablets_certified": False,
              "global_algorithmic_independence_certified": False}
    start = monotonic()
    try:
        require(os.getenv("GITHUB_REF_NAME") == BRANCH
                and len(sha) == 40 and all(c in "0123456789abcdef" for c in sha),
                "E_EXACT_GITHUB_BRANCH_SHA")
        require(jar.is_file() and jar.stat().st_size > 0, "E_PRODUCTION_JAR")
        result["jar_sha256"] = digest(jar.read_bytes())
        code = Path(__file__).resolve()
        original_code = Path(original.__file__).resolve()
        result["aggregator_sha256"] = digest(code.read_bytes())
        result["worker_code_sha256"] = digest(original_code.read_bytes())
        verified = []
        worker_pids = []
        for idx in range(1, WORKERS + 1):
            prefix = "process-" + str(idx)
            paths = {label: output_dir / (prefix + "." + extension)
                     for label, extension in (("report", "json"),
                                              ("transcript", "production.tsv"),
                                              ("gaps", "gaps.tsv"),
                                              ("metrics", "metrics.tsv"))}
            cmd = [sys.executable, "-B", str(original_code), "--jar", str(jar),
                   "--timeout-seconds", str(TIMEOUT_PER_WORKER),
                   "--evidence", str(paths["report"]),
                   "--transcript", str(paths["transcript"]),
                   "--gaps", str(paths["gaps"]), "--metrics", str(paths["metrics"])]
            with subprocess.Popen(cmd, stdout=subprocess.PIPE,
                                  stderr=subprocess.PIPE, text=True,
                                  cwd=str(code.parent.parent)) as proc:
                worker_pids.append(proc.pid)
                try:
                    out, err = proc.communicate(timeout=TIMEOUT_PER_WORKER + 10)
                except subprocess.TimeoutExpired:
                    proc.kill()
                    proc.communicate()
                    raise ColdWarmError("E_WORKER_TIMEOUT_" + str(idx))
                save(output_dir / (prefix + ".stdout.log"), out)
                save(output_dir / (prefix + ".stderr.log"), err)
                require(proc.returncode == 0, "E_WORKER_EXIT_" + str(idx))
            data = json.loads(paths["report"].read_text(encoding="utf-8"))
            verified.append(inspect_records(
                data, paths["transcript"].read_text(encoding="utf-8"),
                paths["gaps"].read_text(encoding="utf-8"),
                paths["metrics"].read_text(encoding="utf-8"), sha))
        require(len(set(worker_pids)) == WORKERS, "E_WORKER_PID_REUSE")
        result["worker_python_pids"] = worker_pids
        result.update(verify_workers(verified))
        result["worker_result_json_sha256"] = [
            digest((output_dir / ("process-" + str(i) + ".json")).read_bytes())
            for i in range(1, WORKERS + 1)]
        result["worker_elapsed_seconds"] = [
            json.loads((output_dir / ("process-" + str(i) + ".json")).read_text(
                encoding="utf-8"))["elapsed_seconds"] for i in range(1, WORKERS + 1)]
        result["status"] = GOOD
    except Exception as exc:
        result["error_type"] = type(exc).__name__
        result["error"] = str(exc)[:800]
    finally:
        result["elapsed_seconds"] = round(monotonic() - start, 3)
        save(output_dir / "cold-warm-report.json",
             json.dumps(result, indent=2, sort_keys=True) + "\n")
        manifest = []
        for p in sorted(output_dir.iterdir()):
            if p.is_file() and p.name != "SHA256SUMS.txt":
                manifest.append(digest(p.read_bytes()) + "  " + p.name)
        save(output_dir / "SHA256SUMS.txt", "\n".join(manifest) + "\n")
        print(json.dumps({k: result.get(k) for k in
                          ("status", "source_sha", "jvm_sessions",
                           "seven_column_rows", "five_field_comparisons",
                           "independent_signed_gaps", "error")}, sort_keys=True))
    return 0 if result["status"] == GOOD else 2


def main(argv=None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--jar", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    return run(**vars(parser.parse_args(argv)))


if __name__ == "__main__":
    raise SystemExit(main())
