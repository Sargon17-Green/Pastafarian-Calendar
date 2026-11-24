#!/usr/bin/env python3
"""Validate future outputs ONLY. No build, execution, dispatch or subprocess."""
import argparse,json,re
from pathlib import Path

def validate(panel,lines):
    expected={ (x['c'],x['t']):x['expected'] for x in panel['cases'] if x['run_new'] }
    if len(expected)!=9:raise ValueError('expected nine cases')
    seen=set()
    for line in lines:
        if not re.fullmatch(r'ISSUE29_V191_CORRECTED_ADA(?:\s+-?\d+){7}',line.strip()):raise ValueError('invalid record')
        c,t,*fields=map(int,line.split()[1:]); key=c,t
        if key not in expected or key in seen:raise ValueError('unexpected or duplicate pair')
        if fields!=expected[key]:raise ValueError(f'first difference at {key}: {fields} != {expected[key]}')
        seen.add(key)
    if seen!=set(expected):raise ValueError('incomplete panel')
    return {'status':'MATCH_PANEL_RECORDS_ONLY','matched':len(seen),'year_credit':0}

def selftest(panel):
    good=['ISSUE29_V191_CORRECTED_ADA '+' '.join(map(str,[x['c'],x['t'],*x['expected']])) for x in panel['cases'] if x['run_new']]
    assert validate(panel,good)['matched']==9
    bad=[good[:-1],good+[good[0]],['wrong marker']+good[1:], [good[0]+' 0']+good[1:], [good[0].rsplit(' ',1)[0]+' 999']+good[1:], [good[0].replace(str(panel['cases'][1]['t']),'0',1)]+good[1:]]
    for x in bad:
        try:validate(panel,x)
        except ValueError:continue
        raise AssertionError('mutation escaped')
    return {'status':'SELFTEST_ONLY_NOT_NATIVE','positive':1,'negative':len(bad),'native_calls':0}
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('panel',type=Path);p.add_argument('records',nargs='?',type=Path);a=p.parse_args(); panel=json.loads(a.panel.read_text()); print(json.dumps(validate(panel,a.records.read_text().splitlines()) if a.records else selftest(panel),indent=2))
