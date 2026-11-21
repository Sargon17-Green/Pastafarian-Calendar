#!/usr/bin/env python3
"""QA21 strict receipt verifier for original input-reachable source opcodes.
Verify finite one-step effects; never infer numeric necessity or global Stage1.
"""
import argparse,copy,json,hashlib
from pathlib import Path
PIN='560d6aa5807a7f766213a33835cce85eab0fa40c'
SPECS=[(10,44,'>', 'invalid18',1503), (150,20,'x','invalid18',1185),
       (175,38,'x','invalid18',1502), (179,44,'@','invalid18',1672),
       (235,11,'x','invalid14',9891),(396,17,'x','invalid07',1065)]
STEPS={'invalid18':1672,'invalid14':10061,'invalid07':1235}
def need(x,msg):
    if not x:raise AssertionError(msg)
def verify(w,r):
    need(w.get('schema')=='qa21-native-six-original-natural-execution-witnesses-v1'
         and w.get('source_git_blob')==PIN and w.get('original_native_run')==39761821210
         and w.get('qa20_tested_commit')=='d0a1c686c4f9244121246aa5b70266c072c3ddce'
         and w.get('normal_case_count')==6 and w.get('stage1_complete') is False,
         'invalid or spoofed original source witness header')
    need(r.get('schema')=='qa21-six-input-reachable-source-ops-native-z-intervention-v1'
         and r.get('source_git_blob')==PIN and r.get('new_native_program_instances')==12
         and r.get('original_cases')==6 and r.get('natural_prefixes_verified')==6
         and r.get('test_mutations_only_after_natural_opcode_reach') is True
         and r.get('production_source_modified') is False
         and r.get('forced_ip_relocation') is False
         and r.get('global_dead_code_proof') is False and r.get('stage1_complete') is False,
         'Native result claims forbidden scope or wrong source')
    we=w.get('entries');rr=r.get('records')
    need(type(we) is list and type(rr) is list and len(we)==len(rr)==6,'six signed scenarios absent')
    different=0
    for spec,e,row in zip(SPECS,we,rr):
        x,y,op,lab,tick=spec
        need(e.get('target')==[x,y] and e.get('opcode')==op and
             e.get('original_case')==lab and e.get('first_tick')==tick and
             e.get('original_full_steps')==STEPS[lab] and
             e.get('recorded_step',[0])[0]==tick and
             e['recorded_step'][1:3]==[x,y] and
             e['recorded_step'][5:]==[ord(op),0],
             'frozen Native STEP witness mismatch')
        for field in ('target','opcode','input','original_case'):
            target_field='original_case' if field=='original_case' else field
            need(row.get(target_field)==e.get(field),'Native counterfactual not bound to exact input')
        need(row.get('original_tick')==tick and
             row.get('original_trace_sha256')==e.get('original_gzip_sha256') and
             row.get('original_prefix_sha256')==e.get('prefix_sha256') and
             row.get('normal_full_steps')==STEPS[lab] and
             row.get('normal_full_output')==['-1']*7,
             'Native original prefix/full rejection not reproducible')
        need(row.get('natural_unmodified_prefix_reached') is True and
             row.get('prefix_state_identical') is True and
             row.get('ip_relocated') is False and
             row.get('only_mutant_live_funge_space_changed') is True and
             row.get('full_numeric_necessity_proven') is False and
             row.get('mutant_full_output')=='NOT_EXECUTED',
             'Native receipt overclaims semantics or mutated production')
        pre=row.get('before_native');native=row.get('normal_after_one_native_step')
        alter=row.get('test_only_z_after_one_native_step')
        need(type(pre) is dict and type(native) is dict and type(alter) is dict,
             'Native actual one-step states absent')
        need(pre.get('alive') is True and pre.get('pos')==[x,y] and
             pre.get('stringmode') is False,
             'Native unmodified IP not at original source opcode')
        isdifferent=native!=alter
        need(row.get('one_step_native_state_differs') is isdifferent,
             'counterfactual one-step semantic effect misreported')
        if isdifferent:different+=1
    return {'input_origin_cases':6,'original_full_native_rejections':6,
            'mutated_only_temporary_funge_space':6,'immediate_native_state_differences':different,
            'numeric_necessity_claimed':False,'global_stage1_complete':False}
def main():
    p=argparse.ArgumentParser();p.add_argument('--witness');p.add_argument('--native');p.add_argument('--output');p.add_argument('--selftest',action='store_true');a=p.parse_args()
    if a.selftest:
        print('QA21_INDEPENDENT_AUDITOR_LOADS_WITHOUT_NATIVE_ASSERTIONS')
        return
    w=json.loads(Path(a.witness).read_text());r=json.loads(Path(a.native).read_text())
    metrics=verify(w,r)
    attacks=[('fake-final',lambda c:c.__setitem__('stage1_complete',True)),
             ('fake-reachability',lambda c:c.__setitem__('forced_ip_relocation',True)),
             ('source-edit',lambda c:c.__setitem__('production_source_modified',True)),
             ('one-missing',lambda c:c['records'].pop()),
             ('fake-causality',lambda c:c['records'][0].__setitem__('one_step_native_state_differs',not c['records'][0]['one_step_native_state_differs'])),
             ('forged-invalid-output',lambda c:c['records'][0].__setitem__('normal_full_output',['-1']*6+['0'])),
             ('fake-prestate',lambda c:c['records'][1]['before_native'].__setitem__('pos',[0,0])),
             ('overclaim-number',lambda c:c['records'][2].__setitem__('full_numeric_necessity_proven',True))]
    for label,mutation in attacks:
        fake=copy.deepcopy(r);mutation(fake)
        try:verify(w,fake)
        except (AssertionError,KeyError,IndexError):pass
        else:raise AssertionError('forged causal report accepted: '+label)
    result={'schema':'qa21-original-natural-opcode-native-causal-audit-v1',
            'source_git_blob':PIN,'original_qa20_run':39761821210,
            'tested_native':metrics,'forgeries_rejected':[x[0] for x in attacks],
            'stage1_complete':False,'normal_input_numeric_necessity_unproved':True}
    Path(a.output).write_text(json.dumps(result,sort_keys=True,indent=2)+'\n')
    print('QA21_SIX_NATIVE_INPUT_ORIGIN_CAUSAL_TEST_RECEIPTS_AUDITED',metrics)
    print('QA21_EIGHT_FORGED_REPORTS_REJECTED')
    print('QA21_NO_NUMERIC_NECESSITY_OR_STAGE1_ACCEPTANCE')
if __name__=='__main__':main()