#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA30B: real PyFunge state at signed QA30A near-control observations.

Replay original invalid00 / invalid18 from input origin, never move the IP.
Check every Native STEP against QA20 signed evidence and record exact live
FungeSpace values and actual put chronology at 15 candidate source cells.
"""
from __future__ import print_function
import gzip
import hashlib
import json
import os
import sys
import StringIO
import stage1_qa20_native_input_route_scan as old

SOURCE_BLOB='560d6aa5807a7f766213a33835cce85eab0fa40c'
QA30A_SHA='7c3ba01dc00a4f67fc30cc52e594b1cd6a2adee597a21939dbe0176ac2be2d4e'
MANIFEST={
  'invalid00':(3,'3f2e81afb325a4f1e8bfee3910be6d92d2bef23145ba39a33fc355ea23a5454b'),
  'invalid18':(1,'9c5af6212cfd7c1ab58e9603f385767e64b10799c90be416a86c4f09d613bfdd')
}
OLDER={(10,44),(150,20),(175,38),(179,44),(235,11),(396,17)}
def need(v,s):
    if not v: raise AssertionError(s)
def sha(b):
    return hashlib.sha256(b).hexdigest()
def parse(line,t):
    parts=line.split('\t')
    need(len(parts)==7,'signed original Native STEP width invalid')
    row=tuple(map(int,parts))
    need(row[0]==t and row[-1] in (0,1) and 0<=row[-2]<=255,
         'original Native STEP tick/opcode/stringmode invalid')
    return row
def start(label,root,qa30a):
    shard,pin=MANIFEST[label]
    folder=os.path.join(root,label)
    data=open(os.path.join(folder,'qa20_manifest.json'),'rb').read()
    need(sha(data)==pin,'original QA20 Native manifest pin changed')
    manifest=json.loads(data)
    need(manifest.get('source_git_blob')==SOURCE_BLOB
         and manifest.get('shard')==shard
         and manifest.get('source_modified') is False
         and manifest.get('ip_relocated') is False
         and manifest.get('stage1_final_acceptance') is False
         and len(manifest.get('records',[]))==12,
         'original QA20 Native provenance mismatch')
    candidates=[r for r in manifest['records'] if r['label']==label]
    need(len(candidates)==1,'original selected input missing')
    rec=candidates[0]
    need(rec['valid'] is False and rec['output']==['-1']*7
         and rec['output']==rec['expected']
         and rec['natural_ip_no_intervention'] is True,
         'original QA20 rejection output changed')
    zipped=open(os.path.join(folder,rec['path']),'rb').read()
    need(sha(zipped)==rec['compressed_trace_sha256']
         and len(zipped)==rec['compressed_bytes'],
         'original SHA256 of compressed Native STEP trace changed')
    lines=gzip.GzipFile(fileobj=StringIO.StringIO(zipped),mode='rb').read().splitlines()
    need(len(lines)==rec['steps'],'original physical Native trace length changed')
    signed=[parse(line,t) for t,line in enumerate(lines,1)]
    witnesses={}
    for coord,records in qa30a['nearest_observed_control_transitions_by_15_source_candidates'].items():
        for e in records:
            if e['input_group']!='QA20' or e['input_label']!=label:continue
            tick=e['tick']
            need(1<=tick<len(signed),'signed QA30A witness is outside actual Native STEP')
            before=signed[tick-1];after=signed[tick]
            need(e['position']==list(before[1:3])
                 and e['vector_before']==list(before[3:5])
                 and e['runtime_opcode']==before[5]
                 and e['stringmode_before']==before[6]
                 and e['next_position']==list(after[1:3])
                 and e['vector_after']==list(after[3:5])
                 and e['next_runtime_opcode']==after[5]
                 and e['next_stringmode']==after[6],
                 'QA30A nearest control edge not anchored in original QA20 raw STEPs')
            witnesses.setdefault(tick,[]).append(coord)
    need(len(witnesses)>0,'no input-origin observed QA30A control witnesses for '+label)
    source=open(old.SOURCE,'rb').read()
    need(old.pin(source)==SOURCE_BLOB==old.PIN,'original production Funge source changed')
    program=old.create_program(source,rec['raw_input'],label)
    space=program['program'].space
    original_rows=source.splitlines()
    targets=sorted(set(tuple(map(int,coord.split(','))) for coord
                       in qa30a['nearest_observed_control_transitions_by_15_source_candidates']))
    need(len(targets)==15 and not any(x in OLDER for x in targets),
         'original 15 unresolved cells changed')
    initial={(x,y):ord(original_rows[y][x]) for x,y in targets}
    cls=type(space);original_put=cls.put
    writes=[];put_events=[];put_count=[0];tick_holder=[0];snapshots=[]
    def capture_put(self,*args,**kwargs):
        need(self is space and len(args)>=2,'unexpected foreign physical Native put')
        pos=tuple(map(int,args[0]))
        oldvalue=int(self.get(args[0]))
        rv=original_put(self,*args,**kwargs)
        actual=int(self.get(args[0]))
        put_count[0]+=1
        put_events.append({'tick':tick_holder[0], 'coordinate':list(pos),
                           'before':oldvalue,'after':actual})
        if pos in initial:
            writes.append({'tick':tick_holder[0],'coordinate':list(pos),
                           'before':oldvalue,'after':actual})
        return rv
    try:
        cls.put=capture_put
        while program['program'].ips:
            need(len(program['program'].ips)==1,'input-driven Native program became multi-IP')
            tick=program['steps']+1
            need(tick<=len(signed),'real Native run exceeded accepted STEP count')
            ip=program['program'].ips[0]
            actual=(tick,int(ip.position[0]),int(ip.position[1]),
                    int(ip.delta[0]),int(ip.delta[1]),
                    int(space.get(ip.position)),int(bool(ip.stringmode)))
            need(actual==signed[tick-1],
                 'actual Native instruction diverged from original signed QA20 STEP '+label+' '+str(tick))
            matches=witnesses.get(tick)
            if matches:
                snapshot={'tick':tick,'target_coords':sorted(matches),
                          'actual_before_step':list(actual),
                          'fetched_source_candidate_live_values':[
                              {'coordinate':[x,y],
                               'runtime_value':int(space.get(program['point']((x,y)))),
                               'static_original_value':initial[x,y],
                               'actual_prior_put_ticks':[
                                 w['tick'] for w in writes if w['coordinate']==[x,y]]}
                              for x,y in targets],
                          'physical_candidate_writes_prior_to_tick':len(writes)}
                snapshots.append(snapshot)
            tick_holder[0]=tick
            old.tick_qa20(program)
            if matches and program['program'].ips:
                ip=program['program'].ips[0]
                actual_next=(tick+1,int(ip.position[0]),int(ip.position[1]),
                             int(ip.delta[0]),int(ip.delta[1]),
                             int(space.get(ip.position)),int(bool(ip.stringmode)))
                need(actual_next==signed[tick],
                     'real Native control successor differs from original signed STEP '+label+' '+str(tick))
                snapshots[-1]['actual_next_step']=list(actual_next)
        need(program['steps']==rec['steps'] and len(snapshots)==len(witnesses),
             'not all original Native instructions or witness checkpoints replayed')
    finally:
        cls.put=original_put
    need(len(put_events)==put_count[0],
         'real Native FungeSpace.put provenance count incomplete')
    need(program['stdout'].getvalue().split()==rec['output'],
         'actual Native program output is not original signed QA20 result')
    return {'label':label,'original_shard':shard,'original_input':rec['raw_input'],
            'original_signed_steps':len(signed),'qa20_original_gzip_sha256':sha(zipped),
            'real_native_put_calls':put_count[0],
            'all_real_native_put_events':put_events,
            'writes_to_original_15_cells':writes,
            'signed_witness_tick_count':len(witnesses),
            'signed_target_witness_pairs':sum(len(x) for x in witnesses.values()),
            'live_state_snapshots':snapshots,
            'native_final_output':program['stdout'].getvalue().split(),
            'full_original_native_step_parity':True,
            'no_forced_ip_relocation':True,'production_source_mutated':False}

def main(root,originalqa30a):
    raw=open(originalqa30a,'rb').read()
    need(sha(raw)==QA30A_SHA,'original signed QA30A report SHA256 changed')
    doc=json.loads(raw)
    need(doc.get('schema')=='qa30a-136-original-native-dynamic-control-frontier-v1'
         and doc.get('original_production_git_blob')==SOURCE_BLOB
         and doc.get('original_programs_reaudited')==136
         and doc.get('original_native_steps_reaudited')==4513423
         and doc.get('negative_provenance_and_directed_edge_controls_rejected')==70
         and doc.get('stage1_complete') is False,
         'QA30A original fixed finite audit conditions modified')
    rows=[start(label,root,doc) for label in ('invalid00','invalid18')]
    need(sum(r['original_signed_steps'] for r in rows)==18859,
         'QA30B 2 input programs no longer reproduce signed total')
    report={'schema':'qa30b-two-original-input-live-source-owner-frontier-v1',
      'production_git_blob':SOURCE_BLOB,
      'qa30a_original_json_sha256':QA30A_SHA,
      'qa20_original_run':39761821210,
      'qa30a_original_run':40125781530,
      'original_programs_replayed':2,
      'original_native_steps_replayed':sum(r['original_signed_steps'] for r in rows),
      'candidate_count':15,
      'all_native_execution_input_origin':True,
      'native_program_bytes_modified':False,
      'no_forced_ip_relocation':True,
      'global_mutation_apis_excluded':False,
      'global_source_deadness_proved':False,
      'stage1_complete':False,'records':rows}
    with open(os.path.join(root,'qa30b_live_source_frontier.json'),'wb') as handle:
        handle.write(json.dumps(report,sort_keys=True,indent=2)+'\n')
    print('QA30B_TWO_REAL_NATIVE_ORIGINAL_INPUT_REPLAYS_PASS',report['original_native_steps_replayed'])
    print('QA30B_SIGNED_DYNAMIC_CONTROL_MEMORY_SNAPSHOTS_CAPTURED',sum(len(r['live_state_snapshots']) for r in rows))
    print('QA30B_NO_GLOBAL_DEAD_CODE_OR_STAGE1_ACCEPTANCE')
if __name__=='__main__':
    need(len(sys.argv)==3,'usage: qa30b.py EVIDENCE_ROOT ORIGINAL_QA30A_JSON')
    main(sys.argv[1],sys.argv[2])
