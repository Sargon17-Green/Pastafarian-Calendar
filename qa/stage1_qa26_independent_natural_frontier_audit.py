#!/usr/bin/env python3
"""QA26 independent physical STEP receipt auditor for 64 actual Native routes.

Every gzip STEP file is SHA-checked, decompressed, replayed monotonically, and
used to recompute 21 original source-cell physical hits and L1 proximity.
This auditor does not simulate Funge operations or calendar numeric outputs.
"""
import argparse
import copy
import gzip
import hashlib
import json
from pathlib import Path

import stage1_qa26_frozen_input_corpus as corpus

SOURCE='560d6aa5807a7f766213a33835cce85eab0fa40c'
QA18='263a73a40afa17a8a9b1c831a01239be671d9ea0a9c331fd3f725f83cf1cfea7'
QA20='75d2ee07eaf998fcb69bcb238d5fcb2163ab8305efe4abe4378af95f41385117'
OLDER_HITS=('10,44','150,20','175,38','179,44','235,11','396,17')

def need(value,why):
    if not value:raise AssertionError(why)

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def original_source():
    raw=Path('src/interleaved_work_counts.b98').read_bytes()
    blob=hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest()
    need(blob==SOURCE,'original production source was altered')
    return raw.splitlines()

def pinned_json(filename,digest):
    content=Path(filename).read_bytes()
    need(sha(content)==digest,'original native input evidence digest does not match')
    return json.loads(content)

def ground(roles,prior,source_rows):
    need(roles.get('schema')=='qa18-source-glyph-contact-v1'
         and roles.get('source_git_blob')==SOURCE
         and roles.get('native_original_trace_count')==49
         and roles.get('dead_code_certified') is False,
         'QA18 accepted source-role identity altered')
    targets=[(int(t['x']),int(t['y']),t['source_char'])
             for t in roles['never_touched_potential_control_glyphs']]
    need(len(targets)==21 and len(set((x,y) for x,y,c in targets))==21,
         'QA18 21 candidate source cells changed')
    need(all(len(ch)==1 and source_rows[y][x]==ord(ch) for x,y,ch in targets),
         'one original candidate opcode not present in signed production source')
    need(prior.get('schema')=='qa20-final-finite-native-physical-route-audit-v1'
         and prior.get('native_cases')==48
         and prior.get('stage1_complete') is False
         and prior.get('no_dead_code_certification') is True
         and tuple(sorted(prior.get('natural_source_opcode_hits',[])))==OLDER_HITS,
         'QA20 natural source-contact evidence changed')
    dist=prior.get('min_l1_by_candidate',{})
    need(set(dist)=={'%d,%d'%(x,y) for x,y,_ in targets}
         and all(type(v) is int and v>=0 for v in dist.values()),
         'QA20 distance frontier incomplete')
    return targets

def expected_inputs(shard):
    allcases=corpus.cases()
    return [(i,v) for i,v in enumerate(allcases) if i%4==shard]

def structural(r,shard,targets):
    ids=['%d,%d'%(x,y) for x,y,c in targets]
    missing=sorted(k for k in ids if k not in OLDER_HITS)
    need(r.get('schema')=='qa26-native-64-disjoint-input-source-frontier-v1'
         and r.get('source_git_blob')==SOURCE
         and r.get('qa18_original_roles_sha256')==QA18
         and r.get('qa20_original_aggregate_sha256')==QA20
         and r.get('original_qa18_target_count')==21
         and r.get('source_candidate_coordinates')==[list(z) for z in targets]
         and tuple(r.get('original_six_known_hits',[]))==OLDER_HITS
         and r.get('original_fifteen_not_reached')==missing
         and r.get('shard')==shard
         and r.get('native_program_count')==16
         and r.get('native_corpus_total')==64
         and r.get('native_valid_total')==32 and r.get('native_invalid_total')==32
         and r.get('ip_relocated') is False
         and r.get('production_source_modified') is False
         and r.get('any_test_only_memory_interventions') is False
         and r.get('source_byte_ownership_globally_proven') is False
         and r.get('dead_code_certified') is False
         and r.get('stage1_complete') is False,
         'QA26 manifest source/corpus/geometry/stage forged')
    entries=r.get('records')
    expected=expected_inputs(shard)
    need(type(entries) is list and len(entries)==len(expected)==16,
         'QA26 missing real original Native programs')
    for row,(index,(label,raw,valid)) in zip(entries,expected):
        need(row.get('label')==label
             and row.get('raw_input')==raw
             and row.get('valid') is valid
             and row.get('qa26_case_index')==index
             and row.get('path')==label+'.steps.gz'
             and row.get('natural_ip_no_intervention') is True
             and row.get('output')==row.get('expected')
             and type(row.get('output')) is list
             and len(row['output'])==7,
             'QA26 frozen natural input or output identity changed')
        if not valid:
            need(row['output']==['-1']*7,'invalid input was accepted')
        else:
            need(len(raw.split())==4,'valid input tuple malformed')
    return entries

def physical(row,folder,targets):
    name=row['label']
    path=folder/(name+'.steps.gz')
    need(path.is_file(),'missing actual Native raw STEP trace '+name)
    compressed=path.read_bytes()
    need(len(compressed)==row.get('compressed_bytes')
         and sha(compressed)==row.get('compressed_trace_sha256'),
         'altered compressed Native physical STEP archive '+name)
    try:lines=gzip.decompress(compressed).splitlines()
    except Exception as exc:raise AssertionError('corrupt actual Native gzip '+name) from exc
    nearest={'%d,%d'%(x,y):[10**10,None] for x,y,c in targets}
    hits={'%d,%d'%(x,y):[] for x,y,c in targets}
    real=set()
    need(len(lines)>50,'Native execution trace empty/truncated '+name)
    for tick,line in enumerate(lines,1):
        parts=line.split(b'\t')
        need(len(parts)==7,'invalid actual Native STEP field count '+name)
        try:seq,x,y,dx,dy,op,string=map(int,parts)
        except ValueError as exc:raise AssertionError('non-numeric actual STEP '+name) from exc
        need(seq==tick and 0<=op<=255 and string in (0,1),
             'nonmonotonic Native STEP / opcode / stringmode '+name)
        for tx,ty,ch in targets:
            key='%d,%d'%(tx,ty)
            d=abs(x-tx)+abs(y-ty)
            if d<nearest[key][0]:
                nearest[key]=[d,[tick,x,y,dx,dy,op,string]]
            if d==0:
                hits[key].append([tick,op,string])
                if string==0 and op==ord(ch):
                    real.add(key)
    need(len(lines)==row.get('steps')
         and row.get('nearest')==nearest
         and row.get('target_step_hits')==hits,
         'raw Native STEP physical evidence does not reproduce report '+name)
    return {'label':name,'steps':len(lines),'hits':sorted(real),
            'nearest':{key:v[0] for key,v in nearest.items()}}

def one_shard(folder,shard,targets):
    doc=json.loads((folder/'qa26_manifest.json').read_text())
    rows=structural(doc,shard,targets)
    evidence=[physical(r,folder,targets) for r in rows]
    coverage=set(k for e in evidence for k in e['hits'])
    distances={k:min(e['nearest'][k] for e in evidence)
               for k in evidence[0]['nearest']}
    return {'shard':shard,'programs':len(evidence),
            'valid':sum(r['valid'] for r in rows),
            'invalid':sum(not r['valid'] for r in rows),
            'steps':sum(e['steps'] for e in evidence),
            'labels':[e['label'] for e in evidence],
            'source_opcode_matches':sorted(coverage),'min_l1':distances,
            'no_original_byte_ownership_claim':True,
            'no_dead_code_or_stage1_claim':True}

def controls(document,shard,targets,folder):
    structural(document,shard,targets)
    tests=[
      ('source',lambda d:d.__setitem__('source_git_blob','0'*40)),
      ('stage',lambda d:d.__setitem__('stage1_complete',True)),
      ('dead-code',lambda d:d.__setitem__('dead_code_certified',True)),
      ('forced-ip',lambda d:d.__setitem__('ip_relocated',True)),
      ('memory-mutation',lambda d:d.__setitem__('any_test_only_memory_interventions',True)),
      ('fake-ownership',lambda d:d.__setitem__('source_byte_ownership_globally_proven',True)),
      ('missing-program',lambda d:d['records'].pop()),
      ('wrong-input',lambda d:d['records'][0].__setitem__('raw_input','0 0 0 0\n')),
      ('changed-candidate',lambda d:d['source_candidate_coordinates'][0].__setitem__(0,999)),
      ('wrong-prior-hits',lambda d:d['original_six_known_hits'].pop()),
      ('false-invalid-result',lambda d:d['records'][8].__setitem__('output',['42']*7)),
      ('wrong-shard',lambda d:d.__setitem__('shard',(shard+1)%4))]
    for name,edit in tests:
        forged=copy.deepcopy(document);edit(forged)
        try:structural(forged,shard,targets)
        except (AssertionError,IndexError,KeyError,TypeError):pass
        else:raise AssertionError('adversarial forged QA26 report accepted '+name)
    forged=copy.deepcopy(document['records'][0])
    forged['compressed_trace_sha256']='0'*64
    try:physical(forged,folder,targets)
    except AssertionError:pass
    else:raise AssertionError('forged Native STEP digest accepted')
    return len(tests)+1

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--qa18',required=True)
    ap.add_argument('--qa20',required=True)
    ap.add_argument('--directory')
    ap.add_argument('--shard',type=int)
    ap.add_argument('--aggregate',nargs='*')
    ap.add_argument('--output',required=True)
    a=ap.parse_args()
    rows=original_source()
    roles=pinned_json(a.qa18,QA18)
    original=pinned_json(a.qa20,QA20)
    targets=ground(roles,original,rows)
    if a.aggregate:
        need(len(a.aggregate)==4,'require exactly four original Native QA26 shards')
        folders=[Path(z) for z in a.aggregate]
        need(all(sha((f/'qa18_glyph_roles.json').read_bytes())==QA18
                 and sha((f/'qa20_native_48_aggregate.json').read_bytes())==QA20
                 for f in folders),'original Native baseline mismatch across shards')
        shards=[one_shard(folder,i,targets) for i,folder in enumerate(folders)]
        attacks=sum(controls(json.loads((folder/'qa26_manifest.json').read_text()),
                             i,targets,folder) for i,folder in enumerate(folders))
        labels=[key for s in shards for key in s['labels']]
        expected=[lab for lab,raw,valid in corpus.cases()]
        need(len(labels)==64 and set(labels)==set(expected)
             and sum(s['valid'] for s in shards)==32
             and sum(s['invalid'] for s in shards)==32
             and attacks==52,
             'incomplete QA26 corpus or negative controls')
        newly=set(k for s in shards for k in s['source_opcode_matches'])
        original_seen=set(OLDER_HITS)
        all_keys=set(original['min_l1_by_candidate'])
        distances={k:min(s['min_l1'][k] for s in shards) for k in all_keys}
        result={'schema':'qa26-64-real-native-source-frontier-final-v1',
          'source_git_blob':SOURCE,
          'qa18_original_sha256':QA18,'qa20_original_sha256':QA20,
          'new_original_input_native_programs':64,
          'valid':32,'invalid':32,
          'actual_native_steps':sum(s['steps'] for s in shards),
          'original_source_coordinate_opcode_matches':sorted(newly),
          'newly_observed_of_prior_15':sorted(newly-original_seen),
          'still_unobserved_of_prior_15':sorted(all_keys-original_seen-newly),
          'prior_15_repartition_complete':True,
          'per_candidate_min_l1_new_corpus':distances,
          'improved_l1_of_prior_15':sorted(
              k for k in all_keys-original_seen if distances[k]<original['min_l1_by_candidate'][k]),
          'negative_controls_rejected':attacks,
          'source_byte_ownership_proven':False,
          'globally_dead_code_certified':False,'stage1_complete':False,
          'shards':shards}
        need(len(result['newly_observed_of_prior_15'])+
             len(result['still_unobserved_of_prior_15'])==15,
             'fifteen original source cells were not conserved')
        Path(a.output).write_text(json.dumps(result,sort_keys=True,indent=2)+'\n')
        print('QA26_SIXTY_FOUR_NEW_REAL_NATIVE_SOURCE_TRACES_REAUDITED',
              result['actual_native_steps'])
        print('QA26_FIFTY_TWO_FORGERIES_REJECTED')
        print('QA26_NEW_NATURAL_SOURCE_COORDINATES',result['newly_observed_of_prior_15'])
    else:
        need(a.shard in range(4) and a.directory,'a single exact QA26 shard is required')
        folder=Path(a.directory)
        doc=json.loads((folder/'qa26_manifest.json').read_text())
        proof=one_shard(folder,a.shard,targets)
        rejected=controls(doc,a.shard,targets,folder)
        need(proof['programs']==16 and rejected==13,'QA26 partial shard not accepted')
        Path(a.output).write_text(json.dumps(
            {'schema':'qa26-single-original-native-shard-audit-v1',
             'original_shard':a.shard,'results':proof,
             'negative_controls_rejected':rejected,'stage1_complete':False},
            sort_keys=True,indent=2)+'\n')
        print('QA26_SIXTEEN_ORIGINAL_NATIVE_STEP_TRACES_AUDITED',
              a.shard,proof['steps'])
        print('QA26_THIRTEEN_FORGERIES_REJECTED')
        print('QA26_NO_GLOBAL_SOURCE_BYTE_OWNERSHIP_OR_STAGE1_ACCEPTANCE')

if __name__=='__main__':main()
