#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Pure Native BF98 EOF reflection witness composed with 24-token line grammar.

Every classification comes from TWO unchanged native Befunge programs:
one-line 24-token parser, and literal-stream EOF/reflection guard.
Python only marshals test cases and compares independent expected flags.
No production change; not a full integrated Year5000 lexical parser.
"""
from __future__ import print_function
import json,os,subprocess
LINE="qa/year5000_exact_line_grammar.b98"
EOF="qa/year5000_raw_eof_guard.b98"
ROOT="/year5000-eof"
CMD=["timeout","--kill-after=3s","20s","pyfunge",
     "--disable-fprint","--no-concurrent","--no-filesystem","-v98","-d2"]
ROWS=[]
def base():
    t=["0","100","0","0","9"]
    for i in range(9):t+=["0",str(i*42)]
    return " ".join(t+["1"])
def witness_cases():
    b=base()
    sign=b.split()
    neg=sign[:];neg[2:4]=["1","7"]
    rank3=sign[:];rank3[-1]="3"
    badsign=sign[:];badsign[2]="2"
    minus=sign[:];minus[0]="-0"
    plus=sign[:];plus[3]="+0"
    negzero=sign[:];negzero[2:4]=["1","0"]
    count=sign[:];count[4]="8"
    leading=sign[:];leading[4]="09"
    invalid=sign[:];invalid[11]="garbage"
    return [
        ("ordinary_no_lf",b,1,1),
        ("ordinary_with_lf",b+"\n",1,1),
        ("spaces_before_lf","  "+b+"   \n",1,1),
        ("no_lf_trailing_spaces",b+"   ",1,1),
        ("negative_index_no_lf"," ".join(neg),1,1),
        ("negative_index_lf"," ".join(neg)+"\n",1,1),
        ("rank3_lf"," ".join(rank3)+"\n",1,1),
        ("tabs_lf","\t".join(sign)+"\n",1,1),
        ("big_magnitude_no_lf"," ".join(sign[:1]+["9"*72]+sign[2:]),1,1),
        ("new_line_followed_by_ascii",b+"\nEXTRA",-1,1),
        ("new_line_followed_by_digit",b+"\n1",-1,1),
        ("new_line_followed_by_space",b+"\n ",-1,1),
        ("new_line_followed_by_tab",b+"\n\t",-1,1),
        ("new_line_followed_by_second_lf",b+"\n\n",-1,1),
        ("new_line_followed_by_cr",b+"\n\r",-1,1),
        ("new_line_followed_by_minus",b+"\n-",-1,1),
        ("new_line_followed_by_plus",b+"\n+",-1,1),
        ("new_line_followed_by_second_line",b+"\n"+b,-1,1),
        ("new_line_followed_by_whitespace_line",b+"\n \t \n",-1,1),
        ("new_line_followed_by_colon",b+"\n:",-1,1),
        ("new_line_followed_by_slash",b+"\n/",-1,1),
        ("new_line_followed_by_formfeed",b+"\n\f",-1,1),
        ("missing_early_lf"," ".join(sign[:12])+"\n"+" ".join(sign[12:]),-1,-1),
        ("one_extra_same_line",b+" 1",-1,-1),
        ("missing_last_field"," ".join(sign[:-1]),-1,-1),
        ("bad_sign_no_lf"," ".join(badsign),-1,-1),
        ("negative_raw_no_lf"," ".join(minus),-1,-1),
        ("positive_raw_no_lf"," ".join(plus),-1,-1),
        ("negative_zero"," ".join(negzero),-1,-1),
        ("gate_count_eight"," ".join(count),-1,-1),
        ("gate_count_09"," ".join(leading),-1,-1),
        ("nondigit_inside"," ".join(invalid),-1,-1),
        ("empty","",-1,-1),
        ("single_lf","\n",-1,-1),
        ("spaces_only","  \t  ",-1,-1),
        ("carriage_in_firstline","\r"+b,-1,-1),
        ("carriage_before_lf",b+"\r\n",-1,-1),
    ]
def native(path,raw):
    proc=subprocess.Popen(CMD+[path],stdin=subprocess.PIPE,stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE)
    out,err=proc.communicate(raw)
    if proc.returncode:
        raise AssertionError("Native %s exit=%s stderr=%r"%
                             (path,proc.returncode,err[-400:]))
    try:got=[int(v) for v in out.split()]
    except ValueError:raise AssertionError("Noninteger Native result "+repr(out))
    if len(got)!=1 or got[0] not in (-1,1):
        raise AssertionError("Invalid Native EOF/grammar result "+repr(got))
    return got[0]
def main():
    if not os.path.isdir(ROOT):raise AssertionError("Native evidence dir missing")
    for label,raw,expected,line_expect in witness_cases():
        eof=native(EOF,raw)
        line=native(LINE,raw+"\n")
        want_eof=(-1 if "\n" in raw and raw.index("\n")<len(raw)-1 else 1)
        if eof!=want_eof:
            raise AssertionError("Native EOF %s observed=%d expected=%d"%
                                 (label,eof,want_eof))
        if line!=line_expect:
            raise AssertionError("Native 24-token %s observed=%d expected=%d"%
                                 (label,line,line_expect))
        accepted=1 if eof==1 and line==1 else -1
        if accepted!=expected:
            raise AssertionError("Composite Native %s observed=%d expected=%d"%
                                 (label,accepted,expected))
        ROWS.append({"case":label,"raw":raw,"native_eof":eof,
                     "native_line_grammar":line,"composed":accepted,
                     "expected":expected,"return_code":0})
        print("NATIVE_YEAR5000_EOF_AND_24TOKEN_GRAMMAR_PASS",label)
    result={"schema":"befunge-stage1-eof-reflection-grammar-composition-v1",
            "scope":"TEST_ONLY_TWO_NATIVE_GUARDS_NOT_INTEGRATED_PRODUCTION",
            "stage1_complete":False,"full_functional_acceptance":False,
            "geometric_acceptance":False,"last_completed_stage":0,
            "native_cases":len(ROWS),"eof_reflection_uses_native_torus":True,
            "records":ROWS}
    with open(ROOT+"/native_eof_full_stream.json","wb") as f:
        f.write(json.dumps(result,indent=2,sort_keys=True)+"\n")
    print("NATIVE_YEAR5000_EOF_FULL_STREAM_%d_CASES_PASS_STAGE1_OPEN"%len(ROWS))
if __name__=="__main__":main()
