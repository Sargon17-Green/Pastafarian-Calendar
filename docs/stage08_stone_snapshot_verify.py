#!/usr/bin/env python3
"""Independent exact seeded-path model and per-cell observation audit."""
import csv
import json
import sys
from pathlib import Path

M = 2**127 - 1
HEADER = ["i", "wheat", "barley", "salt", "bitter", "red"]
def load(path):
    with open(path, encoding="utf-8", newline="") as f:
        rows = list(csv.reader(f, delimiter="\t"))
    if len(rows) != 47 or rows[0] != HEADER:
        raise ValueError(f"invalid table size/header: {path}")
    result = []
    for i, row in enumerate(rows[1:], 1):
        if len(row) != 6 or row[0] != str(i):
            raise ValueError(f"invalid row {i}: {path}")
        vals = [int(s) for s in row[1:]]
        if any(str(v) != s or not 1 <= v <= M for v, s in zip(vals, row[1:])):
            raise ValueError(f"noncanonical/out-of-range row {i}: {path}")
        result.append(vals)
    return result

def reduce(v):
    return v - ((v - 1) // M) * M

def model(sequential):
    rows = [[17, 29, 43, 71, 101]]
    for n in range(2, 47):
        old = rows[-1]
        next_row = old.copy()
        for j, c in enumerate((3, 5, 7, 11, 13)):
            src = next_row if sequential else old
            next_row[j] = reduce(src[j] ** 2 + c * src[(j+1)%5] + (n if j == 0 else src[j-1]))
        rows.append(next_row)
    return rows

def main():
    expected, observed = map(load, sys.argv[1:3])
    if expected != model(False):
        raise ValueError("independent normative JS/Python oracle disagreement")
    seeded = model(True)
    matched = red = 0
    unexpected = []
    print("row\tstone\tnormative\tseeded_prediction\tobserved\tstatus")
    for i, (norm, pred, obs) in enumerate(zip(expected, seeded, observed), 1):
        for j, (n, p, o) in enumerate(zip(norm, pred, obs)):
            status = "MATCH" if n == p else "SEEDED_RED"
            if o != p:
                unexpected.append((i, j+1))
                status = "UNEXPECTED"
            elif n == p:
                matched += 1
            else:
                red += 1
            print(i, HEADER[j+1], n, p, o, status, sep="\t")
    summary = dict(cells=230, matched=matched, seeded_red=red, unexpected=len(unexpected))
    print(json.dumps(summary), file=sys.stderr)
    if unexpected or matched != 6 or red != 224:
        return 1
    return 0

if __name__ == "__main__":
    sys.exit(main())
