#!/usr/bin/env python3
"""QA31J: independent SHA-pinned full-STEP check for two new natural Native inputs."""
import copy,gzip,hashlib,json,sys
from pathlib import Path
PIN='560d6aa5807a7f766213a33835cce85eab0fa40c'
INPUTS={'digit_lf':b'1\n','digit_tab':b'1\t'}
CAP=7000
def need(ok,msg):
    if not ok:raise AssertionError(msg)
def sha(b):return hashlib.sha256(b).hexdigest()
def source(path):
    b=Path(path).read_bytes()
    h=hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()
    need(h==PIN,'Git blob source drift')
    return b.splitlines()
def cell(rows,x,y):
    return rows[y][x] if 0<=y<len(rows) and 0<=x<len(rows[y]) else 32

def validate(report,traces,rows):
    need(report['schema']=='qa31j-unseen-native-v1' and
         report['source_blob']==PIN and report['source_modified'] is False and
         report['ip_relocated'] is False and report['stage1_pass'] is False and
         report['original_qa31g_cases_rerun']==0 and report['new_native_cases']==2,
         'Native source/scope')
    cases=report['cases']
    need(len(cases)==2 and {c['label'] for c in cases}==set(INPUTS),
         'two exact new inputs')
    facts={}
    for c in cases:
        tag=c['label'];raw=INPUTS[tag];records=traces[tag]
        need(c['raw_hex']==raw.hex() and c['raw_sha256']==sha(raw),
             'raw original input bytes')
        need(c['trace']=='qa31g_'+tag+'.jsonl.gz','trace name')
        need(len(records)==c['steps'] and 0<len(records)<=CAP,'physical STEP count')
        need(c['status'] in ('HALT','STEP_LIMIT','RUNTIME_ERROR'),'status')
        need((c['status']=='RUNTIME_ERROR')==(c['error'] is not None),'error receipt')
        overlay={};reads=[];puts=0;gets=0;gates=[]
        for i,s in enumerate(records):
            need(s['t']==i+1,'STEP order')
            ip=s['ip'];d=s['delta'];pre=s['pre'];post=s['post']
            need(len(ip)==len(d)==2 and d!=[0,0] and
                 all(type(v) is int for v in ip+d),'IP/delta bounds')
            x,y=ip
            need(s['op']==overlay.get((x,y),cell(rows,x,y)),
                 'original source/physical opcode overlay')
            need(s['string'] is False,'unsupported string mode in narrow oracle')
            need(type(pre) is list and type(post) is list and
                 all(type(v) is int for v in pre+post),'physical stack')
            if i:
                need(records[i-1]['next']==ip and
                     records[i-1]['next_delta']==d,'IP continuity')
            op=s['op']
            need(op not in (ord('{'),ord('}'),ord('u'),ord('s')),
                 'offset/stackspace/unmodeled source mutation')
            if op==ord('p'):
                need(len(pre)>=3 and post==pre[:-3],'physical p semantics')
                overlay[(pre[-2],pre[-1])]=pre[-3];puts+=1
            if op==ord('g'):
                need(len(pre)>=2 and post[:-1]==pre[:-2] and
                     len(post)==len(pre)-1,'physical g stack')
                px,py=pre[-2:]
                need(post[-1]==overlay.get((px,py),cell(rows,px,py)),
                     'g read source/last write')
                gets+=1
            if op==ord('j') and ip in ([89,29],[113,32]):
                v=pre[-1] if pre else 0
                need(post==(pre[:-1] if pre else []),'j operand pop')
                need(s['next']==[x+(v+1)*d[0],y+(v+1)*d[1]],
                     'j original physical successor')
                gates.append({'t':i+1,'point':ip,'operand':v})
            need(type(s['reads']) is list,'input event list')
            for e in s['reads']:
                a,b=e['start'],e['end']
                need(e['t']==i+1 and e['ip']==ip and e['stack']==pre and
                     e['method'] in ('read','readline') and
                     type(a) is int and type(b) is int and
                     0<=a<=b<=len(raw) and e['hex']==raw[a:b].hex(),
                     'exact input read event')
                reads.append(e)
        need(reads and len(reads)==c['reads'],'input reads tally')
        need(reads[0]['ip']==[13,5] and reads[0]['start']==0 and
             reads[0]['end']==len(raw) and reads[0]['hex']==raw.hex(),
             'natural first read must preserve unseen bytes')
        if c['status']=='HALT':
            need(records[-1]['next'] is None and records[-1]['op']==ord('@'),
                 'HALT receipt')
        elif c['status']=='STEP_LIMIT':
            need(len(records)==CAP,'capped receipt')
        facts[tag]={'status':c['status'],'steps':len(records),
             'reads':len(reads),'puts':puts,'gets':gets,'gates':gates,
             'first_read_t':reads[0]['t'],'first_read_hex':reads[0]['hex'],
             'output':c['output']}
    return facts

def mutants(report,traces,rows):
    rejected=[]
    def attempt(name,fn):
        r=copy.deepcopy(report);t=copy.deepcopy(traces)
        fn(r,t)
        try:validate(r,t,rows)
        except (AssertionError,TypeError,KeyError,IndexError,ValueError):
            rejected.append(name)
        else:raise AssertionError('hostile forgery accepted: '+name)
    attempt('source pin',lambda r,t:r.__setitem__('source_blob','0'*40))
    attempt('fake PASS',lambda r,t:r.__setitem__('stage1_pass',True))
    attempt('wrong stdin',lambda r,t:r['cases'][0].__setitem__('raw_hex','3030'))
    attempt('short step count',lambda r,t:r['cases'][1].__setitem__('steps',1))
    attempt('delete STEP',lambda r,t:t['digit_lf'].pop(2))
    attempt('source opcode',lambda r,t:t['digit_tab'][0].__setitem__('op',0))
    attempt('first read byte',lambda r,t:next(s for s in t['digit_lf'] if s['reads'])['reads'][0].__setitem__('hex','00'))
    attempt('zero IP delta',lambda r,t:t['digit_tab'][1].__setitem__('delta',[0,0]))
    need(len(rejected)==8,'negative controls count')
    return rejected

def main(source_path,folder):
    rows=source(source_path);folder=Path(folder)
    r=json.loads((folder/'qa31j_receipt.json').read_text())
    traces={}
    for c in r['cases']:
        tag=c['label']
        need(tag in INPUTS and tag not in traces,'unique trace')
        compressed=(folder/c['trace']).read_bytes()
        need(sha(compressed)==c['trace_sha256'],'signed gzip content digest')
        traces[tag]=[json.loads(v) for v in gzip.decompress(compressed).splitlines()]
    facts=validate(r,traces,rows)
    negative=mutants(r,traces,rows)
    out={'schema':'qa31j-independent-byte-frontier-v1',
         'source_blob':PIN,'native_new_cases':len(facts),
         'physical_steps_checked':sum(x['steps'] for x in facts.values()),
         'mutations_rejected':negative,'facts':facts,
         'global_owner_proven':False,'stage1_pass':False,
         'full_functional_qa_pass':False,'geometric_spaghetti_qa_pass':False}
    (folder/'qa31j_independent.json').write_text(json.dumps(out,indent=2,sort_keys=True)+'\n')
    print('QA31J_INDEPENDENT_CASES',len(facts))
    print('QA31J_INDEPENDENT_STEPS',out['physical_steps_checked'])
    print('QA31J_EIGHT_MUTATIONS_REJECTED')
    print('QA31J_NO_STAGE1_PASS')
if __name__=='__main__':
    need(len(sys.argv)==3,'usage: audit source output_dir')
    main(sys.argv[1],sys.argv[2])
