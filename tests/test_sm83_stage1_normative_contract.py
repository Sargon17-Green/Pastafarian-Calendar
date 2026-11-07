#!/usr/bin/env python3
"""Independent Stage1 *contract-data* gate, not a full calendar oracle.

AC.1 conformance vectors and checkpoint are pinned normative data from the
repository's authoritative main README, not outputs computed by this SM83
implementation. Mathematical day/work counters are independently checked,
including values larger than the signed-32 native routines can accept.

Do not interpret PASS as full calendar/date conversion or Ge'ez catalog QA.
"""
from __future__ import annotations

import json
from pathlib import Path
from random import Random


PATH = Path(__file__).resolve().parent / "fixtures/sm83_stage1_canonical_vectors.json"
MAIN_SHA = "56bc4173aae4975ded019ef5ab5a36249f1424df"
FOUNDATION = -15055671
M = (1 << 127) - 1
LO32, HI32 = -(1 << 31), (1 << 31) - 1


def day_count(day: int) -> int:
    delta = day - FOUNDATION
    return -2 * delta if delta < 0 else 2 * delta + 1


def inverse_day_count(number: int) -> int:
    if number < 1:
        raise ValueError("day count must be positive")
    delta = -(number // 2) if number % 2 == 0 else (number - 1) // 2
    return FOUNDATION + delta


def work_counters(calculation_day: int, target_day: int) -> tuple[int, int, int, int, int]:
    c, t = calculation_day, target_day
    return (
        day_count(c),
        day_count(t),
        abs(t - c) + 1,
        day_count(c) + day_count(t),
        (1 if t < c else 2 if t == c else 3),
    )


def retained(value: int) -> int:
    return 1 + (value - 1) % M


def check_stage1_normative_contract() -> None:
    data = json.loads(PATH.read_text(encoding="utf-8"))
    assert data["schema"] == "sm83.stage1.canonical-vectors.v1"
    assert data["provenance"] == {
        "repository": "Sargon17-Green/Pastafarian-Calendar",
        "branch": "main",
        "commit": MAIN_SHA,
        "file": "README.md",
        "section": "AC.1 retained-bowl-sum normative conformance vectors",
        "status": "NORMATIVE_DATA_NOT_COMPUTED_BY_SM83_BRANCH",
    }
    assert data["foundation"] == FOUNDATION
    assert int(data["retained_modulus"]) == M
    assert data["result_fields"] == [
        "yearNumber", "cutletCanonicalIndex", "dayInCutlet",
        "monthCanonicalIndex", "dayInMonth",
    ]
    expected_vectors = (
        (-15055671, -15055671, (5000, 10, 503, 20, 56)),
        (-15055671, -15055672, (5000, 10, 502, 32, 21)),
        (-15055671, -15055670, (5000, 14, 1, 29, 38)),
        (-15055671, -15056171, (5000, 10, 3, 1, 29)),
        (-15055671, -15055171, (5000, 14, 500, 18, 76)),
        (-15055671, -15061671, (4999, 5, 158, 43, 3)),
        (-15055671, -15049671, (5001, 12, 95, 5, 81)),
        (-15056905, -15056448, (5000, 9, 167, 10, 65)),
        (-15054437, -15053449, (5000, 14, 10, 1, 45)),
        (-15058171, -15053171, (5002, 5, 288, 29, 13)),
    )
    vectors = data["vectors"]
    assert len(vectors) == len(expected_vectors) == 10
    assert [record["id"] for record in vectors] == list(range(1, 11))
    for vector, (c, t, out) in zip(vectors, expected_vectors):
        assert (vector["c"], vector["t"], tuple(vector["expected"])) == (c, t, out)
        year, cutlet, in_cutlet, month, in_month = out
        assert isinstance(year, int)
        assert 1 <= cutlet <= 17 and 1 <= month <= 47
        assert 1 <= in_cutlet <= 5778 and 1 <= in_month <= 123
        a, b, distance, aggregate, direction = work_counters(c, t)
        assert a > 0 and b > 0 and distance >= 1 and aggregate == a + b
        assert inverse_day_count(a) == c
        assert inverse_day_count(b) == t
        assert direction == (1 if t < c else 2 if t == c else 3)

    checkpoint = data["canonical_checkpoint"]
    assert checkpoint["vector_id"] == 1
    assert (checkpoint["c"], checkpoint["t"]) == (FOUNDATION, FOUNDATION)
    assert checkpoint["work_counts"] == [1, 1, 1, 2, 2]
    assert tuple(checkpoint["expected"]) == expected_vectors[0][2]
    assert checkpoint["order_at_46"] == [4, 5, 2, 3, 6, 1]
    assert len(set(checkpoint["order_at_46"])) == 6
    assert len(checkpoint["hidden_drops"]) == 7
    for number in checkpoint["hidden_drops"] + [
        checkpoint["visible_drop_1"], checkpoint["visible_drop_46"],
    ] + checkpoint["post_stir_bowls"]:
        assert 1 <= int(number) <= M, number
    assert len(checkpoint["post_stir_bowls"]) == 6
    assert checkpoint["year5000_open_gate"] == -15057703
    assert checkpoint["year5000_close_gate"] == -15053459
    gate_lo = checkpoint["year5000_open_gate"]
    gate_hi = checkpoint["year5000_close_gate"]
    assert gate_hi - gate_lo == 4244
    assert 252 <= gate_hi - gate_lo <= 5778
    assert gate_lo < FOUNDATION <= gate_hi

    # The canonical main vector fixture supplies a year gate only when c=F.
    # Applying this gate to c!=F would be an ungrounded assumption.
    for record in vectors[:7]:
        t = record["t"]
        in_year = gate_lo < t <= gate_hi
        assert (record["expected"][0] == 5000) == in_year

    mutant = data["historical_superseded_noncanonical"]
    assert mutant["warning"] == "HISTORICAL_SUPERSEDED_RAW_BOWL_SUM_NOT_NORMATIVE"
    assert mutant["forbidden_expected_for_vector_1"] == [5000, 4, 762, 12, 105]
    assert tuple(mutant["forbidden_expected_for_vector_1"]) != expected_vectors[0][2]
    assert tuple(mutant["forbidden_bowls"]) != tuple(checkpoint["post_stir_bowls"])
    assert mutant["forbidden_open_gate"] != gate_lo
    assert mutant["forbidden_close_gate"] != gate_hi
    assert len(mutant["forbidden_bowls"]) == 6

    assert data["restrictions"] == {
        "gate_gap_days": [42, 963],
        "year_days": [252, 5778],
        "cutlet_names": 17,
        "month_names": 47,
        "month_days": [4, 123],
        "month_count": [3, 47],
    }
    assert [day_count(FOUNDATION + d) for d in range(-3, 4)] == [6, 4, 2, 1, 3, 5, 7]
    for n in (1, 2, M, 2*M, M+1, 0, -M, -1, -(1 << 500)):
        assert 1 <= retained(n) <= M
    assert [retained(n) for n in (M, 2*M, M+1, 0)] == [M, M, 1, M]

    rng = Random(0x6E0F1)
    extremes = [
        -(1 << 4095), -(1 << 128), -(1 << 64),
        LO32-1, LO32, LO32+1, -3, -1, 0, 1, 3,
        HI32-1, HI32, HI32+1, 1 << 64, 1 << 128, 1 << 4095,
    ]
    offsets = extremes + [
        (1 if rng.getrandbits(1) else -1) * rng.getrandbits(rng.randrange(0, 512))
        for _ in range(256)
    ]
    for delta in offsets:
        count = day_count(FOUNDATION + delta)
        expected = (-2 * delta if delta < 0 else 2 * delta + 1)
        assert count == expected and inverse_day_count(count) == FOUNDATION + delta
        assert count % 2 == (0 if delta < 0 else 1)
        assert work_counters(FOUNDATION, FOUNDATION + delta) == (
            1, count, abs(delta) + 1, 1 + count, 1 if delta < 0 else 2 if delta == 0 else 3
        )
    signed_32 = [n for n in offsets if LO32 <= n <= HI32]
    assert LO32 in signed_32 and HI32 in signed_32
    assert any(n < LO32 for n in offsets) and any(n > HI32 for n in offsets)

    # Bounded native arithmetic is verified separately by tests and PyBoy.
    # An unbounded Python result is NOT evidence of SM83 BigInt support.
    assert (1 << 64) > HI32
    print(
        "HOST_STAGE1_NORMATIVE_CONTRACT=PASS "
        "main_sha=" + MAIN_SHA +
        " golden_vectors=10 canonical_checkpoint=1 "
        "historical_mutant=EXCLUDED foundation=-15055671 "
        f"unbounded_integer_cases={len(offsets)} signed32_intersection={len(signed_32)} "
        "calendar_implementation=NOT_CLAIMED native=NOT_EXECUTED",
        flush=True,
    )


if __name__ == "__main__":
    check_stage1_normative_contract()
