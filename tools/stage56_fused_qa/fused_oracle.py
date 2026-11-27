import itertools, json, math, random, subprocess, sys
from pathlib import Path
B=10**9
rng=random.Random(5627)
def limbs(n):
    out=[]
    while n: out.append(n%B); n//=B
    return out or [0]
def integer(a):
    n=0
    for x in reversed(a): n=n*B+x
    return n
def words(lengths):
    # Independent lexicographic enumeration: no suffix recurrence or weights.
    n=len(lengths); remaining=list(lengths); word=[]
    def walk(opened,closed):
        if not any(remaining):
            yield tuple(word); return
        for j in range(min(n,opened+1)):
            if remaining[j]==0 or (remaining[j]==1 and j!=closed): continue
            remaining[j]-=1; word.append(j)
            yield from walk(max(opened,j+1),closed+(remaining[j]==0))
            word.pop(); remaining[j]+=1
    return list(walk(0,0))
def reference(l):
    width=list(itertools.accumulate([l[0]]+[x-1 for x in l[1:]]))
    following=[1]*(width[-1]+1)
    for i in range(len(l)-2,-1,-1):
        m=l[i+1]; row=[0]
        for q in range(1,width[i]+1): row.append(row[-1]+math.comb(m+q-3,q-1)*following[m+q-1])
        following=row
    return following[l[0]]
cases=[]; expected=[]
for m,n,mx in itertools.product([1,2,7,8,9,16,17,28,32,33,64],[1,8,9,31,100,1009],[False,True]):
    def v(k): return [B-1 if mx else rng.randrange(B) for _ in range(k)]
    a,b,c=v(m),v(n),v(m+n+1); cases.append({'operands':[a,b,c]}); expected.append(limbs(integer(a)*integer(b)+integer(c)))
for a,b,c in [([0],[0],[0]),([0],[B-1],[B-1]),([B-1],[B-1],[0])]:
    cases.append({'operands':[a,b,c]}); expected.append(limbs(integer(a)*integer(b)+integer(c)))
small=0
for n in range(1,4):
    for l in itertools.product(range(2,5),repeat=n):
        w=words(l); assert w==sorted(set(w)); count=len(w); assert count==reference(l)
        cases.append({'lengths':l}); expected.append(limbs(count)); small+=1
large=[[4]*46,[123,122,121,120],[4,123,4,123,4]]
for l in large: cases.append({'lengths':l}); expected.append(limbs(reference(l)))
p=subprocess.run(['php',str(Path(__file__).with_name('fused.php'))],input=json.dumps(cases),capture_output=True,text=True,timeout=120,check=True)
assert not p.stderr
actual=[json.loads(x) for x in p.stdout.splitlines()]; assert actual==expected
print(f'FUSED_QA_PASS arithmetic=135 exhaustive_count={small} recurrence_count={len(large)}; rank enumeration oracle only, PHP rank NOT tested')
