#!/usr/bin/env python3
"""Independent direct-permutation oracle for finite Native Chapel lexical rank/unrank.

This does NOT import the Chapel insertion recurrence or the Python sparse transfer.
Runtime and result are bounded; no production or Stage 6 acceptance claim.
"""
from collections import Counter, defaultdict
from itertools import permutations, product
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]

def parse_csv(value):
    return tuple(map(int, value.split(","))) if value else ()

def accepted_words(lengths):
    base = tuple(i+1 for i, k in enumerate(lengths) for _ in range(k))
    good = []
    all_words = set(permutations(base))
    for word in all_words:
        first = tuple(word.index(i) for i in range(1,len(lengths)+1))
        last = tuple(len(word)-1-word[::-1].index(i) for i in range(1,len(lengths)+1))
        if first == tuple(sorted(first)) and last == tuple(sorted(last)):
            good.append(word)
    return sorted(good), len(all_words)

def main():
    cases = tuple(lengths for m in range(1,5)
                  for lengths in product((1,2,3), repeat=m)
                  if sum(lengths) <= 8)
    oracle = {}
    prefix_reference = Counter()
    total_permutations = total_accepted = 0
    for lengths in cases:
        words, unique = accepted_words(lengths)
        oracle[lengths] = words
        total_permutations += unique
        total_accepted += len(words)
        for word in words:
            for d in range(len(word)+1):
                prefix = word[:d]
                prefix_reference[(lengths,prefix,len(
                    [other for other in words if other[:d] == prefix]))] += 1
    assert (len(cases),total_permutations,total_accepted) == (88,42221,331)
    with tempfile.TemporaryDirectory(prefix="chapel-native-prefix-") as temp:
        binary = Path(temp) / "prefix-probe"
        build = subprocess.run(
            ["chpl", "-M", "src", "-M", "test",
             "test/weaving_native_prefix_rank_probe.chpl", "-o", str(binary)],
            cwd=ROOT, capture_output=True, text=True, timeout=150)
        if build.returncode:
            raise RuntimeError("Native compilation failed:\n"+build.stdout+build.stderr)
        native = subprocess.run(["/usr/bin/time","-f","NATIVE_PREFIX_WALL=%e\\nNATIVE_PREFIX_RSS_KIB=%M",
                                 str(binary)],cwd=ROOT,capture_output=True,text=True,
                                timeout=90)
        if native.returncode:
            raise RuntimeError("Native prefix probe failed:\n"+
                               native.stdout[-4000:]+native.stderr[-4000:])
    observed_counts = {}
    observed_words = defaultdict(list)
    observed_prefixes = Counter()
    observed_invalid = {}
    summaries = {}
    for line in native.stdout.splitlines():
        if not line.startswith("NATIVE_PREFIX_"): continue
        key, data = line.split("=", 1)
        if key == "NATIVE_PREFIX_CASE":
            shape, count = data.split(";")
            lengths = parse_csv(shape)
            assert lengths not in observed_counts
            observed_counts[lengths] = int(count)
        elif key == "NATIVE_PREFIX_WORD":
            shape, rank, word = data.split(";")
            observed_words[parse_csv(shape)].append((int(rank),parse_csv(word)))
        elif key == "NATIVE_PREFIX_COUNT":
            shape, prefix, count = data.split(";")
            observed_prefixes[(parse_csv(shape),parse_csv(prefix),int(count))] += 1
        elif key == "NATIVE_PREFIX_INVALID":
            shape, symbol, count = data.split(";")
            lengths = parse_csv(shape)
            assert lengths not in observed_invalid
            observed_invalid[lengths] = (int(symbol),int(count))
        else:
            assert key not in summaries
            summaries[key] = data
    assert observed_counts == {lengths:len(words) for lengths,words in oracle.items()}
    for lengths, words in oracle.items():
        assert observed_words[lengths] == list(enumerate(words)), lengths
    assert observed_prefixes == prefix_reference, "Incorrect finite prefix counts"
    assert observed_invalid == {
        lengths: (len(lengths),0) for lengths in cases if len(lengths) > 1}
    baseline_layers = int(summaries.pop("NATIVE_PREFIX_INCREMENTAL_BASELINE_LAYERS"))
    visited_layers = int(summaries.pop("NATIVE_PREFIX_INCREMENTAL_VISITED_LAYERS"))
    calls = int(summaries.pop("NATIVE_PREFIX_INCREMENTAL_EVALUATIONS"))
    assert 0 < visited_layers < baseline_layers and calls > 0
    assert summaries == {
        "NATIVE_PREFIX_INCREMENTAL_PREFIX_CHECKS":"2698",
        "NATIVE_PREFIX_INCREMENTAL_RANK_ROUNDTRIPS":"662",
        "NATIVE_PREFIX_INCREMENTAL_RESULT":"PASS",
        "NATIVE_PREFIX_FINITE_FAMILIES":"88",
        "NATIVE_PREFIX_FINITE_WORDS":"331",
        "NATIVE_PREFIX_FINITE_PREFIX_CHECKS":"2698",
        "NATIVE_PREFIX_FINITE_INVALID_CHECKS":str(sum(len(x)>1 for x in cases)),
        "NATIVE_PREFIX_FULL_4244":"NOT_TESTED",
        "NATIVE_PREFIX_STAGE6_ACCEPTANCE":"NOT_CLAIMED",
        "NATIVE_PREFIX_PRODUCTION_CHANGE":"NONE"}, summaries
    wall = float(next(line.split("=",1)[1] for line in native.stderr.splitlines()
                      if line.startswith("NATIVE_PREFIX_WALL=")))
    rss = int(next(line.split("=",1)[1] for line in native.stderr.splitlines()
                   if line.startswith("NATIVE_PREFIX_RSS_KIB=")))
    assert 0 <= wall < 90 and 0 < rss <= 524288, (wall,rss)
    print("WEAVING_NATIVE_PREFIX_FAMILIES=88")
    print("WEAVING_NATIVE_PREFIX_INDEPENDENT_UNIQUE_PERMUTATIONS=42221")
    print("WEAVING_NATIVE_PREFIX_LEX_WORDS=331")
    print("WEAVING_NATIVE_PREFIX_RANK_ROUNDTRIPS=662")
    print("WEAVING_NATIVE_PREFIX_CHECKS=2698")
    print("WEAVING_NATIVE_PREFIX_INVALID_FIRST_MONTHS="+str(len(observed_invalid)))
    print("WEAVING_NATIVE_PREFIX_WALL_SECONDS="+str(wall))
    print("WEAVING_NATIVE_PREFIX_RSS_KIB="+str(rss))
    print("WEAVING_NATIVE_PREFIX_FULL_4244=NOT_TESTED")
    print("WEAVING_NATIVE_PREFIX_STAGE6_ACCEPTANCE=NOT_CLAIMED")
    print("WEAVING_NATIVE_PREFIX_INCREMENTAL_BASELINE_LAYERS="+str(baseline_layers))
    print("WEAVING_NATIVE_PREFIX_INCREMENTAL_VISITED_LAYERS="+str(visited_layers))
    print("WEAVING_NATIVE_PREFIX_INCREMENTAL_SAVED_LAYERS="+str(baseline_layers-visited_layers))
    print("WEAVING_NATIVE_PREFIX_INCREMENTAL_EVALUATIONS="+str(calls))
    print("WEAVING_NATIVE_PREFIX_INCREMENTAL_RESULT=PASS")
    print("WEAVING_NATIVE_PREFIX_RESULT=PASS")

if __name__ == "__main__":
    main()
