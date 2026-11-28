#!/usr/bin/env python3
"""Adapt archived public-soak candidate to completed exact-SHA audit artifact; pilot only."""
import collections, hashlib, json, os, pathlib, signal, subprocess, sys, time
SHA='341927541dccc940bfc5e2b4073c21c647261278'
FIXTURE='a1383b111a88203b0d652b8f0a0e9af1a8b75f25'
ARTIFACT='66a1b65e47f24bb3e20c45c4fb3b7c69c6d92c056a89f18e809b16f52a9d6504'
WORD='76396b8dc72b209c9f273d7ebbab3c6a09b3424eff8ee71acd1566680641786e'
COUNT='c0c08ac89c8faaaf589d1b3e076fe1e96405f2ad7172a15efa9d028fb43fb6f8'
def sha(x): return hashlib.sha256(x).hexdigest()
def dump(x): return json.dumps(x,ensure_ascii=False,separators=(',',':'))+'\n'
def rss(pgid):
    total=0
    for p in pathlib.Path('/proc').iterdir():
        if not p.name.isdigit(): continue
        try:
            s=(p/'stat').read_text().rsplit(')',1)[1].split()
            if int(s[2])==pgid: total+=int(s[21])*os.sysconf('SC_PAGE_SIZE')
        except (OSError,ValueError,IndexError): pass
    return total
def q(p): return "'"+str(p).replace("'","''")+"'"
def main():
    import zipfile
    root,artifact,out=map(lambda p:pathlib.Path(p).resolve(),sys.argv[1:])
    out.mkdir(parents=True,exist_ok=False)
    assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()==SHA
    assert not subprocess.check_output(['git','status','--porcelain','--untracked-files=no'],cwd=root,text=True).strip()
    raw=(root/'tests/fixtures/stage55_year5000_appendix_a_metadata.json').read_bytes()
    assert hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest()==FIXTURE
    assert sha(artifact.read_bytes())==ARTIFACT
    with zipfile.ZipFile(artifact) as z:
        assert z.testzip() is None
        r=json.loads(z.read('stage55_forward_worker/preflight/source.response.json'))
    w=r['word']; f=json.loads(raw)
    assert r['operation']=='unrank' and r['positions']==4244 and sha(r['count'].encode())==COUNT and sha(dump(w).encode())==WORD
    lo,hi=f['first_day'],f['last_day']
    assert (f['calculation_day'],lo,hi)==(-15055671,-15057702,-15053459)
    assert len(w)==4244 and len(f['month_lengths'])==45 and all(type(j) is int and 1<=j<=45 for j in w)
    assert [w.count(j) for j in range(1,46)]==f['month_lengths']
    assert sorted(range(1,46),key=w.index)==list(range(1,46))
    assert sorted(range(1,46),key=lambda j:len(w)-1-w[::-1].index(j))==list(range(1,46))
    assert len(f['month_name_indices'])==len(set(f['month_name_indices']))==45
    assert len(f['cutlet_name_indices'])==len(f['cutlet_day_lengths'])==6 and sum(f['cutlet_day_lengths'])==4244 and all(n>0 for n in f['cutlet_day_lengths'])
    seen=collections.Counter(); rows=[]; pos=0
    for cutlet,length in zip(f['cutlet_name_indices'],f['cutlet_day_lengths']):
        for day in range(1,length+1):
            j=w[pos]; seen[j]+=1; pos+=1
            rows.append(dict(cutlet_index=cutlet,cutlet_day=day,month_index=f['month_name_indices'][j-1],month_day=seen[j]))
    assert len(rows)==4244
    exp=out/'expected.json'; exp.write_text(dump(dict(calculation_day=f['calculation_day'],first_day=lo,last_day=hi,rows=rows)),encoding='utf-8')
    summary=dict(source_sha=SHA,artifact_sha256=ARTIFACT,fixture_blob=FIXTURE,word_sha256=WORD,expected_sha256=sha(exp.read_bytes()),mode='pilot',stage55_accepted=False)
    sf=out/'summary.json'; sf.write_text(dump(summary))
    log=out/'session1.jsonl'; stdout=out/'session1.log'
    cmd=['matlab','-singleCompThread','-batch',f"addpath({q(pathlib.Path(__file__).resolve().parent)}); run_stage55_public_soak_pilot({q(root)},{q(exp)},{q(log)});"]
    start=time.monotonic(); peak=0; reason=None
    with stdout.open('wb') as output:
        p=subprocess.Popen(cmd,cwd=root,stdout=output,stderr=subprocess.STDOUT,start_new_session=True,env={**os.environ,'OMP_NUM_THREADS':'1','MKL_NUM_THREADS':'1'})
        try:
            while p.poll() is None:
                peak=max(peak,rss(p.pid))
                if peak>3*1024**3: reason='RSS_LIMIT'; break
                if time.monotonic()-start>10000: reason='TIME_LIMIT'; break
                time.sleep(.5)
        finally:
            if p.poll() is None: os.killpg(p.pid,signal.SIGKILL); p.wait()
    summary.update(exit=p.returncode,reason=reason,seconds=time.monotonic()-start,peak_sampled_group_rss_bytes=peak)
    sf.write_text(dump(summary))
    assert p.returncode==0 and reason is None
    records=[json.loads(x) for x in log.read_text(encoding='utf-8').splitlines()]
    targets=[lo,lo,lo+2121,hi,lo+2121,lo]
    assert len(records)==len(targets)
    for i,(r,t) in enumerate(zip(records,targets),1):
        assert r['session']==1 and r['index']==i and r['target']==t and r['equal'] is True and r['actual']==r['expected'] and len(r['actual'])==5 and r['seconds']>=0
    assert 'PUBLIC_SOAK_PASS mode=pilot session=1 calls=6' in stdout.read_text(errors='replace')
    cold=records[0]['seconds']; warm=max(r['seconds'] for r in records[1:])
    summary.update({'pass':True,'verified_calls':6,'cold_seconds':cold,'warm_max_seconds':warm,'estimated_full_seconds':cold+4248*warm,'within_budget':cold+4248*warm<10000,'log_sha256':sha(log.read_bytes())})
    sf.write_text(dump(summary))
    print(dump(summary))
if __name__=='__main__': main()
