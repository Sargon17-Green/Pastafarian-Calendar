#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA19: real PyFunge-98 one-cell forced-IP counterfactuals.
Deliberately displaced IP is NOT a normal input-reachable path.
"""
from __future__ import print_function
import hashlib,json,os,subprocess,sys,StringIO
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_live_pair_matrix as base

PIN='560d6aa5807a7f766213a33835cce85eab0fa40c'
SOURCE='src/interleaved_work_counts.b98'
CLI=['timeout','--kill-after=2s','55s','pyfunge','--disable-fprint',
     '--no-concurrent','--no-filesystem','-v98','-d2']
MAX_STEPS=160000
def need(value,msg):
    if not value:raise AssertionError(msg)
def blob(data):
    return hashlib.sha1('blob %d\0%s'%(len(data),data)).hexdigest()
def input_for(fields):
    need(len(fields)==4 and all(type(x) in (int,long) for x in fields),'native signed four-field input invalid')
    return ' '.join(str(x) for x in fields)+'\n'
def make(source,raw):
    sin=StringIO.StringIO(raw);sout=StringIO.StringIO()
    platform=BufferedPlatform([],{},stdin=sin,stdout=sout)
    p=Program(Befunge98,platform=platform)
    p.load_code(source);p.create_ip()
    need(len(p.ips)==1,'Native fresh IP missing')
    return dict(program=p,stdin=sin,stdout=sout,point=p.ips[0].position.__class__,steps=0)
def native_ref(path,raw):
    p=subprocess.Popen(CLI+[path],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    out,err=p.communicate(raw)
    need(p.returncode==0,'independent Native BF98 reference failed: %s %r'%(path,err[-150:]))
    return out.split()
def reference(fields):
    c,t=fields[:2],fields[2:]
    out=native_ref('reference/work_counts.b98',input_for(fields))
    out+=native_ref('reference/save.b98','%d %d\n'%tuple(c))
    out+=native_ref('reference/save.b98','%d %d\n'%tuple(t))
    need(len(out)==7,'three independent BF98 references failed')
    return out
def state(ip):
    return {'position':list(map(int,ip.position)),
            'delta':list(map(int,ip.delta)),
            'stringmode':bool(ip.stringmode),
            'stack_depth':len(ip.stack[0]),
            'stack_tail':list(map(int,ip.stack[0][-4:]))}
def to_candidate(source,raw,entry):
    item=make(source,raw);p=item['program']
    wanted={int(c['tick']):c for c in entry['candidates']}
    need(wanted,'empty immutable native witness set')
    maximum=max(wanted)
    while item['steps']<maximum and p.ips:
        next_tick=item['steps']+1
        if next_tick in wanted:
            c=wanted[next_tick];ip=p.ips[0]
            need(tuple(map(int,ip.position))==tuple(c['neighbor']) and
                 tuple(map(int,ip.delta))==tuple(c['delta']) and
                 int(p.space.get(ip.position))==c['source_byte'],
                 'native source trace witness cannot replay exactly at tick %d'%next_tick)
            if not ip.stringmode:
                need(abs(int(ip.position[0])-int(entry['target'][0]))+
                     abs(int(ip.position[1])-int(entry['target'][1]))==1,
                     'claimed forced displacement not exactly one cell')
                return item,c
        base.tick(item)
        need(item['steps']<=MAX_STEPS,'witness replay exceeded Native bound')
    raise AssertionError('No actual non-stringmode native neighboring instruction has two stack values: '+str(entry['target']))
def to_tick(source,raw,c):
    item=make(source,raw)
    while item['steps']<c['tick']-1:
        need(item['program'].ips,'native replay died before frozen witness')
        base.tick(item)
        need(item['steps']<=MAX_STEPS,'prefix replay exceeded bound')
    ip=item['program'].ips[0]
    need(tuple(map(int,ip.position))==tuple(c['neighbor']) and
         tuple(map(int,ip.delta))==tuple(c['delta']) and
         int(item['program'].space.get(ip.position))==c['source_byte'] and
         not ip.stringmode,
         'Native prefix diverged for controlled experiment')
    return item
def run_mode(source,raw,c,target,mode):
    item=to_tick(source,raw,c)
    p=item['program'];ip=p.ips[0]
    original=state(ip)
    pt=item['point'](tuple(target))
    need(int(p.space.get(pt))==ord('x'),'source-original x was not present in live Funge-space')
    if mode=='original_path':
        while p.ips:
            base.tick(item)
            need(item['steps']<=MAX_STEPS,'original unaffected Native baseline exceeded bound')
        return {'mode':mode,'prefix':original,'native_output':item['stdout'].getvalue().split(),
                'normal_termination':True,'steps':item['steps']}
    need(mode in ('redirect_x','redirect_z'),'unknown experiment mode')
    ip.position=pt # precise one-cell displacement from a genuine executed neighbor
    if mode=='redirect_z':
        p.space.put(pt,ord('z')) # sole disposable, NON-PRODUCTION neutral-opcode mutation
    opcode=int(p.space.get(ip.position))
    need(opcode==ord('x' if mode=='redirect_x' else 'z'),
         'physical experiment opcode unexpectedly modified')
    before=state(ip)
    need(before['stringmode'] is False,'target glyph would be inert in stringmode')
    base.tick(item) # exactly ONE actual Native PyFunge opcode execution
    need(p.ips,'native target opcode terminated unexpectedly')
    return {'mode':mode,'prefix':original,'target_before_step':before,
            'target_opcode':opcode,'native_step_completed':True,
            'after_one_step':state(p.ips[0]),
            'stdout_one_step':item['stdout'].getvalue()}
def main(witnessfile,outdir):
    need(os.path.isdir(outdir),'QA19 receipt directory not mounted')
    source=open(SOURCE,'rb').read()
    need(blob(source)==PIN==base.PIN,'QA19 signed production source blob changed')
    data=json.load(open(witnessfile,'rb'))
    need(data['schema']=='qa19-one-cell-native-execution-witness-v1' and
         data['source_git_blob']==PIN and len(data['entries'])==3,
         'QA19 witness ledger missing or altered')
    records=[]
    for e in data['entries']:
        target=e['target'];raw=input_for(e['fields'])
        _,c=to_candidate(source,raw,e)
        actual=run_mode(source,raw,c,target,'original_path')
        expected=reference(e['fields'])
        need(actual['native_output']==expected,'unmodified Native baseline differs from three independent Befunge oracles')
        intervention=run_mode(source,raw,c,target,'redirect_x')
        inert=run_mode(source,raw,c,target,'redirect_z')
        need(intervention['prefix']==inert['prefix']==actual['prefix'],
             'counterfactual native prefixes were not identical')
        xout=intervention['after_one_step'];zout=inert['after_one_step']
        different=(xout['delta']!=zout['delta'] or
                   xout['stack_depth']!=zout['stack_depth'] or
                   xout['stack_tail']!=zout['stack_tail'])
        need(different,'real x at forced source cell had no immediate effect against inert z')
        records.append({'target':target,'case':e['case'],'fields':e['fields'],
                        'original_trace_sha256':e['trace_sha256'],
                        'selected_tick':c['tick'],'original_neighbor':c['neighbor'],
                        'displacement_l1':1,'source_byte':120,
                        'native_prefix_stack_depth':c['depth'],
                        'implicit_zero_operand_underflow':(c['depth']<2),
                        'unmodified_baseline':actual,
                        'counterfactual_executed_x':intervention,
                        'counterfactual_executed_z':inert,
                        'immediate_x_vs_z_native_state_difference':different,
                        'natural_reachability_proven':False})
        print('QA19_NATIVE_FORCED_ONE_CELL_X_EXECUTED_VS_Z_PASS',
              target,e['case'],'prefix_tick',c['tick'],
              'x_delta',xout['delta'],'z_delta',zout['delta'])
        sys.stdout.flush()
    report={'schema':'qa19-native-forced-2d-x-execution-v1',
            'production_git_blob':PIN,'candidate_count':len(records),
            'fresh_independent_native_reference_invocations':9,
            'native_program_instance_invocations':len(records)*4,
            'source_modified':False,'normal_reachability_proven':False,
            'natural_dead_code_status':'UNDETERMINED',
            'stage1_complete':False,'records':records}
    f=os.path.join(outdir,'qa19_native_forced_x.json')
    with open(f,'wb') as s:s.write(json.dumps(report,sort_keys=True,indent=2)+'\n')
    print('QA19_THREE_NATIVE_X_COUNTERFACTUALS_FINITE_PASS')
    print('QA19_FORCED_REACH_IS_NOT_NATURAL_REACHABILITY_OR_STAGE1')
if __name__=='__main__':
    need(len(sys.argv)==3,'usage: SCRIPT WITNESSES_JSON OUTPUT_DIR')
    main(sys.argv[1],sys.argv[2])
