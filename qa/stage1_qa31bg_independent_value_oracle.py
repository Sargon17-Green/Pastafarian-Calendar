#!/usr/bin/env python3
"""QA31BG oracle B, independently replay signed stack opcodes and conditional g43 values.

Signed execution and counterfactual evaluation are separated explicitly.
Not a Native run, and there is no source-byte independent reparse.
"""
import collections,gzip,hashlib,io,json,sys,zipfile
from pathlib import Path
PROJECT='PC-BRANCH-BEFUNGE98-KYRGYZ'
ORIG='9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49'
META='2e4c4809c73438359900e3f54bc616c21282fed83a4784228965da2b8b3b3a77'
SRC='560d6aa5807a7f766213a33835cce85eab0fa40c'

def zopen(b,hex_digest=None):
    if hex_digest:assert hashlib.sha256(b).hexdigest()==hex_digest
    z=zipfile.ZipFile(io.BytesIO(b));assert z.testzip() is None
    return z

def corpus(root):
    layer1=zopen(root.read('QA31AH_BEFUNGE98_KYRGYZ_ORIGINAL_29_UPSTREAM_PREFIX_20261106.zip'))
    layer2=zopen(layer1.read('QA31Y_BEFUNGE98_KYRGYZ_FULL_EVIDENCE_20261104.zip'))
    for j in range(8):
        fragment=zopen(layer2.read('QA31V_SHARD%d.zip'%j))
        for filename in fragment.namelist():
            if filename.endswith('.jsonl.gz'):yield j,filename,fragment.read(filename)

def arith(a,b,op):
    if op=='+':return a+b
    if op=='-':return a-b
    if op=='*':return a*b
    if op=='/':return int(a/b) if b else 0
    if op=='%':return a%b if b else 0
    raise AssertionError(('ARITH',op))

def run_segment(w,start,end,replace=None):
    """Interpreter from a single authenticated g43 poststack to endpoint;
    records independent numeric + boolean dependence and branch vectors.
    For conditional run, all later g values use recorded signed receipts (held constant),
    and changed branch vectors are flagged rather than treated as physical execution.
    """
    root=w[start]
    assert root['op']==103 and root['pre'][-2:]==[43,1702]
    signed=replace is None
    stack=[(v,False) for v in root['post']]
    stack[-1]=(stack[-1][0] if signed else replace,True)
    branch_differences=[];branch_taint=[];put_values=[]
    for k in range(start+1,end+1):
        r=w[k];op=chr(r['op'])
        if signed:assert [v for v,_ in stack]==r['pre'],('PRE_REPLAY',r['t'])
        if op in '0123456789abcdef':stack.append((int(op,16),False))
        elif op in '+-*/%':
            assert len(stack)>=2,(op,r['t'])
            b,tb=stack.pop();a,ta=stack.pop()
            stack.append((arith(a,b,op),ta or tb))
        elif op=='g':
            y,ty=stack.pop();x,tx=stack.pop()
            if tx or ty:raise AssertionError(('TAINTED_G_ADDRESS',r['t']))
            assert [x,y]==r['pre'][-2:],('G_COORD',r['t']) if signed else ('G_COORD_POSSIBLY_CHANGED',r['t'])
            stack.append((r['post'][-1],False))
        elif op=='x':
            y,ty=stack.pop();x,tx=stack.pop()
            vector=(x,y)
            branch_taint.append((r['t'],tx or ty))
            if [r['ip'][0]+x,r['ip'][1]+y]!=r['next']:
                branch_differences.append((r['t'],vector))
            if signed:assert r['post']==[v for v,_ in stack],('X_POST',r['t'])
        elif op=='j':
            n,ta=stack.pop()
            branch_taint.append((r['t'],ta))
            # Do not infer direction or exact j targeting from this bounded stack-only replay.
        elif op=='p':
            y,ty=stack.pop();x,tx=stack.pop();v,tv=stack.pop()
            if tx or ty:raise AssertionError(('TAINTED_P_ADDRESS',r['t']))
            if signed:assert [v,x,y]==r['pre'][-3:],('P_COORD_VALUE',r['t'])
            put_values.append({'t':r['t'],'address':[x,y],'value':v,'depends_on_g43':tv})
        elif op in '<>^v ':
            pass
        else:raise AssertionError(('UNHANDLED_OPCODE',op,r['t']))
        if signed:assert [v for v,_ in stack]==r['post'],('POST_REPLAY',r['t'])
    return {'stack':[v for v,_ in stack],'taints':[t for _,t in stack],
            'tainted_branch_ticks':[t for t,a in branch_taint if a],
            'branch_count':len(branch_taint),'branch_differences':branch_differences,
            'puts':put_values,'tainted_final_cells':sum(int(t) for _,t in stack)}

def forward_ownership(rows):
    """Distinct from reverse writer search: forward mutable memory event index."""
    storage={};owners={};read_receipts=[]
    for r in rows:
        op=r['op'];pre=r['pre']
        if op==112 and len(pre)>=3:storage[tuple(pre[-2:])]=(r['t'],tuple(r['ip']),pre[-3])
        elif op==103 and len(pre)>=2 and pre[-2:]==[43,1702]:
            prev=storage.get((43,1702));assert prev is not None
            assert prev[-1]==r['post'][-1],('FORWARD_OWNER_MISMATCH',r['t'])
            owners[r['t']]=prev
            read_receipts.append(r['t'])
    return owners

def get_indices(w):
    def one(op,ip,coord):
        found=[k for k,r in enumerate(w) if r['op']==ord(op) and r['ip']==ip and r['pre'][-2:]==coord]
        assert len(found)==1,(op,ip,found)
        return found[0]
    return {'p43':one('p',[962,480],[43,1702]),
            'g43a':one('g',[958,1050],[43,1702]),
            'p53':one('p',[860,99],[53,1704]),
            'g43b':one('g',[174,195],[43,1702])}

def main(arch,bc,out):
    outer=zopen(Path(arch).read_bytes(),ORIG)
    ref=zopen(Path(bc).read_bytes(),META)
    ledger=json.loads(ref.read('qa31bc_full_original_selector_routes.json'))
    assert ledger['source_git_blob']==SRC and ledger['original_signed_archive_sha256']==ORIG
    bysha={(x['shard'],x['trace_sha256']):x for x in ledger['per_case']}
    cs=collections.Counter();effects=collections.Counter();records=[]
    for shard,name,compressed in corpus(outer):
        digest=hashlib.sha256(compressed).hexdigest()
        meta=bysha.pop((shard,digest));assert name==meta['trace']
        raw_lines=gzip.decompress(compressed).splitlines()
        assert len(raw_lines)==meta['steps'] and json.loads(raw_lines[-1])['op']==64
        cs['cases']+=1;cs['steps']+=len(raw_lines)
        # Independent bounded slicing: only parse source event and following 1024
        # STEP records. All compressed bytes remain SHA-pinned and gzip-validated.
        candidates=[n for n,line in enumerate(raw_lines) if b'"ip":[540,195]' in line]
        for pos in candidates:
            r=json.loads(raw_lines[pos])
            if r['op']!=120 or r['next']!=[575,670]:continue
            assert pos+1025<=len(raw_lines)
            w=[json.loads(line) for line in raw_lines[pos+1:pos+1025]]
            assert all(q['t']==pos+2+j for j,q in enumerate(w))
            assert len(w)==1024
            assert all(a['next']==b['ip'] and a['post']==b['pre'] for a,b in zip(w,w[1:])),('INCONSISTENT_CHAIN',name)
            a=get_indices(w)
            assert a['p43']<a['g43a']<a['p53']<a['g43b']
            p=w[a['p43']];g=w[a['g43a']];g2=w[a['g43b']];p53=w[a['p53']]
            # Forward on-window memory ownership, algorithmically distinct from
            # oracle A's reverse full-trace search.
            writers=forward_ownership(w)
            assert writers[g['t']]==writers[g2['t']]==(p['t'],tuple(p['ip']),p['pre'][-3])
            assert g['post'][-1]==g2['post'][-1]==p['pre'][-3]
            f_ob=run_segment(w,a['g43a'],a['p53'])
            f0=run_segment(w,a['g43a'],a['p53'],0)
            f1=run_segment(w,a['g43a'],a['p53'],1)
            assert f_ob['puts']==[{'t':p53['t'],'address':[53,1704],'value':p53['pre'][-3],'depends_on_g43':True}],('CAUSAL_P53',name)
            assert f0['puts'][0]['value']!=f1['puts'][0]['value'],('CF_P53_UNCHANGED',name)
            assert f1['puts'][0]['value']-f0['puts'][0]['value']==1,('CF_P53_NOT_UNIT_SLOPE',name)
            assert not f_ob['tainted_branch_ticks'] and not f0['branch_differences'] and not f1['branch_differences']
            s_ob=run_segment(w,a['g43b'],len(w)-1)
            s0=run_segment(w,a['g43b'],len(w)-1,0)
            s1=run_segment(w,a['g43b'],len(w)-1,1)
            assert not s_ob['puts'] and not s_ob['tainted_branch_ticks']
            assert not s0['branch_differences'] and not s1['branch_differences']
            cs.update({'windows':1,'g43_forward_owner_matches':2,'first_read_conditional_p53_unit_slope':1,
                'first_path_untainted_branch_count':f_ob['branch_count'],
                'second_path_untainted_branch_count':s_ob['branch_count'],
                'second_path_tainted_stack_entries':s_ob['tainted_final_cells']})
            effects['p53_minus_g43_'+str(p53['pre'][-3]-g['post'][-1])]+=1
            records.append({'shard':shard,'trace':name,'compressed_sha256':digest,'x_t':r['t'],
              'p43_t':p['t'],'p43_value':p['pre'][-3],'g43a_t':g['t'],'g43b_t':g2['t'],
              'p53_t':p53['t'],'p53_value':p53['pre'][-3],
              'p53_conditional_g43_0':f0['puts'][0]['value'],
              'p53_conditional_g43_1':f1['puts'][0]['value'],
              'first_branch_count':f_ob['branch_count'],
              'second_branch_count':s_ob['branch_count'],
              'end_stack_tainted_slots':s_ob['tainted_final_cells'],
              'end_stack_differs_0_1':s0['stack']!=s1['stack']})
        if cs['cases']%50==0:print('SYMBOLIC_PROGRESS',cs['cases'],cs['windows'],flush=True)
    assert not bysha and cs['cases']==200 and cs['steps']==3628390 and cs['windows']==225
    assert cs['g43_forward_owner_matches']==450 and cs['first_read_conditional_p53_unit_slope']==225
    assert len(records)==225
    data={'project_id':PROJECT,'schema':'qa31bg-independent-stack-value-v1',
          'original_outer_zip_sha256':ORIG,'original_index_zip_sha256':META,
          'source_git_blob_pinned_not_freshly_replayed':SRC,'counts':dict(cs),
          'effects':dict(effects),'witnesses':records,
          'counterfactual_caveat':'g43 manually set to 0/1; all later g receipts held fixed, verified x vectors unchanged; no physical alternate Native execution',
          'new_native':0,'stage1_pass':False}
    Path(out).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('QA31BG_SYMBOLIC_PASS',json.dumps(data['counts'],sort_keys=True))
if __name__=='__main__':
    if len(sys.argv)!=4:raise SystemExit('independent.py original.zip index.zip out.json')
    main(*sys.argv[1:])
