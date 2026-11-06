#!/usr/bin/env python3
"""QA31AG finite source-gated feasibility; never claims a fresh Native witness."""
import argparse
import copy
import hashlib
import json
from pathlib import Path

SOURCE_SHA = '560d6aa5807a7f766213a33835cce85eab0fa40c'
R_SHA = '4cb764bdef1859a47a34e6e7b1280b1fc2fd13af'
AF_SHA = '8307d335d55d64bcf0006f5437a717edb317bb47'
SITES = {(13,5):'~',(164,5):'j',(225,5):'x',(286,5):'x',
         (57,8):'g',(151,8):'g',(185,8):'j',(150,20):'x',
         (113,23):'j',(235,23):'x',(57,29):'g',(89,29):'j',
         (211,29):'x',(57,32):'g',(113,32):'j',(174,32):'x',
         (235,32):'x',(248,35):'p'}


def require(cond,msg):
    if not cond: raise AssertionError(msg)


def blob_sha(b):
    return hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()


def checked_file(p,sha):
    raw=Path(p).read_bytes()
    require(blob_sha(raw)==sha,'pinned Git blob differs: '+str(p))
    return raw


def cell(rows,x,y):
    return chr(rows[y][x]) if 0<=y<len(rows) and 0<=x<len(rows[y]) else ' '


def pin_source(rows):
    for (x,y),op in SITES.items(): require(cell(rows,x,y)==op,'source opcode mismatch at '+str((x,y)))
    require(len(rows)==2015 and rows[49]==b'', 'source geometry drift')
    return len(SITES)


def run_line(rows,row,q=0,m=0,byte=None,raw_negative=False):
    """Independent bounded linear Funge-98 segment interpreter; not a whole-program emulator."""
    mem={(0,49):32,(1,49):q,(2,49):1,(3,49):m}
    mem.update({(10+i,49):i+1 for i in range(4)})
    x,y,vx,vy=10,row,1,0
    stack=[]; sites=[]; reads=[]; writes=[]
    def pop():return stack.pop() if stack else 0
    for tick in range(1,550):
        require(0<=y<len(rows) and 0<=x<len(rows[y]),'source path left finite row')
        op=cell(rows,x,y);sites.append([x,y])
        if op in '0123456789abcdef':stack.append(int(op,16))
        elif op in ('+','-','*','`'):
            b=pop();a=pop();stack.append(a+b if op=='+' else a-b if op=='-' else a*b if op=='*' else int(a>b))
        elif op=='!':stack.append(int(pop()==0))
        elif op=='g':
            yy=pop();xx=pop();val=mem.get((xx,yy),ord(cell(rows,xx,yy)))
            stack.append(val);reads.append([x,y,xx,yy,val])
        elif op=='p':
            yy=pop();xx=pop();val=pop();mem[xx,yy]=val;writes.append([x,y,xx,yy,val])
        elif op=='j':
            jump=pop();x+=jump*vx;y+=jump*vy
        elif op=='x':vy=pop();vx=pop()
        elif op=='>':vx,vy=1,0
        elif op=='#':x+=vx;y+=vy
        elif op=='~':
            require(row==5,'unexpected stdin site')
            if byte is None:
                # PyFunge physical EOF is a reflection and no stack value, not -1.
                vx,vy=-vx,-vy
                return {'entry':row,'exit':[x+vx,y+vy],'eof_reflect':True,
                        'returned':None,'sites':sites,'writes':writes,'reads':reads}
            require(raw_negative or 0<=byte<=255, 'not a real byte')
            stack.append(byte)
        elif op!=' ':
            raise AssertionError(f'unmodeled opcode {op!r} at {(x,y)}')
        x+=vx;y+=vy
        if y!=row:
            return {'entry':row,'exit':[x,y],'eof_reflect':False,'returned':byte,
                    'sites':sites,'writes':writes,'reads':reads,'steps':tick}
    raise AssertionError('segment instruction bound exceeded')


def derive(rows):
    outcomes=[]
    for row in (23,32):
        for m in (0,1):
            for q in range(7):
                v=run_line(rows,row,q,m)
                expected=[10,44] if q>3 else ([10,26] if row==23 else [10,35])
                require(v['exit']==expected, f'gate edge row{row}/m{m}/q{q}')
                target=(235,row)
                require((list(target) in v['sites'])==(q>3),'x235 not selected by q threshold')
                outcomes.append({'row':row,'m':m,'q':q,'exit':v['exit'],
                                 'x235_hit':list(target) in v['sites'],'kind':'counterfactual_segment'})
    for m in (0,1):
        v=run_line(rows,29,m=m)
        require(v['exit']==([10,32] if m else [10,38]),'row29 control condition mismatch')
        outcomes.append({'row':29,'m':m,'exit':v['exit'],'kind':'counterfactual_segment'})
    increments=[]
    for q in range(4):
        v=run_line(rows,35,q=q,m=1)
        actual=[a for a in v['writes'] if a[:2]==[248,35]]
        require(actual==[[248,35,1,49,q+1]],'row35 last writer mismatch')
        require(v['exit']==[10,38],'row35 exit unexpected')
        increments.append({'q_at_row35':q,'q_written':q+1,'next_row':38,
                           'does_not_reenter_row32':True,'kind':'counterfactual_segment'})
    eof=run_line(rows,5,byte=None)
    require(eof['exit']==[12,5] and eof['eof_reflect'] and eof['returned'] is None,
            'EOF modeled as invented negative result')
    for b in (0,1,10,49,255):
        a=run_line(rows,5,byte=b)
        require(a['exit']==[10,8] and [286,5] not in a['sites'],
                'nonnegative stdin byte reached phantom row5 branch')
    negative=run_line(rows,5,byte=-1,raw_negative=True)
    require(negative['exit']==[10,29] and [286,5] in negative['sites'],
            'purely hypothetical negative-value route missing')
    # No unsupported assumption about prior row8 stack or reentrancy is permitted.
    return outcomes,increments,{'physical_model_eof_next':[12,5],
               'hypothetical_non_native_negative_next':negative['exit']}


def self_tests(rows):
    # Negative tests of source pins, gate target and EOF semantics, not Native executions.
    mutations=0
    for xy in ((13,5),(185,8),(235,23),(235,32),(248,35)):
        clone=[bytearray(v) for v in rows];x,y=xy;clone[y][x]=ord(' ')
        try: pin_source(clone)
        except AssertionError:mutations+=1
        else:raise AssertionError('mutated source site accepted')
    # Sixth hostile is a genuine source-shape mutation.
    altered=list(rows);altered[49]=b'x'
    try:pin_source(altered)
    except AssertionError:mutations+=1
    else:raise AssertionError('nonempty original memory row accepted')
    require(mutations==6,'negative-control count changed')
    return mutations


def main():
    p=argparse.ArgumentParser()
    p.add_argument('--source',required=True);p.add_argument('--qa31r',required=True)
    p.add_argument('--qa31af',required=True);p.add_argument('--out',required=True)
    a=p.parse_args()
    rows=checked_file(a.source,SOURCE_SHA).splitlines()
    pin_count=pin_source(rows)
    r=checked_file(a.qa31r,R_SHA).decode('utf-8')
    af=checked_file(a.qa31af,AF_SHA).decode('utf-8')
    for sample in ('`digit`','`q=(1,49)=0`','`m=(3,49)=1`'):
        require(sample in r,'signed-prefix report claim missing: '+sample)
    for sample in ('680 visits','100 visits','140 reflected EOF'):
        require(sample in af,'finite original report claim missing: '+sample)
    outcomes,increments,eof=derive(rows)
    negatives=self_tests(rows)
    report={'schema':'qa31ag-source-bounded-upstream-feasibility-v1',
        'project_id':'PC-BRANCH-BEFUNGE98-KYRGYZ','source_blob':SOURCE_SHA,
        'prior_report_git_blobs':{'QA31R':R_SHA,'QA31AF':AF_SHA},
        'original_source_site_pins':pin_count,
        'tested_m_q_gate_states':len(outcomes),'source_segment_cases':len(outcomes)+len(increments)+7,
        'segment_outcomes':outcomes,'row35_increments':increments,'eof':eof,
        'source_pin_negative_controls':negatives,
        'row8_alternative_ingress':'UNKNOWN: prior stack/input and alternate exits not physically replayed',
        'natural_input_witness_m1_q_gt3_at_row23_or32':False,
        'physical_prefixes':{'QA31R_digit_row29_m':1,'QA31R_digit_row32_q':0,
            'QA31AF_row23_original_visits':680,'QA31AF_row32_original_visits':100,
            'QA31AF_row23_x235_hits':0,'QA31AF_row32_x235_hits':0,
            'provenance':'pinned historical reports only; this run did not reverify original STEP bytes'},
        'hypothetical_negative_byte_is_native':False,'new_native_runs':0,
        'source_only':True,'global_reachability_proven':False,'stage1_pass':False}
    Path(a.out).write_text(json.dumps(report,indent=2,sort_keys=True)+'\n')
    print('QA31AG_SOURCE_PINNED_FINITE_MODEL_OK',len(outcomes),'states',negatives,'negative controls')
    print('QA31AG_NO_NEW_NATIVE_NO_STAGE1_PASS')

if __name__=='__main__':main()