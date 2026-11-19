#!/usr/bin/env python3
"""v110 static mathematical witness: Ada fixed-rail weaving is not the Python family.

No calls to F(c,t), no original source execution, no algorithm modification.
The Python enumerator models the original _moves open-order/close-order rule.
The Ada enumerator models the two hard-coded opening/closing rails in
Month_Weaving.From_Choices. This does NOT prove which stage caused a particular
date mismatch.
"""
from __future__ import annotations
import argparse
from itertools import combinations, permutations
import json
from pathlib import Path

SCHEMA="PASTAFARI_STATIC_MONTH_WEAVING_FAMILY_PROOF_V110/1"
PYA="def choose_month_weaving("
ADA1="function Choose_Month_Weaving"
ADA2="function From_Choices"


def canonical_weaves(lengths:tuple[int,int])->set[tuple[int,...]]:
    if len(lengths)!=2 or any(type(x) is not int or x<2 or x>8 for x in lengths):
        raise ValueError("bounded two-month static examples only")
    a,b=lengths
    result=set()
    for first_positions in combinations(range(a+b),a):
        in_first=set(first_positions)
        seq=tuple(1 if i in in_first else 2 for i in range(a+b))
        if seq.index(1)<seq.index(2) and (
            a+b-1-seq[::-1].index(1)<a+b-1-seq[::-1].index(2)):
            result.add(seq)
    return result


def ada_rails(lengths:tuple[int,int])->set[tuple[int,...]]:
    if len(lengths)!=2 or any(type(x) is not int or x<2 or x>8 for x in lengths):
        raise ValueError("bounded two-month static examples only")
    a,b=lengths
    # Original Ada From_Choices writes opening rail 1..M, interior picks,
    # closing rail 1..M. Every interior permutation is included as a superset
    # of its sequential ticket choices, so this is conservative for Ada.
    interior=(1,)*(a-2)+(2,)*(b-2)
    return {(1,2)+p+(1,2) for p in set(permutations(interior))}


def source_contract(ada_weave:str,ada_calendar:str,python_source:str)->None:
    if (ADA2 not in ada_weave
        or "function Canonical_Weave_Count" not in ada_weave
        or "Output (Pos) := J;" not in ada_weave
        or "Total - 2 * Lengths'Length" not in ada_weave
        or ADA1 not in ada_calendar
        or "Month_Weaving.From_Choices (Lengths, Tickets)" not in ada_calendar
        or "Answer_At (Stream, B (I - 1))" not in ada_calendar
        or "class MonthWeavingFamily:" not in python_source
        or "def _moves(" not in python_source
        or PYA not in python_source
        or "return family.unrank1(rank)" not in python_source):
        raise ValueError("frozen original-source algorithm skeleton has changed")


def prove(ada_weave:str,ada_calendar:str,python_source:str)->dict:
    source_contract(ada_weave,ada_calendar,python_source)
    rows=[]
    for lengths,expected_p,expected_a in (((2,2),2,1),((4,4),20,6)):
        ref=canonical_weaves(lengths)
        ada=ada_rails(lengths)
        missing=ref-ada
        if (len(ref)!=expected_p or len(ada)!=expected_a or
            not ada.issubset(ref) or len(missing)!=expected_p-expected_a):
            raise AssertionError("family comparison not an exact witnessed difference")
        rows.append({
            "month_lengths":list(lengths),
            "python_source_family_count":len(ref),
            "ada_fixed_rails_family_count":len(ada),
            "unrepresentable_python_sequences_in_ada":len(missing),
            "canonical_counterexample":list(min(missing)),
        })
    special=(1,1,1,1,2,2,2,2)
    if (special not in canonical_weaves((4,4)) or
        special in ada_rails((4,4))):
        raise AssertionError("minimum-month-length counterexample invalid")
    return {
        "schema":SCHEMA,
        "status":"STATIC_ORIGINAL_SOURCE_MONTH_WEAVING_FAMILIES_NOT_EQUIVALENT",
        "ada_source_commit":"a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72",
        "python_source_commit":"0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4",
        "proof_examples":rows,
        "minimum_month_length_counterexample":list(special),
        "caused_foundation_day_specific_mismatch_proven":False,
        "no_native_converter_call":True,
        "stop_new_native_soak_dispatch":True,
        "full_years_certified":0,
        "ten_thousand_years_certified":0,
        "algorithmic_independence_certified":False,
    }


def main()->None:
    parser=argparse.ArgumentParser()
    parser.add_argument("--ada-month-weave",required=True,type=Path)
    parser.add_argument("--ada-calendar",required=True,type=Path)
    parser.add_argument("--python-reference",required=True,type=Path)
    parser.add_argument("--report-out",required=True,type=Path)
    a=parser.parse_args()
    result=prove(a.ada_month_weave.read_text(encoding="utf-8"),
                 a.ada_calendar.read_text(encoding="utf-8"),
                 a.python_reference.read_text(encoding="utf-8"))
    with a.report_out.open("x",encoding="utf-8") as f:
        json.dump(result,f,ensure_ascii=False,sort_keys=True,indent=2)
        f.write("\n")
    print("V110_STATIC_ORIGINAL_MONTH_WEAVING_MATH_DIVERGENCE_PROVEN_NO_NATIVE_SOAK")


if __name__=="__main__":
    main()
