#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA26: 64 fresh ordinary-input Native PyFunge-98 routes for QA18 source cells.

Runs 16 original (unmodified) Native programs in each of four CI shards.
Uses existing exact QA20 Native runner for full compressed physical STEP traces,
independent executable BF98 reference programs, and malformed-input sentinels.
No forced IP positioning, instruction patch, source write, or Python calendar.
"""
from __future__ import print_function
import hashlib,json,os,sys
import stage1_qa20_native_input_route_scan as base
import stage1_qa26_frozen_input_corpus as corpus

SOURCE_SHA='560d6aa5807a7f766213a33835cce85eab0fa40c'
QA18_SHA='263a73a40afa17a8a9b1c831a01239be671d9ea0a9c331fd3f725f83cf1cfea7'
QA20_SHA='75d2ee07eaf998fcb69bcb238d5fcb2163ab8305efe4abe4378af95f41385117'
OLDER_HITS=('10,44','150,20','175,38','179,44','235,11','396,17')

def need(value,explanation):
    if not value:raise AssertionError(explanation)

def sha_file(path):
    return hashlib.sha256(open(path,'rb').read()).hexdigest()

def main(shard,directory,roles_path,original_qa20):
    need(shard in (0,1,2,3) and os.path.isdir(directory),'bad native shard or output path')
    need(sha_file(roles_path)==QA18_SHA
         and sha_file(original_qa20)==QA20_SHA,
         'accepted original Native geometry baseline was modified')
    source=open(base.SOURCE,'rb').read()
    need(base.pin(source)==SOURCE_SHA==base.PIN,
         'immutable production source Git blob drifted')
    roles=json.load(open(roles_path,'rb'))
    old=json.load(open(original_qa20,'rb'))
    need(roles.get('schema')=='qa18-source-glyph-contact-v1'
         and roles.get('source_git_blob')==SOURCE_SHA
         and roles.get('dead_code_certified') is False,
         'QA18 source provenance claim forged')
    need(old.get('schema')=='qa20-final-finite-native-physical-route-audit-v1'
         and old.get('native_cases')==48 and old.get('stage1_complete') is False
         and old.get('no_dead_code_certification') is True
         and tuple(sorted(old.get('natural_source_opcode_hits',[])))==OLDER_HITS,
         'QA20 original six Native source opcode hits changed')
    targets=base.targets_from_qa18(roles_path,source)
    need(len(targets)==21,'QA18 original 21 candidate source cells missing')
    full=corpus.verify_disjoint(base.cases())
    records=[]
    for index,(label,raw,valid) in enumerate(full):
        if index%4!=shard:continue
        result=base.sample(source,label,raw,valid,targets,directory)
        result['qa26_case_index']=index
        records.append(result)
        print('QA26_NEW_ORIGINAL_NATIVE_INPUT',shard,label,
              'steps',result['steps'],
              'candidate_contact_count',sum(bool(v) for v in result['target_step_hits'].values()))
        sys.stdout.flush()
    need(len(records)==16,'sixteen exact fresh Native programs not completed')
    original_15=sorted('%d,%d'%(x,y) for x,y,_ in targets
                       if '%d,%d'%(x,y) not in OLDER_HITS)
    need(len(original_15)==15,'original fifteen unobserved candidates changed')
    report={'schema':'qa26-native-64-disjoint-input-source-frontier-v1',
      'source_git_blob':SOURCE_SHA,
      'qa18_original_roles_sha256':QA18_SHA,
      'qa20_original_aggregate_sha256':QA20_SHA,
      'original_qa18_target_count':21,
      'source_candidate_coordinates':[list(z) for z in targets],
      'original_six_known_hits':list(OLDER_HITS),
      'original_fifteen_not_reached':original_15,
      'shard':shard,'native_program_count':len(records),
      'native_corpus_total':64,'native_valid_total':32,'native_invalid_total':32,
      'ip_relocated':False,'production_source_modified':False,
      'any_test_only_memory_interventions':False,
      'source_byte_ownership_globally_proven':False,
      'dead_code_certified':False,'stage1_complete':False,
      'records':records}
    with open(os.path.join(directory,'qa26_manifest.json'),'wb') as f:
        f.write(json.dumps(report,sort_keys=True,indent=2)+'\n')
    print('QA26_SIXTEEN_NEW_REAL_NATIVE_ROUTES_CAPTURED',shard)
    print('QA26_NO_GLOBAL_DEAD_CODE_OR_STAGE1_ACCEPTANCE')
if __name__=='__main__':
    need(len(sys.argv)==5,'usage: qa26_native.py SHARD OUTPUT_DIR QA18_ROLES QA20_AGGREGATE')
    main(int(sys.argv[1]),sys.argv[2],sys.argv[3],sys.argv[4])
