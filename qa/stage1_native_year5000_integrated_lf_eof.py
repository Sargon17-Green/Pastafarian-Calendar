#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Stage 1 native BF98 ONE-LINE 24-token grammar, not a Python parser.

All classifications measured with the unchanged BF98 scanner source. This
test-only scanner checks one LF-terminated line; it does not inspect bytes
after that LF. Its output never replaces production or normative oracle.
"""
from __future__ import print_function
import json,os,subprocess
PROGRAM="qa/year5000_integrated_lf_eof_grammar.b98"
ROOT="/year5000-integrated"
CMD=["timeout","--kill-after=3s","20s","pyfunge",
     "--disable-fprint","--no-concurrent","--no-filesystem",
     "-v98","-d2",PROGRAM]
SIGN=(0,2,5,7,9,11,13,15,17,19,21)
MAG=(1,3,6,8,10,12,14,16,18,20,22)
def base():
    t=["0","100","0","0","9"]
    for i in range(9):t+=["0",str(i*42)]
    return t+["1"]
def encode(t):return " ".join(t)
def cases():
    b=base()
    values=[
      ("plain",encode(b),1),
      ("whitespace","  "+"\t  ".join(b)+"   ",1),
      ("negative_day",encode(["1","100"]+b[2:]),1),
      ("negative_index",encode(b[:2]+["1","7"]+b[4:]),1),
      ("negative_gate",encode(b[:5]+["1","7"]+b[7:]),1),
      ("long_magnitude",encode(b[:1]+["9"*70]+b[2:]),1),
      ("leading_magnitude_zeros",encode(b[:1]+["000100"]+b[2:]),1),
      ("rank_three",encode(b[:-1]+["3"]),1),
      ("empty","", -1),
      ("whitespace_only","  \t ",-1),
      ("early_linebreak",encode(b[:12])+"\n"+encode(b[12:]),-1),
      ("extra_same_line",encode(b)+" 1",-1),
      ("rank_zero",encode(b[:-1]+["0"]),-1),
      ("gate_count_eight",encode(b[:4]+["8"]+b[5:]),-1),
      ("gate_count_ten",encode(b[:4]+["10"]+b[5:]),-1),
      ("gate_count_two_digits",encode(b[:4]+["09"]+b[5:]),-1),
      ("tab_only_between","\t".join(b),1),
      ("invalid_cr",encode(b)+"\r",-1),
      ("multi_line_post_lf_not_checked",encode(b)+"\nEXTRA INVALID",-1)
    ]
    for i in range(24):
        v=list(b);v[i]="-"+v[i]
        values.append(("negative_token_%02d"%i,encode(v),-1))
        v=list(b);v[i]="+"+v[i]
        values.append(("positive_sign_token_%02d"%i,encode(v),-1))
        v=list(b);v[i]="garbage"
        values.append(("nondigit_token_%02d"%i,encode(v),-1))
        v=list(b);del v[i]
        values.append(("missing_field_%02d"%i,encode(v),-1))
    for pos in SIGN:
        for bad in ("2","00","01"):
            v=list(b);v[pos]=bad
            values.append(("bad_sign_%02d_%s"%(pos,bad),encode(v),-1))
    for pos in MAG:
        v=list(b);v[pos-1]="1";v[pos]="0"
        values.append(("negative_zero_%02d"%pos,encode(v),-1))
    for pos,value in ((0,"1.0"),(4,"9x"),(23,"1,2"),(2,"0x0")):
        v=list(b);v[pos]=value
        values.append(("punctuation_%02d"%pos,encode(v),-1))
    return values
def main():
    if not os.path.isdir(ROOT):raise AssertionError("missing Native evidence mount")
    rows=[]
    for label,raw,want in cases():
        p=subprocess.Popen(CMD,stdin=subprocess.PIPE,stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE)
        output,err=p.communicate(raw+"\n")
        if p.returncode:
            raise AssertionError("native grammar process %s rc=%s stderr=%r"%
                                 (label,p.returncode,err[-400:]))
        try:received=list(map(int,output.split()))
        except ValueError:raise AssertionError("nonnumeric Befunge output "+repr(output))
        if received!=[want]:
            raise AssertionError("native grammar mismatch %s got=%r expected=%r"%
                                 (label,received,[want]))
        rows.append({"case":label,"raw":raw,"native_output":received,
                     "expected_output":[want],"return_code":p.returncode})
        print("NATIVE_YEAR5000_24TOKEN_GRAMMAR_PASS",label)
    report={"schema":"befunge-stage1-24token-integrated-lf-eof-native-v1",
            "scope":"SINGLE_BF98_INTEGRATED_LF_EOF_NOT_RAW_NO_LF_STAGE1_OPEN",
            "case_count":len(rows),"last_completed_stage":0,
            "production_modified":False,"full_functional_acceptance":False,
            "without_lf_native_not_certified":True,"records":rows}
    with open(ROOT+"/native_year5000_integrated_lf_eof.json","wb") as f:
        f.write(json.dumps(report,indent=2,sort_keys=True)+"\n")
    print("NATIVE_YEAR5000_24TOKEN_INTEGRATED_LF_EOF_%d_CASES_PASS_STAGE1_OPEN"%len(rows))
if __name__=="__main__":main()
