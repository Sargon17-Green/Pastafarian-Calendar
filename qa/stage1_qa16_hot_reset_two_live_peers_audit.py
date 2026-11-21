#!/usr/bin/env python3
"""Independent fail-closed QA16 audit. Only Native Befunge produces calendar values."""
import copy, json, hashlib, sys
from pathlib import Path
PIN='560d6aa5807a7f766213a33835cce85eab0fa40c'
CASES=(
    ('invalid_valid_two_peers','i0','v1','v3','v0',(100,2,3)),
    ('valid_invalid_lexical_two_peers','v2','v4','v5','i5',(51,3,2)),
    ('invalid_numeric_valid_two_peers','i2','v2','v3','v5',(37,2,5)),
    ('valid_invalid_numeric_two_peers','v3','v1','v5','i0',(83,5,2)),
)
FLAGS=('old_actor_memory_preserved','peers_stayed_private','same_program_identity',
       'fresh_actor_space_semantics_ip_io','three_outputs_match_independent_native_references')
COUNTERS=('before_overlap','after_all_three_overlap',
          'passive_peer_snapshot_checks','old_actor_written_coordinates_checked',
          'actor_post_reset_put')

def need(ok,why):
    if not ok:raise AssertionError(why)

def verify(z):
    need(type(z) is dict and z.get('schema')=='qa16-real-native-two-live-peers-hot-reset-v1'
         and z.get('source_git_blob')==PIN and z.get('stage1_final_accepted') is False
         and z.get('scenario_count')==4 and z.get('native_program_executions')==16
         and z.get('independent_native_reference_invocations')==18,
         'QA16 signed contract or real Native interpreter counts wrong')
    rows=z.get('records')
    need(type(rows) is list and len(rows)==len(CASES),
         'QA16 missing/extra/reordered Native scenarios')
    anchors={};before=after=checks=0
    for (name,first,peer1,peer2,new,quantum),r in zip(CASES,rows):
        need(type(r) is dict and tuple(r.get(k) for k in
             ('name','before','peer_one','peer_two','after'))==
             (name,first,peer1,peer2,new) and r.get('quanta')==list(quantum),
             'QA16 exact tested quantum schedule/labels changed: '+name)
        need(all(r.get(f) is True for f in FLAGS),
             'QA16 physical Native memory/isolation flag invalid: '+name)
        need(all(type(r.get(k)) is int and r[k]>0 for k in COUNTERS),
             'QA16 missing Native concurrency/ownership counters: '+name)
        need(type(r.get('peer_memory_attack_rejected')) is int and
             r['peer_memory_attack_rejected']==1,
             'QA16 passive peer physical corruption detector not tested: '+name)
        need(type(r.get('peer_writes')) is list and len(r['peer_writes'])==2
             and type(r.get('peer_reads')) is list and len(r['peer_reads'])==2
             and all(type(v) is int and v>0 for v in
                     r['peer_writes']+r['peer_reads']),
             'QA16 both original live peers must genuinely read/write memory')
        need(r['passive_peer_snapshot_checks'] >=
             2*(r['before_overlap']+r['after_all_three_overlap']),
             'QA16 insufficient Native all-live passive ownership checks')
        for label,key in ((first,'before_output'),(peer1,'peer_one_output'),
                          (peer2,'peer_two_output'),(new,'after_output')):
            vals=r.get(key)
            need(type(vals) is list and len(vals)==7 and all(
                 type(v) is str and v and v.lstrip('-').isdigit() for v in vals),
                 'QA16 malformed seven-field Native output: '+name+key)
            if label.startswith('i'):
                need(vals==['-1']*7,'QA16 invalid Native syntax not rejected')
            elif label in anchors:
                need(vals==anchors[label], 'QA16 same Native reference changed: '+label)
            else:anchors[label]=vals
        before+=r['before_overlap'];after+=r['after_all_three_overlap']
        checks+=r['passive_peer_snapshot_checks']
    need(set(anchors)=={'v0','v1','v2','v3','v4','v5'},
         'QA16 all six native valid reference vectors not exercised')
    return {'scenarios':4,'valid_native_reference_vectors':6,
            'before_triple_overlap_rounds':before,'after_triple_overlap_rounds':after,
            'passive_program_state_checks':checks}

def forge_checks(d):
    attacks=[
      ('false_frozen_source',lambda x:x.__setitem__('source_git_blob','0'*40)),
      ('missing_case',lambda x:x['records'].pop()),
      ('reordered_case',lambda x:x['records'].reverse()),
      ('label_changed',lambda x:x['records'][0].__setitem__('peer_two','v5')),
      ('quantum_changed',lambda x:x['records'][1]['quanta'].__setitem__(0,999)),
      ('new_actor_not_fresh',lambda x:x['records'][0].__setitem__('fresh_actor_space_semantics_ip_io',False)),
      ('peer_corrupt',lambda x:x['records'][1].__setitem__('peers_stayed_private',False)),
      ('old_space_dirty',lambda x:x['records'][2].__setitem__('old_actor_memory_preserved',False)),
      ('forged_invalid_response',lambda x:x['records'][3]['after_output'].__setitem__(0,'0')),
      ('synthetic_peer_corruption_not_rejected',lambda x:x['records'][0].__setitem__('peer_memory_attack_rejected',0)),
      ('missing_overlap',lambda x:x['records'][0].__setitem__('after_all_three_overlap',0)),
      ('fictitious_stage1_acceptance',lambda x:x.__setitem__('stage1_final_accepted',True)),
    ]
    for name,mutate in attacks:
        bad=copy.deepcopy(d);mutate(bad)
        try:verify(bad)
        except AssertionError:continue
        raise AssertionError('QA16 forged report accepted: '+name)
    return [name for name,_ in attacks]

def selftest():
    r=[]
    for name,first,p1,p2,after,q in CASES:
        row=dict(name=name,before=first,peer_one=p1,peer_two=p2,after=after,
                 quanta=list(q),before_overlap=10,after_all_three_overlap=10,
                 passive_peer_snapshot_checks=60,old_actor_written_coordinates_checked=10,
                 actor_post_reset_put=10,peer_memory_attack_rejected=1,
                 peer_writes=[10,20],peer_reads=[10,20])
        row.update({s:True for s in FLAGS})
        for label,key in ((first,'before_output'),(p1,'peer_one_output'),
                          (p2,'peer_two_output'),(after,'after_output')):
            row[key]=(['-1']*7 if label.startswith('i') else [label[1:]]*7)
        r.append(row)
    x=dict(schema='qa16-real-native-two-live-peers-hot-reset-v1',
           source_git_blob=PIN,stage1_final_accepted=False,
           scenario_count=4,native_program_executions=16,
           independent_native_reference_invocations=18,records=r)
    verify(x)
    need(len(forge_checks(x))==12,'QA16 synthetic adversarial controls incomplete')
    print('QA16_AUDITOR_12_SYNTHETIC_FALSIFICATIONS_REJECTED')
    print('QA16_SYNTHETIC_FIXTURE_NOT_NATIVE_PROOF')

def main(p):
    source=Path('src/interleaved_work_counts.b98').read_bytes()
    sha=hashlib.sha1(b'blob '+str(len(source)).encode()+b'\0'+source).hexdigest()
    need(sha==PIN,'QA16 production Befunge source changed')
    z=json.loads(Path(p).read_text(encoding='utf-8'))
    summary=verify(z)
    attacks=forge_checks(z)
    target=Path(p).parent/'qa16_native_two_live_peers_audit.json'
    target.write_text(json.dumps({'schema':'qa16-native-two-peers-failclosed-audit-v1',
                'summary':summary,'forged_reports_rejected':attacks,
                'stage1_final_accepted':False},sort_keys=True,indent=2)+'\n',encoding='utf-8')
    print('QA16_NATIVE_TWO_PEERS_INDEPENDENT_AUDIT_PASS',json.dumps(summary,sort_keys=True))
    print('QA16_TWELVE_FORGED_REPORTS_REJECTED')
    print('STAGE1_STILL_OPEN')
if __name__=='__main__':
    if len(sys.argv)==2 and sys.argv[1]=='--selftest':selftest()
    else:
        need(len(sys.argv)==2,'QA16 auditor needs one real Native receipt JSON')
        main(sys.argv[1])
