# Stage02 — source-aware calendar Choose call-chain audit (2026-11-23)

PROJECT_ID: `PC-BRANCH-WAT-SPANISH`  
Authorized branch: `WAT+Español`  
Audit baseline: `1d60ff82a0e96c61f5697ffc4c3425509af76ff6`  
Calendar module: `oracle/normative_calendar_wide.wat`, Git blob `70267bb5730678f81d6138a2224d6b8d9a193eb8`  
Isolated selector: `tests/normative_selector.wat`, Git blob `e23f013ab96b498b0ac365dbb1b25273c845e790`  
New checker: `tests/stage02_calendar_choose_callchain_audit.cjs` (committed at `ec2d6a753b10ad1ab9186e030cf17a04bdd1eedf`).  
Historical Stage02 ZIP + manifest: **UNVERIFIED**; not reconstructed.

## What was observed

A source-aware structural checker was evaluated against the two exact GitHub file contents/blobs above and returned `STATIC_SOURCE_AWARE PASS`. The check validates the actual caller functions, `N` producers, bowl/seal selectors, and the dispatch destinations. It does **not** execute WebAssembly. The committed checker locks both Git blobs and emits a JSON report or exits nonzero when its structure/lock assumptions are violated.

The calendar entry `wide_calendar_date(cDay,tDay)` calls `find_target_year_wide` and `resolve_year_structure_wide`. The former selects the year through `year5000_wide`, `next_year_wide`, and/or `previous_year_wide`; the latter calls `build_year_structure_wide`. There are three distinct year-selection call sites and seven structure-selection call sites, covering **nine conceptual family categories** because next/previous year are one category of the prior cardinality-envelope proof.

| Family / runtime caller | Bowl / seal | Actual producer of N | Actual selector |
| --- | --- | --- | --- |
| Origin year pairs: `year5000_wide` | 1 / 10 | `total`: candidate gate pairs containing calculation day, grouped by year length | `choose_small_n(first,dir,total)` |
| Next year: `next_year_wide` | 1 / 11 | `countc`: admissible closing gates for the fixed opening gate | `choose_small_n(first,dir,countc)` |
| Previous year: `previous_year_wide` | 1 / 12 | `countc`: admissible opening gates for the fixed closing gate | `choose_small_n(first,dir,countc)` |
| Cutlet count: `build_year_structure_wide` | 2 / 20 | `candidateCount=min(17,G)-5` | `s_select_family → s_choose` |
| Cutlet partitions | 2 / 21 | `s_fi_cutlet_suffix_count(G,K,0,0,required)` | `s_select_family → s_choose` |
| Cutlet distinct names | 5 / 22 | `s_fi_falling_factorial(17,K)` | `s_select_family → s_choose` |
| Month count | 3 / 30 | `candidateCount=maxMonths-minMonths+1` | `s_select_family → s_choose` |
| Month lengths | 3 / 31 | `s_count_bounded(L,m,4,123)` | `s_select_family → s_choose` |
| Month weaving | 4 / 32 | `s_wp_build(s_N)`: exact packed count | `s_select_family → s_choose` |
| Month distinct names | 5 / 33 | `s_fi_falling_factorial(47,m)` | `s_select_family → s_choose` |

`s_select_family` obtains `(first,direction)` from `ask(bowl,seal)`, copies the response into the big-integer representation, and calls the calendar-local `s_choose`. That dispatcher invokes `s_choose_short` for `N<=2^127-1` and `s_choose_wide` otherwise. The year selectors instead use the separate small-integer implementation `choose_small_n`.

**Extra helper not counted in the nine-family envelope:** `gate_gap_wide` uses `ask(1,1)` and `choose_922` with `N=922` to construct gate gaps. This is a real additional calendar selection mechanism and must be included in future end-to-end coverage, although its bounded cardinality is not a tenth large family in the envelope calculation.

**Critical isolation finding:** `tests/normative_selector.wat` defines an isolated `choose` and does not participate in the calendar call graph. The calendar module embeds its own `s_choose`, and the year path additionally uses `choose_small_n`. Therefore focused Names47 tests of the isolated selector **do not prove** calendar end-to-end behavior or implementation equivalence. The source blobs above are different; source equivalence has not been shown.

## Independent oracle and bounded QA contract for the remaining gate

Input: `(calculationDay,targetDay)` as signed wide-day values, and the canonical gate/sauce rules fixed to a source revision. Output: exact five calendar fields plus an observed internal decision trace consisting of `family,bowl,seal,N,first,step,rank,selectedCandidate`. An instrumented **copy** of the exact original calendar WAT may expose this trace; do not modify the normative file. Every trace must demonstrate `1<=rank<=N` and map `rank` to the independently enumerated candidate at index `rank-1` (or independent unranking in the large families).

Oracle must be independently implemented from the canonical rules, not from the WAT output or other language branches:
- For origin and neighbor-year families, enumerate admissible gate intervals and order them as specified; compare exact `N`, rank and resulting year.
- For cutlet counts/partitions, enumerate small compositions of gate gaps with the mandatory internal boundary; cross-check a separate combinatorial recurrence for larger cases.
- For cutlet/month distinct names, count the falling factorial `P(master,k)=master!/(master-k)!`; independently unrank lexicographically on small exhaustive cases.
- For month lengths, compute positive bounded compositions `[x_1,...,x_m]`, each `4<=x_i<=123`, summing to `L`, via separate DP; compare rank and composition.
- For weaving, enumerate all valid positional sequences for tiny month profiles and independently count/unrank larger profiles. Do not assume `47^5778` is an attained `N_max`.
- For selector rejection, independently compute `M=2^127-1`, minimal `k` with `M^k>=N`, `limit=floor(M^k/N)N`, and the accepted `rank=((x-1) mod N)+1`. Include exact-limit, limit+1, wraparound and both directions where attainable. The canonical month-name case `N=47!` has `k=2`; this is a mathematical oracle fact, not a new Native PASS.

Coverage required for acceptance: at least one observed runtime trace for every mapped family (both next and previous year paths), `N=1` and largest attainable `N` in each feasible small domain, the short/wide transition where a real family permits it, both steps where generated by the sauce, and at least one full five-field `wide_calendar_date` comparison with an independently constructed expected tuple. Gate-gap `choose_922` is tracked separately. Native runs require exact Git SHA, tool versions, code/exit/log/artifact identities and nonzero failure handling; a timeout is not an expected-red.

## Gate classification and NEXT

- **Code:** added an original source-locked static checker; normative WAT unchanged.
- **Static source-aware:** PASS against the baseline blobs for the structural caller mapping. A committed executable checker awaits CI/Node execution on the checked-in commit.
- **Native / differential of integrated calendar:** NOT RUN in this audit.
- **Names47 focused gate:** previously accepted at run `45066080002` (QA SHA `2fd26115...`), 2/2 CI Native and separate 28/28 local differential; not rerun.
- **Historical Stage02 ZIP/manifest:** UNVERIFIED.
- **Overall Stage02:** **NOT ACCEPTED**.

NEXT: run the source-locked checker in CI and inspect its job/log/artifact; then implement an instrumented-copy calendar trace test with independent bounded oracle and actual full-path Native cases. No `main`, merge, release, or reconstruction of the missing historical ZIP.
