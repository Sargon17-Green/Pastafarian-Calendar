#!/usr/bin/env python3
"""Independent exact suffix counter for DISCOVERY24 Clojure+Nederlands.

Scope: QA only, no production imports, no new Native/CI or Stage2 acceptance.
Proof: In any completed legal suffix, last closure is of its largest live label j.
Remove all j copies from a legal word: a legal smaller-label word remains. All
j insertions use gaps after first occurrence of j-1 iff j-1 was not previously
opened (j > initially_opened+1), and at least one j occupies the final gap to
preserve the increasing last-closure order. Fixing the first j insertion at gap
a determines j's first index a+1; the remaining insertions are counted by a
binomial coefficient. Hence a 1D distribution of first-max positions is exact.
"""
import argparse
import hashlib
import json
import math
from functools import lru_cache
import sys
import zipfile
from itertools import permutations
from time import perf_counter

PROJECT_ID = 'PC-BRANCH-CLOJURE-DUTCH'
CANONICAL_SOURCE_SHA = 'ec0051ec6335fe178c03bcf3583b3dbfec1ffa84'
CANONICAL_ARTIFACT_SHA256 = 'eb7c55739ab2ff9c237138c4f2a8a28ebfd006cfe00d373ca1621c8b8e460cd5'
BUDGET = 5_000_000
SEARCH_BUDGET = 128


def moves(state):
    counts, opened, closed = state
    m = len(counts)
    for i in range(min(m, opened + 1)):
        before = counts[i]
        if before == 0 or (before == 1 and i != closed):
            continue
        child = list(counts)
        child[i] -= 1
        yield i + 1, (tuple(child), max(opened, i + 1), closed + int(before == 1))


@lru_cache(maxsize=1024)
def tail_factor(active_days, unopened_counts, first_constrained=False):
    """Insertion language for unopened months, normalized per active word.

    For its first new month the first-open condition is free unless the source
    has *no* pre-opened months (initial root state); later months must open
    after the preceding new month. Each last closure is increasing, hence the
    newest inserted month is always the final symbol. The previous base word
    may be arbitrary: its first active symbol is irrelevant for a free insert.
    """
    if not unopened_counts:
        return 1
    n=active_days
    dp=None
    for step,k in enumerate(unopened_counts):
        if k < 1:raise ValueError('unopened counts must be positive')
        if dp is None:
            total=1
        else:
            total=sum(dp)
        constrained=bool(step>0 or first_constrained)
        # An initial/root base has one single word of a repeated letter; its
        # first position is 1. For a free first insertion, no state is needed.
        pref=0
        new=[0]*(n+k+1)
        weights=[1]*(n+1)
        if k>=2:
            for t in range(1,n+1):
                weights[t]=weights[t-1]*(t+k-2)//t
        for a in range(n+1):
            if constrained:
                if dp is None:
                    if a>=1:pref=1
                elif a:
                    pref+=dp[a]
            ways=1 if a==n else (weights[n-a] if k>=2 else 0)
            new[a+1]=(pref if constrained else total)*ways
        n+=k
        dp=new
    return sum(dp)


@lru_cache(maxsize=2048)
def exact_suffix_count(state):
    counts,opened,closed=state
    m=len(counts)
    if not (0<=closed<=opened<=m):
        raise ValueError('invalid grammar indices')
    if any(counts[:closed]) or any(k<1 for k in counts[closed:]):
        raise ValueError('unreachable live counts')
    if closed==m:return 1
    base=1
    n=counts[closed]
    if opened==closed:
        # All previously opened species have already closed; the smallest
        # live one is the forced first *new* month of this suffix.
        return tail_factor(n,tuple(counts[closed+1:]),True)
    for i in range(closed+1,opened):
        k=counts[i]
        n+=k
        base*=math.comb(n-1,k-1)
    return base*tail_factor(n,tuple(counts[opened:]))

def exact_trace(profile, ordinal, target_position, budget=BUDGET):
    """Independent rank path with the SHARED cost of prefix-op-rang-begrensd.

    Its first forced 1 is free; active letter counts share a single charge,
    and a subsequent unopened candidate has a separate shared-factor charge.
    This is NOT the per-candidate raming of weving-op-rang-groot.
    """
    if len(profile) < 2 or any(k < 2 for k in profile):
        raise ValueError('invalid initial profile')
    if not (1 <= target_position <= sum(profile)):
        raise ValueError('invalid target position')
    if not 1 <= budget <= BUDGET:
        raise ValueError('invalid budget')
    root = (tuple(profile), 0, 0)
    total = exact_suffix_count(root)
    if not 1 <= ordinal <= total:
        raise ValueError('ordinal outside legal language')
    first = dict(moves(root))[1]
    state = first
    rank = ordinal
    prefix, billed, tested, skipped, charged_active, charged_new = [1], 0, 0, 0, 0, 0
    while len(prefix) < target_position:
        counts, opened, closed = state
        legal = list(moves(state))
        active = [(letter, child) for letter, child in legal if letter <= opened]
        new = [(letter, child) for letter, child in legal if letter == opened + 1]
        found = False
        if active:
            charge = 1 + (len(profile) - opened) * sum(counts)
            if billed + charge > budget:
                return dict(status='BUDGET_REFUSAL', prefix_length=len(prefix),
                            group='ACTIVE', candidate=active[0][0], billed=billed,
                            required_next=billed + charge, tested=tested, skipped=skipped,
                            certified_prefix=prefix, opened=opened, closed=closed,
                            active_charge_groups=charged_active, new_charge_groups=charged_new)
            billed += charge
            charged_active += 1
            for letter, child in active:
                count = exact_suffix_count(child)
                tested += 1
                if rank > count:
                    rank -= count
                    skipped += 1
                else:
                    prefix.append(letter)
                    state = child
                    found = True
                    break
        if not found and new:
            charge = 1 + (len(profile) - opened - 1) * sum(counts)
            if billed + charge > budget:
                return dict(status='BUDGET_REFUSAL', prefix_length=len(prefix),
                            group='NEW', candidate=new[0][0], billed=billed,
                            required_next=billed + charge, tested=tested, skipped=skipped,
                            certified_prefix=prefix, opened=opened, closed=closed,
                            active_charge_groups=charged_active, new_charge_groups=charged_new)
            billed += charge
            charged_new += 1
            letter, child = new[0]
            count = exact_suffix_count(child)
            tested += 1
            if rank > count:
                raise AssertionError(('new candidate insufficient',len(prefix),rank,count))
            prefix.append(letter)
            state = child
            found = True
        if not found:
            raise AssertionError(('no legal next letter',len(prefix),rank))
    return dict(status='CERTIFIED_PREFIX', prefix=prefix,
                residual_rank_digits=len(str(rank)), billed=billed,
                tested=tested, skipped=skipped,active_charge_groups=charged_active,
                new_charge_groups=charged_new)

def brute_words(profile):
    letters = tuple(i+1 for i, k in enumerate(profile) for _ in range(k))
    accepted = []
    for word in sorted(set(permutations(letters))):
        starts = [word.index(i+1) for i in range(len(profile))]
        ends = [len(word)-1-word[::-1].index(i+1) for i in range(len(profile))]
        if starts == sorted(starts) and ends == sorted(ends):
            accepted.append(word)
    return accepted


def tiny_tests():
    profiles = ((2,2), (2,3), (3,2), (2,2,2), (3,3,2), (4,4))
    words_count = comparisons = prefix_checks = refused = 0
    states = {}
    for profile in profiles:
        words = brute_words(profile)
        words_count += len(words)
        for word in words:
            state = (tuple(profile), 0, 0)
            for depth in range(len(word) + 1):
                key = (profile, state)
                states.setdefault(key, (depth, 0))
                depth0, count0 = states[key]
                assert depth0 == depth
                states[key] = (depth, count0 + 1)
                if depth < len(word):
                    state = dict(moves(state))[word[depth]]
        for rank, word in enumerate(words, 1):
            for target in range(1, len(word) + 1):
                result = exact_trace(profile, rank, target)
                assert result['status'] == 'CERTIFIED_PREFIX'
                assert tuple(result['prefix']) == word[:target]
                assert exact_trace(profile, rank, target, max(1, result['billed']))['status'] == 'CERTIFIED_PREFIX'
                if result['billed'] > 1:
                    less = exact_trace(profile, rank, target, result['billed'] - 1)
                    assert less['status'] == 'BUDGET_REFUSAL'
                    refused += 1
                prefix_checks += 1
    for (profile, state), (depth, freq) in states.items():
        # Every suffix from this fixed grammar state has freq legal extensions.
        # The same state can appear from distinct prefixes; normalize by
        # counting how many *distinct* word prefixes reached it.
        matching = set()
        for w in brute_words(profile):
            pref = w[:depth]
            st = (tuple(profile), 0, 0)
            for v in pref:
                st = dict(moves(st))[v]
            if st == state:
                matching.add(pref)
        assert len(matching) > 0 and freq % len(matching) == 0
        expected = freq // len(matching)
        got = exact_suffix_count(state)
        assert got == expected, (profile, state, expected, got)
        comparisons += 1
    assert (words_count, prefix_checks, refused) == (59, 436, 377)
    # Same full multiset may yield different suffix counts depending on prior
    # first openings. Test all short profiles using independent suffix brute.
    extra = 0
    for p in ((2,2),(2,3),(2,2,2)):
        for opened in range(len(p)+1):
            s = (p, opened, 0)
            expected = 0
            for w in sorted(set(permutations(tuple(i+1 for i,k in enumerate(p) for _ in range(k))))):
                starts = [w.index(i) for i in range(opened+1,len(p)+1)]
                ends = [len(w)-1-w[::-1].index(i) for i in range(1,len(p)+1)]
                if starts == sorted(starts) and ends == sorted(ends):
                    expected+=1
            assert expected == exact_suffix_count(s)
            extra+=1
    return dict(tiny_profiles=6, legal_words=words_count,
                unique_reachable_state_checks=comparisons,
                extra_opened_state_checks=extra,
                rank_prefix_checks=prefix_checks, exact_budget_accepts=prefix_checks,
                budget_minus_one_refusals=refused, independent_oracle='brute_multiset_permutations',
                production_imported=False)


def canonical(path):
    with open(path,'rb') as handle:
        digest = hashlib.sha256(handle.read()).hexdigest()
    if digest != CANONICAL_ARTIFACT_SHA256:
        raise ValueError('canonical artifact digest mismatch')
    with zipfile.ZipFile(path) as z:
        data = json.loads(z.read('discovery24_canonical_dp_input.json'))
        old = json.loads(z.read('discovery24_canonical_dp_result.json'))
    assert data['project_id'] == PROJECT_ID
    assert data['source_sha'] == CANONICAL_SOURCE_SHA
    assert old['source_sha'] == CANONICAL_SOURCE_SHA
    assert old['status'] == 'DP_FEASIBILITY_UNPROVEN'
    assert all(data[k] is True for k in ('production_year_matches_normative',
        'production_profile_matches_normative','production_rank_matches_normative'))
    p = tuple(data['profile'])
    rank = int(data['weaving_rank']); recorded_total=int(data['weaving_total'])
    assert (len(p),sum(p),len(data['weaving_rank']),data['search_budget']) == (33,3569,5288,SEARCH_BUDGET)
    assert data['production_weaving_rank'] == data['weaving_rank']
    computed_total = exact_suffix_count((p,0,0))
    assert computed_total == recorded_total, 'independent exact count differs from source-locked total'
    assert 1 <= rank <= computed_total
    first = dict(moves((p,0,0)))[1]
    after11 = dict(moves(first))[1]
    count11 = exact_suffix_count(after11)
    results={f'p{n}':exact_trace(p,rank,n) for n in (82,520)}
    for key,result in results.items():
        assert result['status']=='BUDGET_REFUSAL', (key,result['status'])
        assert (result['prefix_length'],result['group'],result['billed'],result['required_next']) == (81,'ACTIVE',4995675,5002652)
        result['certified_prefix_sha256']=hashlib.sha256(
            ','.join(map(str,result.pop('certified_prefix'))).encode('ascii')).hexdigest()

    return dict(project_id=PROJECT_ID,source_sha=CANONICAL_SOURCE_SHA,
        artifact_sha256=digest,profile_months=len(p), profile_days=sum(p),
        rank_digits=len(str(rank)), total_digits=len(str(computed_total)),
        independent_total_equals_prior_Clojure=True,
        prefix_11_count_digits=len(str(count11)),rank_greater_than_prefix_11_count=rank>count11,
        budget=BUDGET,search_budget=SEARCH_BUDGET,targets=results,
        new_ci='NOT_RUN',new_native='NOT_RUN',five_field_differential='NOT_RUN',stage2='OPEN')


def main():
    if hasattr(sys, 'set_int_max_str_digits'):sys.set_int_max_str_digits(25000)
    parser=argparse.ArgumentParser()
    parser.add_argument('--artifact-zip')
    args=parser.parse_args()
    st=perf_counter()
    tiny=tiny_tests()
    print('SELFTEST',json.dumps(tiny,sort_keys=True))
    if args.artifact_zip:
        print('CANONICAL',json.dumps(canonical(args.artifact_zip),sort_keys=True))
    print('ELAPSED_SEC',round(perf_counter()-st,3))

if __name__ == '__main__':main()
