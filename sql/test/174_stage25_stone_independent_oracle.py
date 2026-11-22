#!/usr/bin/env python3
"""Independent exact-integer oracle for SQL+தமிழ் Stage 2 stone/bowl QA.

No normative fixture, SQL definition, cross-branch implementation, or floating point.
Generates executable PostgreSQL assertions from an independently written Python model.
"""
from __future__ import annotations
import argparse
import hashlib
import itertools
import json
from pathlib import Path

PROJECT = "PC-BRANCH-SQL-TAMIL"
M = 170141183460469231731687303715884105727
LOCKS = {
    "sql/03_stage02_production_core.sql": "72ae68d3ec009f65f081a099c8bf06e0dd3ed9d6",
    "sql/04_stage02_stone_states.sql": "caed82dc41d7a259953dc817d5e0722038821310",
    "sql/07_stage02_bowls.sql": "0ad25cc4054f46fba66c10dfeffcd81d49f32399",
    "sql/08_stage02_bowl_round.sql": "68a7d99c7cddd1a5b47ef4ef9dc189ab08c53da6",
}

def wrap(value: int) -> int:
    return ((value - 1) % M) + 1

def model_stones() -> dict[int, tuple[int, ...]]:
    state = (17, 29, 43, 71, 101)
    result = {1: state}
    for index in range(2, 47):
        a, b, c, d, e = state
        state = (
            wrap(a*a + 3*b + index),
            wrap(b*b + 5*c + a),
            wrap(c*c + 7*d + b),
            wrap(d*d + 11*e + c),
            wrap(e*e + 13*a + d),
        )
        result[index] = state
    return result

def order_for_drop(drop: int) -> tuple[int, ...]:
    # Independent lexicographic permutation enumeration, not SQL factoradic decoding.
    index = (drop - 1) % 720
    return next(itertools.islice(itertools.permutations((1, 2, 3, 4, 5, 6)), index, None))

def bowl_model(bowls: tuple[int, ...], drop: int, index: int,
               states: dict[int, tuple[int, ...]]) -> tuple[int, ...]:
    assert len(bowls) == 6 and 1 <= index <= 46
    arrangement = order_for_drop(drop)
    stones = states[index]
    out = []
    for bowl_id in range(1, 7):
        position = arrangement.index(bowl_id)
        prev_id = arrangement[(position - 1) % 6]
        next_id = arrangement[(position + 1) % 6]
        previous = bowls[prev_id - 1]
        following = bowls[next_id - 1]
        if position < 3:
            poured = wrap(drop*drop + stones[position]*bowls[bowl_id - 1]
                          + (3, 5, 7)[position]*index)
        else:
            poured = 0
        kind = (0, 1, 2, 3, 4, 0)[position]
        mixed = (bowls[bowl_id - 1] + 2*previous + 3*following
                 + poured + drop + stones[kind])
        out.append(wrap(mixed*mixed + 5*previous*following + index*(position + 1)))
    return tuple(out)

def check_locks(root: Path) -> None:
    for name, expected in LOCKS.items():
        raw = (root / name).read_bytes()
        actual = hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\0" + raw).hexdigest()
        if actual != expected:
            raise ValueError(f"source lock mismatch {name}: {actual}")

def cases():
    states = model_stones()
    bowls_options = ((1, 2, 3, 4, 5, 6), tuple(M-k for k in range(6, 0, -1)))
    for index, drop, bowls in itertools.product((1, 2, 23, 46), (-1, 1, 720, 721), bowls_options):
        yield (index, drop, bowls, bowl_model(bowls, drop, index, states))

def sql():
    statements = ["\\set ON_ERROR_STOP on", "SET statement_timeout = '60s';",
                  "DO $oracle$", "DECLARE", " v_stone pastafari_sql_tamil.stone5;",
                  " v_bowls numeric[];", "BEGIN"]
    for i, v in model_stones().items():
        statements.append(f" v_stone := pastafari_sql_tamil.stone_state({i});")
        checks = " OR ".join(f"(v_stone).{name} IS DISTINCT FROM {number}::numeric"
                             for name, number in zip(("wheat", "barley", "salt", "bitter", "red"), v))
        statements.append(f" IF v_stone IS NULL OR {checks} THEN RAISE EXCEPTION 'stone oracle mismatch index {i}'; END IF;")
    for n, (i, drop, bowls, expected) in enumerate(cases(), 1):
        arr = ",".join(map(str, bowls))
        exp = ",".join(map(str, expected))
        statements.append(f" SELECT pastafari_sql_tamil.bowl_round(ARRAY[{arr}]::numeric[], {drop}::numeric, {i}) INTO v_bowls;")
        statements.append(f" IF v_bowls IS DISTINCT FROM ARRAY[{exp}]::numeric[] THEN RAISE EXCEPTION 'bowl oracle mismatch case {n}'; END IF;")
    statements += [" RAISE NOTICE 'SQL_TAMIL_INDEPENDENT_STONE=230/230 PASS';",
                   " RAISE NOTICE 'SQL_TAMIL_INDEPENDENT_BOWL=32/32 PASS';",
                   "END;", "$oracle$;", ""]
    return "\n".join(statements)

def self_test():
    states = model_stones()
    assert len(states) == 46
    assert states[1] == (17, 29, 43, 71, 101)
    assert states[2] == (378, 1073, 2375, 6195, 10493)
    assert order_for_drop(1) == (1, 2, 3, 4, 5, 6)
    assert order_for_drop(720) == (6, 5, 4, 3, 2, 1)
    assert wrap(0) == M and wrap(M+1) == 1
    all_cases = list(cases())
    assert len(all_cases) == 32
    assert all(len(result) == 6 and all(1 <= v <= M for v in result)
               for _, _, _, result in all_cases)
    generated = sql()
    assert generated == sql()
    assert generated.count(" v_stone := pastafari_sql_tamil.stone_state(") == 46
    assert " INTO v_stone;" not in generated
    print("SQL_TAMIL_INDEPENDENT_ORACLE_STATIC=PASS; stone=46x5; bowl=32")
    print("SQL_TAMIL_INDEPENDENT_ORACLE_NATIVE=NOT_EXECUTED")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--root", type=Path, default=Path("."))
    parser.add_argument("--out-dir", type=Path)
    args = parser.parse_args()
    if not args.self_test and args.out_dir is None:
        parser.error("specify --self-test or --out-dir")
    self_test()
    if args.out_dir is not None:
        check_locks(args.root)
        args.out_dir.mkdir(parents=True, exist_ok=True)
        content = sql()
        (args.out_dir / "independent_stone_bowl.sql").write_text(content, encoding="utf-8")
        (args.out_dir / "oracle_summary.json").write_text(json.dumps({
            "project_id": PROJECT, "source_git_blobs": LOCKS,
            "oracle_sha256": hashlib.sha256(content.encode()).hexdigest(),
            "stone_states": 46, "stone_fields": 230, "bowl_cases": 32,
            "oracle_independence": "Python integer recurrence + lexicographic permutations; no SQL import",
            "native_status": "NOT_EXECUTED",
        }, indent=2) + "\n", encoding="utf-8")
        print("SQL_TAMIL_INDEPENDENT_ORACLE_SQL_SHA256=" + hashlib.sha256(content.encode()).hexdigest())

if __name__ == "__main__":
    main()
