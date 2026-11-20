# Candidate Stage43 / Discovery28 — Neighbor-year gate response contract (2026-11-20)

PROJECT_ID: PC-BRANCH-POWERSHELL-TAGALOG
Branch: `PowerShell+Tagalog`
Status: **CONTRACT_ONLY / NOT ACTIVATED / NOT NATIVE-VERIFIED**
Scope: bounded, independent normative-oracle QA; no production changes, no expectation of an intentional failure, no merge/main/release.

## Predecessor evidence (accepted exact Stage42 seal)

The exact sealed Stage42 source was checked at commit `fcf1640de4f3a96f8bcb60822d067253b79af9ca`.
[Actions run 44799736042](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44799736042), attempt 1: `completed/success`, all **16/16** jobs successful on that exact commit. On hosted Windows PowerShell 5.1, Stage42 job `136508451039` returned `STAGE42_ASSERTIONS_PASSED=1657`, `STAGE42_ASSERTIONS_FAILED=0`, `STAGE42_NATIVE=SEALED_RECHECK_PASS`, with 160 endpoints, 80 calculation seams, 80 target seams, 40 mixed faces, 144 adjacent seal pairs. Artifact `14661575418`, ZIP digest `sha256:5c919dd5846ec20c0ddb1c603f6a9cc114d6b80e95fc69645ed06f8d5f42c0ed`.

Stage41 job `136508449965` returned 481/481 and `STAGE41_SEAL_RECHECK=PASS`. Stage40 job `136508450201` returned 425/425 and `STAGE40_SEAL_RECHECK=PASS`. Windows regression/finalizer job `136508449985` returned Stage30 96/96; both finalizer invocations `EXIT_CODE=0`, `STDERR_LENGTH=0`, `ALREADY_FINALIZED=True`, and before/after SHA256 identical:
`0E54874D8D8412185FA9F81F75A5528C820A76BD13C5D61657857AC438E013AF`.
Finalizer artifact `14660806960` (ZIP digest `sha256:9bdbb685c73bab4f8f901454b680c4fa6a487bfefbf1f9d30edb91be729c0bbb`). Canonical `verify` job `136508450517` completed/success. This is full acceptance of the *Stage42 seal at the verified predecessor SHA*, not Native acceptance of a future Stage43 commit.

## Research question / non-duplication

Stage42 tested the coupled calculation-day and target-day gates of a *single* normative year under all ten legal seals. The next bounded question is whether the source program's First/Step stream remains equivalent to the normative oracle at **both sides and the exact open/close gates of the neighboring years** (years 4999, 5000 and 5001), with explicit attention to the convention `OpenGateDay < TargetDay <= CloseGateDay`. It does **not** assert continuity of First/Step across a gate, since such continuity is not normative.

The oracle is the existing **same-repository independent normative implementation** `oracle/NormativeScroll.ps1` (`NormativeCore.ps1`, `NormativeCalendar.ps1`); no implementation or fixture from another branch may be imported. The source under test is `src/MonsterSkeleton.ps1` and its callable public functions. Never derive expected values by calling the source under test or by copying Stage42's measured outputs.

## Fixed finite inputs

1. Define `F = [BigInteger](Get-NormFoundationDay)`. Compute `Y = Get-NormYear5000 -CalculationDay F` and `C = [BigInteger]Y.CloseGateDay`. Calculation days are exactly `[F, C]` (two distinct contexts). Assert `F != C` and `Y.OpenGateDay < F <= C`.
2. **Recompute years separately for each calculation day `d`** (no cross-context assumption that Year5000 gates are unchanged): `Y0 = Get-NormYear5000 d`, `Yminus = Get-NormPreviousYear d Y0`, `Yplus = Get-NormNextYear d Y0`.
3. For each `d`, define four ordered boundary points `G = [Yminus.OpenGateDay, Yminus.CloseGateDay, Y0.CloseGateDay, Yplus.CloseGateDay]`. Assert `Yminus.CloseGateDay = Y0.OpenGateDay` and `Y0.CloseGateDay = Yplus.OpenGateDay`; assert all four gate days are strictly increasing.
4. For each gate `g` take target days `[g-1, g, g+1]`, yielding **12 distinct target days** per calculation context. For each target, query numeric bowl ID **1** under legal seals **1..10** only; never silently extend source bowl-ID domain. All day arithmetic, differences and modulus are `System.Numerics.BigInteger`.
5. Endpoint grid: `2 calculation days x 4 gates x 3 target offsets x 10 seals = 240` unique labeled samples. The program execution must be bounded to these 240 samples; no exhaustive date-space walk, stochastic sampling, persistence or unrelated production actions.

## Independent oracle and strict assertions (planned, not executed)

For every `(d, t, seal)`, run source `Invoke-CalendarDateSpaghetti -CalculationDay d -TargetDay t`, then `Get-Discovery13AnswerStreamFromContext -Context source -QueriedBowlId 1 -Seal seal`. Separately run normative `Invoke-NormSauce d t`, then `Get-NormAnswerStream -SauceResult normative -QueriedBowlId 1 -Seal seal`.

Six source checks **per endpoint**: First equal to normative First; Step equal to normative Step; First lies in `[1,M]` where `M=Get-NormM`; Step is exactly `+1` or `-1`; legacy order writes equal **58**; Patch12 invocation count equal **1**. Planned **240 x 6 = 1,440 assertions**. The latter two are existing source-architecture invariants and are not claimed as independent normative outcomes.

For each of the four gates in each calculation context and each seal, compare two adjacent target pairs `(g-1,g)` and `(g,g+1)`. Pair comparison: modulo-`M` First difference source equals independently computed oracle First difference, and the boolean Step-change source equals oracle. Planned **2 x 4 x 10 x 2 = 160 target pairs**, **320 assertions**. Normalize modulo using `((x % M) + M) % M`.

For each calculation day and target, compare each adjacent seal pair 1→2, ..., 9→10 with the same two oracle-based differences. Planned **2 x 12 x 9 = 216 seal pairs**, **432 assertions**. Assert equality, **not** a made-up invariance or uniform distribution.

Exactly **23 additional structural guards**: per calculation context (11 each): Year5000 number=5000; previous=4999; next=5001; previous close=current open; current close=next open; strict positive span for all three years (3); gate count/strict distinct order=4; target count/distinctness=12; calculation day lies in the recalculated Year5000. Plus one guard that the two calculation days differ. Do not turn oracle failures into synthetic expected-red cases.

Planned total **1,440 + 320 + 432 + 23 = 2,215 assertions**. Planned counts are a contract, **not actual PASS**. Any rejected source input, oracle exception, mismatched sample, invalid count or structural guard failure means failed Gate; no silent case skipping, fallback, capped enumeration or acceptance by job-level green alone.

## Acceptance gates and restrictions

- Contract existence/readback alone is **STATIC DOC ONLY**. It does not open or activate Stage43 and must not change `CURRENT_STAGE`, `CURRENT_DISCOVERY`, `LAST_COMPLETED_STAGE`, `STAGE42_RUNTIME_VERIFICATION` or any Stage43 runtime status.
- Future separate implementation: independently materialize `tests/Stage43.Tests.ps1` with explicit counts, deterministic labels, fail-fast errors and structured evidence; add a correctly scoped dedicated hosted Windows PowerShell **5.1** job and retained metadata/transcript artifact. First record **preflight** at exact implementation SHA. Do not call a Linux or local static inspection Native.
- At acceptance: check `completed/success`, run attempt, **exact SHA**, each relevant job and actual log assertions, ZIP artifact ID/hash, canonical verify and Stage23 twice-idempotent finalizer. Existing stage regressions must pass. Do not dispatch duplicate queued/in-progress runs and do not rerun an accepted exact SHA without new reason.
- No production patch, oracle edits, metadata stage transition, branch protection bypass, merge to `main` or publication is authorized by this contract.
