# Stage 21 पूर्ण — Stage 22 DISCOVERY 11 साठी HANDOFF

## अधिकृत पूर्णत्व

- Repository `Sargon17-Green/Pastafarian-Calendar`; **फक्त `TypeScript+मराठी`** या branch मध्ये पुढे चालू ठेवा. `main` किंवा इतर language branches बदलू नका.
- Total 55 stages. शेवटचा पूर्ण टप्पा **21 — PATCH 10**. पुढचा **22 — DISCOVERY 11**. Stage23 PATCH 11 आगाऊ अंमलात आणू नये. प्रत्येक user response मध्ये जास्तीत जास्त **एकच stage**.
- Tested implementation commit `5010a3c4af0d875e4195e1c8176557943531743f`.
- GitHub Actions [run 38228198853](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38228198853): `verify` आणि `stage21-typescript-marathi` **SUCCESS**, native TypeScript `tsc`, Stage 1–21 regression suite, all 10 independent archival expected-red scripts and frozen canonical names lock pass.
- Frozen `SourceLanguageCatalog` / `CANONICAL_NAMES_LOCK.sha256`; independent pure TypeScript/Marathi implementation, no cross-language code/data copying, no oracle imports into production. `calendarDateSpaghetti` Stage54 पूर्वी `MonsterStageError` देते.

## Stage21 मध्ये केलेले तंतोतंत बदल

`src/patch10SnapshotStir.ts`:
- `Patch10ShadowBowlAdapter.stage` मध्ये `vaultOld=[...initialBowls]` व `pending=[...initialBowls]` स्वतंत्र clones.
- सहा positions वर `currentRead`, `previousRead`, `nextRead` **फक्त vaultOld मधून**, Stage19 corrected pours सहित. प्रत्येक result `pending[bowlId-1]` वर. सगळे सहा steps तयार झाल्यावरच `commit` मध्ये सहा bowl IDs चे परिणाम handler-owned destination वर लिखित.
- `Patch10SnapshotStirHandler` जुन्या `LegacyInPlaceBowlStirAdapter.stirInPlace` ला **एक खरी call** स्वतंत्र working clone वर करून historical `historicalBowls` व `historicalSteps` जतन करतो. जुन्या helper, `src/discovery10LegacyInPlaceStir.ts`, `test/discovery10Red.ts` बदललेले नाहीत; repaired path historical helper च्या outputs वर आधारित नाही.
- Frozen `originalBowls`, `inputStone`, `vaultOld`, `pending`, `correctedBowls`, all old/new step traces; separate context metrics for clones, vault reads, pending writes, six final committed writes.
- Stage 21 optional `afterPendingWrite(position)` failure-injection constructor hook वर 1..6 कोणत्याही position नंतर exception येऊ शकतो, पण **बाहेरील input किंवा MonsterContext बदलत नाही**; deterministic retry succeeds. Node22 strip-only runtime compatibility: ordinary class member and constructor assignment, **TypeScript constructor parameter property वापरू नये**.

## CI मधील स्थिर पुरावे

```text
STAGE_21_PATCH_10_GUARDS_PASS witnesses=8 cells=48 mismatches=0 historicWrong=40 historicMatches=8 vaultReads=6 pendingWrites=6 committedWrites=6 injectedFailures=6 legacyCalls=1
STAGE_21_PATCH_10_PROPERTIES_PASS orders=720 orderWrong=3600 orderMatches=720 cases=2304 cells=13824 mismatches=0 oldWrong=11520 oldMatches=2304 vaultReads=13824 pendingWrites=13824 committedWrites=13824 realPairs=12 realDrops=552 evolvingPairs=12 evolvingDrops=552 evolvingMismatches=0 historicalFinalMismatches=72 seeded=1024 giant=8
```

- 720 complete permutations; 2304 corrected single-drop cases ×6 bowls =13824, **0 corrected mismatches**; 11520 old wrong historical comparisons, 2304 coincidental matches retained.
- 12 actual day-pairs ×46 canonical visible drops =552; 12 full evolving 46-drop sequences match `test/normativeOracle.ts:applyVisibleDropsToBowls` at **every step** and on all final bowls. Original in-place history retains 72 wrong final bowl outputs.
- Six injected faults prove no partial external mutation; ten deliberately-red archives independent expected nonzero exits.
- There were two integration-only fixes after first Stage21 commit: initial Git tree used the earlier Stage19 base, unintentionally omitting Stage20 files; restored **all Stage20 sources/tests and Stage21 additions together** at commit `f601004...`. Then Node22 strip-only rejected TypeScript constructor parameter property, fixed in `5010a3c...`. Both jobs SUCCESS only after these fixes. **Always base next Git tree on the live Stage21 closing commit, not historic parent tree.**

## Stage22 — पुढील एकमेव काम: DISCOVERY 11

मूळ 55-stage contract व Stage21/20 handoffs वाचल्यानंतरच सुरू करा. Stage22 दोष: सामान्य permutation-order memory सर्व 46 visible-drop mixing rounds नंतरचे `orderAtDrop46` **कायम ठेवत नाही**. नंतरच्या **12 post-stir rounds** मध्ये तोच general `order` memory पुन्हा लिहिला जातो; एकूण 46+12=**58 writes**. जुन्या query path ने overwritten general memory मधून (साधारण शेवटच्या `STIR_12` मधील order) उत्तर घेतल्याने कॅननमध्ये अपेक्षित **drop 46 permutation** हरवते. या stage मध्ये अजून कोठेही स्वतंत्र immutable `orderAt46` latch नाही.

- Stage22 मध्ये historical **overwritable** general order memory, real 46-round bowl calculations based on Stage19/Stage21 corrected paths, 12 post-stirs, 58 actual writes, final old-memory query आणि test-only normative drop46 reference यांचा स्वतंत्र diagnosis करा. Canonical full 46-drop bowl results आणि 12-stir final bowls जतन करा; **Stage21 correction कधीही पुन्हा in-place दोषात ढकलू नका**.
- स्वतंत्र historical expected-red witnesses (तर्कतः positions **1, 2, 6**; मूल contract मधील नेमके witnesses पुन्हा सत्यापित करावेत), deterministic properties, observed write ledger, isolation, TypeScript native CI व **अकरावा** archival expected-red. जुने दहा archive scripts unchanged.
- **Stage23 PATCH 11** मध्येच `orderAt46Latch = clone(order)` ही once-after-drop46 स्वतंत्र single-write प्रत तयार होईल आणि `queryOrder` फक्त latch मधून वाचेल. Stage22 मध्ये latch बनवू नका, 58 overwrites सुधारणार नाहीत.
- Stage24 future next-bowl rule किंवा इतर defects, Stage54 integration अजून नाही. एक stage per reply; GitHub Actions दोन्ही jobs PASS व historical intentionally-red proof नंतरच `LAST_COMPLETED_STAGE=22`.
- नव्या प्रत्युत्तराच्या सुरुवातीस live branch HEAD, `DEVELOPMENT_STAGE.md`, `HANDOFF_STAGE_21.md`, original normative 55-stage contract आणि CI तपासा. Concurrent editing असल्यास optimistic SHA lock. स्थानिक user action नाही.
