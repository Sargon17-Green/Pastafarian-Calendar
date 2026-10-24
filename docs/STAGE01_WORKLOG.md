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

## 2026-10-22 — first actual Icarus simulation evidence

The isolated push run 39763869338 and isolated PR run 39763937760
both **completed FAILURE**. This is not a blocked runner anymore.
Their logs were read and the failure was localized.

- **PASS on both actual Icarus 12.0 runs:** bootstrap request/response
  primitive and reset/recovery testbenches.
- **PASS on PR run:** 4103 deterministic arithmetic property cases.
- **FAIL in both:** Icarus compilation of
  `tests/tb_sauce_foundation.sv`: SV syntax error on line 16
  (`logic ... dist`) and dependent expressions. The token `dist`
  is a reserved SystemVerilog keyword. This is a compilation failure,
  not an arithmetic assertion failure.
- Fixed all eleven `dist` declarations/references in
  `tests/tb_sauce_foundation.sv` and
  `tests/tb_gate_gap_oracle.sv` in commit
  `a450565858acc58d91588ac0800cfe03815fd811`.
- Strengthened `scripts/check_sv_declarations.sh` to reject the
  reserved keyword and duplicate module-level `logic` declarations
  in addition to `integer`; source fixes in
  `2bc45cb3b8db0fdbd2d5c4889638b6d5e36aa33e`.
- A fourth synthetic adversarial source case demonstrates the reserved
  identifier rejection in the local preflight. Actual Icarus rerun
  **has not returned** a conclusion on the current HEAD.
- A separate 4096-cycle backpressure scoreboard is written, pending
  execution. The QA still is NOT Stage-1 PASS.

## 2026-10-22 — high-width division root-cause analysis

1. Read current real CI logs, including run 39767130720:
   all seven fixture groups preceding wide selection succeeded.
2. Isolated the wide3 failure with run 39772016684. Icarus 12 native
   quotient is incorrect for M³/(M²+1); documented expected q and r.
3. Implemented `pcal_exact_division_pkg.sv` (test-only binary long
   division, unsigned width 384, internal remainder width 385).
4. Added 36 externally calculated golden vectors including full-width
   384-bit and canonical three-digit edge cases.
5. Integrated exact divider into selection equivalence suite, keeping
   native divide mismatch as an explicit diagnostic only.
6. Expanded CI runner to execute 36 golden vectors before selection
   equivalence. No PASS is claimed until current-head run completes.
7. Stage 1 still lacks the complete five-field calendar oracle and
   64 native Kalaallisut approvals; no further contract stage opened.

## 2026-10-22 — source-language semantic review queue

- Proposals now include `bronze` (cutlet index 1) and `qajuusat`
  (month index 39), with dictionary references.
- Research total: 8/64 candidate words; still 0/64 native-approved.
  The candidate set is not a source-language catalog and MUST NOT
  be frozen, shown as complete, or used in canonical rankings.
- Wide3 test-only long divider awaits current-head Icarus simulation;
  this log does not claim new PASS.

## 2026-10-22 — actual CI success and next independent oracle layer

- The CI run on implementation HEAD `3d3b6ce...` completed SUCCESS:
  https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39773684223.
- Read job log from GitHub; baseline operations and all existing
  test-only vectors passed on actual Icarus Verilog 12.
- Verified 36/36 exact wide division goldens and
  178878/178878 bounded rejection equivalence cases.
- CI native division discrepancy remains as nonfatal diagnostic;
  exact independent test-only divider is canonical in the fixture.
- Began the next isolated calendar-oracle slice within Stage 1:
  cutlet count, eligible gap partition, lexicographic composition
  selection, and 17Pk distinct name-index assignment for
  P(Foundation,Foundation), with normative expected (10,503).
- That new cutlet fixture is WRITTEN_NOT_SIMULATED as of this note,
  and cannot yet count as a PASS.
- Remaining gates: full 5-component independent oracle,
  qualified review/freeze of all 64 Kalaallisut names, Stage-1 audit.

## 2026-10-22 — accepted cutlet and month-length oracle extension

**Native CI PASS**: run 39816637847, Icarus 12.0, after the
cutlet-reference fixture. Its log attested the following exact
intermediates at c=t=Foundation:
K=6, 15 allowed gap compositions, chosen composition #9,
six distinct cutlet indices [15,17,10,14,8,13], selected
third cutlet = canonical index 10, day 503. All pre-existing
Stage-1 testbench groups continued to pass.

**New month sublayer, not yet CI-certified**: c=Foundation,
firstDayOfYear=-15057702, year length 4244. The independent
reconstruction selected 45 months out of allowable 35..47,
using bowl 3 seal 30 (rank #11 of 13).

The count of all valid lex-ordered length sequences for m=45,
each 4..123 and total 4244, is a 274-bit integer:
28267369127220710176329716843724118975520840014877906533654334421021017631241800900.
Two independent methods (sliding-window DP and inclusion-exclusion)
produced exactly that value. Because the count exceeds M² (where
M=2^127-1), selection with bowl 3 seal 31 uses **three consecutive
base-M digits**, not one or two. The independent unranked vector has
45 entries and sum 4244 in
`docs/FOUNDATION_MONTH45_LENGTHS_REFERENCE.csv`.

Added `tests/tb_foundation_month_length_count.sv` as an independent
count regression and extended `tests/tb_gate_gap_oracle.sv` to use
a 384-bit exact test-only division and DP suffix-block unranking.
Source is committed; the latest full fixture has **not yet earned CI
PASS**. The month weave and the 47P45 month-name selection are not
implemented and cannot be inferred from nominal length prefixes.
The canonical target remains month-name index 20, occurrence day 56.

## 2026-10-22 — exact weave semantics and unavoidable width

- Added `tests/tb_weave_small_exhaustive.sv`, checking eight
  tiny cases with both brute-force word enumeration and state-vector
  dynamic programming, including exhaustive lexical unrank ranks.
  Source written; first CI result not yet confirmed.
- Replayed the 45-month length-rank unranking independently in
  a separate Python arithmetic implementation. All 45 lengths,
  total 4244, and final rank zero agree with the committed
  test-only vector. This is not SystemVerilog run evidence.
- Established exact lower and upper bounds on the Foundation
  weave count by multinomial construction, checked using
  independent factorial and successive-binomial arithmetic.
  Count requires between 22350 and 22851 bits, i.e. 699..715
  32-bit limbs, and a base-M digit stream of 176..180 digits.
  See `docs/FOUNDATION_WEAVE_SIZE_AND_DP.md`.
- Dense suffix count DP for 45 month lengths would require
  about 2^292.57 possible used-count states and cannot be used.
  A scalable exact counting/unranking design is a required
  next gate, without using 384-bit arithmetic or pretending
  nominal months are contiguous.

## 2026-10-22 — compressed month-weave suffix count breakthrough

- Derived exact O(m*L) **root** count recurrence from legal
  insertion of each new largest month label, tracking the first
  occurrence of the newest label.
- Generalized to exact completion count of *any legal prefix*:
  first process already-started active labels under last-order
  restriction, then insert first fresh label and subsequent
  fresh labels using a first-position transfer.
- Independent exhaustive enumeration agrees on eight small
  instances and 258 valid prefixes. Extended
  `tb_weave_small_exhaustive.sv` with this comparison; awaiting
  actual SystemVerilog runner verdict.
- Calculated exact 45-month root weave count by two arithmetic
  recurrences: 22470 bits, 703 uint32 limbs, exactly 177
  consecutive base-M digits. Minimal big-endian SHA256:
  `925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da`.
- This turns the previous naive exponential dense DP into a
  polynomial exact counting *kernel*, but the complete
  lexicographic unranking, production bigint design, and
  45-month full weave CI evidence remain unimplemented.

## 2026-10-22 — final observed green evidence this turn

- Identified initial blocking lint error in run 39823278850
  as a module-scope `logic` declaration split over multiple
  lines, not a simulator/algorithm failure.
- Replaced line-oriented source preflight with semicolon-delimited
  declaration parsing and verified legitimate 2-D unpacked
  arrays versus reserved-name and duplicate-declaration
  negative controls.
- Actual CI 39836691095: full 45-month composition counting
  and lexical unrank PASS; eight toy weave cases PASS;
  465 prefix completion crosschecks PASS.
- Actual CI 39837437421: five additional 2048-bit exact
  medium weave root golden checkpoints PASS, for the
  actual Foundation first 2 through 6 months.
- Independent big-integer replay reconfirmed the Foundation
  full 45-month root bit length 22470 and SHA256
  `925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da`.
  This is **not** a full SystemVerilog root PASS.
- Next work: decide and implement bounded 22528-bit
  limb arithmetic, full-root exact checkpoint, and then
  streaming lex unrank of all 4244 woven days with
  candidate-resource safeguards.

## 2026-10-22 — exact full root and wide selection candidate

- Source implementation `tb_weave_full_root.sv` computes 45 actual
  month lengths in 22528-bit integers, using 864-bit exact
  binomial coefficients and guarded finite 4245-entry row arrays.
- Bounded runner: 6144-bit 12-month probe / 300 seconds,
  22528-bit full 45-month root / 2100 seconds; QA job has a
  43-minute timeout and 4 GiB virtual memory ceiling.
- Independent Python arbitrary-precision replay in this session
  confirmed the **22470-bit** root and its previously locked
  SHA256 `925c8a37...` from the actual committed 45-length vector.
- Reconstructed the full sauce for `(Foundation,firstDay)`:
  `Q4=68405753691768034022026521715063004414`,
  next bowl Q3, `A0=106458209471735273212934705135928382248`;
  reverse step (-1). Added these to the separate SV sauce test.
- Derived the 177-digit initial wide answer and its first-choice
  accepted rank in independent arithmetic: ring quotient 555,
  no rejection, 22469-bit ordinal,
  SHA256 `2c447438a567fbc40a79c68fb8b3f27f308cb89a2f59aaba1d2275dd3acf1a06`.
- Added `tb_weave_full_rank.sv` exact wide selection, reading
  the root **only after** its SHA is confirmed; its own SHA is
  checked in the full-root runner. Both are TEST_ONLY.
- Isolated QA PR-only full_weave_root job is present. Run
  39839764359 was queued, and superseding commits cancelled
  obsolete CI; newest conclusion not yet available.
- No full 4244-day weave unrank nor 47P45 names; no qualified
  Kalaallisut source-catalog approval; Stage 1 cannot close.

## 2026-10-23 — fully green 22528-bit root and 177-digit rank, then bounded prefix

- Verified the actual logs for run [39842311226](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39842311226), HEAD `02aeccd0a4e5b793f7c753a4e14cbcd2221f9422`: **both jobs completed SUCCESS**.
- 45-month full root computed 22470 bits, 2809-byte SHA256 matched
  `925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da`.
  From CI job timestamps, the 45-month kernel took approximately 8m28s.
- Exact 177-digit wide choice passed rank SHA256
  `2c447438a567fbc40a79c68fb8b3f27f308cb89a2f59aaba1d2275dd3acf1a06`.
  The residue quotient printed by the rank fixture was 347.
  Do not confuse this with the *domain* quotient 555.
- The same run's baseline job passed all earlier properties, sauce,
  gates, 45-month length selection, toy weave and medium-root tests.
- Added an independent 47P45 month name-index lexical-unrank test
  (bowl5 seal33), expected vector in
  `docs/FOUNDATION_MONTH_NAME_45_INDICES.csv`, still pending CI.
- Separately, exact Python reference completion-count replay
  after legal prefix [1,1] yields 22465 bits and SHA256
  `642e6ddd164593dd415bc78ea87142e949a1cc4728accff2c8693a9120f81cac`.
  Its block is strictly smaller than the selected root rank, hence
  the first two physical month ordinals should be [1,2].
- Added a bounded `+prefix11` path to the full-width test-only
  SystemVerilog oracle; it will emit the full block and check SHA256,
  then `tb_weave_prefix2.sv` checks the first two ordinals against
  verified root, rank, and prefix count. This new test has NOT YET
  passed native CI and is not a full 4244-symbol unrank.
- A full prefix unrank attempted in independent arithmetic grows
  computationally very expensive even within the first 11 symbols;
  no unbounded long-running CI job was added. Profiling and a
  resource-bounded algorithm are required before expanding.

## 2026-10-23 — SHA-bound prefix and 47P45-name QA work

- `tests/tb_foundation_month_names.sv`: exact name-index selection,
  seal 33, 45 distinct indices among 47 and 0 remaining rank,
  linked into the baseline Icarus runner. Its result is PENDING.
- `tests/tb_weave_full_root.sv` now has a distinct
  `+prefix11` option: 113 remaining month-1 copies and an
  unconstrained *first* insertion of month2; later months are
  handled by the existing exact transfer. It checks 22465 bits
  and emits `foundation_weave_prefix11.bin`.
- `scripts/verify_weave_fullroot.sh` verifies the entire root
  and selected-rank hashes before running the bounded prefix
  counter, verifying SHA256
  `642e6ddd164593dd415bc78ea87142e949a1cc4728accff2c8693a9120f81cac`,
  then checks `tb_weave_prefix2.sv` for prefix `[1,2]`.
- Artifacts for the prefix count and prefix verdict added to
  isolated QA workflow; no merge and no main changes.
- A preliminary independent full-precision unrank calculated
  eleven symbols of the selected word, but its follow-on
  computation exceeded a bounded runtime. See prefix reference;
  do not mark full word unrank accepted.
- At this checkpoint newer CI run 39915693359 was QUEUED.

## 2026-10-23 — verified CI green for month names and first 2 woven symbols

GitHub Actions run 39915988093 completed SUCCESS for both simulation
and `full_weave_root` on `3617858e4e3af8b8be8b9e4464b3cf3dd93ba62c`.
Actual job logs confirm:
- `STAGE1_FOUNDATION_47P45_MONTH_NAME_UNRANK_PASS`;
  all 45 canonical name indexes match the golden CSV, unused
  indexes exactly 21 and 47.
- Root and selected-rank SHA256 checks PASS again.
- 22,465-bit exact completion after prefix `[1,1]`,
  `foundation_weave_prefix11.bin` SHA256 PASS.
- `STAGE1_FOUNDATION_WEAVE_LEX_PREFIX_PASS first=1 second=2`.
  The selected woven sequence begins `[1,2]`.

The verified source does not produce the remaining 4,242
woven ordinals or final canonical month/day pair.

## 2026-10-23 — single extra full-root suffix to establish third symbol

Researched exact three-way lexical blocks after prefix `[1,2]`:
- `C([1,2,1])`: 22,465 bits; SHA256
  `0a29d31d02e980a1ae807575c85a908bd31a05eb73b521a80f7ee3f2e925f1a7`.
- `C([1,2,2])`: 22,465 bits; SHA256
  `50064b46e82a20681a0e100e8a1516e0b4c151398231dd2f898be22f07bb9866`.
- `C([1,2,3])`: 22,470 bits; SHA256
  `a89a9799db0649b78a5b24bf150f57dc11e549ce2d0d42088929974237762dde`.

Independent research arithmetic reproduced all three from
the full 45-month lengths and selected rank and verified
`C([1,2,1])+C([1,2,2])+C([1,2,3])=C([1,2])`.
Because remaining rank after `[1,2]` exceeds the sum of
the first two blocks, the third chosen symbol should be 3.

Optimization: both active months #1 and #2 have already
started. The active-subword count after prefix `[1,2,1]`
is `C(219,113)`; after `[1,2,2]` it is `C(219,114)`.
All fresh-month suffixes have the same 220 active
positions in both states, so
`C([1,2,2]) = C([1,2,1]) * 53 / 57`.

Added `+prefix121` exact 22,528-bit count to
`tb_weave_full_root.sv`; added
`tb_weave_prefix3.sv` to calculate the other two
blocks with 32-bit-limb exact small division.
The runner will independently hash-check all three
binary counts before reporting the third woven symbol.

**New CI verification still pending.** Current run 39931331917
was queued at last observation. No full unrank or stage PASS.

## 2026-10-23 — five woven ordinals CI PASS, exact sixth probe queued

- Read actual Icarus logs for [run 39981519434](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39981519434):
  all THREE jobs SUCCESS. In `fifth_weave_symbol`, pinning to
  completed 20-file root artifact from the previously partial-red
  run 39965349618 was confirmed. Prefix `[1,2,3,4,1]` and
  all four other fifth-choice blocks passed independent SHA256
  tests. Selected first FIVE canonical month ordinals
  `[1,2,3,4,5]` PASS in native SystemVerilog.
- Verified new independent exact completion reference after
  `[1,2,3,4,5,1]`: 22465 bits, SHA256
  `d8e4482e4011c525254fc9fbf7ff8c0b38d8f03debda9dc3db43c1058fc3cdf7`.
  Four other already-started suffix blocks are in the precise
  ratios 53/57, 330/323, 306020/328491, 132658240/146835477
  to the block ending with old month #1. The sixth possible
  branch is selected by difference from the parent.
- Independent arithmetic computed all six candidate suffix
  counts and selected month ordinal 6, giving research prefix
  `[1,2,3,4,5,6]`. Each candidate has a separate SHA.
  This is NOT yet an Icarus result.
- Added SystemVerilog `+prefix123451` test-only full-width
  suffix count to `tb_weave_full_root.sv`, and
  `tb_weave_prefix6.sv` verifies exact 32-bit denominators,
  reconstruction, six-block partition, one-based rank and
  the selected sixth ordinal.
- Added `scripts/verify_weave_prefix6.sh`, pinning two
  independent CI artifact sources by their merge SHAs,
  requiring all 15 input binaries and validating every SHA.
- Added independent QA-only `sixth_weave_symbol` job on branch
  `qa-systemverilog-kalaallisut-stage1-20261022` at
  `71e6cbd7a176e536ad01103ddcde842eb5496880`,
  budgeted to 22 minutes with 4-GiB VM limit and evidence ZIP.
  New full-width 6th-symbol source has NOT yet earned CI PASS.
- No changes to main, no opening Stage 2, no native Kalaallisut
  approval (0/64), and no complete 4244-symbol SV unrank.

## 2026-10-24 — actual sixth CI and seventh preparation

- Read `sixth_weave_symbol` job 120578557551 in successful
  [run 40001527283](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40001527283):
  source merge SHA pins PASS, all 15 input SHA256 PASS,
  prefix123451 exact completion SHA PASS, six selected
  ordinals `[1,2,3,4,5,6]` PASS.
- Derived seven independent completion SHA witnesses and
  ordinal 7 for the selected year by exact arithmetic.
  Checks include sum of seven blocks equals parent.
- Added `tests/tb_weave_full_root.sv +prefix1234561`,
  `tests/tb_weave_prefix7.sv`, and
  `scripts/verify_weave_prefix7.sh`. All run **test-only**
  and do not modify production ASIC logic.
- Seventh QA job added to isolated QA workflow at commit
  `95386321d664918170b4ea800585063980848180`,
  with three immutable prior evidence downloads, 22-minute
  timeout and 4-GiB VM bound.
- Latest available seventh candidate CI still unconfirmed;
  status remains `WRITTEN_NOT_CI_PASSED`.
- Proof for active last-appearance ratios and related
  limits added as `FOUNDATION_WEAVE_ACTIVE_RATIO_THEOREM.md`.

## 2026-10-24 — seventh CI accepted; eighth exact test case

- Retrieved job `120966467980` and Icarus logs from completed
  [run 40125682591](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40125682591).
  Full 22528-bit `prefix1234561` root, 21 historical input SHA256,
  all seven output blocks and selected ordinal 7 PASS.
  All five jobs were green.
- Independent Python big-int recurrence replayed the Foundation
  root/rank hashes, the seven-symbol parent, and all eight
  child blocks. First 8th choice is **4**.
- First ratio exceeding signed-int max is
  2917684055/2982394728. New `tb_weave_prefix8.sv`
  uses 64-bit unsigned ratio arguments, 22528-bit operands,
  limb-serial exact division, exact conservation and rank checks.
- Added `+prefix12345671` in `tb_weave_full_root.sv`
  to compute the 22464-bit independent 8th-choice block
  under existing 1100-second full-width test bound.
- `scripts/verify_weave_prefix8.sh` pins FOUR earlier CI
  merge SHAs, all 28 input binary hashes, and all eight
  new 2809-byte block witnesses.
- Isolated QA job `eighth_weave_symbol` added to
  `qa-systemverilog-kalaallisut-stage1-20261022` at
  `7b17e99c1281f6b94b954db9bda0e615a2e6476b`.
  CI outcome **PENDING**, no eighth-symbol SV PASS claimed.
