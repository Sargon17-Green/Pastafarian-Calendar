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
PROBE = r"""import '../lib/src/monster_month_weave_planner.dart';

void main(List<String> args) {
  if (args.length != 2 ||
      (args[0] != 'trace' && args[0] != 'sample') ||
      (args[1] != '443' && args[1] != '444')) {
    throw ArgumentError('Usage: stage7_target_probe.dart trace|sample 443|444');
  }
  final lengths = args[1] == '443' ? <int>[4, 4, 3] : <int>[4, 4, 4];
  final rank = BigInt.from(args[1] == '443' ? 57 : 127);
  if (args[0] == 'trace') {
    final word = MonsterMonthWeavePlanner.unrankFull(lengths, rank);
    print('WORD|' + word.join(','));
    return;
  }
  for (var i = 0; i < 500; i++) {
    MonsterMonthWeavePlanner.unrankFull(lengths, rank);
  }
  final watch = Stopwatch()..start();
  List<int> word = <int>[];
  for (var i = 0; i < 5000; i++) {
    word = MonsterMonthWeavePlanner.unrankFull(lengths, rank);
  }
  watch.stop();
  print('SAMPLE|' + watch.elapsedMicroseconds.toString() + '|' + word.join(','));
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


def replace_once(source: str, old: str, new: str) -> str:
    if source.count(old) != 1:
        raise RuntimeError("Trace anchor not unique: " + old[:70])
    return source.replace(old, new, 1)


def instrument(source: str, label: str) -> str:
    source = replace_once(
        source, "final childBases = _activeChildren(active, activeBase);",
        "final childBases = _activeChildren(active, activeBase);\n"
        "        print('ACTIVE|' + day.toString() + '|' + ordinal.toString() +"
        " '|' + opened.toString() + '|' + closed.toString() +"
        " '|' + childBases[0].toString());")
    if label == "A":
        anchor = ("final factor = ordinal == BigInt.one\n"
                  "            ? BigInt.one\n"
                  "            : _unopenedFactor(remaining, opened, activeLength - 1);")
        source = replace_once(
            source, anchor,
            anchor + "\n"
            "        if (ordinal != BigInt.one) {\n"
            "          print('FACTOR|' + day.toString() + '|' + factor.toString());\n"
            "        } else {\n"
            "          print('SHORTCUT|' + day.toString() + '|' +"
            " ordinal.toString() + '|' + childBases[0].toString());\n"
            "        }")
    else:
        anchor = "if (ordinal <= childBases[0]) {"
        source = replace_once(source, anchor, anchor + "\n"
                              "          print('SHORTCUT|' + day.toString() +"
                              " '|' + ordinal.toString() + '|' +"
                              " childBases[0].toString());")
        anchor = "final factor = _unopenedFactor(remaining, opened, activeLength - 1);"
        source = replace_once(
            source, anchor,
            anchor + "\n"
            "          print('FACTOR|' + day.toString() + '|' + factor.toString());")
    source = replace_once(
        source, "result.add(chosen + 1);",
        "result.add(chosen + 1);\n"
        "      print('CHOSEN|' + day.toString() + '|' +"
        " (chosen + 1).toString());")
    return source


CASES = {
    "443": {"lengths": (4, 4, 3), "rank": 57,
            "count": 461, "factor": 15},
    "444": {"lengths": (4, 4, 4), "rank": 127,
            "count": 1301, "factor": 35},
}
ORACLE_BLOB = "575569a9d96b217675f5b858443f509e3149e56b"
BASELINE_HEAD = "b2a1ca8d94aeab09ecda7d45ef388f54c2ca1325"


def parse_trace(raw: str, label: str, key: str, oracle_word: tuple) -> dict:
    events = []
    word_lines = []
    for line in raw.splitlines():
        if line.startswith(("ACTIVE|", "FACTOR|", "SHORTCUT|", "CHOSEN|")):
            events.append(line.split("|"))
        elif line.startswith("WORD|"):
            word_lines.append(tuple(map(int, line[5:].split(","))))
    if len(word_lines) != 1 or word_lines[0] != oracle_word:
        raise RuntimeError("Dart trace word/oracle mismatch: " + label + key)
    steps = [{"day": d, "factors": [], "shortcuts": [], "active": [], "chosen": []}
             for d in range(len(oracle_word))]
    for parts in events:
        kind = parts[0]
        day = int(parts[1])
        if day < 0 or day >= len(steps):
            raise RuntimeError("Invalid trace day")
        steps[day][{"FACTOR": "factors", "SHORTCUT": "shortcuts",
                    "ACTIVE": "active", "CHOSEN": "chosen"}[kind]].append(
                        list(map(int, parts[2:])))
    if [s["chosen"][0][0] for s in steps if len(s["chosen"]) == 1] != list(oracle_word):
        raise RuntimeError("Incomplete trace/word mismatch " + label + key)
    for s in steps:
        if len(s["chosen"]) != 1:
            raise RuntimeError("Duplicate/missing chosen day")
        if len(s["factors"]) + len(s["shortcuts"]) > 1:
            raise RuntimeError("Overlapping factor/shortcut instrumentation")
    witness = steps[3]
    if len(witness["active"]) != 1 or witness["active"][0][0] != 2:
        raise RuntimeError("Witness residual rank missing")
    if witness["active"][0][3] != 3:
        raise RuntimeError("Witness child base mismatch")
    if label == "A":
        if witness["factors"] != [[CASES[key]["factor"]]] or witness["shortcuts"]:
            raise RuntimeError("A failed to calculate expected factor")
    else:
        if witness["shortcuts"] != [[2, 3]] or witness["factors"]:
            raise RuntimeError("B did not skip target factor")
    return {"word": list(oracle_word), "steps": steps,
            "factor_calls": sum(len(s["factors"]) for s in steps),
            "shortcuts": sum(len(s["shortcuts"]) for s in steps)}


def main() -> int:
    import importlib.util
    root = Path(__file__).resolve().parent.parent
    output = root / "out" / "dart-hebrew-stage7-targeted-ab"
    output.mkdir(parents=True, exist_ok=True)
    result = {
        "project_id": PROJECT, "stage": 7, "qa_only": True,
        "native_acceptance": False, "performance_acceptance": False,
        "benchmark": "two-independently-selected-synthetic-witnesses-v1",
        "status": "NOT_RUN",
        "head_sha": run("git", "rev-parse", "HEAD", cwd=root),
        "github_run_id": os.environ.get("GITHUB_RUN_ID"),
        "environment": {"platform": platform.platform(),
                        "python": platform.python_version(),
                        "dart": run("dart", "--version", cwd=root)},
        "sampling": {"warmup_iterations_per_process": 500,
                     "timed_iterations_per_process": 5000,
                     "alternating_pairs_per_case": 5,
                     "timed_scope": "unmodified unrankFull, per process",
                     "note": "JIT/time variation; no cross-platform claim"},
        "cases": {}, "source_locks": {},
    }
    directories = {}
    try:
        run("git", "merge-base", "--is-ancestor", BASELINE_HEAD, "HEAD", cwd=root)
        oracle_blob = run(
            "git", "rev-parse", "HEAD:tool/dart_hebrew_stage7_shortcut_oracle.py",
            cwd=root)
        if oracle_blob != ORACLE_BLOB:
            raise RuntimeError("Independent leaf oracle blob lock differs")
        result["source_locks"] = lock_sources(root)
        result["source_locks"]["oracle_blob"] = oracle_blob
        result["source_locks"]["runner_blob"] = run(
            "git", "rev-parse",
            "HEAD:tool/dart_hebrew_stage7_targeted_ab_runner.py", cwd=root)
        sys.path.insert(0, str(root / "tool"))
        from dart_hebrew_stage7_shortcut_oracle import leaves, review

        expected_words = {}
        for key, spec in CASES.items():
            words = leaves(spec["lengths"])
            if len(words) != spec["count"]:
                raise RuntimeError("Independent count mismatch for " + key)
            expected_words[key] = words[spec["rank"] - 1]
            independent = review(spec["lengths"], spec["count"])
            matches = [x for x in independent["b_only_expensive_witnesses"]
                       if x["rank"] == spec["rank"] and x["day_index"] == 3
                       and x["residual_rank"] == 2 and x["C0"] == 3
                       and x["factor"] == spec["factor"]]
            if len(matches) != 1:
                raise RuntimeError("Independent factor witness missing: " + key)
            result["cases"][key] = {"input": spec, "oracle_word": list(expected_words[key]),
                                    "trace": {}, "warmup": {}, "pairs": []}

        with tempfile.TemporaryDirectory(prefix="dart_hebrew_stage7_target_") as temp:
            try:
                for label, commit in (("A", A), ("B", B)):
                    worktree = Path(temp) / label
                    run("git", "worktree", "add", "--detach", str(worktree),
                        commit, cwd=root)
                    directories[label] = worktree
                    probe_path = worktree / "tool" / "dart_hebrew_stage7_target_probe.dart"
                    probe_path.parent.mkdir(exist_ok=True)
                    probe_path.write_text(PROBE, encoding="utf-8")
                    src_path = worktree / PLANNER
                    original = src_path.read_text(encoding="utf-8")
                    if run("git", "hash-object", PLANNER, cwd=worktree) != BLOBS[label]:
                        raise RuntimeError("Original source bytes fail source lock")
                    src_path.write_text(instrument(original, label), encoding="utf-8")
                    for key in CASES:
                        raw = run("dart", "run", "tool/dart_hebrew_stage7_target_probe.dart",
                                  "trace", key, cwd=worktree, timeout=180)
                        (output / ("trace_" + label + "_" + key + ".txt")).write_text(
                            raw + "\n", encoding="utf-8")
                        result["cases"][key]["trace"][label] = parse_trace(
                            raw, label, key, expected_words[key])
                    src_path.write_text(original, encoding="utf-8")
                    if run("git", "hash-object", PLANNER, cwd=worktree) != BLOBS[label]:
                        raise RuntimeError("Uninstrumented benchmark source not restored")
                for key in CASES:
                    for label in ("A", "B"):
                        result["cases"][key]["warmup"][label] = sample(
                            directories[label], key, expected_words[key])
                    for i in range(5):
                        order = ("A", "B") if i % 2 == 0 else ("B", "A")
                        pair = {"pair": i + 1, "order": "".join(order)}
                        for label in order:
                            pair[label + "_us"] = sample(
                                directories[label], key, expected_words[key])
                        pair["B_minus_A_us"] = pair["B_us"] - pair["A_us"]
                        pair["B_speedup_pct"] = round(
                            100.0 * (pair["A_us"] - pair["B_us"]) / pair["A_us"], 6)
                        result["cases"][key]["pairs"].append(pair)
                        print("STAGE7_TARGET_PAIR " + key + " " +
                              json.dumps(pair, sort_keys=True), flush=True)
            finally:
                for label, worktree in directories.items():
                    subprocess.run(["git", "worktree", "remove", "--force",
                                    str(worktree)], cwd=root, capture_output=True)
        for key, record in result["cases"].items():
            pairs = record["pairs"]
            pct = [p["B_speedup_pct"] for p in pairs]
            record["median_paired_speedup_pct"] = statistics.median(pct)
            record["min_paired_speedup_pct"] = min(pct)
            record["B_faster_pairs"] = sum(p["B_us"] < p["A_us"] for p in pairs)
            record["observed_gate"] = (
                record["B_faster_pairs"] == 5 and
                record["median_paired_speedup_pct"] >= 2.0 and min(pct) >= 1.0)
        result["verdict"] = (
            "B_OBSERVED_BENEFIT_REVIEW"
            if all(rec["observed_gate"] for rec in result["cases"].values())
            else "INCONCLUSIVE_DEFAULT_A")
        result["status"] = "MEASURED_QA_ONLY"
        print("STAGE7_TARGETED_QA_PASS " + json.dumps({
            "verdict": result["verdict"],
            "witnesses": {k: {"A_factor": r["trace"]["A"]["steps"][3]["factors"],
                             "B_shortcut": r["trace"]["B"]["steps"][3]["shortcuts"],
                             "median_pct": r["median_paired_speedup_pct"]}
                          for k, r in result["cases"].items()},
        }, sort_keys=True), flush=True)
    except Exception as error:
        result["status"] = "FAILED"
        result["error"] = str(error)
        print("STAGE7_TARGETED_QA_FAILED: " + str(error), file=sys.stderr, flush=True)
    (output / "results.json").write_text(
        json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    with (output / "pairs.csv").open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=[
            "case", "pair", "order", "A_us", "B_us", "B_minus_A_us", "B_speedup_pct"])
        writer.writeheader()
        for key, rec in result["cases"].items():
            for pair in rec["pairs"]:
                writer.writerow({"case": key, **pair})
    return 0 if result["status"] == "MEASURED_QA_ONLY" else 1


def sample(worktree: Path, key: str, expected: tuple) -> int:
    raw = run("dart", "run", "tool/dart_hebrew_stage7_target_probe.dart",
              "sample", key, cwd=worktree, timeout=180)
    lines = [line for line in raw.splitlines() if line.startswith("SAMPLE|")]
    if len(lines) != 1:
        raise RuntimeError("Missing sample output")
    parts = lines[0].split("|")
    if len(parts) != 3 or tuple(map(int, parts[2].split(","))) != expected:
        raise RuntimeError("Benchmark output/oracle mismatch")
    elapsed = int(parts[1])
    if elapsed <= 0:
        raise RuntimeError("Invalid elapsed time")
    return elapsed


if __name__ == "__main__":
    sys.exit(main())
