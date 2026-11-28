#!/usr/bin/env python3
"""Create deterministic BigInt floorDivMod vectors with Python's independent int oracle."""
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
        raise SystemExit("usage: prepare_vectors.py OUTPUT_DIRECTORY")
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
            "a": str(a),
            "b": str(b),
            "expected_q": str(q),
            "expected_r": str(r),
            "tag": tag,
        })

    edge_divisors = [1, 2, 3, 7, 720, BASE - 1, MERSENNE_127]
    edge_values = [
        0, 1, -1, BASE - 1, BASE, BASE + 1,
        BASE**6 - 1, -(BASE**6 - 1),
        MERSENNE_127 - 1, MERSENNE_127, MERSENNE_127 + 1,
        -(MERSENNE_127 + 1),
    ]
    for divisor in edge_divisors:
        for value in edge_values:
            add(value, divisor, "edge")

    for i in range(64):
        digits = rng.randint(40, 600)
        value = random_decimal(rng, digits)
        if i % 2:
            value = -value
        add(value, MERSENNE_127, "mersenne-127")

    for i in range(48):
        digits = rng.randint(40, 600)
        value = random_decimal(rng, digits)
        if i % 2:
            value = -value
        divisor = rng.randint(1, BASE - 1)
        add(value, divisor, "single-limb")

    for i in range(48):
        a_digits = rng.randint(60, 600)
        b_digits = rng.randint(8, 150)
        value = random_decimal(rng, a_digits)
        divisor = random_decimal(rng, b_digits)
        if i % 2:
            value = -value
        if i % 7 == 0:
            value = rng.randrange(0, divisor)
        add(value, divisor, "multi-limb")

    vectors_path = out / "vectors.json"
    payload = json.dumps(vectors, ensure_ascii=False, separators=(",", ":")) + "\n"
    vectors_path.write_text(payload, encoding="utf-8")
    digest = hashlib.sha256(vectors_path.read_bytes()).hexdigest()
    manifest = {
        "oracle": "Python arbitrary-precision int divmod; floor quotient and nonnegative remainder",
        "seed": SEED,
        "base": BASE,
        "mersenne_modulus": str(MERSENNE_127),
        "vector_count": len(vectors),
        "vectors_sha256": digest,
        "categories": {
            "edge": sum(v["tag"] == "edge" for v in vectors),
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
