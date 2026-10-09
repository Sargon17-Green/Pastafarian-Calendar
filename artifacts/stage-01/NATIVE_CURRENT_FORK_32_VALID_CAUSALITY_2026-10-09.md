# Stage 1 — current upstream |: 32 Native branch/causality observations

**9 October 2026 · QA-only.** This is a bounded empirical diagnosis, not final Stage-1 functional, spaghetti geometry, or semantic ownership acceptance.

## Frozen source and execution

- Active QA source: `src/interleaved_work_counts.b98`, Git blob `560d6aa5807a7f766213a33835cce85eab0fa40c`. Canonical `Befunge+Кыргызча` and `main` were not changed.
- Native test: `qa/stage1_native_current_fork_route_differential.py`. It observes real PyFunge-98 `Program` execution, flips only the operand immediately before an actually executed `|` at `(951,1335)`, and leaves every source byte intact.
- Valid inputs: 14 original diverse cases plus 18 signed/wide cases, including 128-bit and decimal 10^41 boundaries. Invalid sign/lexeme inputs are excluded from this specific experiment.
- Reference output: seven fields computed by the three independent Befunge-98 programs, not by Python.
- [Real Native run 37952419130](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37952419130), commit `752b5849935830bf6ee1a23c8404a3c9b41d2b8f`: focused `native-fork-operand-counterfactual` job SUCCESS, 32 measured inputs. Full workflow is a separate status. The subsequent QA guard also requires this class separation explicitly.

## Observed classification, 64 real Native Program executions

| Actual pre-`|` operand | Number of valid inputs | Opposite branch physically selected | Final output/execution changed |
|---|---:|---:|---:|
| Zero | 12 | 12/12 | 12/12 |
| Nonzero | 20 | 20/20 | 0/20 |
| **All** | **32** | **32/32** | **12/32** |

Every forced-opposite case chose the opposite vertical Native IP vector. In all 32 comparisons, both measured trajectories also contained a matching five-event motion sequence, within a 512-event observation window.

## Stronger observed Native stack-state witness (source unchanged)

A later [exact-PyFunge run 37954028561](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37954028561), focused `native-fork-operand-counterfactual` job SUCCESS on source SHA `560d6aa5807a7f766213a33835cce85eab0fa40c`, also captured the real instruction pointer's **TOSS contents**, not just positions and directions, at both sides' first shared five-event motion window.

| Observed class | Cases | Identical TOSS on all five shared motion steps | Unequal TOSS on all five |
|---|---:|---:|---:|
| Natural nonzero `|`, output-inert forced inversion | 20 | 20 | 0 |
| Natural zero `|`, output-causal forced inversion | 12 | 0 | 12 |

The matching-geometry windows were located from actual Native IP observations. Real TOSS data was compared at those same indices; 32 synthetic one-snapshot TOSS changes were rejected by the local equality check. The supplementary QA guard added after that run now requires exactly these 20/12 relationships and must itself pass an exact-head CI run.

**Interpretation:** There is direct evidence of stack-value reconvergence on the sampled inert paths and stack-value divergence on the sampled causal paths. This explains the observed output asymmetry more concretely than a common IP trajectory alone. These observations still do **not** establish equal SOSS frames, every Funge-space cell, temporal write history, remaining input stream, or full execution state. An output-inert forced fork can be a legitimate redundant path in some input domains; final geometric acceptance cannot require every forced inversion to change output without a separate explicit normative rule.

**Do not overclaim.** Matching motion events do not imply matching full Funge-space, total program state, or numeric results. The strict equivalence between naturally **zero** gate operands and changed final behavior is **only observed for these 32 inputs**; it is not a mathematical proof for every integer. Twenty **nonzero-operand** inputs exhibit genuine branching but output-inert forced inversion.

## Corrected classification and failure provenance

A later Native job, [37952921013](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37952921013), failed its final 32-case assertion despite all 32 individually logged Native routes passing: its expected `zero=20/inert, nonzero=12/causal` classification had inverted the observed `|` operand classes. The real Funge-98 IP headed down `(0,+1)` for the 12 zero operands and up `(0,-1)` for the 20 nonzero operands. This report corrects the descriptive error; it does not remove the strict 32-case assertion or claim universal causality. A fresh exact-HEAD CI run is required to validate the corrective QA commit.

## Additional bounded IP-context audit

The next QA replay records the **real PyFunge IP storage offset, string/invert/queue modes, and input cursor** on both executed branches at the five already matched motion checkpoints, covering 32 valid input pairs. The independent evidence checker rejects two extra adversarial mutations to these fields. These are bounded runtime-context observations, **not** an assertion of equal entire Funge-space, all fingerprints, or complete execution state. Exact-commit Native CI is required before accepting the results.

## One precisely localized native p-scratch divergence

The [real PyFunge-98 run 37957517917](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37957517917) at QA commit `9a0643c9612aba54a9d5c0e233cafa680bdcf26a` retained the raw all-stack-frame and p-modified-Funge-cell values, along with the independently checked SHA-256, at five matching IP-motion checkpoints for each of the 32 normal/forced-opposite run pairs. Original GitHub artifact ID: `11627988606`.

Inspection of **all 160 paired checkpoints** shows exactly one differing p-mutated coordinate: **(1490,1600)**. In all 20 naturally nonzero | cases the normal arm wrote decimal **12** there and the forced arm retained the source's original blank byte. In the 12 naturally zero | cases the sides are reversed. All remaining cells changed by p had equal physical values at the matching motion steps, despite different path histories.

The actual p operation counts differ by **exactly one per paired run**, with the extra write on the side possessing value 12 at that scratch cell. The observed 160 stack-of-stacks snapshots all contained exactly one frame, so the previously reported 20-case full-frame equivalence follows from the measured TOSS equivalence at those checkpoints.

**Limit:** this proves a localized divergence of the native *p*-mutated memory, not the entirety of Funge-space, every past write, remaining input, or global semantic-state ownership. The QA evidence checker now enforces the exact-cell, exact-value, write-count and initially-blank invariants, including two new hostile mutations. Its latest exact-HEAD regression must pass before the new guard can be marked complete.

## Exact read-after-write and post-rejoin scratch liveness (32 valid Native inputs)

Verified against the original GitHub Actions artifact `11631119170` from [QA run 37960506587](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37960506587), which completed **31/31 SUCCESS** on commit `77f9a48dc4ae891cbbf47a6fcf2e740b12c2ac76`:

- In each of the 32 actual branches executing `p/g`, Native `p` committed decimal **12** to `(1490,1600)`; Native `g` later read the same value **29 executed instructions after p**, and the first five-motion reconvergence checkpoint followed **14 instructions after g**.
- The other 32 branch runs did not execute scratch-addressed `p/g` and preserved the implicit-space byte `32` at that coordinate.
- A separate 128-execution PyFunge intervention corpus observed **64 normal-vs-mutated tail pairs**. Flipping the scratch cell at the first matching directed IP-motion checkpoint caused **0/64** final-output/termination changes. Across baseline and intervention tails alike, the observers recorded **no subsequent scratch-targeted g reads, p writes or IP execution at that location**.
- This is an input- and checkpoint-bounded proof. It does not cover all Funge-space read/write mechanisms, all input domains, or universal scratch-cell deadness. The follow-up independent tail checker adds strict timing and zero-tail-access invariants plus three new negative mutations; its exact-head CI must pass separately.

## Acceptance boundary

The upstream `|` universal-output-causality question remains OPEN. The 32-domain diagnostic shows a reproducible branch-dependent asymmetry, not a universal final-output dependence. It neither changes the Befunge algorithm nor begins Stage 2.

`CURRENT_STAGE=1`; `LAST_COMPLETED_STAGE=0`; `FULL_FUNCTIONAL_QA_PASS=NO`; `GEOMETRIC_SPAGHETTI_QA_PASS=NO`. PR #17 remains Draft. Do not merge on the strength of this test alone.


## Stage-1 QA: controlled single-cell scratch liveness (pending exact-HEAD Native run)

A separate experiment starts at each *actually measured first common five-step
IP motion* for the 32 valid inputs and both naturally selected/forced-opposite
branches. Each branch is replayed unchanged and then again with **only the
runtime Funge-space cell (1490,1600)** switched between the previously observed
blank value 32 and written value 12 at the same native IP tick. It records
subsequent completion, all seven output fields, instruction count, and
candidate later native g/p accesses to that coordinate.

The reference fields remain computed only by independent Befunge programs.
The 128 real PyFunge executions and an independent seven-tamper evidence
audit are QA-only, and classify effects rather than presupposing them.
Even unchanged output cannot establish universal dead memory: alternative
memory instructions, interpreter bounds, untested inputs and later lifecycle
states are outside the proof. **Stage 1 stays OPEN**, PR #17 stays Draft,
and no production Befunge source or canonical branch is changed.
