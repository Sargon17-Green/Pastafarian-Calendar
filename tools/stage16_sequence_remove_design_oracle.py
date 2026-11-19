#!/usr/bin/env python3
"""Independent domain oracle for Stage 16 small sequence remove-by-position.

This script is a specification and mathematical oracle only. It never executes FALSE.
"""
import hashlib
import itertools
import json
from pathlib import Path

PROJECT='PC-BRANCH-FALSE-ARABIC'

def specification(items, pos):
    # Deliberately independent of the normative FALSE source implementation.
    assert 1 <= len(items) <= 6
    assert 1 <= pos <= len(items)
    chosen = items[pos-1]
    remaining = items[:pos-1] + items[pos:]
    return chosen, remaining

def main():
    total=0
    # Exhaust the finite 1..n permutations at every legal removal position.
    for n in range(1,7):
        for seq in itertools.permutations(range(1,n+1)):
            for pos in range(1,n+1):
                chosen,rest=specification(seq,pos)
                assert len(rest)==n-1
                assert tuple(rest[:pos-1])+(chosen,)+tuple(rest[pos-1:])==seq
                assert sorted((chosen,)+tuple(rest))==list(range(1,n+1))
                total+=1
    assert total==5039
    anchors=[]
    for n in range(1,7):
        seq=list(range(1,n+1))
        positions=[1] if n==1 else [1,n]
        for p in positions:
            chosen,rest=specification(seq,p)
            anchors.append({'sequence':seq,'position':p,'chosen':chosen,'remaining':list(rest)})
    duplicate=[4,2,4,2,5]
    chosen,rest=specification(duplicate,3)
    anchors.append({'sequence':duplicate,'position':3,'chosen':chosen,'remaining':list(rest)})
    assert len(anchors)==12
    assert (chosen,rest)==(4,[4,2,2,5])
    report={'project_id':PROJECT,'stage':16,'status':'DESIGN_ORACLE_ONLY','reference_operation':50,
            'production_operation_planned':33,'input_shape':'[sequence,pos] with sequence=[n,x1,...,xn]',
            'output_shape':'[chosen,newSequence] with newSequence=[n-1,...]',
            'domain':{'sequence_length_min':1,'sequence_length_max':6,'position_base':1},
            'exhaustive_permutation_position_cases':total,
            'native_anchor_cases':len(anchors),'anchors':anchors,
            'invalid_native_shapes_to_test':['n=0','n=7','pos=0','pos=n+1','tuple_missing_sequence','tuple_missing_position'],
            'native_evidence':False,'stage16_accepted':False}
    text=json.dumps(report,ensure_ascii=False,sort_keys=True,indent=2)+'\n'
    output=Path('evidence/stage16_sequence_remove_design_oracle_2026-11-19.json')
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_text(text,encoding='utf-8')
    print('ORACLE_SHA256',hashlib.sha256(text.encode()).hexdigest())
    print('TESTS',total,'ANCHORS',len(anchors))
    print('SCRIPT_SHA256',hashlib.sha256(Path(__file__).read_bytes()).hexdigest())

if __name__=='__main__':
    main()
