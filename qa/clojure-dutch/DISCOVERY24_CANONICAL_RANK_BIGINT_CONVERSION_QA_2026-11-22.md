# DISCOVERY24 — canonical-rank decimal conversion failure: targeted QA correction (2026-11-22)

PROJECT_ID: PC-BRANCH-CLOJURE-DUTCH
Authorized branch: `Clojure+Nederlands`
Source before fix: `082a69bf39f12e4bbee4b784d6d55fa4abd9cecf`
Scope: TEST/QA ONLY, isolated canonical DP feasibility. Not a production or Stage 2 change.

## Verified completed CI evidence
- Run 44958845160, source `749d848cb09ece7cb3816918d3105b71c9468d2d`: verify job 137012899525 completed SUCCESS; isolated DP job 137012899776 completed FAILURE.
- Run 44959154375, source `082a69bf39f12e4bbee4b784d6d55fa4abd9cecf`: verify job 137013872914 completed SUCCESS; isolated DP job 137013873067 completed FAILURE.
- In both logs, the Clojure independent canonical year/profile/rank extraction step completed SUCCESS. The Python self-test emitted 9 profiles, 135 words, 1102 rank/position checks PASS. Subsequent diagnostic terminated at `int(data["weaving_rank"])` with `ValueError: Exceeds the limit (4300 digits) ... value has 5288 digits`.
- Artifacts retained: 14729349142 (first run), 14729613736 (second run). Both runs are FAILURE, not a budget refusal or five-field proof. Native full-suite jobs SKIPPED.
- This is an input parsing failure in Python 3.11+, not a discovery that DP is feasible or infeasible.

## Narrow change and measurable local oracle
- Raise only Python's decimal-int parse/format safety setting to 25000 digits for canonical diagnostics, where available. Set before `json.load`; keep `LIMIT=5_000_000`, 128N Clojure search budget, suffix DP and independent normative oracle unchanged.
- Upper bound: any accepted canonical profile has at most 5778 day symbols; its full weaving count is at most `5778!` (<20000 decimal digits). Thus the 25000 limit covers accepted-domain numbers without removing conversion limits globally beyond the isolated QA process.
- Add a 5288-digit decimal parse-and-format regression to `--self-test` with restoration of the process setting. The regression does not imply a real canonical p82 or p520 proof.
- Before fix local Python 3.13.5: `int("7"*5288)` raised ValueError at 4300; after `sys.set_int_max_str_digits(25000)`, `len(str(int("7"*5288))) == 5288`. This validates the mechanism, not the complete new source or CI.
- Gates for the new exact-SHA automatic run: completed verify + isolated DP job, raw logs and uploaded canonical JSON input/result artifacts. Exit 2 with explicit `DP_FEASIBILITY_UNPROVEN` is bounded diagnostic only; exit 0 with DP prefix is feasibility only until independent cost-model audit. Unexpected exception is FAILURE. Neither outcome is five-field differential, Native PASS or Stage 2 ACCEPTED.

No production, API, original tests, budget, main, merge, release or publication changes. Previous p81/p82 accounting remains LIMITED ACCEPTED: p81=4,995,675 and next p82=5,002,652 >5,000,000; p82/p520 numerical witness unproven. Legacy generic E2E 0/7.

NEXT: Audit exact source SHA new run without duplicate dispatch, verify canonical input and independent normative-vs-production rank cross-check, result JSON and bounded state/transition accounting. If an unexpected new runtime failure occurs, diagnose that exact error; no blind rerun.
