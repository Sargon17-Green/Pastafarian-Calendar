#!/usr/bin/env python3
"""QA-only root fixtures and bounded Native checks. Never reruns Foundation H45.
Usage: python3 scripts/verify_general_h_roots.py --prepare-only NEW_DIR
       python3 scripts/verify_general_h_roots.py --native NEW_DIR
Five host-derived calendar geometries plus small and boundary probes; not year-selection QA.
"""
import argparse, hashlib, itertools, json, math, pathlib, shutil, subprocess, time

VECTORS = [
 ('year4999', [123,123,122,120,123,120,120,123,121,123,123,122,122,122,123,123,123,118,120,121,122,122,123,117,121,120,123,123,118,120,119,123,119,121]),
 ('year5001', [123,120,121,121,119,123,123,122,118,123,120,123,123,118,120,117,123,118,120,121,121,123,123,123,123,116,122,120,120,122,122,120,123,122,123,114,123,123,122,123,122,114,118,123,123,123]),
 ('creation_minus1234', [108,109,99,123,76,83,115,117,110,50,113,52,66,111,109,117,90,95,104,105,113,113,13,122,96,80,110,122,25,116,121,103,66,118,76,75,117,90]),
 ('creation_plus1234', [121,50,70,74,13,101,98,119,98,74,118,75,106,14,64,119,45,75,122,78,72,95,119,101,113,14,71,34,43,41,119,75,69,95,123,119,89,73,56,109,118,113,36]),
 ('year5002', [80,81,121,105,102,24,82,83,112,9,118,64,111,120,92,67,114,123,74,71,39,116,19,123,78,42,86,72,86,108,64,114,32,114,119,111,119,94,98,103,110,69,122,120]),
 ('one_min', [4]), ('one_max', [123]), ('two_min', [4,4]), ('three_min', [4,4,4]),
 ('max_months_min', [4]*47), ('max_geometry', [123]*46+[120]),
]
BENCH_BLOB = 'dea946e1f1e1bca0ffde60acf6f042f88750368b'
ORACLE_BLOB = 'e228f43f2d33b9af59c5fb232281ca403455ca5c'

def sha(b): return hashlib.sha256(b).hexdigest()
def git_blob(b): return hashlib.sha1(f'blob {len(b)}\0'.encode()+b).hexdigest()

def root(lengths):
    assert 1 <= len(lengths) <= 47 and all(4 <= v <= 123 for v in lengths) and sum(lengths) <= 5778
    caps = list(itertools.accumulate(v-1 for v in lengths))
    nxt = [1]*(caps[-1]+1)
    for s in range(len(lengths)-2,-1,-1):
        v=lengths[s+1]; running=0; row=[]
        for n in range(caps[s]+1):
            running += math.comb(n+v-2,v-2)*nxt[n+v-1]
            row.append(running)
        nxt=row
    return nxt[lengths[0]-1],sum(c+1 for c in caps)

def brute(lengths):
    # Enumeration independent of H, only tiny probes.
    counts=list(lengths); total=sum(counts); m=len(counts)
    def visit(w):
        if len(w)==total:
            first=[w.index(i) for i in range(m)]; last=[total-1-w[::-1].index(i) for i in range(m)]
            return int(first==sorted(first) and last==sorted(last))
        result=0
        for i in range(m):
            if counts[i]:
                counts[i]-=1; result+=visit(w+[i]); counts[i]+=1
        return result
    return visit([])

def run(cmd,log,seconds):
    with log.open('wb') as out:
        try: p=subprocess.run(cmd,stdout=out,stderr=subprocess.STDOUT,timeout=seconds,check=False)
        except subprocess.TimeoutExpired: return 'TIMEOUT'
    return p.returncode

def main():
    p=argparse.ArgumentParser()
    g=p.add_mutually_exclusive_group(required=True); g.add_argument('--prepare-only',action='store_true'); g.add_argument('--native',action='store_true'); p.add_argument('directory',type=pathlib.Path); a=p.parse_args()
    d=a.directory.resolve(); d.mkdir(parents=False,exist_ok=False)
    manifest={'scope':'HOST_GEOMETRY_ROOT_ONLY_STAGE1_NOT_ACCEPTED','oracle_blob_reference':ORACLE_BLOB,'bench_blob':BENCH_BLOB,'cases':[]}
    for name,l in VECTORS:
        t=time.monotonic(); r,records=root(l)
        assert 0<r.bit_length()<=32095
        if name in ('one_min','two_min','three_min'): assert r==brute(l)
        geo=(' '.join(map(str,[len(l),*l]))+'\n').encode(); expected=r.to_bytes(4096,'big')
        (d/(name+'.geometry')).write_bytes(geo); (d/(name+'.expected')).write_bytes(expected)
        entry={'name':name,'months':len(l),'days':sum(l),'records':records,'bits':r.bit_length(),'geometry_sha256':sha(geo),'root_sha256':sha(expected),'host_seconds':round(time.monotonic()-t,3),'native':'NOT_RUN'}
        manifest['cases'].append(entry); print(json.dumps(entry),flush=True)
    def save(): (d/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    save()
    if a.prepare_only: return
    bench=pathlib.Path(__file__).resolve().parent.parent/'tests/tb_weave_native_general_h.sv'
    if git_blob(bench.read_bytes())!=BENCH_BLOB: raise SystemExit('bench blob mismatch')
    if not shutil.which('iverilog') or not shutil.which('vvp'): raise SystemExit('Icarus absent; Native NOT_RUN')
    vvp=d/'general_h.vvp'; rc=run(['iverilog','-g2012','-s','tb_weave_native_general_h','-o',str(vvp),str(bench)],d/'compile.log',60)
    manifest['compile']=rc; save()
    if rc!=0: raise SystemExit('compile failed: '+str(rc))
    failed=False
    # Tiny probes first; every other case independently bounded, no H45.
    for entry in sorted(manifest['cases'],key=lambda x:x['records']):
        name=entry['name']; actual=d/(name+'.actual'); log=d/(name+'.log')
        rc=run(['vvp',str(vvp),'+geometry='+str(d/(name+'.geometry')),'+root='+str(actual)],log,240)
        marker=f"GENERAL_H_CANDIDATE_PASS months={entry['months']} days={entry['days']} records={entry['records']} root_bits={entry['bits']}"
        ok=rc==0 and marker in log.read_text(errors='replace') and actual.is_file() and actual.read_bytes()==(d/(name+'.expected')).read_bytes()
        entry['native']='PASS' if ok else 'TIMEOUT' if rc=='TIMEOUT' else 'FAIL'; entry['exit']=rc; failed |= not ok; save()
    for name,geo,marker in [('zero_months','0\n','GENERAL_H_MONTH_COUNT'),('short_month','1 3\n','GENERAL_H_LENGTH'),('long_month','1 124\n','GENERAL_H_LENGTH'),('too_many_months','48\n','GENERAL_H_MONTH_COUNT'),('trailing','1 4 5\n','GENERAL_H_TRAILING_GEOMETRY')]:
        path=d/(name+'.geometry'); path.write_text(geo); actual=d/(name+'.actual'); log=d/(name+'.log'); rc=run(['vvp',str(vvp),'+geometry='+str(path),'+root='+str(actual)],log,30)
        ok=isinstance(rc,int) and rc!=0 and marker in log.read_text(errors='replace') and not actual.exists(); manifest.setdefault('negative',{})[name]='PASS' if ok else 'FAIL'; failed |= not ok; save()
    if failed: raise SystemExit('Native root QA incomplete/failed')
    print('NATIVE_GENERAL_H_ROOTS_PASS cases=11 negatives=5 SCOPE=HOST_GEOMETRY_ONLY STAGE1_NOT_ACCEPTED')

if __name__=='__main__': main()
