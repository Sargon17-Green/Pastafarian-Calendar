#!/usr/bin/env python3
"""Independent fail-closed finite audit of three one-cell Native BF98 interventions."""
import hashlib,json,sys
from pathlib import Path
PIN='560d6aa5807a7f766213a33835cce85eab0fa40c'
TARGETS=((150,20),(175,38),(396,17))
def need(v,msg):
    if not v:raise AssertionError(msg)
def verify(w,r):
    need(w.get('schema')=='qa19-one-cell-native-execution-witness-v1'
         and w.get('source_git_blob')==PIN and w.get('archive_original_run')==39108506703
         and w.get('stage1_complete') is False, 'original witness header invalid')
    need(r.get('schema')=='qa19-native-forced-2d-x-execution-v1'
         and r.get('production_git_blob')==PIN and r.get('candidate_count')==3
         and r.get('native_program_instance_invocations')==12
         and r.get('fresh_independent_native_reference_invocations')==9
         and r.get('source_modified') is False
         and r.get('normal_reachability_proven') is False
         and r.get('natural_dead_code_status')=='UNDETERMINED'
         and r.get('stage1_complete') is False,
         'Native evidence header or final-status invalid')
    need(len(w['entries'])==len(r['records'])==3,'missing native cases')
    for target,ref,row in zip(TARGETS,w['entries'],r['records']):
        need(tuple(ref['target'])==tuple(row['target'])==target
             and row['case']==ref['case'] and row['fields']==ref['fields']
             and row['original_trace_sha256']==ref['trace_sha256']
             and row['source_byte']==120 and row['displacement_l1']==1
             and abs(target[0]-row['original_neighbor'][0])
                 +abs(target[1]-row['original_neighbor'][1])==1,
             'input or one-cell displacement not tied to Native evidence')
        need(any(c['tick']==row['selected_tick'] and
                 c['neighbor']==row['original_neighbor'] and
                 c['trace_sha256']==row['original_trace_sha256']
                 for c in ref['candidates']),
             'neighbor did not originate in source-hashed Native trace')
        b=row['unmodified_baseline'];x=row['counterfactual_executed_x'];z=row['counterfactual_executed_z']
        need(b['mode']=='original_path' and b['normal_termination'] is True
             and b['steps']>row['selected_tick'] and len(b['native_output'])==7
             and all(isinstance(t,str) and t.lstrip('-').isdigit() for t in b['native_output']),
             'normal Native baseline or numeric reference invalid')
        need(x['mode']=='redirect_x' and z['mode']=='redirect_z'
             and x['target_opcode']==120 and z['target_opcode']==122
             and x['native_step_completed'] is True and z['native_step_completed'] is True
             and x['prefix']==z['prefix']==b['prefix']
             and x['target_before_step']==z['target_before_step']
             and x['target_before_step']['position']==list(target)
             and x['target_before_step']['stringmode'] is False,
             'counterfactual shared prefix or actual target opcode invalid')
        aa=x['after_one_step'];bb=z['after_one_step']
        need(row['immediate_x_vs_z_native_state_difference'] is True and
             (aa['delta']!=bb['delta'] or aa['stack_depth']!=bb['stack_depth']
              or aa['stack_tail']!=bb['stack_tail']),
             'real Native x did not differ from neutral execution')
        need(row['natural_reachability_proven'] is False,
             'forced input is not natural route proof')
    return True
def main(a,b,c):
    data=Path('src/interleaved_work_counts.b98').read_bytes()
    need(hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()==PIN,
         'source Git blob changed')
    w=json.loads(Path(a).read_text());r=json.loads(Path(b).read_text())
    verify(w,r)
    out={'schema':'qa19-finite-independent-witness-v1','cases':3,
         'native_x_effects':3,'natural_reachability_proven':False,
         'stage1_complete':False,'source_git_blob':PIN}
    Path(c).write_text(json.dumps(out,sort_keys=True,indent=2)+'\n')
    print('QA19_INDEPENDENT_THREE_ONE_CELL_NATIVE_WITNESSES_PASS')
    print('QA19_STAGE1_AND_NATURAL_REACHABILITY_STILL_OPEN')
if __name__=='__main__':
    need(len(sys.argv)==4,'needs witness, actual native report, receipt path')
    main(*sys.argv[1:])
