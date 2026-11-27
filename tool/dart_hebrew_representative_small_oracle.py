#!/usr/bin/env python3
"""Independent bounded suffix oracle; QA only. Never patches tracked source."""
import argparse
import hashlib
import itertools
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

DRIVER = r'''
import 'dart:convert';
import 'dart:io';
import 'package:pastafari_calendar_dart_hebrew/src/monster_month_weave_counter.dart';

void main(List<String> args) {
  final rows = jsonDecode(File(args[0]).readAsStringSync()) as List;
  final results = <Map<String, Object>>[];
  for (final row in rows) {
    final v = List<int>.unmodifiable((row['vector'] as List).cast<int>());
    try {
      final result = MonsterMonthWeaveCounter.countCompletions(
        v,
        openedUpTo: row['opened'] as int,
        closedUpTo: row['closed'] as int,
      );
      results.add({'count': result.toString()});
    } catch (error) {
      results.add({'error': error.runtimeType.toString()});
    }
  }
  File(args[1]).writeAsStringSync(jsonEncode(results));
}
'''


def require(condition, reason):
    if not condition:
        raise RuntimeError(reason)


def oracle(vector, opened, closed):
    # Enumerate EVERY distinct multiset word; filter only at leaves.
    # No insertion recurrence, binomial arithmetic or production calls.
    word = []
    remaining = list(vector)
    length = sum(vector)
    accepted = leaves = 0

    def walk():
        nonlocal accepted, leaves
        if len(word) == length:
            leaves += 1
            first = [word.index(i) for i in range(opened, len(vector))]
            last = [
                length - 1 - word[::-1].index(i)
                for i in range(closed, len(vector))
            ]
            if all(a < b for a, b in zip(first, first[1:])) and all(
                a < b for a, b in zip(last, last[1:])
            ):
                accepted += 1
            return
        for i, value in enumerate(remaining):
            if value:
                remaining[i] -= 1
                word.append(i)
                walk()
                word.pop()
                remaining[i] += 1

    walk()
    return accepted, leaves


def fixtures():
    rows = []
    leaves = totals = nontrivial = 0
    for n in range(1, 5):
        for closed in range(n + 1):
            for opened in range(closed, n + 1):
                for active in itertools.product(range(1, 4), repeat=n - closed):
                    vector = [0] * closed + list(active)
                    if sum(vector) > 8:
                        continue
                    count, visited = oracle(vector, opened, closed)
                    leaves += visited
                    totals += count
                    nontrivial += count > 1
                    rows.append(dict(vector=vector, opened=opened, closed=closed,
                                     expected={"count": str(count)}))
    require((len(rows), leaves, totals, nontrivial) == (567, 221482, 8055, 403),
            "independent census mismatch")
    invalid = [
        ([], 0, 0, "RangeError"),
        ([1] * 48, 0, 0, "RangeError"),
        ([5779], 0, 0, "RangeError"),
        ([1], 0, -1, "ArgumentError"),
        ([1], 2, 0, "ArgumentError"),
        ([0, 1], 0, 1, "ArgumentError"),
        ([1, 1], 1, 1, "ArgumentError"),
        ([0, 1], 0, 0, "ArgumentError"),
        ([-1, 1], 0, 0, "ArgumentError"),
        ([0, 0], 1, 1, "ArgumentError"),
    ]
    for vector, opened, closed, error in invalid:
        rows.append(dict(vector=vector, opened=opened, closed=closed,
                         expected={"error": error}))
    # Reverse repeat covers exact repeat keys and reordered distinct keys;
    # the same API driver can later be run against an injected disposable copy.
    return rows + rows[::-1], dict(valid_unique=567, invalid_unique=len(invalid),
                                   enumerated_words=leaves, count_sum=totals,
                                   nontrivial_states=nontrivial)


def save(path, obj):
    data = (json.dumps(obj, ensure_ascii=True, separators=(",", ":")) + "\n").encode()
    path.write_bytes(data)
    return hashlib.sha256(data).hexdigest()


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--root", type=Path, default=Path.cwd())
    p.add_argument("--out", type=Path, required=True)
    p.add_argument("--oracle-only", action="store_true")
    args = p.parse_args()
    root, out = args.root.resolve(), args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    rows, summary = fixtures()
    fixture = out / "fixtures.json"
    summary["fixture_sha256"] = save(fixture, rows)
    summary["requests"] = len(rows)
    summary["native"] = "NOT_RUN"
    save(out / "summary.json", summary)
    print(json.dumps(summary), flush=True)
    if args.oracle_only:
        return
    try:
        with tempfile.TemporaryDirectory(prefix="dart-representative-oracle-") as tmp:
            work = Path(tmp)
            shutil.copytree(root / "lib", work / "lib")
            shutil.copy2(root / "pubspec.yaml", work / "pubspec.yaml")
            (work / "tool").mkdir()
            driver = work / "tool" / "qa_suffix_oracle.dart"
            driver.write_text(DRIVER, encoding="utf-8")
            for name, command, timeout in [
                ("version", ["dart", "--version"], 30),
                ("pub-get", ["dart", "pub", "get"], 90),
                ("format", ["dart", "format", str(driver)], 30),
                ("analyze", ["dart", "analyze"], 90),
                ("native", ["dart", "run", str(driver), str(fixture),
                            str(out / "actual.json")], 180),
            ]:
                with (out / (name + ".log")).open("wb") as log:
                    completed = subprocess.run(command, cwd=work, stdout=log,
                                               stderr=subprocess.STDOUT, timeout=timeout)
                require(completed.returncode == 0, name + " nonzero exit")
        actual = json.loads((out / "actual.json").read_text(encoding="utf-8"))
        require(isinstance(actual, list) and len(actual) == len(rows), "result coverage")
        for i, (row, result) in enumerate(zip(rows, actual)):
            require(result == row["expected"], f"case {i}: {row!r} actual={result!r}")
        summary["actual_sha256"] = hashlib.sha256((out / "actual.json").read_bytes()).hexdigest()
        summary["native"] = "PASS"
        save(out / "summary.json", summary)
        print("REPRESENTATIVE_SMALL_ORACLE_PASS", json.dumps(summary), flush=True)
    except Exception as exc:
        summary["native"] = "NOT_ACCEPTED"
        summary["failure"] = repr(exc)
        save(out / "summary.json", summary)
        raise


if __name__ == "__main__":
    main()
