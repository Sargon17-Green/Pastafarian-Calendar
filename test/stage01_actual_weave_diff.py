#!/usr/bin/env python3
"""Eight new dates taken from the *actual* year-5000 month weaving.

The pinned independent Python normative implementation supplies both the
selected structural witnesses and the expected five fields. Original Fortran
is invoked separately. This is narrow QA, never full Stage1 acceptance.
"""
from __future__ import annotations
import argparse
import hashlib
import importlib.util
import json
import resource
import subprocess
import sys
from pathlib import Path

PROJECT_ID='PC-BRANCH-FORTRAN-ENGLISH'
PARENT_SHA='3ed11b0a4dc0ea83b0c5d4bcbd01e99a9da68923'
PYTHON_BLOB='d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53'
FOUNDATION=-15055671
FIELDS=('year_number','cutlet_name_index','day_in_cutlet',
        'month_name_index','day_in_month')
# The known static targets in existing direct, expanded, context and boundary tests.
PRIOR_OFFSETS=frozenset((-2032,-2033,-2031,-2032-137,-1,0,1,137,
                        271,2212,2213,2214,2213+137,-3192,3192))

def check(ok,why):
    if not ok: raise AssertionError(why)

def sha_blob(raw):
    return hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest()

def pinned(path):
    raw=path.read_bytes()
    check(sha_blob(raw)==PYTHON_BLOB,'independent Python blob SHA mismatch')
    spec=importlib.util.spec_from_file_location('pinned_stage01_weaving',path)
    check(spec is not None and spec.loader is not None,'reference import')
    mod=importlib.util.module_from_spec(spec)
    sys.modules[spec.name]=mod
    spec.loader.exec_module(mod)
    check(mod.FOUNDATION_DAY==FOUNDATION,'reference foundation mismatch')
    return mod.NormativeCalendar()

def selected_months(m):
    check(m>=8,'insufficient actual months')
    months=((m+4)//5,(2*m+4)//5,(3*m+4)//5,m)
    check(len(set(months))==4 and min(months)>=1 and max(months)<=m,
          'non-distinct month sample')
    return months

def pick(weaving,first_day):
    check(bool(weaving),'empty weaving')
    months=max(weaving)
    check(set(weaving)==set(range(1,months+1)),'missing month IDs')
    old={FOUNDATION+x for x in PRIOR_OFFSETS}
    seen=set()
    rows=[]
    for month in selected_months(months):
        offsets=[i for i,x in enumerate(weaving) if x==month]
        check(len(offsets)>=4,'illegal month length')
        for kind,candidates in (('first',offsets),('last',list(reversed(offsets)))):
            unused=[i for i in candidates if i not in seen and first_day+i not in old]
            check(bool(unused),'no new target for month '+str(month))
            i=unused[0]
            seen.add(i)
            rows.append({'month_id':month,'occurrence':kind,'day_offset':i,
                         'target_day':first_day+i})
    check(len(rows)==len(seen)==8,'eight unique new targets')
    return rows

def field(lines,key):
    x=[line[len(key):] for line in lines if line.startswith(key)]
    check(len(x)==1,'missing/duplicate '+key)
    return x[0]

def decode(stdout,target):
    lines=stdout.splitlines()
    check(field(lines,'STAGE01_ACTUAL_WEAVE_CALC=')==str(FOUNDATION),
          'calculation context mismatch')
    check(field(lines,'STAGE01_ACTUAL_WEAVE_TARGET=')==str(target),
          'target mismatch')
    parts=field(lines,'STAGE01_ACTUAL_WEAVE_FIELDS=').split(',')
    check(len(parts)==5,'field count')
    return tuple(int(x) for x in parts)

def memory_limit():
    bound=1024*1024*1024
    resource.setrlimit(resource.RLIMIT_AS,(bound,bound))

def original_fortran(exe,target):
    p=subprocess.run((str(exe.resolve()),str(target)),
                     stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,
                     check=False,timeout=65,preexec_fn=memory_limit)
    check(p.returncode==0,'Fortran exit '+str(p.returncode)+': '+p.stderr[-400:])
    return decode(p.stdout,target)

def selftest():
    check(sha_blob(b'abc')=='f2ba8f84ab5c1bce84a7b441cb1959cfc7093b7f',
          'hashing')
    check(selected_months(45)==(9,18,27,45),'45 month sample')
    cases=pick(tuple(m for m in range(1,9) for _ in range(4)),
               FOUNDATION+10000)
    check(len(cases)==len({r['target_day'] for r in cases})==8,'8 cases')
    check([r['month_id'] for r in cases]==[2,2,4,4,5,5,8,8],
          'month sample labels')
    text='STAGE01_ACTUAL_WEAVE_CALC=-15055671\nSTAGE01_ACTUAL_WEAVE_TARGET=42\nSTAGE01_ACTUAL_WEAVE_FIELDS=5000,1,2,3,4\n'
    check(decode(text,42)==(5000,1,2,3,4),'frame')
    try: decode(text+'STAGE01_ACTUAL_WEAVE_TARGET=42\n',42)
    except AssertionError: pass
    else: raise AssertionError('duplicate accepted')
    print('STAGE01_ACTUAL_WEAVE_HARNESS=7/7')

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--reference',type=Path)
    ap.add_argument('--fortran-exe',type=Path)
    ap.add_argument('--self-test',action='store_true')
    a=ap.parse_args()
    if a.self_test:
        selftest()
        return 0
    check(a.reference is not None and a.fortran_exe is not None,'args')
    oracle=pinned(a.reference)
    year=oracle.year5000(FOUNDATION)
    structure=oracle.build_year_structure(FOUNDATION,year)
    weaving=tuple(structure.month_weaving)
    months=structure.month_count
    length=year.close_gate_day-year.open_gate_day
    check(len(weaving)==length,'actual year length')
    check(months==len(structure.month_lengths)==max(weaving),
          'month count')
    check(tuple(weaving.count(i) for i in range(1,months+1))
          ==tuple(structure.month_lengths),'month frequencies')
    chosen=pick(weaving,year.open_gate_day+1)
    rows=[]
    total=0
    for i,row in enumerate(chosen,1):
        target=row['target_day']
        answer=oracle.calendar_date_ids(FOUNDATION,target)
        expected=tuple(int(getattr(answer,k)) for k in FIELDS)
        actual=original_fortran(a.fortran_exe,target)
        matched=sum(x==y for x,y in zip(expected,actual))
        total+=matched
        rows.append({**row,'calculation_day':FOUNDATION,
                     'expected':dict(zip(FIELDS,expected)),
                     'fortran':dict(zip(FIELDS,actual)),
                     'matched_fields':matched})
        print(f'STAGE01_ACTUAL_WEAVE_CASE={i}/8 MONTH_ID={row["month_id"]} MATCHED_FIELDS={matched}/5',flush=True)
    out=Path('build/stage01-actual-weave.json')
    out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps({'project_id':PROJECT_ID,'parent_sha':PARENT_SHA,
                  'reference_blob':PYTHON_BLOB,'full_stage1_accepted':False,
                  'actual_year':5000,'actual_month_count':months,
                  'actual_year_days':length,'month_count_45_observed':months==45,
                  'cases':rows},indent=2)+'\n',encoding='utf-8')
    print(f'STAGE01_ACTUAL_WEAVE_STRUCTURE MONTHS={months} DAYS={length}')
    print(f'STAGE01_ACTUAL_WEAVE_DIFFERENTIAL={sum(r["matched_fields"]==5 for r in rows)}/8 CASES; {total}/40 FIELDS')
    print('STAGE01_ACTUAL_WEAVE_QA_ONLY_NOT_FULL_STAGE1_ACCEPTANCE')
    return 0 if total==40 else 1

if __name__=='__main__':
    try: sys.exit(main())
    except Exception as e:
        print('STAGE01_ACTUAL_WEAVE_ERROR='+repr(e),file=sys.stderr)
        sys.exit(1)
