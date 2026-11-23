# PC-BRANCH-LOGO-IDO — Stage 2 integration-gap audit and bounded dispatch QA candidate (2026-11-23)

**Scope:** Existing Stage 2 only. QA-only static/code + independent host mathematics, **not Native PASS**, not integrated acceptance, not Stage 2 acceptance. LAST_COMPLETED_STAGE=1. No canonical, main, merge, publication, or policy change.

## Source provenance and current acceptance boundary

- Canonical `Logo+Ido` at audit: `ad001c6aeeb6c758f5004b206a656fec5d6fc403`, `DEVELOPMENT_STAGE.md` states `DISCOVERY21_CANONICAL_NATIVE_PENDING`; do not infer canonical Native acceptance from a QA run.
- QA source parent `633db2c4c12e7d4ba0872b2c97fdf23439e1bea7`, followed by evidence-only commit `cddd7fb1b84e51defc948953dec18d48b2f1cead`.
- Locked QA blobs already at the parent: `src/stage02_choose_short.logo` `a556145f52a6c59018b0ef216d7a4fc6813e0f23`; `src/stage02_choose_wide.logo` `8fb2dc47c827b8ccd8fa6fdd817b9fa088c51013`; `src/stage02_choose_wide_general.logo` `bda23ddc1d0f8a534b20d8391ecc7519fccd57c3`; `test/normative_reference.logo` `625171ecd5fd93fb8381686f2b2f6b29ed3649cf` (test-only reference, never an oracle).
- Previously accepted bounded QA: two-digit wide Native run 44947067097 at `1fea4a9a2b1f595151411b1f3457546deb8bd2e4`; general fastmod six-shard Native run 45087182742 with 134 cases/212 checks; Horner run 45087182646, 5 cases; Names Lock 45087182592 on exact QA SHA 633db2c4. Previous evidence and artifacts remain unchanged; no repeated dispatch.

## Confirmed gaps vs non-gaps

1. **Missing integration entrypoint:** canonical tree at `ad001c6a` has `src/stage02_choose_short.logo`, but neither `src/stage02_choose_wide.logo` nor `src/stage02_choose_wide_general.logo`, and no `src/stage02_choose_rank.logo`. The QA parent has the three reporters, but no single production reporter dispatching by N. The actual new source in this commit fills *only* the QA dispatcher gap.
2. **No algorithmic hole at M<N<=M²:** the earlier QA `monster.stage02.choose.wide` already implements this two-digit interval and was separately tested. Do not repeat that work or mislabel it missing.
3. **Shared stream and downstream remain unproven:** D20/D21 composition used synthetic ASK streams; neither that gate nor independent k>=3 fastmod shards proves a true D19 ASK-to-dispatch-to-unranking/calendar route. `nr.choose.rank`, `nr.unrank.names`, cutlet/month operations in `test/normative_reference.logo` describe reference behavior, not production integration.
4. **General-k capacity:** accepted Native QA covers k=4,5,6,32,33,64 with fixed case budgets. It does not guarantee arbitrary width, unbounded stack, or uniform performance.
5. **Exact-source acceptance:** the new dispatcher has no Native execution at its new commit SHA, so source addition is **code only**; prior Native results for pre-existing helpers are not transferable to a combined production acceptance claim.

## Bounded new reporter contract

`monster.stage02.choose.rank :stream :N` is a pure Logo reporter. Valid `:stream` is a two-item list `[firstBI step]`, with canonical BI `1<=firstBI<=M`, `step` exactly +1 or -1, and canonical BI `N>=1`. Let `M=2^127-1`. Invalid inputs return `[]`; malformed internal BI objects that cannot be inspected are outside the guard contract. Do not convert BI to floating point or mutate global state.

Dispatch is mutually exclusive:
- `1<=N<=M`: `monster.stage02.choose.short` (k=1).
- `M<N<=M²`: `monster.stage02.choose.wide` (k=2).
- `N>M²`: `monster.stage02.choose.wide.general` (least k>=3 with `M^k>=N`).

The new dispatcher checks `N` before any BI comparison; the selected reporter performs the existing independent stream/step guards. For any accepted stream the rank is a canonical BI in [1,N]. For k>=2, define `x_j=1+((firstBI-1+j*step) mod M)`, `S=M^k`, `W=1+sum((x_j-1)*M^j)`, `L=floor(S/N)*N`. If `W<=L`, rank is `1+((W-1) mod N)`; otherwise rank=1 for +1 and rank=N for -1. The same rule with k=1 is the D21 result. No new stage or user decision is introduced.

## Independently run host mathematical check (NOT Logo execution)

Source: `qa/logo_stage2_integration_boundary_oracle.py`. No import of this repository or its normative reference. For bases 2..11, it independently constructs consecutive digits and explicitly walks candidate rejection; a second implementation uses closed-form per-index digits and high-to-low Horner with the constant-time suffix decision.

Actual local Python execution (2026-11-23) output:
```text
PROJECT_ID=PC-BRANCH-LOGO-IDO
SCOPE=HOST_MATH_ONLY; NO_NATIVE; NO_CANONICAL_PROMOTION
FINITE_DIFFERENTIAL_CASES=80206
FINITE_REJECTED_INITIAL_CASES=16558
FINITE_WIDTH_COUNTS=k1:1010,k2:7700,k3:71236,k4:260
PRODUCTION_M_BOUNDARY_SHAPE_CASES=80
LOGO_IDO_INTEGRATION_HOST_MATH=PASS
```
The 80 production-M probes cover N = M, M+1, M², M²+1, M^31+1, M^32, M^32+1, M^63+1, M^64, M^64+1 with first=1,2,M-1,M and both directions; these check mathematical shape/range only, **not independently enumerated long rejection walks**. No false claim that the host math check executed the new Logo dispatcher.

## Required NEXT gate before QA acceptance

1. Reverify this new QA branch's exact live HEAD and all four dependency blobs; inspect source for pure delegation and absence of new global state.
2. Add a **new source-locked, bounded Native integration fixture/workflow only on the QA branch**. The independent fixture generator must not consult `nr.choose.rank` or any previous fixture. Cover N at M, M+1, M², M²+1; both step directions; initial wraps; accepted/rejected suffix; invalid shape/canonical-BI/zero-N; k=31/32/33 and 64/65 transition where runtime permits. Never route k>=32 through D20's `answer.at` bounded 0..31.
3. Before running, fix deterministic case/check counts, Native timeout, genuine pinned UCBLogo 6.2.5, source locks, host oracle, explicit exit and log markers, and artifact manifest. Wait for naturally triggered exact-SHA run; no duplicate manual dispatch.
4. Inspect run, job, SHA, logs, Native counters, exit, and artifact digest, then distinguish bounded dispatcher QA from downstream D19/structure and Stage2 acceptance.
5. Do not promote any of these files to `Logo+Ido` or mark Stage 2 complete without an independently authorized canonical gate.

**Status:** QA dispatcher source candidate + host differential mathematics only. Canonical untouched. D=פתוחה, G=READY.
