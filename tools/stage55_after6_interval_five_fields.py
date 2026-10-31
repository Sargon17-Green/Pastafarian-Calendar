#!/usr/bin/env python3
"""Stage55 independent insertion-count rank-offset and five-field day-six witness."""
import argparse, json, sys
from pathlib import Path
from hashlib import sha256
from stage55_after4_interval_witness import insertion_count, brute_count
sys.set_int_max_str_digits(0)
PIN="285da1744f964b96cf4c1b33a0dcf11fb23a07b0ebb2a07ab57a554410e0e5b2"
KEYS={"schema","originalLengths","remaining","openedUpTo","closedUpTo",
      "rankDecimal","countDecimal","done","stepsComputed"}
def read(path,pin=None):
    data=Path(path).read_bytes()
    digest=sha256(data).hexdigest()
    if pin: assert digest==pin,(path,digest,pin)
    obj=json.loads(data)
    assert set(obj)==KEYS and obj["schema"]=="pastafari-weave-cursor-v1"
    for k in ("rankDecimal","countDecimal"):
        v=obj[k]; assert isinstance(v,str) and v.isascii() and v.isdigit() and v[0] in "123456789"
    return obj,digest
def run(before,after,fixture):
    small=((1,1),(2,1),(1,2),(2,2),(3,2),(2,3),(2,2,2))
    cases=0
    for lengths in small:
        for opened in range(len(lengths)+1):
            assert insertion_count(list(lengths),opened)==brute_count(lengths,opened)
            cases+=1
    assert cases==22
    p,h5=read(before,PIN); q,h6=read(after)
    f=json.loads(Path(fixture).read_text(encoding="utf-8"))
    L=f["month_lengths"]; a=p["remaining"]; b=q["remaining"]
    assert f["year"]==5000 and len(L)==45 and sum(L)==4244
    assert f["first_day"]==-15057702 and f["cutlet_name_indices"][0]==15
    assert p["originalLengths"]==q["originalLengths"]==L
    assert a[:5]==[x-1 for x in L[:5]] and a[5:]==L[5:]
    assert p["stepsComputed"]==5 and q["stepsComputed"]==6
    assert p["openedUpTo"]==5 and p["closedUpTo"]==q["closedUpTo"]==0
    assert p["done"] is q["done"] is False and sum(a)==4239 and sum(b)==4238
    changed=[i+1 for i,(x,y) in enumerate(zip(a,b)) if x-y==1]
    assert len(changed)==1 and sum(x-y for x,y in zip(a,b))==1
    symbol=changed[0]; assert 1<=symbol<=6 and a[symbol-1]>1
    assert q["openedUpTo"]==5+int(symbol==6)
    rp,cp=int(p["rankDecimal"]),int(p["countDecimal"])
    rq,cq=int(q["rankDecimal"]),int(q["countDecimal"])
    assert 1<=rp<=cp and 1<=rq<=cq
    blocks=[]
    for j in range(1,7):
        assert a[j-1]>1
        child=a.copy(); child[j-1]-=1
        count=insertion_count(child,5+int(j==6))
        assert count>0
        blocks.append(count)
        print(f"STAGE55_SIXTH_INDEPENDENT_BLOCK SYMBOL={j} DIGITS={len(str(count))}")
    assert sum(blocks)==cp and blocks[symbol-1]==cq
    lower=sum(blocks[:symbol-1])
    assert lower==rp-rq and lower<rp<=lower+cq
    name=f["month_name_indices"][symbol-1]
    mday=1 if symbol==6 else 2
    assert b[symbol-1]==L[symbol-1]-mday
    print(f"STAGE55_SIXTH_ROW POSITION=6 YEAR=5000 CUTLET_INDEX=15 CUTLET_DAY=6 MONTH_INDEX={name} MONTH_DAY={mday}")
    print(f"STAGE55_SIXTH_INDEPENDENT_PASS SMALL={cases} BLOCKS=6 AFTER5_SHA256={h5} AFTER6_SHA256={h6} REMAINING=4238")
    print("STAGE55_FULL_YEAR_CANONICAL_ORACLE_NOT_VERIFIED")
    print("STAGE55_CROSS_ENGINE_SOAK_NOT_VERIFIED")
    print("STAGE55_FINAL_STAGE_PASS_NOT_VERIFIED")
if __name__=="__main__":
    a=argparse.ArgumentParser()
    a.add_argument("after5",type=Path); a.add_argument("after6",type=Path)
    a.add_argument("fixture",type=Path)
    args=a.parse_args(); run(args.after5,args.after6,args.fixture)
