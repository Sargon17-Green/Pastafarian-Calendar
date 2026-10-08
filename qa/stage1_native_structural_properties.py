#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Stage 1: native Befunge-98 combinatorial properties, not a Python oracle.

All counts and unranked objects come from *native* test-only Befunge programs.
This harness checks only independent structural invariants, uniqueness and
the documented lexicographic rank order. It never generates calendar dates,
sauce, gate ranks, cutlet choices or expected values in Python.
"""
from __future__ import print_function
import collections
import subprocess

COMMAND = [
    "timeout", "--kill-after=2s", "55s",
    "pyfunge", "--disable-fprint", "--no-concurrent",
    "--no-filesystem", "-v98", "-d2",
]
RUNS = [0]


def native(path, fields):
    raw = " ".join(str(v) for v in fields) + "\n"
    RUNS[0] += 1
    proc = subprocess.Popen(
        COMMAND + [path],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE,
        stderr=subprocess.PIPE)
    output, errors = proc.communicate(raw)
    if proc.returncode:
        raise AssertionError(
            "native execution failed path=%s input=%r rc=%s stderr=%r" %
            (path, raw, proc.returncode, errors[-800:]))
    tokens = output.split()
    if not tokens:
        raise AssertionError("empty native output for %s %r" % (path, raw))
    try:
        return tuple(int(value) for value in tokens)
    except ValueError:
        raise AssertionError("nonnumeric native output %r %r" % (path, tokens))


def count(path, args):
    result = native(path, args)
    if len(result) != 1 or result[0] < 1:
        raise AssertionError("invalid native family count %r %r" % (args, result))
    return result[0]


def sample_ranks(total):
    if total <= 40:
        return list(range(1, total + 1))
    # Large families: boundary, nearby and interior ranks.
    return sorted(set([1, 2, 3, 4, 5, total // 3,
                       total // 2, (2 * total) // 3,
                       total - 4, total - 3, total - 2,
                       total - 1, total]))


def bounded_composition_family(total, slots, lower, upper):
    args = (total, slots, lower, upper)
    counter = "reference/count_bounded_compositions.b98"
    unranker = "reference/unrank_bounded_composition.b98"
    cardinality = count(counter, args)
    previous = None
    visited = set()
    for rank in sample_ranks(cardinality):
        item = native(unranker, args + (rank,))
        if len(item) != slots or sum(item) != total:
            raise AssertionError("bounded shape or sum %r rank=%d item=%r" %
                                 (args, rank, item))
        if not all(lower <= n <= upper for n in item):
            raise AssertionError("bounded item outside range %r %r" % (args, item))
        if item in visited:
            raise AssertionError("duplicate bounded item %r rank=%d" % (args, rank))
        if previous is not None and not previous < item:
            raise AssertionError("bounded rank not lexicographic %r rank=%d" %
                                 (args, rank))
        previous = item
        visited.add(item)
    for bad_rank in [0, cardinality + 1]:
        if native(unranker, args + (bad_rank,)) != (-1,):
            raise AssertionError("bounded invalid rank accepted %r %d" %
                                 (args, bad_rank))
    print("NATIVE_BOUNDED_FAMILY_PASS", args, "count", cardinality,
          "checked", len(visited))


def weaving_family(lengths, expected_count=None):
    lengths = tuple(lengths)
    args = (len(lengths),) + lengths
    counter = "reference/count_weavings.b98"
    unranker = "reference/unrank_weaving.b98"
    cardinality = count(counter, args)
    if expected_count is not None and cardinality != expected_count:
        raise AssertionError("native known-count mismatch %r %d != %d" %
                             (args, cardinality, expected_count))
    previous = None
    visited = set()
    for rank in sample_ranks(cardinality):
        item = native(unranker, args + (rank,))
        if len(item) != sum(lengths):
            raise AssertionError("weaving shape %r rank %d: %r" %
                                 (args, rank, item))
        frequencies = collections.Counter(item)
        for ident, quantity in enumerate(lengths, 1):
            if frequencies[ident] != quantity:
                raise AssertionError("weaving multiplicity %r rank %d: %r" %
                                     (args, rank, item))
        if set(item) != set(range(1, len(lengths) + 1)):
            raise AssertionError("weaving unexpected month id %r" % (item,))
        first = [item.index(ident) for ident in range(1, len(lengths) + 1)]
        last = [len(item) - 1 - item[::-1].index(ident)
                for ident in range(1, len(lengths) + 1)]
        if first != sorted(first) or last != sorted(last):
            raise AssertionError("weaving first/last ordering %r" % (item,))
        if item in visited:
            raise AssertionError("duplicate weaving %r rank %d" % (args, rank))
        if previous is not None and not previous < item:
            raise AssertionError("weaving rank not lexicographic %r rank %d" %
                                 (args, rank))
        visited.add(item)
        previous = item
    for bad_rank in [0, cardinality + 1]:
        if native(unranker, args + (bad_rank,)) != (-1,):
            raise AssertionError("weaving invalid rank accepted %r %d" %
                                 (args, bad_rank))
    print("NATIVE_WEAVING_FAMILY_PASS", lengths, "count", cardinality,
          "checked", len(visited))


# These boundaries are intentionally modest enough for exhaustive native
# rank walks, including middle and final items of larger families.
for args in [
    (5, 2, 1, 4),
    (8, 3, 1, 4),
    (9, 3, 2, 5),
    (10, 4, 1, 5),
]:
    bounded_composition_family(*args)

for lengths, expected in [
    ((2, 2), None),
    ((3, 3, 2), 26),
    ((4, 4), 20),
    ((3, 3, 3), 71),
]:
    weaving_family(lengths, expected)

# Exact already-documented native Year-5000 witness, to pin its reference ABI
# alongside structural test expansion; this is not an end-to-end year oracle.
YEAR_5000_INPUT = (
    0, 100, 0, 0, 7,
    0, 0, 0, 42, 0, 84, 0, 126, 0, 168, 0, 210, 0, 252,
    1)
YEAR_5000_EXPECTED = (0, 5000, 0, 6, 0, 252)
if native("reference/year5000_from_gates_rank.b98", YEAR_5000_INPUT) != YEAR_5000_EXPECTED:
    raise AssertionError("known native Year-5000 reference witness mismatch")
print("NATIVE_YEAR5000_WITNESS_PASS")
print("NATIVE_STAGE1_STRUCTURAL_PROPERTIES_PASS native_invocations=%d" % RUNS[0])
print("SCOPE: native structural properties only; Stage 1 acceptance still OPEN")
