#!/usr/bin/env python3
"""Independent 4244-row five-field *projection* oracle for Stage55.

Neither this module nor its fixture chooses the canonical middle-rank weave.
Input is the audited Year5000 metadata and either greedy edge words or a
provided COMPLETE weave. The algorithm counts occurrences directly and never
calls any MATLAB implementation, rank function, or generated result.
"""
import argparse
import bisect
import hashlib
import itertools
import json
from pathlib import Path

HEADER = b"POSITION,YEAR,CUTLET_INDEX,CUTLET_DAY,MONTH_INDEX,MONTH_DAY\n"
PROJECT_ID = "PC-BRANCH-MATLAB-POLSKI"


def fail_unless(condition, message):
    if not condition:
        raise ValueError(message)


def fixture_data(path):
    raw = path.read_bytes()
    d = json.loads(raw)
    L = d["month_lengths"]
    C = d["cutlet_day_lengths"]
    fail_unless(d["year"] == 5000 and d["first_day"] == -15057702
                and d["last_day"] == -15053459, "year boundaries")
    fail_unless(len(L) == 45 and sum(L) == 4244
                and all(type(v) is int and v > 1 for v in L), "month lengths")
    fail_unless(len(C) == 6 and sum(C) == 4244
                and all(type(v) is int and v > 0 for v in C), "cutlet lengths")
    fail_unless(len(d["month_name_indices"]) == len(L)
                and len(set(d["month_name_indices"])) == len(L), "month names")
    fail_unless(len(d["cutlet_name_indices"]) == len(C)
                and len(set(d["cutlet_name_indices"])) == len(C), "cutlet names")
    return d, hashlib.sha256(raw).hexdigest()


def valid_word(word, lengths):
    fail_unless(len(word) == sum(lengths), "word length")
    first = [None] * len(lengths)
    last = [None] * len(lengths)
    counts = [0] * len(lengths)
    for position, symbol in enumerate(word):
        fail_unless(type(symbol) is int and 1 <= symbol <= len(lengths), "symbol domain")
        j = symbol - 1
        counts[j] += 1
        if first[j] is None:
            first[j] = position
        last[j] = position
    fail_unless(counts == lengths, "month multiplicities")
    fail_unless(all(a < b for a, b in zip(first, first[1:])), "first-occurrence order")
    fail_unless(all(a < b for a, b in zip(last, last[1:])), "last-occurrence order")


def greedy_edge(lengths, largest):
    left = lengths.copy()
    opened = closed = 0
    word = []
    for _ in range(sum(lengths)):
        choices = []
        for symbol in range(1, len(lengths) + 1):
            n = left[symbol - 1]
            if n and (n != lengths[symbol - 1] or symbol == opened + 1) \
                    and (n != 1 or symbol == closed + 1):
                choices.append(symbol)
        fail_unless(bool(choices), "no legal completion")
        chosen = choices[-1] if largest else choices[0]
        j = chosen - 1
        old = left[j]
        left[j] = old - 1
        opened += int(old == lengths[j])
        closed += int(old == 1)
        word.append(chosen)
    fail_unless(all(v == 0 for v in left)
                and opened == closed == len(lengths), "incomplete weave")
    valid_word(word, lengths)
    return word


def tiny_exhaustive_controls():
    families = ((1, 1), (2, 2), (1, 2, 1), (2, 1, 2), (2, 2, 2), (3, 2))
    for family in families:
        words = []
        multiset = tuple(j for j, n in enumerate(family, 1) for _ in range(n))
        for w in set(itertools.permutations(multiset)):
            try:
                valid_word(w, list(family))
            except ValueError:
                continue
            words.append(w)
        fail_unless(bool(words), "tiny family empty")
        fail_unless(tuple(greedy_edge(list(family), False)) == min(words), "low edge")
        fail_unless(tuple(greedy_edge(list(family), True)) == max(words), "high edge")
    return len(families)


def csv_bytes(word, fixture):
    valid_word(word, fixture["month_lengths"])
    ends = list(itertools.accumulate(fixture["cutlet_day_lengths"]))
    starts = [0] + ends[:-1]
    count = [0] * len(fixture["month_lengths"])
    lines = [HEADER]
    for pos, symbol in enumerate(word, start=1):
        cutlet = bisect.bisect_left(ends, pos)
        fail_unless(cutlet < len(ends), "cutlet index")
        count[symbol - 1] += 1
        fields = (pos, fixture["year"], fixture["cutlet_name_indices"][cutlet],
                  pos - starts[cutlet], fixture["month_name_indices"][symbol - 1],
                  count[symbol - 1])
        lines.append((",".join(map(str, fields)) + "\n").encode("ascii"))
    fail_unless(count == fixture["month_lengths"], "final occurrence counts")
    fail_unless(len(lines) == 4245, "wrong line count")
    return b"".join(lines)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("fixture", type=Path)
    p.add_argument("output_dir", type=Path)
    p.add_argument("--word-json", type=Path,
                   help="Optional complete canonical weave as an integer JSON array")
    args = p.parse_args()
    d, fixture_digest = fixture_data(args.fixture)
    cases = ({"CANDIDATE": json.loads(args.word_json.read_text(encoding="utf-8"))}
             if args.word_json else
             {"FIRST": greedy_edge(d["month_lengths"], False),
              "LAST": greedy_edge(d["month_lengths"], True)})
    tiny_cases = tiny_exhaustive_controls()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    manifest = {"project_id": PROJECT_ID, "year": 5000,
                "fixture_sha256": fixture_digest, "tiny_exhaustive_families": tiny_cases,
                "scope": "FULL_YEAR_PROJECTION_ONLY; CANONICAL_MIDDLE_RANK_NOT_VERIFIED",
                "cases": {}}
    for kind, word in cases.items():
        valid_word(word, d["month_lengths"])
        data = csv_bytes(word, d)
        name = f"STAGE55_YEAR5000_{kind}.csv"
        (args.output_dir / name).write_bytes(data)
        manifest["cases"][kind] = {
            "csv": name, "rows": 4244, "bytes": len(data),
            "sha256": hashlib.sha256(data).hexdigest(),
            "weave_sha256": hashlib.sha256(json.dumps(word, separators=(",", ":")).encode("ascii")).hexdigest()}
    (args.output_dir / "STAGE55_YEAR5000_PROJECTION_MANIFEST.json").write_text(
        json.dumps(manifest, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    print(f"STAGE55_YEAR5000_INDEPENDENT_PROJECTION_PASS CASES={len(cases)} "
          f"ROWS_PER_CASE=4244 TINY={tiny_cases} FIXTURE_SHA256={fixture_digest}")
    print("STAGE55_CANONICAL_MIDDLE_RANK_NOT_VERIFIED")
    print("STAGE55_FINAL_STAGE_PASS_NOT_VERIFIED")


if __name__ == "__main__":
    main()
