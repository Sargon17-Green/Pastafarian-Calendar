# Dart+עברית — Stage 2 / PRODUCTION11 — §§S–T meatballs and names

PROJECT_ID: PC-BRANCH-DART-HEBREW
BRANCH: Dart+עברית only
PRECONDITION: PRODUCTION10_YEAR_WALK_PASS; GitHub run 41617827706 at 98d4ad9c421dcc5190c75cbb0cdb194d0ccaff2e completed/success 14/14; P10 job 125855596791: checks=115, anchors=3, forward=3, backward=3, oracle=6, format/analyze clean.
NORMATIVE_SOURCE: main README §§S–T, 17 canonical indices preserved from source_language_catalog.dart. The human source is normative; no string sorting or borrowed algorithm.
STATE: One additional structural component only; not a five-field calendar date.

## Contract

Input: exact BigInt calculation day c and one fully proved MonsterTraversedYear from §R. Let the year span G §O gate intervals and be (openGate,closeGate]. The common sauce for all three questions is (c, openGate+1), NOT (c,c), NOT (c,target). Build exact §O gates and fail closed if the final gate differs from the proved year close.

1. Choose K from 6..min(17,G) by bowl 2, seal 20, §N one-based rank. There are maxK-5 choices.
2. Choose positive integer composition x1..xK of G, in lexicographic order by integer tuple, via bowl 2, seal 21. The domain has binomial(G-1,K-1) choices. If c lies exactly at an internal year gate after q intervals, require q among the proper prefix sums and reduce the domain to binomial(G-2,K-2). No gate constraint if c is not an internal gate. The open gate and final close gate are not internal.
3. Choose K distinct canonical name indices from 1..17 in lexicographic index order, via bowl 5, seal 22. The domain is 17!/(17-K)!. Display the Hebrew text from the locked source language catalog after selection; Hebrew spelling never participates in selection.
4. Build consecutive meatball bounds from the exact gate prefix list. Each interval is (opening gate, closing gate]; the union equals the year and there are no overlaps.
5. All ranks, domain sizes and calculations must remain exact (BigInt); unrank without exponential materialization. Invalid input/rank refuses; no year/month/date claim.

## Independent oracle and acceptance

The Native test enumerates all small positive compositions for G=6..11, K=6..min(8,G) both with and without required internal cut, comparing exact count and lexicographic ranks; 30 independent domains. A separate tiny-domain recursive name permutation enumeration tests K=1..3 and 9 rank probes, no production unranking. Three canonical calculation-day anchors (Foundation ±1 and Foundation) test §R/§S continuity, sauce, ranges, index-selected names and partition invariants. Additional large BigInt domain and invalid-rank checks.

Gate: all preceding CI jobs completed/success at the same branch SHA, Dart 3.13.2 format 0 changed and analyze 0 issues; PRODUCTION11_MEATBALL_PASS with checks >=175, composition_domains=30, name_probes=9, canonical_anchors=3. Changes only in Dart+עברית, no main, merge or publication. A queued run is not PASS.

NEXT after evidence-backed PASS: §§U–W month counts, bounded lengths, full weave and names; then §X full five-component date against independent OracleEngine.calendar_date_normative. Do not mark Stage2 complete before all gates.
