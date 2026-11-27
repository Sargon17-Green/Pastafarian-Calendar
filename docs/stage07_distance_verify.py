#!/usr/bin/env python3
"""Stage07 differential: unchanged independent Stage06 interval oracle."""
import csv
import sys
from stage06_distance_tag_scale_oracle import HEADER, vectors

def verify(expected_path, actual_path):
    expected = list(vectors())
    with open(expected_path, encoding="ascii", newline="") as f:
        r = csv.reader(f, delimiter="\t")
        assert next(r) == HEADER
        assert [tuple(map(int, row)) for row in r] == expected
    reds = controls = production_checks = legacy_checks = 0
    with open(actual_path, encoding="ascii", newline="") as f:
        r = csv.reader(f, delimiter="\t")
        assert next(r) == ["c", "t"] + [p+"_"+k for p in ("direct","decimal","context","legacy") for k in HEADER[2:]]
        for e, row in zip(expected, r, strict=True):
            v = tuple(map(int, row))
            assert len(v) == 22 and v[:2] == e[:2], (e, v)
            for i in (2, 7, 12):
                assert v[i:i+5] == e[2:], (e, v, i)
                production_checks += 5
            wanted = (e[2], e[3], 2*e[4]-1, e[5], e[6])
            assert v[17:22] == wanted, (e, v)
            legacy_checks += 5
            if e[0] == e[1]:
                assert v[17:22] == e[2:]
                controls += 1
            else:
                assert v[19] != e[4]
                reds += 1
    assert (production_checks, legacy_checks, reds, controls) == (121500, 40500, 8010, 90)
    print("STAGE07_PRODUCTION_COMPARISONS=121500/121500")
    print("STAGE07_LEGACY_COMPARISONS=40500/40500")
    print("STAGE07_LEGACY_RED_ROWS=8010")
    print("STAGE07_LEGACY_CONTROL_ROWS=90")
    print("STAGE07_UNEXPECTED_MISMATCHES=0")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit(2)
    verify(*sys.argv[1:])
