#!/usr/bin/env python3
"""Independent full-step QA31G receipt/overlay/EOF/forgery verifier."""
import sys,json,gzip,copy,hashlib
from pathlib import Path
PIN='560d6aa5807a7f766213a33835cce85eab0fa40c'
INPUTS={'empty':b'','digit':b'1','digit_space':b'1 '}
def need(x,msg):
    if not x:raise AssertionError(msg)
def sha(x):return hashlib.sha256(x).hexdigest()
def readsrc(path):
    b=path.read_bytes()
    h=hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()
    need(h==PIN,'source Git blob drift')
    return b.splitlines()
def check(report,folder,rows):
    need(report['schema']=='qa31g-original-native-eof-v1'
         and report['source_blob']==PIN and report['source_modified'] is False
         and report['ip_relocated'] is False
         and report['native_expected_model_proven'] is False
         and report['stage1_pass'] is False,'source or scope forged')
    seen={}
    need(len(report['cases'])==3,'expected three cases')
    for item in report['cases']:
        label=item['label']
        need(label in INPUTS and label not in seen,'case label')
        raw=INPUTS[label]
        need(item['raw_hex']==raw.hex() and item['raw_sha256']==sha(raw),'stdin provenance')
        name='qa31g_'+label+'.jsonl.gz'
        need(item['trace']==name,'file name')
        z=(folder/name).read_bytes()
        need(sha(z)==item['trace_sha256'],'compressed trace integrity')
        records=[json.loads(line) for line in gzip.decompress(z).splitlines()]
        need(len(records)==item['steps'] and 0<len(records)<=7000,'all steps')
        overlay={};count_reads=0;j29=[];j32=[];p35=[]
        for i,s in enumerate(records):
            need(s['t']==i+1,'step sequence')
            x,y=s['ip'];dx,dy=s['delta']; pre=s['pre'];post=s['post']
            need(0<=y<len(rows) and 0<=x<len(rows[y]),'IP bounds')
            need(s['op']==overlay.get((x,y),rows[y][x]),'physical opcode/source overlay')
            need(not s['string'],'unexpected stringmode (independent model scope)')
            need(all(type(v) is int for v in pre+post) and len(pre)<5000 and len(post)<5000,'stack')
            if i:
                need(records[i-1].get('next')==s['ip']
                     and records[i-1].get('next_delta')==s['delta'],'native IP continuity')
            op=s['op']
            if op==ord('p'):
                need(len(pre)>=3 and post==pre[:-3],'p stack')
                py,px,value=pre[-1],pre[-2],pre[-3]
                overlay[(px,py)]=value
                if (x,y)==(248,35):p35.append((i+1,px,py,value))
            elif op==ord('g'):
                need(len(pre)>=2 and len(post)==len(pre)-1,'g stack')
                py,px=pre[-1],pre[-2]
                memory=overlay.get((px,py),
                    rows[py][px] if 0<=py<len(rows) and 0<=px<len(rows[py]) else 32)
                need(post[-1]==memory,'g memory semantics')
            elif op==ord('j') and (x,y) in ((89,29),(113,32)):
                v=pre[-1] if pre else 0
                need(post==(pre[:-1] if pre else []),'j pop')
                (j29 if y==29 else j32).append((i+1,v,overlay.get((3,49),rows[49][3])))
            for e in s['reads']:
                a,b=e['start'],e['end']
                need(e['t']==i+1 and e['ip']==s['ip'] and e['stack']==pre
                     and e['method'] in ('read','readline')
                     and type(a) is int and type(b) is int
                     and 0<=a<=b<=len(raw) and e['hex']==raw[a:b].hex(),'EOF/input trace')
                count_reads+=1
        need(count_reads==item['reads'],'read count')
        need(item['status'] in ('HALT','STEP_LIMIT','RUNTIME_ERROR'),'status')
        need((item['status']=='RUNTIME_ERROR')==(item['error'] is not None),'error receipt')
        if item['status']=='HALT': need(records[-1]['next'] is None,'halt step')
        seen[label]={'steps':len(records),'status':item['status'],'reads':count_reads,
                     'eof_reads':sum(e['start']==e['end'] for s in records for e in s['reads']),
                     'j29':j29,'j32':j32,'p35':p35,'output':item['output']}
    need(set(seen)==set(INPUTS),'missing case')
    return seen
def main(src,folder):
    rows=readsrc(src)
    report=json.loads((folder/'qa31g_receipt.json').read_text())
    facts=check(report,folder,rows)
    rejections=0
    for attack in (
       lambda r:r.__setitem__('source_blob','0'*40),
       lambda r:r.__setitem__('stage1_pass',True),
       lambda r:r['cases'][0].__setitem__('steps',999),
       lambda r:r['cases'][1].__setitem__('raw_hex','00'),
       lambda r:r['cases'][2].__setitem__('trace_sha256','0'*64)):
        copy_report=copy.deepcopy(report);attack(copy_report)
        try:check(copy_report,folder,rows)
        except (AssertionError,KeyError,TypeError,ValueError):rejections+=1
        else:raise AssertionError('forgery accepted')
    need(rejections==5,'forgeries not rejected')
    d=facts['digit'];a=facts['empty'];b=facts['digit_space']
    match=(d['status']=='HALT' and a['status']=='HALT' and b['status']=='HALT'
           and any(z[1]==61 and z[2]==1 for z in d['j29'])
           and d['j32'] and any(z[1:]==(1,49,1) for z in d['p35'])
           and a['j29'] and b['j29']
           and all(z[1]==0 for z in a['j29']+b['j29']))
    verdict='MODEL_MATCH' if match else 'MODEL_MISMATCH_OR_INCOMPLETE'
    result={'schema':'qa31g-independent-v1','cases_verified':3,
            'forgeries_rejected':5,'verdict':verdict,
            'facts':facts,'stage1_pass':False}
    (folder/'qa31g_independent.json').write_text(json.dumps(result,indent=2,sort_keys=True)+'\n')
    print('QA31G_FULL_NATIVE_TRACE_STEPS',sum(x['steps'] for x in facts.values()))
    print('QA31G_FIVE_FORGERIES_REJECTED')
    print('QA31G_NATIVE_MODEL_VERDICT',verdict)
    print('QA31G_NO_STAGE1_ACCEPTANCE')
if __name__=='__main__':
    main(Path(sys.argv[1]),Path(sys.argv[2]))
