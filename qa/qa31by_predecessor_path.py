#!/usr/bin/env python3
"""QA31BY: bounded, signed-original anchored, counterfactual predecessor/path QA.

No native interpreter, no network, no release gate acceptance. Python 3.11+.
Usage: python qa31by_predecessor_path.py --bw BW.zip --bx BX.zip \
       --attestation QA31BY_SOURCE_ATTESTATION.json --out QA31BY_RESULT.json

Original signed controls are CROSS-CHECKED against two earlier pinned QA
archives; original STEP files are NOT replayed by this QA. Conditional
interventions are not observable modified-run facts.
"""
from __future__ import annotations
import argparse
import copy
import hashlib
import json
import zipfile
from pathlib import Path
from itertools import product

PROJECT = 'PC-BRANCH-BEFUNGE98-KYRGYZ'
SOURCE_SHA1 = '560d6aa5807a7f766213a33835cce85eab0fa40c'
SOURCE_LENGTH = 1836425
BW_SHA256 = 'a9e76afb498ab922fb5086254edf9b59c96ada07ead73ba5f1ee37726c847628'
BX_SHA256 = 'b92945d86c03da42b611f2ec708813fa73f9a91099eb42f4de9ae57fb7ea3e7b'
X = 1500
ENTRY_Y = 1860
DOT_Y = 1881
VERTICAL = 'v7a*9+1a*7+a*1+a*0+g.'
WRITER_IP = [96, 480]
LOOKUP_RELATIVE = (79, 1710)
DIRECTIONS = {(1,0): 'east',(-1,0): 'west',(0,1): 'south',(0,-1): 'north'}


def check(condition, reason):
    if not condition:
        raise AssertionError(reason)


def hash256(b):
    return hashlib.sha256(b).hexdigest()


def open_pinned(path, expected, qa):
    raw = Path(path).read_bytes()
    check(hash256(raw) == expected, f'{qa}: zip SHA256')
    z = zipfile.ZipFile(path)
    check(z.testzip() is None, f'{qa}: ZIP CRC')
    manifest = json.loads(z.read('MANIFEST.json'))
    check(manifest['project_id'] == PROJECT and manifest['qa'] == qa, f'{qa}: project/scope')
    check(bool(manifest.get('files')), f'{qa}: empty manifest')
    for name, record in manifest['files'].items():
        digest = record['sha256'] if isinstance(record, dict) else record
        check(hash256(z.read(name)) == digest, f'{qa}: corrupt member {name}')
    return z


def read_jsonl(z, path):
    return [json.loads(line) for line in z.read(path).splitlines() if line]


def source_check(a):
    check(a['project_id'] == PROJECT, 'attestation project')
    check(a['git_blob_sha1'] == SOURCE_SHA1 and a['byte_length'] == SOURCE_LENGTH, 'immutable full-source pin')
    check(a['git_object_sha1_was_independently_rehashed'] is True, 'missing independent source hash attestation')
    check(a['sha1_algorithm_sanity'] == 'a9993e364706816aba3e25717850c26c9cd0d89d', 'hash oracle')
    check(a['method'] == 'SOURCE_BLOB_GITHUB_CONNECTOR_INDEPENDENT_JS_SHA1', 'attestation method')
    cells = a['cells']
    check(len(cells) == 23 and [r['y'] for r in cells] == list(range(ENTRY_Y,1883)), 'window coordinates')
    for index, r in enumerate(cells):
        check(r['x'] == X and r['value'] == (' ' + VERTICAL + '8')[index], f'static source at y={r["y"]}')
        check(r['line_length'] == (1531 if index == 0 else 1501), 'line length source proof')
    check(a['dot_left'] == ' ' and a['dot_right'] == ' ', 'source dot adjacency')
    return {r['y']:r['value'] for r in cells}


def check_original_record(r, bx_index):
    """Cross-check original witness pins; do not infer a changed-run."""
    check(r['type'] == 'untouched_original_signed_native', 'untouched status')
    check(len(r['trace_sha256']) == 64 and all(c in '0123456789abcdef' for c in r['trace_sha256']), 'trace pin')
    check(isinstance(r['steps'], int) and r['steps'] > 0, 'step count')
    check(isinstance(r['p_events'], int) and r['p_events'] >= 0, 'p count')
    check(isinstance(r['g_events'], int) and r['g_events'] >= 0, 'g count')
    b = bx_index[r['case']]
    check(b['case'] == r['case'] and b['steps'] == r['steps'], 'BX/BW original case and step cross-index')
    check(b['source_fetch_byte'] == 32, 'static source byte at original fetch')
    check(b['dynamic_fetch'] in (None,62), 'original dynamic byte')
    return b


def verify_witness(w):
    check(w['kind'] == 'fetch', 'not fetch')
    check(w['ip'] == [X,ENTRY_Y] and w['effective_address'] == [X,ENTRY_Y], 'fetch coordinates')
    check(w['observed_value_or_opcode'] == 62, 'actual original greater-than')
    writer=w['physical_prior_p_writer']
    check(isinstance(writer,dict), 'no physical p witness')
    check(writer['ip'] == WRITER_IP, 'writer IP')
    check(writer['stored_value'] == 62, 'writer value original')
    check(isinstance(writer['tick'],int) and 0 <= writer['tick'] < w['t'], 'writer prior to fetch')
    check(isinstance(w['t'],int), 'fetch tick')
    return True


def observed_controls(bw, bx):
    b=json.loads(bx.read('QA31BX_RESULT.json'))
    check(b['source_git_sha1'] == SOURCE_SHA1 and b['source_bytes'] == SOURCE_LENGTH, 'BX source pin')
    check(b['original_signed_halt_receipts'] == 200 and b['original_steps_independently_parsed'] == 3628390, 'BX historic summary')
    check(b['physical_original_p_to_1500_1881'] == 0 and b['unvisited_original_fetch_1500_1881'] == 0, 'BX original negative observations')
    xidx={v['case']:v for v in b['records']}
    controls=read_jsonl(bw,'qa31bw_untouched_controls.jsonl')
    witnesses=read_jsonl(bw,'qa31bw_selected_original_sites.jsonl')
    fidx={v['case']:v for v in witnesses if v['kind']=='fetch'}
    check(len(controls) == 12 and len({r['case'] for r in controls}) == 12, '12 original control identities')
    check(len(witnesses)==280 and len(fidx)==140, 'BW 140+140 original site records')
    rows=[]
    for r in controls:
        bidx=check_original_record(r,xidx)
        if r['case'] in fidx:
            verify_witness(fidx[r['case']])
            check(bidx['fetches'] >= 1 and bidx['dynamic_fetch'] == 62,'original positive fetch case')
            kind='historical_original_fetch_greater_than'
        else:
            check(bidx['fetches']==0 and bidx['dynamic_fetch'] is None,'original absence control')
            kind='historical_original_nonfetch'
        rows.append({'case':r['case'],'trace_sha256':r['trace_sha256'],'kind':kind,'steps':r['steps']})
    check(sum(r['kind']=='historical_original_fetch_greater_than' for r in rows)==11, '11 original fetch controls')
    check(sum(r['kind']=='historical_original_nonfetch' for r in rows)==1, 'one negative original control')
    return rows,fidx


def pop(st):
    return st.pop() if st else 0


def execute_bounded_source(source, input_stack, so, memory_value, patch):
    """Oracle A: bounded transition system with explicit counterfactual memory.

    Preconditions are NOT inferred from original Native: a single IP at entry,
    no subsequent writes along the corridor, and identical inherited stack/SO.
    """
    check(patch in ('>','v'), 'patch unsupported')
    state={ 'ip':[X,ENTRY_Y], 'dir':(1,0), 'stack':list(input_stack), 'out':[] }
    executed=[]
    for tick in range(22 if patch=='v' else 1):
        x,y=state['ip']
        check(x==X and y in source,'bounded target source')
        op=patch if y==ENTRY_Y else source[y]
        executed.append({'tick':tick,'ip':[x,y],'opcode':op})
        st=state['stack']
        if op=='>':state['dir']=(1,0)
        elif op=='v':state['dir']=(0,1)
        elif op in '0123456789abcdef':st.append(int(op,16))
        elif op=='+':st.append(pop(st)+pop(st))
        elif op=='*':st.append(pop(st)*pop(st))
        elif op=='g':
            relative_y=pop(st);relative_x=pop(st)
            check((relative_x,relative_y)==LOOKUP_RELATIVE, 'g address operand not 79,1710')
            effective=(relative_x+so[0],relative_y+so[1])
            st.append(memory_value if effective == (79+so[0],1710+so[1]) else 32)
        elif op=='.':state['out'].append(str(pop(st))+' ')
        else:raise AssertionError('unexpected source op '+op)
        dx,dy=state['dir'];state['ip']=[x+dx,y+dy]
    return state,executed


def analytic_oracle(stack,so,m):
    """Oracle B: closed-form independent algebra, no source instruction loop."""
    gx = 7*10+9
    gy = 1*1000 + 7*100 + 1*10 + 0
    check((gx,gy) == LOOKUP_RELATIVE, 'algebraic source indexing')
    return {'ip':[X,DOT_Y+1],'dir':(0,1),'stack':list(stack),'out':[f'{m} '],'effective_g_address':[gx+so[0],gy+so[1]]}


def predecessor_enumeration(source):
    """Exhaustive local cardinal predecessor coordinates (NOT global reachability)."""
    succ=[]
    for direction in DIRECTIONS:
        dx,dy=direction
        pred=[X-dx,DOT_Y-dy]
        # Static dot always leaves its direction unchanged when executed.
        succ.append({'direction':DIRECTIONS[direction],'predecessor_ip':pred,'dot_ip':[X,DOT_Y],
                     'next_ip':[X+dx,DOT_Y+dy],'local_opcode':'.',
                     'proved_reachable_from_original_input':False})
    check(len(succ)==4 and len({tuple(v['predecessor_ip']) for v in succ})==4,'cardinal exhaustive set')
    check(succ[2]['predecessor_ip']==[X,DOT_Y-1] and source[DOT_Y-1]=='g', 'southern predecessor g')
    return succ


def negative_controls(attestation,case,witness):
    """16 detached, synthetic guard tamperings; never native results."""
    failures=[]
    def bad(name, fn):
        try:
            fn()
        except (AssertionError,KeyError,TypeError,ValueError):
            failures.append(name);return
        raise AssertionError('negative accepted: '+name)
    def modify_att(k,v):
        tmp=copy.deepcopy(attestation);tmp[k]=v;source_check(tmp)
    for k,v in [('project_id','WRONG'),('git_blob_sha1','0'*40),('byte_length',12),
                ('git_object_sha1_was_independently_rehashed',False),('method','ASSUMED')]:
        bad('attestation_'+k,lambda k=k,v=v:modify_att(k,v))
    for ind,value in [(0,'>'),(1,'>'),(19,'p'),(21,'@')]:
        def change(i=ind,value=value):
            a=copy.deepcopy(attestation);a['cells'][i]['value']=value;source_check(a)
        bad('mutate_source_y'+str(ENTRY_Y+ind),change)
    for name,key,value in [('wrong_writer_ip','ip',[97,480]),('wrong_writer_value','stored_value',118),('after_fetch_writer_tick','tick',witness['t']+1)]:
        def change(k=key,v=value):
            w=copy.deepcopy(witness);w['physical_prior_p_writer'][k]=v;verify_witness(w)
        bad(name,change)
    for name,key,value in [('wrong_fetch_ip','ip',[X,DOT_Y]),('wrong_fetch_opcode','observed_value_or_opcode',118)]:
        def change(k=key,v=value):
            w=copy.deepcopy(witness);w[k]=v;verify_witness(w)
        bad(name,change)
    def change_control():
        t=copy.deepcopy(case);t['type']='counterfactual';check_original_record(t,{t['case']:{'case':t['case'],'steps':t['steps'],'source_fetch_byte':32,'dynamic_fetch':62}})
    bad('original_control_relabel',change_control)
    def change_next():
        actual,_=execute_bounded_source({y:r['value'] for y,r in [(cell['y'],cell) for cell in attestation['cells']]},[],(0,0),9,'>')
        check(actual['ip']==[X,ENTRY_Y+1], 'forged east next ip accepted')
    bad('counterfactual_false_next_ip',change_next)
    check(len(failures)>=12,'too few rejected hostiles')
    return failures


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--bw',required=True)
    parser.add_argument('--bx',required=True)
    parser.add_argument('--attestation',required=True)
    parser.add_argument('--out',required=True)
    args=parser.parse_args()
    attestation=json.loads(Path(args.attestation).read_text(encoding='utf-8'))
    source=source_check(attestation)
    with open_pinned(args.bw,BW_SHA256,'QA31BW') as bw, open_pinned(args.bx,BX_SHA256,'QA31BX') as bx:
        controls, witnesses=observed_controls(bw,bx)
        w=witnesses['pair_30_30']
        check(w['t'] == 17845 and w['physical_prior_p_writer']['tick'] == 17817,'sample signed chronology')
        negative=negative_controls(attestation,read_jsonl(bw,'qa31bw_untouched_controls.jsonl')[0],w)
    orig,trace_orig=execute_bounded_source(source,[4,5],(0,0),33,'>')
    check(orig['ip'] == [1501,1860] and len(trace_orig)==1 and orig['out']==[], 'observed greater-than first-hop')
    rows=[]
    ms=[-3,0,1,32,127,30111343]
    stacks=[[],[99],[0,2],[2,-1,22],[7,12,27,39]]
    offsets=[(0,0),(25,-10),(-79,0),(-100,1)]
    for m,st,so in product(ms,stacks,offsets):
        actual,ticks=execute_bounded_source(source,st,so,m,'v')
        expected=analytic_oracle(st,so,m)
        for key in ('ip','dir','stack','out'):
            check(actual[key]==expected[key],f'conditional independent oracle mismatch {key}')
        check(len(ticks)==22 and ticks[-1]['ip']==[X,DOT_Y] and ticks[-1]['opcode']=='.','dot reached only under premises')
        rows.append({'memory_value':m,'initial_stack':st,'storage_offset':list(so),'conditional_next_ip':actual['ip'],
                     'conditional_g_effective_address':expected['effective_g_address'],'conditional_output':actual['out']})
    pred=predecessor_enumeration(source)
    result={
      'project_id':PROJECT,'qa':'QA31BY','verdict':'LOCAL_FINITE_CONDITIONAL_PATH_PASS_NOT_NATIVE_NOT_STAGE1',
      'source_git_blob_sha1':SOURCE_SHA1,'source_bytes':SOURCE_LENGTH,'source_rehashed_locally_by_python':False,
      'source_rehashed_independently_via_github_js':True,
      'original_signed_controls_cross_checked':len(controls),
      'original_signed_controls_with_original_fetch':11,
      'original_signed_controls_without_original_fetch':1,
      'original_signed_controls':controls,
      'old_original_dynamic_opcode':62,'old_original_writer_ip':WRITER_IP,
      'old_original_first_successor':[1501,1860],
      'explicit_counterfactual_hypothesis':{
        'input':'EXPLICIT_NATIVE_P_WRITE_VALUE_INTERVENTION_NOT_A_KNOWN_NATURAL_STDIN',
        'site':[96,480],'original_write_value':62,'counterfactual_write_value':118,
        'write_target':[1500,1860],
        'bounded_start_ip':[1500,1860],
        'assumptions':['Only the p stored value changes, with identical target coordinates and p stack consumption',
                       'The intervened write is the last write to (1500,1860) before its fetch',
                       'Actual control reaches (1500,1860) in the altered run',
                       'Source bytes y1861..1881 are not overwritten before their respective fetches',
                       'One IP proceeds without competing FungeSpace mutation',
                       'Initial stack, storage offset, and g memory content are supplied explicitly'],
        'conditional_first_successor':[1500,1861],
        'conditional_21st_source_instruction_ip':[1500,1881],
        'conditional_first_dot_successor':[1500,1882],
        'remaining_real_modified_native_execution':'UNKNOWN'
      },
      'bounded_predecessors':pred,
      'counterfactual_comparisons':len(rows),
      'conditional_independent_oracle_agreements':len(rows),
      'counterfactual_examples':rows[:4],
      'detached_hostiles_rejected':len(negative),'detached_hostile_names':negative,
      'observed_original_reachability_of_dot':False,
      'new_native_runs':0,'new_ci_runs':0,'stage1_accepted':False,
      'limit':'Do not infer real changed-run IP, stack, SO, source mutations, output, or whole Stage1 acceptance'
    }
    Path(args.out).write_text(json.dumps(result,ensure_ascii=False,indent=2,sort_keys=True)+'\n',encoding='utf-8')
    print('QA31BY LOCAL FINITE CONDITIONAL QA PASS | 12 cross-archive original controls (11 fetch, 1 nonfetch) | '
          +str(len(rows))+' conditional dual-oracle cases | '+str(len(negative))+' detached hostiles rejected | 4 local predecessors | Native=0 CI=0 Stage1=OPEN')

if __name__=='__main__':main()