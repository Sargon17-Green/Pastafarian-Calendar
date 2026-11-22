# DISCOVERY24 rank-path safe-bounds QA (2026-11-23)

PROJECT_ID: PC-BRANCH-CLOJURE-DUTCH
Scope: authorized TEST/QA only. No production, API, budget, source algorithm, main, merge, publication, user-machine Native, or generic E2E changes. Stage2 remains OPEN.

## Exact source and prior CI

- Feature branch: `Clojure+Nederlands`; baseline HEAD `b2a28afd62ffd02e343e53d2b8ddd187088cedb3`. Baseline source code remains the tested code `ec0051ec6335fe178c03bcf3583b3dbfec1ffa84`, with production blob `src/pastafari/maandrang.clj` = `62f304dc013a9a9f70475bb0d34f186838b27318`.
- Completed run [45065505365](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45065505365) at source SHA `ec0051ec...`: verify job 137340625261 SUCCESS, isolated Python DP job 137340625561 SUCCESS, full Native job 137340626593 SKIPPED. The DP job emitted `DP_FEASIBILITY_UNPROVEN`, no p82/p520 prefix, no five-field differential; 4,973,786 charged units plus a proposed 113,505 exceeded 5,000,000. No new workflow was dispatched.
- Earlier [first-refusal run 44928375240](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44928375240) remains a LIMITED diagnostic: p81 accepted at 4,995,675, p82 proposed 5,002,652. This QA only checks the historical inequality and does not turn it into an independent canonical proof.

## Reproducible new QA

File: `qa/clojure-dutch/discovery24_rank_path_bounds_qa.py` (standalone Python 3, standard library only), first committed at `1fa8161d8dbbda2f9ba4ff23781095f40148f843`. Verified uploaded Git blob `89bcff8945ad77189a0683bda25e652ed1c95807`, equal to the locally executed file's Git blob. Python `py_compile` exit 0; `python3 qa/clojure-dutch/discovery24_rank_path_bounds_qa.py` exit 0.

Static results:

| Check | Result |
| --- | --- |
| Exhaustive independent multiset enumeration | 6 profiles; 59 legal words |
| Exact rank/position prefix comparison | 436/436 correct |
| Rank-path raming bound versus toevoegen conj cells | 436/436 prefixes satisfy charged >= conj cells |
| Budget refusal at charged minus one and acceptance at charged | 436/436 each |
| Admissible suffix lower/upper inclusion | Every examined legal candidate; no violations |
| Interval-only resolved prefixes (independent of exact tiny oracle) | 36, all exact |
| Interval-only unresolved prefixes | 400, returned UNPROVEN instead of a guessed branch |
| Invalid tiny rank checks | Both rejected |
| Canonical p82/p520; five fields; full Native | UNPROVEN; NOT_RUN; NOT_RUN |

Concrete strict gap: profile (2,2), rank 1, first position: `raming` charges 9 while the modeled `toevoegen` loop appends only 2 vector cells. These are only `conj` append operations, **not** all allocations, CPU operations, or a new production-budget definition.

## Safe bound and interval proof

For remaining multiplicities `r=(r_1,...,r_m)` with `R=sum(r)`, the number `S` of admissible completions of any legal reachable successor satisfies:

`1 <= S <= R! / product_i(r_i!)`.

Upper bound: discard both first-occurrence and last-occurrence order constraints, counting all multiset permutations. Lower bound: emit remaining letters in nondecreasing month order; for a legal reachable state, this completes already-open months in order and then introduces remaining months in order, preserving both first and last ordering. A terminal remainder has count exactly one.

For rank uncertainty interval `[a,b]` and suffix-count interval `[L,U]`: the candidate can be safely *rejected* if `a>U`, yielding new rank interval `[a-U,b-L]`; it can be safely *chosen* if `b<=L`. Otherwise return `UNPROVEN_SUFFIX_INTERVAL`. In particular, never subtract the multinomial upper bound as though it were an exact suffix count.

For a legal candidate with `opened=o>0` and `R` remaining letters, the production charge is `raming=1+(m-o+1)(1+R)`. The `tel-rest` implementation invokes `toevoegen` for no more than `m-o` unopened months, and each call appends at most `1+R` cells; terminal remainder invokes zero. Thus modeled `toevoegen` append count is <= `(m-o)(1+R)` < `raming`. This is an accounting upper bound, not proof that every overall memory allocation or CPU operation has this cost.

The code's oracle mode enumerates all tiny legal words independently and then follows every selected/rejected candidate on the requested lexicographic rank path; the interval mode has no access to those exact counts and stops without claiming success as soon as its bounds cannot decide. The tiny oracle does not import the Clojure source, the previous Python DP, or fixtures from other branches.

## Gate decision

- `NEW_SCRIPT_AND_GIT_BLOB=VERIFIED`; `LOCAL_STATIC_QA=PASS`; `SOURCE_FORMULA_AUDIT=PASS`.
- `RANK_PATH_TINY_EXHAUSTIVE=PASS`; `SUFFIX_INTERVAL_SAFETY_TINY=PASS`; `RAMING_GE_TOEVOEGEN_CONJ=PASS` for examined cases and justified by the formula above.
- `CANONICAL_RANK_PATH_P82_P520=UNPROVEN`; `CANONICAL_BUDGET_PROOF=UNPROVEN`; `FIVE_FIELD_DIFFERENTIAL=NOT_RUN`; `NEW_NATIVE=NOT_RUN`; `STAGE2=OPEN`.

## NEXT — still QA only

Tighten admissible suffix-count intervals with an independently derived combinatorial counting algorithm that can distinguish canonical rejected/chosen candidate blocks without full memo-graph charging. Verify every interval operation against the tiny exhaustive oracle and preserve rank-interval uncertainty after skipped candidates. Only attempt canonical p82/p520 and a distinct five-field differential if exact input identity, cost accounting and the unchanged 128N / 5,000,000N gates are independently met. Never infer a production failure or success from full-DP charges or from this toy enumeration. Do not repeat the accepted same-SHA CI; no Native user run, main, merge, or publication.
