# Stage 26 पूर्ण — Stage 27 PATCH 13 साठी continuation

## Current authoritative status

- Repository `Sargon17-Green/Pastafarian-Calendar`; only `TypeScript+मराठी` branch. Do NOT modify `main` or other branches.
- Canonical 55 stages. **LAST_COMPLETED_STAGE=26**, current **26 DISCOVERY 13**. Next sole stage **27 PATCH 13**; Stage28 DISCOVERY14 must not begin in the same response.
- Verified implementation commit `c024cacdc53556bf8a0e82891f97dd13eb1ea807`; [GitHub Actions run 38246972763](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38246972763) two jobs both SUCCESS (native typecheck, all Stage1–26 regression tests, 13 intentionally-red histories, frozen name lock).
- Start from live branch HEAD, `DEVELOPMENT_STAGE.md`, `docs/STAGE26_DISCOVERY13_VERIFICATION.md`, production `src/discovery13LegacyBiasedModulo.ts`, `src/patch12NextBowl.ts`, independent test-only `test/normativeOracle.ts`, and historical `test/discovery13Red.ts`. No local user action required.

## Stage26 historical defect

Old production method `LegacyBiasedModuloRankAdapter.oldChooseModulo(firstAnswer,N)` is **intentionally wrong**: `1 + ((firstAnswer-1)%N)`. It takes only first answer, ignoring rejection for short sizes and the M-base multi-answer scheme for wide sizes. Keep this method exactly unchanged and ensure Stage27 physically invokes it for archived scar, while computing corrected answer independently.

The full Stage25 corrected bowl successor chain (46 DROP rounds, 12 STIR rounds, **58 historical shared-memory writes**, saved immutable DROP46 permutation, old numeric successor real call) is used by Stage26. Two production `patch01Save` calls calculate exact first answer and direction from final bowls: `first=SAVE((queried+seal+181)^2 +179*next+seal)`; `directionNumber=SAVE((first+seal+194)^2+193*first+197*B6)`; direction +1 for odd, -1 for even. 13 archived expected-red tests remain unchanged.

Independent oracle defines `M=(1<<127)-1`, `answerAt(k)=1+regularMod(first-1+direction*k,M)`:
- Short `1<=N<=M`: accept first `answerAt(k)<=floor(M/N)*N`, return `1+regularMod(accepted-1,N)`.
- Wide `N>M`: minimal k with `M^k>=N`; construct `wide=1+Σ(answerAt(j)-1)*M^j`, accept cyclic ±1 wide candidates under `floor(M^k/N)*N`, return `1+regularMod(acceptedWide-1,N)`.
- Be extremely careful: *synthetic* upward wide streams near high M can require ~M sequential rejection iterations. Stage26 learned to avoid unbounded oracle test vectors. Stage27 must preserve exact semantics without accidental astronomical loops; develop bounded witnesses and/or prove an equivalent efficient skip.

Verified data:
```text
STAGE_26_DISCOVERY_13_GUARDS_PASS dayPairs=12 cells=72 oldWrong=16 oldMatches=56 wideWrong=16 wideSame=0 redWitnesses=3 moduloCalls=2 correctedNextCalls=2 oldNextCalls=2 injectedFailures=2
STAGE_26_DISCOVERY_13_PROPERTIES_PASS analyticalSizes=256 biasedFamilies=255 topRejections=255 directCases=984 directWrong=426 directMatches=558 wideCases=328 wideWrong=326 thresholdWitnesses=3 realPairs=12 varied=64 giant=8 ranks=720 unique=720 histories=804 sharedWrites=46632 streamMismatches=0 oldWrong=177 oldMatches=627
DISCOVERY_13_EXPECTED_RED mismatches=3 matches=0 sizes=2,3,5 first=M
```

## Next one stage — Stage27 PATCH 13

Add a **separate corrected production** rank selector to use Stage26's authentic answer stream, support both short rejection and wide M-base digit selection including wrap, integer N beyond M, and follow all accepted indexing. Preserve the genuine old method call + historical output for side-by-side comparisons; previous 13 intentional red scripts remain expected failures. Test direct synthetic threshold crossing both directions, exhaustive small surrogate mathematical family counts, short M-edge conditions, wide M^k boundaries, 12 daypairs, varied inputs, giant signed bigints, real full 58-write histories, mutation isolation, fault injection, and Stage54 calendar barrier. Test-only oracle never imported by production. No other stages before 27 closes via both CI jobs.

Do not commit any user-only HANDOFF_* archives. Build tree from newest live commit tree (past Stage21 stale-tree incident), optimistic SHA / non-force fast-forward. At closure update status and provide next continuation under `docs/`.
