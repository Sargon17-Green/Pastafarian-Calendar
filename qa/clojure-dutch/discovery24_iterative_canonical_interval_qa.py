#!/usr/bin/env python3
"""DISCOVERY24 QA-only iterative suffix-language bounds; independent of production.

Never imports production code/oracle, never assumes memo-graph cost equals the
production path. A budget gate counts only mandatory rank-path candidate charges.
A CI ZIP provides canonical source-locked data; independently re-extracting the
calendar input from Clojure is OUT OF SCOPE and is not claimed here.
"""
import argparse
import hashlib
import json
import sys
import zipfile
from itertools import permutations
from math import factorial

PROJECT_ID = 'PC-BRANCH-CLOJURE-DUTCH'
CANONICAL_SHA = 'ec0051ec6335fe178c03bcf3583b3dbfec1ffa84'
CANONICAL_ARTIFACT_SHA256 = 'eb7c55739ab2ff9c237138c4f2a8a28ebfd006cfe00d373ca1621c8b8e460cd5'
BUDGET = 5_000_000


def moves(state):
    counts, opened, closed = state
    for index in range(min(len(counts), opened + 1)):
        before = counts[index]
        if before == 0 or (before == 1 and index != closed):
            continue
        child = list(counts)
        child[index] -= 1
        yield index + 1, (tuple(child), max(opened, index + 1), closed + (before == 1))


class IntervalCounter:
    def __init__(self, profile):
        self.facts = [factorial(i) for i in range(sum(profile) + 1)]
        self.exact = {}

    def fallback(self, state):
        counts = state[0]
        n = sum(counts)
        if n == 0:
            return (1, 1)
        denominator = 1
        for k in counts:
            denominator *= self.facts[k]
        return (1, self.facts[n] // denominator)

    def count(self, root, cap):
        if cap < 0:
            raise ValueError('negative investigation cap')
        if root in self.exact:
            return self.exact[root], 0
        edges, seen, stack = {}, set(), [root]
        while stack and len(seen) < cap:
            state = stack.pop()
            if state in seen or state in self.exact:
                continue
            seen.add(state)
            if sum(state[0]) == 0:
                edges[state] = ()
            else:
                children = tuple(child for _, child in moves(state))
                if not children:
                    raise AssertionError(('unreachable legal suffix', state))
                edges[state] = children
                stack.extend(reversed(children))
        bounds = {}
        for state in sorted(seen, key=lambda s: sum(s[0])):
            if not edges[state]:
                bounds[state] = (1, 1)
            else:
                pairs = [bounds.get(child, self.exact.get(child)) or self.fallback(child)
                         for child in edges[state]]
                low = sum(p[0] for p in pairs)
                high = min(sum(p[1] for p in pairs), self.fallback(state)[1])
                assert 1 <= low <= high
                bounds[state] = (low, high)
            if bounds[state][0] == bounds[state][1]:
                self.exact[state] = bounds[state]
        return bounds.get(root, self.exact.get(root)) or self.fallback(root), len(seen)


def rank_trace(profile, ordinal, position, cap=4096, budget=BUDGET,
               word_oracle=None):
    if len(profile) < 2 or any(n < 2 for n in profile):
        raise ValueError('invalid profile')
    if not (1 <= ordinal and 1 <= position <= sum(profile)):
        raise ValueError('invalid rank or position')
    if not (1 <= budget <= BUDGET):
        raise ValueError('invalid production budget')
    if word_oracle is not None and ordinal > len(word_oracle):
        raise ValueError('rank outside independently enumerated legal words')
    counter = IntervalCounter(profile)
    state = (tuple(profile), 0, 0)
    rank_lo = rank_hi = ordinal
    prefix, billed, explored, tested, skipped = [], 0, 0, 0, 0
    while len(prefix) < position:
        chosen = False
        legal = tuple(moves(state))
        for letter, child in legal:
            charge = 1 + (len(profile) - child[1] + 1) * (1 + sum(child[0]))
            if billed + charge > budget:
                return dict(status='BUDGET_REFUSAL', prefix_length=len(prefix),
                            candidate=letter, billed=billed, required_next=billed+charge,
                            tested=tested, explored=explored)
            if len(legal) == 1:
                # No competing legal next letter; globally valid ranks must
                # select this edge. Production would still bill this candidate.
                billed += charge
                tested += 1
                prefix.append(letter)
                state = child
                chosen = True
                break
            interval, expansions = counter.count(child, cap)
            explored += expansions
            lower, upper = interval
            if word_oracle is not None:
                current = tuple(prefix + [letter])
                true = sum(w[:len(current)] == current for w in word_oracle)
                assert lower <= true <= upper
            if rank_lo > upper:
                decision = 'skip'
            elif rank_hi <= lower:
                decision = 'take'
            else:
                return dict(status='UNPROVEN_SUFFIX_INTERVAL', prefix_length=len(prefix),
                            candidate=letter, count_interval_digits=(len(str(lower)), len(str(upper))),
                            rank_interval_digits=(len(str(rank_lo)), len(str(rank_hi))),
                            billed_before_candidate=billed, candidate_charge=charge,
                            explored=explored, tested=tested)
            billed += charge
            tested += 1
            if decision == 'skip':
                rank_lo, rank_hi = rank_lo-upper, rank_hi-lower
                assert 1 <= rank_lo <= rank_hi
                skipped += 1
            else:
                prefix.append(letter)
                state = child
                chosen = True
                break
        if not chosen:
            raise AssertionError('no certified next letter')
    if word_oracle is not None:
        assert tuple(prefix) == word_oracle[ordinal-1][:position]
    return dict(status='CERTIFIED_PREFIX', prefix=prefix,
                rank_exact=(rank_lo == rank_hi), billed=billed,
                tested=tested, skipped=skipped, explored=explored)


def brute(profile):
    raw = tuple(i+1 for i, k in enumerate(profile) for _ in range(k))
    accepted = []
    for word in sorted(set(permutations(raw))):
        starts = [word.index(i) for i in range(1, len(profile)+1)]
        ends = [len(word)-word[::-1].index(i)-1 for i in range(1, len(profile)+1)]
        if starts == sorted(starts) and ends == sorted(ends):
            accepted.append(word)
    return accepted


def self_test():
    profiles = ((2,2),(2,3),(3,2),(2,2,2),(3,3,2),(4,4))
    total_words = checks = refusals = 0
    for profile in profiles:
        words = brute(profile)
        total_words += len(words)
        for rank, word in enumerate(words, 1):
            for pos in range(1, len(word)+1):
                result = rank_trace(profile, rank, pos, 4096, word_oracle=words)
                assert result['status'] == 'CERTIFIED_PREFIX'
                assert tuple(result['prefix']) == word[:pos]
                edge = rank_trace(profile, rank, pos, 4096,
                                  result['billed'], words)
                assert edge['status'] == 'CERTIFIED_PREFIX'
                if result['billed'] > 1:
                    less = rank_trace(profile, rank, pos, 4096,
                                      result['billed']-1, words)
                    assert less['status'] == 'BUDGET_REFUSAL'
                    refusals += 1
                checks += 1
    assert (total_words, checks, refusals) == (59, 436, 436)
    long = rank_trace((123,)*29, 1, 2, 64)
    assert long['status'] in ('UNPROVEN_SUFFIX_INTERVAL', 'BUDGET_REFUSAL', 'CERTIFIED_PREFIX')
    return dict(tiny_profiles=6, tiny_words=total_words, exact_rank_prefix_checks=checks,
                exact_budget_boundary_checks=checks, budget_minus_one_refusals=refusals,
                long_profile_status=long['status'], canonical_acceptance=False)


def canonical(zip_path, cap):
    with open(zip_path, 'rb') as f:
        digest = hashlib.sha256(f.read()).hexdigest()
    if digest != CANONICAL_ARTIFACT_SHA256:
        raise ValueError('canonical ZIP SHA256 mismatch')
    if hasattr(sys, 'set_int_max_str_digits'):
        sys.set_int_max_str_digits(25000)
    with zipfile.ZipFile(zip_path) as z:
        d = json.loads(z.read('discovery24_canonical_dp_input.json'))
        old = json.loads(z.read('discovery24_canonical_dp_result.json'))
    if d['project_id'] != PROJECT_ID or d['source_sha'] != CANONICAL_SHA:
        raise ValueError('project/source mismatch')
    if old['source_sha'] != d['source_sha'] or old['status'] != 'DP_FEASIBILITY_UNPROVEN':
        raise ValueError('prior diagnostic identity/status mismatch')
    if not all(d[k] is True for k in ('production_year_matches_normative',
                                       'production_profile_matches_normative',
                                       'production_rank_matches_normative')):
        raise ValueError('prior normative crosscheck missing')
    profile = tuple(d['profile'])
    rank = int(d['weaving_rank'])
    assert (len(profile), sum(profile), len(d['weaving_rank']), d['search_budget']) == (33,3569,5288,128)
    assert d['production_weaving_rank'] == d['weaving_rank']
    assert 1 <= rank <= int(d['weaving_total'])
    reports = {}
    for pos in (82,520):
        reports[f'p{pos}'] = rank_trace(profile, rank, pos, cap)
    return dict(status='QA_ONLY', project_id=PROJECT_ID, prior_source_sha=CANONICAL_SHA,
                artifact_sha256=digest, normative_crosscheck='ACCEPTED_CI_ASSERTIONS_NOT_RERUN',
                profile_months=len(profile), profile_days=sum(profile), rank_digits=len(d['weaving_rank']),
                investigation_state_cap_per_candidate=cap, production_budget_unchanged=BUDGET,
                search_budget_unchanged=128, results=reports,
                five_field_differential='NOT_RUN', new_native='NOT_RUN', stage2='OPEN')


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--artifact-zip')
    p.add_argument('--expansion-cap', type=int, default=4096)
    a = p.parse_args()
    if not 0 <= a.expansion_cap <= 10000:
        p.error('bounded QA expansion cap must be 0..10000')
    print('SELFTEST', json.dumps(self_test(),sort_keys=True))
    if a.artifact_zip:
        print('CANONICAL',json.dumps(canonical(a.artifact_zip,a.expansion_cap),sort_keys=True))


if __name__ == '__main__':
    main()
