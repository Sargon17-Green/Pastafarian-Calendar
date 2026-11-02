#!/usr/bin/env python3
"""QA31Q: 15 untouched QA20 control glyphs, conditional source ingress.

Uses independently SHA-checked, PRE-EXISTING QA18 and QA20 reports; executes
only bounded hypothetical source segments. Neither Native nor a global proof.
"""
import argparse
import copy
import hashlib
import json
from pathlib import Path

SOURCE_BLOB = '560d6aa5807a7f766213a33835cce85eab0fa40c'
QA18_SHA = '263a73a40afa17a8a9b1c831a01239be671d9ea0a9c331fd3f725f83cf1cfea7'
QA20_SHA = '75d2ee07eaf998fcb69bcb238d5fcb2163ab8305efe4abe4378af95f41385117'
HITS = {(10,44), (150,20), (175,38), (179,44), (235,11), (396,17)}
# Source-independent asserted coordinate/codebook, checked again against QA18 and original bytes.
EXPECTED_UNSEEN = {
 (10,32):'>',(10,35):'>',(57,32):'g',(57,35):'g',
 (113,32):'j',(127,35):'g',(152,35):'p',(174,32):'x',
 (199,35):'g',(211,29):'x',(235,23):'x',(235,32):'x',
 (248,35):'p',(286,5):'x',(309,35):'x',
}

def need(ok, why):
    if not ok:
        raise AssertionError(why)

def signed_json(path, sha):
    raw = Path(path).read_bytes()
    need(hashlib.sha256(raw).hexdigest() == sha, 'signed existing JSON SHA mismatch: '+str(path))
    return json.loads(raw)

def source_rows(path):
    raw = Path(path).read_bytes()
    blob = hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest()
    need(blob == SOURCE_BLOB, 'immutable original source blob mismatch: '+blob)
    rows = raw.splitlines()
    # The pinned 2,016-line byte stream ends in LF; splitlines() omits the terminal empty item.
    need(len(rows) == 2015, 'source height drift')
    return rows

def glyph(rows, xy):
    x,y = xy
    return chr(rows[y][x]) if 0 <= y < len(rows) and 0 <= x < len(rows[y]) else ' '

def original_inventory(rows, qa18, qa20):
    need(qa18['schema']=='qa18-source-glyph-contact-v1' and
         qa18['source_git_blob']==SOURCE_BLOB and
         qa18['native_original_trace_count']==49 and
         qa18['dead_code_certified'] is False, 'QA18 immutable receipt identity')
    controls = {(r['x'],r['y']):r['source_char']
                for r in qa18['never_touched_potential_control_glyphs']}
    need(len(controls)==21 and len(qa18['never_touched_potential_control_glyphs'])==21,
         'QA18 controls not uniquely 21')
    need(all(glyph(rows,p)==c for p,c in controls.items()), 'original source/QA18 glyph disagreement')
    need(qa20['schema']=='qa20-final-finite-native-physical-route-audit-v1' and
         (qa20['native_cases'],qa20['native_valid'],qa20['native_invalid'],qa20['step_total']) ==
         (48,27,21,1939997) and qa20['stage1_complete'] is False and
         qa20['no_dead_code_certification'] is True, 'QA20 finite Native summary mismatch')
    hits = {tuple(map(int,k.split(','))) for k in qa20['natural_source_opcode_hits']}
    need(hits == HITS and hits <= controls.keys(), 'QA20 observed control witness set drift')
    need(qa20['all_original_qa18_targets']==21 and
         qa20['not_hit_source_opcode_count']==15 and
         set(qa20['min_l1_by_candidate'])=={f'{x},{y}' for x,y in controls},
         'QA20 coordinate coverage incomplete')
    unseen = {p:c for p,c in controls.items() if p not in hits}
    need(unseen == EXPECTED_UNSEEN and len(unseen)==15, 'remaining QA20 candidates not exactly 15')
    return [{'xy':[x,y], 'opcode':unseen[x,y],
             'qa20_min_l1':qa20['min_l1_by_candidate'][f'{x},{y}']}
            for x,y in sorted(unseen, key=lambda xy:(xy[1],xy[0]))]

def model_segment(rows, start_row, mem, incoming_byte=None):
    """Original-source, finite one-row interpreter. A modeled state is NOT stdin."""
    x,y,dx,dy = 10,start_row,1,0
    stack, visits, reads, writes = [], [], [], []
    memory = dict(mem)
    def pop():
        return stack.pop() if stack else 0
    for tick in range(1,550):
        need(0 <= y < len(rows) and 0 <= x < len(rows[y]), 'modeled segment out of bounds')
        op = chr(rows[y][x]); visits.append((x,y))
        if op in '0123456789abcdef':
            stack.append(int(op,16))
        elif op in '+-*`':
            b,a = pop(),pop()
            stack.append(a+b if op=='+' else a-b if op=='-' else
                         a*b if op=='*' else int(a>b))
        elif op=='!':stack.append(int(pop()==0))
        elif op=='g':
            yy,xx = pop(),pop(); val=memory.get((xx,yy),ord(glyph(rows,(xx,yy))))
            stack.append(val); reads.append([x,y,xx,yy,val])
        elif op=='p':
            yy,xx,val=pop(),pop(),pop()
            memory[(xx,yy)]=val;writes.append([x,y,xx,yy,val])
        elif op=='j':
            n=pop();need(-300 <= n <= 300,'jump leaves bounded contract');x+=n*dx;y+=n*dy
        elif op=='x':dy,dx=pop(),pop()
        elif op=='>':dx,dy=1,0
        elif op=='#':x+=dx;y+=dy
        elif op=='~':
            need(start_row==5 and incoming_byte is not None,'unmodeled stdin opcode')
            stack.append(incoming_byte)
        elif op!=' ':raise AssertionError('unexpected source opcode '+repr(op))
        x+=dx;y+=dy
        if y!=start_row:
            return {'entry':start_row,'exit':[x,y],'visits':visits,'reads':reads,
                    'writes':writes,'memory':memory,'stack':stack,'steps':tick}
    raise AssertionError('source segment exceeded 549 instructions')

def initial(q=0,m=0,c=32,r=5):
    return {(0,49):c,(1,49):q,(2,49):r,(3,49):m,
            **{(10+i,49):i+1 for i in range(4)}}

def ingress(rows):
    covered = set(); cases=0; matrix=[]; active_rows=set()
    def evaluate(row, memory, nextxy, target_sites=(), incoming_byte=None):
        nonlocal cases
        res=model_segment(rows,row,memory,incoming_byte)
        need(res['exit']==list(nextxy), f'unexpected source edge row {row}: {res["exit"]}')
        points=set(res['visits']); covered.update(points & EXPECTED_UNSEEN.keys())
        need(set(target_sites)<=points,'source route omitted required target sites')
        active_rows.add(row);cases+=1
        return res
    # 256 existing nonnegative input-byte hypotheses, and ONE explicitly artificial -1.
    for c in range(256):
        r=evaluate(5,initial(c=c),(10,8),incoming_byte=c)
        # Row5 exits toward row8 using x225 under a nonnegative byte.
        need((225,5) in r['visits'] and (286,5) not in r['visits'],'nonnegative byte took synthetic path')
    # Original x(286,5) is only a counterfactual local negative return: NO EOF/native claim.
    r=evaluate(5,initial(c=-1),(10,29),[(286,5)],incoming_byte=-1)
    need((225,5) not in r['visits'],'negative counterfactual entered other x')
    for q in range(6):
        r=evaluate(23,initial(q=q),(10,44) if q>3 else (10,26),
                   [(235,23)] if q>3 else ())
        need(((235,23) in r['visits'])==(q>3),'row23 q comparison')
    for m in (0,1):
        r=evaluate(29,initial(m=m),(10,32) if m else (10,38),
                   [(211,29)] if m else ())
        need(((211,29) in r['visits'])==bool(m),'row29 m gate')
    for q in range(6):
        r=evaluate(32,initial(q=q),(10,44) if q>3 else (10,35),
                   [(235,32)] if q>3 else [(174,32)])
        need(((235,32) in r['visits'])==(q>3),'row32 q threshold')
    for q in range(4):
        r=evaluate(35,initial(q=q,r=5),(10,38),
                   [(10,35),(57,35),(127,35),(152,35),(199,35),(248,35),(309,35)])
        need(r['writes']==[[152,35,10+q,49,5],[248,35,1,49,q+1]],
             'row35 indexed output write and q owner')
        # Row29 -> row32 -> row35 -> row38 under m=1, q<=3 is hypothetical only.
        route29=evaluate(29,initial(q=q,m=1),(10,32),[(211,29)])
        route32=evaluate(32,route29['memory'],(10,35),[(174,32)])
        route35=evaluate(35,route32['memory'],(10,38),[(248,35)])
        res38=evaluate(38,route35['memory'],(10,41) if q==3 else (10,44))
        matrix.append({'entry_q':q,'row35_last_q_writer':q+1,
                       'row38_exit':res38['exit'],'conditional_only':True})
    need(cases==257+6+2+6+4+16,'bounded model count mismatch')
    need(covered == set(EXPECTED_UNSEEN), 'at least one of 15 controls not covered by conditional models')
    return cases, active_rows, matrix

def hostile(rows,qa18,qa20):
    # One source glyph forgery per outstanding coordinate, plus signed corpus forgeries.
    rejected=0
    for xy,code in EXPECTED_UNSEEN.items():
        broken=[bytearray(line) for line in rows]
        x,y=xy;broken[y][x]=ord(' ')
        try:original_inventory(broken,qa18,qa20)
        except AssertionError:rejected+=1
        else:raise AssertionError('altered control glyph accepted '+str(xy))
    for mut in (lambda a,b:a.__setitem__('native_original_trace_count',48),
                lambda a,b:b.__setitem__('not_hit_source_opcode_count',14),
                lambda a,b:b.__setitem__('natural_source_opcode_hits',[])):
        a,b=copy.deepcopy(qa18),copy.deepcopy(qa20);mut(a,b)
        try:original_inventory(rows,a,b)
        except AssertionError:rejected+=1
        else:raise AssertionError('forged signed report accepted')
    need(rejected==18,'hostile control count')
    return rejected

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('original_source')
    parser.add_argument('qa18_glyph_json')
    parser.add_argument('qa20_aggregate_json')
    parser.add_argument('--out',default='qa31q_frontier.json')
    a=parser.parse_args()
    rows=source_rows(a.original_source)
    qa18=signed_json(a.qa18_glyph_json,QA18_SHA)
    qa20=signed_json(a.qa20_aggregate_json,QA20_SHA)
    inventory=original_inventory(rows,qa18,qa20)
    cases,active,matrix=ingress(rows)
    rejected=hostile(rows,qa18,qa20)
    report={'schema':'qa31q-source-pinned-conditional-15-frontier-v1',
            'project_id':'PC-BRANCH-BEFUNGE98-KYRGYZ','original_source_blob':SOURCE_BLOB,
            'qa18_report_sha256':QA18_SHA,'qa20_aggregate_sha256':QA20_SHA,
            'original_QA20_native_cases_reused':48,'original_QA20_signed_steps_reused':1939997,
            'historically_unvisited_qa20_control_cells':inventory,
            'historically_unvisited_count':15,
            'hypothetical_source_segment_cases':cases,
            'modeled_source_rows':sorted(active),
            'counterfactual_row5_negative_return_not_native':True,
            'hypothetical_row29_row32_row35_row38':matrix,
            'source_and_receipt_forgeries_rejected':rejected,'fresh_native':0,
            'natural_stdin_witness_for_any_missing_control':False,
            'global_reachability_proven':False,'last_writer_global_proven':False,
            'stage1_pass':False}
    Path(a.out).write_text(json.dumps(report,sort_keys=True,indent=2)+'\n')
    print('QA31Q_UNSEEN_15_OF_21_SOURCE_VERIFIED')
    print('QA31Q_HYPOTHETICAL_SEGMENTS',cases)
    print('QA31Q_HOSTILE_18_OF_18')
    print('QA31Q_NO_NEW_NATIVE_NO_STAGE1_PASS')

if __name__=='__main__':main()
