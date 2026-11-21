#!/usr/bin/env python3
"""Stage18: deterministic Native source generator. Independent itertools oracle.
Never treats source generation as Native PASS or Stage18 acceptance.
"""
import hashlib
import itertools
import json
from pathlib import Path

VECTORS = Path("test/stage18_drop_order_design_vectors.json")
PERMS = list(itertools.permutations(range(1, 7)))
assert len(PERMS) == 720 and len(set(PERMS)) == 720
FINAL = "STAGE18_ALL_GROUPS_OK"

def literal(n):
    assert isinstance(n, int)
    return f"{-n}_" if n < 0 else str(n)

def base512(value):
    if value == 0:
        return (0, 1, [0])
    sign = -1 if value < 0 else 1
    n = abs(value)
    limbs = []
    while n:
        limbs.append(n % 512)
        n //= 512
    return sign, len(limbs), limbs

def order(value):
    rank = value % 720 or 720
    return rank, (6,) + PERMS[rank - 1]

def make_cases():
    result = []
    for value in range(1, 721):
        sign, count, limbs = base512(value)
        rank, expected = order(value)
        result.append(dict(drop=value, raw=[sign, count, *limbs],
                           rank=rank, direct=list(expected), category="exhaustive"))
    parsed = json.loads(VECTORS.read_text(encoding="utf-8"))
    assert parsed["project_id"] == "PC-BRANCH-FALSE-ARABIC"
    assert parsed["stage"] == 18 and parsed["scope"] == "DESIGN_ONLY"
    assert len(parsed["cases"]) == 28
    for vector in parsed["cases"]:
        value = int(vector["drop"])
        sign, count, limbs = base512(value)
        assert sign == vector["bigint_sign"]
        assert count == vector["bigint_limb_count"]
        assert limbs == vector["bigint_limbs_base512_le"]
        rank, expected = order(value)
        assert rank == vector["rank"] and list(expected) == vector["order_direct"]
        result.append(dict(drop=value, raw=[sign, count, *limbs],
                           rank=rank, direct=list(expected), category="design"))
    for value in (0, -719):
        sign, count, limbs = base512(value)
        rank, expected = order(value)
        result.append(dict(drop=value, raw=[sign, count, *limbs],
                           rank=rank, direct=list(expected), category="replay"))
    assert len(result) == 750
    return result

def fixture(cases, index, mutant=None):
    code = ["{ Stage18: generated from pinned itertools/permutation oracle. }"]
    labels = []
    assertions = 0
    for i, case in enumerate(cases):
        tag = f"STAGE18_DROP_{index+i:04d}"
        labels.append(tag + "_OK")
        sign, count, *limbs = case["raw"]
        code.append("z;d:" + "".join(literal(n) + "a;!" for n in case["raw"]))
        code.append("z;b:d;a;!b;s:b;35h;!!o:")
        expected = list(case["direct"])
        if mutant == "bad_order" and i == 0:
            expected[1] = 7
        for pos, value in enumerate(expected):
            code.append(f'o;{pos}+g;!{literal(value)}=~["{tag}_OUTPUT_{pos}_FAIL"0 0/]?')
            assertions += 1
        checks = [
            (f'b;g;!d;-0=', "ARG_CELL"),
            ('b;s;-0=', "ARG_HANDLE"),
            ('o;b;-0=', "OUTPUT_ARG_ALIAS"),
            ('o;d;-0=', "OUTPUT_BIG_ALIAS"),
            (f'd;g;!{literal(sign)}=', "SIGN"),
            (f'd;1+g;!{literal(count)}=', "LIMB_COUNT"),
        ]
        if mutant == "bad_sign" and i == 0:
            checks[4] = (f'd;g;!{literal(-1 if sign != -1 else 1)}=', "SIGN")
        for expr, suffix in checks:
            # Non-alias checks fail on inequality; alias checks fail on equality.
            condition = expr if suffix.startswith("OUTPUT_") else expr + "~"
            code.append(f'{condition}["{tag}_{suffix}_FAIL"0 0/]?')
            assertions += 1
        for limb_index, value in enumerate(limbs, 2):
            code.append(f'd;{limb_index}+g;!{literal(value)}=~["{tag}_LIMB_{limb_index}_FAIL"0 0/]?')
            assertions += 1
        code.append(f'"{tag}_OK"10,')
    final = f"STAGE18_CHUNK_{index:04d}_OK"
    code.append(f'"{final}"10,')
    code.append("[z;0>][%z;1-z:]#")
    return "\n".join(code) + "\n", labels, final, assertions

def chunks():
    cases = make_cases()
    return [(start, cases[start:start+150])
            for start in range(0, len(cases), 150)]

def integrity():
    summaries = []
    for start, cases in chunks():
        data, labels, marker, checks = fixture(cases, start)
        assert len(labels) == len(set(labels))
        assert data.count('STAGE18_DROP_') >= checks
        summaries.append(dict(start=start, cases=len(cases),
                              assertions=checks, final=marker,
                              sha256=hashlib.sha256(data.encode()).hexdigest()))
    assert sum(x["cases"] for x in summaries) == 750
    assert sum(x["assertions"] for x in summaries) >= 750 * 13
    return summaries

if __name__ == "__main__":
    print(json.dumps(integrity(), indent=2))
