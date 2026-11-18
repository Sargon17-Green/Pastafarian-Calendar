#!/usr/bin/env python3
"""Bounded read-only differential validation; never calculates a date itself."""
from __future__ import annotations
import argparse
import json
from pathlib import Path
from audit_ts_original_v094 import C, audit_pair, load_catalog, read_rows, sha

SCHEMA='PASTAFARI_TWO_ENGINE_READINESS_ORIGINAL_SAMPLE_V101/1'
SAMPLES=('-15055671','-15055658','-15056671','-15054671')
YEAR_FIRST=-15057702
YEAR_LAST=-15053459

def sample_index(t:str)->int:
    if type(t) is not str or t not in SAMPLES: raise ValueError('nonapproved original target day')
    i=SAMPLES.index(t)
    if not YEAR_FIRST<=int(t)<=YEAR_LAST: raise ValueError('target outside frozen candidate year')
    return i

def audit_one(folder:Path,day:str)->dict:
    index=sample_index(day)
    catalog=load_catalog(folder/f'original-typescript-{index}-catalog.json')
    ts,ts_raw=read_rows(folder/f'original-typescript-{index}-raw.jsonl',1)[0]
    py,py_raw=read_rows(folder/f'original-python-{index}-raw.jsonl',1)[0]
    pn,pn_raw=read_rows(folder/f'original-python-{index}-normalized.jsonl',1)[0]
    result=audit_pair(ts,ts_raw,py,py_raw,pn,pn_raw,catalog,day)
    return {
        'schema':SCHEMA,
        'status':'ONE_UNCHANGED_ORIGINAL_SOURCE_DAY_MATCH_NOT_YEAR',
        'case_index':index,
        'calculation_day':C,
        'target_day':day,
        'canonical_fields':result['five_fields'],
        'typescript_native_names':{
            'cutlet':result['typescript_cutlet_name_raw'],
            'month':result['typescript_month_name_raw']},
        'python_native_names':{
            'cutlet':pn['cutlet_name_raw'],'month':pn['month_name_raw']},
        'original_typescript_raw_sha256':sha(ts_raw),
        'original_python_raw_sha256':sha(py_raw),
        'original_python_normalized_sha256':sha(pn_raw),
        'whole_original_years_certified':0,
        'algorithmic_independence_certified':False,
        'windows_resource_admission_certified':False,
    }

def main()->None:
    p=argparse.ArgumentParser()
    p.add_argument('--evidence-root',type=Path,required=True)
    p.add_argument('--target-day',required=True)
    p.add_argument('--verdict-out',type=Path,required=True)
    a=p.parse_args()
    verdict=audit_one(a.evidence_root.resolve(strict=True),a.target_day)
    with a.verdict_out.open('x',encoding='utf8',newline='\n') as f:
        json.dump(verdict,f,sort_keys=True,ensure_ascii=False,indent=2)
        f.write('\n')
        f.flush()
    print('V101_ORIGINAL_SAMPLE_ONE_DAY_MATCH_NOT_YEAR='+verdict['target_day'])

if __name__=='__main__':
    main()
