#!/usr/bin/env python3
"""Stage7 QA-only: source-locked A restoration in disposable Git worktrees.
No production-branch mutation. Independent exhaustive leaf DFS supplies expected words.
"""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile

PROJECT = "PC-BRANCH-DART-HEBREW"
PLANNER = "lib/src/monster_month_weave_planner.dart"
SOURCE_A = "1d98a83db7446ceb4548c39e0eaf9b4441b72b9a"
A_BLOB = "3553a7f2e3899c958d56620c5449daa35b0731e2"
B_BLOB = "d736ca8afe3409a10474b8514284aceb154a46a9"
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

def restore_a(b: str, a: str) -> tuple[str, int, int]:
    prefix = 0
    while prefix < min(len(a), len(b)) and a[prefix] == b[prefix]:
        prefix += 1
    suffix = 0
    while suffix < min(len(a), len(b)) - prefix and a[-suffix - 1] == b[-suffix - 1]:
        suffix += 1
    assert (prefix, suffix) == (4662, 2393), (prefix, suffix)
    assert b.count("if (ordinal <= childBases[0])") == 1
    assert a.count("final factor = ordinal == BigInt.one") == 1
    candidate = b[:prefix] + a[prefix:len(a) - suffix] + b[len(b) - suffix:]
    assert candidate == a
    return candidate, prefix, suffix

def main() -> None:
    root = Path(__file__).resolve().parent.parent
    out = root / "out" / "dart-hebrew-stage7-isolated-restoration"
    out.mkdir(parents=True, exist_ok=True)
    head = run("git", "rev-parse", "HEAD", cwd=root)
    assert os.environ.get("GITHUB_REF", "refs/heads/Dart+עברית") == "refs/heads/Dart+עברית"
    assert run("git", "rev-parse", f"HEAD:{PLANNER}", cwd=root) == B_BLOB
    assert run("git", "rev-parse", f"{SOURCE_A}:{PLANNER}", cwd=root) == A_BLOB
    b = run("git", "show", f"HEAD:{PLANNER}", cwd=root) + "\n"
    a = run("git", "show", f"{SOURCE_A}:{PLANNER}", cwd=root) + "\n"
    assert git_blob(a) == A_BLOB and git_blob(b) == B_BLOB
    restored, prefix, suffix = restore_a(b, a)
    cases = [{"lengths": list(counts), "words": words_for(counts)} for counts in CASES]
    assert [len(c["words"]) for c in cases] == EXPECTED_COUNTS
    assert cases[1]["words"][56] == [1, 1, 2, 1, 1, 2, 2, 3, 2, 3, 3]
    assert cases[2]["words"][126] == [1, 1, 2, 1, 1, 2, 2, 3, 2, 3, 3, 3]
    oracle_json = json.dumps({"project_id": PROJECT, "cases": cases}, separators=(",", ":"), ensure_ascii=False)
    (out / "oracle.json").write_text(oracle_json, encoding="utf-8")
    results = {"project_id": PROJECT, "source_head": head, "accepted_a_commit": SOURCE_A,
               "planner_b_blob": B_BLOB, "planner_a_blob": A_BLOB,
               "isolated_patch": {"prefix_chars": prefix, "suffix_chars": suffix,
                                  "b_middle_chars": len(b)-prefix-suffix,
                                  "a_middle_chars": len(a)-prefix-suffix},
               "oracle_sha256": hashlib.sha256(oracle_json.encode("utf-8")).hexdigest(),
               "domains": EXPECTED_COUNTS, "variants": {}}
    with tempfile.TemporaryDirectory(prefix="dart_stage7_restoration_") as td:
        for label in ("B", "RESTORED_A"):
            wd = Path(td) / label
            run("git", "worktree", "add", "--detach", str(wd), head, cwd=root)
            try:
                if label == "RESTORED_A":
                    (wd / PLANNER).write_text(restored, encoding="utf-8")
                    assert (wd / PLANNER).read_text(encoding="utf-8") == a
                    assert git_blob((wd / PLANNER).read_text(encoding="utf-8")) == A_BLOB
                (wd / "tool" / "stage7_qa_probe.dart").write_text(PROBE, encoding="utf-8")
                (wd / "tool" / "stage7_qa_expected.json").write_text(oracle_json, encoding="utf-8")
                fmt = run("dart", "format", "--output=none", "--set-exit-if-changed", PLANNER, cwd=wd)
                analyze = run("dart", "analyze", cwd=wd, timeout=360)
                log = run("dart", "run", "tool/stage7_qa_probe.dart", "tool/stage7_qa_expected.json", label,
                          cwd=wd, timeout=600)
                assert f"STAGE7_ISOLATED_DIFFERENTIAL_PASS variant={label} ranks=1788" in log
                results["variants"][label] = {"format": fmt, "analyze": analyze, "run": log}
            finally:
                run("git", "worktree", "remove", "--force", str(wd), cwd=root)
    results["status"] = "PASS_ISOLATED_QA_ONLY"
    (out / "results.json").write_text(json.dumps(results, indent=2, ensure_ascii=False) + "\n",
                                      encoding="utf-8")
    print("STAGE7_ISOLATED_RESTORATION_QA_PASS head=" + head + " cases=1788x2 no_production_edit")

if __name__ == "__main__":
    main()
