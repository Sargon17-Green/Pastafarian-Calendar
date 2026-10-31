#!/usr/bin/env python3
"""Stage55 AFTER8→AFTER9: independent insertion-count and strict five-field witness.

This verifies one bounded transition, NOT the full-year canonical oracle/soak.
"""
import argparse
import json
import sys
from hashlib import sha256
from pathlib import Path
from stage55_after4_interval_witness import insertion_count, brute_count

sys.set_int_max_str_digits(0)
PIN = "76873d9ec945eb2e3de8d67606f5ee61994049b03dff7796c9f29b632c3442d3"
KEYS = {"schema", "originalLengths", "remaining", "openedUpTo", "closedUpTo",
        "rankDecimal", "countDecimal", "done", "stepsComputed"}

def read_checkpoint(path, pin=None):
    data = Path(path).read_bytes()
    digest = sha256(data).hexdigest()
    if pin is not None:
        assert digest == pin, ("checkpoint digest mismatch", str(path), digest, pin)
    obj = json.loads(data)
    assert set(obj) == KEYS and obj["schema"] == "pastafari-weave-cursor-v1"
    assert isinstance(obj["openedUpTo"], int) and isinstance(obj["closedUpTo"], int)
    for key in ("rankDecimal", "countDecimal"):
        value = obj[key]
        assert isinstance(value, str) and value.isascii() and value.isdigit()
        assert len(value) > 0 and value[0] in "123456789"
    return obj, digest

def run(before, after, fixture):
    small = ((1, 1), (2, 1), (1, 2), (2, 2), (3, 2), (2, 3), (2, 2, 2))
    cases = 0
    for lengths in small:
        for opened in range(len(lengths) + 1):
            assert insertion_count(list(lengths), opened) == brute_count(lengths, opened)
            cases += 1
    assert cases == 22
    p, h7 = read_checkpoint(before, PIN)
    q, h8 = read_checkpoint(after)
    f = json.loads(Path(fixture).read_text(encoding="utf-8"))
    lengths = f["month_lengths"]
    a, b = p["remaining"], q["remaining"]
    assert f["year"] == 5000 and f["first_day"] == -15057702
    assert f["cutlet_name_indices"][0] == 15
    assert len(lengths) == 45 and sum(lengths) == 4244
    assert p["originalLengths"] == q["originalLengths"] == lengths
    assert a == [x - (i < 7) - (i == 3) for i, x in enumerate(lengths)]
    assert p["stepsComputed"] == 8 and q["stepsComputed"] == 9
    assert p["openedUpTo"] == 7 and p["closedUpTo"] == q["closedUpTo"] == 0
    assert p["done"] is False and q["done"] is False
    assert sum(a) == 4236 and sum(b) == 4235
    changed = [i + 1 for i, (x, y) in enumerate(zip(a, b)) if x - y == 1]
    assert len(changed) == 1 and sum(x - y for x, y in zip(a, b)) == 1
    symbol = changed[0]
    assert 1 <= symbol <= 8 and a[symbol - 1] > 1
    assert q["openedUpTo"] == 7 + (symbol == 8)
    rp, cp = int(p["rankDecimal"]), int(p["countDecimal"])
    rq, cq = int(q["rankDecimal"]), int(q["countDecimal"])
    assert 1 <= rp <= cp and 1 <= rq <= cq
    blocks = []
    for j in range(1, 9):
        assert a[j - 1] > 1
        child = a.copy()
        child[j - 1] -= 1
        count = insertion_count(child, 7 + (j == 8))
        assert count > 0
        blocks.append(count)
        print(f"STAGE55_NINTH_INDEPENDENT_BLOCK SYMBOL={j} DIGITS={len(str(count))}")
    assert sum(blocks) == cp, "eight child blocks do not partition parent count"
    assert blocks[symbol - 1] == cq, "native child count differs from independent count"
    lower = sum(blocks[:symbol - 1])
    assert lower == rp - rq and lower < rp <= lower + cq, "rank interval mismatch"
    month_index = f["month_name_indices"][symbol - 1]
    month_day = lengths[symbol - 1] - b[symbol - 1]
    assert month_day == 1 + (symbol <= 7) + (symbol == 4)
    print(f"STAGE55_NINTH_ROW POSITION=9 YEAR=5000 CUTLET_INDEX=15 CUTLET_DAY=9 MONTH_INDEX={month_index} MONTH_DAY={month_day}")
    print(f"STAGE55_NINTH_INDEPENDENT_PASS SMALL={cases} BLOCKS=8 AFTER8_SHA256={h7} AFTER9_SHA256={h8} REMAINING=4235")
    print("STAGE55_FULL_YEAR_CANONICAL_ORACLE_NOT_VERIFIED")
    print("STAGE55_CROSS_ENGINE_SOAK_NOT_VERIFIED")
    print("STAGE55_FINAL_STAGE_PASS_NOT_VERIFIED")

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("after8", type=Path)
    ap.add_argument("after9", type=Path)
    ap.add_argument("fixture", type=Path)
    args = ap.parse_args()
    run(args.after8, args.after9, args.fixture)
