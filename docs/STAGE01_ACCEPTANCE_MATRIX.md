# Stage 1 — gate checklist

Reference: canonical Scroll in `main@56bc4173aae4975ded019ef5ab5a36249f1424df`.
Implementation: independent `SystemVerilog+Kalaallisut` orphan branch.
All statuses below distinguish **written** from **executed**.

| Substep | Status | Acceptance criterion |
|---|---|---|
| 1.1 Orphan branch | VERIFIED | Root commit has no parent |
| 1.2 Base request/ready RTL | WRITTEN_NOT_SIMULATED | Capture, context lifetime, one transaction per ready handshake |
| 1.3 Basic arithmetic test-only oracle | WRITTEN_NOT_SIMULATED | Signed ±64-bit boundary, SAVE and day-index invariants |
| 1.4 Independent sauce intermediate test | WRITTEN_NOT_SIMULATED | 7 hidden, drops 1 and 46, order at 46, six final bowls |
| 1.5 Reset and in-flight recovery | WRITTEN_NOT_SIMULATED | Reset during busy and done; stale data and counter cleared |
| 1.6 Source language catalog shell | 64_PENDING | Exactly 17 cutlet + 47 month indices with independently checked Kalaallisut strings |
| 1.7 Linguistic evidence and approval | 0_OF_64 | Orthography, semantics, phonology/transliteration, Unicode NFC, a knowledgeable reviewer |
| 1.8 Whole-calendar independent oracle | NOT_STARTED | Year/gates/weaving, exact five fields, all normative witnesses |
| 1.9 CI and native simulation | NO_RUN_RECORDED | Simulator exit status 0 and retained reproducible logs |
| 1.10 Contract completion | BLOCKED | All prior items PASS, no Stage 2 until proven |

This document does not assert native fluency or silicon implementation completion.

## Separate ASIC S00–S20 gates

ASIC implementation design cannot be closed by a Stage 1 simulator result.
No PPA, DFT, timing, area, memory-bound or tapeout claims exist yet.

## Auxiliary arithmetic inspection

A scratch mathematical translation of the normative sauce formulas
reproduced the published Foundation witnesses for 7 hidden drops,
visible drops 1 and 46, orderAt46 and all six final bowls. This is
**not** a SystemVerilog simulation, not the branch's normative oracle
and not evidence of a hardware PASS.

## Additional progress — exact rejection shortcut

The short/wide circular rejection rule has a closed form in [the mathematical proof](SELECTION_REJECTION_CLOSED_FORM_PROOF.md). A new independent SystemVerilog testbench, `tests/tb_selection_rejection_equivalence.sv`, exhaustively compares direct and iterative selection for all small states and tests 127-bit, two-digit, and three-digit arithmetic. The shell runner now compiles and invokes it. **No SystemVerilog simulator execution has been confirmed.** Stage 1 remains open and the later DISCOVERY/PATCH stages are not preempted.

## Additional negative controls

The test-only sauce regression now asserts *all* seven published hidden
drops, both reported visible drop checkpoints, orderAt46, the six
canonical final bowls, and six historically superseded raw-sum-mutant
bowls. The mutant is a test negative control only and is not reachable
from production RTL.

**Statuses:** source written; scratch mathematics checked; native SV
simulation NOT EXECUTED. Green stage-1 signoff is forbidden until
actual simulator results and catalog review are recorded.
## Independent signed gate tests

New `tests/tb_gate_gap_oracle.sv`: 22 test-only gate checks for
`(Foundation,Foundation±n)`, n=1..8, with separately derived
arithmetic expected values. It enforces direction semantics,
exact soup/sauce construction, final bowl querying, and the
short equal-selection rule for 1..922 with a 41-day offset.

The fixture is **unexecuted** under a real SystemVerilog simulator.
The scratch independently computed positive gaps
`[345,818,831,218,854,136,674,649]` and negative
`[503,441,329,759,433,890,558,414]`.
Do not use the gap vectors as proof of full five-field calendar output.

## Normative name witness

`catalog/NORMATIVE_NAME_WITNESS.csv` holds exactly 17+47 Maltese
original labels from the pinned normative sections T and W,
with semantics classifications and strict index joins to the
Kalaallisut catalog. These Maltese labels are **review-only
provenance**, never output locale strings or a fallback source language.
An additional validator guards the fraction, invented-name, and
cross-index invariants.

Review status remains 0/64 approved. The presence of a lexical
candidate does not constitute qualified Kalaallisut validation.

## Canonical Year 5000 reference checkpoint

The gate fixture is now extended to 22 computed signed gap witnesses
(positive n=1..10 and negative n=1..12). It computes the first four
cumulative sums in both directions and verifies the canonical year-5000
open gate -15057703 and close gate -15053459.

It then enumerates all eligible candidate years containing Foundation,
requiring at least six gap intervals, length 252..5778, and interval
(open,close]. The independent mathematical scratch returned **43**
candidates, sorted by length and then opening gate. Bowl 1 with seal 10
selected candidate **15**, length 4244, open -15057703, close -15053459,
matching the normative canonical checkpoint.

The complete reference candidate ordering is stored in
`docs/FOUNDATION_YEAR5000_43_CANDIDATES.csv`; the 22 gate gaps and
cumulative endpoints in `docs/FOUNDATION_22_SIGNED_GATE_GAPS.csv`.

This is a new **test-only** independent SystemVerilog oracle segment,
not a production calculation module. CI iverilog / vvp is still
UNEXECUTED. No full five-field calendar oracle or Kalaallisut source
catalog acceptance is claimed.
## 2026-10-22 — targeted pre-simulation remediation

A manual static audit found a duplicate module-scope declaration of
`positive_sum,negative_sum` in `tests/tb_gate_gap_oracle.sv`.
The duplicate has been removed in commit
`5a38eb4389f875880f70e83de64aa2aa22aed433`.
A module-scope integer declaration inspection of all eight current
SystemVerilog source files found no other module-scope integer
duplicates; repeated task-local variable names are not duplicates.

The new `scripts/check_sv_declarations.sh` was executed on
synthetic positive and intentionally invalid fixtures in the
scratch environment. Correct declaration scopes passed; duplicated
module-scope declarations failed. It has **not** been run through an
HDL parser and does not replace Icarus/Verilator compilation.

`scripts/verify_stage1.sh` now runs source-declaration preflight,
64-name catalog structure and production/oracle isolation **before**
testing whether `iverilog` and `vvp` are installed.

CI evidence: isolated QA push run 39763869338 and non-main PR run
39763937760 were queued on last observation, with no job logs.
The draft PR #20 must never be merged. Stage 1 cannot PASS while
these checks remain unexecuted and the 64-name catalog unapproved.

## Current additional QA, 2026-10-22

| Gate | Actual evidence | Status |
|---|---|---|
| Module-level integer duplicate preflight | 3 positive/adversarial locally executed cases | LOCAL_PREFLIGHT_PASS |
| Stage-1 preflight integrated before Icarus detection | Bash runner source inspected | WRITTEN_NOT_CI_EXECUTED |
| 4096-cycle ready/valid/reset/backpressure scoreboard | Independent `tb_stage1_backpressure.sv` | WRITTEN_NOT_SIMULATED |
| Six Kalaallisut lexical sources and semantic caveats | `catalog/KALAALLISUT_LEXICAL_QA_DOSSIER.md` | 6_RESEARCH_CANDIDATES_0_APPROVED |
| HDL simulator job status | No runner logs yet | QUEUED |
| Full calendar five-field oracle | Not yet present | OPEN |
| 55-stage advancement authorization | Stages 1 and 2 not approved | BLOCKED |

Beware: shell AWK scope lint is not an HDL parser. A future Icarus
pass cannot substitute for independent native-language catalog QA,
and an external mathematical reference is not a silicon signoff.

## Real Icarus 12 regression progress — 2026-10-22

[Run 39767130720](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39767130720)
provided actual PASS evidence for bootstrap, 4103 arithmetic property pairs,
reset/recovery, 4096-cycle backpressure (773 accepted handshakes; 20
resets), Foundation canonical-and-mutant sauce tests, all 22 signed
gate gaps, and the 43-candidate Year-5000 rank-15 checkpoint.
The run **failed** at `WIDE_THREE_DIGITS_ARITHMETIC`, so Stage 1 did
not PASS.

[Diagnostic run 39772016684](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39772016684)
proved that for S=M^3, N=M^2+1 (M=2^127-1), Icarus 12 native
384-bit `/` returned an incorrect quotient. The Euclidean division
must have q=M-1, r=M²-M+1. Independent numeric proof and exact
hexadecimal reproduction are in
[`WIDE3_ICARUS12_DIVISION_REPRO.md`](WIDE3_ICARUS12_DIVISION_REPRO.md).

The new test-only helper
`tests/pcal_exact_division_pkg.sv` implements explicit unsigned
385-bit-remainder long division over 384-bit operands.
`tests/tb_wide_division_golden.sv` asserts 36 independent quotient
and remainder goldens and the reconstruction identity; both the
testbench and integration into the selection equivalence fixture
have been written, but a successful CI verdict is **not yet observed**.

Native Icarus division is preserved as a *diagnostic only* and cannot
affect any expected canonical output or acceptance calculation.
This does not authorize a production division architecture.
64-name native Kalaallisut QA remains at 0/64.

## 2026-10-22 — green actual CI for existing Stage-1 test suite

Run [39773684223](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39773684223)
completed **SUCCESS** (Icarus Verilog 12.0). Logs independently checked:
four static declaration fixtures; 64/64 canonical-index witnesses;
bootstrap; 4,103 arithmetic cases; reset; 4,096-cycle scoreboard with
773 accepted and 20 resets; Foundation sauce and historical raw-sum
mutant; 22 signed gate vectors; 43 eligible candidate years and rank-15
Year-5000 selection; 36 exact unsigned 384-bit long-division goldens;
and 178,878 selection-rejection small-domain comparisons.

The log intentionally prints `ICARUS_NATIVE_WIDE3_DIVISION_UNSAFE`.
That diagnostic identifies a simulator-native wide division defect,
not a failure of the test-only exact divider, and does not constitute
any license to accept incorrect native quotient as normative.

**New oracle scope opened within Stage 1, not a new 55-stage milestone:**
`tb_gate_gap_oracle.sv` now checks the canonical cutlet fields of
`P(Foundation,Foundation)` by implementing sections S and T
(physical gate composition with forced interior boundary, and 17Pk
distinct canonical name-index unranking). Its latest test has not
yet returned an Icarus verdict. Success of the old suite must not
be misreported as passing this new test.

The full 5-field oracle and 64 qualified Kalaallisut approvals
remain open. `STAGE1_PASS=NO`.

## CI gate — Foundation cutlet structure certified

[Run 39816637847](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39816637847)
ended SUCCESS. It executed the cutlet count, interior gate constraint,
15 eligible lexicographically ordered compositions, composition rank 9,
6-name permutation rank 7,851,263, and output canonical index 10/day 503.
No different source language string was assumed.

## New source-only month sublayer

Independent computations established 45 calendar months for the
Foundation year's 4244 days. A 45-part bounded-composition count was
cross-checked via a second inclusion-exclusion algorithm:
a 274-bit value. A 3-digit wide selection and 45-length lexical
unrank fixture was written. The selected lengths appear in
`docs/FOUNDATION_MONTH45_LENGTHS_REFERENCE.csv` but its
nominal running totals **do not** specify physical day order,
because actual months are interwoven (Scroll V).

**Current status:** month-length DP and 45-length unrank source
are WRITTEN_NOT_CI_VERIFIED. Woven month count/rank and month-name
permutation remain UNIMPLEMENTED. Stage 1 is NOT SIGNED.

## Exact weave work (small oracle; large engine still open)

- Eight independent toy test cases enumerate **every** word,
  filter by first/last appearance order, and verify the count
  and complete lexicographic `unrank` against a separate
  DP suffix-count oracle. Expected toy counts:
  `2,5,9,14,4,1,1,20`. Source has been written and wired to CI.
- A constructive rigorous lower bound for the 45-month root weave
  count has 22350 bits; an unrestricted-multiset upper bound has
  22851 bits. Therefore the production full-rank engine needs
  699..715 uint32 limbs (for this vector), with 176..180 base-M
  answer digits. The 384-bit oracle is insufficient.
- **Blocked**: an exact compressed 45-month weave count/unrank
  algorithm with demonstrable feasible resource limits, a full
  woven-word computation, 47P45 month-name choice, and day 56
  / canonical month index 20 checkpoint.
- The toy SV fixture is **WRITTEN_NOT_SIMULATED** as of this
  checkpoint. Stage 1 remains open regardless of prior green
  Icarus runs of other test slices.

## Exact compressed completion counting — research only

Eight small instances and 258 legal-prefix queries were checked
by independent exhaustive reference enumeration against a
first/last order transfer. The complete Foundation root weave
count is a 22470-bit nonnegative integer, requiring 703 uint32
limbs and exactly 177 base-(2^127−1) answer digits for choice.
Full derivation and hash are in
`docs/FOUNDATION_WEAVE_TRANSFER_EXACT.md`.

SV fixture for tiny cases has been extended, but cannot be
marked PASS until a matched GitHub Actions run completes.
The large 45-month unrank and the two month fields
of the canonical 5-tuple remain OPEN.

## 2026-10-22 — exact 45-month lengths and medium weave CI PASS

[CI run 39836691095](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39836691095)
completed SUCCESS, with independently reviewed Icarus 12 logs:
- all five source declaration preflight fixtures;
- Foundation month count `45` for year length `4244`;
- exact 274-bit month-length composition total and full
  **45-element lexical unrank**, including rank conservation;
- 8/8 independent small weave cases and 465 prefix-block
  checks (brute force versus count/unrank);
- all previous Stage-1 basic tests.

[CI run 39837437421](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39837437421)
completed SUCCESS. The new **test-only 2,048-bit exact
first-position-transfer oracle** matched *five independent
golden roots* for actual first 2..6 month lengths of Foundation:
217, 528, 880, 1262 and 1602 bits, respectively.
All earlier tests continued to pass.

This explicitly lifts arithmetic testing beyond the earlier
384-bit helper. It does **not** prove the full 45-month
22,470-bit root and does not derive the canonical weave rank or
the final month index/occurrence.

The static linter failure in run 39823278850 arose from
a multiline `logic` declaration; corrected by parsing the
complete declaration through its semicolon, with a separate
packed/unpacked array fixture. Actual CI pass now exists.

Stage 1 remains OPEN: production RTL cannot yet output
the canonical five-field tuple, and **0/64 Kalaallisut**
names have been natively approved. No Stage 2 authorized.
