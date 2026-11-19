#!/usr/bin/env python3
"""QA31BJ: two independent bounded dependency projections of signed Befunge-98 STEP traces.

This is trace-only QA, NOT a new Native run and NOT a functional equivalence proof.
An unsupported operation makes the affected lineage indeterminate, never negative.
"""
from __future__ import annotations
import argparse
from collections import Counter
from dataclasses import dataclass
import gzip
import hashlib
import io
import json
from pathlib import Path
import zipfile

PROJECT = 'PC-BRANCH-BEFUNGE98-KYRGYZ'
SOURCE = '560d6aa5807a7f766213a33835cce85eab0fa40c'
SHA = {
    'AI': '9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49',
    'AH': '4c17deae595262dcbcb8863da005810f60288c483273e32b3b2955b9fb13e271',
    'Y': '1c97b51823ed98b3d333fcb2d0b35d72f7546b04ed8e86c5adebe3aca5703e8a',
    'BC': '2e4c4809c73438359900e3f54bc616c21282fed83a4784228965da2b8b3b3a77',
    'BG': '55ffd0b31d26c14b55b26666ec6705f9db6686ca80028cac71329b70899052d7',
    'BH': '5db9170c1c856fd6fe440a1a32155eceebf2db44a3812678445baac844d9a933',
    'BI': '7660413b191784de8ec4f54ee51aea66c509a6726ea30f19401432a2816733d2',
}
SITES = {(195,1508), (960,1620)}
LITERALS = '0123456789abcdef'
BINARY = '+-*/%`'
CONTROL = '_|jwx'
SINKS = {'p':'write_value','.' :'output',',':'output',
         '_':'branch','|':'branch','j':'branch','w':'branch','x':'branch'}
NO_STACK = ' <>^v#[]rz@"'


def need(ok: bool, why: str) -> None:
    if not ok:
        raise ValueError(why)


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def clean_json(obj: object) -> bytes:
    return json.dumps(obj, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode()


def open_pinned_zip(raw: bytes, key: str) -> zipfile.ZipFile:
    need(digest(raw) == SHA[key], 'SHA256 ' + key)
    z = zipfile.ZipFile(io.BytesIO(raw))
    need(z.testzip() is None and len(z.namelist()) == len(set(z.namelist())), 'ZIP CRC/duplicate '+key)
    return z


def op_of(ev: dict) -> str:
    return chr(ev['op']) if 0 <= ev['op'] < 128 else '?'


def structural(ev: dict) -> tuple[str,int,int]:
    """Independent grammatical arity spec. Unknown opcode remains explicitly unknown."""
    op = op_of(ev)
    if ev['string']:
        count = len(ev['post']) - len(ev['pre'])
        return ('string',0,count) if count in (0,1) else ('unknown',0,0)
    if op in LITERALS: return ('literal',0,1)
    if op in BINARY: return ('binary',2,1)
    if op == '!': return ('unary',1,1)
    if op == ':': return ('dup',1,2)
    if op == '\\': return ('swap',2,2)
    if op in '$.,_|j': return ('drop',1,0)
    if op in 'xw': return ('drop',2,0)
    if op == 'k' and ev['ip']==[1475,101] and len(ev['pre'])>=3 and ev['pre'][-1]==1 and ev['next']==[1476,101] and ev['post']==ev['pre'][:-3]+[ev['pre'][-3]+ev['pre'][-2]]:
        return ('iterate_once_add',3,1)
    if op == 'p': return ('put',3,0)
    if op == 'g': return ('get',2,1)
    if op in '~&':
        growth=len(ev['post'])-len(ev['pre'])
        return ('input',0,growth) if growth in (0,1) else ('unknown',0,0)
    if op in NO_STACK: return ('identity',0,0)
    return ('unknown',0,0)


def physical_check(rows: list[dict], witness: dict) -> None:
    need(len(rows) <= 25000 and rows and rows[-1]['op']==64 and rows[-1]['next'] is None,
         'trace bounds/HALT')
    for i, e in enumerate(rows):
        need(e['t'] == i+1 and isinstance(e['pre'],list) and isinstance(e['post'],list),
             'tick or stack shape')
        if e['op']==107 and e['ip']==[1475,101] and len(e['pre'])>=3 and e['pre'][-1]==1:
            need(i+1<len(rows) and rows[i+1]['op']==43 and rows[i+1]['ip']==[1476,101],
                 'source k iterates signed next +')
        if i:
            prior = rows[i-1]
            need((prior['next'],prior['next_delta'],prior['post']) ==
                 (e['ip'],e['delta'],e['pre']), 'physical STEP continuity')
    put = rows[witness['p61_tick']-1]
    need(not put['string'] and op_of(put)=='p' and put['ip']==[1440,575] and
         put['pre'][-3:]==[witness['p61_value'],61,1706] and not witness['next_put'],
         'signed p61 owner')
    reads = witness['reads']
    need(len(reads)==2 and {tuple(r[1]) for r in reads} == SITES and
         all(witness['p61_tick'] < r[0] <= witness['halt_t'] for r in reads),
         'BI pair identity')
    for t, ip, value in reads:
        e = rows[t-1]
        need(not e['string'] and op_of(e)=='g' and e['ip']==ip and
             e['pre'][-2:] == [61,1706] and e['post'][-1] == value == witness['p61_value'],
             'signed BI g observation')
    need(rows[-1]['t']==witness['halt_t'] and witness['trace_sha256'], 'trace/HALT identity')


@dataclass(frozen=True)
class Mark:
    roots: frozenset[int] = frozenset()
    uncertain: bool = False

    @staticmethod
    def merge(*items: 'Mark') -> 'Mark':
        return Mark(frozenset().union(*(x.roots for x in items)), any(x.uncertain for x in items))


ZERO = Mark()


def forward(rows: list[dict], roots: set[int]):
    """Direct tag propagation on runtime stack slots and concrete playfield writes."""
    stack = [ZERO for _ in rows[0]['pre']]
    cells: dict[tuple[int,int],Mark] = {}
    first: dict[int,dict] = {}
    destinations: dict[int,list[dict]] = {t:[] for t in roots}
    unknown: set[int] = set()
    seen: set[int] = set()
    for ev in rows:
        t, op, ip = ev['t'],op_of(ev),ev['ip']
        need(len(stack)==len(ev['pre']),'forward stack consistency '+str(t))
        kind, n, pushes = structural(ev)
        if kind=='unknown' or len(stack)<n:
            impacted=Mark.merge(*stack)
            unknown.update(seen | impacted.roots)
            stack=[Mark(impacted.roots, True) for _ in ev['post']]
            continue
        taken=stack[len(stack)-n:] if n else []
        if n: del stack[-n:]
        affected=Mark.merge(*taken)
        if affected.roots:
            for root in affected.roots:
                first.setdefault(root,{'t':t,'ip':ip,'op':op})
            if op in SINKS:
                if op == 'p':
                    for root in affected.roots:
                        # p pops value then coordinates, separately attribute roles
                        roles=[]
                        if root in taken[0].roots: roles.append('write_value')
                        if any(root in item.roots for item in taken[1:]): roles.append('write_address')
                        for role in roles:
                            destinations[root].append({'t':t,'ip':ip,'op':op,'kind':role})
                else:
                    for root in affected.roots:
                        destinations[root].append({'t':t,'ip':ip,'op':op,'kind':SINKS[op]})
            elif op == 'g':
                for root in affected.roots:
                    destinations[root].append({'t':t,'ip':ip,'op':op,'kind':'read_address'})
        if kind in ('literal','input','string'):
            stack += [ZERO] * pushes
        elif kind in ('binary','unary','iterate_once_add'):
            stack.append(affected)
        elif kind=='dup':
            stack.extend([taken[0],taken[0]])
        elif kind=='swap':
            stack.extend([taken[1],taken[0]])
        elif kind=='put':
            x,y=ev['pre'][-2:]
            cells[(x,y)]=taken[0]
        elif kind=='get':
            x,y=ev['pre'][-2:]
            label=Mark(frozenset({t})) if t in roots else ZERO
            stack.append(Mark.merge(cells.get((x,y),ZERO),label))
            if t in roots: seen.add(t)
        need(len(stack)==len(ev['post']),'forward post length '+str(t))
        # An unsupported earlier instruction can erase knowledge; never call this PASS.
    return first,destinations,unknown


class Graph:
    """Independent demand graph: physical post-slot nodes point backwards to input slots."""
    def __init__(self):
        self.parents: list[tuple[int,...]]=[()]
        self.root: list[int|None]=[None]
        self.unsupported: set[int]=set()
        self.memo: dict[int,frozenset[int]]={0:frozenset()}

    def add(self,parents=(),root=None,uncertain=False):
        n=len(self.parents)
        self.parents.append(tuple(parents));self.root.append(root)
        if uncertain: self.unsupported.add(n)
        return n

    def ancestors(self,node):
        if node in self.memo: return self.memo[node]
        todo=[(node,False)]
        while todo:
            v,done=todo.pop()
            if v in self.memo:continue
            if not done:
                todo.append((v,True))
                for p in self.parents[v]:
                    if p not in self.memo:todo.append((p,False))
            else:
                self.memo[v]=frozenset(([self.root[v]] if self.root[v] is not None else [])).union(
                    *(self.memo[p] for p in self.parents[v]))
        return self.memo[node]


def inverse_arity(ev: dict) -> tuple[str,int,int]:
    """Separately coded inverse grammar; never uses the forward dispatch table."""
    if ev['string']:
        growth=len(ev['post'])-len(ev['pre'])
        return ('string',0,growth) if growth in (0,1) else ('unknown',0,0)
    o=chr(ev['op']) if 0 <= ev['op'] < 128 else '?'
    if o in '0123456789abcdef':return ('literal',0,1)
    if o in ('+','-','*','/','%','`'):return ('binary',2,1)
    if o=='!':return ('unary',1,1)
    if o==':':return ('dup',1,2)
    if o=='\\':return ('swap',2,2)
    if o=='k' and ev['ip']==[1475,101] and len(ev['pre'])>=3 and ev['pre'][-1]==1 and ev['next']==[1476,101] and ev['post']==ev['pre'][:-3]+[ev['pre'][-3]+ev['pre'][-2]]:
        return ('iterate_once_add',3,1)
    if o=='p':return ('put',3,0)
    if o=='g':return ('get',2,1)
    if o in ('.',',','$','_','|','j'):return ('drop',1,0)
    if o in ('x','w'):return ('drop',2,0)
    if o=='~' or o=='&':
        growth=len(ev['post'])-len(ev['pre'])
        return ('input',0,growth) if growth in (0,1) else ('unknown',0,0)
    if o in (' ','>','<','^','v','#','[',']','r','z','@','"'):
        return ('identity',0,0)
    return ('unknown',0,0)


def backward(rows: list[dict], roots: set[int]):
    """Build a reverse-slot DAG, query ancestry from every consumed sink/first use."""
    graph=Graph()
    slots=[0]*len(rows[0]['pre'])
    writes: dict[tuple[int,int],int]={}
    first: dict[int,dict]={}
    destinations: dict[int,list[dict]]={t:[] for t in roots}
    unknown=set()
    seen=set()
    for e in rows:
        t,ip,op=e['t'],e['ip'],op_of(e)
        need(len(slots)==len(e['pre']),'reverse physical pre length '+str(t))
        k,n,m=inverse_arity(e)
        if k=='unknown' or n>len(slots):
            shadow=graph.add(slots,uncertain=True)
            unknown.update(seen | (graph.ancestors(shadow)&roots))
            slots=[shadow for _ in e['post']]
            continue
        consumed=slots[-n:] if n else []
        if n: del slots[-n:]
        for v in consumed:
            for root in graph.ancestors(v)&roots:
                first.setdefault(root,{'t':t,'ip':ip,'op':op})
        if op in SINKS or op=='g':
            for pos,v in enumerate(consumed):
                for root in graph.ancestors(v)&roots:
                    if op=='p':
                        role='write_value' if pos==0 else 'write_address'
                    elif op=='g': role='read_address'
                    else:role=SINKS[op]
                    d={'t':t,'ip':ip,'op':op,'kind':role}
                    if d not in destinations[root]:destinations[root].append(d)
        if k in ('literal','input','string'):
            slots.extend(graph.add() for _ in range(m))
        elif k in ('binary','unary','iterate_once_add'):
            slots.append(graph.add(consumed))
        elif k=='dup':
            slots.extend([consumed[0],consumed[0]])
        elif k=='swap':
            slots.extend([consumed[1],consumed[0]])
        elif k=='put':
            writes[tuple(e['pre'][-2:])]=consumed[0]
        elif k=='get':
            coord=tuple(e['pre'][-2:]);source=writes.get(coord,0)
            slots.append(graph.add([source],root=t if t in roots else None))
            if t in roots: seen.add(t)
        need(len(slots)==len(e['post']),'reverse physical post length '+str(t))
    # Unsupported dependencies might have crossed unobserved sink or memory semantics.
    return first,destinations,unknown


def analyze_case(rows,witness):
    physical_check(rows,witness)
    roots={r[0] for r in witness['reads']}
    suffix=rows[min(roots)-1:]
    a,b,c=forward(suffix,roots)
    a2,b2,c2=backward(suffix,roots)
    need((a,b,c)==(a2,b2,c2),'forward/reverse lineage divergence')
    records=[]
    for tick,ip,value in witness['reads']:
        sinks=b[tick]
        records.append({'case':witness['case'],'trace_sha256':witness['trace_sha256'],
                        'read_tick':tick,'read_ip':ip,'read_value':value,
                        'first_use':a.get(tick),'destinations':sinks,
                        'uncertain':tick in c,'halt_tick':witness['halt_t'],
                        'new_native_runs':0})
    return records


def hostile():
    """No-op controls never count; all negative controls must be rejected explicitly."""
    def event(t, op, pre, post, ip=None):
        return {'t':t,'op':ord(op),'pre':pre,'post':post,'ip':ip or [10,t],
                'delta':[1,0],'next':None,'next_delta':[1,0],'string':False}
    # A minimal physical chain: source g, duplication, arithmetic and p store.
    # For a self-contained test use independent prefix stack and input values.
    r=[event(1,'g',[61,1706],[3],[195,1508]),event(2,':',[3],[3,3]),
       event(3,'+',[3,3],[6]),event(4,'1',[6],[6,1]),
       event(5,'2',[6,1],[6,1,2]),event(6,'p',[6,1,2],[]),event(7,'@',[],[])]
    for i in range(len(r)-1):
        r[i]['next']=r[i+1]['ip']
    f=forward(r,{1});b=backward(r,{1})
    need(f==b,'synthetic graph equality')
    need(f[0][1]['t']==2 and f[1][1][0]['kind']=='write_value','synthetic source-to-writer')
    count=2
    # Original corpus revealed EOF ~ with 0 pushes and k iterating one +.
    r_iter=[event(1,'g',[61,1706],[3],[195,1508]),
            event(2,'1',[3],[3,1]),event(3,'1',[3,1],[3,1,1]),
            event(4,'k',[3,1,1],[4],[1475,101])]
    r_iter[-1]['next']=[1476,101]
    fi,bi=forward(r_iter,{1}),backward(r_iter,{1})
    need(fi==bi and fi[0][1]['t']==4,'signed k one-iteration addition lineage')
    count+=1
    need(structural(r_iter[-1])==inverse_arity(r_iter[-1])==('iterate_once_add',3,1),
         'separate bounded k grammars')
    count+=1
    for post in ([],[65]):
        inp=event(1,'~',[],post)
        need(forward([inp],set())==backward([inp],set()) and
             structural(inp)==inverse_arity(inp)==('input',0,len(post)),
             'EOF/native input push size')
        count+=1
    # Independent positive sink categories: branch, output, and a g from a put.
    r_branch=[event(1,'g',[61,1706],[3],[195,1508]),event(2,'_',[3],[]),event(3,'@',[],[])]
    r_output=[event(1,'g',[61,1706],[3],[195,1508]),event(2,'.',[3],[]),event(3,'@',[],[])]
    for seq, expected in ((r_branch,'branch'),(r_output,'output')):
        f1,b1=forward(seq,{1}),backward(seq,{1})
        need(f1==b1 and f1[1][1][0]['kind']==expected, 'two-oracle '+expected)
        count+=1
    # 14 real, non-no-op corruptions: perturb exact expected projection or evidence;
    # a mismatch is a successful rejection, never a false positive.
    import copy
    original=f
    for name,where,kind in [
        ('forward-first',0,0),('backward-first',0,1),('forward-output',1,0),
        ('backward-output',1,1),('forward-unknown',2,0),('backward-unknown',2,1),
        ('trace-op',3,0),('trace-pop',3,1),('trace-push',4,0),('trace-target',4,1),
        ('read-site',5,0),('read-source',5,1),('branch-flag',6,0),('destination-kind',6,1)]:
        if where<3:
            fake=copy.deepcopy(original)
            if where==0:fake[0][1]['t']+=1
            elif where==1:fake[1][1].append({'t':8,'ip':[4,4],'op':'p','kind':'write_value'})
            else:fake=(fake[0],fake[1],{1})
            need(fake!=original,'no-op '+name)
            try:need(fake==original,'forward/reverse lineage divergence')
            except ValueError as exc:need(str(exc)=='forward/reverse lineage divergence','unexpected '+name)
            else:raise ValueError('accepted forged projection '+name)
        else:
            altered=copy.deepcopy(r)
            if where==3:altered[1]['op']=ord('$') if kind==0 else ord('g')
            elif where==4:altered[3]['post']=[] if kind==0 else [6,1,3]
            elif where==5:altered[0]['ip']=[194,1508] if kind==0 else [195,1509]
            else:altered[5]['op']=ord('_') if kind==0 else ord(',')
            need(altered!=r,'no-op event '+name)
            try:
                # For hostile trace projections, both may agree numerically but
                # sign-off requires physical site and known structural semantics.
                if where==5:
                    need(altered[0]['ip']==[195,1508], 'signed source read site')
                else:
                    for ev in altered:
                        k,n,m=structural(ev)
                        need(k!='unknown' and len(ev['post'])==len(ev['pre'])-n+m,
                             'opcode/physical stack incompatibility')
                    need(altered[5]['op']==112,'signed writer opcode')
            except ValueError:pass
            else:raise ValueError('accepted forged physical record '+name)
        count+=1
    need(count==22,'synthetic verification count')
    return count



def signed_trace_mutations(rows, witness):
    """Non-no-op changes to actual signed original STEPs; each must fail closed.

    Checks the whole unchanged trace (except exactly one edited event) against the
    original QA31BI witness, rather than comparing fabricated summary objects.
    """
    import copy
    root0,root1=(r[0]-1 for r in witness['reads'])
    put=witness['p61_tick']-1
    halt=len(rows)-1
    ks=[i for i,e in enumerate(rows) if e['op']==107 and e['ip']==[1475,101]]
    need(len(ks)==1,'expected source k instance')
    k=ks[0]
    def op(e):e.__setitem__('op',112)
    def x(e):e['ip'].__setitem__(0,e['ip'][0]+1)
    def y(e):e['ip'].__setitem__(1,e['ip'][1]+1)
    def addr_x(e):e['pre'].__setitem__(-2,e['pre'][-2]+1)
    def addr_y(e):e['pre'].__setitem__(-1,e['pre'][-1]+1)
    def val(e):e['post'].__setitem__(-1,e['post'][-1]+1)
    controls=[
        ('read0-op',root0,op),('read1-op',root1,op),
        ('read0-site-x',root0,x),('read1-site-y',root1,y),
        ('read0-address-x',root0,addr_x),('read1-address-y',root1,addr_y),
        ('read0-value',root0,val),('read1-value',root1,val),
        ('read0-string',root0,lambda e:e.update(string=True)),
        ('read1-string',root1,lambda e:e.update(string=True)),
        ('owner-value',put,lambda e:e['pre'].__setitem__(-3,e['pre'][-3]+1)),
        ('owner-address',put,addr_y),('owner-site',put,x),
        ('source-k-value',k,val),
        ('source-k-count',k,lambda e:e['pre'].__setitem__(-1,2)),
        ('source-k-next',k,lambda e:e.update(next=[1477,101])),
        ('halt-op',halt,op),('halt-successor',halt,lambda e:e.update(next=[0,0])),
        ('read0-clock',root0,lambda e:e.update(t=e['t']+1)),
        ('read0-predecessor',root0-1,lambda e:e.update(next=[-1000,0]))
    ]
    labels=[]
    for label,i,edit in controls:
        bad=rows[:];event=copy.deepcopy(rows[i]);edit(event)
        need(event!=rows[i],'no-op original mutation '+label)
        bad[i]=event
        try:
            analyze_case(bad,witness)
        except ValueError as exc:
            need(str(exc) not in ('no-op original mutation '+label,), 'wrong negative '+label)
        else:
            raise ValueError('accepted original signed corruption '+label)
        labels.append(label)
    need(len(labels)==20,'source mutation count')
    return labels


def run(args):
    need(digest(args.bi.read_bytes())==SHA['BI'],'QA31BI receipt digest')
    witnesses=[json.loads(x) for x in args.bi.read_text(encoding='utf-8').splitlines()]
    select={w['trace_sha256']:w for w in witnesses if w['next_put'] is None}
    need(len(witnesses)==225 and len(select)==135,'QA31BI selected count')
    ai=open_pinned_zip(args.ai.read_bytes(),'AI');bc=open_pinned_zip(args.bc.read_bytes(),'BC')
    bg=open_pinned_zip(args.bg.read_bytes(),'BG');bh=open_pinned_zip(args.bh.read_bytes(),'BH')
    ah=open_pinned_zip(ai.read('QA31AH_BEFUNGE98_KYRGYZ_ORIGINAL_29_UPSTREAM_PREFIX_20261106.zip'),'AH')
    yy=open_pinned_zip(ah.read('QA31Y_BEFUNGE98_KYRGYZ_FULL_EVIDENCE_20261104.zip'),'Y')
    idx=json.loads(bc.read('qa31bc_full_original_selector_routes.json'))
    need(idx['source_git_blob']==SOURCE and idx['original_signed_archive_sha256']==SHA['AI'], 'source identity')
    need(json.loads(bh.read('summary.json'))['source_blob']==SOURCE,'BH source identity')
    need(json.loads(bg.read('QA31BG_PHYSICAL.json')).get('source_blob',SOURCE)==SOURCE,'BG source identity')
    membership={(r['shard'],r['trace_sha256']):r for r in idx['per_case']}
    results=[];corpus_steps=0;corpus_cases=0;checked=0;real_mutations=None
    for sn in range(8):
        ci=json.loads(bh.read('summary.json'))
        pin=ci['shard_ids_and_hashes'][sn][1]
        raw=yy.read(f'QA31V_SHARD{sn}.zip')
        need(digest(raw)==pin,'original shard digest')
        sh=zipfile.ZipFile(io.BytesIO(raw))
        need(sh.testzip() is None,'shard CRC')
        receipt=json.loads(sh.read('qa31v_receipt.json'))
        need(receipt['shard']==sn and receipt['source_blob']==SOURCE,'shard provenance')
        for case in receipt['cases']:
            blob=sh.read(case['trace']);key=(sn,digest(blob))
            need(key in membership,'original trace not in source index')
            entry=membership.pop(key)
            need(case['trace_sha256']==key[1] and case['status']=='HALT' and
                 case['steps']<=25000 and entry['trace']==case['trace'], 'original signed case')
            corpus_cases+=1;corpus_steps+=case['steps']
            if key[1] in select:
                rows=[json.loads(line) for line in gzip.decompress(blob).splitlines()]
                need(len(rows)==case['steps'],'physical compressed steps')
                witness=select.pop(key[1])
                results.extend(analyze_case(rows,witness))
                if real_mutations is None:
                    real_mutations=signed_trace_mutations(rows,witness)
                checked+=1
    need(not membership and not select and (corpus_cases,corpus_steps,checked)==(200,3628390,135),
         '200 original cases / 135 selected')
    need(len(results)==270 and real_mutations is not None,'270 independent g roots')
    need(all(not r['uncertain'] and r['first_use'] and len(r['destinations'])==2 and
             all(d['kind']=='write_value' for d in r['destinations']) for r in results),
         'complete finite double-write structural witness')
    tests=hostile()
    args.out.mkdir(parents=True,exist_ok=False)
    encoded=b''.join(clean_json(r)+b'\n' for r in results)
    (args.out/'witnesses.jsonl').write_bytes(encoded)
    cnt=Counter(d['kind'] for r in results for d in r['destinations'])
    summary={'project':PROJECT,'source_git_blob':SOURCE,'inputs_sha256':SHA,
             'cases_verified':corpus_cases,'signed_steps_verified':corpus_steps,
             'cases_selected':checked,'read_roots':len(results),
             'unknown_roots':sum(r['uncertain'] for r in results),
             'sinks_by_kind':dict(cnt),'synthetic_and_hostile_checks':tests,
             'signed_original_mutations_rejected':real_mutations,
             'first_use_by_site':dict(Counter(str((r['read_ip'],r['first_use']['ip'],r['first_use']['op'])) for r in results)),
             'write_value_sites':dict(Counter(str(d['ip']) for r in results for d in r['destinations'] if d['kind']=='write_value')),
             'witnesses_sha256':digest(encoded), 'new_native_runs':0,
             'stage1_pass':False,'global_causality_proven':False}
    (args.out/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,sort_keys=True,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(summary,ensure_ascii=False,sort_keys=True))


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--self-test',action='store_true')
    for name in ('ai','bc','bg','bh','bi','out'):
        ap.add_argument('--'+name,type=Path)
    args=ap.parse_args()
    if args.self_test:
        print(json.dumps({'self_test_checks':hostile(),'stage1_pass':False}))
    else:
        need(all(getattr(args,name) is not None for name in ('ai','bc','bg','bh','bi','out')),
             '--ai --bc --bg --bh --bi --out required')
        run(args)


if __name__=='__main__':
    main()