# Stage 1 — integrated lexical parser candidate, QA-only

2026-10-08. **Native acceptance not yet verified. Not merged. Stage 1 remains open.**

## Bug reproduced in historical native runtime

The original production program at Git blob
`e06d8f75d6502b2771d6a76b00397c6b6dbee543` accepts raw
`0 -1 0 1` as if `0 1 0 1`. The correct contract requires
`-1 -1 -1 -1 -1 -1 -1`. Historical native run:
https://github.com/Sargon17-Green/pastafari-calendar/actions/runs/37787577988

## QA candidate files

- `qa/lexical_candidate.b98`: standalone native Befunge-98 scanner.
- `qa/interleaved_work_counts_lexical_candidate.b98`: scanner
  inserted into the original 2D production map **without moving the original
  arithmetic**. This is a candidate, not an authoritative production change.
- `qa/stage1_native_integrated_lexical.py`: native differential against
  `reference/work_counts.b98` and two separate
  `reference/save.b98` executions for nineteen valid day pairs,
  with malformed input rejections and independent original-implementation parity.
- `qa/stage1_parser_integration_structure.py`: static exact-source
  preservation test.
- `qa/stage1_full_execution_geometry_sim.py`: step-by-step local
  2D instruction-pointer and self-modifying write trajectory comparison.
- `.github/workflows/befunge-kyrgyz-stage1-regression.yml`:
  independent native candidate test job, native write audit and local preflight.

Candidate Git blob: `e2b39b066d1d47bcb8ce4f234b093fca94cb21d1`.

## Source map and state handoff

The original program's bounding rectangle is **1531 × 2016** cells.
Rows 1–49 were entirely empty in the original source. The scanner lives
inside those reserved rows and writes its own input scratch cells at
`y=49, x=0..3` and parsed value cells at `y=49, x=10..13`.

- New code starts at the entry vector `(0,0)`.
- On a valid four-token lexical input, it saves the four exact nonnegative
  integer values and returns to original arithmetic.
- The scanner's first attempt returned directly to `(5,0)` while leaving
  a noncanonical direction vector: that prototype failed full-program
  simulation and was replaced.
- The repaired candidate returns first to `(4,0)`, executes a
  **`>` instruction** to restore velocity `(1,0)`, then proceeds to
  original calculation at `(5,0)`.
- Invalid lexical input terminates immediately with seven `-1` outputs.
- The original arithmetic bytes at `row=0,x>=5`, every original source
  byte in `rows>=50`, and both source extents are exactly preserved.
- The original `p/g` executable interleaving remains intact. The scanner
  adds its own runtime Funge-space writes, so its state-ownership lifecycle
  also requires native audit.

## Test evidence and remaining acceptance

Two test-only, BigInt-safe Funge instruction simulations were performed.
The corrected integrated candidate gave **12/12 whole-program output
agreements** or correct lexical rejection against the original interpreter
model. The four-number input stack and `(1,0)` entry direction were verified.
These are *local simulations*, **NOT** native PyFunge runs.

Native acceptance must prove both the exact independent-reference values
and executable instruction-pointer/write-after traces. The external
reference and original production may not be replaced by Python
calendar calculations.

**Required next step**: native candidate qualification, fix any discovered
differences, then graduate the candidate to production only after the
full Stage 1 functional and geometric gates. Do not mark Stage 1 complete
or begin Stage 2 based on these tests.

## Additional exact execution-trajectory reconciliation

A separate JS BigInt-compatible Funge instruction simulation compared the
**entire post-entry IP stream** (x/y, direction, executed instruction) and
the complete **post-entry `p` write stream** for three input families:

- `0 0 0 0`: 7,406 observed instruction/write events, 32 `p` writes;
- `1 15055672 1 15055670`: 26,110 events, 128 `p` writes;
- `2 10 0 10`: 11,958 events, 56 `p` writes.

All three original-versus-integrated event streams were **byte-for-byte
equal after the handoff to (5,0)** in this local simulator. Runtime
scanner events occur before that handoff; they are extra code, not counted
as equivalent original arithmetic events. This is evidence of precise
geometry preservation for these cases **in the local simulation only**.
Independent native interpreter confirmation remains PENDING.


## Checkpoint 2026-10-08 — native-qualified QA-source promotion

**This section supersedes prior "unverified candidate" language above; the earlier
paragraphs are kept as historical development evidence.**

Native run [37831929988](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37831929988)
at SHA \`cc02c86d75b1fd5aa3598e25a04a64cdf33d5ade\`
established 5 PASS jobs: 421 targeted native regression invocations plus
order permutations; 43 valid + 48 invalid native standalone lexical parser cases;
123 integrated native differential invocations; exact native IP and g/p
post-handoff parity over 26,708 valid and 12,194 invalid events;
24 fresh native Program runs plus two simultaneously live stepwise pairs.
The sole failing job reproduced the original lexical bug in the old \`src\`.

**QA-only promotion performed AFTER those native successes:**

- \`src/interleaved_work_counts.b98\` in the **QA branch only** now has
  exact Git blob \`e2b39b066d1d47bcb8ce4f234b093fca94cb21d1\`,
  identical to the independently native-tested
  \`qa/interleaved_work_counts_lexical_candidate.b98\`.
- \`qa/interleaved_work_counts_pre_lexical_baseline.b98\` preserves the
  original Git blob \`e06d8f75d6502b2771d6a76b00397c6b6dbee543\`.
- The canonical branch \`Befunge+Кыргызча\` still contains the original
  source and \`main\` has not been changed. No merge.
- The six CI jobs are rewired to use the promoted QA production as the
  source under test, with the original byte-identical baseline for
  differential IP/p/g comparison and a historical negative control for
  malformed sign tokens. Exact source hashes are pinned.
- **Post-promotion all-six-Native-CI result: PENDING.**

There is still no verified reset/reuse of **the exact same previously
mutated Program object**. This is separate from the passed 24-fresh-Program
and two-pair interleaving tests. Stage 1 and ownership audit remain open;
\`LAST_COMPLETED_STAGE=0\`, Stage 2 not started.
