#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA26 precommitted 64-input corpus; no post-hoc case selection.

32 valid 4-parameter calendar tuples and 32 deliberately malformed lexical
tuples, all disjoint from QA20 (48) and QA24 (24) input strings.
Compatible with Python 2.7 (native runner) and Python 3 (receipt auditor).
"""
from __future__ import print_function
import stage1_qa24_frozen_input_corpus as qa24

PAIRS = (
    (2, 5), (3, 8), (42, 41), (15055671, 15055669),
    (15055673, 15055674), (1234567, 7654321),
    (10**20 + 9, 10**20 + 11), (11, 2)
)
SIGN_PAIRS = ((0, 0), (0, 1), (1, 0), (1, 1))
MALFORMED_MAGNITUDES = (101, 102, 103, 104, 105, 106, 107, 108)

def cases():
    valid=[]
    for s,t in SIGN_PAIRS:
        for a,b in PAIRS:
            valid.append(('qa26v%02d'%len(valid),
                          '%d %d %d %d\n'%(s,a,t,b),True))
    malformed=[]
    for n in MALFORMED_MAGNITUDES:
        for raw in ('0 -%d 0 %d\n'%(n,n+1),
                    '2 %d 0 %d\n'%(n,n+1),
                    '1 -%d 1 %d\n'%(n,n+1),
                    '0 %d 3 %d\n'%(n,n+1)):
            malformed.append(('qa26i%02d'%len(malformed),raw,False))
    result=valid+malformed
    assert len(valid)==len(malformed)==32 and len(result)==64
    assert len({x[0] for x in result})==len({x[1] for x in result})==64
    return result

def verify_disjoint(previous_qa20):
    now=cases()
    previous=previous_qa20+qa24.cases()
    assert len(previous_qa20)==48 and len(qa24.cases())==24
    seen={v[1] for v in previous}
    assert not seen.intersection(v[1] for v in now), 'QA26 reuses earlier Native input'
    return now

if __name__=='__main__':
    rows=cases()
    print('QA26_FROZEN_64_DISJOINT_INPUTS',len(rows),sum(r[2] for r in rows))
