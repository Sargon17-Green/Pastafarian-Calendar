#!/usr/bin/env python3
"""Read-only Stage2 result classifier. No interpreter execution, no PASS inference."""
from __future__ import annotations
import json, sys, zipfile
PROJECT='PC-BRANCH-FALSE-ARABIC'
SHA='d05b84ab06a667e2b06d452dc73ca8c7b0837767'
MARKERS=('DISCOVERY01_SHAPE_M0_2M0_3M0_MPLUS1_1','DISCOVERY01_RECREATED_NATIVE_SHAPE_VERIFIED')
def require(condition, message):
    if not condition: raise ValueError(message)
def classify(path: str)->dict:
    with zipfile.ZipFile(path) as z:
        require(z.testzip() is None, 'ZIP CRC mismatch')
        names={n.replace('\\','/').rsplit('/',1)[-1]:n for n in z.namelist()}
        require('evidence.json' in names, 'missing evidence.json')
        info=json.loads(z.read(names['evidence.json']).decode('utf-8-sig'))
        require(info['project_id']==PROJECT, 'PROJECT_ID mismatch')
        require(info['target_sha']==SHA, 'target SHA mismatch')
        exitcode=info.get('runner_exit_code')
        native=info.get('native_exit_code')
        if exitcode==3 and native is None:
            return {'classification':'ENVIRONMENT_MISSING','native_pass':False,'runner_exit_code':3}
        if exitcode!=0 or native!=0 or info.get('observed_sha')!=SHA:
            return {'classification':'NATIVE_NOT_ACCEPTED','native_pass':False,'runner_exit_code':exitcode}
        require('native_stdout.txt' in names, 'Native stdout missing')
        stdout=z.read(names['native_stdout.txt']).decode('utf-8-sig')
        require(all(marker in stdout for marker in MARKERS), 'missing expected Native marker')
        require('combined_sha256.txt' in names, 'missing source SHA evidence')
        source_hash=z.read(names['combined_sha256.txt']).decode('utf-8-sig').split()[0]
        require(len(source_hash)==64 and all(ch in '0123456789abcdef' for ch in source_hash.lower()), 'invalid source hash format')
        require(info.get('combined_source_sha256')==source_hash, 'source hash evidence inconsistent')
        runtime_hash=info.get('runtime_sha256','')
        require(len(runtime_hash)==64 and all(ch in '0123456789abcdef' for ch in runtime_hash.lower()), 'runtime hash missing')
        return {'classification':'NATIVE_SHAPE_VERIFIED','native_pass':True,'runner_exit_code':0}
if __name__=='__main__':
    print(json.dumps(classify(sys.argv[1]),ensure_ascii=False,sort_keys=True))
