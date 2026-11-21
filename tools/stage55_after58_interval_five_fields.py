#!/usr/bin/env python3
"""Stage55 AFTER57→AFTER58: independent insertion-count/rank-interval witness.

This is a bounded one-step witness, not the full-year canonical oracle or soak.
"""
import argparse
import json
import sys
from hashlib import sha256
from pathlib import Path
from stage55_after4_interval_witness import insertion_count, brute_count

sys.set_int_max_str_digits(0)
PIN = "4d9e5b1cb87a2f4bd4d8c0039162b4233fd42246f217a7b2923e6083498b84d1"
KEYS = {"schema", "originalLengths", "remaining", "openedUpTo", "closedUpTo",
        "rankDecimal", "countDecimal", "done", "stepsComputed"}
PREFIX = (1, 2, 3, 4, 5, 6, 7, 4, 8, 9, 10, 9, 11, 6, 12, 13, 14, 15, 16, 16, 17, 7, 18, 2, 19, 20, 19, 5, 21, 22, 9, 1, 7, 23, 3, 8, 23, 14, 10, 9, 24, 2, 25, 18, 7, 15, 26, 3, 3, 21, 27, 22, 28, 11, 5, 5, 22)


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
        assert value and value[0] in "123456789"
    assert isinstance(obj["done"], bool)
    assert isinstance(obj["stepsComputed"], int)
    return obj, digest


def derive(after57_path, fixture_path):
    small = ((1, 1), (2, 1), (1, 2), (2, 2), (3, 2), (2, 3), (2, 2, 2))
    cases = 0
    for lengths in small:
        for opened in range(len(lengths) + 1):
            assert insertion_count(list(lengths), opened) == brute_count(lengths, opened)
            cases += 1
    assert cases == 22

    p, source_digest = read_checkpoint(after57_path, PIN)
    f = json.loads(Path(fixture_path).read_text(encoding="utf-8"))
    lengths = f["month_lengths"]
    a = p["remaining"]
    assert f["year"] == 5000 and f["first_day"] == -15057702
    assert f["cutlet_name_indices"][0] == 15
    assert len(lengths) == 45 and sum(lengths) == 4244
    assert p["originalLengths"] == lengths and len(a) == 45
    assert a == [x - PREFIX.count(i + 1) for i, x in enumerate(lengths)]
    assert p["stepsComputed"] == 57 and len(PREFIX) == 57
    assert p["openedUpTo"] == 28 and p["closedUpTo"] == 0 and p["done"] is False
    assert sum(a) == 4187

    parent_rank, parent_count = int(p["rankDecimal"]), int(p["countDecimal"])
    assert 1 <= parent_rank <= parent_count
    blocks = []
    for j in range(1, 30):
        assert a[j - 1] > 1, ("non-positive candidate", j, a[j - 1])
        child = a.copy()
        child[j - 1] -= 1
        child_opened = p["openedUpTo"] + (j == p["openedUpTo"] + 1)
        count = insertion_count(child, child_opened)
        assert count > 0
        blocks.append(count)
        print(f"STAGE55_FIFTY_EIGHTH_INDEPENDENT_BLOCK SYMBOL={j} DIGITS={len(str(count))}")
    assert len(blocks) == 29 and sum(blocks) == parent_count

    lower = 0
    selected = None
    rank_offset = None
    child_count = None
    for j, count in enumerate(blocks, 1):
        if lower < parent_rank <= lower + count:
            selected = j
            rank_offset = parent_rank - lower
            child_count = count
            break
        lower += count
    assert selected is not None
    assert selected == 18
    assert lower == parent_rank - rank_offset
    assert lower < parent_rank <= lower + child_count

    child_remaining = a.copy()
    child_remaining[selected - 1] -= 1
    child_opened = p["openedUpTo"] + (selected == p["openedUpTo"] + 1)
    month_index = f["month_name_indices"][selected - 1]
    month_day = lengths[selected - 1] - child_remaining[selected - 1]
    cutlet_index = f["cutlet_name_indices"][0]
    full_prefix = list(PREFIX) + [selected]
    assert child_opened == 28
    assert sum(child_remaining) == 4186
    assert month_index == 46
    assert month_day == full_prefix.count(selected) == 3
    assert cutlet_index == 15
    expected_row = (f"STAGE55_FIFTY_EIGHTH_ROW POSITION=58 YEAR=5000 "
                    f"CUTLET_INDEX={cutlet_index} CUTLET_DAY=58 "
                    f"MONTH_INDEX={month_index} MONTH_DAY={month_day}")
    result = {
        "project_id": "PC-BRANCH-MATLAB-POLSKI",
        "transition": "AFTER57->AFTER58",
        "after57_sha256": source_digest,
        "fixture_year": f["year"],
        "fixture_first_day": f["first_day"],
        "small_brute_cases": cases,
        "positive_child_blocks": len(blocks),
        "parent_partition_exact": sum(blocks) == parent_count,
        "parent_rank_digits": len(str(parent_rank)),
        "parent_count_digits": len(str(parent_count)),
        "selected_symbol": selected,
        "rank_lower_offset_digits": len(str(lower)),
        "child_rank_digits": len(str(rank_offset)),
        "child_count_digits": len(str(child_count)),
        "rank_interval_exact": lower < parent_rank <= lower + child_count,
        "steps_computed": 58,
        "remaining": sum(child_remaining),
        "opened_up_to": child_opened,
        "closed_up_to": 0,
        "month_index": month_index,
        "month_day": month_day,
        "cutlet_index": cutlet_index,
        "cutlet_day": 58,
        "expected_row": expected_row,
        "invalid_prefix_positions": [0, 59]
    }
    print(f"STAGE55_FIFTY_EIGHTH_PREFLIGHT_PASS SMALL={cases} BLOCKS={len(blocks)} "
          f"SYMBOL={selected} STEPS=58 REMAINING=4186 ROW=58/5000/15/58/46/3 "
          f"AFTER57_SHA256={source_digest}")
    return p, f, result, child_remaining, rank_offset, child_count


def validate(after58_path, expected, f, child_remaining, rank_offset, child_count):
    q, result_digest = read_checkpoint(after58_path)
    p = expected
    assert q["originalLengths"] == p["originalLengths"] == f["month_lengths"]
    assert q["remaining"] == child_remaining
    assert q["stepsComputed"] == 58 and sum(q["remaining"]) == 4186
    assert q["openedUpTo"] == 28 and q["closedUpTo"] == 0 and q["done"] is False
    assert q["rankDecimal"] == str(rank_offset)
    assert q["countDecimal"] == str(child_count)
    assert 1 <= int(q["rankDecimal"]) <= int(q["countDecimal"])
    assert result_digest
    print(f"STAGE55_FIFTY_EIGHTH_ROW POSITION=58 YEAR=5000 CUTLET_INDEX=15 CUTLET_DAY=58 MONTH_INDEX=46 MONTH_DAY=3")
    print(f"STAGE55_FIFTY_EIGHTH_INDEPENDENT_PASS SMALL=22 BLOCKS=29 AFTER57_SHA256={PIN} "
          f"AFTER58_SHA256={result_digest} REMAINING=4186")
    print("STAGE55_FULL_YEAR_CANONICAL_ORACLE_NOT_VERIFIED")
    print("STAGE55_CROSS_ENGINE_SOAK_NOT_VERIFIED")
    print("STAGE55_FINAL_STAGE_PASS_NOT_VERIFIED")
    return result_digest


def run(after57_path, fixture_path, after58_path=None, report_path=None):
    p, f, result, child_remaining, rank_offset, child_count = derive(after57_path, fixture_path)
    if after58_path is not None:
        result["after58_sha256"] = validate(after58_path, p, f, child_remaining, rank_offset, child_count)
        result["after58_validation"] = "PASS"
    else:
        result["after58_validation"] = "NOT_RUN_PRE_NATIVE"
    if report_path is not None:
        Path(report_path).write_text(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return result


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("after57", type=Path)
    ap.add_argument("fixture", type=Path)
    ap.add_argument("--after58", type=Path)
    ap.add_argument("--report", type=Path)
    args = ap.parse_args()
    run(args.after57, args.fixture, args.after58, args.report)
