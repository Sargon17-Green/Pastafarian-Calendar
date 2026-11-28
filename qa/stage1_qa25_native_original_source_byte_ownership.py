#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA25: exact fresh original-input PyFunge physical source-cell ownership replay.

For each accepted QA24 input, compare every real Native STEP tuple to QA24's
unchanged raw compressed original execution. Record *actual* Program.space.put
calls at all 21 frozen source candidates, and classify fetched original bytes
based on physical prior writes, not matching runtime opcode alone.

Single-IP, one Program at a time. No IP relocation or Funge-space intervention.
No static source code edit. No source-language calendar oracle implemented here.
"""
from __future__ import print_function
import gzip
import hashlib
import json
import os
import sys
import StringIO

import stage1_qa20_native_input_route_scan as q20
import stage1_qa24_frozen_input_corpus as c24

SOURCE = '560d6aa5807a7f766213a33835cce85eab0fa40c'
QA18 = '263a73a40afa17a8a9b1c831a01239be671d9ea0a9c331fd3f725f83cf1cfea7'
QA20 = '75d2ee07eaf998fcb69bcb238d5fcb2163ab8305efe4abe4378af95f41385117'
QA24_RUN = 39841651046
EXPECTED_HITS = ('10,44','179,44','235,11','396,17')

def need(condition, why):
    if not condition:
        raise AssertionError(why)

def sha(data):
    return hashlib.sha256(data).hexdigest()

def sha_file(path):
    return sha(open(path,'rb').read())

def source_at(rows,coord):
    x,y=coord
    return int(rows[y][x]) if 0<=y<len(rows) and 0<=x<len(rows[y]) else 32

def replay(source, entry, manifest, targets, folder, source_rows):
    label=entry['label']; raw=entry['raw_input']
    need(entry['path']==label+'.steps.gz','original Native QA24 route path changed')
    compressed=open(os.path.join(folder,entry['path']),'rb').read()
    need(sha(compressed)==entry['compressed_trace_sha256'],
         'QA24 compressed trace not original '+label)
    original_stream=gzip.GzipFile(fileobj=StringIO.StringIO(compressed),mode='rb').read()
    original_lines=original_stream.splitlines()
    need(len(original_lines)==entry['steps'] and len(original_lines)>50,
         'original original QA24 raw STEP trace malformed '+label)
    need(entry['natural_ip_no_intervention'] is True
         and entry['output']==entry['expected'] and len(entry['output'])==7,
         'original Native QA24 case input/output contract changed '+label)

    current=q20.create_program(source,raw,label)
    program=current['program']; space=program.space
    cls=type(space); old_put=cls.put
    point=program.ips[0].position.__class__
    static={(x,y):ord(ch) for x,y,ch in targets}
    latest={}
    watched_puts=[]
    steps_hash=hashlib.sha256()
    candidate_fetches=[]
    tick=[0]; ip_entry=[None]; total_puts=[0]
    def record_put(self,*args,**kwargs):
        need(self is space and len(args)>=2,'unexpected foreign/native put identity')
        coord=tuple(map(int,args[0])); old=int(self.get(args[0]))
        result=old_put(self,*args,**kwargs)
        val=int(self.get(args[0]))
        need(val==int(args[1]),'Native space.put failed physical persist')
        total_puts[0]+=1
        if coord in static:
            e={'tick':tick[0],'coordinate':list(coord),
               'origin_ip':ip_entry[0]['pos'] if ip_entry[0] else None,
               'origin_opcode':ip_entry[0]['opcode'] if ip_entry[0] else None,
               'previous_value':old,'written_value':val,
               'before_original_byte':old==static[coord],
               'after_original_byte':val==static[coord]}
            watched_puts.append(e)
            latest[coord]=e
        return result
    try:
        cls.put=record_put
        while program.ips:
            need(len(program.ips)==1,'QA25 original native source acquired second IP')
            ip=program.ips[0]
            x,y=map(int,ip.position);dx,dy=map(int,ip.delta)
            op=int(space.get(ip.position));s=int(bool(ip.stringmode))
            tick[0]+=1
            need(tick[0]<=q20.MAX_TICKS,'QA25 actual Native step bound exhausted')
            line='%d\t%d\t%d\t%d\t%d\t%d\t%d'%(tick[0],x,y,dx,dy,op,s)
            # The original archive may have a final newline, but raw STEP rows
            # are compared one-for-one before computing the new exact digest.
            need(line==original_lines[tick[0]-1],
                 'real Native STEP differs from original QA24 route: '+label+' at '+str(tick[0]))
            steps_hash.update(line+'\n')
            ip_entry[0]={'pos':[x,y],'opcode':op}
            key=(x,y)
            if key in static:
                writer=latest.get(key)
                candidate_fetches.append({
                    'tick':tick[0], 'coordinate':[x,y],
                    'runtime_opcode':op,
                    'original_opcode':static[key],
                    'stringmode':bool(s),
                    'previous_native_put':writer is not None,
                    'latest_prior_put_tick':writer['tick'] if writer else None,
                    'matching_original_opcode':op==static[key],
                    'original_byte_owned':writer is None and op==static[key],
                    'effective_original_instruction':
                       writer is None and op==static[key] and not bool(s)})
            q20.tick_qa20(current)
        need(current['steps']==entry['steps']==tick[0],
             'QA25 original Native program terminated with a different step count')
    finally:
        cls.put=old_put

    output=current['stdout'].getvalue().split()
    need(output==entry['output'],'QA25 original native seven-field output differs from QA24')
    need(sha(original_stream)==steps_hash.hexdigest(),
         'QA25 entire Native STEP stream differs from frozen original QA24')
    for e in candidate_fetches:
        key=tuple(e['coordinate'])
        need(e['previous_native_put'] is
             any(tuple(w['coordinate'])==key and w['tick']<e['tick']
                 for w in watched_puts),
             'mutation ownership classification inconsistent at a Native fetch')
    print('QA25_NATIVE_SOURCE_OWNER_REPLAY',label,
          'steps',tick[0],'puts',total_puts[0],
          'watched',len(watched_puts),'source_fetches',len(candidate_fetches))
    sys.stdout.flush()
    return {'label':label,'raw_input':raw,'valid':entry['valid'],
            'actual_native_steps':tick[0],
            'native_output':output,
            'qa24_original_raw_steps_sha256':sha(original_stream),
            'qa25_replayed_raw_steps_sha256':steps_hash.hexdigest(),
            'original_gzip_sha256':sha(compressed),
            'actual_space_put_calls':total_puts[0],
            'candidate_put_events':watched_puts,
            'candidate_fetches':candidate_fetches,
            'no_test_only_write':True,
            'production_source_mutated':False,'forced_ip_relocation':False}

def main(shard,folder):
    need(shard in range(4),'need physical shard 0..3')
    source=open('src/interleaved_work_counts.b98','rb').read()
    need(q20.pin(source)==SOURCE,'signed original production source changed')
    roles_path=os.path.join(folder,'qa18_glyph_roles.json')
    original_path=os.path.join(folder,'qa20_native_48_aggregate.json')
    need(sha_file(roles_path)==QA18 and sha_file(original_path)==QA20,
         'QA18/QA20 verified original Native baseline changed')
    targets=q20.targets_from_qa18(roles_path,source)
    need(len(targets)==21,'not exactly original 21 target cells')
    manifest=json.load(open(os.path.join(folder,'qa24_manifest.json'),'rb'))
    need(manifest.get('schema')=='qa24-24-disjoint-native-input-physical-route-v1'
         and manifest.get('shard')==shard and manifest.get('source_git_blob')==SOURCE
         and manifest.get('qa18_source_provenance_sha256')==QA18
         and manifest.get('qa20_prior_native_aggregate_sha256')==QA20
         and manifest.get('new_native_source_mutations')==0
         and manifest.get('ip_relocated') is False
         and manifest.get('stage1_complete') is False,
         'untrusted original QA24 per-shard manifest')
    expected=[(i,item) for i,item in enumerate(c24.check_disjoint(q20.cases())) if i%4==shard]
    need(len(manifest['records'])==len(expected)==6,'six original Native QA24 cases missing')
    for row,(i,(name,raw,valid)) in zip(manifest['records'],expected):
        need(row['label']==name and row['raw_input']==raw
             and row['valid'] is valid and row['qa24_corpus_index']==i,
             'QA24 original input label or source changed')
    source_rows=source.splitlines()
    result=[]
    for entry in manifest['records']:
        result.append(replay(source,entry,manifest,targets,folder,source_rows))
        checkpoint={'schema':'qa25-physical-21-original-source-cell-ownership-v1',
          'source_git_blob':SOURCE,'native_qa24_original_run':QA24_RUN,
          'prior_qa18_source_roles_sha256':QA18,'prior_qa20_original_aggregate_sha256':QA20,
          'original_qa24_shard':shard,'native_programs_replayed':len(result),
          'original_21_source_candidate_locations':[list(z) for z in targets],
          'real_native_provenance_records':result,
          'all_original_inputs_unchanged':True,'ip_relocated':False,
          'production_source_edited':False,
          'static_byte_origin_proof_scoped_to_actual_put_calls':True,
          'other_mutation_apis_excluded_globally':False,
          'stage1_complete':False}
        with open(os.path.join(folder,'qa25_native_owner_receipts.json'),'wb') as stream:
            stream.write(json.dumps(checkpoint,sort_keys=True,indent=2)+'\n')
    print('QA25_ALL_SIX_ORIGINAL_NATIVE_OWNERSHIP_RUNS_COMPLETE',shard)
    print('QA25_NO_GLOBAL_STAGE1_OWNERSHIP_OR_DEAD_CODE_PROOF')

if __name__=='__main__':
    need(len(sys.argv)==3,'usage: qa25.py SHARD RESTORED_QA24_SHARD_DIR')
    main(int(sys.argv[1]),sys.argv[2])
