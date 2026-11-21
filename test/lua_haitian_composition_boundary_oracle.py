#!/usr/bin/env python3
"""QA-only, independent bounded-composition feasibility and resource preflight.

PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Normative source blob: 8fab731dff7011b1a4c3a241c5d1cdefef1c2f1d
The optional source lock checks exact Git blob bytes, not just the filename.
Never imports or executes the Lua oracle, composes a real year, or certifies a date.
"""
from __future__ import annotations

import argparse
import hashlib
import itertools
import json
from math import comb
from pathlib import Path

PROJECT_ID = "PC-BRANCH-LUA-HAITIAN"
ORACLE_GIT_BLOB = "8fab731dff7011b1a4c3a241c5d1cdefef1c2f1d"
YEAR_MIN, YEAR_MAX = 252, 5778
MONTH_MIN, MONTH_MAX = 3, 47
MONTH_DAYS_MIN, MONTH_DAYS_MAX = 4, 123
WITNESS_DAY, WITNESS_LENGTH = -15017676, 5294
QA_MONTH_RESOURCE_CAP = 16  # NOT a normative month limit.


def count_compositions(total: int, slots: int, lo: int = 4, hi: int = 123) -> int:
    """Independent inclusion-exclusion: count ordered x_i in [lo,hi] summing to total."""
    if not isinstance(total, int) or not isinstance(slots, int) or slots < 1 or lo < 1 or hi < lo:
        raise ValueError("invalid composition parameters")
    remaining = total - slots * lo
    width = hi - lo + 1
    if remaining < 0 or remaining > slots * (width - 1):
        return 0
    return sum(
        (-1 if k % 2 else 1) * comb(slots, k) * comb(remaining - k * width + slots - 1, slots - 1)
        for k in range(min(slots, remaining // width) + 1)
    )


def construct_composition(total: int, slots: int, lo: int = 4, hi: int = 123) -> list[int] | None:
    """Independent constructive existence check; does not use counting recurrence."""
    if not (slots >= 1 and slots * lo <= total <= slots * hi):
        return None
    values = [lo] * slots
    remainder = total - slots * lo
    for i in range(slots):
        addition = min(remainder, hi - lo)
        values[i] += addition
        remainder -= addition
    assert remainder == 0 and sum(values) == total
    return values


def month_range(length: int) -> tuple[int, int]:
    return max(MONTH_MIN, (length + MONTH_DAYS_MAX - 1) // MONTH_DAYS_MAX), min(MONTH_MAX, length // MONTH_DAYS_MIN)


def guard_resource(length: int, cap: int, downstream=None) -> dict:
    """Admission for OPTIONAL resource-bounded QA; not a normative rejection."""
    if not isinstance(length, int) or isinstance(length, bool) or not isinstance(cap, int) or isinstance(cap, bool):
        raise ValueError("length/cap must be integers")
    if not 1 <= cap <= MONTH_MAX:
        raise ValueError("invalid QA month cap")
    if not YEAR_MIN <= length <= YEAR_MAX:
        return {"status": "INVALID_YEAR_LENGTH", "admitted": False, "called": False}
    minimum, maximum = month_range(length)
    if minimum > maximum:
        return {"status": "NORMATIVE_MONTH_INFEASIBLE", "admitted": False, "called": False}
    if minimum > cap:
        return {"status": "RESOURCE_REJECT", "admitted": False, "called": False,
                "minMonths": minimum, "maxMonths": maximum, "cap": cap}
    if downstream is not None:
        downstream()  # A spy only in this test. Real compositions are never invoked.
    return {"status": "ADMISSIBLE_TO_NEXT_RESOURCE_GATE", "admitted": True,
            "called": downstream is not None, "minMonths": minimum,
            "maxMonths": maximum, "cap": cap}


def git_blob_sha(data: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()


def selftest() -> int:
    checks = 0
    def check(condition: bool) -> None:
        nonlocal checks
        assert condition, f"selftest {checks + 1} failed"
        checks += 1

    # Enumerative oracle on an intentionally different, tiny domain.
    for slots in range(1, 5):
        sums = {}
        for seq in itertools.product(range(4, 8), repeat=slots):
            s = sum(seq)
            sums[s] = sums.get(s, 0) + 1
        for total in range(0, 33):
            check(count_compositions(total, slots, 4, 7) == sums.get(total, 0))
            check((construct_composition(total, slots, 4, 7) is not None) == (sums.get(total, 0) > 0))

    check(count_compositions(12, 3) == 1)
    check(count_compositions(11, 3) == 0)
    check(count_compositions(5778, 47) == comb(49, 3))
    check(count_compositions(WITNESS_LENGTH, 43) == 0)
    check(count_compositions(WITNESS_LENGTH, 44) == comb(161, 43))
    check(month_range(WITNESS_LENGTH) == (44, 47))
    for m in range(44, 48):
        constructed = construct_composition(WITNESS_LENGTH, m)
        check(constructed is not None and all(4 <= x <= 123 for x in constructed) and sum(constructed) == WITNESS_LENGTH)
        check(count_compositions(WITNESS_LENGTH, m) > 0)
    called = []
    r = guard_resource(WITNESS_LENGTH, QA_MONTH_RESOURCE_CAP, lambda: called.append(1))
    check(r["status"] == "RESOURCE_REJECT" and not r["admitted"] and not r["called"] and not called)
    r = guard_resource(WITNESS_LENGTH, 47, lambda: called.append(1))
    check(r["status"] == "ADMISSIBLE_TO_NEXT_RESOURCE_GATE" and r["called"] and called == [1])
    check(guard_resource(251, 16)["status"] == "INVALID_YEAR_LENGTH")
    check(guard_resource(5779, 16)["status"] == "INVALID_YEAR_LENGTH")
    check(guard_resource(252, 16)["admitted"] is True)
    for invalid in (0, 48, -1):
        try:
            guard_resource(5294, invalid)
        except ValueError:
            check(True)
        else:
            check(False)
    return checks


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check-source", type=Path, help="check exact Git blob SHA of normative_oracle.lua")
    args = parser.parse_args()
    source_status = "NOT_CHECKED"
    if args.check_source:
        digest = git_blob_sha(args.check_source.read_bytes())
        if digest != ORACLE_GIT_BLOB:
            raise SystemExit(f"SOURCE_BLOB_MISMATCH expected={ORACLE_GIT_BLOB} actual={digest}")
        source_status = "MATCH"
    checks = selftest()
    min_months, max_months = month_range(WITNESS_LENGTH)
    counts = {str(m): str(count_compositions(WITNESS_LENGTH, m)) for m in range(min_months, max_months + 1)}
    report = {
        "projectId": PROJECT_ID, "scope": "STATIC_INDEPENDENT_QA_ONLY",
        "normativeSourceBlob": ORACLE_GIT_BLOB, "sourceLock": source_status,
        "day": WITNESS_DAY, "lengthDays": WITNESS_LENGTH,
        "normativeMonthRange": [min_months, max_months],
        "normativeCompositionCounts": counts,
        "qaMonthCap": QA_MONTH_RESOURCE_CAP,
        "resourceScreen": guard_resource(WITNESS_LENGTH, QA_MONTH_RESOURCE_CAP),
        "compositionInvoked": False, "weavingInvoked": False, "fullDateRun": False,
        "selftests": checks,
    }
    print(json.dumps(report, ensure_ascii=False, sort_keys=True, indent=2))
    print(f"COMPOSITION_BOUNDARY_STATIC_SELFTEST_PASS: {checks}/{checks}")
    print("OVER_CAP_RESOURCE_REJECT_WITHOUT_COMPOSITION: PASS")
    print("NORMATIVE_FEASIBILITY_EXISTS: 44..47 MONTHS (NOT FULL-DATE PASS)")


if __name__ == "__main__":
    main()
