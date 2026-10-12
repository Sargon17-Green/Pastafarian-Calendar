# Stage 19 पूर्ण — Stage 20 साठी प्रमाणित handoff

## अधिकृत स्थिती

- Repository: `Sargon17-Green/Pastafarian-Calendar`; फक्त branch **`TypeScript+मराठी`**. `main` किंवा दुसऱ्या branch मध्ये push करू नका.
- एकूण 55 टप्पे; **`LAST_COMPLETED_STAGE=19`, PATCH 09**. पुढील एकमेव **Stage 20 — DISCOVERY 10**. Stage 21 PATCH 10 किंवा पुढील काम आगाऊ सुरू करू नये.
- Tested Stage19 implementation commit: `616df1cad4f24a4bd596955759dc1a488cdd1a3d`.
- CI https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38212645315 — `verify` व `stage19-typescript-marathi` दोन्ही SUCCESS; TypeScript native `tsc`, regression Stage 1–19, all 9 archival historical expected-red scripts, frozen canonical name lock PASS.
- Frozen `SourceLanguageCatalog`, `CANONICAL_NAMES_LOCK.sha256`, pure TypeScript implementation, Marathi documentation/comments, independent test-only `test/normativeOracle.ts`. Other language branches, their implementations or fixtures import करू नका.
- `calendarDateSpaghetti` हे Stage 54 पूर्वी जाणूनबुजून `MonsterStageError` देते.

## Stage 19 काय केले

`src/patch09BowlAlias.ts` हे स्वतंत्र patched production code. Historical `src/discovery09LegacyFixedPours.ts` मधील `LegacyFixedBowlPoursAdapter.legacyFixedPours` आणि ninth archival `test/discovery09Red.ts` कोणत्याही रीतीने बदलले नाहीत.

पुरातन legacy helper position 1–3 साठी नेहमी `oldBowls[0..2]` वाचतो. Patch 09 मध्ये:

```text
order = patch08Permutation(c,t,drop).order   // आधीचा Stage17 patch
bowlAlias[0] = 0                              // index 0 sentinel
for position in 1..6:
    bowlAlias[position] = order[position]
    virtualBowls[position] = oldBowls[bowlAlias[position]]
historicalPours = oldLegacyPours(c,t,i,drop,oldBowls,stone)
correctedPours  = oldLegacyPours(c,t,i,drop,virtualBowls,stone)
```

वरील pseudocode 1-based bowl IDs आहे; TypeScript array access `oldBowls[bowlAlias[position]-1]` व virtual view `virtualBowls[position-1]`.

- सहाही position aliases immutable व distinct, legacy helper ला raw input **आणि** corrected aliased view या दोन प्रत्यक्ष calls.
- `LegacyBowlAliasAdapter.installOrderAliases` / `bowlByLegacyPosition` validates six distinct ids, alias indexing, complete bigint bowl arrays; immutable position view.
- `Patch09BowlAliasHandler` calls `patch08Permutation`, tracks trace `PATCH_09_INSTALL_ORDER_ALIASES`, `PATCH_09_VIRTUAL_BOWL_POSITION_READS`, `PATCH_09_REUSE_FIXED_LEGACY_POURS_WITH_ALIASES`; context metrics, preflight validation, no context reuse, immutable input/return snapshots.
- No bowl mixing, no in-place mutations, no `vaultOld` / `pending` writes. Those belong to future stages.

## प्रमाणित QA evidence

```text
STAGE_19_PATCH_09_GUARDS_PASS witnesses=8 cells=24 mismatches=0 historicalWrong=16 historicalMatches=8 aliases=6 originalCalls=2
STAGE_19_PATCH_09_PROPERTIES_PASS cases=3328 cells=9984 mismatches=0 rankOrders=720 rankWrong=1800 rankMatches=360 realPairs=12 realDrops=552 realWrong=1383 realMatches=273 seeded=2048 giant=8
```

- 720 पूर्ण permutation ranks आणि तीन pours; 1,800 historical mismatches/360 accidental matches अजून नोंदले जातात, corrected mismatches शून्य.
- 12 दिवस-जोड्या × 46 normative visible drops = 552, **each computed against initial bowls of that day-pair**, not evolving 46-step bowl mixing. Historical 1383 wrong/273 coincident; corrected zero wrong.
- 2048 deterministic signed-case inputs; 8 extremely large signed bigint cases. एकूण 3328 स्वतंत्र corrected calls ×3 = 9984 cells, 0 mismatches.
- जुन्या `DISCOVERY_01` ते `DISCOVERY_09` या **नऊ intentionally-red** tests अजून nonzero exit देतात. Workflow सर्व नऊ required historical evidence म्हणून तपासते.

## पुढचा एकमेव Stage 20 — DISCOVERY 10

मूळ 55-stage project contract पुन्हा वाचा. Stage 20 मध्ये जुना **in-place bowl contamination** दोष जतन करणे/शोधणे आवश्यक आहे. सर्व छह bowls `B` वर क्रमाने गणना करताना जुन्या stir method ने `B[id]` ताबडतोब mutate केले; पुढील positions च्या वाचनात मागच्या positions चे नव्याने लिहिलेले bowl values येतात. Test-only normative algorithm प्रत्येक pour च्या सुरुवातीच्या snapshot वरून सर्व सहा outputs काढतो.

- `src/discovery10LegacyInPlaceStir.ts` सारखा स्वतंत्र legacy implementation मार्ग, मूळ in-place mutation राखून context/diagnostics/metrics, visible differences दाखवणाऱ्या स्वतंत्र guards/properties/expected-red. Input ownership आणि failure semantics स्पष्ट नोंदवा.
- Stage 19 चा patched pour aliases वापरता येईल; त्यात mutation चालू करू नका. जुन्या `src/discovery09LegacyFixedPours.ts` किंवा Stage19 repair पुनर्लिखित करू नका.
- **Stage 21 PATCH 10 आधी `vaultOld=clone(B)`, `pending=clone(B)`, all reads from vaultOld, all writes into pending, final commit नको.** तो Stage 21 चा अधिकृत सुधारणा मार्ग आहे; Stage 20 मध्ये दोष intentionally कायम.
- All Stage 1–19 regressions and 9 deliberately-red archival tests PASS राहतील; independent 10th expected-red test, full TypeScript typecheck आणि GitHub Actions दोन्ही jobs SUCCESS होईपर्यंत Stage 20 पूर्ण मानू नका.
- एका प्रत्युत्तरात **एकच stage**. Next reply आधी GitHub live HEAD, `DEVELOPMENT_STAGE.md`, canonical contract व handoff तपासा; other chats branch पुढे नेऊ शकतात.

वापरकर्त्याची स्थानिक कृती आवश्यक नाही.
