#!/usr/bin/env python3
"""QA24 independent SHA-pinned actual Native STEP route auditor.

The scanner and the auditor are distinct. The audit never executes Python
calendar algorithms or pretends finite missing contact means dead source code.
"""
import argparse,copy,gzip,hashlib,json
from pathlib import Path
from collections import Counter
import stage1_qa24_frozen_input_corpus as corpus

SOURCE='560d6aa5807a7f766213a33835cce85eab0fa40c'
QA18_SHA='263a73a40afa17a8a9b1c831a01239be671d9ea0a9c331fd3f725f83cf1cfea7'
QA20_SHA='75d2ee07eaf998fcb69bcb238d5fcb2163ab8305efe4abe4378af95f41385117'
OLD_HITS=('10,44','150,20','175,38','179,44','235,11','396,17')

def need(x,msg):
    if not x:raise AssertionError(msg)

def sha(data):
    return hashlib.sha256(data).hexdigest()

def read_pinned(path,digest):
    raw=Path(path).read_bytes()
    need(sha(raw)==digest,'frozen original Native receipt SHA-256 mismatch: '+str(path))
    return json.loads(raw)

def coords_from_roles(roles):
    need(roles.get('schema')=='qa18-source-glyph-contact-v1'
         and roles.get('source_git_blob')==SOURCE
         and roles.get('dead_code_certified') is False
         and roles.get('native_original_trace_count')==49,
         'QA18 original source role claim altered')
    targets=[(int(t['x']),int(t['y']),t['source_char'])
             for t in roles['never_touched_potential_control_glyphs']]
    need(len(targets)==21 and len(set((x,y) for x,y,c in targets))==21,
         'QA18 original 21 source candidates not unique')
    need(all(len(c)==1 for x,y,c in targets),'invalid frozen source byte')
    return targets

def old_frontier(original,targets):
    need(original.get('schema')=='qa20-final-finite-native-physical-route-audit-v1'
         and original.get('native_cases')==48 and original.get('native_valid')==27
         and original.get('native_invalid')==21
         and original.get('all_original_qa18_targets')==21
         and original.get('no_dead_code_certification') is True
         and original.get('stage1_complete') is False
         and tuple(sorted(original.get('natural_source_opcode_hits',[])))==OLD_HITS,
         'QA20 accepted original six/source-count changes')
    distances=original['min_l1_by_candidate']
    need(set(distances)=={'%d,%d'%(x,y) for x,y,c in targets}
         and all(type(v) is int and v>=0 for v in distances.values()),
         'QA20 original full original source cell distance coverage missing')
    return distances

def structure(manifest,shard,targets,old,expected_rows):
    candidate_ids=['%d,%d'%(x,y) for x,y,c in targets]
    unseen=sorted(k for k in candidate_ids if k not in OLD_HITS)
    need(manifest.get('schema')=='qa24-24-disjoint-native-input-physical-route-v1'
         and manifest.get('shard')==shard
         and manifest.get('source_git_blob')==SOURCE
         and manifest.get('qa18_source_provenance_sha256')==QA18_SHA
         and manifest.get('qa20_prior_native_aggregate_sha256')==QA20_SHA
         and tuple(manifest.get('prior_natural_source_hits',[]))==OLD_HITS
         and manifest.get('fifteen_not_yet_reached')==unseen
         and manifest.get('candidate_count')==21
         and manifest.get('new_native_cases')==len(expected_rows)==6
         and manifest.get('new_native_source_mutations')==0
         and manifest.get('ip_relocated') is False
         and manifest.get('dead_code_certified') is False
         and manifest.get('stage1_complete') is False,
         'forged manifest source/corpus/stage/geometry declarations')
    need(manifest.get('targets')==[list(t) for t in targets],
         'candidate original coordinates replaced')
    records=manifest.get('records')
    need(type(records) is list and len(records)==6,
         'not exactly six original Native runs in shard')
    for record,(idx,(label,raw,valid)) in zip(records,expected_rows):
        need(record.get('label')==label and
             record.get('qa24_corpus_index')==idx and
             record.get('raw_input')==raw and
             record.get('valid') is valid and
             record.get('natural_ip_no_intervention') is True and
             record.get('path')==label+'.steps.gz' and
             record.get('output')==record.get('expected') and
             type(record.get('output')) is list and len(record['output'])==7,
             'case removed, reordered, input changed, or oracle parity forged')
        if not valid:
            need(record['output']==['-1']*7,'invalid input not rejected')
        else:
            need(len(raw.split())==4,'valid lexical input shape altered')
    return records

def physical_trace(row,folder,targets):
    name=row['label']
    path=folder/(name+'.steps.gz')
    need(path.is_file(),'Native physical STEP file not saved '+name)
    compressed=path.read_bytes()
    need(len(compressed)==row.get('compressed_bytes')
         and sha(compressed)==row.get('compressed_trace_sha256'),
         'Native gzip bytes/digest not retained '+name)
    try:decoded=gzip.decompress(compressed)
    except Exception as exc:raise AssertionError('Native STEP gzip not readable '+name) from exc
    nearest={'%d,%d'%(x,y):[10**10,None] for x,y,c in targets}
    hits={'%d,%d'%(x,y):[] for x,y,c in targets}
    count=0;runtime_matching=set()
    for line in decoded.splitlines():
        p=line.split(b'\t')
        need(len(p)==7,'unexpected Native STEP row width '+name)
        try:seq,x,y,dx,dy,opcode,string=map(int,p)
        except ValueError as exc:raise AssertionError('STEP not numeric '+name) from exc
        count+=1
        need(seq==count and 0<=opcode<=255 and string in (0,1),
             'forged or incomplete Native STEP sequence '+name)
        for tx,ty,ch in targets:
            key='%d,%d'%(tx,ty)
            d=abs(x-tx)+abs(y-ty)
            if d<nearest[key][0]:
                nearest[key]=[d,[seq,x,y,dx,dy,opcode,string]]
            if d==0:
                hits[key].append([seq,opcode,string])
                if string==0 and opcode==ord(ch):
                    runtime_matching.add(key)
    need(count>50 and row.get('steps')==count,
         'Native raw trace tick count wrong or truncated '+name)
    need(row.get('nearest')==nearest and row.get('target_step_hits')==hits,
         'Native recorded nearest/hit summary inconsistent with compressed raw STEP trace')
    return {'label':name,'steps':count,'runtime_matching':sorted(runtime_matching),
            'min_distances':{key:v[0] for key,v in nearest.items()}}

def inspect_shard(folder,shard,roles,qa20):
    targets=coords_from_roles(roles)
    old=old_frontier(qa20,targets)
    cases=corpus.cases()
    expected=[(i,item) for i,item in enumerate(cases) if i%4==shard]
    data=json.loads((folder/'qa24_manifest.json').read_text())
    records=structure(data,shard,targets,old,expected)
    proofs=[physical_trace(record,folder,targets) for record in records]
    return {'schema':'qa24-shard-physical-native-audit-v1',
            'shard':shard,'cases':len(proofs),
            'labels':[p['label'] for p in proofs],
            'real_native_steps':sum(p['steps'] for p in proofs),
            'runtime_matching_original_source_coordinates':sorted(set(
                key for p in proofs for key in p['runtime_matching'])),
            'min_distances':{key:min(p['min_distances'][key] for p in proofs)
                             for key in old},
            'static_byte_ownership_proven':False,
            'unobserved_is_dead_code':False,'stage1_complete':False}

def test_negative_controls(roles,qa20):
    targets=coords_from_roles(roles)
    old=old_frontier(qa20,targets)
    expected=[(i,v) for i,v in enumerate(corpus.cases()) if i%4==0]
    n0=[{'label':v[0],'qa24_corpus_index':i,'raw_input':v[1],'valid':v[2],
         'natural_ip_no_intervention':True,'path':v[0]+'.steps.gz',
         'output':['-1']*7 if not v[2] else ['0']*7,
         'expected':['-1']*7 if not v[2] else ['0']*7}
        for i,v in expected]
    ids=['%d,%d'%(x,y) for x,y,c in targets]
    sample={'schema':'qa24-24-disjoint-native-input-physical-route-v1',
       'shard':0,'source_git_blob':SOURCE,
       'qa18_source_provenance_sha256':QA18_SHA,
       'qa20_prior_native_aggregate_sha256':QA20_SHA,
       'prior_natural_source_hits':list(OLD_HITS),
       'fifteen_not_yet_reached':sorted(k for k in ids if k not in OLD_HITS),
       'candidate_count':21,'new_native_cases':6,'new_native_source_mutations':0,
       'ip_relocated':False,'dead_code_certified':False,
       'stage1_complete':False,'targets':[list(v) for v in targets],'records':n0}
    structure(sample,0,targets,old,expected)
    attacks=[
       ('source-edit',lambda d:d.__setitem__('source_git_blob','0'*40)),
       ('forced-ip',lambda d:d.__setitem__('ip_relocated',True)),
       ('production-mutation',lambda d:d.__setitem__('new_native_source_mutations',1)),
       ('global-stage',lambda d:d.__setitem__('stage1_complete',True)),
       ('dead-code',lambda d:d.__setitem__('dead_code_certified',True)),
       ('missing-native',lambda d:d['records'].pop()),
       ('reordered-raw-input',lambda d:d['records'][0].__setitem__('raw_input','wrong\n')),
       ('false-oracle',lambda d:d['records'][4].__setitem__('output',['bad']*7)),
       ('path-swap',lambda d:d['records'][2].__setitem__('path','../../escape.gz')),
       ('changed-targets',lambda d:d['targets'][0].__setitem__(0,999)),
       ('changed-prior-hits',lambda d:d['prior_natural_source_hits'].pop()),
       ('missing-original',lambda d:d.__setitem__('qa20_prior_native_aggregate_sha256','0'*64))]
    for name,attack in attacks:
        fake=copy.deepcopy(sample);attack(fake)
        try:structure(fake,0,targets,old,expected)
        except (AssertionError,KeyError,IndexError,TypeError):pass
        else:raise AssertionError('QA24 adversarial forged report accepted: '+name)
    # A separate actual trace grammar test; these are NOT Native executions.
    fake=b'1\t0\t0\t1\t0\t62\t0\n2\t1\t0\t1\t0\t120\t0\n'
    assert len(fake.splitlines())==2
    malformed=fake.replace(b'2\t1\t0',b'1\t1\t0')
    def check_ticks(data):
        for index,line in enumerate(data.splitlines(),1):
            fields=list(map(int,line.split(b'\t')))
            need(len(fields)==7 and fields[0]==index,'synthetic physical STEP forgery')
    check_ticks(fake)
    try:check_ticks(malformed)
    except AssertionError:pass
    else:raise AssertionError('synthetic repeated Native tick accepted')
    return len(attacks)+1

def main():
    pa=argparse.ArgumentParser()
    pa.add_argument('--qa18');pa.add_argument('--qa20')
    pa.add_argument('--shard',type=int)
    pa.add_argument('--directory')
    pa.add_argument('--aggregate',nargs='*')
    pa.add_argument('--output')
    pa.add_argument('--selftest',action='store_true')
    a=pa.parse_args()
    if a.selftest:
        # Selftest with real frozen metadata runs as part of normal audit below.
        print('QA24_SELFTEST_REQUIRES_SHA_PINNED_QA18_QA20_METADATA')
        return
    roles=read_pinned(a.qa18,QA18_SHA)
    original=read_pinned(a.qa20,QA20_SHA)
    rejects=test_negative_controls(roles,original)
    need(rejects==13,'negative test count changed')
    if a.aggregate:
        need(len(a.aggregate)==4,'QA24 must audit exactly four source shards')
        proofs=[inspect_shard(Path(folder),i,roles,original)
                for i,folder in enumerate(a.aggregate)]
        expected=set(c[0] for c in corpus.cases())
        names=[name for p in proofs for name in p['labels']]
        need(len(names)==len(expected)==24 and set(names)==expected,
             'missing or duplicate QA24 Native input')
        new=set().union(*(set(p['runtime_matching_original_source_coordinates'])
                          for p in proofs))
        old_hits=set(OLD_HITS)
        allcoords=set(original['min_l1_by_candidate'])
        result={
          'schema':'qa24-24-new-native-natural-source-frontier-aggregate-v1',
          'sha256_original_qa18_roles':QA18_SHA,
          'sha256_original_qa20_48_case_aggregate':QA20_SHA,
          'original_source_git_blob':SOURCE,
          'new_original_native_cases':24,
          'new_valid_cases':16,'new_invalid_cases':8,
          'new_real_native_steps':sum(p['real_native_steps'] for p in proofs),
          'old_natural_matching_opcodes':sorted(old_hits),
          'new_runtime_matching_source_coordinate_opcodes':sorted(new),
          'newly_observed_of_original_15':sorted(new-old_hits),
          'still_unobserved_original_15':sorted(allcoords-old_hits-new),
          'new_min_l1_by_original_source_coordinate':{
              key:min(p['min_distances'][key] for p in proofs) for key in allcoords},
          'natural_ip_no_relocation':True,'source_file_unchanged':True,
          'static_source_byte_ownership_proven':False,
          'no_dead_code_certification':True,'stage1_complete':False,
          'synthetic_forgeries_rejected':rejects}
        need(len(result['newly_observed_of_original_15'])+
             len(result['still_unobserved_original_15'])==15,
             'original remaining fifteen not fully partitioned')
        Path(a.output).write_text(json.dumps(result,sort_keys=True,indent=2)+'\n')
        print('QA24_TWENTY_FOUR_NATIVE_DISJOINT_INPUT_ROUTES_AUDITED',json.dumps(result,sort_keys=True))
        print('QA24_NO_DEAD_CODE_OR_FULL_GEOMETRIC_STAGE1_ACCEPTANCE')
    else:
        need(a.shard in range(4) and a.directory,'need exact shard and receipt directory')
        result=inspect_shard(Path(a.directory),a.shard,roles,original)
        Path(a.output).write_text(json.dumps(result,sort_keys=True,indent=2)+'\n')
        print('QA24_SIX_REAL_NATIVE_SOURCE_ROUTES_AUDITED',a.shard,result['real_native_steps'])
    print('QA24_THIRTEEN_FORGED_RECEIPTS_REJECTED')
if __name__=='__main__':main()
