# Stage 1 — aallartinneqartoq (ammasoq)

```text
STAGE=1
STATUS=IN_PROGRESS
PREVIOUS_STAGE=0
DEVELOPMENT_TRACK=CALENDAR_55_STAGES
SILICON_TRACK=S00_S20
SOURCE_LANGUAGE=Kalaallisut
SOURCE_LANGUAGE_QA=NOT_STARTED
SOURCE_LANGUAGE_CATALOG_FROZEN=NO
RTL_STAGE1_BOOTSTRAP=WRITTEN_UNVERIFIED
REFERENCE_ORACLE=PARTIAL_PLUS_FOUNDATION_SAUCE_TEST_ONLY
FULL_CALENDAR_ORACLE=NOT_IMPLEMENTED
SIMULATOR_LOCAL_AVAILABLE=NO
GITHUB_ACTIONS_RUN_OBSERVED=0
FOUNDATION_SAUCE_SIMULATION_STATUS=NOT_EXECUTED
STAGE1_PASS=NO
```

## Atorneqartut

- `rtl/pcal_stage1_bootstrap.sv`: request/ready, register, context, bounded dispatcher aamma observation.
- `tests/pcal_stage1_oracle_pkg.sv`: test-only SAVE/dayCount/distance/sum/direction, SystemVerilog-imi allataq.
- `tests/tb_stage1.sv`: initial testbench; actual PASS aatsaat simulator-imi uppernarsarneqarsinnaavoq.
- `tests/tb_sauce_foundation.sv`: test-only 7 hidden / 46 visible / 6 bowls / 12 saved-sum rounds and normative intermediate witnesses; not yet executed.
- `catalog/catalog_review_queue.csv`: 64 canonical slots: 3 sourced lexical research candidates, 61 empty, 0 native approvals.
- `.github/workflows/stage1-systemverilog.yml`: GitHub Actions iverilog + vvp simulation.
- `SOURCE_LANGUAGE_CATALOG.md`: 17 + 47 atit suli amigaataapput.

## Piumasaqaatit suli amigaataasut

- 64 canonical atit Kalaallisut-imi native review, transliteration policy, immutability SHA.
- Full independent SystemVerilog calendar oracle, fixtures and all canonical witnesses.
- CI test run PASS and independent code review.
- Stage 1 completion certificate only after all above evidence exists.

No stage 2 discovery or patch was opened.

## 2026-10-21 — Suliniutip ingerlaqqinnera

- `tests/tb_stage1_reset.sv`: request interrupted by asynchronous reset and another reset during completion; code written, not simulated.
- `scripts/check_catalog_structure.sh`: 17 cutlet + 47 month contiguous index check; data structure separately checked in the connected GitHub record (64 rows, 8 columns each).
- Three sourced proposals (not native-approved): `terianniaq`, `kuuk`, `ulloriaq`.
- Temporary mathematical inspection of the published Foundation sauce checkpoint reproduced all seven hidden drops' boundary witnesses, drops 1 and 46, orderAt46 and six final bowls. It did **not** execute the SystemVerilog source.
- CI: no branch workflow runs observed at this checkpoint. Stage 1 remains open; Stage 2 remains closed.

## 2026-10-21 — research and test-only discrimination

- The exact rejection walk has a closed-form first accepted answer and
  reject count. This holds for the short domain `S=M` and for the wide
  post-construction domain `S=M^k` without altering wide digits.
- A separately executed scratch comparison covered 2,272,548 cases,
  every domain `S=2..150`, all admissible `N,A`, both directions:
  0 mismatches. This is not SystemVerilog execution.
- `tests/tb_selection_rejection_equivalence.sv` checks a separate
  small-domain comparison and large arithmetic boundaries, but has
  not run in a simulator.
- `tests/tb_sauce_foundation.sv` now has 7 published hidden drop
  witnesses, and an intentionally wrong raw bowl-sum mutant with
  6 published superseded bowl values as negative controls.
- A scratch math reproduction confirmed the canonical and mutant
  6-bowl outputs independently, without running the RTL.
- Stage-1 completion remains blocked by SV simulator + CI evidence,
  full-calendar oracle and reviewed Kalaallisut 64-name catalog.
- Engineering documentation and comments still require independent
  Kalaallisut language QA; current English technical research notes
  must not be treated as linguistically certified source documentation.

## 2026-10-22 — Foundation gates and Year 5000 reference

- Mathematical scratch executed for positive gates n=1..10 and
  negative gates n=1..12, exact soup/sauce and bowl query per input.
- 22 gap values independently recorded as derived vectors.
- The first four positive and negative gap sums reproduce the two
  canonical Year 5000 boundaries, length 4244.
- Exactly 43 candidate years satisfy the normative eligibility rules
  for c=Foundation. Sorting by length then opening gate yields
  canonical chosen rank 15.
- `tests/tb_gate_gap_oracle.sv` extended accordingly, using the
  independent SystemVerilog sauce engine and an independent candidate
  enumeration / sorting implementation; **not yet simulated**.
- Added complete candidate and signed gap CSV ledgers. They contain
  research-derived values, not hardware-run evidence.
- Native Kalaallisut review remains 0/64 approved; full calendar
  oracle unfinished, Stage 1 stays IN_PROGRESS.
## 2026-10-22 — preflight compilation blocker remediation

- Found and removed duplicate global `integer positive_sum,negative_sum`
  in `tb_gate_gap_oracle.sv`.
- Inspected eight SystemVerilog source files for module-level integer
  duplicate declarations. None remain under this static check.
- Scoped test-only duplicate declarations in separate `task`
  bodies are permitted.
- Added a standalone AWK preflight with positive/negative local
  fixture evidence: duplicate globals are rejected; task locals do not
  produce false positives.
- Moved static source, catalog and oracle-isolation checks to run
  before simulator availability check.
- `iverilog`, `vvp` and `verilator` are still unavailable locally;
  apt cannot resolve its package server. The two isolated CI jobs
  remain queued, not failed and not passed.

## 2026-10-22 — renewed quality gates

- CI jobs: implementation branch pull-request and isolated QA push
  runs remain queued; no HDL run logs have been returned.
- The current execution environment has no iverilog, vvp or verilator.
  Direct GitHub raw download and apt Debian mirror fail DNS resolution.
- Added `scripts/test_sv_preflight.sh` to run **three** adversarial
  source lint fixtures before checking for a simulator.
  A separate local reproduction actually executed all three and
  confirmed: good module accepted; duplicate module-level integer
  rejected; missing `endtask` rejected. This verifies only the
  shell/AWK preflight behavior, **not** HDL syntax or RTL correctness.
- Added deterministic 4096-cycle `tb_stage1_backpressure.sv`
  with scoreboard for accept/hold/backpressure/reset and explicit
  `date_valid=0` guarantee. Test code written, not simulated.
- Source-language research expanded to six proposed words with
  references in `catalog/KALAALLISUT_LEXICAL_QA_DOSSIER.md`.
  All six remain PENDING native review and **0/64** are approved.
- No Stage 2, no main change, and no release claim.
