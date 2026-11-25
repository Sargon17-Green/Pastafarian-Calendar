#!/usr/bin/env python3
"""Independent unique-multiset enumeration for every 1–4 month 2/3-length family."""
from itertools import product
from pathlib import Path
import json

FIXTURE = Path("qa/issue29/v198_families.txt")
rows = []
total_words = 0
expected_vectors = [
    tuple(values)
    for month_count in range(1, 5)
    for values in product((2, 3), repeat=month_count)
]

def enumerate_words(lengths):
    month_count = len(lengths)
    remaining = list(lengths)
    prefix = []
    words = []
    total_days = sum(lengths)

    def visit():
        if len(prefix) == total_days:
            first = [None] * month_count
            last = [None] * month_count
            for position, month in enumerate(prefix):
                index = month - 1
                if first[index] is None:
                    first[index] = position
                last[index] = position
            if all(first[i] < first[i + 1] and last[i] < last[i + 1]
                   for i in range(month_count - 1)):
                words.append("".join(map(str, prefix)))
            return
        for index in range(month_count):
            if remaining[index]:
                remaining[index] -= 1
                prefix.append(index + 1)
                visit()
                prefix.pop()
                remaining[index] += 1

    visit()
    words.sort()
    return words

parsed_vectors = []
for raw in FIXTURE.read_text(encoding="utf-8").splitlines():
    line = raw.strip()
    if not line or line.startswith("#"):
        continue
    left, right = line.split("|", 1)
    lengths = tuple(map(int, left.split(",")))
    expected = right.split(";")
    assert 1 <= len(lengths) <= 4 and all(n in (2, 3) for n in lengths)
    assert len(set(expected)) == len(expected)
    assert expected == sorted(expected)
    actual = enumerate_words(lengths)
    assert actual == expected, {
        "lengths": lengths,
        "expected_count": len(expected),
        "actual_count": len(actual),
        "first_expected": expected[:3],
        "first_actual": actual[:3],
    }
    parsed_vectors.append(lengths)
    total_words += len(actual)
    rows.append({
        "lengths": list(lengths),
        "count": len(actual),
        "first": actual[0],
        "last": actual[-1],
    })

assert parsed_vectors == expected_vectors, (parsed_vectors, expected_vectors)
assert len(rows) == 30 and total_words == 3424, (len(rows), total_words)
largest = max(rows, key=lambda row: row["count"])
assert largest["lengths"] == [3, 3, 3, 3] and largest["count"] == 1266

Path("evidence").mkdir(exist_ok=True)
Path("evidence/independent-oracle.json").write_text(
    json.dumps({
        "schema": "V198_INDEPENDENT_UNIQUE_MULTISETS/1",
        "families": rows,
        "family_count": len(rows),
        "total_exact_words": total_words,
        "largest_family": largest,
        "rule": "first positions and last positions both strictly increase by month index",
    }, ensure_ascii=False, sort_keys=True, indent=2) + "\n",
    encoding="utf-8",
)
print(f"V198_INDEPENDENT_FIXTURE_PASS families={len(rows)} words={total_words}")
