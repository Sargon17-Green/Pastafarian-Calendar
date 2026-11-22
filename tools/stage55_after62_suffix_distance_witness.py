#!/usr/bin/env python3
"""Stage55 AFTER61->AFTER62: independent suffix-distance insertion witness.

This is a forward insertion DP whose state is the distance from the first
occurrence of the current largest symbol to the end of the word.  It does not
consume MATLAB selector output.  Tiny brute-force enumerations, the exact
parent partition, and the rank interval are independent controls.
"""
import argparse
import hashlib
import itertools
import json
import math
import sys
from pathlib import Path

sys.set_int_max_str_digits(0)
PROJECT_ID = "PC-BRANCH-MATLAB-POLSKI"
PARENT_SHA256 = "cddc573d509cc6f0cbe705d57125ebbc3baa9cd4f7ab0d0e22edcfb0681d382f"
CHECKPOINT_KEYS = {
    "schema", "originalLengths", "remaining", "openedUpTo", "closedUpTo",
    "rankDecimal", "countDecimal", "done", "stepsComputed"
}
TINY_FAMILIES = ((1, 1), (2, 1), (1, 2), (2, 2), (3, 2), (2, 3), (2, 2, 2))


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def read_checkpoint(path, expected_sha=None):
    raw = Path(path).read_bytes()
    actual = sha256(raw)
    if expected_sha is not None:
        assert actual == expected_sha, ("checkpoint digest mismatch", actual)
    obj = json.loads(raw)
    assert set(obj) == CHECKPOINT_KEYS
    assert obj["schema"] == "pastafari-weave-cursor-v1"
    assert isinstance(obj["done"], bool)
    for key in ("rankDecimal", "countDecimal"):
        value = obj[key]
        assert isinstance(value, str) and value.isascii()
        assert value.isdigit() and value[0] != "0"
    rank, count = int(obj["rankDecimal"]), int(obj["countDecimal"])
    assert 1 <= rank <= count
    assert isinstance(obj["originalLengths"], list)
    assert isinstance(obj["remaining"], list)
    assert all(type(x) is int and x > 0 for x in obj["originalLengths"])
    assert all(type(x) is int and x >= 0 for x in obj["remaining"])
    assert len(obj["originalLengths"]) == len(obj["remaining"])
    return obj, actual


def suffix_distance_count(multiplicities, opened_up_to):
    """Return exact count using suffix-distance distributions.

    State key s is the number of positions from the first occurrence of the
    current largest symbol through the final position, inclusive.

    When adding symbol j with q copies, choose r old-word characters after its
    first occurrence.  The q-2 interior copies can occupy the r+1 suffix gaps
    in C(r+q-2,q-2) ways.  For j > opened_up_to+1, its first occurrence must
    follow the previous largest symbol's first occurrence; in suffix
    coordinates this is exactly the strict tail sum over old keys s > r.
    """
    assert multiplicities and all(type(x) is int and x > 0 for x in multiplicities)
    assert 0 <= opened_up_to <= len(multiplicities)

    # The one-symbol word has its first occurrence at position one.
    distribution = {multiplicities[0]: 1}
    old_size = multiplicities[0]

    for symbol, quantity in enumerate(multiplicities[1:], start=2):
        total_old = sum(distribution.values())

        if quantity == 1:
            # Its unique copy is simultaneously first and last, at the end.
            # It therefore follows every predecessor's first occurrence.
            next_distribution = {1: total_old}
        else:
            next_distribution = {}
            tail_weight = 0
            for suffix_after_first in range(old_size, -1, -1):
                eligible = (
                    total_old
                    if symbol <= opened_up_to + 1
                    else tail_weight
                )
                if eligible:
                    placements = math.comb(
                        suffix_after_first + quantity - 2,
                        quantity - 2
                    )
                    ways = eligible * placements
                    if ways:
                        next_distribution[suffix_after_first + quantity] = ways

                # Make this predecessor state eligible for the next smaller
                # suffix_after_first, where the strict condition is s > r.
                tail_weight += distribution.get(suffix_after_first, 0)

        distribution = next_distribution
        old_size += quantity

    return sum(distribution.values())


def brute_count(lengths, opened_up_to):
    symbols = tuple(
        symbol
        for symbol, quantity in enumerate(lengths, start=1)
        for _ in range(quantity)
    )
    valid = 0
    for word in set(itertools.permutations(symbols)):
        first = [word.index(symbol) for symbol in range(1, len(lengths) + 1)]
        last = [
            len(word) - 1 - word[::-1].index(symbol)
            for symbol in range(1, len(lengths) + 1)
        ]
        if last == sorted(last) and first[opened_up_to:] == sorted(first[opened_up_to:]):
            valid += 1
    return valid


def validate_fixture(fixture):
    lengths = fixture["month_lengths"]
    assert fixture["year"] == 5000
    assert fixture["first_day"] == -15057702
    assert len(lengths) == 45 and sum(lengths) == 4244
    assert len(fixture["month_name_indices"]) == 45
    assert fixture["cutlet_name_indices"][0] == 15
    assert all(type(x) is int and x > 0 for x in lengths)


def derive(after61_path, fixture_path):
    parent, parent_digest = read_checkpoint(after61_path, PARENT_SHA256)
    fixture = json.loads(Path(fixture_path).read_text(encoding="utf-8"))
    validate_fixture(fixture)

    lengths = fixture["month_lengths"]
    remaining = parent["remaining"]
    opened = parent["openedUpTo"]
    closed = parent["closedUpTo"]

    assert parent["originalLengths"] == lengths
    assert parent["stepsComputed"] == 61
    assert opened == 29 and closed == 0 and parent["done"] is False
    assert sum(remaining) == 4183
    consumed = [original - left for original, left in zip(lengths, remaining)]
    assert all(x > 0 for x in consumed[:opened])
    assert all(x == 0 for x in consumed[opened:])
    assert all(left > 0 for left in remaining)
    assert all(left < original for left, original in zip(remaining[:opened], lengths[:opened]))

    # Tiny exact enumeration controls for every opening frontier.
    small_cases = 0
    for family in TINY_FAMILIES:
        for opened_small in range(len(family) + 1):
            assert suffix_distance_count(family, opened_small) == brute_count(
                family, opened_small
            ), (family, opened_small)
            small_cases += 1
    assert small_cases == 22

    # Reproduce the engine's legal first-label frontier, without using its
    # selected label or child counts.
    legal = []
    for symbol in range(closed + 1, len(lengths) + 1):
        quantity = remaining[symbol - 1]
        if quantity == 0:
            continue
        if quantity == lengths[symbol - 1] and symbol != opened + 1:
            continue
        if quantity == 1 and symbol != closed + 1:
            continue
        legal.append(symbol)
    assert legal == list(range(1, 31))

    child_blocks = []
    for symbol in legal:
        child_remaining = remaining.copy()
        quantity = child_remaining[symbol - 1]
        child_remaining[symbol - 1] -= 1
        child_opened = opened + int(quantity == lengths[symbol - 1])
        child_closed = closed + int(quantity == 1)
        assert child_closed == 0
        child_count = suffix_distance_count(child_remaining, child_opened)
        assert child_count > 0
        child_blocks.append((symbol, child_count))
        print(
            f"STAGE55_SIXTY_SECOND_CHILD_BLOCK SYMBOL={symbol} "
            f"DIGITS={len(str(child_count))}",
            flush=True
        )

    parent_count = int(parent["countDecimal"])
    parent_rank = int(parent["rankDecimal"])
    assert len(child_blocks) == 30
    assert sum(count for _, count in child_blocks) == parent_count

    offset = 0
    selected = None
    for symbol, count in child_blocks:
        if offset < parent_rank <= offset + count:
            selected = (symbol, count, parent_rank - offset, offset)
            break
        offset += count
    assert selected is not None
    symbol, child_count, child_rank, preceding = selected

    child_remaining = remaining.copy()
    quantity = child_remaining[symbol - 1]
    child_remaining[symbol - 1] -= 1
    child_opened = opened + int(quantity == lengths[symbol - 1])
    child_closed = closed + int(quantity == 1)

    assert symbol == 23
    assert child_opened == 29 and child_closed == 0
    assert sum(child_remaining) == 4182
    assert 1 <= child_rank <= child_count
    assert preceding + child_rank == parent_rank

    month_index = fixture["month_name_indices"][symbol - 1]
    month_day = lengths[symbol - 1] - child_remaining[symbol - 1]
    assert month_index == 35 and month_day == 3
    row = (
        "STAGE55_SIXTY_SECOND_ROW POSITION=62 YEAR=5000 CUTLET_INDEX=15 "
        f"CUTLET_DAY=62 MONTH_INDEX={month_index} MONTH_DAY={month_day}"
    )

    report = {
        "project_id": PROJECT_ID,
        "transition": "AFTER61->AFTER62",
        "algorithm": "forward suffix-distance insertion DP",
        "after61_sha256": parent_digest,
        "fixture_year": fixture["year"],
        "fixture_first_day": fixture["first_day"],
        "small_brute_cases": small_cases,
        "positive_child_blocks": len(child_blocks),
        "parent_partition_exact": True,
        "rank_interval_exact": True,
        "parent_count_digits": len(str(parent_count)),
        "parent_rank_digits": len(str(parent_rank)),
        "selected_symbol": symbol,
        "child_rank_digits": len(str(child_rank)),
        "child_count_digits": len(str(child_count)),
        "steps_computed": 62,
        "remaining": 4182,
        "opened_up_to": child_opened,
        "closed_up_to": child_closed,
        "month_index": month_index,
        "month_day": month_day,
        "cutlet_index": 15,
        "cutlet_day": 62,
        "expected_row": row,
        "invalid_prefix_positions": [0, 63],
        "after62_validation": "NOT_RUN_PRE_NATIVE"
    }
    print(
        f"STAGE55_SIXTY_SECOND_PREFLIGHT_PASS SMALL={small_cases} "
        f"BLOCKS={len(child_blocks)} SYMBOL={symbol} STEPS=62 "
        f"REMAINING=4182 ROW=62/5000/15/62/35/3 "
        f"AFTER61_SHA256={parent_digest}",
        flush=True
    )
    return parent, fixture, report, child_remaining, child_rank, child_count


def verify_after62(after62_path, parent, fixture, report,
                   expected_remaining, expected_rank, expected_count):
    child, digest = read_checkpoint(after62_path)
    assert child["originalLengths"] == parent["originalLengths"] == fixture["month_lengths"]
    assert child["remaining"] == expected_remaining
    assert child["stepsComputed"] == 62
    assert child["openedUpTo"] == 29 and child["closedUpTo"] == 0
    assert child["done"] is False and sum(child["remaining"]) == 4182
    assert child["rankDecimal"] == str(expected_rank)
    assert child["countDecimal"] == str(expected_count)
    report["after62_sha256"] = digest
    print(report["expected_row"], flush=True)
    print(
        f"STAGE55_SIXTY_SECOND_INDEPENDENT_PASS SMALL=22 BLOCKS=30 "
        f"AFTER61_SHA256={PARENT_SHA256} AFTER62_SHA256={digest} "
        "REMAINING=4182",
        flush=True
    )
    print("STAGE55_FULL_YEAR_CANONICAL_ORACLE_NOT_VERIFIED", flush=True)
    print("STAGE55_CROSS_ENGINE_SOAK_NOT_VERIFIED", flush=True)
    print("STAGE55_FINAL_STAGE_PASS_NOT_VERIFIED", flush=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("after61", type=Path)
    parser.add_argument("fixture", type=Path)
    parser.add_argument("--after62", type=Path)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()

    parent, fixture, report, child_remaining, child_rank, child_count = derive(
        args.after61, args.fixture
    )
    if args.after62 is not None:
        verify_after62(
            args.after62, parent, fixture, report,
            child_remaining, child_rank, child_count
        )
        report["after62_validation"] = "PASS"

    if args.report is not None:
        args.report.write_text(
            json.dumps(report, sort_keys=True, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8"
        )


if __name__ == "__main__":
    main()
