#!/usr/bin/env python3
"""Independent QA22 finite Native counterfactual-output receipt auditor."""
import argparse,copy,hashlib,json
from pathlib import Path
PIN='560d6aa5807a7f766213a33835cce85eab0fa40c'
SPECS=[(10,44,'>','invalid18',1503),(150,20,'x','invalid18',1185),
 (175,38,'x','invalid18',1502),(179,44,'@','invalid18',1672),
 (235,11,'x','invalid14',9891),(396,17,'x','invalid07',1065)]
STEPS={'invalid18':1672,'invalid14':10061,'invalid07':1235}
def need(v,s):
    if not v:raise AssertionError(s)
def verify(w,prev,r):
    need(w['schema']=='qa21-native-six-original-natural-execution-witnesses-v1'
         and w['source_git_blob']==PIN and w['original_native_run']==39761821210
         and w['stage1_complete'] is False,'wrong original Native source witness')
    need(prev['schema']=='qa21-six-input-reachable-source-ops-native-z-intervention-v1'
         and prev['source_git_blob']==PIN and prev['stage1_complete'] is False,'wrong original QA21 Native acceptance')
    need(r.get('schema')=='qa22-six-input-origin-rejection-continuations-v1'
         and r.get('source_git_blob')==PIN and r.get('per_mutant_extra_step_cap')==125000
         and r.get('new_native_program_instances')==12
         and r.get('production_source_modified') is False
         and r.get('forced_ip_relocation') is False
         and r.get('global_dead_code_proof') is False
         and r.get('stage1_complete') is False,
         'QA22 overclaimed, changed source or missed Native scope')
    need(len(r['records'])==len(w['entries'])==len(prev['records'])==6,'missing original six Native cases')
    out=[]
    for (x,y,op,lab,tick),p,q,z in zip(SPECS,w['entries'],prev['records'],r['records']):
        need(p['target']==q['target']==z['target']==[x,y] and
             p['opcode']==q['opcode']==z['opcode']==op and
             p['original_case']==q['original_case']==z['original_case']==lab and
             p['first_tick']==q['original_tick']==z['original_tick']==tick and
             p['prefix_sha256']==q['original_prefix_sha256']==z['original_prefix_sha256'] and
             p['original_gzip_sha256']==q['original_trace_sha256']==z['original_trace_sha256'],
             'QA22 changed immutable source-case, prefix or reached opcode')
        need(z['before_native']==q['before_native'] and
             z['normal_after_one_native_step']==q['normal_after_one_native_step'] and
             z['test_only_z_after_one_native_step']==q['test_only_z_after_one_native_step'] and
             z['one_step_native_state_differs'] is True,
             'QA22 did not independently reproduce exact QA21 counterfactual')
        need(z['normal_full_steps']==STEPS[lab] and z['normal_full_output']==['-1']*7
             and z['prefix_state_identical'] is True and
             z['natural_unmodified_prefix_reached'] is True and
             z['ip_relocated'] is False and z['only_mutant_live_funge_space_changed'] is True
             and z['full_numeric_necessity_proven'] is False,
             'QA22 original Native rejection not revalidated or numeric proof overclaimed')
        n=z['post_intervention_steps']
        need(type(n) is int and 0<=n<=125000,'QA22 Native continuation step cap violated')
        done=z['mutant_terminated'];need(type(done) is bool and z['bounded_unresolved'] is (not done),
             'Native termination vs unresolved falsely classified')
        if done:
            need(isinstance(z['mutant_full_output'],list) and
                 z['mutant_full_output']==z['mutant_output_so_far'],
                 'Native full mutant output not recorded')
        else:
            need(z['mutant_full_output']=='CAP_UNRESOLVED' and n==125000,
                 'bounded execution misreported as complete')
        out.append({'target':[x,y],'terminated':done,'post_steps':n,
                    'mutant_full_output':z['mutant_full_output']})
    return out
def main():
    p=argparse.ArgumentParser()
    for x in ('witness','qa21','qa22','output'):p.add_argument('--'+x)
    p.add_argument('--selftest',action='store_true');a=p.parse_args()
    if a.selftest:
        print('QA22_AUDITOR_SELFTEST_READY_NO_NATIVE_PASS_CLAIM');return
    src=Path('src/interleaved_work_counts.b98').read_bytes()
    need(hashlib.sha1(b'blob '+str(len(src)).encode()+b'\0'+src).hexdigest()==PIN,'production source modified')
    w=json.loads(Path(a.witness).read_text());prev=json.loads(Path(a.qa21).read_text());r=json.loads(Path(a.qa22).read_text())
    result=verify(w,prev,r)
    attacks=[('source',lambda z:z.__setitem__('source_git_blob','0'*40)),
      ('stage',lambda z:z.__setitem__('stage1_complete',True)),
      ('forced_ip',lambda z:z.__setitem__('forced_ip_relocation',True)),
      ('no_case',lambda z:z['records'].pop()),
      ('fake_finished',lambda z:z['records'][0].__setitem__('mutant_terminated',not z['records'][0]['mutant_terminated'])),
      ('fake_caps',lambda z:z['records'][1].__setitem__('post_intervention_steps',200000)),
      ('fake_prefix',lambda z:z['records'][2].__setitem__('original_prefix_sha256','0'*64)),
      ('fake_output',lambda z:z['records'][3].__setitem__('normal_full_output',['0']*7))]
    for label,fn in attacks:
        fake=copy.deepcopy(r);fn(fake)
        try:verify(w,prev,fake)
        except (AssertionError,KeyError,IndexError):pass
        else:raise AssertionError('synthetic forged receipt accepted '+label)
    out={'schema':'qa22-bounded-native-output-followthrough-audit-v1',
      'source_git_blob':PIN,'tested_cases':result,'forgeries_rejected':[t[0] for t in attacks],
      'stage1_complete':False,'numeric_necessity_globally_proven':False}
    Path(a.output).write_text(json.dumps(out,sort_keys=True,indent=2)+'\n')
    print('QA22_SIX_NATIVE_FULL_OR_BOUNDED_MUTANT_EXECUTIONS_INDEPENDENTLY_AUDITED',result)
    print('QA22_EIGHT_FORGED_CONTINUATION_REPORTS_REJECTED')
    print('QA22_BOUNDED_CASES_UNRESOLVED_NOT_GLOBAL_DEAD_CODE_OR_STAGE1')
if __name__=='__main__':main()
