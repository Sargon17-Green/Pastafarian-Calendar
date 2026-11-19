#!/usr/bin/env python3
"""v123 pure-number proof of original choose_rank_wide rejection-loop exposure.

Models only the cyclic rejection *selection helper*, never Sauce/F(c,t).
The optimized endpoint result is mathematically identical to the stepwise
loop for any finite admissible stream. No enormous loop is ever executed.
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path

from exact_month_weaving_pure_v119 import ExactMonthWeaves

SCHEMA="PASTAFARI_SOURCE_WIDE_RANK_STEPWISE_REJECTION_RISK_V123/1"


def exact_endpoint(m:int,n:int,first:int,step:int)->dict:
    if (type(m) is not int or m<2 or type(n) is not int or n<1
        or type(first) is not int or not 1<=first<=m
        or type(step) is not int or step not in (-1,1)):
        raise ValueError("invalid synthetic wide rank selection parameters")
    places,space=1,m
    while space<n:
        places+=1
        space*=m
    wide,weight=1,1
    for j in range(places):
        x=1+(first-1+step*j)%m
        wide+=(x-1)*weight
        weight*=m
    if wide<1 or wide>space or weight!=space:
        raise AssertionError("source choice space normalization failed")
    limit=(space//n)*n
    if wide<=limit:
        accepted=wide
        advances=0
    elif step==-1:
        accepted=limit
        advances=wide-limit
    else:
        accepted=1
        advances=space-wide+1
    return {
        "places":places,
        "space_bit_length":space.bit_length(),
        "acceptance_limit_bit_length":limit.bit_length(),
        "rejected":wide>limit,
        "stepwise_rejections_avoided":advances,
        "resulting_rank":(accepted-1)%n+1,
        "rank_was_accepted_immediately":advances==0,
        "first_accepted_wide_value":accepted,
    }


def bounded_source_loop(m:int,n:int,first:int,step:int)->tuple[int,int]:
    """Slow source semantics for SMALL surrogate moduli only."""
    if m>31 or n>m**4:
        raise ValueError("unbounded original while-loop replay forbidden")
    # Validation inherited from exact_endpoint.
    result=exact_endpoint(m,n,first,step)
    places=result["places"]
    space=m**places
    wide=1
    w=1
    for j in range(places):
        wide+=((first-1+step*j)%m)*w
        w*=m
    limit=(space//n)*n
    advances=0
    while wide>limit:
        wide=1+(wide-1+step)%space
        advances+=1
        if advances>space:
            raise AssertionError("bounded source simulation did not terminate")
    return (wide-1)%n+1,advances


def proof()->dict:
    m=2**127-1
    lengths=(123,)*46+(120,)
    n=ExactMonthWeaves(lengths).count()
    first=m-m//65536
    positive=exact_endpoint(m,n,first,+1)
    negative=exact_endpoint(m,n,first,-1)
    if (n.bit_length()!=31483 or
        not positive["rejected"] or not negative["rejected"] or
        positive["places"]!=248 or negative["places"]!=248 or
        positive["stepwise_rejections_avoided"].bit_length()!=31480 or
        negative["stepwise_rejections_avoided"].bit_length()!=31482 or
        positive["resulting_rank"]!=1 or
        negative["resulting_rank"]!=n):
        raise AssertionError("synthetic extreme exact-rejection witness changed")
    return {
        "schema":SCHEMA,
        "status":"SYNTHETIC_ORIGINAL_WIDE_RANK_STEPWISE_RUNTIME_RISK_PROVED_NOT_REAL_FCT",
        "family_month_count":47,
        "family_total_days":sum(lengths),
        "family_count_bits":n.bit_length(),
        "source_M":str(m),
        "synthetic_answer_first":str(first),
        "wide_base_places":positive["places"],
        "wide_space_bits":positive["space_bit_length"],
        "direction_plus_one":{
            "rejected":True,
            "unoptimized_iterations_bits":positive["stepwise_rejections_avoided"].bit_length(),
            "exact_shortcut_rank":"1",
        },
        "direction_minus_one":{
            "rejected":True,
            "unoptimized_iterations_bits":negative["stepwise_rejections_avoided"].bit_length(),
            "exact_shortcut_rank_bits":negative["resulting_rank"].bit_length(),
        },
        "all_small_bounded_cyclic_cases_exact":False,
        "synthetic_answer_stream_proven_reachable_from_actual_sauce":False,
        "source_converter_Fct_executed":False,
        "original_Python_or_Ada_source_modified":False,
        "new_native_soak_dispatch_halted":True,
        "full_original_years_certified":0,
        "ten_thousand_years_certified":0,
    }


def main()->None:
    parser=argparse.ArgumentParser()
    parser.add_argument("--report-out",type=Path,required=True)
    a=parser.parse_args()
    result=proof()
    with a.report_out.open("x",encoding="utf8") as f:
        json.dump(result,f,indent=2,sort_keys=True,ensure_ascii=False)
        f.write("\n")
    print("V123_SYNTHETIC_WIDE_RANK_REJECTION_STEP_COUNT_PROVEN_NO_FCT")


if __name__=="__main__":
    main()
