#!/usr/bin/env python3
"""Bounded Native Chapel root-only feasibility, checked by independent permutations."""
import hashlib
import itertools
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MONTHS = (115,108,119,109,106,81,115,114,117,120,98,52,81,97,121,
          97,115,96,107,61,106,115,119,39,84,103,115,107,55,119,
          97,50,122,110,81,54,101,83,88,40,25,77,98,122,105)
HASH = "925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da"

def value(s, key):
    found = [line.split("=", 1)[1] for line in s.splitlines()
             if line.startswith(key+"=")]
    if len(found) != 1:
        raise AssertionError((key, len(found)))
    return found[0]

def direct_oracle():
    expected = {}
    seen = valid = 0
    for m in range(1, 5):
        for lengths in itertools.product((1,2,3), repeat=m):
            if sum(lengths) > 8: continue
            base = tuple(i+1 for i, k in enumerate(lengths) for _ in range(k))
            accepted = 0
            for word in set(itertools.permutations(base)):
                first = tuple(word.index(i) for i in range(1,m+1))
                last = tuple(len(word)-1-word[::-1].index(i) for i in range(1,m+1))
                accepted += first == tuple(sorted(first)) and last == tuple(sorted(last))
                seen += 1
            expected[lengths] = accepted
            valid += accepted
    assert (len(expected), seen, valid) == (88,42221,331)
    return expected, seen, valid

def main():
    sys.set_int_max_str_digits(10000)
    with tempfile.TemporaryDirectory(prefix="native-poly-") as temp:
        binary = Path(temp)/"probe"
        build = subprocess.run(
            ["chpl","-M","src","-M","test","test/weaving_native_polynomial_probe.chpl",
             "-o",str(binary)],cwd=ROOT,capture_output=True,text=True,timeout=150)
        if build.returncode:
            print(build.stdout+build.stderr,file=sys.stderr)
            raise RuntimeError("Native compilation failed")
        run = subprocess.run(
            ["/usr/bin/time","-f",
             "NATIVE_POLY_WALL=%e\nNATIVE_POLY_RSS_KIB=%M",str(binary)],
            cwd=ROOT,capture_output=True,text=True,timeout=90)
        if run.returncode:
            print(run.stdout[-3000:]+run.stderr[-3000:],file=sys.stderr)
            raise RuntimeError("Native execution failed")
        oracle, seen, valid = direct_oracle()
        actual = {}
        for line in run.stdout.splitlines():
            if line.startswith("WEAVING_NATIVE_POLY_CASE="):
                csv, sep, number = line.split("=",1)[1].partition(";")
                assert sep
                key = tuple(int(x) for x in csv.split(","))
                assert key not in actual
                actual[key] = int(number)
        assert actual == oracle, "Native counts differ from direct positional oracle"
        assert int(value(run.stdout,"WEAVING_NATIVE_POLY_FINITE_CASES")) == 88
        assert tuple(map(int,value(run.stdout,"WEAVING_NATIVE_POLY_MONTH_LENGTHS").split(","))) == MONTHS
        assert int(value(run.stdout,"WEAVING_NATIVE_POLY_MONTHS")) == 45
        assert int(value(run.stdout,"WEAVING_NATIVE_POLY_DAYS")) == 4244
        root = int(value(run.stdout,"WEAVING_NATIVE_POLY_ROOT_DECIMAL"))
        assert root.bit_length() == 22470
        digest = hashlib.sha256(root.to_bytes((root.bit_length()+7)//8,"big")).hexdigest()
        assert digest == HASH
        wall = float(value(run.stderr,"NATIVE_POLY_WALL"))
        rss = int(value(run.stderr,"NATIVE_POLY_RSS_KIB"))
        assert 0 <= wall < 90 and 0 < rss <= 524288, (wall,rss)
        assert value(run.stdout,"WEAVING_NATIVE_POLY_ROOT_COUNT_ONLY") == "COMPLETE"
        assert value(run.stdout,"WEAVING_NATIVE_POLY_RANK_UNRANK") == "NOT_TESTED"
        assert value(run.stdout,"WEAVING_NATIVE_POLY_PRODUCTION_CHANGE") == "NONE"
        print(f"WEAVING_NATIVE_POLY_FINITE_FAMILIES={len(actual)}")
        print(f"WEAVING_NATIVE_POLY_INDEPENDENT_PERMUTATIONS={seen}")
        print(f"WEAVING_NATIVE_POLY_INDEPENDENT_ACCEPTED={valid}")
        print(f"WEAVING_NATIVE_POLY_FULL_MONTHS=45")
        print(f"WEAVING_NATIVE_POLY_FULL_DAYS=4244")
        print(f"WEAVING_NATIVE_POLY_ROOT_BITS={root.bit_length()}")
        print(f"WEAVING_NATIVE_POLY_ROOT_SHA256={digest}")
        print(f"WEAVING_NATIVE_POLY_WALL_SECONDS={wall}")
        print(f"WEAVING_NATIVE_POLY_RSS_KIB={rss}")
        print("WEAVING_NATIVE_POLY_FULL_RANK_UNRANK=NOT_TESTED")
        print("WEAVING_NATIVE_POLY_STAGE6_ACCEPTANCE=NOT_CLAIMED")
        print("WEAVING_NATIVE_POLY_RESULT=PASS")

if __name__ == "__main__":
    main()
