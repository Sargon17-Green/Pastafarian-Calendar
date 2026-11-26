#!/usr/bin/env python3
"""Independent canonical full-year differential, QA only."""
import argparse
import collections
import hashlib
import json
import os
import sys
from pathlib import Path
from stage01_scroll_weaving_reverse_endpoint import (
    Budget, exact_unrank, word_invariants, foundation, FOUNDATION_LENGTHS, SOURCE_SHA256,
)
from stage01_scroll_months_independent import foundation_months
from stage01_scroll_cutlets_independent import foundation_cutlets
from stage01_scroll_month_names_independent import foundation_names

PREFIX = "STAGE01_CANONICAL_YEAR_"
DAYS = 4399
CALC = -15055671

def parse(lines, key, width=None):
    values = [l[len(PREFIX+key+"="):] for l in lines if l.startswith(PREFIX+key+"=")]
    if width is None:
        if len(values) != 1:
            raise ValueError("missing or duplicate marker "+key)
        return values[0]
    rows = [tuple(map(int,v.split(","))) for v in values]
    if len(rows) != DAYS or any(len(r)!=width for r in rows):
        raise ValueError("row count or width "+key)
    if [r[0] for r in rows] != list(range(1,DAYS+1)):
        raise ValueError("nonconsecutive rows "+key)
    return rows

def main():
    if hasattr(sys,"set_int_max_str_digits"):
        sys.set_int_max_str_digits(20000)
    ap=argparse.ArgumentParser()
    ap.add_argument("--actual",type=Path,required=True)
    ap.add_argument("--output",type=Path,required=True)
    args=ap.parse_args()
    lines=args.actual.read_text(encoding="utf8").splitlines()
    report={"project_id":"PC-BRANCH-FORTRAN-ENGLISH","source_commit":os.environ.get("GITHUB_SHA"),
            "source_sha256":SOURCE_SHA256,"source_bytes_verified":False,"full_stage1_accepted":False,
            "comparison_pass":False,"actual_sha256":hashlib.sha256(args.actual.read_bytes()).hexdigest()}
    try:
        oracle=foundation(Budget(180,150000),None)
        m=foundation_months()
        lengths=tuple(m["month_lengths"])
        first=m["calendar_year_first_day_offset"]
        if lengths!=FOUNDATION_LENGTHS or first!=-4021 or sum(lengths)!=DAYS:
            raise ValueError("independent inputs changed")
        if tuple(map(int,parse(lines,"META").split(",")))!=(5000,CALC+first-1,CALC+first+DAYS-1,DAYS,44):
            raise ValueError("year metadata mismatch")
        if tuple(map(int,parse(lines,"LENGTHS").split(",")))!=lengths:
            raise ValueError("length mismatch")
        if parse(lines,"DONE")!=str(DAYS) or parse(lines,"RANK_DONE")!=str(DAYS) or parse(lines,"ORDERING_PASS")!="5/5":
            raise ValueError("completion marker mismatch")
        actual=parse(lines,"ROW",7)
        rank_rows=parse(lines,"RANK_ROW",5)
        cuts=foundation_cutlets()["cutlets"]
        names=foundation_names()["month_name_indices_1based"]
        counts=collections.Counter()
        expected=[]
        for i,mid in enumerate(oracle["weaving"],1):
            offset=first+i-1
            candidates=[c for c in cuts if c["first_day_offset"]<=offset<=c["last_day_offset"]]
            if len(candidates)!=1:
                raise ValueError("cutlet coverage")
            c=candidates[0]
            counts[mid]+=1
            expected.append((i,mid,5000,c["name_index_1based"],offset-c["first_day_offset"]+1,names[mid-1],counts[mid]))
        total=int(oracle["count_decimal"])
        report["count_decimal"]=str(total)
        report["actual_count_decimal"]=parse(lines,"RANK_TOTAL")
        report["count_match"]=report["actual_count_decimal"]==str(total)
        report["month_ids_matched"]=sum(a[1]==b[1] for a,b in zip(actual,expected))
        report["fields_matched"]=sum(x==y for a,b in zip(actual,expected) for x,y in zip(a[2:],b[2:]))
        report["actual_rows"]=actual
        report["expected_rows"]=expected
        word_invariants(lengths,[r[1] for r in actual])
        report["rank_results"]=[]
        for col,rank in enumerate((0,1,total-2,total-1),1):
            n,word,_=exact_unrank(lengths,rank,Budget(180,150000))
            if n!=total:
                raise ValueError("independent count mismatch")
            observed=[r[col] for r in rank_rows]
            word_invariants(lengths,word)
            word_invariants(lengths,observed)
            matched=sum(x==y for x,y in zip(word,observed))
            report["rank_results"].append({"rank_one_based":str(rank+1),"matched":matched,"expected":word,"actual":observed})
            print("CANONICAL_RANK_CASE",col,matched,flush=True)
        report["comparison_pass"]=(report["count_match"] and report["month_ids_matched"]==DAYS
            and report["fields_matched"]==5*DAYS and all(r["matched"]==DAYS for r in report["rank_results"]))
        print("CANONICAL_YEAR_MONTH_IDS={}/4399".format(report["month_ids_matched"]))
        print("CANONICAL_YEAR_FIELDS={}/21995".format(report["fields_matched"]))
        print("CANONICAL_YEAR_RANK_IDS={}/17596".format(sum(r["matched"] for r in report["rank_results"])))
        print("CANONICAL_YEAR_COUNT_MATCH="+str(report["count_match"]).lower())
        print("CANONICAL_YEAR_QA_ONLY_NOT_FULL_STAGE1_ACCEPTANCE")
        if not report["comparison_pass"]:
            raise ValueError("canonical differential mismatch")
    except Exception as exc:
        report["error"]=str(exc)
        raise
    finally:
        args.output.write_text(json.dumps(report,sort_keys=True,indent=2)+"\n",encoding="utf8")

if __name__=="__main__":
    main()
