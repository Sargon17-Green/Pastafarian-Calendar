#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""QA31G original PyFunge native EOF probe; no source/input/IP interventions."""
from __future__ import print_function
import os,sys,json,gzip,hashlib,StringIO,binascii
import stage1_qa20_native_input_route_scan as qa20
PIN='560d6aa5807a7f766213a33835cce85eab0fa40c'
CASES=[('empty',''),('digit','1'),('digit_space','1 ')]
CAP=7000
def need(test,msg):
    if not test: raise AssertionError(msg)
def sha(x): return hashlib.sha256(x).hexdigest()
def toss(ip):
    return [int(v) for v in ip.stack[-1]] if len(ip.stack) else []
class Observed(StringIO.StringIO):
    def __init__(self, raw):
        StringIO.StringIO.__init__(self,raw)
        self.t=0;self.ip=None;self.events=[]
    def record(self,method,start,chunk):
        need(self.ip is not None and self.t>0,'read outside native step')
        e={'t':self.t,'method':method,'start':start,'end':self.tell(),
           'hex':binascii.hexlify(chunk),'ip':list(map(int,self.ip.position)),
           'stack':toss(self.ip)}
        self.events.append(e);return chunk
    def read(self,*args):
        start=self.tell()
        return self.record('read',start,StringIO.StringIO.read(self,*args))
    def readline(self,*args):
        start=self.tell()
        return self.record('readline',start,StringIO.StringIO.readline(self,*args))
def run(src,folder,label,raw):
    stdin=Observed(raw); stdout=StringIO.StringIO()
    platform=qa20.BufferedPlatform([],{},stdin=stdin,stdout=stdout)
    p=qa20.Program(qa20.Befunge98,platform=platform)
    p.load_code(src);p.create_ip()
    need(len(p.ips)==1,'original IP count')
    item={'program':p,'steps':0}
    fname='qa31g_'+label+'.jsonl.gz'
    records=0; status='HALT';err=None
    f=gzip.open(os.path.join(folder,fname),'wb')
    try:
        while p.ips:
            if records>=CAP: status='STEP_LIMIT';break
            need(len(p.ips)==1,'unexpected concurrent native IP')
            ip=p.ips[0];t=records+1
            rec={'t':t,'ip':list(map(int,ip.position)),
                 'delta':list(map(int,ip.delta)),
                 'op':int(p.space.get(ip.position)),
                 'string':bool(ip.stringmode),'pre':toss(ip)}
            stdin.t=t;stdin.ip=ip;start=len(stdin.events)
            try:
                qa20.tick_qa20(item)
                rec['post']=toss(ip)
                rec['next']=list(map(int,ip.position)) if ip in p.ips else None
                rec['next_delta']=list(map(int,ip.delta)) if ip in p.ips else None
            except Exception as exc:
                err=type(exc).__name__+': '+str(exc)
                rec['post']=toss(ip);rec['error']=err
                status='RUNTIME_ERROR'
            rec['reads']=stdin.events[start:]
            f.write(json.dumps(rec,sort_keys=True,separators=(',',':'))+'\n')
            records+=1
            if err is not None:break
    finally:f.close()
    z=open(os.path.join(folder,fname),'rb').read()
    return {'label':label,'raw_hex':binascii.hexlify(raw),'raw_sha256':sha(raw),
            'trace':fname,'trace_sha256':sha(z),'steps':records,
            'reads':len(stdin.events),'status':status,'error':err,
            'output':stdout.getvalue().split()}
def main(folder):
    need(os.path.isdir(folder),'missing output directory')
    source=open(qa20.SOURCE,'rb').read()
    need(qa20.pin(source)==PIN==qa20.PIN,'original Git blob changed')
    result={'schema':'qa31g-original-native-eof-v1','source_blob':PIN,
            'source_modified':False,'ip_relocated':False,
            'native_expected_model_proven':False,'stage1_pass':False,
            'cases':[run(source,folder,label,raw) for label,raw in CASES]}
    with open(os.path.join(folder,'qa31g_receipt.json'),'wb') as f:
        f.write(json.dumps(result,sort_keys=True,indent=2)+'\n')
    for c in result['cases']:
        print('QA31G_NATIVE_OBSERVATION',c['label'],c['status'],c['steps'],c['reads'])
    print('QA31G_STAGE1_REMAINS_OPEN')
if __name__=='__main__':
    need(len(sys.argv)==2,'usage: native_probe output_folder')
    main(sys.argv[1])
