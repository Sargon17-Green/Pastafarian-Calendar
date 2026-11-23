#!/usr/bin/env python3
"""DISCOVERY24 second independent oracle: whole-word brute enumeration, not tel-rest.
This verifies shared active/new billing, first-open/last-close, exact/minus-one.
No production import, no Native claim. Small grammar only (some 1-day edge cases).
"""
import json
from collections import defaultdict
from itertools import permutations

PROJECT_ID = 'PC-BRANCH-CLOJURE-DUTCH'
# Verified in live src/pastafari/maandrang.clj: prefix-gedeelde-raming
# uses 1 + (count(restvector) - geopend) * sum(restvector).
PRODUCTION_BLOB = '62f304dc013a9a9f70475bb0d34f186838b27318'


def words(counts):
    pool = tuple(i+1 for i,k in enumerate(counts) for _ in range(k))
    result = []
    for word in sorted(set(permutations(pool))):
        first = [word.index(i) for i in range(1,len(counts)+1)]
        last = [len(word)-1-word[::-1].index(i) for i in range(1,len(counts)+1)]
        if first == sorted(first) and last == sorted(last):
            result.append(word)
    return result


def check(profile):
    all_words = words(profile)
    children = defaultdict(list)
    for w in all_words:
        for j in range(1,len(w)+1): children[w[:j]].append(w)
    totals = dict(words=len(all_words),prefixes=0,minus_one_refusals=0,opens=0,
                  closes=0,simultaneous=0,active_charges=0,new_charges=0,skipped=0)
    for rank,w in enumerate(all_words,1):
        for target in range(1,len(w)+1):
            budget_used=0
            residual=rank
            for i in range(1,target):
                prefix=w[:i]; selected=w[i]; m=len(profile)
                left=[profile[k]-prefix.count(k+1) for k in range(m)]
                opened=max(prefix); remaining=sum(left)
                legal=[(v,len(children[prefix+(v,)])) for v in range(1,m+1)
                       if prefix+(v,) in children]
                active=[v for v,_ in legal if v<=opened]
                newer=[v for v,_ in legal if v==opened+1]
                assert selected in [v for v,_ in legal] and len(newer)<=1
                if active:
                    budget_used+=1+(m-opened)*remaining
                    totals['active_charges']+=1
                if selected==opened+1:
                    assert newer==[selected]
                    budget_used+=1+(m-opened-1)*remaining
                    totals['new_charges']+=1
                    totals['opens']+=1
                if left[selected-1]==1:
                    totals['closes']+=1
                    if selected==opened+1:totals['simultaneous']+=1
                for v,k in legal:
                    if v<selected:
                        residual-=k
                        totals['skipped']+=1
                assert 1<=residual<=len(children[prefix+(selected,)])
            # Oracle B rebuilds expenses independently from the fixed word's
            # transitions, not from the rank-skip traversal above.
            expected=sum((1+(len(profile)-max(w[:i]))*(sum(profile)-i)
                          if any(w[:i]+(v,) in children for v in range(1,max(w[:i])+1)) else 0)
                          + (1+(len(profile)-max(w[:i])-1)*(sum(profile)-i)
                             if w[i]==max(w[:i])+1 else 0)
                         for i in range(1,target))
            assert budget_used==expected
            totals['prefixes']+=1
            if expected>=2:
                assert expected-1<budget_used
                totals['minus_one_refusals']+=1
    return dict(profile=list(profile), **totals)


def main():
    profiles=((2,2),(2,3),(3,2),(2,2,2),(2,3,2),(3,2,2),(2,2,2,2),(4,4),
              (2,1),(1,2),(1,1,2),(2,1,1))
    details=[check(p) for p in profiles]
    total={k:sum(x[k] for x in details) for k in
           ('words','prefixes','minus_one_refusals','opens','closes','simultaneous',
            'active_charges','new_charges','skipped')}
    assert total['simultaneous']>0 and total['closes']>0 and total['opens']>0
    print(json.dumps(dict(project_id=PROJECT_ID,scope='MODEL_ONLY',result='PASS',
          source_blob=PRODUCTION_BLOB,profiles=details,totals=total,
          ci='NOT_RUN',native='NOT_RUN',stage2='OPEN'),sort_keys=True))

if __name__=='__main__':main()
