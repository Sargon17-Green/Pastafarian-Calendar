#!/usr/bin/env python3
"""Independent mathematical contract check, NOT a FALSE native execution."""
from __future__ import annotations

import hashlib
import json
import random
from pathlib import Path

M = (1 << 127) - 1
REPO = Path(__file__).resolve().parents[1]
FALSE_TEST = REPO / "test" / "stage02_discovery01_tests.false"
BIGINT = REPO / "src" / "bigint.false"
REFERENCE = REPO / "test" / "normative_reference.false"
BOOTSTRAP = REPO / "src" / "monster_bootstrap.false"
ORIGINAL_SHA = "6148142e82fd3a90817e2c46b55381f1ba66612abf6ed822ffc5288d24ca56b2"


def regular_mod(x: int) -> int:
    """Euclidean remainder, in [0,M)."""
    return divmod(x, M)[1]


def save_oracle(x: int) -> int:
    """Mathematical SAVE boundary contract; independent of FALSE source."""
    quotient, remainder = divmod(x, M)
    assert quotient * M + remainder == x
    if x != 0 and remainder == 0:
        return M
    return remainder


def check() -> dict[str, object]:
    source = FALSE_TEST.read_text(encoding="utf-8")
    bigint = BIGINT.read_text(encoding="utf-8")
    ref = REFERENCE.read_text(encoding="utf-8")
    bootstrap = BOOTSTRAP.read_text(encoding="utf-8")
    # A structural gate, not a native program proof.
    assert source.count("30o;!") == 6, "Expected six Euclidean calls"
    assert source.count("36o;!") == 6, "Expected six SAVE calls"
    assert "DISCOVERY01_SHAPE_M0_2M0_3M0_MPLUS1_1" in source
    assert "DISCOVERY01_RECREATED_NATIVE_SHAPE_VERIFIED" in source
    assert "19: ثابت M" in bigint
    assert "16: باقي إقليدي" in bigint
    assert "36: SAVE" in ref
    assert "[]l:" in bootstrap
    assert "oldRemainder" not in bootstrap

    anchors = (
        (0, 0, 0),
        (1, 1, 1),
        (M - 1, M - 1, M - 1),
        (M, 0, M),
        (M + 1, 1, 1),
        (2 * M, 0, M),
        (2 * M + 1, 1, 1),
        (3 * M, 0, M),
        (3 * M - 1, M - 1, M - 1),
        (-1, M - 1, M - 1),
        (-M, 0, M),
        (-2 * M, 0, M),
        (-M - 1, M - 1, M - 1),
    )
    mismatches = 0
    for x, normal, saved in anchors:
        assert regular_mod(x) == normal, ("anchor regular", x)
        assert save_oracle(x) == saved, ("anchor SAVE", x)
        mismatches += normal != saved

    rng = random.Random(20261103)
    for _ in range(384):
        x = rng.randrange(-(1 << 320), 1 << 320)
        if _ % 8 == 0:
            x = rng.randrange(-1000, 1001) * M
        r = regular_mod(x)
        s = save_oracle(x)
        assert 0 <= r < M
        assert (s == r) if (x == 0 or r != 0) else (s == M)
        assert x % M == s % M

    return {
        "project_id": "PC-BRANCH-FALSE-ARABIC",
        "stage": "2_DISCOVERY_01_RECREATED",
        "status": "MATHEMATICAL_CONTRACT_PASS_NATIVE_NOT_RUN",
        "native_false_pass": False,
        "historical_zip_recovered": False,
        "historical_zip_sha256_reference_only": ORIGINAL_SHA,
        "checked_anchor_cases": len(anchors),
        "distinct_anchor_cases": mismatches,
        "deterministic_property_cases": 384,
        "false_test_sha256": hashlib.sha256(source.encode("utf-8")).hexdigest(),
        "false_test_calls_regular": source.count("30o;!"),
        "false_test_calls_save": source.count("36o;!"),
    }


if __name__ == "__main__":
    print(json.dumps(check(), ensure_ascii=False, sort_keys=True, indent=2))
