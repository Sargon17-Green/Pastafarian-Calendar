#!/usr/bin/env python3
"""Stage14 Ada+తెలుగు: independently reconstruct numeric dates from real day inputs.

This Python standard-library implementation does not invoke Ada Calendar_Date
or read its results when constructing expectations. The numerical mixing
recurrences are specification-derived; combinatorial decoding uses Python
permutations, DP and occurrence-list removal instead of Ada data structures.
It is not a mathematical proof of independence.
"""
from functools import lru_cache
from itertools import permutations
from math import prod

MOD = 2**127 - 1
FOUNDATION = -15_055_671
YEAR_LIMIT = 5778

def save(n):
    return 1 + (n - 1) % MOD

def work(cal, target):
    def day(n):
        return 1 if n == FOUNDATION else (2*(n-FOUNDATION)+1 if n > FOUNDATION else 2*(FOUNDATION-n))
    a, t = day(cal), day(target)
    return a, t, abs(target-cal)+1, a+t, 1 if target < cal else (3 if target > cal else 2)

def build_stones():
    seq = [(17, 29, 43, 71, 101)]
    for i in range(2, 47):
        w,b,s,h,r = seq[-1]
        seq.append((save(w*w+3*b+i), save(b*b+5*s+w),
                    save(s*s+7*h+b), save(h*h+11*r+s),
                    save(r*r+13*w+h)))
    return seq

STONES = build_stones()
HCOEFF = ((3,4,6,8),(5,7,10,12),(7,10,14,16),(9,13,18,20),
          (11,16,22,24),(13,19,26,28),(15,22,30,32))
HKIND = (0,1,2,3,4,0,1)
VGRIND = ((3,5,7,11,0),(5,7,11,13,1),(7,11,13,17,2),
          (11,13,17,19,3),(13,17,19,23,4),(17,19,23,29,0),
          (19,23,29,31,1),(23,29,31,37,2),(29,31,37,41,3),
          (31,37,41,43,4),(37,41,43,47,0))
ORDERS = list(permutations(range(6)))

@lru_cache(maxsize=256)
def sauce(cal, target):
    a,t,d,co,direction = work(cal,target)
    hidden = []
    for k in range(7):
        x = save(a+HCOEFF[k][0]*t+HCOEFF[k][1]*d+
                 HCOEFF[k][2]*co+HCOEFF[k][3]*direction+sum(STONES[k]))
        for j in range(7):
            x = save(x*x+3*x+STONES[k][HKIND[j]]+j+1)
        hidden.append(x)
    visible = []
    for i in range(46):
        def prior(back):
            idx = i-back
            return visible[idx] if idx >= 0 else hidden[-1-idx]
        p1,p3,p7 = prior(1),prior(3),prior(7)
        w,b,s,h,r = STONES[i]
        x = save(w*a+b*t+s*d+h*co+r*direction+p1+3*p3+5*p7+i+1)
        for aa,bb,cc,dd,kind in VGRIND:
            x = save(x*x+aa*x+bb*p1+cc*p3+dd*p7+STONES[i][kind])
        visible.append(x)
    primes = (17,19,23,29,31,37)
    bowls = [save((a+(j+1)*t+d+co+direction+primes[j]**2)**2+j+1)
             for j in range(6)]
    for i,drop in enumerate(visible,1):
        order = ORDERS[(drop-1)%720]
        old = bowls[:]
        pour = [save(drop*drop+STONES[i-1][z]*old[order[z]]+(2*z+3)*i)
                for z in range(3)] + [0,0,0]
        nxt = old[:]
        for p,idx in enumerate(order):
            before,after = order[(p-1)%6],order[(p+1)%6]
            q = old[idx]+2*old[before]+3*old[after]+pour[p]+drop+STONES[i-1][(0,1,2,3,4,0)[p]]
            nxt[idx] = save(q*q+5*old[before]*old[after]+i*(p+1))
        bowls = nxt
    order_at_drop46 = order
    for stir in range(1,13):
        old = bowls[:]
        total = save(sum(old)+149*stir)
        order = ORDERS[(total-1)%720]
        nxt = old[:]
        for p,idx in enumerate(order):
            before,after = order[(p-1)%6],order[(p+1)%6]
            q = old[idx]+3*old[before]+5*old[after]+total+stir+(p+1)**2
            nxt[idx] = save(q*q+7*old[before]*old[after])
        bowls = nxt
    return tuple(bowls),tuple(order_at_drop46)

def stream(cal,target,bowl,seal):
    bowls,order = sauce(cal,target)
    p = order.index(bowl-1)
    first = save((bowls[bowl-1]+seal+181)**2+179*bowls[order[(p+1)%6]]+seal)
    direction_number = save((first+seal+194)**2+193*first+197*bowls[5])
    return first, (1 if direction_number % 2 else -1)

def rank(s,n,offset=0):
    if n < 1:
        raise ValueError("empty candidate family")
    first,delta = s
    def answer(k):
        return 1+(first-1+delta*k)%MOD
    if n <= MOD:
        x = answer(offset)
        lim = (MOD//n)*n
        if x > lim:
            x = lim if delta == -1 else 1
        return 1+(x-1)%n
    places,space = 1,MOD
    while space < n:
        places += 1
        space *= MOD
    x,weight = 1,1
    for i in range(places):
        x += (answer(offset+i)-1)*weight
        weight *= MOD
    lim = (space//n)*n
    if x > lim:
        x = lim if delta == -1 else 1
    return 1+(x-1)%n

class Gates:
    def __init__(self):
        self.g = {0:FOUNDATION}
        self.lo = self.hi = 0
    def at(self,i):
        while i > self.hi:
            k = self.hi+1
            self.g[k] = self.g[k-1]+41+rank(stream(FOUNDATION,FOUNDATION+k,1,1),922)
            self.hi = k
        while i < self.lo:
            k = self.lo-1
            self.g[k] = self.g[k+1]-41-rank(stream(FOUNDATION,FOUNDATION-abs(k),1,1),922)
            self.lo = k
        return self.g[i]
    def cover(self,low,high):
        while self.at(self.lo) > low:
            self.at(self.lo-1)
        while self.at(self.hi) < high:
            self.at(self.hi+1)
    def before(self,day):
        self.cover(day,day)
        return max(i for i,g in self.g.items() if g <= day)

def target_year(g,cal,target):
    g.cover(cal-YEAR_LIMIT,cal+YEAR_LIMIT)
    pairs = []
    for i in range(g.lo,g.hi):
        for j in range(i+6,g.hi+1):
            length = g.at(j)-g.at(i)
            if 252 <= length <= YEAR_LIMIT and g.at(i) < cal <= g.at(j):
                pairs.append((length,g.at(i),i,j))
    pairs.sort()
    if not pairs:
        raise AssertionError("no year-5000 candidate")
    _,_,a,b = pairs[rank(stream(cal,cal,1,10),len(pairs))-1]
    year = 5000
    while target > g.at(b):
        cand = []
        j = b+6
        while g.at(j)-g.at(b) <= YEAR_LIMIT:
            if g.at(j)-g.at(b) >= 252:
                cand.append(j)
            j += 1
        a,b = b,cand[rank(stream(cal,g.at(b),1,11),len(cand))-1]
        year += 1
    while target <= g.at(a):
        cand = []
        i = a-6
        while g.at(a)-g.at(i) <= YEAR_LIMIT:
            if g.at(a)-g.at(i) >= 252:
                cand.append(i)
            i -= 1
        old = a
        a = cand[rank(stream(cal,g.at(old),1,12),len(cand))-1]
        b = old
        year -= 1
    return year,a,b

def unrank_labels(size,k,r):
    labels = list(range(1,size+1))
    output = []
    for remaining in range(k,0,-1):
        block = prod(range(len(labels)-remaining+1,len(labels)))
        choice = (r-1)//block
        r = 1+(r-1)%block
        output.append(labels.pop(choice))
    return output

def partition(g,cal,a,b,s,k):
    required = g.before(cal)-a if a < g.before(cal) < b and g.at(g.before(cal)) == cal else 0
    @lru_cache(None)
    def count(remaining,slots,cumulative,hit):
        if not slots:
            return int(remaining==0 and (not required or hit))
        if remaining < slots:
            return 0
        ans = 0
        for step in range(1,remaining-slots+2):
            new = cumulative+step
            if required and not hit and new>required:
                continue
            ans += count(remaining-step,slots-1,new,hit or (required!=0 and new==required))
        return ans
    r = rank(s,count(b-a,k,0,False))
    out,remain,cumulative,hit = [],b-a,0,False
    for pos in range(k):
        for step in range(1,remain-(k-pos-1)+1):
            new = cumulative+step
            if required and not hit and new>required:
                continue
            newhit = hit or bool(required and new==required)
            n = count(remain-step,k-pos-1,new,newhit)
            if r > n:
                r -= n
            else:
                out.append(step);remain-=step;cumulative=new;hit=newhit
                break
        else:
            raise AssertionError("partition unranking failed")
    assert remain == 0
    return out

def month_lengths(total,slots,s):
    dp = [[0]*(total+1) for _ in range(slots+1)]
    dp[0][0] = 1
    for m in range(1,slots+1):
        pref = [0]*(total+2)
        for n in range(total+1):
            pref[n+1] = pref[n]+dp[m-1][n]
        for n in range(4*m,total+1):
            dp[m][n] = pref[n-3]-pref[max(0,n-123)]
    r = rank(s,dp[slots][total])
    lengths = []
    remain,cnt = total,slots
    while cnt:
        for value in range(4,124):
            n = dp[cnt-1][remain-value] if remain >= value else 0
            if r>n:
                r -= n
            else:
                lengths.append(value);remain-=value;cnt-=1
                break
        else:
            raise AssertionError("month length unranking failed")
    assert remain == 0
    return lengths

def weave(lengths,s):
    occurrences = [i for i,n in enumerate(lengths) for _ in range(n-2)]
    seq = list(range(len(lengths)))
    for k in range(len(occurrences)):
        idx = rank(s,len(occurrences),k)-1
        seq.append(occurrences.pop(idx))
    return seq+list(range(len(lengths)))

def date(cal,target):
    g = Gates()
    year,a,b = target_year(g,cal,target)
    first = g.at(a)+1
    gaps = b-a
    k = 5+rank(stream(cal,first,2,20),min(17,gaps)-5)
    part = partition(g,cal,a,b,stream(cal,first,2,21),k)
    names = unrank_labels(17,k,rank(stream(cal,first,5,22),prod(range(18-k,18))))
    total = g.at(b)-g.at(a)
    low,high = (total+122)//123,min(47,total//4)
    m = low+rank(stream(cal,first,3,30),high-low+1)-1
    lengths = month_lengths(total,m,stream(cal,first,3,31))
    months = weave(lengths,stream(cal,first,4,32))
    month_names = unrank_labels(47,m,rank(stream(cal,first,5,33),prod(range(48-m,48))))
    cursor = a
    cutlet = cutlet_day = None
    for i,step in enumerate(part):
        if g.at(cursor) < target <= g.at(cursor+step):
            cutlet,cutlet_day = names[i],target-g.at(cursor)
            break
        cursor += step
    assert cutlet is not None
    offset = target-first
    month = months[offset]
    fields = (year,cutlet,cutlet_day,month_names[month],months[:offset+1].count(month))
    assert 4999<=year<=5001 and 1<=cutlet<=17 and 1<=cutlet_day<=YEAR_LIMIT
    assert 1<=fields[3]<=47 and 1<=fields[4]<=123
    return fields

if __name__ == "__main__":
    for target in (FOUNDATION-1,FOUNDATION,FOUNDATION+1):
        print("STAGE14_REAL_REFERENCE",target,*date(FOUNDATION,target),flush=True)
