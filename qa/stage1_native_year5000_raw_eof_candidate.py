#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native BF98 no-LF EOF handler candidate, 326 independent invocations.
Python only transports inputs and records Native output; original 163-field
corpus generated in the immutable QA harness. Candidate is test-only.
"""
from __future__ import print_function
import json,os,subprocess
import stage1_native_year5000_24token_grammar as original
PROGRAM="qa/year5000_raw_eof_candidate.b98"
ROOT="/year5000-raw-eof"
CMD=["timeout","--kill-after=3s","6s","pyfunge",
     "--disable-fprint","--no-concurrent","--no-filesystem","-v98","-d2"]
def native(raw):
    p=subprocess.Popen(CMD+[PROGRAM],stdin=subprocess.PIPE,
                       stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    out,err=p.communicate(raw)
    if p.returncode:
        raise AssertionError("native EOF candidate rc=%d input=%r error=%r"%
                             (p.returncode,raw[:100],err[-220:]))
    try:got=list(map(int,out.split()))
    except ValueError:raise AssertionError("noninteger Native output "+repr(out))
    if got not in ([1],[-1]):raise AssertionError("wrong Native response "+repr(got))
    return got
def main():
    if not os.path.isdir(ROOT):raise AssertionError("missing evidence mount")
    rows=[]
    corpus=original.cases()
    if len(corpus)!=163:raise AssertionError("original fixture count changed")
    for idx,(label,raw,expected) in enumerate(corpus):
        if label=="multi_line_post_lf_not_checked":expected=-1
        for ending in ("raw","append_lf"):
            given=raw if ending=="raw" else raw+"\n"
            observed=native(given)
            if observed!=[expected]:
                raise AssertionError("BF98 EOF candidate mismatch %d %s %s actual=%r expected=%d"%
                                     (idx,label,ending,observed,expected))
            rows.append({"index":idx,"case":label,"ending":ending,
                         "raw":given,"expected":[expected],
                         "native_output":observed,"native_exit":0})
            print("NATIVE_YEAR5000_NO_LF_CANDIDATE_PASS",idx,label,ending)
    response={"schema":"befunge-stage1-no-lf-native-candidate-v1",
              "stage1_accepted":False,"production_modified":False,
              "native_case_count":len(rows),"last_completed_stage":0,
              "scope":"TEST_ONLY_RAW_EOF_TWO_ROW_CANDIDATE_NOT_FULL_ACCEPTANCE",
              "records":rows}
    with open(ROOT+"/year5000_raw_eof_candidate.json","wb") as f:
        f.write(json.dumps(response,indent=2,sort_keys=True)+"\n")
    print("NATIVE_YEAR5000_NO_LF_326_CASES_PASS_STAGE1_OPEN")
if __name__=="__main__":main()
