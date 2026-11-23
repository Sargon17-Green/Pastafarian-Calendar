#!/usr/bin/env python3
"""Stage7 R2: source-rebaselined A/B differential in disposable Git worktrees.
Historical A remains immutable; only the authorized branch B source is rebased.
Native clean-format, independent exhaustive leaf oracle, and blob locks are required.
"""
from __future__ import annotations

import hashlib
import json
import os
import re
from pathlib import Path
import subprocess
import tempfile

PROJECT = "PC-BRANCH-DART-HEBREW"
PLANNER = "lib/src/monster_month_weave_planner.dart"
SOURCE_A = "1d98a83db7446ceb4548c39e0eaf9b4441b72b9a"
A_BLOB = "3553a7f2e3899c958d56620c5449daa35b0731e2"
B_BLOB = "749b874d2fc736a02bfd3985ac7897ea4fb8c407"
A_REBASED_BLOB = "a29fe8d80f3d1c2dbe6efb18075eea6a01af1853"
B_HISTORICAL_BLOB = "d736ca8afe3409a10474b8514284aceb154a46a9"
B_HISTORICAL_HEAD = "12289c4ae379bde41b62df8c6d8611e4b4bffe8c"
CASES = [(3, 3, 2), (4, 4, 3), (4, 4, 4)]
EXPECTED_COUNTS = [26, 461, 1301]

PROBE = r"""import 'dart:convert';
import 'dart:io';
import '../lib/src/monster_month_weave_planner.dart';

void check(bool good, String why) {
  if (!good) throw StateError(why);
}
void expectArgumentError(List<int> lengths, BigInt rank) {
  try {
    MonsterMonthWeavePlanner.unrankFull(lengths, rank);
  } on ArgumentError {
    return;
  }
  throw StateError('Invalid rank accepted: $lengths/$rank');
}
void main(List<String> args) {
  check(args.length == 2, 'Expected fixture path and variant');
  final root = jsonDecode(File(args[0]).readAsStringSync()) as Map<String, dynamic>;
  var checked = 0;
  for (final raw in root['cases'] as List<dynamic>) {
    final test = raw as Map<String, dynamic>;
    final lengths = (test['lengths'] as List<dynamic>).cast<int>();
    final words = test['words'] as List<dynamic>;
    final initial = List<int>.of(lengths);
    for (var i = 0; i < words.length; i++) {
      final expected = (words[i] as List<dynamic>).cast<int>();
      final actual = MonsterMonthWeavePlanner.unrankFull(lengths, BigInt.from(i + 1));
      check(actual.length == expected.length &&
            List.generate(actual.length, (j) => actual[j] == expected[j]).every((v) => v),
            'Differential mismatch rank ' + (i + 1).toString() + ' actual=$actual expected=$expected');
      if (i == 0) {
        try {
          actual[0] = -1;
          throw StateError('Mutable result');
        } on UnsupportedError {
          // Required immutable result.
        }
      }
      checked++;
    }
    check(lengths.join(',') == initial.join(','), 'Input mutated');
    expectArgumentError(lengths, BigInt.zero);
    expectArgumentError(lengths, BigInt.from(words.length + 1));
  }
  check(checked == 1788, 'Oracle coverage unexpected: $checked');
  stdout.writeln('STAGE7_ISOLATED_DIFFERENTIAL_PASS variant=' + args[1] +
    ' ranks=$checked domains=3 bounds=6 immutable=3');
}
"""

def run(*cmd: str, cwd: Path | None = None, timeout: int = 240) -> str:
    result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=timeout)
    if result.returncode != 0:
        raise RuntimeError(f"exit={result.returncode} cmd={' '.join(cmd)}\n{result.stdout[-2500:]}\n{result.stderr[-2500:]}")
    return result.stdout.strip()

def git_blob(text: str) -> str:
    data = text.encode("utf-8")
    return hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()

def write_results(out: Path, results: dict) -> None:
    (out / "results.json").write_text(
        json.dumps(results, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

def words_for(lengths: tuple[int, ...]) -> list[list[int]]:
    output: list[list[int]] = []
    def visit(remaining: tuple[int, ...], opened: int, closed: int, prefix: tuple[int, ...]) -> None:
        if not any(remaining):
            assert opened == closed == len(lengths)
            output.append([x + 1 for x in prefix])
            return
        for color in range(closed, min(opened, len(lengths) - 1) + 1):
            fresh = color == opened
            if fresh and (opened == len(lengths) or (remaining[color] == 1 and closed < opened)):
                continue
            if not fresh and (remaining[color] == 0 or (remaining[color] == 1 and color != closed)):
                continue
            after = list(remaining)
            after[color] -= 1
            visit(tuple(after), opened + int(fresh), closed + int(after[color] == 0), prefix + (color,))
    visit(lengths, 0, 0, ())
    assert len(output) == len({tuple(word) for word in output})
    assert output == sorted(output)
    return output

def rebaseline_a(b: str, a: str, historical_b: str) -> str:
    """Only two known formatter hunks; never modify the historical A blob."""
    old_arithmetic = (
        "        result[j] = (base * BigInt.from(counts[j] - 1) * suffixNumerator[j]) ~/\n"
        "            (BigInt.from(sums[j] - 1) * suffixDenominator[j]);"
    )
    new_arithmetic = (
        "        result[j] =\n"
        "            (base * BigInt.from(counts[j] - 1) * suffixNumerator[j]) ~/\n"
        "            (BigInt.from(sums[j] - 1) * suffixDenominator[j]);"
    )
    old_call = (
        "    final work = const MonsterWorkCounter().calculate(\n"
        "      calculationDay,\n"
        "      firstDay,\n"
        "    );"
    )
    new_call = (
        "    final work = const MonsterWorkCounter().calculate(calculationDay, firstDay);"
    )
    def apply(source: str) -> str:
        assert source.count(old_arithmetic) == 1
        assert source.count(old_call) == 1
        return source.replace(old_arithmetic, new_arithmetic).replace(old_call, new_call)

    assert git_blob(a) == A_BLOB, "Historical A source modified"
    assert git_blob(historical_b) == B_HISTORICAL_BLOB, "Historical B source modified"
    assert apply(historical_b) == b, "Tracked B exceeds the two allowed formatter hunks"
    new_a = apply(a)
    assert git_blob(new_a) == A_REBASED_BLOB, "Rebased A source lock mismatch"
    # Unlike R1, the revised baseline is a new physical source snapshot.
    # The original A source remains unchanged in its immutable history.
    return new_a


def main() -> None:
    root = Path(__file__).resolve().parent.parent
    out = root / "out" / "dart-hebrew-stage7-isolated-restoration"
    out.mkdir(parents=True, exist_ok=True)
    head = run("git", "rev-parse", "HEAD", cwd=root)
    assert os.environ.get("GITHUB_REF", "refs/heads/Dart+עברית") == "refs/heads/Dart+עברית"
    assert run("git", "rev-parse", f"HEAD:{PLANNER}", cwd=root) == B_BLOB
    assert run("git", "rev-parse", f"{SOURCE_A}:{PLANNER}", cwd=root) == A_BLOB
    assert run("git", "rev-parse", f"{B_HISTORICAL_HEAD}:{PLANNER}", cwd=root) == B_HISTORICAL_BLOB
    b = run("git", "show", f"HEAD:{PLANNER}", cwd=root) + "\n"
    a = run("git", "show", f"{SOURCE_A}:{PLANNER}", cwd=root) + "\n"
    assert git_blob(a) == A_BLOB and git_blob(b) == B_BLOB
    historical_b = run("git", "show", f"{B_HISTORICAL_HEAD}:{PLANNER}", cwd=root) + "\n"
    restored = rebaseline_a(b, a, historical_b)
    cases = [{"lengths": list(counts), "words": words_for(counts)} for counts in CASES]
    assert [len(c["words"]) for c in cases] == EXPECTED_COUNTS
    assert cases[1]["words"][56] == [1, 1, 2, 1, 1, 2, 2, 3, 2, 3, 3]
    assert cases[2]["words"][126] == [1, 1, 2, 1, 1, 2, 2, 3, 2, 3, 3, 3]
    oracle_json = json.dumps({"project_id": PROJECT, "cases": cases}, separators=(",", ":"), ensure_ascii=False)
    (out / "oracle.json").write_text(oracle_json, encoding="utf-8")
    results = {"project_id": PROJECT, "source_head": head, "accepted_a_commit": SOURCE_A,
               "planner_b_blob": B_BLOB, "historical_planner_a_blob": A_BLOB,
               "rebased_a_blob": A_REBASED_BLOB,
               "historical_planner_b_blob": B_HISTORICAL_BLOB,
               "source_rebaseline": "two exact Dart 3.13.2 formatter hunks, no R1 exception",
               "oracle_sha256": hashlib.sha256(oracle_json.encode("utf-8")).hexdigest(),
               "domains": EXPECTED_COUNTS, "variants": {}}
    try:
        with tempfile.TemporaryDirectory(prefix="dart_stage7_restoration_") as td:
            for label in ("B", "RESTORED_A"):
                wd = Path(td) / label
                run("git", "worktree", "add", "--detach", str(wd), head, cwd=root)
                try:
                    if label == "RESTORED_A":
                        (wd / PLANNER).write_text(restored, encoding="utf-8")
                        assert (wd / PLANNER).read_text(encoding="utf-8") == restored
                    source_before_format = (wd / PLANNER).read_text(encoding="utf-8")
                    (wd / "tool" / "stage7_qa_probe.dart").write_text(PROBE, encoding="utf-8")
                    (wd / "tool" / "stage7_qa_expected.json").write_text(oracle_json, encoding="utf-8")
                    # Both B and restored A are source-locked. Diagnose formatting
                    # without modifying either variant; retain the historical bytes.
                    fmt_proc = subprocess.run(
                        ("dart", "format", "--output=none", PLANNER),
                        cwd=wd, capture_output=True, text=True, timeout=240,
                    )
                    fmt_output = (fmt_proc.stdout or "") + (fmt_proc.stderr or "")
                    if fmt_proc.returncode != 0:
                        raise RuntimeError(
                            f"dart format diagnostic failed for locked {label} (exit={fmt_proc.returncode})\n{fmt_output[-4000:]}"
                        )
                    changed_match = re.search(r"Formatted \d+ files? \((\d+) changed\)", fmt_output)
                    if changed_match is None:
                        raise RuntimeError(
                            f"Could not parse Dart formatter summary for locked {label}: " + fmt_output[-2000:]
                        )
                    changed_files = int(changed_match.group(1))
                    fmt = {"output": fmt_output.strip(), "changed_files": changed_files}
                    format_status = "CLEAN" if changed_files == 0 else "BASELINE_FORMAT_DRIFT"
                    source_after_format = (wd / PLANNER).read_text(encoding="utf-8")
                    expected_blob = B_BLOB if label == "B" else A_REBASED_BLOB
                    assert source_after_format == source_before_format, "Formatter changed the source-locked worktree"
                    assert git_blob(source_after_format) == expected_blob, (
                        f"Source blob changed after format diagnostic: {label}"
                    )
                    # Worktree does not inherit the root package configuration.
                    # Resolve its package URI before full-package static analysis.
                    pub_get = run("dart", "pub", "get", cwd=wd, timeout=360)
                    analyze = run("dart", "analyze", cwd=wd, timeout=360)
                    log = run("dart", "run", "tool/stage7_qa_probe.dart", "tool/stage7_qa_expected.json", label,
                              cwd=wd, timeout=600)
                    assert f"STAGE7_ISOLATED_DIFFERENTIAL_PASS variant={label} ranks=1788" in log
                    results["variants"][label] = {
                        "format": fmt,
                        "format_status": format_status,
                        "source_blob_after_format": git_blob(source_after_format),
                        "pub_get": pub_get,
                        "analyze": analyze,
                        "run": log,
                    }
                    write_results(out, results)
                finally:
                    run("git", "worktree", "remove", "--force", str(wd), cwd=root)
    except Exception as exc:
        results["status"] = "INCOMPLETE"
        results["error"] = repr(exc)
        write_results(out, results)
        raise
    drift_variants = [
        label for label, data in results["variants"].items()
        if data["format_status"] == "BASELINE_FORMAT_DRIFT"
    ]
    results["format_gate"] = "BASELINE_FORMAT_DRIFT" if drift_variants else "CLEAN"
    results["status"] = (
        "DIFFERENTIAL_PASS_WITH_FORMAT_DRIFT"
        if drift_variants else "PASS_ISOLATED_QA_ONLY"
    )
    write_results(out, results)
    assert results["format_gate"] == "CLEAN", "R2 source-rebaseline formatter gate failed"
    print(
        "STAGE7_R2_NATIVE_REBASELINE_QA_PASS head=" + head +
        " cases=1788x2 B_format=" + results["variants"]["B"]["format_status"] +
        " A_format=" + results["variants"]["RESTORED_A"]["format_status"] +
        " no_production_edit"
    )

if __name__ == "__main__":
    main()
