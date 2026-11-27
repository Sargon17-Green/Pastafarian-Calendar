"""Independent Python integer and prefix-completion oracle; no PHP fixture imports."""
import itertools, json, math, random, statistics, subprocess, sys
from pathlib import Path
if hasattr(sys, 'set_int_max_str_digits'):
    sys.set_int_max_str_digits(0)
B=10**9
rng=random.Random(56271127)
cases=[]; expected=[]; labels=[]
def add(case, value, label):
    cases.append(case); expected.append(value); labels.append(label)
def number(n, full=False):
    return B**n-1 if full else rng.randrange(B**(n-1),B**n)
def ar(a,b,c):
    result=str(a*b+c)
    add({'operands':list(map(str,(a,b,c)))},[result]*3,'arithmetic')
for w,v,full in itertools.product(range(1,34),[1,8,63,64,700,1009],[False,True]):
    a,b,c=number(w,full),number(v,full),number(w+v,full)
    ar(a,b,c)
    if w in (8,32,33) and v in (64,1009):
        ar(-a,b,c); ar(a,-b,c); ar(a,b,-c); ar(b,a,c)
for x in [(0,0,0),(0,1,2),(1,1,0),(B**8-1,B**3001-1,0),(B**8-1,B**64-1,B**3001-1)]:
    ar(*x)
def words(lengths):
    remaining=list(lengths); word=[]
    def walk(high):
        if not any(remaining):
            yield tuple(word); return
        low=next(i for i,r in enumerate(remaining) if r)
        for j in range(min(len(lengths),high+2)):
            if not remaining[j] or (remaining[j]==1 and j!=low): continue
            remaining[j]-=1; word.append(j)
            yield from walk(max(high,j))
            word.pop(); remaining[j]+=1
    return list(walk(-1))
class Oracle:
    def __init__(self,l):
        self.l=l
        widths=list(itertools.accumulate([l[0]]+[x-1 for x in l[1:]]))
        self.rows=[None]*len(l)
        self.rows[-1]=[1]*(widths[-1]+1)
        for i in range(len(l)-2,-1,-1):
            m=l[i+1]; row=[0]; following=self.rows[i+1]
            for q in range(1,widths[i]+1):
                row.append(row[-1]+math.comb(m+q-3,q-1)*following[m+q-1])
            self.rows[i]=row
        self.count=self.rows[0][l[0]]
    def completions(self,remaining,high):
        active=remaining[:high+1]; total=0; base=1
        # Count interleavings of active symbols with ordered last occurrences.
        for r in active:
            if r:
                base*=math.comb(total+r-1,total)
                total+=r
        return base*self.rows[high][total+1] if high<len(self.l)-1 else base
    def unrank(self,k):
        remaining=list(self.l); high=-1; result=[]
        for _ in range(sum(self.l)):
            low=next(i for i,r in enumerate(remaining) if r)
            for j in range(min(len(self.l),high+2)):
                if not remaining[j] or (remaining[j]==1 and j!=low): continue
                remaining[j]-=1
                size=self.completions(remaining,max(high,j))
                if k<=size:
                    result.append(j); high=max(high,j); break
                k-=size; remaining[j]+=1
            else:
                raise AssertionError('oracle rank outside domain')
        assert k==1
        return result
def shape(l, small):
    o=Oracle(l)
    if small:
        w=words(l)
        assert w==sorted(set(w)) and len(w)==o.count
        probes=[[str(i+1),list(word)] for i,word in enumerate(w)]
        assert all(o.unrank(int(k))==word for k,word in probes)
    else:
        ranks=sorted({1,o.count,(o.count+1)//2,rng.randrange(1,o.count+1)})
        probes=[[str(k),o.unrank(k)] for k in ranks]
    result=[str(o.count),probes]
    add({'lengths':l,'probes':probes},[result,result],'small' if small else 'large')
for n in range(1,4):
    for l in itertools.product(range(2,5),repeat=n):
        shape(l,True)
for l in [[4]*46,[123,122,121,120],[4,123,4,123,4]]:
    shape(l,False)
for width,long in itertools.product(range(1,33),[8,64,700,1009]):
    add({'bench':list(map(str,(number(width),number(long),number(width+long))))},None,f'bench {width}x{long}')
p=subprocess.run(['php','-d','memory_limit=512M',str(Path(__file__).with_name('integrated.php'))],input=json.dumps(cases),capture_output=True,text=True,timeout=180)
if p.returncode or p.stderr:
    raise RuntimeError(f'PHP exit={p.returncode} stderr={p.stderr}')
actual=[json.loads(x) for x in p.stdout.splitlines()]
assert len(actual)==len(cases)
for i,(got,want,label) in enumerate(zip(actual,expected,labels)):
    if want is None:
        assert len(got)==2 and all(len(x)==3 and all(v>0 and math.isfinite(v) for v in x) for x in got)
        print(label, 'baseline', statistics.median(got[0]), 'candidate', statistics.median(got[1]), 'pairs',json.dumps(got))
    elif got!=want:
        raise AssertionError(f'mismatch case {i} {label}')
print('STAGE56_FUSED_INTEGRATED_PASS', 'arithmetic='+str(labels.count('arithmetic')), 'small='+str(labels.count('small')), 'large='+str(labels.count('large')), 'rank_probes='+str(sum(len(c.get('probes',[])) for c in cases)), 'bench='+str(sum(x.startswith('bench') for x in labels)))
