#!/usr/bin/env python3
"""QA31BG oracle A: bounded physical signed-event audit, no new Native run.

Usage: python stage1_qa31bg_signed_physical_audit.py QA31AI.zip QA31BC.zip OUT.json
No imported QA31BF code or report counts: consumes original gzip STEP bytes.
"""
import collections,copy,gzip,hashlib,io,json,sys,zipfile
from pathlib import Path
P='PC-BRANCH-BEFUNGE98-KYRGYZ'
ORIGINAL_SHA='9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49'
INDEX_SHA='2e4c4809c73438359900e3f54bc616c21282fed83a4784228965da2b8b3b3a77'
SOURCE_BLOB='560d6aa5807a7f766213a33835cce85eab0fa40c'

def verified_zip(b,expected=None):
    if expected:assert hashlib.sha256(b).hexdigest()==expected,('ZIP_SHA',expected)
    z=zipfile.ZipFile(io.BytesIO(b));assert z.testzip() is None,('ZIP_CRC',);return z

def source_cases(archive):
    mid=verified_zip(archive.read('QA31AH_BEFUNGE98_KYRGYZ_ORIGINAL_29_UPSTREAM_PREFIX_20261106.zip'))
    inner=verified_zip(mid.read('QA31Y_BEFUNGE98_KYRGYZ_FULL_EVIDENCE_20261104.zip'))
    for shard in range(8):
        sh=verified_zip(inner.read(f'QA31V_SHARD{shard}.zip'))
        for name in sh.namelist():
            if name.endswith('.jsonl.gz'):yield shard,name,sh.read(name)

def hits(w,op,ip,address=None):
    return [(i,r) for i,r in enumerate(w) if r['op']==ord(op) and r['ip']==list(ip) and (address is None or r['pre'][-2:]==list(address))]

def last_physical_writer(rows,read_tick,address):
    for r in reversed(rows[:read_tick-1]):
        if r['op']==112 and len(r['pre'])>=3 and r['pre'][-2:]==list(address):
            return (r['t'],tuple(r['ip']),r['pre'][-3])
    return None

def check(win,pre_owner):
    assert len(win)==1024,('WINDOW_LENGTH',len(win))
    for a,b in zip(win,win[1:]):
        assert a['t']+1==b['t'] and a['next']==b['ip'] and a['post']==b['pre'],('TRACE_CHAIN',a['t'])
    anchors=[('p43','p',(962,480),(43,1702)),('g43a','g',(958,1050),(43,1702)),
             ('g43b','g',(174,195),(43,1702)),('p53','p',(860,99),(53,1704))]
    a={}
    for tag,op,ip,addr in anchors:
        match=hits(win,op,ip,addr)
        assert len(match)==1,('ANCHOR',tag,len(match))
        a[tag]=match[0]
    assert a['p43'][0]<a['g43a'][0]<a['p53'][0]<a['g43b'][0],('ORDER',)
    p43=a['p43'][1];p53=a['p53'][1]
    assert pre_owner==(p43['t'],tuple(p43['ip']),p43['pre'][-3]),('OWNER',)
    assert a['g43a'][1]['post'][-1]==a['g43b'][1]['post'][-1]==p43['pre'][-3],('G43_VALUES',)
    # Physical p53 relation is measured, not assumed to be equality.
    assert not any(r['op']==112 and r['pre'][-2:]==[43,1702] for r in win[a['p43'][0]+1:]),('P43_REWRITE',)
    g43all=[r for r in win if r['op']==103 and r['pre'][-2:]==[43,1702]]
    assert len(g43all)==2,('EXTRA_G43',len(g43all))
    x=[r for r in win if r['op']==120]
    j=[r for r in win if r['op']==106]
    for r in x:
        assert r['next']==[r['ip'][0]+r['pre'][-2],r['ip'][1]+r['pre'][-1]],('X_VECTOR',r['t'])
        assert r['post']==r['pre'][:-2],('X_STACK',r['t'])
    for r in j:
        assert r['post']==r['pre'][:-1],('J_STACK',r['t'])
    assert len(x)==26 and not j,('BRANCH_COUNT',len(x),len(j))
    return a,x,j

def hostile(win,owner):
    anchor,xx,_=check(win,owner)
    p=anchor['p43'][0];g=anchor['g43a'][0];h=anchor['g43b'][0];q=anchor['p53'][0]
    ix=next(i for i,r in enumerate(win) if r['op']==120 and i>g)
    edits=[
        ('tick',lambda w:w[0].__setitem__('t',w[0]['t']+1)),
        ('first-next',lambda w:w[0]['next'].__setitem__(0,w[0]['next'][0]+1)),
        ('first-stack',lambda w:w[1]['pre'].append(987)),
        ('p43-opcode',lambda w:w[p].__setitem__('op',ord('g'))),
        ('p43-ip',lambda w:w[p]['ip'].__setitem__(0,w[p]['ip'][0]+1)),
        ('p43-coordinate',lambda w:w[p]['pre'].__setitem__(-1,1703)),
        ('p43-value',lambda w:w[p]['pre'].__setitem__(-3,w[p]['pre'][-3]+3)),
        ('g43a-opcode',lambda w:w[g].__setitem__('op',ord('p'))),
        ('g43a-address',lambda w:w[g]['pre'].__setitem__(-2,44)),
        ('g43a-value',lambda w:w[g]['post'].__setitem__(-1,w[g]['post'][-1]+1)),
        ('g43b-address',lambda w:w[h]['pre'].__setitem__(-1,1701)),
        ('g43b-value',lambda w:w[h]['post'].__setitem__(-1,w[h]['post'][-1]+1)),
        ('p53-value',lambda w:w[q]['pre'].__setitem__(-3,w[q]['pre'][-3]+1)),
        ('p53-destination',lambda w:w[q]['pre'].__setitem__(-2,54)),
        ('x-operand',lambda w:w[ix]['pre'].__setitem__(-2,w[ix]['pre'][-2]+1)),
        ('x-next',lambda w:w[ix]['next'].__setitem__(0,w[ix]['next'][0]+1)),
        ('duplicate-p43',lambda w:w.insert(p+1,copy.deepcopy(w[p]))),
        ('swap-steps',lambda w:w.__setitem__(slice(g+1,g+3),list(reversed(w[g+1:g+3])))),
    ]
    passed=[]
    for tag,mod in edits:
        change=copy.deepcopy(win);mod(change)
        assert change!=win,('NOOP',tag)
        try:check(change,owner)
        except (AssertionError,IndexError,KeyError,TypeError,ValueError):passed.append(tag)
        else:raise AssertionError(('HOSTILE_ACCEPTED',tag))
    return passed

def main(first,second,out):
    orig=verified_zip(Path(first).read_bytes(),ORIGINAL_SHA)
    idx=verified_zip(Path(second).read_bytes(),INDEX_SHA)
    metadata=json.loads(idx.read('qa31bc_full_original_selector_routes.json'))
    assert metadata['source_git_blob']==SOURCE_BLOB
    assert metadata['original_signed_archive_sha256']==ORIGINAL_SHA
    refs={(r['shard'],r['trace_sha256']):r for r in metadata['per_case']}
    assert len(refs)==200
    counts=collections.Counter();vectors=collections.Counter();witnesses=[];mutations=[]
    for shard,name,compressed in source_cases(orig):
        dg=hashlib.sha256(compressed).hexdigest()
        rec=refs.pop((shard,dg));assert rec['trace']==name
        rows=[json.loads(b) for b in gzip.decompress(compressed).splitlines()]
        assert len(rows)==rec['steps'] and rows[-1]['op']==64,('LENGTH_OR_HALT',name)
        assert all(r['t']==i+1 for i,r in enumerate(rows)),('TICK_SEQUENCE',name)
        assert all(a['next']==b['ip'] and a['post']==b['pre'] for a,b in zip(rows,rows[1:])),('STEP_CHAIN',name)
        counts['cases']+=1;counts['steps']+=len(rows)
        for i,r in enumerate(rows):
            if r['op']!=120 or r['ip']!=[540,195] or r['next']!=[575,670]:continue
            win=rows[i+1:min(i+1025,len(rows))]
            assert len(win)==1024,('EARLY_HALT',name)
            p43=hits(win,'p',(962,480),(43,1702))
            assert len(p43)==1
            p_at=p43[0][1]
            g1=hits(win,'g',(958,1050),(43,1702));g2=hits(win,'g',(174,195),(43,1702))
            assert len(g1)==len(g2)==1
            own1=last_physical_writer(rows,g1[0][1]['t'],(43,1702))
            own2=last_physical_writer(rows,g2[0][1]['t'],(43,1702))
            assert own1==own2,('TWO_READ_OWNERS',name)
            a,x,j=check(win,own1)
            for v in x:vectors[str((tuple(v['ip']),tuple(v['pre'][-2:]),tuple(v['next'])))]+=1
            counts.update({'windows':1,'g43_last_writer_exact':2,'x_validated':len(x),'j_observed':len(j),
                           'p53_equals_g43_observed':int(a['p53'][1]['pre'][-3]==g1[0][1]['post'][-1]),'p53_differs_g43_observed':int(a['p53'][1]['pre'][-3]!=g1[0][1]['post'][-1])})
            witnesses.append({'shard':shard,'trace':name,'trace_sha256':dg,'second_x_t':r['t'],
                'p43_t':p_at['t'],'p43_value':p_at['pre'][-3],
                'g43a_t':g1[0][1]['t'],'g43b_t':g2[0][1]['t'],
                'owner_t':own1[0],'owner_ip':list(own1[1]),
                'p53_t':a['p53'][1]['t'],'p53_value':a['p53'][1]['pre'][-3],
                'branch_x_count':len(x),'branch_j_count':len(j),'window_steps':len(win)})
            if not mutations:mutations=hostile(win,own1)
        if counts['cases']%50==0:print('PHYSICAL_PROGRESS',counts['cases'],counts['windows'],flush=True)
    assert not refs and counts['cases']==200 and counts['steps']==3628390
    assert counts['windows']==225 and counts['g43_last_writer_exact']==450
    assert counts['x_validated']==5850 and counts['j_observed']==0 and counts['p53_equals_g43_observed']+counts['p53_differs_g43_observed']==225
    assert len(mutations)>=12
    payload={'project_id':P,'schema':'qa31bg-original-signed-physical-v1',
            'original_outer_zip_sha256':ORIGINAL_SHA,'original_index_zip_sha256':INDEX_SHA,
            'source_git_blob_pinned_not_freshly_replayed':SOURCE_BLOB,
            'counts':dict(counts),'distinct_x_routes':len(vectors),'x_route_counts':dict(vectors),
            'hostile_rejected':mutations,'witnesses':witnesses,
            'scope':'200 signed original HALT traces; 225 observed 1024-STEP continuations; no unseen input conclusion',
            'new_native':0,'stage1_pass':False}
    Path(out).write_text(json.dumps(payload,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('QA31BG_PHYSICAL_PASS',json.dumps(payload['counts'],sort_keys=True),'hostile',len(mutations))
if __name__=='__main__':
    if len(sys.argv)!=4:raise SystemExit('usage: physical.py original.zip index.zip out.json')
    main(*sys.argv[1:])
