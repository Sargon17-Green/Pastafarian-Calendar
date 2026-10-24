#!/usr/bin/env python3
"""QA23A: independently audit already executed Native QA22 append-only stdout.
No new Native execution; unresolved cases remain bounded/unknown.
"""
import copy, hashlib, json, sys
from pathlib import Path
PIN='560d6aa5807a7f766213a33835cce85eab0fa40c'
COORDS=((10,44),(150,20),(175,38),(179,44),(235,11),(396,17))
def need(value,message):
    if not value: raise AssertionError(message)
def check(doc):
    need(doc.get('schema')=='qa22-six-input-origin-rejection-continuations-v1' and
         doc.get('source_git_blob')==PIN and
         doc.get('per_mutant_extra_step_cap')==125000 and
         doc.get('stage1_complete') is False and
         doc.get('production_source_modified') is False, 'receipt source and scope forged')
    rows=doc.get('records')
    need(type(rows) is list and len(rows)==6,'missing original six native controls')
    result=[]
    for coord,row in zip(COORDS,rows):
        need(tuple(row.get('target',()))==coord,'candidate order or identity forged')
        done=row.get('mutant_terminated')
        need(type(done) is bool,'termination unknown or fabricated')
        n=row.get('post_intervention_steps')
        need(type(n) is int and 0<=n<=125000,'invalid Native bound')
        if not done:need(n==125000 and row.get('bounded_unresolved') is True,'unresolved Native state forged')
        else:need(row.get('bounded_unresolved') is False,'Native completion contradictory')
        observed=row.get('mutant_output_so_far')
        need(type(observed) is list and all(type(t) is str for t in observed),
             'native stdout tokens missing')
        if done:need(row.get('mutant_full_output')==observed,'final stdout not preserved')
        else:need(row.get('mutant_full_output')=='CAP_UNRESOLVED','unfinished Native output overclaimed')
        expect=['-1']*7
        prefix=observed==expect[:len(observed)] and len(observed)<=7
        result.append({'target':list(coord),'terminated':done,'emitted_tokens':len(observed),
                       'irreversible_stdout_divergence':not prefix,
                       'full_equivalence_proved':done and observed==expect,
                       'bounded_unresolved':not done,'no_infinite_loop_proof':True})
    need(result[1]['full_equivalence_proved'] and result[2]['full_equivalence_proved'],
         'two completed same-output controls changed')
    need(result[3]['irreversible_stdout_divergence'] and
         result[3]['emitted_tokens']>7 and not result[3]['terminated'],
         'source @ append-only output divergence not witnessed')
    return result
def main(input_path,out_path):
    raw=Path(input_path).read_bytes()
    need(hashlib.sha256(raw).hexdigest()=='ff85b07dab957de7a97ac32d917ed72f458a0a1ef1827b2744be176debf9d554','original Native receipt hash drifted')
    d=json.loads(raw)
    v=check(d)
    attacks=[
      ('false-completion',lambda c:c['records'][0].__setitem__('mutant_terminated',True)),
      ('extra-stage',lambda c:c.__setitem__('stage1_complete',True)),
      ('source-edit',lambda c:c.__setitem__('source_git_blob','0'*40)),
      ('missing-case',lambda c:c['records'].pop()),
      ('rewrite-stdout',lambda c:c['records'][3].__setitem__('mutant_output_so_far',[])),
      ('reorder-target',lambda c:c['records'][0].__setitem__('target',[0,0])),
      ('fake-final',lambda c:c['records'][2].__setitem__('mutant_full_output',[])),
      ('fake-bound',lambda c:c['records'][4].__setitem__('post_intervention_steps',125001))]
    for name,mutation in attacks:
        x=copy.deepcopy(d);mutation(x)
        try:check(x)
        except (AssertionError,IndexError,KeyError):pass
        else:raise AssertionError('forged Native stdout receipt accepted: '+name)
    result={'schema':'qa23a-real-native-streaming-receipt-audit-v1',
            'source_git_blob':PIN,'native_origin_run':39774061424,
            'new_native_runs':0,'original_native_cases':6,
            'original_receipt_sha256':hashlib.sha256(raw).hexdigest(),
            'forgeries_rejected':[a[0] for a in attacks],
            'finite_classifications':v,'stage1_complete':False}
    Path(out_path).write_text(json.dumps(result,sort_keys=True,indent=2)+'\n')
    print('QA23A_SIX_ORIGINAL_NATIVE_STDOUT_PREFIXES_REAUDITED',len(v))
    print('QA23A_EIGHT_FORGED_REPORTS_REJECTED')
    print('QA23A_NO_INFINITE_LOOP_OR_STAGE1_ACCEPTANCE')
if __name__=='__main__':
    need(len(sys.argv)==3,'required: original-QA22-Native-report output')
    main(sys.argv[1],sys.argv[2])
