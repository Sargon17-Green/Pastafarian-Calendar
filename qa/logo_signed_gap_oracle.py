"""QA-only signed-gate oracle: Python integers and lexicographic permutations.
Derived from the equations in frozen test/normative_reference.logo (625171e).
No expected gap table, production Logo routines, or other branch fixtures.
"""
import argparse
import itertools
import json

M = int('170141183460469231731687303715884105727')
FOUNDATION = -15055671
PERMS = tuple(itertools.permutations(range(6)))
GRINDS = ((3,5,7,11,0),(5,7,11,13,1),(7,11,13,17,2),(11,13,17,19,3),(13,17,19,23,4),(17,19,23,29,0),(19,23,29,31,1),(23,29,31,37,2),(29,31,37,41,3),(31,37,41,43,4),(37,41,43,47,0))

def save(x):
    return 1 + (x-1) % M

def gap(k):
    if type(k) is not int or k == 0:
        raise ValueError('nonzero signed integer required')
    c, t, d = 1, 2*abs(k)+(k>0), abs(k)+1
    conn, direction = c+t, 3 if k>0 else 1
    counts = (c,t,d,conn,direction)
    stones = [(17,29,43,71,101)]
    for i in range(2,47):
        w,b,s,m,r = stones[-1]
        stones.append(tuple(map(save,(w*w+3*b+i,b*b+5*s+w,s*s+7*m+b,m*m+11*r+s,r*r+13*w+m))))
    hidden=[]
    for j,stone in enumerate(stones[:7],1):
        x=save(c+(2*j+1)*t+(3*j+1)*d+(4*j+2)*conn+(4*j+4)*direction+sum(stone))
        for g in range(1,8):
            x=save(x*x+3*x+stone[(g-1)%5]+g)
        hidden.append(x)
    vis=[]
    for i,stone in enumerate(stones,1):
        def prior(back):
            slot=i-back
            return vis[slot-1] if slot>=1 else hidden[-slot]
        p,q,r=(prior(back) for back in (1,3,7))
        x=save(sum(a*b for a,b in zip(stone,counts))+p+3*q+5*r+i)
        for a,b,e,f,j in GRINDS:
            x=save(x*x+a*x+b*p+e*q+f*r+stone[j])
        vis.append(x)
    bowls=[save((c+t*i+d+conn+direction+prime**2)**2+i) for i,prime in enumerate((17,19,23,29,31,37),1)]
    for i,(drop,stone) in enumerate(zip(vis,stones),1):
        order=PERMS[(drop-1)%720]
        pours=[save(drop*drop+stone[j]*bowls[order[j]]+(3+2*j)*i) for j in range(3)]+[0]*3
        new=[0]*6
        for j,bid in enumerate(order):
            prev,nxt=bowls[order[(j-1)%6]],bowls[order[(j+1)%6]]
            mix=bowls[bid]+2*prev+3*nxt+pours[j]+drop+stone[j%5]
            new[bid]=save(mix*mix+5*prev*nxt+i*(j+1))
        bowls=new
    latch=order
    for stir in range(1,13):
        saved=save(sum(bowls)+149*stir)
        order=PERMS[(saved-1)%720]
        new=[0]*6
        for j,bid in enumerate(order):
            prev,nxt=bowls[order[(j-1)%6]],bowls[order[(j+1)%6]]
            mix=bowls[bid]+3*prev+5*nxt+saved+stir+(j+1)**2
            new[bid]=save(mix*mix+7*prev*nxt)
        bowls=new
    nxt=latch[(latch.index(0)+1)%6]
    first=save((bowls[0]+182)**2+179*bowls[nxt]+1)
    direction=save((first+195)**2+193*first+197*bowls[5])
    limit=M-M%922
    # The rejection interval is a contiguous tail. Jump directly to the first
    # accepted answer rather than walking the cyclic stream one item at a time.
    chosen=first if first<=limit else (1 if direction%2 else limit)
    return 42+(chosen-1)%922

def reconstruct(center):
    if type(center) is not int:
        raise ValueError('integer center required')
    lo,hi=center-5778,center+5778
    days={0:FOUNDATION}; gaps={}
    # Both sides start at the foundation; each step has a strict bound from gap>=42.
    for sign in (-1,1):
        target=lo if sign<0 else hi
        i=0
        bound=(abs(target-FOUNDATION)+41)//42+1
        while (days[i]>target if sign<0 else days[i]<target):
            j=i+sign
            if abs(j)>bound:
                raise RuntimeError('coverage bound exceeded')
            g=gap(j)
            if not 42<=g<=963: raise RuntimeError('gap range')
            gaps[j]=g;days[j]=days[i]+sign*g;i=j
    keys=sorted(days)
    if keys!=list(range(keys[0],keys[-1]+1)) or any(days[a]>=days[b] for a,b in zip(keys,keys[1:])):
        raise RuntimeError('invalid reconstruction')
    if not days[keys[0]]<=lo<=hi<=days[keys[-1]]:
        raise RuntimeError('incomplete coverage')
    return {'center':center,'low':lo,'high':hi,'gates':[{'index':k,'day':days[k],'gap':gaps.get(k)} for k in keys]}

if __name__=='__main__':
    p=argparse.ArgumentParser(); g=p.add_mutually_exclusive_group(required=True)
    g.add_argument('--indices',nargs='+',type=int);g.add_argument('--center',type=int)
    a=p.parse_args()
    if a.indices is not None:
        if len(set(a.indices))!=len(a.indices): p.error('duplicate indices')
        print(json.dumps([{'index':k,'gap':gap(k)} for k in a.indices]))
    else: print(json.dumps(reconstruct(a.center)))
