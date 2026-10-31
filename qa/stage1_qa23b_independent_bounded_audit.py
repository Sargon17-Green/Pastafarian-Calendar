#!/usr/bin/env python3
"""QA23B independent audit: finite real Native continuations, no global claims."""
import copy
import hashlib
import json
import sys
from pathlib import Path

SOURCE='560d6aa5807a7f766213a33835cce85eab0fa40c'
QA22_HASH='ff85b07dab957de7a97ac32d917ed72f458a0a1ef1827b2744be176debf9d554'
TARGETS=((10,44),(179,44),(235,11),(396,17))
EXPECTED=('>','@','x','x')
ORIGINAL_CAP=125000
NEW_CAP=500000

def need(check,why):
    if not check: raise AssertionError(why)

def prefix_compatible(tokens):
    return len(tokens)<=7 and tokens == ['-1']*len(tokens)

def old_tokens_are_prefix(old,new):
    if not old: return True
    if len(new)<len(old): return False
    return new[:len(old)-1] == old[:-1] and new[len(old)-1].startswith(old[-1])

def verify(qa22,result):
    need(result.get('schema')=='qa23b-four-native-post-qa22-bounded-continuations-v1'
         and result.get('source_git_blob')==SOURCE
         and result.get('original_qa22_receipt_sha256')==QA22_HASH
         and result.get('original_qa22_run')==39774061424
         and result.get('original_qa22_step_cap')==ORIGINAL_CAP
         and result.get('new_post_intervention_step_cap')==NEW_CAP
         and result.get('four_expected_records')==4
         and result.get('new_native_programs')==4
         and result.get('no_ip_relocation') is True
         and result.get('production_source_modified') is False
         and result.get('stage1_complete') is False
         and result.get('no_infinite_loop_claim') is True
         and result.get('global_dead_code_proof') is False,
         'QA23B header altered, missing a Native case, or makes unsupported claim')
    need(qa22.get('schema')=='qa22-six-input-origin-rejection-continuations-v1'
         and qa22.get('source_git_blob')==SOURCE and len(qa22['records'])==6,
         'original QA22 predecessor missing')
    old={tuple(z['target']):z for z in qa22['records']}
    rows=result.get('records')
    need(type(rows) is list and len(rows)==4,'four exact counterfactual receipts required')
    report=[]
    for i,(coord,op,row) in enumerate(zip(TARGETS,EXPECTED,rows)):
        q=old[coord]
        need(tuple(row.get('target',()))==coord and row.get('opcode')==op
             and row.get('original_case')==q['original_case']
             and row.get('first_tick')==q['original_tick']
             and row.get('prefix_sha256')==q['original_prefix_sha256']
             and row.get('qa22_mutant_after_one_step')==q['test_only_z_after_one_native_step'],
             'original Native opcode, source input or execution prefix changed')
        need(q['bounded_unresolved'] is True and q['mutant_terminated'] is False
             and q['post_intervention_steps']==ORIGINAL_CAP
             and row.get('qa22_125000_post_steps_replayed') is True
             and row.get('qa22_125000_stdout_tokens')==q['mutant_output_so_far']
             and row.get('new_native_programs')==1
             and row.get('source_modified') is False and row.get('ip_relocated') is False
             and row.get('infinite_loop_proven') is False and row.get('global_necessity_proven') is False,
             'original QA22 boundary replay was not faithfully witnessed')
        extra=row.get('more_native_steps')
        n=row.get('total_post_intervention_steps')
        need(type(extra) is int and 0<=extra<=NEW_CAP-ORIGINAL_CAP
             and type(n) is int and n==ORIGINAL_CAP+extra,
             'invalid additional Native step budget')
        done=row.get('mutant_terminated')
        tokens=row.get('mutant_stdout_tokens')
        need(type(done) is bool and type(tokens) is list
             and all(type(s) is str for s in tokens),
             'native completion or stdout record missing')
        need(old_tokens_are_prefix(q['mutant_output_so_far'],tokens),
             'Native captured stdout lost earlier existing tokens')
        need(done or n==NEW_CAP,
             'a live mutant was silently dropped before the explicit finite cap')
        compatible=prefix_compatible(tokens)
        diverged=not compatible
        expected=('TERMINATED_IDENTICAL' if done and tokens==['-1']*7
                  else 'TERMINATED_DIFFERENT' if done
                  else 'BOUND_IRREVERSIBLE_OUTPUT_DIVERGENCE' if diverged
                  else 'BOUND_UNRESOLVED_PREFIX_COMPATIBLE')
        need(row.get('stdout_prefix_compatible') is compatible
             and row.get('irreversible_stdout_divergence') is diverged
             and row.get('outcome')==expected,
             'Native stdout or completion classification inconsistent')
        milestones=row.get('milestones')
        need(type(milestones) is list
             and len(milestones)==extra//50000,
             'missing fixed-interval Native progress receipts')
        for j,point in enumerate(milestones):
            need(point.get('post_steps')==ORIGINAL_CAP+(j+1)*50000
                 and type(point.get('emitted_tokens')) is int
                 and 0<=point['emitted_tokens']<=len(tokens)
                 and type(point.get('stdout_prefix_compatible')) is bool,
                 'altered 50k-step progress boundary')
        report.append({'target':list(coord),'outcome':expected,
                       'actual_post_steps':n,'tokens':len(tokens),
                       'terminated':done,'irreversible_output_difference':diverged})
    return report

def main(original_path,new_path,audit_path):
    oldbytes=Path(original_path).read_bytes()
    need(hashlib.sha256(oldbytes).hexdigest()==QA22_HASH,
         'QA22 Native source artifact SHA-256 mismatch')
    old=json.loads(oldbytes)
    new=json.loads(Path(new_path).read_bytes())
    report=verify(old,new)
    tests=[
      ('missing-original',lambda d:d['records'].pop()),
      ('wrong-source',lambda d:d.__setitem__('source_git_blob','0'*40)),
      ('missing-native',lambda d:d.__setitem__('new_native_programs',3)),
      ('wrong-opcode',lambda d:d['records'][0].__setitem__('opcode','z')),
      ('wrong-first-step',lambda d:d['records'][1].__setitem__('first_tick',1)),
      ('replayed-stdout-forgery',lambda d:d['records'][1].__setitem__('qa22_125000_stdout_tokens',[])),
      ('hidden-steps',lambda d:d['records'][2].__setitem__('more_native_steps',500000)),
      ('false-termination',lambda d:d['records'][3].__setitem__('mutant_terminated',not d['records'][3]['mutant_terminated'])),
      ('fake-final-stdout',lambda d:d['records'][1].__setitem__('mutant_stdout_tokens',['-1']*7)),
      ('global-stage',lambda d:d.__setitem__('stage1_complete',True)),
      ('global-necessity',lambda d:d['records'][0].__setitem__('global_necessity_proven',True))]
    for name,mutate in tests:
        test=copy.deepcopy(new);mutate(test)
        try:verify(old,test)
        except (AssertionError,IndexError,KeyError,TypeError,ValueError):pass
        else:raise AssertionError('counterfeit QA23B receipt accepted: '+name)
    output={'schema':'qa23b-native-4-case-audit-v1',
            'source_git_blob':SOURCE,'qa22_receipt_sha256':QA22_HASH,
            'qa23b_receipt_sha256':hashlib.sha256(Path(new_path).read_bytes()).hexdigest(),
            'four_native_cases':report,
            'negative_controls_rejected':[x[0] for x in tests],
            'full_functional_qa_pass':False,
            'geometric_spaghetti_qa_pass':False,
            'infinite_loop_proven':False}
    Path(audit_path).write_text(json.dumps(output,indent=2,sort_keys=True)+'\n')
    print('QA23B_FOUR_NATIVE_BOUNDARIES_AND_OUTPUTS_VERIFIED',report)
    print('QA23B_ELEVEN_FORGED_RECEIPTS_REJECTED')
    print('QA23B_NO_INFINITE_LOOP_OR_GLOBAL_STAGE1_CERTIFICATE')

if __name__=='__main__':
    need(len(sys.argv)==4,'usage: QA23B_AUDIT.py original_qa22.json qa23b.json audit.json')
    main(sys.argv[1],sys.argv[2],sys.argv[3])
