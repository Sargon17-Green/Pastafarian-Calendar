#!/usr/bin/env python3
"""Bounded year-5000 prefix projection; does not prove full-year five-field oracle."""
import json
import sys
from pathlib import Path
from zipfile import ZipFile
from hashlib import sha256

AFTER5_SHA = "285da1744f964b96cf4c1b33a0dcf11fb23a07b0ebb2a07ab57a554410e0e5b2"
EXPECTED_MONTH_IDS = (18, 14, 37, 28, 24)
EXPECTED_MONTH_NAMES = ("wielbłąd", "żebro", "burza", "Niniwa", "śledziona")

def main():
    assert len(sys.argv) == 3
    fixture = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
    with ZipFile(sys.argv[1]) as z:
        raw = z.read("STAGE55_REAL_YEAR_INNER_CURSOR_AFTER_5.json")
    assert sha256(raw).hexdigest() == AFTER5_SHA
    cursor = json.loads(raw)
    lengths = fixture["month_lengths"]
    assert fixture["year"] == 5000
    assert fixture["calculation_day"] == -15055671
    assert fixture["first_day"] == -15057702 and fixture["last_day"] == -15053459
    assert len(lengths) == 45 and sum(lengths) == 4244
    assert sum(fixture["cutlet_day_lengths"]) == 4244
    assert fixture["cutlet_day_lengths"][0] == 759
    assert fixture["cutlet_name_indices"][0] == 15  # Akad
    assert tuple(fixture["month_name_indices"][:5]) == EXPECTED_MONTH_IDS
    assert cursor["schema"] == "pastafari-weave-cursor-v1"
    assert cursor["originalLengths"] == lengths
    assert cursor["stepsComputed"] == 5 and cursor["openedUpTo"] == 5
    assert cursor["closedUpTo"] == 0 and cursor["done"] is False
    assert cursor["remaining"][:5] == [n - 1 for n in lengths[:5]]
    assert cursor["remaining"][5:] == lengths[5:]
    assert sum(cursor["remaining"]) == 4239
    assert len(set(EXPECTED_MONTH_NAMES)) == 5
    for day in range(1, 6):
        absolute = fixture["first_day"] + day - 1
        assert fixture["first_day"] <= absolute <= fixture["last_day"]
        prefix = tuple(range(1, day + 1))
        month_day = prefix.count(prefix[-1])
        assert month_day == 1 and day <= fixture["cutlet_day_lengths"][0]
        print(f"STAGE55_PREFIX_ROW POSITION={day} YEAR=5000 CUTLET_INDEX=15 "
              f"CUTLET_DAY={day} MONTH_INDEX={EXPECTED_MONTH_IDS[day-1]} "
              f"MONTH_DAY={month_day}")
    print("STAGE55_YEAR5000_PREFIX_FIVE_FIELDS_PYTHON_PASS CASES=5 FIELDS=5")
    print("STAGE55_FULL_YEAR_CANONICAL_ORACLE_NOT_VERIFIED")
    print("STAGE55_CROSS_ENGINE_SOAK_NOT_VERIFIED")
    print("STAGE55_FINAL_STAGE_PASS_NOT_VERIFIED")

if __name__ == "__main__":
    main()
