#!/usr/bin/env python3
"""Create deterministic BigInt vectors using Python's independent int oracle."""
from __future__ import annotations
import hashlib
import json
import pathlib
import random
import sys

BASE = 10**7
MERSENNE_127 = (1 << 127) - 1
SEED = 20261128


def random_decimal(rng: random.Random, digits: int) -> int:
    text = str(rng.randrange(1, 10))
    text += "".join(str(rng.randrange(10)) for _ in range(digits - 1))
    return int(text)


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: prepare_mersenne_vectors.py OUTPUT_DIRECTORY")
    out = pathlib.Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    rng = random.Random(SEED)
    vectors: list[dict[str, str]] = []

    def add(a: int, b: int, tag: str) -> None:
        if b <= 0:
            raise AssertionError("all divisors must be positive")
        q, r = divmod(a, b)
        assert 0 <= r < b and a == q * b + r
        vectors.append({
            "a": str(a), "b": str(b),
            "expected_q": str(q), "expected_r": str(r), "tag": tag,
        })

    # Includes x = 2^128-1, which forces the 31-bit top-limb fold.
    mersenne_edges = [
        0, 1, -1,
        MERSENNE_127 - 1, MERSENNE_127, MERSENNE_127 + 1,
        -(MERSENNE_127 + 1),
        (1 << 127), (1 << 127) + 1,
        (1 << 128) - 1, 1 << 128, (1 << 128) + 1,
        -((1 << 128) - 1), -(1 << 128), -((1 << 128) + 1),
        2 * MERSENNE_127, -(2 * MERSENNE_127),
    ]
    for value in mersenne_edges:
        add(value, MERSENNE_127, "mersenne-edge")

    other_edge_values = [0, 1, -1, BASE**6 - 1, -(BASE**6 - 1)]
    for divisor in [1, 2, 3, 7, 720, BASE - 1]:
        values = other_edge_values + [
            divisor - 1, divisor, divisor + 1, -(divisor + 1)
        ]
        for value in values:
            add(value, divisor, "other-edge")

    for i in range(32):
        value = random_decimal(rng, rng.randint(40, 600))
        if i % 2:
            value = -value
        add(value, MERSENNE_127, "mersenne-127")

    for i in range(24):
        value = random_decimal(rng, rng.randint(40, 600))
        if i % 2:
            value = -value
        add(value, rng.randint(1, BASE - 1), "single-limb")

    for i in range(24):
        value = random_decimal(rng, rng.randint(60, 600))
        divisor = random_decimal(rng, rng.randint(8, 150))
        if i % 2:
            value = -value
        if i % 7 == 0:
            value = rng.randrange(0, divisor)
        add(value, divisor, "multi-limb")

    vectors_path = out / "vectors.json"
    payload = json.dumps(vectors, ensure_ascii=False, separators=(",", ":")) + "\n"
    vectors_path.write_text(payload, encoding="utf-8")
    manifest = {
        "oracle": "Python arbitrary-precision int divmod; floor quotient and nonnegative remainder",
        "seed": SEED,
        "base": BASE,
        "mersenne_modulus": str(MERSENNE_127),
        "vector_count": len(vectors),
        "vectors_sha256": hashlib.sha256(vectors_path.read_bytes()).hexdigest(),
        "categories": {
            "mersenne_edge": sum(v["tag"] == "mersenne-edge" for v in vectors),
            "other_edge": sum(v["tag"] == "other-edge" for v in vectors),
            "mersenne_127": sum(v["tag"] == "mersenne-127" for v in vectors),
            "single_limb": sum(v["tag"] == "single-limb" for v in vectors),
            "multi_limb": sum(v["tag"] == "multi-limb" for v in vectors),
        },
    }
    (out / "vectors_manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(manifest, sort_keys=True))


if __name__ == "__main__":
    main()
