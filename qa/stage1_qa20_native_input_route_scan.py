#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA20: bounded input-driven Native 2D IP reachability of QA18's 21 glyphs.
Never redirects an IP, edits Funge-space, or computes an expected calendar result in Python.
"""
from __future__ import print_function
import gzip, hashlib, json, os, subprocess, sys, StringIO
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_live_pair_matrix as native

SOURCE='src/interleaved_work_counts.b98'
PIN='560d6aa5807a7f766213a33835cce85eab0fa40c'
REF_COUNT='reference/work_counts.b98'
REF_SAVE='reference/save.b98'
MAX_TICKS=1250000
CLI=['timeout','--kill-after=3s','55s','pyfunge','--disable-fprint',
     '--no-concurrent','--no-filesystem','-v98','-d2']
M=(1<<127)-1
V=[
  (0,0,0,0),(0,0,0,1),(0,1,0,0),(0,1,0,1),(0,1,0,2),(0,2,0,1),
  (0,7,0,9),(0,15055670,0,15055671),(0,15055671,0,15055670),
  (0,15055672,0,15055673),(0,10**20+1,0,10**20+3),(0,M,0,M+1),
  (1,1,0,0),(0,0,1,1),(1,1,1,1),(1,2,1,1),
  (1,15055670,1,15055671),(1,15055671,1,15055670),
  (1,15055672,1,15055673),
  (1,987654321,0,123456789),(0,123456789,1,987654321),
  (1,M,0,M),(0,M,1,M),(1,10**80+19,0,10**80+17),
  (0,15055670,1,15055670),(1,15055670,0,15055670),
  (0,15055671,1,15055671)
]
I=[
  '1 0 0 0','0 0 1 0','2 10 0 10','0 10 2 10','3 2 0 4','1 0 1 15055671',
  '0 -1 0 1','-0 1 0 1','0 1 -0 1','0 1 0 -1','0 -0 0 1','0 0 0 -0',
  '0 -15055671 0 1','0 15055671 0 -15055670','0 1 0 1 7','0 1 0',
  '0 1 0 x','0 1 0 1/','','\n','0 1 0 +1'
]

def need(ok,msg):
    if not ok: raise AssertionError(msg)

def cases():
    vals=[('valid%02d'%i,' '.join(map(str,row))+'\n',True) for i,row in enumerate(V)]
    vals += [('invalid%02d'%i,raw+'\n',False) for i,raw in enumerate(I)]
    need(len(vals)==48 and len(set(x[0] for x in vals))==48,'corpus count or name drift')
    return vals

def native_run(source,raw):
    p=subprocess.Popen(CLI+[source],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    output,error=p.communicate(raw)
    need(p.returncode==0,'Native executable failed %s rc=%s tail=%r'%(source,p.returncode,error[-200:]))
    return output.split()

def ref(raw):
    a,b,c,d=map(int,raw.split())
    want=native_run(REF_COUNT,raw)
    want+=native_run(REF_SAVE,'%d %d\n'%(a,b))
    want+=native_run(REF_SAVE,'%d %d\n'%(c,d))
    need(len(want)==7,'reference process produced wrong result shape')
    return want

def pin(data):
    return hashlib.sha1('blob %d\0%s'%(len(data),data)).hexdigest()

def targets_from_qa18(path,source):
    p=json.load(open(path,'rb'))
    need(p.get('schema')=='qa18-source-glyph-contact-v1' and
         p.get('source_git_blob')==PIN and p.get('native_original_trace_count')==49 and
         p.get('stage1_complete') is False and p.get('dead_code_certified') is False,
         'untrusted QA18 baseline')
    raw=p['never_touched_potential_control_glyphs']
    need(len(raw)==21,'21 original candidate cells missing')
    rows=source.splitlines()
    keys=[]
    for p in raw:
        x,y=int(p['x']),int(p['y'])
        need(chr(ord(rows[y][x]))==p['source_char'],'candidate source glyph mismatch')
        keys.append((x,y,p['source_char']))
    need(len(set((x,y) for x,y,_ in keys))==21,'duplicate candidate')
    return keys

def create_program(source, raw, label):
    sin=StringIO.StringIO(raw)
    sout=StringIO.StringIO()
    platform=BufferedPlatform([],{},stdin=sin,stdout=sout)
    program=Program(Befunge98,platform=platform)
    program.load_code(source)
    program.create_ip()
    need(len(program.ips)==1,'Native source requires one original IP')
    return {'program':program,'stdin':sin,'stdout':sout,
            'point':program.ips[0].position.__class__, 'steps':0, 'label':label}

def sample(source,label,raw,valid,targets,folder):
    p=create_program(source,raw,label)
    nearest={str(x)+','+str(y):[10**10,None] for x,y,_ in targets}
    actual={str(x)+','+str(y):[] for x,y,_ in targets}
    fpath=os.path.join(folder,label+'.steps.gz')
    out=gzip.open(fpath,'wb')
    try:
        while p['program'].ips:
            ip=p['program'].ips[0]
            x,y=map(int,ip.position);dx,dy=map(int,ip.delta)
            opcode=int(p['program'].space.get(ip.position));string=bool(ip.stringmode)
            tick=p['steps']+1
            out.write('%d\t%d\t%d\t%d\t%d\t%d\t%d\n'%(tick,x,y,dx,dy,opcode,int(string)))
            for tx,ty,ch in targets:
                d=abs(x-tx)+abs(y-ty); k='%d,%d'%(tx,ty)
                if d<nearest[k][0]:nearest[k]=[d,[tick,x,y,dx,dy,opcode,int(string)]]
                if d==0:actual[k].append([tick,opcode,int(string)])
            native.tick(p)
            need(p['steps']<=MAX_TICKS,'bounded Native route did not terminate '+label)
    finally:
        out.close()
    got=p['stdout'].getvalue().split()
    want=ref(raw) if valid else ['-1']*7
    need(got==want,'%s actual Native BF98 output != native oracle/sentinel'%label)
    need(len(got)==7 and p['steps']>0,'Native output invalid')
    blob=open(fpath,'rb').read()
    return {'label':label,'raw_input':raw,'valid':valid,'steps':p['steps'],
            'output':got,'expected':want,'nearest':nearest,'target_step_hits':actual,
            'path':label+'.steps.gz','compressed_trace_sha256':hashlib.sha256(blob).hexdigest(),
            'compressed_bytes':len(blob),'natural_ip_no_intervention':True}

def main(shard,folder,qa18):
    need(shard in (0,1,2,3),'shard invalid')
    need(os.path.isdir(folder),'missing evidence output directory')
    source=open(SOURCE,'rb').read()
    need(pin(source)==PIN==native.PIN,'signed Native source changed')
    targets=targets_from_qa18(qa18,source)
    rows=[]
    for i,(label,raw,valid) in enumerate(cases()):
        if i%4!=shard:continue
        row=sample(source,label,raw,valid,targets,folder)
        rows.append(row)
        print('QA20_NATURAL_INPUT_NATIVE',shard,label,'steps',row['steps'],
              'reached',sum(bool(v) for v in row['target_step_hits'].values()))
        sys.stdout.flush()
    need(len(rows)==12,'shard must have 12 real Native executions')
    result={'schema':'qa20-native-natural-route-21-controls-v1',
      'source_git_blob':PIN,'qa18_original_run':39423789058,
      'shard':shard,'source_modified':False,'ip_relocated':False,
      'native_case_count':len(rows),'targets':[list(x) for x in targets],
      'stage1_final_acceptance':False,'all_natural_reachability_proved':False,
      'records':rows}
    with open(os.path.join(folder,'qa20_manifest.json'),'wb') as f:
        f.write(json.dumps(result,sort_keys=True,indent=2)+'\n')
    print('QA20_TWELVE_REAL_NATIVE_UNMODIFIED_ROUTES_PASS',shard)

if __name__=='__main__':
    need(len(sys.argv)==4,'arguments: SHARD OUTPUT_DIR QA18_JSON')
    main(int(sys.argv[1]),sys.argv[2],sys.argv[3])
