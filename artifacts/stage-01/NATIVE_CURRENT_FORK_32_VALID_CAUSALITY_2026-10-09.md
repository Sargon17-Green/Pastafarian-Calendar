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

## Acceptance boundary

The upstream `|` universal-output-causality question remains OPEN. The 32-domain diagnostic shows a reproducible branch-dependent asymmetry, not a universal final-output dependence. It neither changes the Befunge algorithm nor begins Stage 2.

`CURRENT_STAGE=1`; `LAST_COMPLETED_STAGE=0`; `FULL_FUNCTIONAL_QA_PASS=NO`; `GEOMETRIC_SPAGHETTI_QA_PASS=NO`. PR #17 remains Draft. Do not merge on the strength of this test alone.
