# Stage7 R2 — authorized tracked-source formatter rebaseline (2026-11-23)

PROJECT_ID: PC-BRANCH-DART-HEBREW. Authorized by user after explicit R1 rejection. Branch-only; no main, merge, Stage8, release, or change to candidate B's performance/default policy.

## Source contracts

- Parent/previous branch head: `12289c4ae379bde41b62df8c6d8611e4b4bffe8c`.
- Historical A source: `1d98a83db7446ceb4548c39e0eaf9b4441b72b9a` / Git blob `3553a7f2e3899c958d56620c5449daa35b0731e2`, preserved unchanged.
- Historical B tracked source: Git blob `d736ca8afe3409a10474b8514284aceb154a46a9`, preserved in previous commit.
- R2 tracked B blob: `749b874d2fc736a02bfd3985ac7897ea4fb8c407`.
- R2 disposable rebaselined A blob: `a29fe8d80f3d1c2dbe6efb18075eea6a01af1853`, deterministically obtained from historical A using exactly the same formatter hunk substitutions. No historical A rewrite.
- Allowed hunk 1: place the `result[j]` assignment RHS on its own following line; arithmetic tokens unchanged.
- Allowed hunk 2: collapse `MonsterWorkCounter().calculate(calculationDay, firstDay)` and remove the single syntactically optional trailing call comma. R1's whitespace-preserving exception remains **rejected**. The original strict comparison was correctly false; R2 records a *new source baseline* instead of relabeling it PASS.

## Acceptance and observation boundaries

The new Native run has **not** passed at commit authoring time. CI job `dart-hebrew-stage7-isolated-restoration-qa-only` is enabled for the exact `[stage7-r2-only]` marker, while the legacy A/B benchmark is skipped by this marker to avoid duplicate historical-only performance work. The normal Stage7 hotpath and regressions still run naturally.

The R2 job must verify: branch and exact HEAD; historical A and B Git blob locks; new tracked B Git blob lock; deterministic two-hunk B patch; reconstructed A formatted blob lock; `dart format --output=none` reporting 0 changed for both isolated variants; `dart pub get`, `dart analyze`, 1788 independently enumerated lexicographic ranks per variant (domains 26+461+1301), 6 out-of-bounds and 3 immutable checks per variant. Source output artifacts and job/commit SHA are required for acceptance. Clean-format checks are **new-SHA evidence**, never inherited from old SHA.

B's previous performance case [4,4,4] failed (2/5 wins, median -9.308410%), so policy stays **KEEP_A_DEFAULT**; branch executing B is not proof of authorization to promote it. No performance or Stage7 acceptance is declared merely because CI passes. The differential and formatting portions of R2 must finish with completed logs and artifacts before their outcomes are known.
