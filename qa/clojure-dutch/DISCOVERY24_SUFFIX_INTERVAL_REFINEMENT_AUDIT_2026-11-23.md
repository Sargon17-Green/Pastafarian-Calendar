# DISCOVERY24 — independent suffix-interval refinement QA (2026-11-23)

PROJECT_ID: PC-BRANCH-CLOJURE-DUTCH

Scope: **TEST/QA only**, existing feature branch `Clojure+Nederlands`. No production, API, search-budget, cell-budget, native-user-execution, main, merge, or publication changes. This is **not** Stage2 acceptance.

## Exact source identity and prior evidence

- Pre-change branch HEAD: `70ce9e2e909b5d11626ce2fd838813a6a119b58a`.
- New standalone QA script commit: `1b2f131b8c52c5190e9f7c3b60a6dadff9834c30`.
- Source file: `qa/clojure-dutch/discovery24_suffix_interval_refinement_qa.py`.
- Verified uploaded Git blob: `c29d87b9e9c8f8189c76e951be0fa59383f4474f`, identical to locally executed script; local SHA-256 `b85da9de8ec38991d8d00e640e75b87bd2c3dae215690b86ef4d4268b8fcb642`.
- Production `src/pastafari/maandrang.clj` blob at branch HEAD is unchanged: `62f304dc013a9a9f70475bb0d34f186838b27318`, as at the tested source commit `ec0051ec6335fe178c03bcf3583b3dbfec1ffa84`.
- Historical workflow [45065505365](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45065505365) is `completed/success` for exactly `ec0051ec...`, attempt 1. Verify job `137340625261` succeeded; isolated Python DP job `137340625561` succeeded but its raw log reports `DP_FEASIBILITY_UNPROVEN` at canonical 33-month profile, `4,973,786 + 113,505 > 5,000,000` under a *memo-graph diagnostic model*. Full Native job `137340626593` was `skipped`. Artifact `14770898411` exists. No new workflow was started.

## New bounded counting algorithm (independent of insertion-count production)

The QA independently enumerates legal tiny words by filtering complete multiset permutations on increasing first and increasing last occurrence positions. A separate grammar walk records the remaining multiplicities and last opened/closed symbols. A capped memoized recurrence partitions completions by their *first suffix symbol*. For an expanded state, the sum of child lower/upper counts is a valid bound; the upper bound is further intersected with the unrestricted multinomial. Unexpanded reachable states use `[1, R! / prod(r_i!)]`. A zero remainder uses `[1,1]`.

The update is sound because (a) every reachable legal state has at least one completion by writing remaining symbols in ascending order, (b) all legal completions are among unrestricted multiset permutations, and (c) children with distinct next symbols represent disjoint languages. The cap counts QA state expansions and **is not** a claim about production allocation or its budget. If count interval `[L,U]` is insufficient to decide rank interval `[a,b]`, the script returns `UNPROVEN_SUFFIX_INTERVAL`, not a guessed candidate. When safely skipping a block, it maintains `[a-U,b-L]`; when `b<=L` it safely chooses the candidate.

## Reproduction and independent small-domain results

Commands executed locally (Python 3, standard library):
```sh
python -m py_compile qa/clojure-dutch/discovery24_suffix_interval_refinement_qa.py
python qa/clojure-dutch/discovery24_suffix_interval_refinement_qa.py
```
Both exit 0. Six profiles `(2,2),(2,3),(3,2),(2,2,2),(3,3,2),(4,4)`; 59 independent legal complete words; 436 exhaustive rank/position checks.

| QA expansion cap per suffix block | Certified correct rank/position pairs | Explicitly unproven |
| ---: | ---: | ---: |
| 0 (old broad interval) | 36 | 400 |
| 1 | 61 | 375 |
| 4 | 91 | 345 |
| 16 | 420 | 16 |
| 128 | 436 | 0 |
| 4096 | 436 | 0 |

On every tiny candidate that was encountered, the independently brute-computed exact suffix block size falls inside the refined bounds. Each certified prefix equals its complete-word oracle prefix, each charged prefix agrees with exact tiny-oracle candidate accounting, and rank uncertainty remains inclusive of the exact rank after each skipped block. Budget equalities: 436/436 accepted at the computed production `raming` sum; 436/436 explicitly refused one unit below. Invalid ranks and budgets are rejected.

Separately modeled `toevoegen` vector appends never exceed summed `raming` charges. Strict gap example: profile `(2,2)`, rank 1, position 1: `raming=9`, `conj` appends `=2`. These appends do **not** measure total allocation. The diagnostic memo graph's aggregate work is **not** interchangeable with the production rank-path charge.

## Exact gate classification and next action

- New source artifact, local Python syntax/exhaustive QA, and Git blob correspondence: **verified PASS** on the recorded SHA.
- New GitHub CI/Native: **NOT_RUN**; historical CI `completed/success` concerns an earlier exact production SHA and must not be misapplied to this QA commit.
- Canonical production rank path at p82/p520 under unchanged `search=128N` and `budget=5,000,000N`: **UNPROVEN**, not FAIL or PASS.
- New exact-SHA independent five-field differential: **NOT_RUN**; Stage 2: **OPEN**.

NEXT (QA only): independently audit the canonical *normative* profile/rank identity against fixed-source hashes, then develop an iterative or closed-form *bounded* suffix counter suitable for 33-month canonical inputs without uncontrolled state explosion or recursive stack overflow. Trace exact rank-window and production `raming` charges for p82/p520, stop on first unproven decision/budget exceedance, and retain refusal if the unchanged limits are not proven. Only if that gate succeeds consider a distinct exact-SHA five-field differential. No rerun of the accepted same-SHA CI and no user Native requirement at this point.
