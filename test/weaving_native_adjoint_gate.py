#!/usr/bin/env python3
"""Independent positional finite oracle for research-only Native Chapel adjoint QA.
This does NOT import the Chapel transfer/adjoint code or its fixtures.
"""
import argparse
import itertools
from pathlib import Path


def csv(items):
    return ",".join(map(str, items))


def families():
    return tuple(p for m in range(1, 5)
                 for p in itertools.product((1, 2, 3), repeat=m)
                 if sum(p) <= 8)


def positional_words(lengths):
    """Directly enumerate the multiset words and filter first/last positions."""
    remaining = list(lengths)
    prefix = []
    accepted = []

    def visit():
        if not any(remaining):
            first = [prefix.index(c) for c in range(1, len(lengths) + 1)]
            last = [len(prefix) - 1 - prefix[::-1].index(c)
                    for c in range(1, len(lengths) + 1)]
            if first == sorted(first) and last == sorted(last):
                accepted.append(tuple(prefix))
            return
        for i, count in enumerate(remaining):
            if count:
                remaining[i] -= 1
                prefix.append(i + 1)
                visit()
                prefix.pop()
                remaining[i] += 1
    visit()
    return tuple(accepted)


def make_expected():
    lines = []
    family_count = word_count = block_count = 0
    for lengths in families():
        words = positional_words(lengths)
        lines.append(f"NATIVE_ADJOINT_CASE={csv(lengths)};{len(words)}")
        family_count += 1
        for rank, word in enumerate(words):
            lines.append(f"NATIVE_ADJOINT_WORD={csv(lengths)};{rank};{csv(word)}")
            for depth in range(len(word)):
                prefix = word[:depth]
                counts = tuple(sum(other[:depth + 1] == prefix + (candidate,)
                                   for other in words)
                               for candidate in range(1, len(lengths) + 1))
                lines.append(f"NATIVE_ADJOINT_BLOCK={csv(lengths)};{csv(prefix)};{csv(counts)}")
                block_count += 1
            word_count += 1
    lines.extend((
        f"NATIVE_ADJOINT_FAMILIES={family_count}",
        f"NATIVE_ADJOINT_WORDS={word_count}",
        f"NATIVE_ADJOINT_BLOCK_ROWS={block_count}",
        "NATIVE_ADJOINT_4244=NOT_TESTED",
        "NATIVE_ADJOINT_STAGE6=NOT_CLAIMED",
        "NATIVE_ADJOINT_PRODUCTION_CHANGE=NONE",
    ))
    return lines, (family_count, word_count, block_count)


def verify(actual, expected):
    if len(actual) != len(expected):
        raise ValueError(f"evidence row count differs: {len(actual)} != {len(expected)}")
    for i, (found, correct) in enumerate(zip(actual, expected), 1):
        if found != correct:
            raise ValueError(f"positional mismatch at evidence row {i}: "
                             f"got {found[:180]!r}, expected {correct[:180]!r}")


def self_test():
    lines, (family_count, word_count, block_count) = make_expected()
    assert (family_count, word_count) == (88, 331), (
        family_count, word_count)
    assert block_count > 0
    verify(lines, lines)
    for index in (0, 1, len(lines) // 2, len(lines) - 1):
        altered = lines.copy()
        altered[index] += "_CORRUPT"
        try:
            verify(altered, lines)
        except ValueError:
            pass
        else:
            raise AssertionError("synthetic corrupted evidence accepted")
    try:
        verify(lines[:-1], lines)
    except ValueError:
        pass
    else:
        raise AssertionError("truncated evidence accepted")
    print("NATIVE_ADJOINT_ORACLE_FINITE_FAMILIES=88")
    print("NATIVE_ADJOINT_ORACLE_FINITE_WORDS=331")
    print(f"NATIVE_ADJOINT_ORACLE_BLOCK_ROWS={block_count}")
    print("NATIVE_ADJOINT_ORACLE_MUTATIONS_REJECTED=5")
    print("NATIVE_ADJOINT_ORACLE_SELFTEST_RESULT=PASS")
    print("NATIVE_ADJOINT_NATIVE_4244=NOT_TESTED")


def main():
    p = argparse.ArgumentParser()
    group = p.add_mutually_exclusive_group(required=True)
    group.add_argument("--self-test", action="store_true")
    group.add_argument("--log", type=Path)
    args = p.parse_args()
    if args.self_test:
        self_test()
    else:
        expected, (family_count, word_count, block_count) = make_expected()
        raw = args.log.read_bytes()
        if not raw.endswith(b"\n") or b"\r" in raw or any(c > 127 for c in raw):
            raise ValueError("noncanonical ASCII LF evidence")
        verify(raw.decode("ascii").splitlines(), expected)
        print(f"NATIVE_ADJOINT_FINITE_FAMILIES={family_count}")
        print(f"NATIVE_ADJOINT_FINITE_WORDS={word_count}")
        print(f"NATIVE_ADJOINT_FINITE_BLOCK_ROWS={block_count}")
        print("NATIVE_ADJOINT_FINITE_RESULT=PASS")
        print("NATIVE_ADJOINT_4244=NOT_TESTED")
        print("NATIVE_ADJOINT_STAGE6=NOT_CLAIMED")


if __name__ == "__main__":
    main()
