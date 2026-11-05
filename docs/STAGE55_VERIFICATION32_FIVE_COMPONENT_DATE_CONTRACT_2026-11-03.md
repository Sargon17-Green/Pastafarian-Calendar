# Stage55 / VERIFICATION32 — five-component calendar date, opt-in provider-backed adapter

PROJECT_ID: PC-BRANCH-PHP-MALAY | PHP+Bahasa-Melayu | 2026-11-03

## Verified entry gate
Stage54 SHA f7a549b461d2a1c21ad59585bd30e1948d4346e8, workflow #41617557721 completed/success with 25/25 jobs, exact PHP+Bahasa-Melayu branch. Dedicated PHP8.3.36 64-bit job #125854701197 passed PHP lint, 81 checks, 4 cases, 16 faults, 16 recoveries, 4 baselines, exit 0 and empty stderr. Artifact #13222500295 digest sha256:702843fd70926c644b485271e907be78427e62453a826ec727abd9876d2fff81.

## Engineering choice and boundary
The existing production PATCH22 resolves the target year, but no production five-component public date computation was available at the entry gate. Implement a new opt-in DateTuplePatch23 facade which calls the real production PATCH22 year traversal and assembles all five final components from a supplied, independently computed year structure. Do not copy NormativeOracle's year-structure algorithm or fixtures into production. In production, callers must supply an independently validated yearStructureProvider; this stage does NOT establish an autonomous production year-structure generator or a user-facing finalized calendar API.

## Input/output and independent differential oracle
Input: calculation day c=NormativeMath::FOUNDATION_DAY, target integer day, trusted Year5000 anchor; real PATCH22 proposed/canonical next/previous and gate callbacks; a year structure provider returning cutlets, monthCount, monthLengths, monthWeaving and monthNameIndices; exact traversal budget. Public output: exactly [year number (int), cutlet name (string), day in cutlet (int), month name (string), day in month (int)].

Test oracle is tests/oracle/NormativeOracle::calendarDate(c,target), which independently finds the target year and constructs its structure. Use three distinct genuine years 4999, 5000, 5001 and three locations per year (first, interior, last): 9 targets * 5 component-wise exact comparisons = 45; do not compare only targetYearCandidate. Production locates cutlet through a validated sorted partition and binary search and calculates month position using occurrence counts within the prefix of the weaving. Source-language names are resolved from the production catalog. The oracle's year-structure generation never enters production.

## Structural and failure gates
- Reject a discontinuous cutlet partition, wrong weaving length, out-of-range month ID, invalid canonical month name, mismatch between month lengths and weaving counts, and non-array provider result (6 invalid cases).
- Two one-step traversal cases must reject a zero step budget before the structure provider is called.
- Throwing structure provider must propagate its exact error; the same target then succeeds and matches its baseline.
- Input years and structures remain byte-for-byte serialized-identical.
- If the year provider remains test-only, report Stage55 as provider-backed integration evidence, not standalone full native date production.

## Native acceptance
GitHub Actions push on exact PHP+Bahasa-Melayu SHA; new stage55-five-components-native PHP 8.3, 64-bit, memory=512M, max runtime=900s, lint PASS, empty stderr, exit=0; stdout exactly matches:
^STAGE55_FIVE_COMPONENTS checks=[0-9]+ targets=9 components=45 invalid=6 budgets=2 recoveries=1$
Artifact must include PROJECT_ID, STAGE=55, source SHA, PHP version, stdout/stderr, exit. Require all 26/26 workflow jobs completed/success on same SHA and verified artifact digest. Queued/in_progress is neither PASS nor blocker. No main/merge or publishing.

## NEXT
If Native fails, inspect actual logs and repair only a proven defect. On GREEN, close Stage55 and plan independent production year-structure generation (not injected Oracle), validating full five-component dates on multiple independent years and boundaries. No claim of standalone full-calendar production until that separate gate passes.

## 2026-11-04 bounded repair attempt — no acceptance implied
Actions #41712461872 on cf4b938680ca187c0532b92098f5ebc56dd9ff79: 25/26 jobs success, stage55-five-components-native #126183744066 failure. PHP 8.3.36 64-bit and both lint passes; fatal 512MiB exhaustion in tests/oracle/OrderedFamilies.php WeavingCounter::count, line 245 before the five-component acceptance line. Failed diagnostic artifact #13268847518, SHA256 a4c3397b51886405bd402202615600fb24f142d52151e0e662cae525cb67dffb.

Implement a test-oracle-only lossless compact memo key (one unsigned byte per remaining month count plus both frontiers) for input lengths <=255 and monthCount <=255; retain textual encoding otherwise. Add a separate test with independently exhaustive multiset-word enumeration on four small vectors, checking exact count and all 53 unrank positions. Preserve 512MiB / 900s and all 26/26 requirements; this change is unaccepted until the full native run completes and proves the original full-date acceptance line. If memory remains inadequate, pursue a bounded alternative exact counting algorithm, not a higher limit or fixture substitution.


## 2026-11-04 — second Native failure and exact polynomial insertion remedy (pending full CI)

On unchanged HEAD b812b9363aeaf0039d2480d1487aee294192de68, Actions #41776056152 completed/failure (25/26 jobs successful). stage55-five-components-native #126396556471: PHP 8.3.36 64-bit, 3 lint PASS; independent microgate STAGE55_MEMO_EXACT cases=4 ranks=53 PASS, but full date generation exceeded 512MiB in WeavingCounter::count (line 255). Evidence artifact #13297286509 (ZIP SHA256=13b34b4e586f673c69cbff83c9d63d9776b343dd55a34b9c457a59214ec7074a). Full-date Stage55 acceptance NOT achieved.

Replace the exponential recursive state memo *only in tests/oracle/OrderedFamilies.php* with an exact insertion DP. For a suffix of unopened month symbols, H[k][t] counts valid interleavings when t existing suffix symbols follow the last new month's first appearance. Inserting a month k with a copies, if d old suffix symbols follow its first occurrence, exactly C(a+d-2,d) placements remain when the last occurrence must follow all older symbols. Therefore H[k][t] = sum(d=0..t) C(a+d-2,d) H[k+1][a-1+d], with H[m+1][t]=1. The incremental prefix sum computes each row in O(t) BigInt operations; no floating point and exact integer division only. Already opened (but not closed) months have only ordered-last restrictions and contribute product over i of C(prefixRemaining+a_i-1, prefixRemaining). The result is that product times H[opened+1][sum(activeRemaining)]. Rows store exact base-10 BigInt values with reversible zlib compression to bound memory; they do not store approximations. This is a test-oracle-only performance implementation: production DateTuplePatch23 is unchanged.

Local PHP 8.4 isolated prototype (separate minimal arithmetic harness, NOT Native project acceptance): independent brute-force enumeration verified count and every rank for 10 small vectors including all four official vectors; official regression comprises 4 cases/53 exact ranks. Count/unrank performance samples with 512MiB: 32 months*70=2240 symbols ~3.8s/72MiB; 37 months*100=3700 symbols ~14.4s/143MiB. These are benchmarks, not a claim about actual normative years, full PHP8.3 native, or the extreme theoretical 47*123 configuration. Preserve all unchanged 512MiB/900s/full 26/26 job acceptance gates. Next: inspect the automatic push CI on exact new commit; on failure use completed log, not assumption.

## 2026-11-05 — Native timeout confirmed, bounded independent-oracle structure cache (awaiting CI)

GitHub Actions #41871346488 on the exact PHP+Bahasa-Melayu commit 7d55e8c012c1c505ab2a4fc821c60195d6c904f1 completed failure 25/26. Dedicated Native job #126718955139 used PHP 8.3.36/64-bit; three syntax checks and independent STAGE55_MEMO_EXACT cases=4 ranks=53 passed. Failure artifact #13346071626, SHA256 5a24f62cb9a518debe539496879d05d429eeade23b867dab2db1d16df85e241c, records exit-code=124 after 900 seconds, with empty stdout and stderr. Thus the verified failure is a time-limit exhaustion, not an established PHP memory-limit failure or a validated algorithmic mismatch. No Stage55 PASS.

The Stage55 suite explicitly builds structures for years 4999/5000/5001 and then calls NormativeOracle::calendarDate for 9 target dates; the previous oracle regenerated the same exact year structure during each target lookup (12 costly structure builds versus 3 logically distinct inputs). Add only a test-oracle cache to NormativeOracle::buildYearStructure, keyed by calculation day plus the exact numeric year and both gate indexes/days. A cache hit returns the same exact value; PHP's array copy-on-write makes caller mutation isolated. Add 3 repeated-value checks and 1 copy-isolation assertion to existing Stage55 Native tests. No benchmark or speedup claim until completed Native evidence. No change to production DateTuplePatch23, independent rank oracle, fixed 512MiB / 900s limit, 9 targets, 45 components, 6 negatives, 2 budget rejects, 1 recovery, or 26/26 acceptance gate. If still timeout, profile the actual exact unranking path before further tuning.
