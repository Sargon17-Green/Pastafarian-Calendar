#!/usr/bin/env python3
"""QA-only controlled same-run Stage7 Candidate A vs B. Never mutates production."""
from __future__ import annotations

import csv
import json
import os
from pathlib import Path
import platform
import shutil
import statistics
import subprocess
import sys
import tempfile
import time

PROJECT = "PC-BRANCH-DART-HEBREW"
A = "1d98a83db7446ceb4548c39e0eaf9b4441b72b9a"
B = "01cf39143731782bb96cc4d9c9a7075195693344"
PLANNER = "lib/src/monster_month_weave_planner.dart"
BLOBS = {"A": "3553a7f2e3899c958d56620c5449daa35b0731e2",
         "B": "d736ca8afe3409a10474b8514284aceb154a46a9"}
EXPECTED = {
    "COUNT": "c0c08ac89c8faaaf589d1b3e076fe1e96405f2ad7172a15efa9d028fb43fb6f8",
    "FIRST": "dc2dabc1c69f5007425c032e576577195ea6cf7b1d1054a9faca74e025aaf13c",
    "LAST": "71b78eb2ce0c68252f404e6c6d34b52a2f8f2b834eb6a2eff687bbc6c0bccdd8",
    "CANONICAL": "7093c6c666dc19642d650fe7fd8a9bbe43cd12238ac4f563ebe668d370eacdda",
}
DIFF_ALLOWED = {
    PLANNER, "bin/stage7_weave_hotpath_profile.dart",
    "docs/dart_hebrew_stage7_candidate_b_feasibility_20261121.md",
}
PROBE = r"""import 'dart:io';

import '../lib/src/monster_month_lengths.dart';
import '../lib/src/monster_month_weave_counter.dart';
import '../lib/src/monster_month_weave_planner.dart';
import '../lib/src/monster_year_traversal.dart';

String digest(String payload) {
  final dir = Directory.systemTemp.createTempSync('stage7_ab_hash_');
  try {
    final file = File(dir.path + '/input');
    file.writeAsStringSync(payload, flush: true);
    final process = Process.runSync('sha256sum', <String>[file.path]);
    if (process.exitCode != 0) {
      throw StateError('sha256sum failure: ' + process.stderr.toString());
    }
    final match = RegExp(r'^[0-9a-f]{64}').firstMatch(process.stdout.toString());
    if (match == null) throw StateError('Invalid sha256sum output');
    return match.group(0)!;
  } finally {
    dir.deleteSync(recursive: true);
  }
}

void main(List<String> args) {
  if (args.length != 1 || (args[0] != 'locks' && args[0] != 'sample')) {
    throw ArgumentError('Usage: probe.dart locks|sample');
  }
  final foundation = BigInt.from(-15055671);
  final year = MonsterYearTraversal().resolve(
    foundation, foundation, maxTransitions: 0,
  );
  final lengths = const MonsterMonthLengthPlanner().plan(foundation, year);
  if (year.yearNumber != BigInt.from(5000) ||
      lengths.yearLength != 4244 ||
      lengths.monthCount != 45) {
    throw StateError('Canonical input anchor mismatch');
  }

  if (args[0] == 'locks') {
    final total = MonsterMonthWeaveCounter.countWholeWeaves(lengths.lengths);
    final first = MonsterMonthWeavePlanner.unrankFull(lengths.lengths, BigInt.one);
    final last = MonsterMonthWeavePlanner.unrankFull(lengths.lengths, total);
    final canonical = const MonsterMonthWeavePlanner().plan(
      foundation, year, lengths,
    );
    if (canonical.weaveCount != total ||
        canonical.weaveChoice.modulus != total) {
      throw StateError('Canonical count/choice mismatch');
    }
    print('LOCK COUNT ' + digest(total.toString()));
    print('LOCK FIRST ' + digest(first.join(',')));
    print('LOCK LAST ' + digest(last.join(',')));
    print('LOCK CANONICAL ' + digest(canonical.monthIds.join(',')));
    return;
  }

  final watch = Stopwatch()..start();
  final canonical = const MonsterMonthWeavePlanner().plan(
    foundation, year, lengths,
  );
  watch.stop();
  print('SAMPLE ' + watch.elapsedMicroseconds.toString() +
      ' ' + digest(canonical.monthIds.join(',')));
}
"""

def run(*args: str, cwd: Path | None = None, timeout: int = 120) -> str:
    command = [str(a) for a in args]
    result = subprocess.run(command, cwd=cwd, capture_output=True, text=True,
                            timeout=timeout, check=False)
    if result.returncode != 0:
        raise RuntimeError("command failed (%d): %s\n%s\n%s" %
                           (result.returncode, " ".join(command),
                            result.stdout[-2000:], result.stderr[-2000:]))
    return result.stdout.strip()

def lock_sources(root: Path) -> dict:
    if run("git", "rev-parse", B + "^", cwd=root) != A:
        raise RuntimeError("Candidate B does not descend directly from accepted A")
    changed = set(run("git", "diff", "--name-only", A, B, cwd=root).splitlines())
    if changed != DIFF_ALLOWED:
        raise RuntimeError("Unexpected A-vs-B source changes: " + repr(sorted(changed)))
    locks = {}
    for label, commit in (("A", A), ("B", B)):
        actual = run("git", "rev-parse", commit + ":" + PLANNER, cwd=root)
        if actual != BLOBS[label]:
            raise RuntimeError(label + " original source blob mismatch: " + actual)
        locks[label] = {"commit": commit, "planner_blob": actual}
    return locks

def dart_probe(directory: Path, mode: str):
    output = run("dart", "tool/dart_hebrew_stage7_ab_probe.dart",
                 mode, cwd=directory, timeout=150)
    matches = [line for line in output.splitlines()
               if line.startswith("LOCK ") or line.startswith("SAMPLE ")]
    if mode == "locks":
        found = {}
        for line in matches:
            parts = line.split()
            if len(parts) != 3 or parts[0] != "LOCK":
                raise RuntimeError("Malformed LOCK line: " + line)
            found[parts[1]] = parts[2]
        if found != EXPECTED:
            raise RuntimeError("Four independent output locks mismatch: " + repr(found))
        return found
    if len(matches) != 1:
        raise RuntimeError("Missing/duplicate SAMPLE: " + output[-1200:])
    parts = matches[0].split()
    if len(parts) != 3 or parts[0] != "SAMPLE" or parts[2] != EXPECTED["CANONICAL"]:
        raise RuntimeError("Sample canonical output regression: " + repr(parts))
    elapsed = int(parts[1])
    if elapsed <= 0:
        raise RuntimeError("Nonpositive sample duration")
    return elapsed

def main() -> int:
    root = Path(__file__).resolve().parent.parent
    output = root / "out" / "dart-hebrew-stage7-ab"
    output.mkdir(parents=True, exist_ok=True)
    result = {
        "project_id": PROJECT,
        "benchmark": "stage7-canonical-A-vs-B-same-run-v1",
        "qa_only": True,
        "status": "NOT_RUN",
        "head_sha": run("git", "rev-parse", "HEAD", cwd=root),
        "github_run_id": os.environ.get("GITHUB_RUN_ID"),
        "github_job": os.environ.get("GITHUB_JOB"),
        "environment": {
            "platform": platform.platform(),
            "python": platform.python_version(),
            "dart": run("dart", "--version", cwd=root) or "see stderr from job",
            "runner_os": os.environ.get("RUNNER_OS"),
            "runner_arch": os.environ.get("RUNNER_ARCH"),
        },
        "input": {"foundation": -15055671, "year": 5000,
                  "days": 4244, "months": 45, "pairs": 5,
                  "timed_scope": "MonsterMonthWeavePlanner.plan on canonical input",
                  "order": "AB, BA, AB, BA, AB"},
        "expected_output_sha256": EXPECTED,
        "samples": [],
    }
    try:
        result["source_locks"] = lock_sources(root)
        with tempfile.TemporaryDirectory(prefix="dart_hebrew_ab_") as temp:
            dirs = {}
            try:
                for label, ref in (("A", A), ("B", B)):
                    location = Path(temp) / label
                    run("git", "worktree", "add", "--detach", str(location),
                        ref, cwd=root)
                    (location / "tool").mkdir(exist_ok=True)
                    (location / "tool" / "dart_hebrew_stage7_ab_probe.dart").write_text(
                        PROBE, encoding="utf-8")
                    dirs[label] = location
                result["locks_observed"] = {
                    label: dart_probe(dirs[label], "locks") for label in ("A", "B")
                }
                result["warmup_us"] = {
                    label: dart_probe(dirs[label], "sample") for label in ("A", "B")
                }
                for i in range(5):
                    order = ("A", "B") if i % 2 == 0 else ("B", "A")
                    pair = {"pair": i + 1, "order": "".join(order)}
                    for label in order:
                        pair[label + "_us"] = dart_probe(dirs[label], "sample")
                    pair["B_minus_A_us"] = pair["B_us"] - pair["A_us"]
                    pair["B_speedup_percent"] = round(
                        100 * (pair["A_us"] - pair["B_us"]) / pair["A_us"], 5)
                    result["samples"].append(pair)
                    print("STAGE7_AB_PAIR " + json.dumps(pair, sort_keys=True),
                          flush=True)
            finally:
                for label in ("A", "B"):
                    if label in dirs:
                        subprocess.run(["git", "worktree", "remove", "--force",
                                        str(dirs[label])], cwd=root,
                                       capture_output=True, check=False)
        pairs = result["samples"]
        speedups = [p["B_speedup_percent"] for p in pairs]
        diffs = [p["B_minus_A_us"] for p in pairs]
        result["median_A_us"] = statistics.median(p["A_us"] for p in pairs)
        result["median_B_us"] = statistics.median(p["B_us"] for p in pairs)
        result["median_paired_B_minus_A_us"] = statistics.median(diffs)
        result["median_paired_B_speedup_percent"] = statistics.median(speedups)
        result["B_faster_pairs"] = sum(diff < 0 for diff in diffs)
        # A deliberately conservative decision threshold, not proof of
        # statistical significance, cross-machine portability or speedup.
        result["verdict"] = ("B_OBSERVED_BENEFIT_REVIEW"
                             if result["B_faster_pairs"] == 5
                             and statistics.median(speedups) >= 2.0
                             and min(speedups) >= 1.0
                             else "INCONCLUSIVE_DEFAULT_A")
        result["status"] = "MEASURED_NOT_STAGE_ACCEPTANCE"
        print("STAGE7_AB_SUMMARY " + json.dumps({
            "verdict": result["verdict"],
            "median_paired_speedup_pct": result["median_paired_B_speedup_percent"],
            "median_B_minus_A_us": result["median_paired_B_minus_A_us"],
            "B_faster_pairs": result["B_faster_pairs"],
        }, sort_keys=True), flush=True)
    except Exception as error:
        result["status"] = "FAILED"
        result["error"] = str(error)
        print("STAGE7_AB_FAILED " + str(error), file=sys.stderr, flush=True)
    (output / "results.json").write_text(
        json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    with (output / "pairs.csv").open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=[
            "pair", "order", "A_us", "B_us", "B_minus_A_us", "B_speedup_percent"])
        writer.writeheader()
        writer.writerows(result["samples"])
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as file:
            file.write("## Dart Hebrew Stage7 A/B (QA only)\n\n")
            file.write("Source A: " + A + " / B: " + B + "\n\n")
            file.write("Status: " + result["status"] +
                       "; verdict: " + result.get("verdict", "NONE") + "\n\n")
            file.write("The Native Stage7 acceptance remains tied to historical"
                       " source SHAs; this benchmark does not authorize merge.\n")
    return 0 if result["status"] == "MEASURED_NOT_STAGE_ACCEPTANCE" else 1

if __name__ == "__main__":
    sys.exit(main())
