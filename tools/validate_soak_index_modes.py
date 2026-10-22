#!/usr/bin/env python3
"""Read-only cross-check of language-local V1 against language-neutral V2."""
import argparse
import csv
import re
from pathlib import Path


def catalog(content, name, size):
    marker = f"{name}{{{{"
    if content.count(marker) != 1:
        raise AssertionError(f"missing or ambiguous catalog {name}")
    body = content.split(marker, 1)[1].split("}};", 1)[0]
    matches = re.findall(r'\{\s*(\d+),\s*"([^"]+)"\s*\}', body)
    if len(matches) != size:
        raise AssertionError(f"{name}: expected {size}, got {len(matches)}")
    indexes = [int(i) for i, _ in matches]
    names = [s for _, s in matches]
    if sorted(indexes) != list(range(1, size + 1)) or len(set(names)) != size:
        raise AssertionError(f"{name}: non-canonical or duplicate entries")
    return {value: index for index, value in zip(indexes, names)}


def records(path):
    with open(path, encoding="utf-8", newline="") as f:
        return list(csv.reader(f, delimiter="\t", strict=True))


def main():
    p = argparse.ArgumentParser()
    p.add_argument("catalog")
    p.add_argument("names")
    p.add_argument("canonical")
    p.add_argument("expected", type=int)
    a = p.parse_args()
    content = Path(a.catalog).read_text(encoding="utf-8")
    cutlets = catalog(content, "CUTLET_SOURCE_CATALOG", 17)
    months = catalog(content, "MONTH_SOURCE_CATALOG", 47)
    local = records(a.names)
    canonical = records(a.canonical)
    if len(local) != a.expected or len(canonical) != a.expected or a.expected < 1:
        raise AssertionError("wrong number of records")
    for n, (v1, v2) in enumerate(zip(local, canonical), 1):
        if len(v1) != 8 or len(v2) != 8:
            raise AssertionError(f"row {n}: schema is not eight columns")
        try:
            want = [v1[0], v1[1], v1[2], v1[3],
                    str(cutlets[v1[4]]), v1[5],
                    str(months[v1[6]]), v1[7]]
        except KeyError as exc:
            raise AssertionError(f"row {n}: source label not in catalog") from exc
        if v2 != want:
            raise AssertionError(f"row {n}: numeric date not equivalent to source-catalog date")
        if not (1 <= int(v2[4]) <= 17 and 1 <= int(v2[6]) <= 47):
            raise AssertionError(f"row {n}: canonical index out of range")
    print(f"SOAK_CANONICAL_NUMERIC={len(local)}/{a.expected}_PASS")


if __name__ == "__main__":
    main()
