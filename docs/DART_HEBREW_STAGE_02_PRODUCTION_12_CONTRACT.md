# Dart+עברית — Stage 2 / PRODUCTION12 — §U month counts and lengths

PROJECT_ID: PC-BRANCH-DART-HEBREW
BRANCH: Dart+עברית only (no main or merge)
PRECONDITION: PRODUCTION11 accepted at commit 2cb25f5afc7bb8c15966a781f7a3190bae83443a; GitHub run 41775886231 completed/success, 15/15; P11 job 126396017704: PRODUCTION11_MEATBALL_PASS checks=326, composition_domains=30, name_probes=9, canonical_anchors=3, format 0 changes, analyze no issues.
NORMATIVE_SOURCE: main README §U. Do not infer §V weave, §W names or the §X five-field calendar date.
ALGORITHM_INDEPENDENCE: Native tests recursively enumerate small length vectors; production uses rolling-window dynamic programming and suffix block unranking. No oracle/other-branch implementation copied into production.

## Contract

Input: exact BigInt calculation day c and one proved MonsterTraversedYear from §R. Let L=closeGate-openGate be in 252..5778. The common structure sauce for all month questions is (c, openGate+1), as already required for §§S–T.

1. minMonths=max(3, ceil(L/123)); maxMonths=min(47, floor(L/4)); reject empty domains.
2. Ask bowl 3 seal 30 with modulus (maxMonths-minMonths+1). Map one-based answer r to m=minMonths+r-1; exact integer arithmetic.
3. Count all *ordered* m-tuples (L1..Lm) with 4<=Li<=123 and sum Li=L. Count with exact BigInt sliding-window DP, O(mL) additions and O(mL) stored states, no exponential enumeration.
4. Ask bowl 3 seal 31 with modulus equal to the full valid-vector count. Unrank its one-based answer against vectors ordered lexicographically by integer length; each prefix block size comes from exact remaining-state counts.
5. The immutable result stores m, bounds, full BigInt domain, both MonsterEqualChoice records, and the ordered vector. It has no weave, canonical month names, or final date, and may not be labelled complete §X.
6. Reject invalid lengths/counts/ranks. Synthetic static functions accept 0..5778 days and 3..47 months (including impossible domains, which have count 0); the canonical planner requires the proven year length 252..5778.

## Independent tests and acceptance

- 30 independent small brute domains: m=3..5 and L=4m..4m+9. The test oracle enumerates vectors recursively; compare exact count and lexicographic first/median/last ranks as well as sum/bounds/arity.
- Four focused boundary assertions: [123,123,123] at L369, the three deficit-one vectors at L368, and L5778/m47 counting C(49,3)=18424; all examples are evaluated as exact BigInt integers. Additional infeasible-domain and invalid-rank refusals.
- Three canonical calculation-day anchors c=Foundation-1, Foundation, Foundation+1: verify §R proven length, seals 30/31 moduli, chosen m and full bounded length vector, and preservation of the common sauce.
- Acceptance only if a new GitHub Actions run on this exact SHA finishes all 16 jobs completed/success, Dart 3.13.2 format 0 changes and dart analyze reports no issues, with PRODUCTION12_MONTH_LENGTHS_PASS checks>=400, brute_domains=30, boundary_cases=4, canonical_anchors=3, and month_weave_ready=false/five_component_calendar_ready=false.
- A local Python arithmetic check is not Dart Native; queued/in_progress is not PASS. Previous stages remain accepted on their previously evidenced SHAs; no main/merge/publication.

NEXT after P12 Native acceptance: §V exact full weave under ordered first and last occurrences, with an independent small-state exhaustive oracle; then §W 47 indexed distinct canonical names; finally §X full five-component date against the independent OracleEngine.
