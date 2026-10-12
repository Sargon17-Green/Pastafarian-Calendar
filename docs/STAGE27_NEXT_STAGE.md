# Stage 27 पूर्ण — Stage 28 DISCOVERY14 साठी continuation

## Source of truth and boundaries

- Repo `Sargon17-Green/Pastafarian-Calendar`, **only branch `TypeScript+मराठी`**; no edits to `main` or other branches.
- Exactly 55 stages, **LAST_COMPLETED_STAGE=27** (PATCH13). Next stage is **28 DISCOVERY14**; do NOT begin Stage29 PATCH14 during the same response.
- Stage27 production verified at commit `2b3485995f97e6f0efa2013f0e2db44d893be194`; [Actions run 38253073014](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38253073014) both `verify` and `stage27-typescript-marathi` SUCCESS.
- Read the LIVE HEAD before work, plus `DEVELOPMENT_STAGE.md`, `docs/STAGE27_PATCH13_VERIFICATION.md`, `src/patch13RejectionRank.ts`, `src/discovery13LegacyBiasedModulo.ts`, `test/normativeOracle.ts`, and full authoritative 55-stage project contract. Do not guess Stage28 defect details from its ordinal alone; identify the exact defect, affected domain, and normative reference first.
- Pure TypeScript production; Marathi documentation/comments, frozen `SourceLanguageCatalog` and `CANONICAL_NAMES_LOCK.sha256`. Test-only normative oracle must never be imported by production.
- Keep 13 previous archived `test/discovery01Red.ts` through `test/discovery13Red.ts` deliberately failing with their exact markers; CI expects their nonzero exits. Final `calendarDateSpaghetti` route still unavailable until Stage54.

## What Stage27 changed

Corrected independent production `Patch13RejectionRankAdapter.choose(stream,N)` implements:

```text
M = 2^127-1
answerAt(j) = 1 + regularMod(first-1 + direction*j, M)
SHORT N<=M: L=floor(M/N)*N, first accepted answer <=L, rank=1+mod(answer-1,N)
WIDE N>M: least k with M^k>=N,
  candidate=1+sum_{j=0}^{k-1}((answerAt(j)-1)*M^j)
  L=floor(M^k/N)*N
  reject while candidate>L, moving ±1 cyclically in the M^k space
  rank=1+mod(acceptedCandidate-1,N)
```

The algorithm optimizes only rejection iteration: for start candidate y>L, direction -1 first accepted value is L after y-L rejections; direction +1 first accepted is 1 after space-y+1 rejections. This is mathematically exact even for astronomical gaps; do not replace with approximate/modulo-biased shortcut. Stage26 old wrong `LegacyBiasedModuloRankAdapter.oldChooseModulo` is **unchanged and physically called once** on the true full chain for forensic comparison. Stage25 full 46 drop+12 post-stir=58 actual shared-memory writes, immutable DROP46 order and true corrected bowl successor maintained.

CI actual proof:
```text
STAGE_27_PATCH_13_GUARDS_PASS dayPairs=12 cells=72 mismatches=0 oldWrong=16 oldMatches=56 wide=16 boundaries=13 legacyCalls=2 correctedCalls=2 predecessorCalls=2 injectedFailures=3
STAGE_27_PATCH_13_PROPERTIES_PASS shortSizes=256 shortCells=2560 shortMismatches=0 shortOldWrong=1365 shortOldMatches=1195 shortRejected=1402 shortWraps=701 surrogateCases=13926 surrogateRejected=2466 surrogateWide=12628 surrogateWrap=1290 powerCases=10 powerDigits=154 giantWideGaps=2 realPairs=12 varied=64 giant=8 ranks=720 unique=720 histories=804 sharedWrites=46632 streamMismatches=0 fullMismatches=0 fullOldWrong=177 fullOldMatches=627
```
All earlier stages and all 13 intentional reds still pass CI.

## Stage28 work scope

Perform **DISCOVERY14** only, after locating its precise historical error from authoritative contract. Add intentionally uncorrected historical production path, independent tests, its 14th standalone expected-red witness, and full corrected Stage27 preceding route with ownership/reentrancy/fault tests. Only after CI two jobs pass should `LAST_COMPLETED_STAGE` change to 28; next Stage29 must be deferred. Preserve prior status/history/documents.

## Git practice

Always base new tree on **latest live branch tree** (avoid earlier stale-tree loss); optimistic `expected_sha` fast-forward, no force push. Never commit `HANDOFF_*.zip` or user-only handoff artifacts; continuation belongs under `docs/`. User local action not required unless a genuinely unavailable native tool blocks work.
