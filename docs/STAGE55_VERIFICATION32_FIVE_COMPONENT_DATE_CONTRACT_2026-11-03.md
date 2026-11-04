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
