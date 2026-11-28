#!/usr/bin/env python3
"""QA31BD: original source-pinned 2nd-hop and optional signed-200 audit.

This is read-only quality assurance. Never runs a Befunge interpreter, never
claims global reachability, and never modifies the original source.

Mode A (portable/CI): from repo root, run with no arguments. Verifies the
immutable Git blob, source corridors, literal/conditional stack program,
source p-site inventory and hostile mutations. Does NOT replay original Native.

Mode B (full signed replay): add --signed-archive and --qa31bc-archive to read
historical signed receipts. Verifies their SHA-256, nested shards, per-trace
SHA-256 and 200/3,628,390 source-original native STEP records, 365 x/g paths,
last-writer receipts and hostile mutations. No fresh Native run.
"""
from __future__ import annotations
import argparse
from collections import Counter, defaultdict
from hashlib import sha1, sha256
import gzip
import io
import json
from pathlib import Path
import zipfile

PROJECT='PC-BRANCH-BEFUNGE98-KYRGYZ'
SOURCE_BLOB='560d6aa5807a7f766213a33835cce85eab0fa40c'
ORIGINAL_ARCHIVE='9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49'
PREVIOUS_ARCHIVE='2e4c4809c73438359900e3f54bc616c21282fed83a4784228965da2b8b3b3a77'
H='v5a*3+1a*7+a*0+a*4+09a*5+-1a*1+a*0+a*1+x'
V='<2a*3+1a*6+a*9+a*7+ga3a*5+4a*7+a*5+x'
ROUTES={62: {'start':(1240,480),'dir':(0,1),'gate':(1240,519), 'next':(1145,1620),'delta':(-95,1101),'steps':40,'code':H,'g':None, 'residual':(53,1704)},
        118:{'start':(575,195),'dir':(-1,0),'gate':(540,195),'next':(575,670),'delta':(35,475),'steps':36,'code':V,'g':(556,195),'residual':(0,10)}}


def checked_zip(data:bytes, name:str) -> zipfile.ZipFile:
    z=zipfile.ZipFile(io.BytesIO(data))
    corrupt=z.testzip()
    assert corrupt is None,(name,corrupt)
    return z


def original_source(path:Path):
    data=path.read_bytes()
    digest=sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
    assert digest==SOURCE_BLOB,('SOURCE_NOT_ORIGINAL',digest)
    lines=data.decode('utf-8').split('\n')
    assert len(lines)==2016 and max(map(len,lines))==1531
    def at(x,y):return lines[y][x] if 0<=y<len(lines) and 0<=x<len(lines[y]) else ' '
    assert at(1500,1750)==' ' and at(1335,1354)=='p'
    for sel,spec in ROUTES.items():
        x,y=spec['start'];dx,dy=spec['dir']
        actual=''.join(at(x+dx*i,y+dy*i) for i in range(spec['steps']))
        assert actual==spec['code'],('SOURCE_SECOND_HOP_CHANGED',sel,actual)
        assert spec['gate']==(x+(spec['steps']-1)*dx,y+(spec['steps']-1)*dy)
    p_sites=[(x,y) for y,line in enumerate(lines) for x,c in enumerate(line) if c=='p']
    assert len(p_sites)==57
    protected={(1500+i,1750) for i in range(1501-1500,1529-1500)} | {(1500,1751+i) for i in range(28)}
    # NOTE p syntax itself does not constrain its stack-supplied coordinates.
    assert len(protected)==56 and not (protected & set(p_sites))
    assert at(23,1697)==' ', 'source g target must initially be blank'
    return {'source_git_blob':digest,'p_sites':len(p_sites),'source_corridor_cells':len(protected),
            'p_opcodes_residing_inside_corridors':0,'second_hop_code_lengths':[len(H),len(V)],
            'source_at_g_target_ord':ord(at(23,1697))}


def source_lit_program(code:str, mem_g:int=0, alteration:dict[int,str]|None=None):
    """Independent source stack oracle; no incoming stack; one documented g."""
    st=[]; g_reads=[]
    for i,c in enumerate(code):
        c=(alteration or {}).get(i,c)
        if i==0:
            assert c in ('v','<')
            continue
        if c=='x':
            assert i==len(code)-1
            break
        if c in '0123456789abcdef': st.append(int(c,16));continue
        if c in ('+','-','*'):
            assert len(st)>=2,('STACK_UNDERFLOW',code,i)
            b,a=st.pop(),st.pop()
            st.append(a+b if c=='+' else a-b if c=='-' else a*b)
            continue
        if c=='g':
            assert len(st)>=2
            y,x=st.pop(),st.pop()
            g_reads.append((x,y))
            st.append(mem_g)
            continue
        raise AssertionError(('UNSUPPORTED_SOURCE_OPCODE',c,i))
    assert len(st)==4,(code,st)
    return {'residual':st[:2], 'delta':st[-2:],'g_reads':g_reads}


def validate_portable():
    r={}
    r['source']=original_source(Path('src/interleaved_work_counts.b98'))
    altered=0; controls={}
    for sel,sp in ROUTES.items():
        origin=source_lit_program(sp['code'])
        assert tuple(origin['delta'])==sp['delta'] and tuple(origin['residual'])==sp['residual']
        assert origin['g_reads']==([] if sel==62 else [(23,1697)])
        negatives=[]
        for i,c in enumerate(sp['code']):
            if c not in '0123456789abcdef':continue
            repl='1' if c!='1' else '2'
            changed=source_lit_program(sp['code'],alteration={i:repl})
            if changed!=origin:
                negatives.append(i)
            if len(negatives)==12:break
        assert len(negatives)==12,('INSUFFICIENT_NONNOOP_NEGATIVES',sel,negatives)
        altered+=len(negatives)
        controls[sel]=negatives
    # g is an explicit self-modification dependent source sink; changing it must
    # not silently pass as the observed branch. No assumptions about natural stdin.
    changed=source_lit_program(V,mem_g=1)
    assert changed!=source_lit_program(V) and changed['g_reads']==[(23,1697)]
    r['independent_source_arithmetic']={'horizontal':source_lit_program(H),
                                         'vertical_g0':source_lit_program(V),
                                         'vertical_g1_counterfactual':changed}
    r['nonnoop_source_mutations_rejected']=altered
    r['source_mutation_offsets']=controls
    return r


def audit_signed(signed_path:Path,qa31bc_path:Path):
    original=signed_path.read_bytes(); prior=qa31bc_path.read_bytes()
    assert sha256(original).hexdigest()==ORIGINAL_ARCHIVE
    assert sha256(prior).hexdigest()==PREVIOUS_ARCHIVE
    with checked_zip(prior,'QA31BC') as z:
        ledger=json.loads(z.read('qa31bc_full_original_selector_routes.json'))
    assert ledger['source_git_blob']==SOURCE_BLOB
    assert ledger['original_signed_archive_sha256']==ORIGINAL_ARCHIVE
    trace_index={(item['trace_sha256'],item['shard']):item for item in ledger['per_case']}
    assert len(trace_index)==200
    ev=defaultdict(list)
    for item in ledger['events']:ev[(item['raw_hex'],item['shard'])].append(item)
    assert len(ledger['events'])==365
    with checked_zip(original,'QA31AI') as z:
        inner=z.read('QA31AH_BEFUNGE98_KYRGYZ_ORIGINAL_29_UPSTREAM_PREFIX_20261106.zip')
    with checked_zip(inner,'QA31AH') as z:
        inner=z.read('QA31Y_BEFUNGE98_KYRGYZ_FULL_EVIDENCE_20261104.zip')
    with checked_zip(inner,'QA31Y') as z:
        shards=[z.read('QA31V_SHARD%d.zip'%i) for i in range(8)]
    totals=Counter(); owner_sites=Counter(); g_cells=Counter(); p_sites=Counter(); hops=Counter(); discrepancy=[]
    examples=[]; first_gate_ids=[]
    for shard,packed in enumerate(shards):
        with checked_zip(packed,f'SHARD{shard}') as z:
            traces=sorted(n for n in z.namelist() if n.endswith('.jsonl.gz'))
            for fname in traces:
                compressed=z.read(fname)
                tr_hash=sha256(compressed).hexdigest()
                key=(tr_hash,shard)
                assert key in trace_index,('TRACE_SHA_OR_SHARD_MISMATCH',shard,fname)
                meta=trace_index.pop(key);raw=meta['raw_hex']
                rows=[json.loads(line) for line in gzip.decompress(compressed).splitlines() if line]
                assert len(rows)==meta['steps'] and rows[-1]['op']==ord('@'),('NOT_SIGNED_HALT',fname)
                assert all(e['t']==i for i,e in enumerate(rows,1)),('NON_CONTIGUOUS_T',fname)
                totals['cases']+=1;totals['steps']+=len(rows)
                write_owners={}; corr={(1500+i,1750) for i in range(1,29)} | {(1500,1751+i) for i in range(28)}
                # Track actual *last* physical p before each original-source g.
                first_sel=None
                expected_by_t={e['x_t']:e for e in ev[(raw,shard)]}
                for row in rows:
                    if row['op']==ord('p'):
                        assert len(row['pre'])>=3
                        value,x,y=row['pre'][-3:]
                        p_sites[tuple(row['ip'])]+=1
                        if (x,y) in corr:totals['p_overwrites_corridor']+=1
                        write_owners[(x,y)]=(row['t'],tuple(row['ip']),value)
                    if row['t'] in expected_by_t:
                        item=expected_by_t[row['t']]
                        assert tuple(row['ip'])==tuple(item['x_source_ip'])
                        assert row['op']==ord('x')
                        sel=item['selector_value'];sp=ROUTES[sel]
                        assert tuple(row['next'])==sp['start']
                        assert row['t']+sp['steps']<=len(rows)
                        path=rows[row['t']:row['t']+sp['steps']]
                        assert ''.join(chr(r['op']) for r in path)==sp['code'],('SOURCE_NEXT_PATH_CHANGED',fname,row['t'])
                        assert [tuple(r['ip']) for r in path]==[
                            (sp['start'][0]+sp['dir'][0]*i,sp['start'][1]+sp['dir'][1]*i)
                            for i in range(sp['steps'])]
                        gate=path[-1]
                        assert tuple(gate['ip'])==sp['gate'] and gate['op']==ord('x')
                        assert tuple(gate['pre'][-2:])==sp['delta'] and tuple(gate['next'])==sp['next']
                        assert tuple(gate['post'][-2:])==sp['residual']
                        assert all(r['op'] not in (ord('p'),ord('j')) for r in path)
                        gs=[r for r in path if r['op']==ord('g')]
                        assert len(gs)==int(sel==118)
                        if gs:
                            g=gs[0]
                            assert tuple(g['ip'])==sp['g'] and tuple(g['pre'][-2:])==(23,1697)
                            assert g['post'][-1]==0
                            owner=write_owners.get((23,1697))
                            assert owner is not None,('NO_PHYSICAL_G_LAST_WRITER',fname,g['t'])
                            assert owner[2]==0 and owner[0]<g['t']
                            owner_sites[owner[1]]+=1
                            g_cells[tuple(g['pre'][-2:])]+=1
                            totals['physically_owned_g_reads']+=1
                        totals['validated_source_second_hop_steps']+=sp['steps']
                        hops[(sel,sp['gate'],sp['next'])]+=1
                        first_gate_ids.append((fname,row['t'],gate['t'],sel))
                        if first_sel is None:first_sel=row['t']
                        if len(examples)<4 and len([x for x in examples if x['selector']==sel])<2:
                            examples.append({'selector':sel,'trace':fname,'event_t':row['t'],'gate_t':gate['t'],
                                             'gate_pre':gate['pre'][-4:],'gate_post':gate['post'][-2:]})
                    if first_sel is not None and row['t']>first_sel and row['ip'][1] in (14,32):
                        totals['parser_reentries_post_selector']+=1
                assert len(ev[(raw,shard)])==meta['selector_executions']
    assert not trace_index
    assert totals['cases']==200 and totals['steps']==3628390
    assert sum(hops.values())==365 and hops[(62,(1240,519),(1145,1620))]==140 and hops[(118,(540,195),(575,670))]==225
    assert totals['validated_source_second_hop_steps']==140*40+225*36==13700
    assert totals['physically_owned_g_reads']==225
    assert totals['p_overwrites_corridor']==0 and totals['parser_reentries_post_selector']==0
    return {'cases':totals['cases'],'steps':totals['steps'],'selector_second_hops':sum(hops.values()),
            'second_hop_op_steps':totals['validated_source_second_hop_steps'],
            'second_hop_routes':[{'selector':key[0],'gate':list(key[1]),'destination':list(key[2]),'count':num} for key,num in sorted(hops.items())],
            'g_read_count':totals['physically_owned_g_reads'],'g_read_address':[23,1697],
            'g_owners':[{'ip':list(k),'count':v} for k,v in owner_sites.most_common()],
            'p_executed_sites':len(p_sites),'p_events':sum(p_sites.values()),
            'physical_p_to_source_corridors':totals['p_overwrites_corridor'],
            'physical_parser_reentry_after_selector':totals['parser_reentries_post_selector'],
            'examples':examples,'new_native_runs':0,'global_reachability':'UNKNOWN','stage1_pass':False}


def hostile_controls(observed):
    # 12 adversarial edits to the derived ledger + source interpreter independent
    # of the signed receipts. They MUST all trigger explicit validation failure.
    import copy
    def accept(o):
        assert o['cases']==200 and o['steps']==3628390
        assert o['second_hop_op_steps']==13700 and o['selector_second_hops']==365
        assert o['g_read_count']==225 and o['g_read_address']==[23,1697]
        assert o['physical_p_to_source_corridors']==0
        assert o['physical_parser_reentry_after_selector']==0
        assert len(o['second_hop_routes'])==2
        assert [(x['selector'],x['count'],x['gate'],x['destination']) for x in o['second_hop_routes']]==[
            (62,140,[1240,519],[1145,1620]),(118,225,[540,195],[575,670])]
        assert sum(x['count'] for x in o['g_owners'])==225
        assert sorted((tuple(x['ip']),x['count']) for x in o['g_owners'])==[((765,1518),90),((1059,1430),135)]
    accept(observed)
    mutations=[('cases',199),('steps',3628389),('second_hop_op_steps',13699),('selector_second_hops',364),
              ('g_read_count',224),('g_read_address',[23,1698]),('physical_p_to_source_corridors',1),
              ('physical_parser_reentry_after_selector',1)]
    for field,val in mutations:
        x=copy.deepcopy(observed);x[field]=val
        try:accept(x)
        except AssertionError:pass
        else:raise AssertionError(('HOSTILE_MUTANT_NOT_REJECTED',field))
    for i,field,val in [(0,'count',139),(0,'gate',[1241,519]),(1,'destination',[575,671]),(1,'count',224)]:
        x=copy.deepcopy(observed);x['second_hop_routes'][i][field]=val
        try:accept(x)
        except AssertionError:pass
        else:raise AssertionError(('HOSTILE_ROUTE_NOT_REJECTED',i,field))
    return len(mutations)+4


def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--signed-archive',type=Path)
    ap.add_argument('--qa31bc-archive',type=Path)
    ap.add_argument('--no-source',action='store_true',help='signed replay only; report source unverified in this runtime')
    ap.add_argument('--output',type=Path)
    args=ap.parse_args()
    assert bool(args.signed_archive)==bool(args.qa31bc_archive)
    result={'project_id':PROJECT,'original_blob':SOURCE_BLOB,'stage1_pass':False,
            'new_native_runs':0,'scope':'source-only' if not args.signed_archive else 'signed-original-replay'}
    if not args.no_source:result['portable_source_gate']=validate_portable()
    else:result['portable_source_gate']='NOT_RUN_IN_THIS_RUNTIME'
    if args.signed_archive:
        r=audit_signed(args.signed_archive,args.qa31bc_archive)
        r['hostile_derived_ledger_mutations_rejected']=hostile_controls(r)
        result['signed_replay']=r
    if args.output:args.output.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    print(json.dumps(result,ensure_ascii=False,indent=2))

if __name__=='__main__':main()