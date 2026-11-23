#!/usr/bin/env python3
"""Source-only differential of two historical month-weave COMPONENT formulas.
Zero calls/imports to original Calendar_Date, F(c,t), Sauce or gate generators.
"""
import hashlib,itertools,json,os,subprocess,time
from math import comb

M=(1<<127)-1
BASE="1160096aa847c54cbef27c232771ce1549d7ba8f"
BRANCH="qa/issue29-shared-stream-causal-fork-v188"
MESSAGE="qa(issue29-v188): source-only same-stream 713-day weave fork; no F"
PATHS={".github/workflows/issue29-v188-synthetic-fork.yml",
       "qa/issue29/v188_shared_stream_fork.py",
       "qa/issue29/V188_SHARED_STREAM_FORK.md"}
PINS={
"a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72:src/normative_oracle.adb":"923733d4f8face03586aee304640bf7540c28b4c",
"a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72:src/month_weaving.adb":"9b02c62dfbc7d8b3b532aba8cd9f1ad0f8b28fef",
"0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4:tests/normative_reference.py":"d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53"}

def require(ok,msg):
    if not ok:raise AssertionError(msg)
def sha(s):return hashlib.sha256(s).hexdigest()
def g(*xs):return subprocess.check_output(["git",*xs],stderr=subprocess.DEVNULL).decode().strip()
def preflight():
    if not os.environ.get("GITHUB_ACTIONS"):return
    require(os.environ.get("GITHUB_EVENT_NAME")=="push","must push")
    require(os.environ.get("GITHUB_RUN_ATTEMPT")=="1","no reruns")
    require(os.environ.get("GITHUB_REF")=="refs/heads/"+BRANCH,"branch mismatch")
    require(g("rev-parse","HEAD")==os.environ["GITHUB_SHA"],"SHA drift")
    ev=json.load(open(os.environ["GITHUB_EVENT_PATH"]))
    require(ev.get("head_commit",{}).get("message")==MESSAGE,"commit activation")
    require(subprocess.run(["git","merge-base","--is-ancestor",BASE,"HEAD"]).returncode==0,"bad source parent")
    diff=g("diff","--name-only",BASE+"...HEAD").splitlines()
    require(len(diff)==3 and set(diff)==PATHS,"only three QA files")
    for p,h in PINS.items():require(g("rev-parse",p)==h,"source drift: "+p)
    lock=open(".github/workflows/canonical-names-lock.yml").read()
    require(lock.count("    if: "+"$"+"{{ false }}")==42,"legacy date jobs enabled")
    require(lock.count("  verify:\n")==1,"verify gate changed")

def answer(first,step,k):return 1+(first-1+step*k)%M
def choose_rank(first,step,n):
    require(n>0 and 1<=first<=M and step in (-1,1),"rank domain")
    if n<=M:
        x=first;limit=(M//n)*n
        if x>limit:x=limit if step<0 else 1
        return (x-1)%n+1
    space=M;places=1
    while space<n:space*=M;places+=1
    x=1;weight=1
    for i in range(places):
        x+=(answer(first,step,i)-1)*weight
        weight*=M
    limit=(space//n)*n
    if x>limit:x=limit if step<0 else 1
    return (x-1)%n+1

def ada_source_weave(lengths,first,step):
    m=len(lengths);k=sum(lengths)-2*m
    remaining=[v-2 for v in lengths];word=list(range(1,m+1))
    for i in range(k):
        ticket=choose_rank(answer(first,step,i),step,k-i)
        for j in range(m):
            if ticket>remaining[j]:ticket-=remaining[j]
            else:
                require(remaining[j]>0,"remaining positive")
                remaining[j]-=1;word.append(j+1);break
        else:raise AssertionError("no ticket label")
    require(not any(remaining),"Ada rail residuals")
    return tuple(word+list(range(1,m+1)))

class PythonGlobalFamily:
    """Exact translated recurrence from historical MonthWeavingFamily."""
    def __init__(self,lengths):
        self.lengths=tuple(lengths);self.m=len(lengths)
        pref=[0]
        for n in lengths:pref.append(pref[-1]+n)
        self.h=[[] for _ in range(self.m+1)]
        self.h[self.m]=[1]*(pref[-1]+1)
        for opened in range(self.m-1,-1,-1):
            n=lengths[opened];mx=pref[opened];my=pref[opened+1]-1
            weighted=[0]*(my+1);acc=0
            for y in range(my+1):
                if y>=n-1:acc+=comb(y-1,n-2)*self.h[opened+1][y]
                weighted[y]=acc
            self.h[opened]=[weighted[x+n-1] for x in range(mx+1)]
    def count(self):return self.h[0][0]
    def completions(self,rem,opened,closed):
        b=0;result=1
        for j in range(closed,opened):
            n=rem[j]
            if not n:return 0
            if b:result*=comb(n+b-1,b);b+=n
            else:b=n
        return result*self.h[opened][b]
    def moves(self,rem,opened,closed):
        for j in range(closed,opened):
            n=rem[j]
            if not n or (n==1 and j!=closed):continue
            nxt=list(rem);nxt[j]-=1
            yield j+1,tuple(nxt),opened,closed+(nxt[j]==0)
        if opened<self.m:
            j=opened;nxt=list(rem);nxt[j]-=1
            require(nxt[j]>0,"opening has interior")
            yield j+1,tuple(nxt),opened+1,closed
    def unrank(self,r):
        require(1<=r<=self.count(),"unrank range")
        rem=self.lengths;opened=closed=0;out=[]
        for _ in range(sum(rem)):
            for label,nxt,no,nc in self.moves(rem,opened,closed):
                block=self.completions(nxt,no,nc)
                if r>block:r-=block
                else:out.append(label);rem=nxt;opened=no;closed=nc;break
            else:raise AssertionError("unrank transition missing")
        require(r==1 and not any(rem) and opened==closed==self.m,"unrank terminal")
        return tuple(out)

def exhaustive_finite_controls():
    checked=0
    for lengths in ((4,4),(4,5),(4,4,4)):
        m=len(lengths);rem=list(lengths);word=[];family=[]
        def walk(opened,closed):
            if len(word)==sum(lengths):
                require(opened==closed==m,"brute terminal")
                family.append(tuple(word));return
            for j in range(closed,opened):
                if rem[j]==0 or (rem[j]==1 and j!=closed):continue
                rem[j]-=1;word.append(j+1)
                walk(opened,closed+(rem[j]==0))
                word.pop();rem[j]+=1
            if opened<m:
                j=opened;rem[j]-=1;word.append(j+1)
                walk(opened+1,closed)
                word.pop();rem[j]+=1
        walk(0,0)
        family.sort();f=PythonGlobalFamily(lengths)
        require(len(family)==f.count(),"brute count")
        for i,w in enumerate(family,1):
            require(f.unrank(i)==w,"brute full unrank")
            checked+=1
        for first,step in ((1,1),(M,-1)):
            w=ada_source_weave(lengths,first,step)
            require(w[:m]==tuple(range(1,m+1)) and w[-m:]==tuple(range(1,m+1)),"rails")
            require(all(w.count(j)==lengths[j-1] for j in range(1,m+1)),"multiset")
    require(checked==1356,"all 1356 finite family witnesses")
    return checked

def selected(word,i):
    label=word[i]
    return [label,word[:i+1].count(label)]

def proof():
    preflight()
    started=time.monotonic()
    controls=exhaustive_finite_controls()
    lengths=(123,123,123,123,123,98);offset=502
    require(sum(lengths)==713 and len(lengths)==6,"witness minimum")
    # A cutlet of 503 followed by five cutlets of 42 is structurally
    # possible in the minimum 713-day year; NOT the observed Sauce.
    cutlets=(503,42,42,42,42,42)
    require(sum(cutlets)==713 and all(42<=x<=963 for x in cutlets),"geometry")
    family=PythonGlobalFamily(lengths)
    n=family.count()
    require(n.bit_length()==1799,"global family domain")
    cases=[]
    for first,step in ((1,1),(1,-1),(M//2,1),(M//2,-1),(M,1),(M,-1)):
        aw=ada_source_weave(lengths,first,step)
        r=choose_rank(first,step,n)
        pw=family.unrank(r)
        ada=selected(aw,offset);py=selected(pw,offset)
        diff=next((i for i,(a,b) in enumerate(zip(aw,pw)) if a!=b),None)
        require(diff is not None and ada[1]!=py[1],"same-stream causal fork")
        cases.append({"stream_first":str(first),"step":step,
                      "global_rank_sha256":sha(str(r).encode()),
                      "first_different_token_offset0":diff,
                      "selected_offset0":offset,
                      "ada_month_id_day":ada,"python_month_id_day":py,
                      "ada_word_sha256":sha(bytes(aw)),
                      "python_word_sha256":sha(bytes(pw))})
    return {"schema":"ISSUE29_V188_SYNTHETIC_SHARED_STREAM_DIFFERENTIAL_NO_F/1",
            "year_days":713,"cutlet_gaps":cutlets,"day_in_first_cutlet":503,
            "month_lengths":lengths,"selected_offset0":offset,
            "python_global_count_bits":n.bit_length(),"python_global_count_sha256":sha(str(n).encode()),
            "finite_exhaustive_rank_controls":controls,
            "same_stream_comparisons":len(cases),"different_days_in_month":len(cases),
            "cases":cases,"elapsed_seconds":round(time.monotonic()-started,4),
            "historical_witness_root_cause":"UNKNOWN",
            "original_calendar_F_calls":0,"native_converter_runs":0,"soak_years_certified":0}
if __name__=="__main__":
    print(json.dumps(proof(),indent=2,sort_keys=True))
