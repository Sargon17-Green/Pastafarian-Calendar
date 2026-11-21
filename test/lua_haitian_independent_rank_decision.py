#!/usr/bin/env python3
"""Bounded, standalone Python bigint selected-year cross-check for Lua+Kreyòl-ayisyen.

This is a NEW Python integer implementation of the deterministic mathematical
selection recipe (not importing Lua or historical fixture/code from any branch).
The specification, not an independent normative authority, is the audited
same-branch `test/normative_oracle.lua` at source blob 8fab731d....
Run: python3 lua_haitian_independent_rank_decision.py
No dependencies, files or network. Results use bounded [-96,96] gate indices.
"""
import hashlib
import itertools
import json
import time
import sys
try:
    import resource
except ImportError:
    resource = None
if resource is not None:  # Hard caps on the GitHub Ubuntu runner.
    resource.setrlimit(resource.RLIMIT_CPU, (20,20))
    resource.setrlimit(resource.RLIMIT_AS, (192*1024*1024,192*1024*1024))


PROJECT_ID = 'PC-BRANCH-LUA-HAITIAN'
SOURCE_LOCK_COMMIT = '01561f6d1eaea06b0a70acf60a1a30340e743c79'
CANONICAL_BLOB = '8fab731dff7011b1a4c3a241c5d1cdefef1c2f1d'
M = 2**127 - 1
F = -15055671
RADIUS = 96
MAX_DAY = 5778
MAX_CANDIDATES = 193*192//2
MAX_WALL_SECONDS = 15
START = time.monotonic()

FIVE = (17, 29, 43, 71, 101)
DROP_WEIGHTS = ((3,4,6,8),(5,7,10,12),(7,10,14,16),(9,13,18,20),
                (11,16,22,24),(13,19,26,28),(15,22,30,32))
HIDDEN_INDEX = (0,1,2,3,4,0,1)
VIS_WEIGHTS = ((3,5,7,11,0),(5,7,11,13,1),(7,11,13,17,2),
               (11,13,17,19,3),(13,17,19,23,4),(17,19,23,29,0),
               (19,23,29,31,1),(23,29,31,37,2),(29,31,37,41,3),
               (31,37,41,43,4),(37,41,43,47,0))
PRIMES = (17,19,23,29,31,37)
ALL_PERMUTATIONS = tuple(itertools.permutations(range(6)))
assert len(ALL_PERMUTATIONS) == 720


def check_budget():
    if time.monotonic()-START > MAX_WALL_SECONDS:
        raise RuntimeError("ABORT_WALL_15S")


def save(x):
    # One-based residue in the 127-bit prime field.
    return ((x-1) % M) + 1


def signed_day_index(day):
    delta = day-F
    return (1 if delta == 0 else 2*delta+1 if delta > 0 else -2*delta)


def constants():
    # Generate all 46 nonlinear 5-vector stones simultaneously from seed.
    stones = [FIVE]
    coefs = (3,5,7,11,13)
    for step in range(2,47):
        old=stones[-1]
        new=tuple(save(old[k]**2 + coefs[k]*old[(k+1)%5] +
                       (step if k==0 else old[(k-1)%5])) for k in range(5))
        stones.append(new)
    return stones

STONES = constants()


def sauce(calculation_day, target_day):
    a=signed_day_index(calculation_day)
    b=signed_day_index(target_day)
    counts=(a,b,abs(target_day-calculation_day)+1,a+b,
            1 if target_day<calculation_day else 3 if target_day>calculation_day else 2)
    hidden=[]
    for k in range(7):
        c=DROP_WEIGHTS[k]
        x=save(counts[0]+sum(c[t]*counts[t+1] for t in range(4)) + sum(STONES[k]))
        for grind,kind in enumerate(HIDDEN_INDEX,1):
            x=save(x*x+3*x+STONES[k][kind]+grind)
        hidden.append(x)
    timeline={-k:hidden[k] for k in range(7)}
    visible=[]
    for i in range(1,47):
        p1,p3,p7=(timeline[i-d] for d in (1,3,7))
        stone=STONES[i-1]
        x=save(sum(stone[t]*counts[t] for t in range(5))+p1+3*p3+5*p7+i)
        for a,b,c,d,which in VIS_WEIGHTS:
            x=save(x*x+a*x+b*p1+c*p3+d*p7+stone[which])
        timeline[i]=x
        visible.append(x)
    bowls=tuple(save((counts[0]+(idx+1)*counts[1]+counts[2]+counts[3]+
                            counts[4]+PRIMES[idx]**2)**2+(idx+1)) for idx in range(6))
    last_order=None
    for iteration,(drop,stone) in enumerate(zip(visible,STONES),1):
        order=ALL_PERMUTATIONS[(drop-1)%720]
        pour=[0]*6
        for index,multiple in enumerate((3,5,7)):
            pour[index]=save(drop*drop+stone[index]*bowls[order[index]]+multiple*iteration)
        fresh=[0]*6
        for pos,bowl in enumerate(order):
            prev,nxt=order[(pos-1)%6],order[(pos+1)%6]
            s=bowls[bowl]+2*bowls[prev]+3*bowls[nxt]+pour[pos]+drop+stone[pos%5]
            fresh[bowl]=save(s*s+5*bowls[prev]*bowls[nxt]+iteration*(pos+1))
        bowls=tuple(fresh)
        last_order=order
    for stir in range(1,13):
        aggregate=save(sum(bowls)+149*stir)
        order=ALL_PERMUTATIONS[(aggregate-1)%720]
        fresh=[0]*6
        for pos,bowl in enumerate(order):
            prev,nxt=order[(pos-1)%6],order[(pos+1)%6]
            x=bowls[bowl]+3*bowls[prev]+5*bowls[nxt]+aggregate+stir+(pos+1)**2
            fresh[bowl]=save(x*x+7*bowls[prev]*bowls[nxt])
        bowls=tuple(fresh)
    return bowls,last_order


def stream_seed(day,seal=10, target_day=None):
    bowls,order=sauce(day,day if target_day is None else target_day)
    next_id=order[(order.index(0)+1)%6]
    first=save((bowls[0]+seal+181)**2+179*bowls[next_id]+seal)
    direction=save((first+seal+194)**2+193*first+197*bowls[5])
    return first, 1 if direction%2 else -1


def rank_from_seed(seed,step,choices):
    if not 1 <= choices <= M:
        raise ValueError('only bounded short-choice ranks are in scope')
    eligible=M//choices*choices
    # Independent direct modulo/interval test. A rejection under the cap is
    # not silently converted to a selected candidate.
    for count in range(20000):
        v=(seed-1+step*count)%M
        if v < eligible:
            return v%choices, count
    raise RuntimeError('ABORT_RANK_REJECTION_BUDGET')


def gates():
    G={0:F}
    for i in range(1,RADIUS+1):
        check_budget()
        seed,step=stream_seed(F,seal=1,target_day=F+i)
        gap=42+rank_from_seed(seed,step,922)[0]
        assert 42 <= gap <= 963
        G[i]=G[i-1]+gap
        seed,step=stream_seed(F,seal=1,target_day=F-i)
        gap=42+rank_from_seed(seed,step,922)[0]
        G[-i]=G[-i+1]-gap
    return G


def select_year(day,G):
    if not G[-RADIUS] <= day-MAX_DAY and G[RADIUS] >= day+MAX_DAY:
        raise ValueError('fixed gate radius insufficient')
    candidates=[]
    for a in range(-RADIUS,RADIUS):
        check_budget()
        if G[a] >= day:
            break
        for b in range(a+6,RADIUS+1):
            length=G[b]-G[a]
            if length>MAX_DAY:
                break
            if length>=252 and G[a]<day<=G[b]:
                candidates.append((length,G[a],a,b))
            if len(candidates)>MAX_CANDIDATES:
                raise RuntimeError('ABORT_CANDIDATE_CAP')
    candidates.sort()
    if not candidates:
        raise ValueError('no candidate year')
    seed,step=stream_seed(day)
    idx,steps=rank_from_seed(seed,step,len(candidates))
    length,opening,a,b=candidates[idx]
    return {'day':day,'rank1':idx+1,'candidateCount':len(candidates),
            'selected': [a,b], 'length':length,
            'minimumMonths':(length+122)//123,'rankRejections':steps,
            'selectedOpeningDay':opening,'selectedClosingDay':G[b],
            'seedSha256':hashlib.sha256(str(seed).encode()).hexdigest(),
            'rankStep':step,
            'shortCandidateRanks':[i+1 for i,(L,_,start,finish) in enumerate(candidates)
                                    if L<=1968]}


def main():
    # Dedicated direct-seed arithmetic can be tested without claiming the
    # chosen rank's normative candidate set. No guessed gate coordinates.
    checks=[]
    def checked(label, condition):
        if not condition:
            raise AssertionError(label)
        checks.append(label)
    checked('foundation count', signed_day_index(F) == 1)
    checked('next day count', signed_day_index(F+1) == 3)
    checked('previous day count', signed_day_index(F-1) == 2)
    checked('zero residue maps to max', save(0) == M)
    checked('modular wrap', save(M+1) == 1)
    for N in (1, 2, 3, 720, 922, 10000):
        for seed in (1, M, M-1, 123456789):
            for step in (-1,1):
                v,k=rank_from_seed(seed,step,N)
                assert 0 <= v < N and k < 20000
    checked('short-choice synthetic ranks', True)
    for invalid in (0,M+1):
        try:
            rank_from_seed(1,1,invalid)
        except ValueError:
            checks.append('reject out-of-domain choice '+str(invalid))
        else:
            raise AssertionError('invalid choice accepted')
    G=gates()
    checked('193 gate positions',len(G) == 2*RADIUS+1 == 193)
    checked('192 bounded positive gaps', all(42<=G[i+1]-G[i]<=963 for i in range(-RADIUS,RADIUS)))
    # Frozen, independently audited geometry: compare selected anchors only;
    # no data imported from the old Lua script or another branch.
    expected_gates={70:-15018240,76:-15016551,66:-15020181,
                    36:-15035001,42:-15033050,71:-15018117,77:-15016161}
    for index,value in expected_gates.items():
        if G[index]!=value:
            raise AssertionError(f'GATE_MISMATCH index={index}: {G[index]} != {value}')
    checked('seven frozen gate anchors',True)
    short={(a,b) for a in range(-RADIUS,RADIUS) for b in range(a+6,RADIUS+1)
           if 252<=G[b]-G[a]<=1968}
    expected_short={(36,42),(37,43),(38,44),(70,76),(71,77)}
    checked('exhaustive five short pairs',short==expected_short)
    native={-15017677:(66,76,3630),-15017114:(73,81,3839),
            -15017465:(72,84,5637),-15016813:(66,75,3562)}
    fresh_day=-15017676
    known_negative={-15033432,-15032867,-15034166,-15033568,-15034351,
                    -15033701,*native.keys()}
    checked('excluded ten known negative samples',len(known_negative)==10 and fresh_day not in known_negative)
    observations=[]
    for day in tuple(native)+(fresh_day,):
        check_budget()
        result=select_year(day,G)
        if day in native and (*result['selected'],result['length'])!=native[day]:
            raise AssertionError(f'NATIVE_MISMATCH day={day}: {result}')
        observations.append(result)
    checked('four accepted Native selection crosschecks',len(observations)==5)
    fresh=observations[-1]
    if (fresh['candidateCount'],fresh['rank1'],fresh['selected'],fresh['length']) != (69,56,[71,82],5294):
        raise AssertionError('fresh-day rank fixture changed; do not claim independent prediction')
    checked('held-out selected rank outside both short intervals', fresh['rank1'] not in fresh['shortCandidateRanks'])
    checked('held-out prediction within 252..5778',252<=fresh['length']<=5778)
    report={'projectId':PROJECT_ID,'sourceLockCommit':SOURCE_LOCK_COMMIT,
            'normativeSourceBlob':CANONICAL_BLOB,
            'gateAnchorChecks':len(expected_gates),'shortPairs':len(short),
            'independentGateComputations':2*RADIUS,
            'wallSecondsLimit':MAX_WALL_SECONDS,'selfTestsPassed':len(checks),
            'posixCpuSecondsCap':20 if resource is not None else None,
            'posixVirtualBytesCap':192*1024*1024 if resource is not None else None,
            'historicalFourTargetIndependentCrosscheck':'4/4 PASS',
            'rankSelectionObservations':observations,
            'boundedStaticIndependentImplementation':'PASS',
            'nativeFreshDay':'NOT_RUN','newDaySelection':'INDEPENDENT_PYTHON_PREDICTION_NOT_NATIVE',
            'fullDate':'NOT_RUN','composition':'NOT_INVOKED'}
    output=json.dumps(report,sort_keys=True,separators=(',',':'))
    check_budget()
    print(output)
    print(f'STATIC_PYTHON_SELFTEST: {len(checks)}/{len(checks)} PASS')
    print('REPORT_SHA256:',hashlib.sha256((output+'\n').encode()).hexdigest())

if __name__=='__main__':
    main()
