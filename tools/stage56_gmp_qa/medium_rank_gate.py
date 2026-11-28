#!/usr/bin/env python3
"""Medium-only isolated GMP qualification. No production provider wiring.
Oracle: memoized legal single-symbol transitions over remaining multiplicities,
not the candidate's ordered-ending factor or suffix-row recurrence.
Candidate arithmetic is identical to accepted small QA, with widened bounds.
"""
import functools, hashlib, json, math, os, pathlib, signal, subprocess, sys, tempfile, time
import rank_microgate as small
import row_microgate as row

SHAPES = [[4,4,4,4,4], [2,3,4,5,6,2], [1,3,1,4,2,5,3],
          [2]*8, [8]*6, [12,10,9,8,7,6]]
MAX_STATES=1_000_000
CAP=512*1024**2

def candidate():
    p=small.PHP
    changes=[
        ('$this->n>4||$this->size>10', '$this->n>8||$this->size>60'),
        ('$m>3)', '$m>12)'),
        ('SMALL_RANK_RESULT', 'MEDIUM_RANK_RESULT'),
    ]
    for old,new in changes:
        if p.count(old)!=1: raise RuntimeError("candidate source drift: "+old)
        p=p.replace(old,new)
    return p

class Oracle:
    def __init__(self,L):
        self.L=tuple(L)
        if not 1<=len(L)<=8 or any(type(x) is not int or not 1<=x<=12 for x in L) or sum(L)>60:
            raise ValueError("oracle shape")
        if math.prod(x+1 for x in L)>MAX_STATES: raise ValueError("oracle state budget")
        self.count=functools.lru_cache(maxsize=None)(self._count)
    def step(self,s,x):
        if type(x) is not int or not 0<=x<len(s) or not s[x]: return None
        # First occurrence: all lower IDs must already have appeared.
        if s[x]==self.L[x] and any(s[j]==self.L[j] for j in range(x)): return None
        # Last occurrence: all lower IDs must have been exhausted.
        if s[x]==1 and any(s[:x]): return None
        return s[:x]+(s[x]-1,)+s[x+1:]
    def _count(self,s):
        if not any(s): return 1
        total=0
        for x in range(len(s)):
            t=self.step(s,x)
            if t is not None: total+=self.count(t)
        return total
    def prefix(self,p):
        s=self.L
        for x in p:
            s=self.step(s,x)
            if s is None: return 0
        return self.count(s)
    def unrank(self,r):
        if not 1<=r<=self.count(self.L): raise ValueError("rank")
        s=self.L; p=[]
        while any(s):
            for x in range(len(s)):
                t=self.step(s,x)
                if t is None: continue
                b=self.count(t)
                if r<=b:
                    p.append(x); s=t; break
                r-=b
            else: raise RuntimeError("oracle exhausted")
        if r!=1: raise RuntimeError("oracle residual")
        return p

def oracle_selftest():
    # Exhaustive independent validation of state oracle only, not a Native rerun.
    shapes=row.SMALL+[[1,1,1,1],[2,2,2,2],[3,2,1,2],[2,3,2,3]]
    for L in shapes:
        o=Oracle(L); words=small.enumerate_words(L)
        if o.count(o.L)!=len(words): raise RuntimeError("oracle count")
        expected={}
        for i,w in enumerate(words,1):
            if o.unrank(i)!=w: raise RuntimeError("oracle ordering")
            for k in range(len(w)+1):
                p=tuple(w[:k]); expected[p]=expected.get(p,0)+1
        for p,c in expected.items():
            if o.prefix(p)!=c: raise RuntimeError("oracle prefix")
            if len(p)<sum(L):
                for x in range(len(L)):
                    if o.prefix(p+(x,))!=expected.get(p+(x,),0): raise RuntimeError("oracle sibling")
    return len(shapes)

def digest(s):
    return hashlib.sha256(s.encode()).hexdigest()

def worker(payload):
    # Wall clock includes JSON encoding, subprocess startup, GMP decimal
    # conversion, stdout capture and JSON decoding; RSS is OS peak of PHP.
    start=time.monotonic()
    data=json.dumps(payload,separators=(",",":"))
    with tempfile.TemporaryDirectory(prefix="stage56-gmp-medium-") as d:
        rss=pathlib.Path(d)/"rss"
        p=subprocess.Popen(["/usr/bin/time","-f","%M","-o",str(rss),"php",
            "-d","memory_limit=512M","-r",candidate()],stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,
            preexec_fn=row.cap,start_new_session=True)
        try: stdout,stderr=p.communicate(data,timeout=180)
        except BaseException:
            try: os.killpg(p.pid,signal.SIGKILL)
            except ProcessLookupError: pass
            p.communicate()
            raise
        if p.returncode or stderr:
            raise RuntimeError(f"worker exit={p.returncode} stderr={stderr[:1000]} stdout={stdout[:1000]}")
        peak=int(rss.read_text().strip())*1024
        out=json.loads(stdout); elapsed=time.monotonic()-start
        if not 0<peak<=CAP or not 0<elapsed<=180: raise RuntimeError("worker budget")
        return out,dict(elapsed_seconds=elapsed,peak_rss_bytes=peak,
                        input_sha256=digest(data),output_sha256=digest(stdout))

def main():
    row.source_lock()
    if not sys.platform.startswith("linux"): raise RuntimeError("Linux required")
    row.emit(dict(type="oracle_selftest",shapes=oracle_selftest()))
    total_rank=total_prefix=total_negative=0; large=False
    for L in SHAPES:
        start=time.monotonic(); o=Oracle(L); c=o.count(o.L)
        if c<=0: raise RuntimeError("oracle empty")
        large |= c>2**63-1
        # Deterministic endpoints, quantiles and neighbors of root-path
        # partition boundaries; no random or floating-point rank generation.
        ranks={1,c,min(2,c),max(1,c-1)}
        ranks.update(1+(c-1)*i//8 for i in range(1,8))
        # Add neighbors of internal sibling boundaries along median path.
        median=o.unrank((c+1)//2); p=[]; offset=0
        for x in median:
            for j in range(x):
                offset+=o.prefix(p+[j])
                for r in (offset,offset+1):
                    if 1<=r<=c: ranks.add(r)
            p.append(x)
        ranks=sorted(ranks); words=[o.unrank(r) for r in ranks]
        prefixes={()}
        for w in words:
            for k in range(len(w)):
                p=tuple(w[:k]); prefixes.add(p)
                prefixes.update(p+(j,) for j in range(len(L)))
            prefixes.add(tuple(w))
        # Invalid token and overlong cases must have zero completions.
        prefixes.update({(-1,), (len(L),), tuple(words[0])+(0,)})
        keys=sorted(prefixes)
        expected=[str(o.prefix(p)) for p in keys]
        for w in words:
            for k in range(len(w)):
                p=tuple(w[:k])
                if o.prefix(p)!=sum(o.prefix(p+(j,)) for j in range(len(L))):
                    raise RuntimeError("oracle partition")
        if o.count.cache_info().currsize>MAX_STATES: raise RuntimeError("oracle budget")
        oracle_seconds=time.monotonic()-start
        payload=dict(lengths=L,words=words,ranks=list(map(str,ranks)),prefixes=keys)
        result,metrics=worker(payload)
        want=dict(status="MEDIUM_RANK_RESULT",count=str(c),rank=payload["ranks"],
                  unrank=words,prefix=expected,negative=8)
        if result!=want: raise RuntimeError(f"medium candidate mismatch {L}")
        total_rank+=len(ranks); total_prefix+=len(keys); total_negative+=8
        row.emit(dict(type="medium_rank",lengths=L,count=str(c),ranks=payload["ranks"],
                      rank=len(ranks),unrank=len(ranks),prefixes=len(keys),negative=8,
                      oracle_states=o.count.cache_info().currsize,oracle_seconds=oracle_seconds,
                      **metrics))
        o.count.cache_clear()
    if not large: raise RuntimeError("no rank above int64 domain")
    row.emit(dict(status="MEDIUM_RANK_GATE_PASS",shapes=len(SHAPES),
                  rank=total_rank,unrank=total_rank,prefixes=total_prefix,
                  negative=total_negative,qualification="MEDIUM_ONLY"))
    return 0

if __name__=="__main__":
    try: sys.exit(main())
    except (RuntimeError,ValueError,OSError,subprocess.TimeoutExpired) as exc:
        row.emit(dict(status="FAIL",error=str(exc))); sys.exit(1)
