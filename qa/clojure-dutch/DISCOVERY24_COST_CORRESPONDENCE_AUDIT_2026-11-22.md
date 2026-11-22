# DISCOVERY24 — independent bounded accounting correspondence audit (2026-11-22)

PROJECT_ID: PC-BRANCH-CLOJURE-DUTCH  
Scope: TEST/QA ONLY, no production/API/budget/branch-policy change. Stage2 OPEN.  
Exact source under audit: `ec0051ec6335fe178c03bcf3583b3dbfec1ffa84` (the tested CI source).  
Earlier evidence commit: `d5d95040a84a94aeb0c932cc1b035a21e929112f`.  
Independent reproducible test: `qa/clojure-dutch/discovery24_cost_correspondence_qa.py`, introduced by `4512551af5d0fb012e7466cd2170060275f78407`.

## Verified source and existing execution evidence

- Production: `src/pastafari/maandrang.clj`, `raming(rest,opened) = 1 + (m-opened+1)*(1+sum(rest))`, tested blob `62f304dc013a9a9f70475bb0d34f186838b27318`. In `weving-op-rang-groot` the cost is charged for each *tested legal candidate* while processing a single selected lexicographic rank; it includes candidates rejected because their suffix block precedes the requested rank.
- Production `tel-rest` immediately returns `1N` when the remainder is all zero, without calling `toevoegen`. Yet `raming([0,0], opened=2) = 2`. Thus charged cost is **not identical to mandatory allocated insertion cells**, even on a terminal transition.
- Diagnostic: `qa/clojure-dutch/discovery24_feasibility_oracle.py`, `_unrank`. It starts at the remainder after fixed first letter `1`, charges `+1` for each unique memo state and `raming(child)` for *every legal outgoing transition visited in the DP graph*, including branches never evaluated on the one production rank path. It does not charge the initial forced first-letter production candidate. Thus its aggregate charge has no per-operation one-to-one correspondence with production's rank-path charges.
- Existing completed exact-SHA run [45065505365](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45065505365): verify and isolated DP jobs SUCCESS, full Native SKIPPED, artifact 14770898411 sha256 `eb7c55739ab2ff9c237138c4f2a8a28ebfd006cfe00d373ca1621c8b8e460cd5`. Its diagnostic `4973786 + 113505 = 5087291 > 5000000` remains `DP_FEASIBILITY_UNPROVEN`, not a p82/p520 numeric witness.

## Independent exhaustive small-family QA

Command: `python3 qa/clojure-dutch/discovery24_cost_correspondence_qa.py` (Python 3 stdlib; no packages). Tested locally on the file before its GitHub commit, exit code **0**, output ends with `STATIC_QA_PASS`. It neither imports project code nor copies fixtures from any other branch. It recursively enumerates all multiset words and retains only words with both first and last occurrences of months in ascending month order. It independently counts the legal suffixes under each candidate and reconstructs the chosen prefix for *every rank*. Each candidate incurs the exact written `raming` formula. Separately, it enumerates memo states and all their legal outgoing transitions, with the diagnostic's state/transition charging rule.

| Tiny profile | Legal words | Memo states | DP graph transitions | DP aggregate charge | Production rank-path charge, min..max |
|---|---:|---:|---:|---:|---:|
| (2,2) | 2 | 5 | 5 | 24 | 21..25 |
| (2,3) | 3 | 7 | 8 | 41 | 29..38 |
| (3,2) | 3 | 7 | 8 | 44 | 32..36 |
| (2,2,2) | 5 | 9 | 11 | 82 | 56..71 |
| (3,3,2) | 26 | 18 | 29 | 258 | 98..126 |
| (4,4) | 20 | 17 | 25 | 169 | 67..85 |

Concrete counterexample: profile (2,2), first lexicographic word `(1,1,2,2)`; charged production candidates by position are `9+7+3+2=21` whereas full memo-graph diagnostic charge is `24`. This falsifies exact rank-path correspondence without assuming that any cost bound is tight. Profile (4,4) also meets the lower input-length constraint of `prefix-op-rang-begrensd`.

The QA numbers are independent, finite-family **static modeling results**, not Clojure Native execution or a cross-language differential. The dynamic DP stack may revisit pending states; the table uses the mathematical unique-state/edge aggregate and does not assert byte-for-byte diagnostic implementation charging for every profile.

## Gate decision

- `SOURCE_AUDIT=PASS`: exact formula and call sites inspected.
- `INDEPENDENT_SMALL_FAMILY_COUNTEREXAMPLE=PASS`: six finite families plus concrete terminal zero-insertion counterexample.
- `PER_OPERATION_EQUIVALENCE=FALSIFIED`, not a conditional PASS.
- `CANONICAL_P82_P520_BUDGET_PROOF=UNPROVEN`; `FIVE_FIELD_DIFFERENTIAL=NOT_RUN`; `FULL_NATIVE=SKIPPED`; `STAGE2=OPEN`.
- Historical independent p81 `4,995,675` and proposed p82 `5,002,652` remain LIMITED accounting for another path; neither is silently equated with the current DP aggregate, and the p82 proposed number is **not** promoted to a witnessed full date.

## NEXT — bounded TEST/QA only

Use a *rank-path-specific* accounting bound that follows production's chosen/rejected candidate sequence rather than the whole DP memo graph, with independently established admissible suffix-count bounds and a separate bound on actual `toevoegen` work. First test on finite families including (4,4), with explicit failing cases and equality/inclusion assertions. Do not infer canonical p82/p520 PASS from DP graph cost alone. If an independent safe cost bound within fixed 5,000,000 and 128N is not established, maintain `UNPROVEN`; do not rerun exact-SHA CI or run generic 0/7 E2E. No main/merge/publication, policy change, or user-machine execution.

This is an independent static QA/counterexample deliverable only, not a Stage2 acceptance.
