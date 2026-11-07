#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA24 frozen input-origin corpus; usable unchanged under Python 2.7 and Python 3.
The new inputs are deliberately disjoint from every QA20 canonical raw input.
"""
from __future__ import print_function

VALID = (
 (0,1,0,3),(0,2,0,3),(0,3,0,2),(0,3,1,2),
 (1,3,0,2),(1,3,1,2),(0,16,0,17),(1,16,0,17),
 (0,15055669,0,15055670),(0,15055673,0,15055672),
 (1,15055673,1,15055672),(1,15055670,0,15055672),
 (0,999999,0,1000000),(1,999999,1,1000000),
 (0,10**30+7,0,10**30+11),(1,10**30+11,0,10**30+7)
)
INVALID = (
 '0 3 0 -4','0 -3 0 4','1 4 0 -3','1 -4 0 3',
 '0 +3 1 5','0 3 1 +5','1 3 0 5 trailing','0 3 1 5 0'
)

def cases():
    valid=[('q24v%02d'%i,' '.join(map(str,row))+'\n',True)
           for i,row in enumerate(VALID)]
    invalid=[('q24i%02d'%i,row+'\n',False)
             for i,row in enumerate(INVALID)]
    cases=valid+invalid
    assert len(cases)==24 and len(set(v[0] for v in cases))==24
    assert len(set(v[1] for v in cases))==24
    return cases

def check_disjoint(earlier):
    now=cases()
    original=set(v[1] for v in earlier)
    assert not original.intersection(v[1] for v in now), 'QA24 reused a QA20 raw input'
    assert len(earlier)==48 and len(set(v[0] for v in earlier))==48
    return now
