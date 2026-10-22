#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA21: Native Befunge 98 test-only local-cell mutation on six NATURALLY reached opcodes.
Never relocate the IP or edit the on-disk production source.
"""
from __future__ import print_function
import hashlib,json,os,sys,StringIO
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
from funge.exception import IPStopped,IPQuitted
PIN='560d6aa5807a7f766213a33835cce85eab0fa40c'
MAX_STEPS=175000

def need(v,why):
    if not v:raise AssertionError(why)
def blob(data):return hashlib.sha1('blob %d\0'%len(data)+data).hexdigest()
def make(source,raw):
    sin=StringIO.StringIO(raw);out=StringIO.StringIO()
    platform=BufferedPlatform([],{},stdin=sin,stdout=out)
    program=Program(Befunge98,platform=platform)
    program.load_code(source);program.create_ip()
    need(len(program.ips)==1,'Native original IP missing')
    return {'program':program,'stdout':out,'steps':0}
def state(p):
    ips=p['program'].ips
    if not ips:return {'alive':False}
    ip=ips[0]
    return {'alive':True,'pos':list(map(int,ip.position)),
            'delta':list(map(int,ip.delta)),
            'stringmode':bool(ip.stringmode),
            'stacks':[[str(z) for z in stk] for stk in ip.stack]}
def tick(p):
    prog=p['program']
    need(len(prog.ips)==1,'unexpected additional Native IP')
    ip=prog.ips[0]
    try:prog.execute_step()
    except IPStopped:prog.remove_ip(ip)
    except IPQuitted:
        for now in list(prog.ips):prog.remove_ip(now)
    p['steps']+=1
    need(p['steps']<=MAX_STEPS,'Native QA21 unexpectedly exceeded 50000-step scope')
def replay_to_prefix(source,entry):
    p=make(source,entry['input']);hasher=hashlib.sha256()
    for step in range(1,entry['first_tick']):
        need(p['program'].ips,'native input process exited before original source witness')
        ip=p['program'].ips[0];x,y=map(int,ip.position);dx,dy=map(int,ip.delta)
        op=int(p['program'].space.get(ip.position))
        line='%d\t%d\t%d\t%d\t%d\t%d\t%d\n'%(step,x,y,dx,dy,op,int(ip.stringmode))
        hasher.update(line)
        tick(p)
    need(hasher.hexdigest()==entry['prefix_sha256'],
         'Native prefix does not reproduce original raw QA20 trace exactly')
    ip=p['program'].ips[0]
    x,y=map(int,ip.position);dx,dy=map(int,ip.delta)
    op=int(p['program'].space.get(ip.position))
    need([entry['first_tick'],x,y,dx,dy,op,int(ip.stringmode)]==entry['recorded_step'],
         'actual Native target tick/coordinate/source byte diverged')
    need((x,y)==tuple(entry['target']) and op==ord(entry['opcode']) and not ip.stringmode,
         'candidate is not naturally executable in unmodified Native program')
    return p

def experiment(source,e):
    # Two entirely new Native Program instances, with identical original input
    # and identical frozen-prefix IP histories. Only one disposable Space gets z.
    orig=replay_to_prefix(source,e)
    control_pre=state(orig)
    tick(orig)
    native_after=state(orig)
    while orig['program'].ips:tick(orig)
    need(orig['stdout'].getvalue().split()==['-1']*7,
         'original BF98 invalid-input output unexpectedly changed')
    control_steps=orig['steps']

    mutant=replay_to_prefix(source,e)
    need(state(mutant)==control_pre,'native counterfactual prefix state differs from original')
    ip=mutant['program'].ips[0]
    before=int(mutant['program'].space.get(ip.position))
    need(before==ord(e['opcode']),'unexpected byte before test-only mutation')
    mutant['program'].space.put(ip.position,ord('z'))
    need(int(mutant['program'].space.get(ip.position))==ord('z'),
         'temporary Native Space mutation failed')
    tick(mutant)
    mutant_after=state(mutant)
    consequence=native_after!=mutant_after
    after_steps=0
    while mutant['program'].ips and after_steps<125000:
        tick(mutant)
        after_steps+=1
    terminated=not bool(mutant['program'].ips)
    mutated_output=mutant['stdout'].getvalue().split()
    return {'target':e['target'],'opcode':e['opcode'],'original_case':e['original_case'],
      'input':e['input'],'original_trace_sha256':e['original_gzip_sha256'],
      'original_tick':e['first_tick'],'original_prefix_sha256':e['prefix_sha256'],
      'prefix_state_identical':True,'before_native':control_pre,
      'normal_after_one_native_step':native_after,
      'test_only_z_after_one_native_step':mutant_after,
      'one_step_native_state_differs':consequence,
      'normal_full_output':['-1']*7,'normal_full_steps':control_steps,
      'mutant_full_output':mutated_output if terminated else 'CAP_UNRESOLVED',
      'mutant_terminated':terminated,'post_intervention_steps':after_steps,
      'mutant_output_so_far':mutated_output,'bounded_unresolved':not terminated,'full_numeric_necessity_proven':False,
      'natural_unmodified_prefix_reached':True,'ip_relocated':False,
      'only_mutant_live_funge_space_changed':True}

def main(wfile,outdir):
    source=open('src/interleaved_work_counts.b98','rb').read()
    need(blob(source)==PIN,'production source blob changed')
    w=json.load(open(wfile,'rb'))
    need(w['schema']=='qa21-native-six-original-natural-execution-witnesses-v1' and
         w['source_git_blob']==PIN and len(w['entries'])==6 and
         w['stage1_complete'] is False,'witness manifest identity corrupt')
    rows=[]
    for e in w['entries']:
        r=experiment(source,e);rows.append(r)
        print('QA21_REAL_NATIVE_NATURAL_INPUT_ONE_STEP_INTERVENTION',e['target'],
              e['opcode'],'changed',r['one_step_native_state_differs'],
              'steps',r['normal_full_steps'])
        sys.stdout.flush()
    out={'schema':'qa22-six-input-origin-rejection-continuations-v1',
         'source_git_blob':PIN,'new_native_program_instances':12,
         'original_cases':6,'natural_prefixes_verified':6,
         'test_mutations_only_after_natural_opcode_reach':True,
         'production_source_modified':False,
         'forced_ip_relocation':False,
         'global_dead_code_proof':False,
         'stage1_complete':False,'per_mutant_extra_step_cap':125000,'records':rows}
    with open(os.path.join(outdir,'qa22_native_continuations.json'),'wb') as f:
        f.write(json.dumps(out,sort_keys=True,indent=2)+'\n')
    print('QA22_SIX_REAL_NATIVE_MUTANTS_CONTINUED_TO_TERMINATION_OR_EXPLICIT_CAP')
    print('QA21_NOT_GLOBAL_NUMERIC_NECESSITY_OR_STAGE1_ACCEPTANCE')
if __name__=='__main__':
    need(len(sys.argv)==3,'usage: SCRIPT QA20_FROZEN_WITNESS.json OUTPUT_DIR')
    main(sys.argv[1],sys.argv[2])