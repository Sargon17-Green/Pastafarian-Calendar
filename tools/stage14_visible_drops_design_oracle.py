#!/usr/bin/env python3
"""Independent integer recurrence for all 46 visible drops."""

import json
import math
import random

MODULUS = (1 << 127) - 1
REFERENCE_DAY = 15055671
PAIRS = ((REFERENCE_DAY, REFERENCE_DAY),
         (REFERENCE_DAY-1, REFERENCE_DAY+1),
         (REFERENCE_DAY+2, REFERENCE_DAY-2))


def save(value):
    assert value > 0
    return 1+(value-1)%MODULUS


def stone_rows():
    rows = [[17,29,43,71,101]]
    for number in range(2,47):
        a,b,c,d,e = rows[-1]
        rows.append([save(a*a+3*b+number),save(b*b+5*c+a),
                     save(c*c+7*d+b),save(d*d+11*e+c),save(e*e+13*a+d)])
    assert len(rows)==46 and rows[-1][0]==73799454308499791987382386781055001470
    return rows


def counts(calculation,target):
    def day_count(value):
        distance=value-REFERENCE_DAY
        return 2*distance+1 if distance>=0 else -2*distance
    a,b=day_count(calculation),day_count(target)
    return [a,b,abs(target-calculation)+1,a+b,
            1 if target==calculation else 2 if target>calculation else 3]


def hidden_drops(record,rows):
    hidden=[]
    for k in range(1,8):
        coeff=(2*k+1,3*k+1,4*k+2,4*k+4)
        value=save(record[0]+sum(coeff[j]*record[j+1] for j in range(4))+
                   sum(rows[k-1]))
        for t in range(1,8):
            value=save(value*value+3*value+rows[k-1][(t-1)%5]+t)
        hidden.append(value)
    return hidden


def prime_windows():
    primes=[n for n in range(3,48) if all(n%d for d in range(2,math.isqrt(n)+1))]
    assert len(primes)==14 and primes[0]==3 and primes[-1]==47
    return [[*(primes[step+column-2] for column in range(1,5)),
             (step-1)%5+1] for step in range(1,12)]


def visible_drops(record,rows,hidden):
    visible=[]
    grind=prime_windows()
    for index in range(1,47):
        def predecessor(back):
            offset=index-back
            return visible[offset-1] if offset>0 else hidden[-offset]
        e,f,g=(predecessor(back) for back in (1,3,7))
        row=rows[index-1]
        current=save(sum(row[j]*record[j] for j in range(5))+e+3*f+5*g+index)
        for g1,g2,g3,g4,kind in grind:
            previous=current
            current=save(previous*previous+g1*previous+g2*e+g3*f+
                         g4*g+row[kind-1])
        visible.append(current)
    assert len(visible)==46 and all(1<=value<=MODULUS for value in visible)
    return visible


def main():
    rows=stone_rows()
    anchors=[]
    for calculation,target in PAIRS:
        record=counts(calculation,target)
        hidden=hidden_drops(record,rows)
        visible=visible_drops(record,rows,hidden)
        anchors.append({"calculation_day":calculation,"target_day":target,
                        "counts":[str(x) for x in record],
                        "hidden":[str(x) for x in hidden],
                        "visible":[str(x) for x in visible]})
    rng=random.Random(20261119^14)
    for _ in range(128):
        calculation=REFERENCE_DAY+rng.randrange(-10000,10001)
        target=REFERENCE_DAY+rng.randrange(-10000,10001)
        record=counts(calculation,target)
        visible_drops(record,rows,hidden_drops(record,rows))
    print(json.dumps({"project_id":"PC-BRANCH-FALSE-ARABIC","stage":14,
                      "status":"DESIGN_ORACLE_ONLY","native_evidence":False,
                      "anchor_pairs":3,"visible_results_per_pair":46,
                      "seeded_python_pairs":128,"anchors":anchors},
                     indent=2,sort_keys=True))


if __name__=="__main__":
    main()
