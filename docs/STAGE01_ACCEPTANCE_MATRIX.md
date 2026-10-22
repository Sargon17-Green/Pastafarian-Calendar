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
