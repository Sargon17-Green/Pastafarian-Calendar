#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA23B: bounded fresh Native replay of all four unfinished QA22 counterfactuals.

No source file changes, no forced instruction-pointer movement, no emulated
execution. First reproduce every exact 125000-post-step QA22 checkpoint.
Then continue each actual PyFunge Program to a larger explicit finite cap.
"""
from __future__ import print_function
import hashlib
import json
import os
import sys
import stage1_qa22_native_mutant_continuations as base

SOURCE_BLOB = '560d6aa5807a7f766213a33835cce85eab0fa40c'
QA22_SHA256 = 'ff85b07dab957de7a97ac32d917ed72f458a0a1ef1827b2744be176debf9d554'
ORIGINAL_CAP = 125000
NEW_CAP = 500000
UNFINISHED = ((10,44),(179,44),(235,11),(396,17))

def require(cond, why):
    if not cond:
        raise AssertionError(why)

def sha256_file(path):
    return hashlib.sha256(open(path,'rb').read()).hexdigest()

def token_prefix_compatible(tokens):
    return len(tokens) <= 7 and tokens == ['-1'] * len(tokens)

def run_one(source, witness, old):
    coord = tuple(witness['target'])
    require(coord in UNFINISHED and old['target'] == witness['target'],
            'unrecognized or reordered original Native candidate')
    require(old['mutant_terminated'] is False and old['bounded_unresolved'] is True
            and old['post_intervention_steps'] == ORIGINAL_CAP,
            'QA22 original case was not pending at original bound')
    require(old['original_prefix_sha256'] == witness['prefix_sha256']
            and old['original_tick'] == witness['first_tick']
            and old['original_trace_sha256'] == witness['original_gzip_sha256']
            and old['input'] == witness['input']
            and old['opcode'] == witness['opcode'],
            'QA22 predecessor witness was substituted')

    p = base.replay_to_prefix(source,witness)
    require(base.state(p) == old['before_native'],
            'new native prefix state disagrees with QA22')
    ip = p['program'].ips[0]
    require(int(p['program'].space.get(ip.position)) == ord(old['opcode']),
            'natural original byte not present before Native modification')
    p['program'].space.put(ip.position,ord('z'))
    base.tick(p)
    require(base.state(p) == old['test_only_z_after_one_native_step'],
            'first native mutation state not identical to accepted QA22')
    for j in range(ORIGINAL_CAP):
        require(bool(p['program'].ips),'new Native copy halted before exact QA22 bound')
        base.tick(p)
    original_tokens = p['stdout'].getvalue().split()
    require(original_tokens == old['mutant_output_so_far'],
            'Native stdout at QA22 checkpoint is not byte-for-byte token-identical')
    require(bool(p['program'].ips),
            'QA22 cap reported unresolved but fresh Native copy has halted')
    print('QA23B_REPLAYED_EXACT_QA22_BOUND',list(coord),ORIGINAL_CAP,len(original_tokens))
    sys.stdout.flush()

    milestones=[]
    more=0
    while p['program'].ips and ORIGINAL_CAP+more < NEW_CAP:
        base.tick(p)
        more += 1
        if more % 50000 == 0:
            tokens=p['stdout'].getvalue().split()
            milestones.append({'post_steps':ORIGINAL_CAP+more,
                               'emitted_tokens':len(tokens),
                               'stdout_prefix_compatible':token_prefix_compatible(tokens)})
            print('QA23B_NATIVE_BOUNDARY',list(coord),ORIGINAL_CAP+more,len(tokens))
            sys.stdout.flush()
    final_tokens=p['stdout'].getvalue().split()
    done=not bool(p['program'].ips)
    compatible=token_prefix_compatible(final_tokens)
    outcome=('TERMINATED_IDENTICAL' if done and final_tokens==['-1']*7
             else 'TERMINATED_DIFFERENT' if done
             else 'BOUND_IRREVERSIBLE_OUTPUT_DIVERGENCE' if not compatible
             else 'BOUND_UNRESOLVED_PREFIX_COMPATIBLE')
    return {'target':list(coord),'opcode':old['opcode'],
            'original_case':old['original_case'],
            'first_tick':witness['first_tick'],
            'prefix_sha256':witness['prefix_sha256'],
            'qa22_mutant_after_one_step':old['test_only_z_after_one_native_step'],
            'qa22_125000_post_steps_replayed':True,
            'qa22_125000_stdout_tokens':original_tokens,
            'new_native_programs':1,
            'more_native_steps':more,'total_post_intervention_steps':ORIGINAL_CAP+more,
            'mutant_terminated':done,'mutant_stdout_tokens':final_tokens,
            'stdout_prefix_compatible':compatible,
            'irreversible_stdout_divergence':not compatible,
            'outcome':outcome,'milestones':milestones,
            'source_modified':False,'ip_relocated':False,
            'infinite_loop_proven':False,'global_necessity_proven':False}

def main(wpath,oldpath,outdir):
    require(sha256_file(oldpath)==QA22_SHA256,'original QA22 Native receipt digest drifted')
    source=open('src/interleaved_work_counts.b98','rb').read()
    require(base.blob(source)==SOURCE_BLOB,'original source Git blob differs')
    w=json.load(open(wpath,'rb'))
    q=json.load(open(oldpath,'rb'))
    require(w['source_git_blob']==SOURCE_BLOB
            and w['schema']=='qa21-native-six-original-natural-execution-witnesses-v1'
            and q['schema']=='qa22-six-input-origin-rejection-continuations-v1'
            and len(w['entries'])==len(q['records'])==6
            and q['stage1_complete'] is False,
            'original QA21/QA22 case manifests altered')
    original_pairs=list(zip(w['entries'],q['records']))
    selected=[(e,r) for e,r in original_pairs if tuple(e['target']) in UNFINISHED]
    require(len(selected)==len(UNFINISHED)
            and set(tuple(e['target']) for e,r in selected)==set(UNFINISHED),
            'one of the four unfinished Native cases missing')
    base.MAX_STEPS = NEW_CAP + max(e['first_tick'] for e,r in selected) + 2
    records=[]
    for e,r in selected:
        records.append(run_one(source,e,r))
        # Retain completed Native results even if a later case fails.
        out={'schema':'qa23b-four-native-post-qa22-bounded-continuations-v1',
             'source_git_blob':SOURCE_BLOB,'original_qa22_receipt_sha256':QA22_SHA256,
             'original_qa22_run':39774061424,'original_qa22_step_cap':ORIGINAL_CAP,
             'new_post_intervention_step_cap':NEW_CAP,
             'four_expected_records':len(UNFINISHED),
             'new_native_programs':len(records),'records':records,
             'no_ip_relocation':True,'production_source_modified':False,
             'stage1_complete':False,'no_infinite_loop_claim':True,
             'global_dead_code_proof':False}
        with open(os.path.join(outdir,'qa23b_native_continuations.json'),'wb') as f:
            f.write(json.dumps(out,sort_keys=True,indent=2)+'\n')
    print('QA23B_FOUR_PENDING_NATIVE_MUTANTS_REPLAYED_AND_BOUNDED')
    print('QA23B_NO_UNBOUNDED_NONTERMINATION_OR_STAGE1_ACCEPTANCE')
if __name__=='__main__':
    require(len(sys.argv)==4,'usage: QA23B.py ORIGINAL_WITNESS.json QA22_NATIVE.json OUTDIR')
    main(sys.argv[1],sys.argv[2],sys.argv[3])
