#!/usr/bin/env python3
"""Stage 15 contract oracle for the bounded small factorial operation."""

import json
import math


def build():
    cases = [{"input": n, "expected": math.prod(range(1, n+1))}
             for n in range(7)]
    assert [c["expected"] for c in cases] == [1, 1, 2, 6, 24, 120, 720]
    assert all(cases[n]["expected"] == n*cases[n-1]["expected"]
               for n in range(1, 7))
    return {"project_id": "PC-BRANCH-FALSE-ARABIC", "stage": 15,
            "status": "DESIGN_ONLY_PREDECESSOR_STAGE14_PENDING",
            "input_record": "[n]", "valid_domain": [0, 6],
            "cases": cases, "invalid_cases": [-1, 7, "empty_tuple"],
            "native_acceptance": False}


if __name__ == "__main__":
    print(json.dumps(build(), indent=2, sort_keys=True))
