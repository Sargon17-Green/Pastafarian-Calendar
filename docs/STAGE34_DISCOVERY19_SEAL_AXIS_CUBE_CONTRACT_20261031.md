# Stage34 / Discovery19 — seal-axis cubic interaction (contract with implementation scope; native pending)

Repository branch: `PowerShell+Tagalog`. This contract is authored only after exact Stage33 evidence-seal run [41230776154](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41230776154) completed/success on `de5e9a49924ac92790832aa67b715d035a36a140`: 7/7 jobs, `STAGE33_SEAL_RECHECK=PASS`, 560/560 Stage33 assertions, 239/239 Stage32, 309+441+85 Stage31, 664 predecessor assertions, verify success and two idempotent finalizer passes with unchanged SHA256.

## Novel and falsifiable question
Stage33 measured a two-input mixed finite difference **within** seal 1 or 2. Stage34 tests whether changing the seal alters that interaction. This is a third-axis contrast; it does not presume the two seals behave independently or that a historical defect exists. Keep production semantics and the independent normative oracle unmodified.

Let `M = 2^127-1`, `f = Get-NormFoundationDay()`, `F(c,t,s)` = First and `S(c,t,s)` = Step of bowl 1 under seal `s in {1,2}`. For target base `d` and `i,j in {0,1}`, query `(f+i,d+j,s)`. Define:

- `D_s = (F(f+1,d+1,s) - F(f+1,d,s) - F(f,d+1,s) + F(f,d,s)) mod M`.
- `Q_s = (S(f,d,s) != S(f,d+1,s)) XOR (S(f+1,d,s) != S(f+1,d+1,s))`.
- **Seal-axis third contrast** `E = (D_2-D_1) mod M`; **seal-axis Step contrast** `R = Q_1 XOR Q_2`.
- For every one of the four corners, independently check the seal edge `(F(c,t,2)-F(c,t,1)) mod M` and `S(c,t,1) != S(c,t,2)`.

Every expected First/Step and derived quantity must be computed from `Invoke-NormSauce` and `Get-NormAnswerStream` **independently for each input and seal**, not from Stage33 outputs, a copied fixture, another language branch, or a rewritten implementation. Compare actual endpoint First/Step to oracle, all seal edges to oracle, both square-face interactions to oracle, and E/R to oracle. Output observed E zero/nonzero, R flip/same, distinct E and per-cube records without asserting an invented distribution.

## Finite input domain, counting and boundaries
Use the eight *same labeled target bases* as Stage33 but make a new three-dimensional query across the seal axis:
`OpenGateDay-1`, `OpenGateDay`, `CloseGateDay-1`, `CloseGateDay`, `f-1`, `f`, `f+1`, `f+36525`. The gate boundaries come from `Get-NormYear5000 -CalculationDay f` and must be sanity-checked. `36525` is a purely ordinal offset, **not** a Gregorian conversion. Exactly **8 cubes**, **32 labeled (calculation,target) context instances (numeric pairs overlap across neighboring target bases)**, **64 per-seal endpoints**, **32 seal edges**, **16 calculation/target faces**. Reuse a context for two seals only if it is immutable for both extractions; assert 58 legacy writes and one Patch12 invocation on each labeled context instance. No extrapolation to other years, seals, bowls or dates.

Neighboring target bases, such as `f-1` and `f`, share an endpoint; consequently 32 labeled contexts are not 32 unique numeric input pairs. The numeric-unique count is separately reported, and the 448-assertion gate still covers all 32 labeled contexts.

## Measurable test gate
The planned `tests/Stage34.Tests.ps1` uses Windows PowerShell 5.1, `Set-StrictMode -Version Latest`, the existing native independent oracle, exact SHA checkout, and retained metadata/transcript with a 20-minute job timeout.

**Exactly 448 assertions** is the deterministic test contract:
- 4 predecessor/stage metadata checks + 4 normative-year sanity checks = 8.
- 32 labeled contexts x 2 invariants (58 legacy writes, one Patch12 call) = 64.
- 64 seal-specific outputs x 4 assertions (First, Step, valid First domain, Step in {-1,+1}) = 256.
- 32 seal-axis edges x 2 independent-oracle comparisons (First delta and Step flip) = 64.
- 16 calculation-target faces x 2 independent-oracle comparisons (mixed First and mixed Step) = 32.
- 8 cubes x 2 independent-oracle comparisons (E and R) = 16.
- 8 aggregate checks (base count, cube count, labeled-context count, endpoint count, seal-edge count, face count, E conservation, R conservation) = 8.

Sum: `8 + 64 + 256 + 64 + 32 + 16 + 8 = 448`, zero failures. Emit `STAGE34_ASSERTIONS_PASSED=448`, `STAGE34_ASSERTIONS_FAILED=0` and observed cube statistics only after real native execution. Test count must be established from actual harness execution, not static code-site counting.

## Integration, status, and limits
In the implementation commit, extend the exact-branch CI wiring and predecessor tests to accept `CURRENT_STAGE=34, LAST_COMPLETED_STAGE=33, STAGE34_RUNTIME_VERIFICATION=PENDING_NATIVE` without weakening historical RED/green, Stage33 seal or Stage23 finalizer checks. Stage34 itself stays research-only. Preserve the seven existing successful jobs, add one bounded Windows PowerShell 5.1 Stage34 job with exact-SHA evidence, and never manually duplicate an automatic CI run. Do not advance `LAST_COMPLETED_STAGE` or claim Stage34 PASS until completed/log evidence; seal Stage34 on a later evidence-only commit and recheck that new SHA separately.

**Original contract commit** was contract-only. Its follow-up implementation opens `CURRENT_STAGE=34`, retains `LAST_COMPLETED_STAGE=33` and sets `STAGE34_RUNTIME_VERIFICATION=PENDING_NATIVE`. A native PASS is not claimed yet. No production/oracle alteration, main merge, publication, statistical uniformity or independence claim, or civil/Gregorian mapping.
