#!/usr/bin/env python3
"""SQL+தமிழ் Slice20 independent oracle: explicitly enumerate feasible month counts."""
import argparse

DAYS = (252,253,254,365,492,493,614,615,738,739,1000,1230,1845,2460,3075,4305,5777,5778)

def feasible_month_counts(days):
    return [m for m in range(1,48) if 4*m <= days <= 123*m]

def goldens():
    for days in DAYS:
        choices=feasible_month_counts(days)
        assert choices
        for rank1 in sorted({1,(len(choices)+1)//2,len(choices)}):
            yield days,rank1,choices[rank1-1]

def self_test():
    for days in range(252,5779):
        enumerated=feasible_month_counts(days)
        lower=(days+122)//123
        upper=min(47,days//4)
        assert enumerated==list(range(lower,upper+1)),days
        assert 1<=len(enumerated)<=45
    rows=list(goldens())
    assert len(rows)==50,len(rows)
    assert (252,1,3) in rows and (5778,1,47) in rows
    print("oracle selftest PASS days=5527 goldens=50 enumeration=independent")

def emit_sql():
    print("CREATE TEMP TABLE slice20_goldens(days numeric,rank1 numeric,expected integer);")
    for d,r,e in goldens():
        print(f"INSERT INTO slice20_goldens VALUES ({d},{r},{e});")

if __name__=="__main__":
    p=argparse.ArgumentParser()
    p.add_argument("--self-test",action="store_true")
    p.add_argument("--emit-sql",action="store_true")
    args=p.parse_args()
    if args.self_test==args.emit_sql:
        p.error("choose exactly one action")
    if args.self_test: self_test()
    else: emit_sql()
