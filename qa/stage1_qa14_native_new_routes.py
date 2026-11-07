#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA14: NEW independent native 2D PyFunge routes; no Python calendar oracle.

32 directed cases from 16 unambiguously frozen pairs. Each row performs
three separate native BF98 reference calls, one traced QA-production call,
and one fresh untraced QA-production call. Archives raw interpreter traces.
Not a Stage-1 final completion or universal state ownership proof.
"""
from __future__ import print_function
import hashlib, json, os, subprocess, sys

SOURCE='src/interleaved_work_counts.b98'
PIN='560d6aa5807a7f766213a33835cce85eab0fa40c'
CMD=['pyfunge','--disable-fprint','--no-concurrent','--no-filesystem','-v98','-d2']
M=(1<<127)-1
PAIRS=(
 (-15055673,-15055672),(-15055672,-15055671),
 (-15055671,-15055670),(-15055670,-15055669),
 (-15055672,-15055670),(-15055672,0),
 (-15055670,1),(-1,0),(-2,2),(1,2),
 (2,3),(15055670,15055672),(-M,M),
 (M,M+1),(-(M+1),-M),(10**80+17,-(10**80+19)),
)

def cases():
    out=[]
    for i,(c,t) in enumerate(PAIRS):
        out.append(('pair%02d_A'%i,c,t))
        out.append(('pair%02d_B'%i,t,c))
    return out

def require(ok,why):
    if not ok: raise AssertionError(why)

def blob(data):
    return hashlib.sha1('blob %d\0'%(len(data))+data).hexdigest()

def encode(n):
    return ('1' if n<0 else '0')+' '+str(abs(n))

def execute(path,text,trace=None):
    env=os.environ.copy()
    env.pop('BF98_TRACE_LOG',None)
    env.pop('PYTHONPATH',None)
    if trace is not None:
        env['BF98_TRACE_LOG']=trace
        env['PYTHONPATH']='/work/qa'
    command=['timeout','--kill-after=3s','55s']+CMD+[path]
    p=subprocess.Popen(command,stdin=subprocess.PIPE,stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE,env=env)
    stdout,stderr=p.communicate(text)
    require(p.returncode==0,
            'native BF98 nonzero path=%r input=%r rc=%r err=%r'%(
             path,text,p.returncode,stderr[-500:]))
    parts=stdout.split()
    require(len(parts)>0,'empty Native stdout from '+path)
    return parts

def main(shard,output):
    require(shard in (0,1,2,3),'invalid Native shard')
    require(os.path.isdir(output),'missing artifact directory')
    code=open(SOURCE,'rb').read()
    require(blob(code)==PIN,'production source blob changed')
    rows=[]
    data=cases()
    require(len(data)==32 and len(set(x[0] for x in data))==32,
            'QA14 control corpus malformed')
    for k,(label,c,t) in enumerate(data):
        if k%4!=shard: continue
        cal=encode(c);targ=encode(t)
        raw=cal+' '+targ+'\n'
        work=execute('reference/work_counts.b98',raw)
        savec=execute('reference/save.b98',cal+'\n')
        savet=execute('reference/save.b98',targ+'\n')
        expected=work+savec+savet
        require(len(expected)==7,'independent BF98 reference wrong shape')
        location=os.path.join(output,label+'.tsv')
        actual=execute(SOURCE,raw,location)
        repeat=execute(SOURCE,raw)
        require(actual==repeat==expected,
                'Native traced/untraced/reference mismatch '+label)
        with open(location,'rb') as rd:
            evidence=rd.read()
        require(len(evidence)>50000 and evidence.startswith('STEP\t1\t'),
                'missing real executed Native trace '+label)
        with open(os.path.join(output,label+'.out'),'wb') as f:
            f.write(' '.join(actual)+'\n')
        rows.append({'label':label,'signed_days':[str(c),str(t)],
                     'transport':raw.strip(),'valid':True,
                     'stdout':actual,'trace_file':label+'.tsv',
                     'trace_sha256':hashlib.sha256(evidence).hexdigest(),
                     'trace_bytes':len(evidence),'native_interpreter_calls':5})
        print('QA14_NEW_REAL_NATIVE_ROUTE',shard,label,'trace_bytes',len(evidence))
        sys.stdout.flush()
    require(len(rows)==8,'expected exactly eight directed cases per shard')
    manifest={'schema':'qa14-expanded-new-native-2d-routes-v1','source_git_blob':PIN,
              'reference_pins':{
                'reference/work_counts.b98':'f941efc793c9eee4accf5d03873f8ed029b16725',
                'reference/save.b98':'7b5e79aa6e2bfb636717cb018a3db6a13fb2bb44'},
              'shard':shard,'shards':4,'reference_invocations':24,
              'native_production_invocations':16,'native_traced_invocations':8,
              'records':rows,'stage1_final_acceptance':False}
    with open(os.path.join(output,'native_manifest.json'),'wb') as f:
        f.write(json.dumps(manifest,sort_keys=True,indent=2)+'\n')
    print('QA14_NATIVE_SHARD_PASS',shard,'new_cases',len(rows),'native_invocations',40)

if __name__=='__main__':
    require(len(sys.argv)==3,'usage: ... SHARD OUTPUT_DIR')
    main(int(sys.argv[1]),sys.argv[2])
