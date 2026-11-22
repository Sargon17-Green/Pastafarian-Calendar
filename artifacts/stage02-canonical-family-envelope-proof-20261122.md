# Stage02 canonical calendar family envelope — 2026-11-22

Project: PC-BRANCH-WAT-SPANISH
Authorized branch: WAT+Español
Parent HEAD checked: 10f0a30f1ee86faea5362ebd063b7afae48a7002
Source: Pastafarian_Canon_Discrete_Formulation_2026-10-19.md, specifically rule.years, rule.structure, rule.family.compositions, rule.family.weaving, rule.selection.rank.
Status of source corpus: adopted decisions binding; complete v1 corpus freeze not attested.

## Semantic distinction

The 47^5778 value is a **provable upper bound** for family cardinalities N used in calendar-invoked Choose, not a proved attainable maximal count N_max, and not a restriction on generic Choose(N) as an independent mathematical primitive.

Canonical source constants: year length at most 5778; gap between neighboring gates at least 42; at most 17 cutlets, 47 months. The calendar's individual Choose calls are to select among origin/next/previous year candidates, cutlet count/partitions/names, month count/lengths/weaving/names. No product of these separate choices is passed to one Choose.

## Independent family bounds

1. OriginCandidates(c): start and end gate each lie in a respective <=5778-day half-window of c. Each has no more than floor(5778/42)+1 = 138 possible gates. Candidate pairs <= 138^2 = 19044.
2. NextYear and PreviousYear candidates with fixed endpoint: <= floor(5778/42) = 137.
3. Cutlet counts: 6..17 inclusive -> <= 12.
4. Cutlet partitions: positive compositions of n<=137, with any additional prefix restriction, form a subset of all 2^(n-1) compositions. Bound 2^136.
5. Cutlet distinct names: at most 17! (order-sensitive arrangements from 17 identities).
6. Month counts: at most 47.
7. Month lengths: positive compositions of Y<=5778, a subset of 2^(Y-1). Bound 2^5777.
8. Month weaving: every valid weave is one of m^Y sequences of Y positional month identities; m<=47 and Y<=5778. Bound 47^5778.
9. Month distinct names: at most 47! (ordered arrangements).

All nine upper bounds are <= 47^5778. This shows only a conservative domain bound for canonical calendar calls. The exact largest attainable weaving count was NOT calculated.

Let M=2^127-1. Exact integer checks give M^252 < 47^5778 <= M^253. Therefore k=min{a>=1 : M^a>=N} <=253 for every canonical calendar-invoked Choose. The upper bound has 32095 bits, M^253 has 32131 bits, M*(47^5778) has 32222 bits. Conservative max requires ceil(32222/30)=1075 base-2^30 limbs, below 1100 declared by the WAT module. The proof does NOT assert all runtime intermediate arrays are safe or that every implementation path terminates.

## Reproducible QA

New file: tests/stage02_canonical_family_envelope.py
Git blob: 0fa5d09fc53ebe4ca7de6460f484d22728e82273
SHA256 (source bytes): c8fba3203172acb35c5b4b40eb79c96ffb255398764c64322cc2f6d7ca673d19
Runtime used for static/numeric QA: Python 3.13.5 (GCC 14.2.0).
Commands:
python tests/stage02_canonical_family_envelope.py --self-test
python tests/stage02_canonical_family_envelope.py

Observed: five local unittest cases PASS (exit code 0). Standalone JSON report generated successfully. Upper bound unsigned-big-endian SHA256 d478a375f19722eb786c816870829def4035bb4131109d1a17af778c700adc88; 9 covered family categories. This is an independently implemented mathematical check; no WAT was executed and no new CI/native/differential run was claimed or dispatched.

Existing accepted, separate tests: k253 focused QA run 44954094856 completed/success, artifact 14726874775; k259 stress run 44960026911 completed/success, artifact 14728728384. These remain limited to their earlier verified scope; no rerun. Locked WAT blob e23f013ab96b498b0ac365dbb1b25273c845e790 remains unchanged.

## Gates and next

- New canonical envelope/static numeric check: PASS only in its limited scope.
- Calendar Choose domain capacity bounded for the documented canonical caller families: proof recorded.
- Generic Choose arbitrary positive N: no 47^5778 cap claimed.
- New GitHub CI/Native/differential: NOT RUN.
- Overall Stage02: NOT ACCEPTED.
- Original historical Stage02 ZIP plus manifest: unavailable, not recreated, source equivalence not claimed.
- NEXT: evaluate a source-locked, narrowly scoped Native semantic case fed by an actual canonical family cardinality rather than just stress input; keep independent counting oracle, explicit time/exit/hash evidence; do not rerun accepted k253/k259 unchanged. Continue provenance work independently. No main, merge, or release.
