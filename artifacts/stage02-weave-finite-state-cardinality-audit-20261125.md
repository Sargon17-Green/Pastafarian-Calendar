# Stage02 — finite-state cardinality cross-check (2026-11-25)
PROJECT_ID: PC-BRANCH-WAT-SPANISH
Baseline live HEAD: 3aca128a111b419dc39412147eff429753960776 (identical compare).
Reference: tests/stage02_calendar_weave_independent_oracle.py, blob 5793a3a9e310f6515d33fd86362324ba0f577a34. Its documented H recurrence is re-expressed, not executed in this check.

Contract: lengths >= 2, ordered first and last appearances, exact integer family cardinality. Direct memoized state search counts one path per admissible word; state is the remaining multiplicities. An untouched month may be introduced only if it is the first untouched month; a final occurrence is legal only if all earlier months are exhausted. This counts independently of the H recurrence and does not construct a rank order. Five families, including one previously only structurally tested, compared against the explicitly re-expressed recurrence. No other branch used.

Local Linux Python 3.13.5, timeout 25s, exit 0 (pipeline exit 0/0).
Local script SHA256 f8eee43a72e03b187e67dd6b797871d5eb956ba5f4643651e76d5f73731c29ef.
Output JSON SHA256 1f0ecaee23c57f2e0ec20ca5f0d8faf6e573d165963c88844385e26e035b2146 (including LF).
```json
{"cases": [{"direct_count": "42", "lengths": [2, 2, 2, 2, 2], "match": true, "reference_count": "42", "states": 21}, {"direct_count": "697", "lengths": [3, 4, 2, 3], "match": true, "reference_count": "697", "states": 48}, {"direct_count": "177260", "lengths": [4, 4, 4, 4], "match": true, "reference_count": "177260", "states": 179}, {"direct_count": "12502111", "lengths": [2, 3, 4, 5, 6], "match": true, "reference_count": "12502111", "states": 415}, {"direct_count": "110149940369327776552117", "lengths": [3, 4, 5, 6, 7, 8, 9], "match": true, "reference_count": "110149940369327776552117", "states": 79439}], "gate": "CARDINALITY_RECURRENCE_MATCH", "native_pass": false, "project": "PC-BRANCH-WAT-SPANISH", "stage02_accepted": false}
```

Reproduction script (local direct_count.py):
```python
#!/usr/bin/env python3
"""Independent finite-state cardinality audit, not WAT execution."""
from functools import lru_cache
from math import comb
import json

FAMILIES = [(2,2,2,2,2), (3,4,2,3), (4,4,4,4), (2,3,4,5,6), (3,4,5,6,7,8,9)]

def direct_count(lengths):
    m = len(lengths)
    @lru_cache(None)
    def count(rem):
        if not any(rem):
            return 1
        next_new = next((i for i in range(m) if rem[i] == lengths[i]), m)
        total = 0
        for i in range(min(next_new + 1, m)):
            if not rem[i] or (rem[i] == 1 and any(rem[:i])):
                continue
            nxt = rem[:i] + (rem[i]-1,) + rem[i+1:]
            total += count(nxt)
        return total
    result = count(lengths)
    states = count.cache_info().currsize
    count.cache_clear()
    return result, states

def reference_recurrence(lengths):
    # Independent re-expression of the existing Python oracle's published H recurrence.
    # This does not execute or replace that source.
    bounds = [0]
    for n in lengths:
        bounds.append(bounds[-1]+n-1)
    row = [1]*(bounds[-1]+1)
    for i in range(len(lengths)-1, -1, -1):
        q = lengths[i]
        row = [sum(comb(q-2+t,t)*row[q-1+t] for t in range(r+1))
               for r in range(bounds[i]+1)]
    return row[0]

def main():
    cases = []
    for lengths in FAMILIES:
        direct, states = direct_count(lengths)
        ref = reference_recurrence(lengths)
        cases.append(dict(lengths=lengths,direct_count=str(direct),reference_count=str(ref),states=states,match=direct==ref))
    print(json.dumps(dict(project='PC-BRANCH-WAT-SPANISH',gate='CARDINALITY_RECURRENCE_MATCH' if all(x['match'] for x in cases) else 'CARDINALITY_MISMATCH',native_pass=False,stage02_accepted=False,cases=cases),sort_keys=True))
    return 0 if all(x['match'] for x in cases) else 1

if __name__ == '__main__':
    raise SystemExit(main())
```

CI lookup for d686f475bedb4e5f14f3cd95968595fa74460177 again returned empty PR-only listing and empty combined statuses; no duplicate dispatch. Direct connector cannot list push runs by SHA. Targeted Drive filename lookup by project ID / WAT+Español / WAT-Spanish returned no files; original historical ZIP/manifest NOT VERIFIED, not evidence of absence. Historical DISCOVERY01 contract explicitly distinguishes the missing original from new research. This audit is mathematical/local QA, not exact-source Python differential, WAT Native, or stage acceptance. NEXT: independent rank/offset expected outputs for large families; recover exact focused CI run and original ZIP/manifest.
