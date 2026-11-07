#!/usr/bin/env python3
"""QA25 independent physical source-byte and Native instruction receipt auditor.

Verify every original QA24 STEP against fresh Native SHA, and every observed
source candidate's value against chronological real Program.space.put history.
Never call absent source bytes 'dead' and never infer global mutation ownership.
"""
import argparse
import copy
import gzip
import hashlib
import json
from pathlib import Path

import stage1_qa24_frozen_input_corpus as c24

SOURCE='560d6aa5807a7f766213a33835cce85eab0fa40c'
QA18='263a73a40afa17a8a9b1c831a01239be671d9ea0a9c331fd3f725f83cf1cfea7'
QA20='75d2ee07eaf998fcb69bcb238d5fcb2163ab8305efe4abe4378af95f41385117'
QA24_RUN=39841651046

def need(ok,msg):
    if not ok:raise AssertionError(msg)

def sha(data):
    return hashlib.sha256(data).hexdigest()

def load_json(path):
    return json.loads(Path(path).read_bytes())

def pinned(path,digest):
    data=Path(path).read_bytes()
    need(sha(data)==digest,'signed original receipt changed: '+str(path))
    return json.loads(data)

def original_source():
    raw=Path('src/interleaved_work_counts.b98').read_bytes()
    blob=hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest()
    need(blob==SOURCE,'original production source blob changed')
    return raw.splitlines()

def original_targets(roles,src):
    need(roles['schema']=='qa18-source-glyph-contact-v1'
         and roles['source_git_blob']==SOURCE
         and roles['dead_code_certified'] is False
         and len(roles['never_touched_potential_control_glyphs'])==21,
         'QA18 21 original source candidates changed')
    out=[]
    for c in roles['never_touched_potential_control_glyphs']:
        x,y=int(c['x']),int(c['y'])
        op=ord(c['source_char'])
        need(src[y][x]==op,'signed original source byte mismatch')
        out.append((x,y,op))
    need(len(set((x,y) for x,y,op in out))==21,'duplicate source coordinate')
    return out

def original_qa24(folder,shard,candidates):
    orig=load_json(folder/'qa24_manifest.json')
    need(orig.get('schema')=='qa24-24-disjoint-native-input-physical-route-v1'
         and orig.get('shard')==shard
         and orig.get('source_git_blob')==SOURCE
         and orig.get('qa18_source_provenance_sha256')==QA18
         and orig.get('qa20_prior_native_aggregate_sha256')==QA20
         and orig.get('ip_relocated') is False
         and orig.get('new_native_source_mutations')==0
         and orig.get('stage1_complete') is False
         and orig.get('targets')==[[x,y,chr(op)] for x,y,op in candidates],
         'original accepted QA24 source/target anchor drifted')
    cases=c24.cases()
    expected=[(i,c) for i,c in enumerate(cases) if i%4==shard]
    need(len(orig['records'])==len(expected)==6,'original QA24 shard incomplete')
    for old,(i,(label,raw,valid)) in zip(orig['records'],expected):
        need(old['label']==label and old['raw_input']==raw
             and old['valid'] is valid and old['qa24_corpus_index']==i
             and old['natural_ip_no_intervention'] is True,
             'original accepted Native raw input identity mismatch')
    return orig

def verify_one(old,row,folder,initial):
    label=old['label']
    need(row.get('label')==label
         and row.get('raw_input')==old['raw_input']
         and row.get('valid') is old['valid']
         and row.get('native_output')==old['output']
         and row.get('actual_native_steps')==old['steps']
         and row.get('no_test_only_write') is True
         and row.get('production_source_mutated') is False
         and row.get('forced_ip_relocation') is False,
         'QA25 did not replay exact accepted QA24 Native program')
    compressed=(folder/old['path']).read_bytes()
    need(sha(compressed)==old['compressed_trace_sha256']
         and row.get('original_gzip_sha256')==sha(compressed),
         'original QA24 gzipped Native route mutated')
    raw=gzip.decompress(compressed)
    lines=raw.splitlines()
    need(len(lines)==old['steps'] and
         row.get('qa24_original_raw_steps_sha256')==sha(raw)
         and row.get('qa25_replayed_raw_steps_sha256')==sha(raw),
         'complete new physical Native STEP replay differs from signed QA24')
    original={f'{x},{y}':b for x,y,b in initial}
    writes=row.get('candidate_put_events')
    fetches=row.get('candidate_fetches')
    need(type(writes) is list and type(fetches) is list,
         'source-put/source-fetch chronological evidence missing')
    need(type(row.get('actual_space_put_calls')) is int
         and row['actual_space_put_calls']>=len(writes),
         'native FungeSpace.put calls implausible')
    parsed=[]
    for i,ln in enumerate(lines,1):
        nums=ln.split(b'\t')
        need(len(nums)==7,'malformed original accepted Native STEP')
        vals=tuple(map(int,nums))
        need(vals[0]==i and vals[-1] in (0,1) and 0<=vals[-2]<=255,
             'wrong original native tick/opcode/stringmode')
        parsed.append(vals)
    prev={}
    for j,w in enumerate(writes):
        xy=w.get('coordinate')
        need(type(xy) is list and len(xy)==2 and
             all(type(n) is int for n in xy),
             'candidate physical put target malformed')
        key='%d,%d'%tuple(xy)
        tick=w.get('tick')
        need(key in original and type(tick) is int and 1<=tick<=len(parsed),
             'native write to noncandidate or beyond observed execution')
        if j:
            need(writes[j-1]['tick']<=tick,
                 'Native physical candidate write chronology reversed')
        seq,x,y,dx,dy,op,mode=parsed[tick-1]
        need(w.get('origin_ip')==[x,y] and w.get('origin_opcode')==op,
             'physical Native put provenance not tied to the actual STEP')
        oldval=prev.get(key,original[key])
        newval=w.get('written_value')
        need(type(newval) is int and
             w.get('previous_value')==oldval
             and w.get('before_original_byte') is (oldval==original[key])
             and w.get('after_original_byte') is (newval==original[key]),
             'physical put old/new source-byte mutation lineage forged')
        prev[key]=newval
    # Rebuild all candidate fetches directly from original Native STEPs.
    observed=[];writers={}
    next_write=0
    for tick,x,y,dx,dy,op,mode in parsed:
        key='%d,%d'%(x,y)
        if key not in original:continue
        while next_write<len(writes) and writes[next_write]['tick']<tick:
            w=writes[next_write]
            writers['%d,%d'%tuple(w['coordinate'])]=w
            next_write+=1
        writer=writers.get(key)
        expected=writer['written_value'] if writer else original[key]
        need(op==expected,
             'runtime Native source candidate fetch not explained by original byte/put history '+label)
        observed.append({
            'tick':tick,'coordinate':[x,y],
            'runtime_opcode':op,'original_opcode':original[key],
            'stringmode':bool(mode),'previous_native_put':writer is not None,
            'latest_prior_put_tick':writer['tick'] if writer else None,
            'matching_original_opcode':op==original[key],
            'original_byte_owned':writer is None and op==original[key],
            'effective_original_instruction':
                writer is None and op==original[key] and mode==0})
    need(fetches==observed,'Native source candidate exact opcode/ownership receipt altered '+label)
    hit={f"{o['coordinate'][0]},{o['coordinate'][1]}" for o in observed
         if o['effective_original_instruction']}
    overwritten=sum(w['previous_native_put'] for w in observed)
    return {'label':label,'steps':len(parsed),'native_put_calls':row['actual_space_put_calls'],
            'watched_candidate_puts':len(writes),'candidate_fetches':len(observed),
            'prior_written_candidate_fetches':overwritten,
            'unmodified_original_executable_opcodes':sorted(hit)}

def verify_shard(folder,shard,roles,src):
    initial=original_targets(roles,src)
    orig=original_qa24(folder,shard,initial)
    r=load_json(folder/'qa25_native_owner_receipts.json')
    need(r.get('schema')=='qa25-physical-21-original-source-cell-ownership-v1'
         and r.get('source_git_blob')==SOURCE
         and r.get('native_qa24_original_run')==QA24_RUN
         and r.get('prior_qa18_source_roles_sha256')==QA18
         and r.get('prior_qa20_original_aggregate_sha256')==QA20
         and r.get('original_qa24_shard')==shard
         and r.get('native_programs_replayed')==6
         and r.get('original_21_source_candidate_locations')==
             [[x,y,chr(op)] for x,y,op in initial]
         and r.get('all_original_inputs_unchanged') is True
         and r.get('ip_relocated') is False
         and r.get('production_source_edited') is False
         and r.get('static_byte_origin_proof_scoped_to_actual_put_calls') is True
         and r.get('other_mutation_apis_excluded_globally') is False
         and r.get('stage1_complete') is False,
         'missing or overclaimed Native physical byte ownership receipt')
    records=r.get('real_native_provenance_records')
    need(type(records) is list and len(records)==6,'six exact real program runs not preserved')
    reports=[verify_one(old,now,folder,initial) for old,now in zip(orig['records'],records)]
    return {'shard':shard,'programs':6,'steps':sum(z['steps'] for z in reports),
            'puts':sum(z['native_put_calls'] for z in reports),
            'target_puts':sum(z['watched_candidate_puts'] for z in reports),
            'prior_written_candidate_fetches':sum(z['prior_written_candidate_fetches'] for z in reports),
            'original_byte_owned_coords':sorted(set(k for z in reports for k in z['unmodified_original_executable_opcodes'])),
            'rows':reports}

def selftest(folder,shard,roles,src):
    # Mutate real accepted evidence and demand rejections. Never fake PASS.
    initial=original_targets(roles,src)
    orig=original_qa24(folder,shard,initial)
    row=load_json(folder/'qa25_native_owner_receipts.json')['real_native_provenance_records'][0]
    verify_one(orig['records'][0],row,folder,initial)
    attacks=[
      ('source-mismatch',lambda t:t.__setitem__('qa25_replayed_raw_steps_sha256','0'*64)),
      ('wrong-label',lambda t:t.__setitem__('label','forged')),
      ('false-output',lambda t:t.__setitem__('native_output',['42']*7)),
      ('false-program-step-count',lambda t:t.__setitem__('actual_native_steps',1)),
      ('disallow-mutation',lambda t:t.__setitem__('no_test_only_write',False)),
      ('drop-fetch',lambda t:t['candidate_fetches'].pop() if t['candidate_fetches'] else t.__setitem__('qa24_original_raw_steps_sha256','0'*64)),
      ('fake-owner',lambda t:t['candidate_fetches'][0].__setitem__('original_byte_owned',False) if t['candidate_fetches'] else t.__setitem__('actual_space_put_calls',-1)),
      ('fake-candidate-put-count',lambda t:t.__setitem__('actual_space_put_calls',-1))]
    for name,attack in attacks:
        forged=copy.deepcopy(row)
        attack(forged)
        try:verify_one(orig['records'][0],forged,folder,initial)
        except (AssertionError,IndexError,KeyError,TypeError,ValueError):pass
        else:raise AssertionError('forged original Native source provenance accepted '+name)
    return len(attacks)

def main():
    p=argparse.ArgumentParser()
    p.add_argument('--directory')
    p.add_argument('--shard',type=int)
    p.add_argument('--aggregate',nargs='*')
    p.add_argument('--output')
    a=p.parse_args()
    need(a.output,'output path required')
    src=original_source()
    if a.aggregate:
        need(len(a.aggregate)==4,'require all four original QA24 Native shards')
        dirs=[Path(d) for d in a.aggregate]
        roles=pinned(dirs[0]/'qa18_glyph_roles.json',QA18)
        need(all(sha((d/'qa18_glyph_roles.json').read_bytes())==QA18 for d in dirs)
             and all(sha((d/'qa20_native_48_aggregate.json').read_bytes())==QA20 for d in dirs),
             'shard-specific original source lineage changed')
        reports=[verify_shard(d,i,roles,src) for i,d in enumerate(dirs)]
        controls=sum(selftest(d,i,roles,src) for i,d in enumerate(dirs))
        original_coords=sorted(set(k for r in reports for k in r['original_byte_owned_coords']))
        result={'schema':'qa25-native-24-executions-original-byte-owned-source-frontier-v1',
            'production_source_git_blob':SOURCE,'original_qa24_run':QA24_RUN,
            'actual_native_replays':24,'full_original_step_replays':sum(r['steps'] for r in reports),
            'actual_space_put_calls':sum(r['puts'] for r in reports),
            'real_put_events_to_original_candidate_cells':sum(r['target_puts'] for r in reports),
            'fetched_candidate_cells_previously_p_written':sum(r['prior_written_candidate_fetches'] for r in reports),
            'original_byte_owned_executable_source_coords':original_coords,
            'original_21_source_candidates':21,
            'individual_forgery_controls_rejected':controls,
            'global_mutation_api_coverage':False,'source_dead_code_certified':False,
            'global_stage1_state_owner_proven':False,'stage1_complete':False,
            'shard_reports':reports}
        need(result['full_original_step_replays']==776706
             and controls==32,'original twenty-four native proof or 32 forensic negative controls missing')
        Path(a.output).write_text(json.dumps(result,sort_keys=True,indent=2)+'\n')
        print('QA25_TWENTY_FOUR_ORIGINAL_NATIVE_BYTE_OWNERSHIP_RUNS_AUDITED',json.dumps({
          'steps':result['full_original_step_replays'],'put_calls':result['actual_space_put_calls'],
          'candidate_puts':result['real_put_events_to_original_candidate_cells'],
          'owned_coords':original_coords},sort_keys=True))
    else:
        need(a.shard in range(4) and a.directory,'specific Native shard missing')
        folder=Path(a.directory)
        roles=pinned(folder/'qa18_glyph_roles.json',QA18)
        need(sha((folder/'qa20_native_48_aggregate.json').read_bytes())==QA20,
             'QA20 source identity mismatch')
        report=verify_shard(folder,a.shard,roles,src)
        controls=selftest(folder,a.shard,roles,src)
        need(controls==8,'eight original Native adversarial mutations did not fail')
        result={'schema':'qa25-shard-original-byte-ownership-audit-v1',
                'original_run':QA24_RUN,'shard':a.shard,
                'report':report,'negative_controls_rejected':controls,
                'stage1_complete':False}
        Path(a.output).write_text(json.dumps(result,sort_keys=True,indent=2)+'\n')
        print('QA25_SIX_FRESH_REAL_NATIVE_BYTE_OWNER_REPLAYS_AUDITED',a.shard,report['steps'])
    print('QA25_EIGHT_FORGED_SOURCE_OWNERSHIP_RECEIPTS_REJECTED_PER_SHARD')
    print('QA25_NO_DEAD_CODE_OR_GLOBAL_STAGE1_OWNERSHIP_ACCEPTANCE')
if __name__=='__main__':main()
