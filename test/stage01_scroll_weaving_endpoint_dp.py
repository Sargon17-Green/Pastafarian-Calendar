#!/usr/bin/env python3
"""Independent exact Scroll seal-32 endpoint-insertion count/unrank.

PROJECT_ID: PC-BRANCH-FORTRAN-ENGLISH
Authority: Megilat_HaItim_Yehuda_FINAL_2026-09-18.md, sha256
7b834f4a444e021bb65164282b851af960a6dbc0be3d458c2412181773b9db7b.

All copies of each month are indistinguishable. First occurrences must be in
month-ID order, as must last occurrences. The largest month ID must occur
last overall. If f_i(a) is the number of legal words for months 1..i whose
first occurrence of i is at a (its last is at total length L), inserting
n>=2 copies of month i+1 with new first position x gives
 f_(i+1)(x) = C(L+n-x-1,n-2) * sum_(a<=x-1) f_i(a).
For a new month after already-open month IDs, first-order is already met,
and the sum is over every old a. In an already-open group only LAST ordering
remains; appending n copies contributes C(L+n-1,n-1) interleavings.

No candidate Fortran or pinned Python calendar is imported. Outputs are
component evidence, NEVER a declaration of full Stage1 acceptance.
"""
from __future__ import annotations
import argparse
import hashlib
import itertools
import json
import math
import sys
import time
from dataclasses import dataclass
from pathlib import Path

PROJECT_ID = "PC-BRANCH-FORTRAN-ENGLISH"
FOUNDATION_LENGTHS = (114,117,99,66,103,83,96,65,80,122,77,101,113,103,118,63,
 109,119,120,118,104,100,103,43,95,58,82,113,100,88,122,113,73,112,
 100,122,122,117,106,100,115,118,99,108)
FOUNDATION_COUNT_SHA256 = "c6d66ea1cf3aa809393bcee7b3232a2f5ff8705897f1016f6d8532d7800d5ab3"

class ResourceLimit(RuntimeError):
    pass

@dataclass
class Budget:
    max_states: int = 100000
    max_seconds: float = 120.0
    def __post_init__(self):
        self.start = time.monotonic()
        self.events = 0
        self.peak = 0
    def check(self, states: int):
        self.events += 1
        self.peak = max(self.peak, states)
        if states > self.max_states:
            raise ResourceLimit(f"state budget {states}>{self.max_states}")
        if self.events % 512 == 0 and time.monotonic()-self.start > self.max_seconds:
            raise ResourceLimit(f"runtime exceeded {self.max_seconds}s")
    def final(self):
        if time.monotonic()-self.start > self.max_seconds:
            raise ResourceLimit(f"runtime exceeded {self.max_seconds}s")


def append_color(f: dict[int,int], length: int, n: int,
                 require_first: bool, budget: Budget) -> tuple[dict[int,int],int]:
    if n < 1:
        raise ValueError("month multiplicity must be positive")
    total = length+n
    if n == 1:
        budget.check(1)
        return {total:sum(f.values())},total
    output = {}
    prefix = 0
    unrestricted = sum(f.values()) if not require_first else 0
    for x in range(1,length+2):
        if require_first:
            prefix += f.get(x-1,0)
        else:
            prefix = unrestricted
        if prefix:
            output[x] = prefix * math.comb(total-x-1,n-2)
            budget.check(len(output))
    budget.final()
    return output,total


def suffix_count(remaining: tuple[int,...], opened: int, budget: Budget) -> int:
    if not remaining or any(type(n) is not int or n<0 for n in remaining):
        raise ValueError("invalid remaining multiplicities")
    if not 0<=opened<=len(remaining):
        raise ValueError("invalid opened boundary")
    if any(n==0 for n in remaining[opened:]):
        raise ValueError("unopened month already exhausted")
    active = [n for n in remaining[:opened] if n]
    if any(remaining[i]==0 and any(remaining[:i]) for i in range(opened)):
        raise ValueError("closed months not an ordered prefix")
    unseen = list(remaining[opened:])
    if not active and not unseen:
        return 1
    if active:
        ways=1
        length=active[0]
        for n in active[1:]:
            ways *= math.comb(length+n-1,n-1)
            length+=n
            budget.check(1)
        if not unseen:
            return ways
        n=unseen.pop(0)
        f,length=append_color({1:ways},length,n,False,budget)
    else:
        n=unseen.pop(0)
        f,length={1:1},n
    for n in unseen:
        f,length=append_color(f,length,n,True,budget)
    budget.final()
    return sum(f.values())


def options(remaining,opened):
    for i in range(min(opened+1,len(remaining))):
        if remaining[i] == 0:
            continue
        nxt=list(remaining)
        nxt[i]-=1
        seen=max(opened,i+1)
        if any(nxt[j]==0 and any(nxt[:j]) for j in range(seen)):
            continue
        yield i+1,tuple(nxt),seen


def unrank(lengths: tuple[int,...], rank: int, budget: Budget,
           total: int | None = None) -> tuple[int,tuple[int,...]]:
    if any(type(n) is not int or n<1 for n in lengths):
        raise ValueError("positive month lengths required")
    if type(rank) is not int or rank<0:
        raise ValueError("rank must be a nonnegative integer")
    total=suffix_count(lengths,0,budget) if total is None else total
    if rank>=total:
        raise ValueError("rank outside legal weavings")
    result=[]
    state,opened=lengths,0
    while any(state):
        for color,nxt,seen in options(state,opened):
            size=suffix_count(nxt,seen,budget)
            if rank<size:
                result.append(color)
                state,opened=nxt,seen
                break
            rank-=size
        else:
            raise AssertionError("no eligible lexicographic branch")
        budget.final()
    if rank != 0:
        raise AssertionError("nonzero terminal rank")
    return total,tuple(result)


def brute(lengths):
    counts=list(lengths)
    n=sum(lengths)
    result=[]
    word=[]
    def visit():
        if len(word)==n:
            first=[word.index(i) for i in range(1,len(lengths)+1)]
            last=[n-1-word[::-1].index(i) for i in range(1,len(lengths)+1)]
            if first==sorted(first) and last==sorted(last):
                result.append(tuple(word))
            return
        for i,c in enumerate(counts):
            if c:
                counts[i]-=1
                word.append(i+1)
                visit()
                word.pop()
                counts[i]+=1
    visit()
    return result


def self_test():
    shapes=ranks=0
    for colors in range(1,5):
        for lengths in itertools.product((1,2,3),repeat=colors):
            if sum(lengths)>10:
                continue
            expected=brute(lengths)
            assert suffix_count(lengths,0,Budget(100000,30))==len(expected)
            shapes+=1
            for rank,word in enumerate(expected):
                total,got=unrank(lengths,rank,Budget(100000,30))
                assert total==len(expected) and got==word,(lengths,rank)
                ranks+=1
    middle=(4,5,6,7,8)
    total,word=unrank(middle,0,Budget(100000,30))
    assert total==63668444337486
    assert len(word)==sum(middle)
    assert all(word.count(i)==middle[i-1] for i in range(1,6))
    assert [word.index(i) for i in range(1,6)]==sorted(word.index(i) for i in range(1,6))
    assert [len(word)-1-word[::-1].index(i) for i in range(1,6)] == sorted(
       len(word)-1-word[::-1].index(i) for i in range(1,6))
    assert (shapes,ranks)==(115,1408)
    return shapes,ranks


def foundation(budget: Budget, do_unrank: bool, candidate_path: str | None):
    from stage01_scroll_gate_independent import choose_index
    from stage01_scroll_months_independent import foundation_months
    months=foundation_months()
    lengths=tuple(months["month_lengths"])
    assert lengths==FOUNDATION_LENGTHS
    assert len(lengths)==44 and sum(lengths)==4399
    total=suffix_count(lengths,0,budget)
    decimal=str(total)
    digest=hashlib.sha256(decimal.encode("ascii")).hexdigest()
    assert len(decimal)==7021 and digest==FOUNDATION_COUNT_SHA256
    question_day=months["calendar_year_first_day_offset"]
    rank=choose_index(0,question_day,4,32,total)
    report={
        "project_id":PROJECT_ID,
        "scope":"INDEPENDENT_SCROLL_SEAL32_COMPONENT_NOT_STAGE1_ACCEPTANCE",
        "full_stage1_accepted":False,
        "months":len(lengths),"days":sum(lengths),
        "lengths":list(lengths),"count_decimal":decimal,
        "count_digits":len(decimal),"count_sha256":digest,
        "rank_zero_based":str(rank),
        "rank_sha256":hashlib.sha256(str(rank).encode("ascii")).hexdigest(),
        "whole_weaving_compared":False,"five_fields_compared":False,
    }
    if do_unrank:
        verified_total,weaving=unrank(lengths,rank,budget,total)
        assert verified_total==total and len(weaving)==4399
        assert [weaving.count(i) for i in range(1,45)]==list(lengths)
        first=[weaving.index(i) for i in range(1,45)]
        last=[len(weaving)-1-weaving[::-1].index(i) for i in range(1,45)]
        assert first==sorted(first) and last==sorted(last)
        report["weaving"]=list(weaving)
        report["weaving_sha256"]=hashlib.sha256(
            ",".join(map(str,weaving)).encode("ascii")).hexdigest()
        if candidate_path:
            candidate=json.loads(Path(candidate_path).read_text(encoding="utf-8"))
            assert candidate["year"]["month_count"]==44
            assert candidate["year"]["day_count"]==4399
            assert candidate["months"]["lengths"]==list(lengths)
            assert candidate["months"]["weaving"]==list(weaving)
            report["whole_weaving_compared"]=True
            from stage01_scroll_cutlets_independent import foundation_cutlets
            from stage01_scroll_month_names_independent import foundation_names
            cuts=foundation_cutlets()
            names=foundation_names()["month_name_indices_1based"]
            entry=[x for x in cuts["cutlets"]
                   if x["first_day_offset"]<=0<=x["last_day_offset"]]
            assert len(entry)==1
            cutlet=entry[0]
            index=-question_day
            month_id=weaving[index]
            day_in_month=sum(x==month_id for x in weaving[:index+1])
            fields=(5000,cutlet["name_index_1based"],
                    1-cutlet["first_day_offset"],names[month_id-1],day_in_month)
            expected=tuple(candidate["date_fields"][key] for key in (
                "year_number","cutlet_canonical_index","day_in_cutlet",
                "month_canonical_index","day_in_month"))
            assert fields==expected,(fields,expected)
            assert candidate["months"]["name_indices"]==names
            report["five_fields_compared"]=True
            report["independent_foundation_fields"]=list(fields)
    report["peak_states"]=budget.peak
    return report


def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--self-test",action="store_true")
    ap.add_argument("--foundation",action="store_true")
    ap.add_argument("--full-unrank",action="store_true")
    ap.add_argument("--candidate-json")
    ap.add_argument("--output")
    ap.add_argument("--lengths")
    ap.add_argument("--rank",type=int)
    ap.add_argument("--max-states",type=int,default=100000)
    ap.add_argument("--max-seconds",type=float,default=120)
    a=ap.parse_args()
    if hasattr(sys,"set_int_max_str_digits"):
        sys.set_int_max_str_digits(20000)
    if a.max_states<=0 or a.max_seconds<=0:
        ap.error("resource limits must be positive")
    if a.full_unrank and not a.foundation:
        ap.error("full-unrank requires --foundation")
    if a.candidate_json and not a.full_unrank:
        ap.error("candidate-json requires --full-unrank")
    if a.self_test:
        shapes,ranks=self_test()
        print(f"STAGE01_ENDPOINT_DP_SHAPES={shapes}")
        print(f"STAGE01_ENDPOINT_DP_RANKS={ranks}")
        print("STAGE01_ENDPOINT_DP_BRUTE_DIFFERENTIAL=PASS")
    budget=Budget(a.max_states,a.max_seconds)
    if a.foundation:
        report=foundation(budget,a.full_unrank,a.candidate_json)
        if a.output:
            Path(a.output).parent.mkdir(parents=True,exist_ok=True)
            Path(a.output).write_text(json.dumps(report,ensure_ascii=False,
                sort_keys=True,indent=2)+"\n",encoding="utf-8")
        print(f"STAGE01_ENDPOINT_DP_FOUNDATION_MONTHS={report['months']}")
        print(f"STAGE01_ENDPOINT_DP_FOUNDATION_DAYS={report['days']}")
        print(f"STAGE01_ENDPOINT_DP_FOUNDATION_COUNT_DIGITS={report['count_digits']}")
        print(f"STAGE01_ENDPOINT_DP_FOUNDATION_COUNT_SHA256={report['count_sha256']}")
        print(f"STAGE01_ENDPOINT_DP_FOUNDATION_PEAK_STATES={budget.peak}")
        print(f"STAGE01_ENDPOINT_DP_WHOLE_WEAVING_COMPARED={report['whole_weaving_compared']}")
        print(f"STAGE01_ENDPOINT_DP_FIVE_FIELDS_COMPARED={report['five_fields_compared']}")
        print("STAGE01_ENDPOINT_DP_COMPONENT_ONLY_NOT_FULL_STAGE1_ACCEPTANCE")
    if a.lengths:
        lengths=tuple(int(x) for x in a.lengths.split(","))
        if a.rank is None:
            result=suffix_count(lengths,0,budget)
            print("COUNT="+str(result))
        else:
            result,word=unrank(lengths,a.rank,budget)
            print("COUNT="+str(result))
            print("WORD="+",".join(map(str,word)))
    if not (a.self_test or a.foundation or a.lengths):
        ap.error("select --self-test, --foundation or --lengths")

if __name__=="__main__":
    try:
        main()
    except ResourceLimit as exc:
        print("STAGE01_ENDPOINT_DP_RESOURCE_LIMIT_INCONCLUSIVE="+str(exc))
        raise SystemExit(2)
