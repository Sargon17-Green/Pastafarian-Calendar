#!/usr/bin/env python3
"""Test-only forward-insertion oracle, recovered from archived Stage55 forward source rank."""
import collections, functools, hashlib, itertools, json, math, resource, sys, time
from pathlib import Path
from fractions import Fraction
sys.set_int_max_str_digits(0)
M=2**127-1
FOUNDATION=-15055671
def sha(x): return hashlib.sha256(str(x).encode()).hexdigest()
def save(x): return 1+(x-1)%M
def perm(x):
    return list(itertools.islice(itertools.permutations(range(6)),(x-1)%720,(x-1)%720+1))[0]
def sauce(c,t):
    def day(d): return 2*(d-FOUNDATION)+1 if d>=FOUNDATION else 2*(FOUNDATION-d)
    a,b,d,h,z=day(c),day(t),abs(t-c)+1,day(c)+day(t),1 if t<c else 2 if t==c else 3
    stones=[[17,29,43,71,101]]
    for i in range(2,47):
        u,v,w,x,y=stones[-1]
        stones.append([save(u*u+3*v+i),save(v*v+5*w+u),save(w*w+7*x+v),save(x*x+11*y+w),save(y*y+13*u+x)])
    timeline={}
    for j in range(7):
        x=save(a+(3+2*j)*b+(4+3*j)*d+(6+4*j)*h+(8+4*j)*z+sum(stones[j]))
        for k in range(1,8): x=save(x*x+3*x+stones[j][(k-1)%5]+k)
        timeline[-j]=x
    bowls=[save((a+b*i+d+h+z+p*p)**2+i) for i,p in enumerate([17,19,23,29,31,37],1)]
    primes=[3,5,7,11,13,17,19,23,29,31,37,41,43,47]
    for i,s in enumerate(stones,1):
        p1,p3,p7=(timeline[i-k] for k in (1,3,7))
        x=save(sum(v*w for v,w in zip(s,(a,b,d,h,z)))+p1+3*p3+5*p7+i)
        for k in range(11):
            q,r,u,v=primes[k:k+4]
            x=save(x*x+q*x+r*p1+u*p3+v*p7+s[k%5])
        timeline[i]=x; order=perm(x); old=bowls[:]
        pours=[save(x*x+s[j]*old[order[j]]+(3+2*j)*i) for j in range(3)]+[0]*3
        for j,idx in enumerate(order):
            prev,nxt=old[order[(j-1)%6]],old[order[(j+1)%6]]
            q=old[idx]+2*prev+3*nxt+pours[j]+x+s[j%5]
            bowls[idx]=save(q*q+5*prev*nxt+i*(j+1))
    order46=order
    for k in range(1,13):
        old=bowls[:]; v=save(sum(old)+149*k); order=perm(v)
        for j,idx in enumerate(order):
            prev,nxt=old[order[(j-1)%6]],old[order[(j+1)%6]]
            q=old[idx]+3*prev+5*nxt+v+k+(j+1)**2
            bowls[idx]=save(q*q+7*prev*nxt)
    return bowls,order46
def source_rank(c,t,n,bowl=4,seal=32):
    bowls,order=sauce(c,t); i=bowl-1; j=order[(order.index(i)+1)%6]
    first=save((bowls[i]+seal+181)**2+179*bowls[j]+seal)
    direction=1 if save((first+seal+194)**2+193*first+197*bowls[5])%2 else -1
    space=M; places=1
    while space<n: space*=M; places+=1
    wide=1; weight=1
    for k in range(places): wide+=((first-1+direction*k)%M)*weight; weight*=M
    limit=space//n*n
    accepted=wide if wide<=limit else (limit if direction==-1 else 1)
    return (accepted-1)%n+1,dict(places=places,direction=direction,first=str(first),wide_sha256=sha(wide),rejected=wide>limit)
def moves(state):
    rem,o,c=state
    for j,r in enumerate(rem):
        if not r or j>o or (r==1 and j!=c): continue
        nxt=list(rem); nxt[j]-=1
        yield j+1,(tuple(nxt),o+(j==o),c+(r==1))
@functools.lru_cache(maxsize=32)
def external(g, unopened):
    f=[1]+[0]*g; k=g
    for n in unopened:
        if n==1: f=[0]*(k+1)+[sum(f)]; k+=1; continue
        q=n-2; coef=math.comb(k+q,q); accum=0; new=[0]*(k+n+1)
        for a in range(k+1):
            accum+=f[a]; new[a+1]=accum*coef
            if a<k: coef=coef*(k-a)//(k-a+q)
        f=new; k+=n
    return sum(f)
def count(state):
    rem,o,c=state; group=rem[c:o]; g=0; inside=1
    for r in group:
        g+=r
        if r: inside*=math.comb(g-1,r-1)
    return inside*external(g,rem[o:])
def blocks(state,total):
    rem,o,c=state; g=sum(rem[c:o]); B=external(g,rem[o:]); assert B and total%B==0
    inside=total//B; partial=[]; k=0
    for r in rem[c:o]: k+=r; partial.append(k)
    ratios={}; tail=Fraction(1)
    for j in range(o-1,c-1,-1):
        r=rem[j]; S=partial[j-c]
        if r>1: ratios[j]=tail*Fraction(r-1,S-1)
        elif j==c: ratios[j]=tail
        if S>1: tail*=Fraction(S-r,S-1)
    for j,s in moves(state):
        if j-1==o: b=count(s)
        else:
            ratio=ratios[j-1]; numerator=inside*ratio.numerator
            assert numerator%ratio.denominator==0
            b=(numerator//ratio.denominator)*external(g-1,rem[o:])
        yield j,s,b
def unrank(lengths,rank,progress=None):
    state=(tuple(lengths),0,0); total=count(state)
    if not 1<=rank<=total: raise ValueError('rank outside family')
    word=[]
    for pos in range(1,sum(lengths)+1):
        choices=list(blocks(state,total))
        assert sum(b for _,_,b in choices)==total
        oldrank=rank
        for j,s,b in choices:
            if rank>b: rank-=b
            else:
                assert b>0
                word.append(j); state=s; total=b; break
        else: raise AssertionError('no chosen child')
        if progress: progress(dict(position=pos,symbol=j,rank_before_sha256=sha(oldrank),rank_after_sha256=sha(rank),child_count_sha256=sha(total),remaining=list(state[0]),opened=state[1],closed=state[2]))
    assert total==rank==1 and not any(state[0])
    return word
def tiny():
    families=states=edges=words=0
    for m in range(1,5):
        for lengths in itertools.product(range(1,4),repeat=m):
            if sum(lengths)>10: continue
            families+=1; root=(lengths,0,0); visited=set()
            @functools.lru_cache(None)
            def direct(s):
                visited.add(s)
                if not any(s[0]): return ((),)
                return tuple((j,)+w for j,n in moves(s) for w in direct(n))
            expected=direct(root); words+=len(expected)
            for s in visited:
                assert count(s)==len(direct(s)),(lengths,s)
                states+=1; edges+=len(list(moves(s)))
            for i,w in enumerate(expected,1): assert tuple(unrank(lengths,i))==w
            for r in (0,len(expected)+1):
                try: unrank(lengths,r)
                except ValueError: pass
                else: raise AssertionError('invalid rank accepted')
    return dict(families=families,states=states,edges=edges,words=words)
def main():
    out=Path('logs/stage55_source_forward'); out.mkdir(parents=True,exist_ok=True)
    start=time.monotonic(); report={'tiny':tiny()}; assert report['tiny']==dict(families=115,states=1335,edges=1697,words=1408)
    f=json.loads(Path('tests/fixtures/stage55_year5000_appendix_a_metadata.json').read_text())
    lengths=tuple(f['month_lengths']); assert len(lengths)==45 and sum(lengths)==4244
    T=count((lengths,0,0)); assert sha(T)=='c0c08ac89c8faaaf589d1b3e076fe1e96405f2ad7172a15efa9d028fb43fb6f8'
    def bounded(n,k):
        if k==0: return int(n==0)
        s=n-4*k
        if s<0 or s>119*k: return 0
        return sum((-1)**j*math.comb(k,j)*math.comb(s-120*j+k-1,k-1) for j in range(min(k,s//120)+1))
    m=len(lengths); N=bounded(sum(lengths),m)
    comp_rank,_=source_rank(f['calculation_day'],f['first_day'],N,3,31)
    assert str(comp_rank)=='21706039149316943527912320903423885398156086660683714452395033170314294340946533'
    r=comp_rank; rest=sum(lengths); derived=[]
    for k in range(m-1,-1,-1):
        for x in range(4,124):
            b=bounded(rest-x,k)
            if r>b: r-=b
            else: derived.append(x);rest-=x;break
        else: raise AssertionError('composition exhausted')
    assert tuple(derived)==lengths and r==1 and rest==0
    rank,meta=source_rank(f['calculation_day'],f['first_day'],T)
    assert sha(rank)=='160ca5c4a8ee5d0ec29c583a0d7ab91a71d8be4b7dc4c139ebaae066596dcff3'
    assert rank!=T//2+1 and meta['places']==177 and meta['direction']==-1 and not meta['rejected']
    (out/'oracle_count.txt').write_text(str(T));(out/'oracle_rank.txt').write_text(str(rank))
    with (out/'oracle_trace.jsonl').open('w') as fp:
        def progress(row): fp.write(json.dumps(row,separators=(',',':'))+'\n');fp.flush()
        word=unrank(lengths,rank,progress)
    (out/'oracle_word.json').write_text(json.dumps(word,separators=(',',':'))+'\n')
    for p,h in [('oracle_trace.jsonl','4e99e73bc0263bb0440d2e308e277f936038fad936544b518c0fec869b2fdce9'),('oracle_word.json','76396b8dc72b209c9f273d7ebbab3c6a09b3424eff8ee71acd1566680641786e')]:
        assert hashlib.sha256((out/p).read_bytes()).hexdigest()==h
    report.update(positions=len(word),source_stream=meta,elapsed=time.monotonic()-start,rss_kib=resource.getrusage(resource.RUSAGE_SELF).ru_maxrss)
    (out/'oracle_report.json').write_text(json.dumps(report)+'\n')
    print('FORWARD_ORACLE_PASS 4244/4244',flush=True)
if __name__=='__main__': main()
