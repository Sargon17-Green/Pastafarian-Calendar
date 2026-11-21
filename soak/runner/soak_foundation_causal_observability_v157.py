#!/usr/bin/env python3
"""v157: trace-dependency DAG and synthetic-only inverse-ambiguity witness.

This does not invoke either historical F(c,t) engine or relabel archived outputs
as intermediate receipts. A passing synthetic snapshot is never proof of the
historical 20 vs 30 cause. The DAG states *which* real fields are missing.
"""
from __future__ import annotations

import argparse
from collections import Counter
from hashlib import sha256
import json
from pathlib import Path

from native_execution_receipt_v038 import canonical
from soak_ada_month_family_divergence_v156 import (
    validate_source_files, SOURCE_LOCKS, PY_COMMIT, ADA_COMMIT
)

SCHEMA = "PASTAFARI_SOAK_FOUNDATION_CAUSAL_OBSERVABILITY_V157/1"
SYNTHETIC = "SYNTHETIC_TOY_NOT_ORIGINAL_FCT"
NEEDED = (
    "year_open_day", "year_close_day", "month_count",
    "month_lengths", "month_weaving", "month_name_indices",
    "target_offset0", "month_id", "day_in_month", "month_index"
)
# This is a partial order. Month names and month weaving are independent
# branches, both needed to compute the canonical month index.
PARENTS = {
    "year_open_day": (),
    "year_close_day": (),
    "month_count": ("year_open_day", "year_close_day"),
    "month_lengths": ("month_count",),
    "month_weaving": ("month_lengths",),
    "month_name_indices": ("month_count",),
    "target_offset0": ("year_open_day", "year_close_day"),
    "month_id": ("month_weaving", "target_offset0"),
    "day_in_month": ("month_weaving", "month_id", "target_offset0"),
    "month_index": ("month_name_indices", "month_id")
}
REQUIRED_SOURCE_TOKENS = {
    "REF-41": (
        "year_offset0 = target_day - (year.open_gate_day + 1)",
        "month_id = structure.month_weaving[year_offset0]",
        "month_name_index = structure.month_name_indices[month_id - 1]",
        "if structure.month_weaving[p] == month_id",
        "month_count = self.choose_month_count(result, year)",
        "month_lengths = self.choose_month_lengths(result, year, month_count)",
        "month_weaving = self.choose_month_weaving(result, month_lengths)",
        "month_names = self.choose_month_names(result, month_count)",
    ),
    "ADA-TELUGU": (
        "Month_Count : constant Positive := Positive (Low_Months + Month_Rank - 1)",
        "Choose_Month_Lengths (Structure_R, Year_Length, Month_Count, Month_Lengths)",
        "Choose_Month_Weaving (Structure_R, Month_Lengths)",
        "Unrank_Distinct (47, Month_Count, Month_Name_Rank)",
        "Month_Id : constant Positive := Positive (Weave (Offset_0 + 1))",
        "if Weave (P) = Month_Id then",
        "Month_Canonical => Positive (Month_Names (Month_Id))",
        "Day_In_Month => B (Day_In_Month)",
    ),
    "ADA-WEAVING": (
        "function From_Choices",
        "Remains (J) := Lengths (J) - 2;",
        "for I in Picks'Range loop",
    ),
}
# Original evidence from v101, v103, v106 contains only terminal tuple values,
# not authenticated year/weave/name intermediate JSON receipts.
HISTORICAL_OBSERVED = {
    "REF-41": (5000,10,503,20,56),
    "ADA-TELUGU": (5000,10,503,30,52),
    "FORTRAN": (5000,10,503,20,56),
}
ARCHIVES = (
    ("Ada", 14472835490, "3d8c594ae761aa6eeb8c11b241755b2f11ef472d41483ffb5be0c1cdc2bd8cbe"),
    ("Python_TS", 14469537094, "bb256c2a8e6d599f7f78aa2264129d4ab4ff0dc0c9b8680077149de55b752ff1"),
    ("Fortran", 14473652463, "7f8e57308aee0c80ffedc9634e59b65d11a1bc94982830dd3217623878e3e48f"),
)


def require(ok: bool, detail: str) -> None:
    if not ok:
        raise ValueError(detail)


def validate_source_mapping(originals: dict[str, bytes]) -> dict:
    verified = validate_source_files(originals)
    for ident, tokens in REQUIRED_SOURCE_TOKENS.items():
        source = originals[ident].decode("utf-8")
        for token in tokens:
            require(token in source, "historical source field dependency changed: " + token)
    return verified


def synthetic_snapshot(month_lengths: tuple[int, ...],
                       weave: tuple[int, ...], names: tuple[int, ...],
                       offset: int, *, engine: str) -> dict:
    require(engine in ("PY_GENERAL", "ADA_TWO_RAIL"),
            "toy family unknown")
    require(2 <= len(month_lengths) <= 3
            and all(type(x) is int and 2 <= x <= 5 for x in month_lengths),
            "toy lengths outside bounded domain")
    require(len(names) == len(month_lengths)
            and len(set(names)) == len(names)
            and all(type(x) is int and 1 <= x <= 47 for x in names),
            "synthetic name mapping not a valid distinct canonical name selection")
    require(len(weave) == sum(month_lengths)
            and Counter(weave) == Counter({
                i+1: n for i,n in enumerate(month_lengths)
            }), "synthetic weave multiplicities do not match month lengths")
    require(type(offset) is int and 0 <= offset < len(weave),
            "toy year offset not a valid index")
    for i in range(len(month_lengths)):
        require(weave.index(i+1) <
                len(weave)-1-weave[::-1].index(i+1),
                "synthetic month missing distinct first and last days")
    require([weave.index(i+1) for i in range(len(month_lengths))] ==
            sorted(weave.index(i+1) for i in range(len(month_lengths))),
            "opening order invalid")
    require([len(weave)-1-weave[::-1].index(i+1)
             for i in range(len(month_lengths))] ==
            sorted(len(weave)-1-weave[::-1].index(i+1)
                   for i in range(len(month_lengths))),
            "closing order invalid")
    if engine == "ADA_TWO_RAIL":
        rail = tuple(range(1,len(month_lengths)+1))
        require(weave[:len(rail)] == rail and weave[-len(rail):] == rail,
                "original Ada fixed two-rail toy condition violated")
    month_id = weave[offset]
    occurrence = weave[:offset+1].count(month_id)
    # Year boundary values are a synthetic coordinate system, not the actual
    # foundation year or a claimed native source intermediate.
    opening = 100
    close = opening + len(weave)
    return {
        "scope": SYNTHETIC, "engine_math_family": engine,
        "year_open_day": opening, "year_close_day": close,
        "month_count": len(month_lengths),
        "month_lengths": list(month_lengths),
        "month_weaving": list(weave),
        "month_name_indices": list(names),
        "target_offset0": offset,
        "target_day": opening + 1 + offset,
        "month_id": month_id, "day_in_month": occurrence,
        "month_index": names[month_id-1]
    }


def verify_snapshot(s: dict) -> None:
    require(type(s) is dict and
            s.get("scope") == SYNTHETIC and
            s.get("engine_math_family") in ("PY_GENERAL","ADA_TWO_RAIL"),
            "synthetic-only snapshot required; no real provenance allowed here")
    base = synthetic_snapshot(tuple(s["month_lengths"]),
                              tuple(s["month_weaving"]),
                              tuple(s["month_name_indices"]),
                              s["target_offset0"],
                              engine=s["engine_math_family"])
    require(s == base, "synthetic intermediate receipt contradicts actual output math")


def minimal_observed_divergences(a: dict, b: dict) -> list[str]:
    verify_snapshot(a)
    verify_snapshot(b)
    require(a["target_day"] == b["target_day"],
            "not the same requested target day")
    differ = {field for field in NEEDED if a[field] != b[field]}
    # Minimal differing fields in the source dependency graph:
    # descendants of any differing parent are not first observable differences.
    first = [field for field in NEEDED if field in differ
             and not any(parent in differ for parent in PARENTS[field])]
    return first


def inverse_ambiguity_demo() -> dict:
    # Two valid Ada two-rail sequences, same target and month output.
    # The month NAME index 20 alone cannot identify the underlying month ID.
    a = synthetic_snapshot((4,4),(1,2,1,1,2,2,1,2),
                           (20,30),2,engine="ADA_TWO_RAIL")
    b = synthetic_snapshot((4,4),(1,2,2,2,1,1,1,2),
                           (30,20),2,engine="ADA_TWO_RAIL")
    require(a["month_id"] != b["month_id"]
            and a["month_index"] == b["month_index"] == 20
            and a["day_in_month"] == b["day_in_month"] == 2,
            "toy inverse-ambiguity counterexample invalid")
    first = minimal_observed_divergences(a,b)
    require(set(first) == {"month_weaving", "month_name_indices"},
            "dependency DAG did not preserve independent divergent branches")
    return {
        "example_a": a,
        "example_b": b,
        "identical_final_month_index": 20,
        "identical_final_day_in_month": 2,
        "different_internal_month_ids": [a["month_id"], b["month_id"]],
        "minimal_observed_differences": first,
        "demonstrates_foundation_causality": False
    }


def inspect(source_root: Path) -> dict:
    paths = {
        "REF-41": source_root/"Python-Turkce"/PY_COMMIT/"tests/normative_reference.py",
        "ADA-TELUGU": source_root/"Ada-Telugu"/ADA_COMMIT/"src/normative_oracle.adb",
        "ADA-WEAVING": source_root/"Ada-Telugu"/ADA_COMMIT/"src/month_weaving.adb",
    }
    originals = {key: path.read_bytes() for key, path in paths.items()}
    verified = validate_source_mapping(originals)
    for key in NEEDED:
        require(key in PARENTS, "missing causal predecessor definition")
    for key, parents in PARENTS.items():
        require(all(parent in NEEDED for parent in parents), "unknown DAG predecessor")
        require(all(NEEDED.index(parent) < NEEDED.index(key) for parent in parents),
                "source DAG has non-topological stage order")
    return {
        "schema": SCHEMA,
        "status": "LOCKED_SOURCE_CAUSAL_DEPENDENCIES_AND_INVERSE_AMBIGUITY_VERIFIED",
        "historical_source_blobs_verified": verified,
        "field_dependency_dag": {key:list(v) for key,v in PARENTS.items()},
        "expected_original_foundation_outputs": {
            k:list(v) for k,v in HISTORICAL_OBSERVED.items()
        },
        "historical_evidence_archives": [
            {"role":role, "artifact_id":aid,"sha256":h}
            for role,aid,h in ARCHIVES
        ],
        "native_intermediate_receipts_for_foundation_attested": False,
        "native_first_internal_numeric_divergence_isolated": False,
        "toy_inverse_ambiguity": inverse_ambiguity_demo(),
        "month_index_means_canonical_name_index_not_month_position": True,
        "source_native_Fct_calls": 0,
        "native_source_executed": False,
        "original_full_years_certified": 0,
        "halt_new_native_soak_dispatch": True,
        "main_changes_permitted": False,
    }


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--sources-root",type=Path,required=True)
    p.add_argument("--report",type=Path,required=True)
    args=p.parse_args()
    out=inspect(args.sources_root)
    with args.report.open("xb") as f:
        f.write(canonical(out)+b"\n")
    print(json.dumps(out,ensure_ascii=False,sort_keys=True))
    return 0


if __name__=="__main__":
    raise SystemExit(main())
