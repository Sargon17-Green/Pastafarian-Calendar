#!/usr/bin/env python3
"""Independent integer design oracle for the seven hidden drops, without FALSE source."""

import json
import random

M = (1 << 127) - 1
REFERENCE_DAY = 15055671
PAIRS = ((REFERENCE_DAY, REFERENCE_DAY),
         (REFERENCE_DAY - 1, REFERENCE_DAY + 1),
         (REFERENCE_DAY + 2, REFERENCE_DAY - 2))


def save(value):
    assert value > 0
    return (value - 1) % M + 1


def stones():
    rows = [(17, 29, 43, 71, 101)]
    for number in range(2, 47):
        a, b, c, d, e = rows[-1]
        rows.append((save(a*a + 3*b + number), save(b*b + 5*c + a),
                     save(c*c + 7*d + b), save(d*d + 11*e + c),
                     save(e*e + 13*a + d)))
    assert len(rows) == 46 and rows[0] == (17, 29, 43, 71, 101)
    assert rows[-1][0] == 73799454308499791987382386781055001470
    return rows


def day_count(day):
    offset = day - REFERENCE_DAY
    return 2*offset + 1 if offset >= 0 else -2*offset


def work_counts(calculation, target):
    a, b = day_count(calculation), day_count(target)
    direction = 2 if target > calculation else 3 if target < calculation else 1
    return (a, b, abs(target - calculation) + 1, a + b, direction)


def drops(counts, rows):
    result = []
    for k in range(1, 8):
        coefficients = (2*k + 1, 3*k + 1, 4*k + 2, 4*k + 4)
        current = counts[0] + sum(coefficients[j] * counts[j+1]
                                  for j in range(4)) + sum(rows[k-1])
        current = save(current)
        for step in range(1, 8):
            kind = (step - 1) % 5
            current = save(current*current + 3*current +
                           rows[k-1][kind] + step)
        result.append(current)
    assert len(result) == 7 and all(1 <= n <= M for n in result)
    return result


def main():
    rows = stones()
    anchors = []
    for calculation, target in PAIRS:
        counts = work_counts(calculation, target)
        anchors.append({"calculation_day": calculation, "target_day": target,
                        "counts": [str(x) for x in counts],
                        "drops": [str(x) for x in drops(counts, rows)]})
    rng = random.Random(20261118 ^ 12)
    for _ in range(384):
        a = REFERENCE_DAY + rng.randrange(-10000, 10001)
        b = REFERENCE_DAY + rng.randrange(-10000, 10001)
        result = drops(work_counts(a, b), rows)
        assert len(result) == 7 and all(1 <= x <= M for x in result)
    print(json.dumps({"project_id": "PC-BRANCH-FALSE-ARABIC",
                      "stage": 12, "native_evidence": False,
                      "status": "DESIGN_ORACLE_ONLY",
                      "anchor_pairs": len(PAIRS), "expected_native_results": 21,
                      "seeded_python_pairs": 384, "anchors": anchors},
                     indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
