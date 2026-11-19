#!/usr/bin/env python3
"""Bounded eleven-row oracle for the Stage 14 grind dependency."""

import argparse
import hashlib
import json
import math
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
FIXTURE=ROOT/"test"/"stage11_visible_grind_55.false"
PRIMES=[candidate for candidate in range(3,48)
        if not any(candidate%divisor==0 for divisor in range(2,math.isqrt(candidate)+1))]
assert len(PRIMES)==14 and PRIMES[-1]==47
FINAL="STAGE11_PATCH_55_RESULTS_110_INPUTS_VERIFIED"


def value(grind,column):
    assert 1<=grind<=11 and 1<=column<=5
    return (grind-1)%5+1 if column==5 else PRIMES[grind+column-2]


def build():
    lines=['{ توسعة المرحلة 11: إحدى عشرة جولة × خمسة أعمدة. }',
           '[~["STAGE11_PATCH_FAILURE"10,0 0/]?]e:']
    cases=[]
    for grind in range(1,12):
        for column in range(1,6):
            expected=value(grind,column)
            lines.append(f"z;d:{grind}a;!{column}a;!d;28h;!!v:")
            lines.append(f"v;{expected}=e;!d;g;!{grind}=e;!d;1+g;!{column}=e;!")
            label=f"STAGE11_PATCH_CASE_{grind:02d}_{column}_OK"
            lines.append(f'"{label}"10,')
            cases.append({"grind":grind,"column":column,"expected":expected,
                          "label":label})
    lines.extend((f'"{FINAL}"10,',"[z;0>][%z;1-z:]#"))
    return "\n".join(lines)+"\n",cases


NEGATIVE=(("grind_0",0,1,"E_VISIBLE_GRIND"),
          ("grind_12",12,1,"E_VISIBLE_GRIND"),
          ("column_0",1,0,"E_VISIBLE_COLUMN"),
          ("column_6",1,6,"E_VISIBLE_COLUMN"))


def invalid(grind,column):
    return (f"z;d:{grind}a;!{column}a;!d;28h;!!v:\n"
            '"INVALID_WRONGLY_ACCEPTED"10,\n')


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write",action="store_true")
    args=parser.parse_args()
    program,cases=build()
    if args.write:
        FIXTURE.write_text(program,encoding="utf-8")
    assert FIXTURE.read_text(encoding="utf-8")==program
    assert len(cases)==55 and [value(11,c) for c in range(1,6)]==[37,41,43,47,1]
    print(json.dumps({"project_id":"PC-BRANCH-FALSE-ARABIC","scope":"STAGE11_PATCH_FOR_STAGE14",
                      "native_evidence":False,"result_assertions":55,"input_assertions":110,
                      "invalid_indices":[list(x) for x in NEGATIVE],
                      "fixture_sha256":hashlib.sha256(program.encode()).hexdigest(),
                      "cases":cases},indent=2,sort_keys=True))


if __name__=="__main__":
    main()
