#!/usr/bin/env python3
"""QA31AG independent inverse-state verifier; no import from the forward model."""
import argparse
import copy
import hashlib
import json
from pathlib import Path

SRC='560d6aa5807a7f766213a33835cce85eab0fa40c'

def need(v,reason):
    if not v: raise AssertionError(reason)

def blob(b):
    return hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()

def verify(x,rows):
    need(x['schema']=='qa31ag-source-bounded-upstream-feasibility-v1','schema')
    need(x['source_blob']==SRC and x['original_source_site_pins']==18,'source identity')
    inverse={(r,m,q):((10,44) if q>3 else ((10,26) if r==23 else (10,35)))
             for r in (23,32) for m in (0,1) for q in range(7)}
    states=x['segment_outcomes']
    need(len(states)==30,'conditional-state count')
    seen=set()
    for s in states:
        need(s['kind']=='counterfactual_segment','fabricated physical source route')
        if s['row'] in (23,32):
            key=(s['row'],s['m'],s['q'])
            need(key in inverse and key not in seen,'missing or duplicate bounded row')
            need(tuple(s['exit'])==inverse[key],'inverse gate edge mismatch')
            need(s['x235_hit']==(s['q']>3),'inverse x235 selection mismatch')
        else:
            need(s['row']==29 and s['m'] in (0,1),'unmodeled row29 state')
            key=(29,s['m'])
            need(key not in seen,'repeated row29 state')
            need(tuple(s['exit'])==((10,32) if s['m'] else (10,38)),'row29 edge mismatch')
        seen.add(key)
    need(all(k in seen for k in inverse) and {(29,0),(29,1)}<=seen,'missing inverse cases')
    inc=x['row35_increments']
    need(len(inc)==4,'row35 case count')
    need({(v['q_at_row35'],v['q_written'],v['next_row']) for v in inc}
          == {(q,q+1,38) for q in range(4)},'row35 source writer')
    need(all(v['does_not_reenter_row32'] and v['kind']=='counterfactual_segment' for v in inc),
         'row35 destination overclaimed')
    need(x['source_segment_cases']==41 and x['tested_m_q_gate_states']==30,'test bounds')
    need(x['eof']['physical_model_eof_next']==[12,5],'EOF reflection missing')
    need(x['eof']['hypothetical_non_native_negative_next']==[10,29],'negative hypothetical')
    p=x['physical_prefixes']
    need((p['QA31R_digit_row29_m'],p['QA31R_digit_row32_q'])==(1,0),'historical natural prefix changed')
    need((p['QA31AF_row23_original_visits'],p['QA31AF_row32_original_visits'])==(680,100),
         'historical recorded gate visits changed')
    need((p['QA31AF_row23_x235_hits'],p['QA31AF_row32_x235_hits'])==(0,0),
         'unobserved target promoted to native')
    need('reports only' in p['provenance'] and 'not reverify' in p['provenance'],
         'original STEP provenance overstated')
    need(x['row8_alternative_ingress'].startswith('UNKNOWN:'),'unproven row8 claimed')
    need(x['natural_input_witness_m1_q_gt3_at_row23_or32'] is False,'invented natural witness')
    need(x['hypothetical_negative_byte_is_native'] is False,'EOF claimed as negative byte')
    need(x['source_pin_negative_controls']==6,'forward hostile count')
    need(x['new_native_runs']==0 and x['source_only'] is True and
         x['stage1_pass'] is False and x['global_reachability_proven'] is False,'global PASS claim')
    pins={(57,8):'g',(185,8):'j',(113,23):'j',(235,23):'x',(57,32):'g',
          (113,32):'j',(235,32):'x',(13,5):'~',(248,35):'p'}
    for (col,row),opcode in pins.items():
        need(rows[row][col]==ord(opcode),'source opcode pin disagrees')
    return len(inverse),len(pins)

def test_hostile(a,rows):
    changes=[
       lambda x:x['segment_outcomes'][0].__setitem__('exit',[10,45]),
       lambda x:x['segment_outcomes'][11].__setitem__('x235_hit',False),
       lambda x:x['segment_outcomes'][0].__setitem__('q',7),
       lambda x:x['segment_outcomes'][0].__setitem__('m',7),
       lambda x:next(v for v in x['segment_outcomes'] if v['row']==29).__setitem__('exit',[10,44]),
       lambda x:x['row35_increments'][0].__setitem__('q_written',9),
       lambda x:x['eof'].__setitem__('physical_model_eof_next',[14,5]),
       lambda x:x.__setitem__('new_native_runs',1),
       lambda x:x.__setitem__('stage1_pass',True),
       lambda x:x.__setitem__('row8_alternative_ingress','RESOLVED'),
       lambda x:x['physical_prefixes'].__setitem__('QA31AF_row23_original_visits',679),
       lambda x:x.__setitem__('natural_input_witness_m1_q_gt3_at_row23_or32',True)
    ]
    rejected=0
    for i,mutate in enumerate(changes):
        bad=copy.deepcopy(a);mutate(bad)
        try:verify(bad,rows)
        except (AssertionError,KeyError,IndexError,TypeError):rejected+=1
        else:raise AssertionError('hostile mutation escaped '+str(i))
    need(rejected==12,'hostile count')
    return rejected

def main():
    p=argparse.ArgumentParser()
    p.add_argument('--source',required=True);p.add_argument('--forward',required=True)
    p.add_argument('--out',required=True);a=p.parse_args()
    raw=Path(a.source).read_bytes()
    need(blob(raw)==SRC,'original source blob differs')
    report=json.loads(Path(a.forward).read_text(encoding='utf-8'))
    states,pins=verify(report,raw.splitlines())
    hostile=test_hostile(report,raw.splitlines())
    output={'schema':'qa31ag-independent-inverse-v1','source_blob':SRC,
            'inverse_states_verified':states,'independent_source_sites':pins,
            'hostile_mutations_rejected':hostile,'native_runs':0,'stage1_pass':False}
    Path(a.out).write_text(json.dumps(output,indent=2,sort_keys=True)+'\n',encoding='utf-8')
    print('QA31AG_INDEPENDENT_INVERSE_OK',states,'states',hostile,'hostile mutations')

if __name__=='__main__':main()
