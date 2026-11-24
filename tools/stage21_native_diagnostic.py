#!/usr/bin/env python3
"""Stage21 independent Python fixtures + bounded original-runtime diagnostic.
This runner is NOT a Stage21 acceptance gate. It preserves actual observations.
Short paths instrument only the outer drop count; full paths use unmodified source.
"""
import hashlib
import itertools
import json
import os
from pathlib import Path
import resource
import subprocess
import sys
import time

M=(1<<127)-1
ORDERS=list(itertools.permutations(range(6)))
K=(0,1,2,3,4,0)
E=Path("evidence/stage21_diagnostic")
FILES=("src/bigint.false","src/monster_bootstrap.false",
       "tools/stage21_native_diagnostic.py","tools/stage21_corrected_neighbor_oracle.mjs",
       "evidence/stage21_corrected_neighbor_math_qa_2026-11-25.json",
       "RUN_STAGE21.md",".github/workflows/false-arabic-stage21-diagnostic.yml")
MARKER='STAGE21_DIAGNOSTIC_CASE_OK'
LIMIT=2*1024**3

def sha(data):
    return hashlib.sha256(data).hexdigest()

def literal(n):
    return str(-n)+'_' if n<0 else str(n)

def limbs(n):
    if n==0:
        return [0,1,0]
    sign=-1 if n<0 else 1
    n=abs(n)
    ds=[]
    while n:
        n,d=divmod(n,512)
        ds.append(d)
    return [sign,len(ds),*ds]

def case(name):
    if name=='ones':
        return [1]*6,[1]*46,[[1]*5 for _ in range(46)]
    if name=='reverse':
        return [2,3,5,7,11,13],[720]*46,[[2,3,5,7,11] for _ in range(46)]
    if name=='boundary':
        return [M,M-1,1,512,513,M-5],[M-i for i in range(46)],[[M,1,512,513,M-1] for _ in range(46)]
    raise ValueError(name)

def oracle(q,steps):
    b,d,s=q
    b=list(b)
    for i in range(steps):
        t=d[i]
        order=ORDERS[(t-1)%720]
        ring=[b[j] for j in order]
        next_b=[None]*6
        for p,id_ in enumerate(order):
            x=ring[p]
            l,r=ring[p-1],ring[(p+1)%6]
            save=lambda z:1+(z-1)%M
            aux=save(t*t+x*s[i][p]+(i+1)*(2*p+3)) if p<3 else 2
            next_b[id_]=save(x*x+2*l+3*r+aux+t+s[i][K[p]]+5*l*r+(i+1)*(p+1))
        b=next_b
    return b,[j+1 for j in order]

def ptr(i):
    return ('ptr',i)

def expression(v):
    return 'x;'+str(v[1])+'+' if isinstance(v,tuple) else literal(v)

def fixture(q,steps,invalid=None):
    """Generate a flat physical heap, retaining input cell addresses for assertions."""
    b,d,s=q
    cells=[]
    def alloc(v):
        at=len(cells)
        cells.extend(v)
        return ptr(at)
    def big(value,bad=None):
        v=limbs(value)
        if bad=='zero_sign': v=[0,1,0]
        if bad=='negative_sign': v=[-1,1,1]
        if bad=='digit512': v=[1,1,512]
        if bad=='digit_negative': v=[1,1,-1]
        if bad=='top_zero': v=[1,2,1,0]
        if bad=='overflow': v=limbs(M+1)
        if bad=='length0': v=[1,0,1]
        if bad=='length16': v=[1,16]+[1]*16
        return alloc(v)
    bh=[big(v,invalid if j==0 else None) for j,v in enumerate(b)]
    dh=[big(v) for v in d]
    rows=[]
    for j,row in enumerate(s):
        hs=[big(v) for v in row]
        header=4 if invalid=='row4' and j==0 else 6 if invalid=='row6' and j==0 else 5
        if header==6: hs.append(big(1))
        rows.append(alloc([header,*hs]))
    headers={'bowls5':5,'bowls7':7,'visible45':45,'visible47':47,'stones45':45,'stones47':47}
    if invalid=='bowls7': bh.append(big(1))
    if invalid=='visible47': dh.append(big(1))
    if invalid=='stones47': rows.append(rows[-1])
    bp=alloc([headers[invalid] if invalid in ('bowls5','bowls7') else 6,*bh])
    dp=alloc([headers[invalid] if invalid in ('visible45','visible47') else 46,*dh])
    sp=alloc([headers[invalid] if invalid in ('stones45','stones47') else 46,*rows])
    arg=alloc([bp,dp,sp])
    lines=['{ Independent Stage21 fixture, all record storage allocated. }','z;x:']
    lines += [expression(v)+'a;!' for v in cells]
    lines += [expression(arg)+'b:', 'b;38h;!!o:']
    if invalid:
        lines += ['"STAGE21_INVALID_ACCEPTED"10,','[z;0>][%z;1-z:]#']
        return '\n'.join(lines)+'\n',None,0
    expected,order=oracle(q,steps)
    checks=0
    def eq(expr,want,tag):
        nonlocal checks
        lines.append(expr+'r:r;'+expression(want)+'-0=~["'+tag+'"0 0/]?')
        checks+=1
    eq('o;g;!',2,'STAGE21_OUT_RECORD_FAIL')
    lines += ['o;1+g;!y:o;2+g;!w:']
    eq('y;g;!',6,'STAGE21_OUT_BOWLS_HEADER_FAIL')
    eq('w;g;!',6,'STAGE21_OUT_ORDER_HEADER_FAIL')
    for j,v in enumerate(expected,1):
        lines.append(f'y;{j}+g;!t:')
        for k,cell in enumerate(limbs(v)):
            eq(f't;{k}+g;!',cell,f'STAGE21_OUT_BOWL_{j}_CELL_{k}_FAIL')
    for j,v in enumerate(order,1):
        eq(f'w;{j}+g;!',v,f'STAGE21_OUT_ORDER_{j}_FAIL')
    for j,v in enumerate(cells):
        eq(f'x;{j}+g;!',v,f'STAGE21_INPUT_CELL_{j}_FAIL')
    lines += ['"'+MARKER+'"10,','[z;0>][%z;1-z:]#']
    return '\n'.join(lines)+'\n',{'bowls':list(map(str,expected)),'order':order},checks

def limits():
    resource.setrlimit(resource.RLIMIT_AS,(LIMIT,LIMIT))
    resource.setrlimit(resource.RLIMIT_CORE,(0,0))

def execute(name,program,seconds,want=MARKER,exitcode=0):
    p=E/(name+'.false')
    p.write_bytes(program)
    start=time.monotonic()
    try:
        cp=subprocess.run(['upstream/false_int','-e',str(p)],capture_output=True,
                          timeout=seconds,preexec_fn=limits,check=False)
        ec,out,err=cp.returncode,cp.stdout,cp.stderr
    except subprocess.TimeoutExpired as exc:
        ec,out,err=124,exc.stdout or b'',exc.stderr or b''
    elapsed=time.monotonic()-start
    (E/(name+'.stdout.txt')).write_bytes(out)
    (E/(name+'.stderr.txt')).write_bytes(err)
    (E/(name+'.exit_code.txt')).write_text(str(ec)+'\n')
    normalized=out.replace(b'\r',b'').replace(b'\n',b'')
    passed=ec==exitcode and (normalized==want.encode() and not err if exitcode==0 else want.encode() in normalized and b'STAGE21_INVALID_ACCEPTED' not in normalized)
    return {'exit_code':ec,'elapsed_seconds':round(elapsed,3),'peak_child_rss_kib_cumulative':resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss,'timeout_seconds':seconds,'address_space_limit_bytes':LIMIT,'program_sha256':sha(program),'stdout_sha256':sha(out),'stderr_sha256':sha(err),'passed':passed}

def main():
    assert oracle(case('ones'),1)[0]==[19,22,25,19,20,21]
    assert oracle(case('reverse'),1)[0]==[974,813,886,519531,519786,519468]
    for name in ('ones','reverse','boundary'):
        body,expected,checks=fixture(case(name),46)
        assert body.count(MARKER)==1 and len(expected['bowls'])==6 and checks>1000
    if '--self-check' in sys.argv:
        print('STAGE21_FIXTURE_SELF_CHECK_PASS');return
    E.mkdir(parents=True,exist_ok=True)
    pin=os.environ['SOURCE_PIN'];runtime=os.environ['RUNTIME_PIN']
    assert subprocess.check_output(['git','rev-parse','HEAD']).decode().strip()==pin
    assert (E/'runtime_observed.txt').read_text().strip()==runtime
    assert (E/'preflight.txt').read_text().strip()=='ORIGINAL_UNICODE_PICK_PREFLIGHT_PASS'
    blobs={}
    for path in FILES:
        actual=Path(path).read_bytes()
        assert actual==subprocess.check_output(['git','show',f'{pin}:{path}']),path
        blobs[path]=actual
    bootstrap=blobs['src/monster_bootstrap.false']
    old=b'1i:\n [i;47<][\n  w;i;+g;!t:'
    new=b'1i:\n [i;2<][\n  w;i;+g;!t:'
    assert bootstrap.count(old)==1,'short instrumentation anchor'
    prefix=blobs['src/bigint.false']+b'\n'+bootstrap+b'\n'
    short=blobs['src/bigint.false']+b'\n'+bootstrap.replace(old,new)+b'\n'
    report={'stage':21,'project_id':'PC-BRANCH-FALSE-ARABIC','source_pin':pin,'runtime_pin':runtime,'source_sha256':{p:sha(v) for p,v in blobs.items()},'production_prefix_sha256':sha(prefix),'short_instrumented_prefix_sha256':sha(short),'run_id':os.getenv('GITHUB_RUN_ID'),'native_gate_accepted':False,'stage21_accepted':False,'physical_pointer_safety_assessed':False,'diagnostic':{}}
    def persist():
        (E/'diagnostic.json').write_text(json.dumps(report,indent=2,sort_keys=True)+'\n')
    def run(name,case_name,steps,seconds):
        q=case(case_name)
        body,expected,checks=fixture(q,steps)
        record={'input':{'bowls':list(map(str,q[0])),'visible':list(map(str,q[1])),'stones':[list(map(str,r)) for r in q[2]]},'expected':expected,'assertions':checks,'steps':steps,'instrumented':steps!=46}
        (E/(name+'.fixture.json')).write_text(json.dumps(record,indent=2)+'\n')
        report['diagnostic'][name]=dict(record=record,**execute(name,(short if steps==1 else prefix)+body.encode(),seconds))
        persist()
        return report['diagnostic'][name]['passed']
    # These are conservative diagnostic caps, not acceptance thresholds.
    if not run('short_ones','ones',1,180):
        sys.exit('STAGE21_SHORT_ONES_NOT_VERIFIED')
    if not run('short_reverse','reverse',1,180):
        sys.exit('STAGE21_SHORT_REVERSE_NOT_VERIFIED')
    if not run('full_ones','ones',46,600):
        sys.exit('STAGE21_FULL_ONES_NOT_VERIFIED')
    print('STAGE21_MEASUREMENT_COMPLETED_NOT_ACCEPTED')

if __name__=='__main__':
    main()
