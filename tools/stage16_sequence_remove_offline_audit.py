#!/usr/bin/env python3
"""Independent artifact-only audit for PC-BRANCH-FALSE-ARABIC Stage16.

No imports from production or CI oracles. No native re-execution.
Does not claim that -1 sentinels prove rejection of physically truncated tuples.
"""
import argparse
import hashlib
import itertools
import json
from pathlib import Path
import re
from zipfile import ZipFile

PROJECT = 'PC-BRANCH-FALSE-ARABIC'
RUN_ID = '44634528237'
HEAD = '3737bfc2f24ac31011f825554be0f9568ca0d77f'
SOURCE = '6f28e9400f5c6e867fbe998629a02f739f91a4a9'
RUNTIME = 'eb3135565a8670cced3f6bbca4dbf7b014c45634'
ARTIFACT_HASH = '06f1fb5a7770c45b65e8cbff74e8dd8a9a3291be4a930337735df1aaed581fbe'
GIT_BLOBS = {
    'src/bigint.false':'1e8de1147ba46cd0eb75a47f24673bbd9783946f',
    'src/monster_bootstrap.false':'923b07573789e80efc6c4c12e9e03accc462f3a5',
    'test/stage16_sequence_remove_14.false':'bdc95f06e5ccfaaf1e5e81c26b059261d2f8bf7a',
}
BAD = {'zero_length':'E_REMOVE_LENGTH','seven_length':'E_REMOVE_LENGTH',
       'zero_position':'E_REMOVE_POSITION','high_position':'E_REMOVE_POSITION',
       'missing_sequence_sentinel':'E_REMOVE_MISSING_SEQUENCE',
       'missing_position_sentinel':'E_REMOVE_MISSING_POSITION'}
FINAL = 'STAGE16_REMOVE_12_PLUS_TWO_REPLAYS_OK'


def digest(x): return hashlib.sha256(x).hexdigest()


def gitblob(x):
    return hashlib.sha1(b'blob '+str(len(x)).encode()+b'\0'+x).hexdigest()


def check_cases(cases):
    if len(cases) != 14: raise ValueError('wrong anchor/replay count')
    checks=0
    for i,c in enumerate(cases):
        seq,p=c['sequence'],c['position']
        if not (1<=len(seq)<=6 and 1<=p<=len(seq)): raise ValueError('domain')
        # Standalone oracle: independently remove at the selected index.
        picked=seq[p-1]
        rem=[x for j,x in enumerate(seq,1) if j != p]
        if c['chosen']!=picked or c['remaining']!=rem: raise ValueError('corrupt oracle')
        if c['label']!=f'STAGE16_REMOVE_{i:02d}_OK': raise ValueError('wrong label')
        if c['replay'] != (i>=12): raise ValueError('replay flag')
        checks+=1
    if cases[12] != dict(cases[0], label='STAGE16_REMOVE_12_OK', replay=True):
        raise ValueError('replay of first anchor mismatch')
    if cases[13] != dict(cases[11], label='STAGE16_REMOVE_13_OK', replay=True):
        raise ValueError('replay of last anchor mismatch')
    return checks


def audit(path):
    raw=Path(path).read_bytes()
    if digest(raw)!=ARTIFACT_HASH: raise ValueError('artifact SHA256 mismatch')
    with ZipFile(path) as z:
        if z.testzip() is not None: raise ValueError('ZIP CRC failure')
        receipt=json.loads(z.read('evidence.json'))
        oracle=json.loads(z.read('oracle.json'))
        if receipt['project_id']!=PROJECT or receipt['stage']!=16: raise ValueError('project identity')
        for field,value in [('github_run_id',RUN_ID),('github_sha',HEAD),
                            ('source_pin',SOURCE),('source_observed',SOURCE),
                            ('runtime_pin',RUNTIME),('runtime_observed',RUNTIME)]:
            if str(receipt[field])!=value: raise ValueError('pin: '+field)
        if z.read('source_observed.txt').decode().strip()!=SOURCE: raise ValueError('source evidence')
        if z.read('runtime_observed.txt').decode().strip()!=RUNTIME: raise ValueError('runtime evidence')
        if z.read('compiler_exit_code.txt').strip()!=b'0': raise ValueError('compiler')
        if z.read('preflight.txt').strip()!=b'ORIGINAL_UNICODE_PICK_PREFLIGHT_PASS': raise ValueError('unicode preflight')
        if z.read('unicode_pick.stdout.txt').strip()!=b'4': raise ValueError('unicode output')
        combined=z.read('native.false')
        if digest(combined)!=receipt['combined_sha256']: raise ValueError('combined SHA256')
        at=0
        matched={}
        # Partition exact input bytes by SHA256, then prove each Git blob SHA-1.
        for fn,gh in GIT_BLOBS.items():
            h=hashlib.sha256()
            matches=[]
            for i in range(at,len(combined)):
                h.update(combined[i:i+1])
                if h.hexdigest()==receipt['source_blob_sha256'][fn]:
                    matches.append(i+1)
            if len(matches)!=1: raise ValueError('source boundary ambiguous: '+fn)
            end=matches[0]
            part=combined[at:end]
            if gitblob(part)!=gh: raise ValueError('source not matching pinned GitHub blob: '+fn)
            if combined[end:end+1]!=b'\n': raise ValueError('source delimiter')
            matched[fn]={'sha256':digest(part),'git_blob_sha1':gitblob(part),'bytes':len(part)}
            at=end+1
        if at != len(combined): raise ValueError('unexpected source suffix')
        if matched['test/stage16_sequence_remove_14.false']['sha256'] != receipt['fixture_sha256']:
            raise ValueError('fixture blob mismatch')
        if combined.count(b'=~["STAGE16_REMOVE_')!=160: raise ValueError('fixture assertion count')
        if receipt['positive_assertions_embedded']!=160: raise ValueError('receipt assertions')
        independent=check_cases(oracle['cases'])
        if independent!=14 or oracle['design_exhaustive_cases']!=5039:
            raise ValueError('oracle count')
        permutation_count=sum(len(p) for n in range(1,7)
                              for p in itertools.permutations(range(1,n+1)))
        if permutation_count!=5039: raise ValueError('independent domain exhaustion')
        expected=[c['label'] for c in oracle['cases']]
        stdout=z.read('native.stdout.txt').decode('utf-8')
        labels=re.findall(r'STAGE16_REMOVE_\d{2}_OK',stdout)
        if labels!=expected or receipt['actual_labels']!=expected: raise ValueError('ordered native markers')
        if stdout.count(FINAL)!=1 or not stdout.rstrip().endswith(FINAL):
            raise ValueError('final marker')
        if re.search(r'STAGE16_REMOVE_[A-Z0-9_]+_FAIL',stdout): raise ValueError('failure marker')
        if z.read('native.exit_code.txt').strip()!=b'0' or z.read('native.stderr.txt').strip():
            raise ValueError('native exit/stderr')
        if z.read('mutant.exit_code.txt').strip()!=b'1' or b'STAGE16_REMOVE_00_RESULT_FAIL' not in z.read('mutant.stdout.txt'):
            raise ValueError('negative mutant was not killed')
        for name,marker in BAD.items():
            if z.read(name+'.exit_code.txt').strip()!=b'1': raise ValueError('invalid exit: '+name)
            if z.read(name+'.stdout.txt').decode()!=marker: raise ValueError('invalid marker: '+name)
            if FINAL in z.read(name+'.stdout.txt').decode(): raise ValueError('invalid final: '+name)
        if receipt['stage16_full_acceptance'] is not False or receipt['truncated_tuple_rejection_verified'] is not False:
            raise ValueError('unsupported acceptance claim')
        # Corrupt an oracle expectation and prove the independent verifier refuses it.
        corrupt=json.loads(json.dumps(oracle['cases']))
        corrupt[0]['chosen']+=1
        detected=False
        try: check_cases(corrupt)
        except ValueError: detected=True
        if not detected: raise ValueError('corrupted oracle negative control survived')
    return {
        'project_id':PROJECT,'stage':16,'run_id':RUN_ID,'head':HEAD,
        'artifact_sha256':ARTIFACT_HASH,'zip_crc':'PASS','source_git_blobs':matched,
        'source_files_verified':len(matched),'native_result_cases':12,
        'deterministic_replays':2,'native_ordered_labels':len(expected),
        'embedded_comparisons':160,'negative_controls':7,
        'independent_anchor_checks':independent,'independent_permutation_position_cases':permutation_count,
        'corrupted_oracle_rejected':detected,
        'native_verified':True,'stage16_full_acceptance':False,
        'contract_gap':'physical truncated tuple rejection unproven: only explicit -1 sentinels',
        'verdict':'NATIVE_VERIFIED_WITH_CONTRACT_GAP',
    }


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('artifact',type=Path)
    parser.add_argument('--output',type=Path)
    a=parser.parse_args()
    result=audit(a.artifact)
    text=json.dumps(result,sort_keys=True,ensure_ascii=False,indent=2)+'\n'
    if a.output: a.output.write_text(text,encoding='utf-8')
    print(text,end='')

if __name__=='__main__': main()
