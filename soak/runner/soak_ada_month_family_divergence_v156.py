#!/usr/bin/env python3
"""v156: locked-source toy witness of Ada vs Python MONTH WEAVING FAMILY mismatch.

No import, compilation, execution or F(c,t) calls on either original engine.
Tests the SOURCE-DEFINITION mathematical family, not the causal chain for the
observed original foundation-day mismatch in Issue #29.
"""
from __future__ import annotations
import argparse
import ast
from collections import Counter
from hashlib import sha1, sha256
from itertools import product
import json
from math import factorial
from pathlib import Path

from native_execution_receipt_v038 import canonical

SCHEMA = "PASTAFARI_SOAK_LOCKED_MONTH_WEAVE_FAMILY_DIVERGENCE_V156/1"
PY_COMMIT = "0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4"
ADA_COMMIT = "a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72"
SOURCE_LOCKS = {
    "REF-41": {
        "commit": PY_COMMIT, "path": "tests/normative_reference.py",
        "git_blob_sha1": "d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53",
    },
    "ADA-TELUGU": {
        "commit": ADA_COMMIT, "path": "src/normative_oracle.adb",
        "git_blob_sha1": "923733d4f8face03586aee304640bf7540c28b4c",
    },
    "ADA-WEAVING": {
        "commit": ADA_COMMIT, "path": "src/month_weaving.adb",
        "git_blob_sha1": "9b02c62dfbc7d8b3b532aba8cd9f1ad0f8b28fef",
    },
}
COMPACT_VECTORS = ((2, 2), (3, 2), (2, 3), (2, 2, 2))


def require(ok: bool, why: str) -> None:
    if not ok:
        raise ValueError(why)


def blob_sha(data: bytes) -> str:
    return sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()


def validate_source_files(originals: dict[str, bytes]) -> dict:
    require(type(originals) is dict and set(originals) == set(SOURCE_LOCKS),
            "requires exactly two locked Ada sources and one Python original")
    verified = {}
    for engine, identity in SOURCE_LOCKS.items():
        data = originals[engine]
        require(type(data) is bytes and blob_sha(data) == identity["git_blob_sha1"],
                "source content does not match historically frozen Git blob: " + engine)
        verified[engine] = {
            **identity, "bytes": len(data), "sha256": sha256(data).hexdigest()
        }
    py = originals["REF-41"].decode("utf-8")
    ao = originals["ADA-TELUGU"].decode("utf-8")
    aw = originals["ADA-WEAVING"].decode("utf-8")
    tree = ast.parse(py)
    family = [n for n in tree.body if isinstance(n, ast.ClassDef)
              and n.name == "MonthWeavingFamily"]
    require(len(family) == 1, "Python general weaving family not unique")
    methods = [n for n in family[0].body if isinstance(n, ast.FunctionDef)]
    moves = [n for n in methods if n.name == "_moves"]
    ranking = [n for n in methods if n.name == "unrank1"]
    require(len(moves) == len(ranking) == 1,
            "Python general open/continue/close move construction unverified")
    move_source = ast.get_source_segment(py, moves[0]) or ""
    require("for index in range(closed, opened):" in move_source
            and "if n == 1 and index != closed:" in move_source
            and "if opened < self.month_count:" in move_source
            and len([x for x in ast.walk(moves[0]) if type(x) is ast.Yield]) == 2,
            "Python dynamically interleaved month opening and closing rule changed")
    require("family = MonthWeavingFamily(month_lengths)" in py
            and "return family.unrank1(rank)" in py,
            "Python original calendar does not select general family")
    require("function Choose_Month_Weaving" in ao
            and "Month_Weaving.From_Choices (Lengths, Tickets)" in ao
            and "Interior : constant Natural := Total - 2 * M_Count" in ao,
            "Ada original calendar no longer selects two-rail tickets")
    require("function From_Choices" in aw and
            "Output (Pos) := J;" in aw
            and "Remains (J) := Lengths (J) - 2;" in aw
            and "for I in Picks'Range loop" in aw
            and "Slots := Slots - 1;" in aw,
            "Ada two-rail fixed opening/closing implementation changed")
    require("for J in Lengths'Range loop" in aw
            and "Interior_Total := Total - 2 * Month_Count;" in aw
            and "function Unrank_Canonical_Weave" in aw,
            "Ada canonical two-rail family source structure changed")
    return verified


def general_family(lengths: tuple[int, ...]) -> tuple[tuple[int, ...], ...]:
    """Independent exhaustive toy oracle: Python _moves open/continue/close rule."""
    require(type(lengths) is tuple and 1 <= len(lengths) <= 3
            and all(type(n) is int and 2 <= n <= 3 for n in lengths),
            "toy enumeration outside bounded family")
    outputs: list[tuple[int, ...]] = []
    total = sum(lengths)
    def visit(rem: tuple[int, ...], opened: int, closed: int,
              prefix: tuple[int, ...]) -> None:
        if len(prefix) == total:
            require(all(x == 0 for x in rem)
                    and opened == closed == len(lengths),
                    "general terminal state invalid")
            outputs.append(prefix)
            return
        for index in range(closed, opened):
            n = rem[index]
            if n <= 0 or (n == 1 and index != closed):
                continue
            nr = list(rem)
            nr[index] -= 1
            next_closed = closed + 1 if nr[index] == 0 else closed
            visit(tuple(nr), opened, next_closed, prefix + (index + 1,))
        if opened < len(lengths):
            index = opened
            nr = list(rem)
            nr[index] -= 1
            next_closed = closed
            if nr[index] == 0:
                require(index == closed, "opening next month would close it out of order")
                next_closed += 1
            visit(tuple(nr), opened + 1, next_closed, prefix + (index + 1,))
    visit(lengths, 0, 0, ())
    return tuple(sorted(outputs))


def two_rail_family(lengths: tuple[int, ...]) -> tuple[tuple[int, ...], ...]:
    """Independent Ada From_Choices toy: fixed open rail/interior/close rail."""
    require(type(lengths) is tuple and 1 <= len(lengths) <= 3
            and all(type(n) is int and 2 <= n <= 3 for n in lengths),
            "toy Ada family outside small bounds")
    m = len(lengths)
    interior = tuple(i+1 for i, n in enumerate(lengths) for _ in range(n - 2))
    from itertools import permutations
    rail = tuple(range(1, m+1))
    return tuple(sorted({rail + p + rail for p in permutations(interior)}))


def enumerate_witnesses(source_files: dict[str, bytes]) -> dict:
    verified = validate_source_files(source_files)
    rows = []
    for lengths in COMPACT_VECTORS:
        general = general_family(lengths)
        ada = two_rail_family(lengths)
        require(set(ada).issubset(general), "Ada rail weave not legal under general semantics")
        missing = sorted(set(general) - set(ada))
        require(missing, "no witness of strict non-equivalence for expected vector")
        count_formula = (factorial(sum(lengths) - 2 * len(lengths))
                         // __import__("math").prod(factorial(x-2) for x in lengths))
        require(count_formula == len(ada), "Ada fixed two-rail count formula mismatch")
        rows.append({
            "month_lengths": list(lengths),
            "python_general_legal_weavings": len(general),
            "ada_two_rail_legal_weavings": len(ada),
            "ada_is_strict_subset": True,
            "lexicographically_first_python_only_witness": list(missing[0]),
            "lexicographically_first_ada_weave": list(ada[0]),
        })
    require(rows[0]["month_lengths"] == [2, 2]
            and rows[0]["python_general_legal_weavings"] == 2
            and rows[0]["ada_two_rail_legal_weavings"] == 1
            and rows[0]["lexicographically_first_python_only_witness"] ==
                [1, 1, 2, 2]
            and rows[0]["lexicographically_first_ada_weave"] ==
                [1, 2, 1, 2],
            "canonical minimal counterexample changed")
    return {
        "schema": SCHEMA,
        "status": "PROVEN_SOURCE_LOCKED_MONTH_WEAVING_FAMILY_NON_EQUIVALENCE",
        "source_files_verified": verified,
        "witnesses": rows,
        "earliest_divergence_type": "CHOICE_FAMILY_DEFINITION_TWO_RAIL_VS_GENERAL_INTERLEAVING",
        "ada_original_calendar_uses_two_rail_ticket_source": True,
        "python_original_calendar_uses_general_family_source": True,
        "source_native_Fct_calls": 0,
        "compiler_invocations": 0,
        "full_calendar_years_calculated": 0,
        "foundation_day_specific_cause_isolated": False,
        "foundation_month_index_20_vs_30_causally_proven": False,
        "historical_source_files_mutated": False,
        "algorithmic_independence_certified": False,
        "full_original_soak_years_certified": 0,
        "halt_new_native_soak_dispatch": True,
        "main_changes_permitted": False,
        "scientific_limit": (
            "Finite toy witnesses prove a strict difference in source-defined "
            "month weave *families*, not which real-year months, counts, ranks, "
            "or canonical choices produced the foundation-day mismatch."
        ),
    }


def main() -> int:
    arg = argparse.ArgumentParser(description=__doc__)
    arg.add_argument("--sources-root", required=True, type=Path)
    arg.add_argument("--report", required=True, type=Path)
    args = arg.parse_args()
    origins = {
        "REF-41": args.sources_root / "Python-Turkce" / PY_COMMIT /
                  "tests/normative_reference.py",
        "ADA-TELUGU": args.sources_root / "Ada-Telugu" / ADA_COMMIT /
                      "src/normative_oracle.adb",
        "ADA-WEAVING": args.sources_root / "Ada-Telugu" / ADA_COMMIT /
                       "src/month_weaving.adb",
    }
    result = enumerate_witnesses({name: path.read_bytes()
                                  for name, path in origins.items()})
    with args.report.open("xb") as f:
        f.write(canonical(result) + b"\n")
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
