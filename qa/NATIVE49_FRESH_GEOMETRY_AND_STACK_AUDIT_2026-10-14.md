# Befunge-98 + Кыргызча — Fresh Native 49-run geometry and stack evidence

Scope: **Stage 1 QA only**, no production/canonical branch promotion and no Stage 2 work.

## Provenance

- Native PyFunge 0.5-rc2 run: GitHub Actions **38583219789**; original Native 49 runs completed; this early run was **red only at the then-stricter independent receipt auditor**, subsequently corrected.
- The same 49-route production-independent candidate/source pin passed the complete source-byte + physical gate + SHA-bound independent receipt audit in run **38585069069**.
- Original artifact ID **11903744065**, archive SHA-256 **29152d570d9e61b7d9b13fd34e66c640b1200046171c8897163bf5c3900f19e1**.
- Candidate Git blob: `d965ce4bdfa282f2d3b82690808def5a2dde10a8`; base source Git blob: `560d6aa5807a7f766213a33835cce85eab0fa40c`.
- Exact cases: signed day-axis pairs `[-3,3] × [-3,3]` (49 pairs). Native references were 147 separate Befunge programs. All 49 candidate outputs matched their three Befunge reference results.
- A separate local independent Befunge subset interpreter replayed **all 49 fresh Native executions**, before and after the fork, including source-driven IP movement, stack-stack instructions, mutable Funge-space, p/g values and seven output numbers. It passed **49/49**. The interpreter was initially written for the historical corpus, but this audit used the new 2026-10-14 artifact above.

## Fresh measured geometry (not a synthetic route)

| Measurement | 49-run total or scope |
|---|---:|
| Native executed instructions | **962,015** |
| Executed instructions before the physical `|` gate | **495,243** |
| Executed instructions after the physical gate | **466,772** |
| `p` writes | **3,936** |
| `g` reads | **7,453** |
| Steps with dynamically assigned, non-cardinal/non-unit vectors | **14,570** |
| Executed IP direction changes | **29,686** |
| Executions of source-modified executable bytes | **146** |
| Distinct self-modified executable cells counted per-case | **98** (two in each case) |
| Directed-route crossings with multiple velocities at one cell | **146** counted per-case |
| Unique spatial coordinates in the union of 49 routes | **12,421** |
| Unique directed nodes in union | **12,428** |
| Unique directed edges in union | **12,432** |
| Distinct directed route signatures | **3** |
| All four cardinal directions executed | **49/49** |
| Dynamically modified source bytes later executed | **49/49** |
| At least two multi-velocity crossing cells | **49/49** |

The three route-signature classes correspond exactly to **21** negative-calculation-day cases, **27** nonnegative-day cases outside zero-equality, and the **single (0,0)** equal-day case. This is a finite measured route partition, **not** evidence of 49 distinct input-dependent control-flow graphs.

Every executed opcode in the local geometry audit was matched to either the immutable candidate `.b98` byte at that coordinate or the last chronologically preceding native `p` write to that coordinate. Every receipt's SHA-256 was bound to the manifest before replay. The independent stack interpreter separately checked the 49 full executions: 12,071 `x` instructions, 49 `k`, 49 `w`, 28 each of `{`, `u`, `}`, 28 `j`, and 343 reference-matched numeric outputs.

## Exact limitations and next acceptance gates

1. **Not a proof of all Stage 1 semantics.** Full Appendix A normative oracle, the full calendar core and comprehensive Year 5000/gate/weaving boundary corpus are not established by these 49 signed-day cases. Production `FUNCTIONAL_QA_PASS` remains **NO**.
2. **Not a universal geometry claim.** The candidate is a QA-only four-cell variant, not an accepted production integration. Quantitative source modification, crossings and input-dependent routes do not by themselves prove the required semantic entanglement for every significant algorithmic stage. `GEOMETRIC_SPAGHETTI_QA_PASS` remains **NO**.
3. **Ownership scope.** Fresh Program objects in the same Python interpreter have separate mutable Funge-space. Reusing one ended Program object without an explicit reset is outside those tests and cannot be claimed. The project's real invocation boundary must be specified before a final ownership sign-off.
4. No change to `src/*.b98` was made in this QA step. This evidence must never automatically set `LAST_COMPLETED_STAGE=1`, merge PR #18, or start Stage 2.

Reproduction artifact: GitHub Actions run 38583219789 / artifact 11903744065; independent exact source replay and SHA-256 of the artifact pin above.
