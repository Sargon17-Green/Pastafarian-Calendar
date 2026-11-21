#!/usr/bin/env python3
"""Bounded 4-case original Fortran versus SHA-pinned independent Python normative differential.

Targets are the previously untested immediate neighbors of the 4999/5001
boundaries. This is QA only, never blanket Stage1 acceptance.
"""
from __future__ import annotations
import argparse, hashlib, importlib.util, json, resource, subprocess, sys
from pathlib import Path

FOUNDATION = -15055671
PYTHON_BLOB = 'd58298c6b7be58fc1d1e2d64a0d203b7c42e4d53'
CASES = ((-1,-2033),(1,-2031),(-1,2212),(1,2214))
FIELDS = ('year_number','cutlet_name_index','day_in_cutlet','month_name_index','day_in_month')

def require(ok, why):
    if not ok: raise ValueError(why)

def days(i):
    require(1 <= i <= 4, 'index')
    c,t = CASES[i-1]
    return FOUNDATION+c, FOUNDATION+t

def exact_five(s, prefix):
    x = [line[len(prefix):] for line in s.splitlines() if line.startswith(prefix)]
    require(len(x)==1, 'missing or duplicate '+prefix)
    parts = x[0].split(',')
    require(len(parts)==5, 'wrong field count')
    return tuple(int(v) for v in parts)

def reference(path):
    data = path.read_bytes()
    blob = hashlib.sha1(('blob '+str(len(data))+'\0').encode()+data).hexdigest()
    require(blob == PYTHON_BLOB, 'reference blob SHA mismatch')
    spec = importlib.util.spec_from_file_location('pinned_boundary_reference',path)
    require(spec is not None and spec.loader is not None, 'reference import')
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name]=module
    spec.loader.exec_module(module)
    require(int(module.FOUNDATION_DAY)==FOUNDATION,'foundation mismatch')
    return module

def memory(mib):
    def apply():
        limit=mib*1024*1024
        resource.setrlimit(resource.RLIMIT_AS,(limit,limit))
    return apply

def execute(argv, mib):
    p = subprocess.run(argv,capture_output=True,text=True,check=False,timeout=75,
                       preexec_fn=memory(mib))
    require(p.returncode==0,f'exit {p.returncode} out={p.stdout[-400:]} err={p.stderr[-400:]}')
    return p.stdout

def selftest():
    assert len(CASES)==len(set(CASES))==4
    assert set(t for _,t in CASES)=={-2033,-2031,2212,2214}
    assert set(c for c,_ in CASES)=={-1,1}
    assert set(t for _,t in CASES[:2])=={-2032-1,-2032+1}
    assert set(t for _,t in CASES[2:])=={2213-1,2213+1}
    assert days(1)==(FOUNDATION-1,FOUNDATION-2033)
    assert exact_five('Y=1,2,3,4,5\n','Y=')==(1,2,3,4,5)
    try: exact_five('Y=1,2,3,4,5\nY=1,2,3,4,5\n','Y=')
    except ValueError: pass
    else: raise AssertionError('duplicate accepted')
    print('STAGE01_BOUNDARY_NEIGHBOR_HARNESS=8/8')

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--reference',type=Path)
    ap.add_argument('--fortran-exe',type=Path)
    ap.add_argument('--worker',type=int)
    ap.add_argument('--self-test',action='store_true')
    args=ap.parse_args()
    if args.self_test: selftest(); return 0
    require(args.reference is not None,'reference required')
    if args.worker is not None:
        m=reference(args.reference)
        calc,target=days(args.worker)
        ans=m.NormativeCalendar().calendar_date_ids(calc,target)
        result=tuple(int(getattr(ans,k)) for k in FIELDS)
        print(f'STAGE01_NEIGHBOR_ORACLE_INPUT={args.worker},{calc},{target}')
        print('STAGE01_NEIGHBOR_ORACLE_FIELDS='+','.join(map(str,result)))
        return 0
    require(args.fortran_exe is not None,'fortran executable required')
    reference(args.reference)
    rows=[]
    for i in range(1,5):
        calc,target=days(i)
        ref=execute([sys.executable,str(Path(__file__).resolve()),'--worker',str(i),
                     '--reference',str(args.reference.resolve())],1536)
        require(ref.splitlines().count(f'STAGE01_NEIGHBOR_ORACLE_INPUT={i},{calc},{target}')==1,
                'oracle input framing')
        expected=exact_five(ref,'STAGE01_NEIGHBOR_ORACLE_FIELDS=')
        out=execute([str(args.fortran_exe.resolve()),str(i)],1024)
        for prefix,value in [('STAGE01_NEIGHBOR_CASE=',i),('STAGE01_NEIGHBOR_CALC=',calc),
                             ('STAGE01_NEIGHBOR_TARGET=',target)]:
            require(out.splitlines().count(prefix+str(value))==1,'fortran input framing')
        actual=exact_five(out,'STAGE01_NEIGHBOR_FIELDS=')
        matched=sum(x==y for x,y in zip(expected,actual))
        rows.append({'case':i,'calculation_day':calc,'target_day':target,
                     'reference':dict(zip(FIELDS,expected)),'fortran':dict(zip(FIELDS,actual)),
                     'matched_fields':matched})
        print(f'STAGE01_NEIGHBOR_CASE={i} MATCHED_FIELDS={matched}/5',flush=True)
    Path('build').mkdir(exist_ok=True)
    Path('build/stage01-boundary-neighbors.json').write_text(
        json.dumps({'project_id':'PC-BRANCH-FORTRAN-ENGLISH','full_stage1_accepted':False,
                    'cases':rows},indent=2)+'\n',encoding='utf-8')
    matched=sum(r['matched_fields'] for r in rows)
    print(f'STAGE01_BOUNDARY_NEIGHBORS={sum(r["matched_fields"]==5 for r in rows)}/4 CASES; {matched}/20 EXACT FIELDS')
    print('STAGE01_BOUNDARY_NEIGHBORS_QA_ONLY_NOT_FULL_STAGE1_ACCEPTANCE')
    return 0 if matched==20 else 1

if __name__=='__main__': sys.exit(main())
