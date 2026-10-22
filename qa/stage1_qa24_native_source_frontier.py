#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA24: new unmodified input-origin Native PyFunge routes, not simulated routes.
Extends QA20 physical STEP recording and three native Befunge reference calls.
"""
from __future__ import print_function
import hashlib,json,os,sys
import stage1_qa20_native_input_route_scan as q20
import stage1_qa24_frozen_input_corpus as corpus

SOURCE_SHA='560d6aa5807a7f766213a33835cce85eab0fa40c'
QA18_SHA='263a73a40afa17a8a9b1c831a01239be671d9ea0a9c331fd3f725f83cf1cfea7'
QA20_SHA='75d2ee07eaf998fcb69bcb238d5fcb2163ab8305efe4abe4378af95f41385117'
OLD_HITS=('10,44','150,20','175,38','179,44','235,11','396,17')

def need(v,msg):
    if not v:raise AssertionError(msg)
def sha(path):
    return hashlib.sha256(open(path,'rb').read()).hexdigest()
def main(shard,folder,rolefile,aggregate):
    need(shard in range(4),'bad QA24 shard number')
    need(os.path.isdir(folder),'missing native receipt destination')
    source=open('src/interleaved_work_counts.b98','rb').read()
    need(q20.pin(source)==SOURCE_SHA==q20.PIN,'signed original Native BF98 source changed')
    need(sha(rolefile)==QA18_SHA and sha(aggregate)==QA20_SHA,
         'QA18/QA20 authoritative Native artifacts drifted')
    roles=json.load(open(rolefile,'rb'))
    past=json.load(open(aggregate,'rb'))
    need(roles['source_git_blob']==SOURCE_SHA
         and roles['dead_code_certified'] is False
         and roles['native_original_trace_count']==49,
         'QA18 Native role proof scope changed')
    need(past['schema']=='qa20-final-finite-native-physical-route-audit-v1'
         and past['native_cases']==48 and past['stage1_complete'] is False
         and past['no_dead_code_certification'] is True
         and past['all_original_qa18_targets']==21
         and sorted(past['natural_source_opcode_hits'])==list(OLD_HITS),
         'original six input-reachable source opcodes changed')
    targets=q20.targets_from_qa18(rolefile,source)
    need(len(targets)==21,'not exactly the original 21 source cells')
    remaining=sorted('%d,%d'%(x,y) for x,y,_ in targets
                     if '%d,%d'%(x,y) not in OLD_HITS)
    need(len(remaining)==15,'original unobserved 15 no longer immutable')
    test_cases=corpus.check_disjoint(q20.cases())
    records=[]
    for i,(label,raw,valid) in enumerate(test_cases):
        if i%4!=shard:continue
        record=q20.sample(source,label,raw,valid,targets,folder)
        record['qa24_corpus_index']=i
        records.append(record)
        print('QA24_REAL_NATIVE_UNMODIFIED_INPUT',label,record['steps'],
              sum(bool(z) for z in record['target_step_hits'].values()))
        sys.stdout.flush()
    need(len(records)==6,'QA24 Native shard incomplete')
    out={'schema':'qa24-24-disjoint-native-input-physical-route-v1',
         'shard':shard,'source_git_blob':SOURCE_SHA,
         'qa18_source_provenance_sha256':QA18_SHA,
         'qa20_prior_native_aggregate_sha256':QA20_SHA,
         'prior_natural_source_hits':list(OLD_HITS),
         'fifteen_not_yet_reached':remaining,
         'candidate_count':21,'new_native_cases':6,
         'new_native_source_mutations':0,'ip_relocated':False,
         'stage1_complete':False,'dead_code_certified':False,
         'records':records,
         'targets':[list(x) for x in targets]}
    with open(os.path.join(folder,'qa24_manifest.json'),'wb') as f:
        f.write(json.dumps(out,sort_keys=True,indent=2)+'\n')
    print('QA24_SIX_NEW_ORIGINAL_NATIVE_ROUTES_PASS',shard)
if __name__=='__main__':
    need(len(sys.argv)==5,'usage: qa24.py shard output_dir qa18.json qa20_aggregate.json')
    main(int(sys.argv[1]),sys.argv[2],sys.argv[3],sys.argv[4])
