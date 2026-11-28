"""Audit Native signed-digit receipts without executing the instrumented Native harness."""
import argparse
import copy
import json
import re
from pathlib import Path

from qa31cm_kernel_equations import M, ORIGIN

CASES=(((0,21,1,12),(-1,10)),((0,12,1,21),(1,-10)),((0,11,1,11),(0,0)),((0,0,0,0),()))


def check(ok, reason):
    if not ok:
        raise ValueError(reason)


def expected(a,b,save_a,save_b):
    def count(n):
        t=n+ORIGIN
        return -2*t if t<0 else 2*t+1
    return list(map(str,(count(a),count(b),abs(a-b)+1,count(a)+count(b),
                         2+(b>a)-(b<a),1+(save_a-1)%M,1+(save_b-1)%M)))


def audit(rows):
    check(len(rows)==len(CASES),"case count")
    for row,(fields,increments) in zip(rows,CASES):
        check(tuple(row["fields"])==fields,"exact native input")
        a,b=(1-2*fields[0])*fields[1],(1-2*fields[2])*fields[3]
        oracle=expected(a,b,a,b)
        base=row["baseline"]
        check(row["native_reference"]==base["output"]==oracle and not base["crossings"]
              and not base["forced"],"baseline and genuine native references")
        test_mutation=bool(increments and increments[0])
        check(("opposite_first_arm" in row)==test_mutation,"mutation scope")
        branches=[(row["healthy"],False)]
        if test_mutation:
            branches.append((row["opposite_first_arm"],True))
        for run,forced in branches:
            check(tuple(run["fields"])==fields and run["forced"]==forced and
                  len(run["crossings"])==len(increments),"trace case or count")
            previous_sum,previous_opcode,extra=0,32,0
            for n,(event,z) in enumerate(zip(run["crossings"],increments)):
                should_flip=forced and n==0
                chosen="v" if z<0 else ">"
                physical=">" if (z>=0)!=should_flip else "v"
                check(event["inc"]==z and event["prior"]==previous_sum and
                      event["write"]==[previous_opcode,ord(chosen)],"physical p and real accumulator")
                check(event["physical_fetch"]==chosen and event["executed"]==physical
                      and event["arm"]==("+" if physical==">" else "-")
                      and bool(event.get("forced"))==should_flip,"wrong arithmetic arm")
                times=[event[key] for key in ("enter_tick","write_tick","fetch_tick","arm_tick","join_tick")]
                check(all(a<b for a,b in zip(times,times[1:])),"temporal gate lineage")
                length=61 if physical==">" else 59
                check(times[-1]-times[0]==length,"real chamber length")
                previous_sum+=(-z if should_flip else z)
                check(event["after"]==previous_sum,"incorrect live join")
                previous_opcode=ord(physical)
                extra+=length-2
            check(run["arithmetic_ticks"]==base["arithmetic_ticks"]+extra and
                  run["ticks"]==base["ticks"]+extra,"arithmetic route length")
            for key in ("route_sha256","arithmetic_route_sha256"):
                check(all(re.fullmatch(r"[0-9a-f]{64}",r[key]) for r in (base,run)),"motion hash")
            shift=increments[0] if forced else 0
            computed=expected(a-shift,b-shift,a,b)
            check(run["output"]==computed,"seven output fields")
            if forced:
                check(row["counterfactual_native_reference"]==computed,"second independent oracle")
    a,b=rows[:2]
    check(a["baseline"]["arithmetic_route_sha256"]==b["baseline"]["arithmetic_route_sha256"]
          and a["healthy"]["arithmetic_route_sha256"]!=b["healthy"]["arithmetic_route_sha256"],
          "equal-length legal inputs must acquire distinct arithmetic routes")
    check(rows[-1]["healthy"]["arithmetic_route_sha256"]==rows[-1]["baseline"]["arithmetic_route_sha256"],
          "zero digits must preserve the original route")
    return {"valid_original_candidate_pairs":len(rows),"observed_healthy_crossings":6,
            "opposite_arm_numeric_witnesses":2,"same_length_same_sign_route_split":True}


def tamper(rows):
    corruptions=[
        ("healthy",0,"inc",0),("healthy",0,"prior",9),("healthy",1,"write",[32,62]),
        ("healthy",0,"physical_fetch",">"),("healthy",0,"arm","+"),("healthy",0,"after",1),
        ("healthy",0,"enter_tick",0),("opposite_first_arm",0,"executed","v"),
        ("opposite_first_arm",0,"forced",False)]
    for group,i,k,value in corruptions:
        changed=copy.deepcopy(rows)
        changed[0][group]["crossings"][i][k]=value
        try: audit(changed)
        except ValueError: continue
        raise ValueError("undetected Native receipt corruption "+k)
    return len(corruptions)


if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("receipt",type=Path)
    rows=json.loads(parser.parse_args().receipt.read_bytes())
    report=audit(rows)
    print(json.dumps(dict(report,negative_controls=tamper(rows)),sort_keys=True))
