# Stage 12 पूर्ण — Stage 13 साठी हस्तांतरण

फक्त `TypeScript+मराठी` शाखा वापरा. `main` बदलू नका. **55 पैकी 12 टप्पे पूर्ण**, पुढचा एकटाच टप्पा 13 — **PATCH 06**. इतर भाषांतील अंमलबजावणी/fixtures आयात करू नका. वापरकर्त्याशी संवाद हिब्रूमध्ये; TypeScript comments व दस्तऐवज मराठीत.

## आधीच्या कामातील बंधने

1. Stage 2/3: ऐतिहासिक regular remainder आणि `patch01Save`.
2. Stage 4/5: ऐतिहासिक `oldDayTag` आणि `patch02DayTags`, foundation scar.
3. Stage 6/7: ऐतिहासिक `oldDistance` आणि `patch03Distance`, +1.
4. Stage 8/9: जुनी in-place `mutateStonesWrong`; `patch04Stones` मध्ये old snapshot, खरा legacy call clone वर, `legacyGarbage`, old-only पाच corrected values.
5. Stage 10/11: `hidden7..hidden1` हा जुना backward storage कायम; `oldHiddenAt(stored,k)` चुकीचा `k-1` index वापरतो; `patch05HiddenDrops` corrected `7-k` वापरतो.
6. Stage 12: `LegacyVisiblePriorAdapter.legacyPrior(dropStore,i,back)` जुने `dropStore[i-back]` expression थेट वापरतो. 0/ऋण slots वर `undefined` येतो; hidden थेंबाकडे जाणारा fallback **नाही**. `discoverLegacyPrior` हा निदान मार्ग status, branchTrace, input clone आणि metrics सहित आहे.
7. सर्व 6 `DISCOVERY_XX_EXPECTED_RED` पुरावे स्वतंत्र ठेवायचे. `calendarDateSpaghetti` Stage 54 आधी `MonsterStageError` देईल. Frozen `SourceLanguageCatalog` आणि SHA lock बदलू नका.

## Stage 12 प्रत्यक्ष पुरावा

- Tested commit `a727c9af88a3d576653d8db104c2a69fdb5c04eb`
- CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38165814846 — दोन्ही jobs PASS.
- `STAGE_12_DISCOVERY_06_GUARDS_PASS mismatches=11 matches=4 hidden=11 visible=4`
- `STAGE_12_DISCOVERY_06_PROPERTIES_PASS days=16 cases=2208 hiddenMisses=176 visibleMatches=2032`
- `DISCOVERY_06_EXPECTED_RED mismatches=11 matches=4` ही सहावी intentionally red साक्ष.
- पडताळणी `docs/STAGE12_DISCOVERY06_VERIFICATION.md`.

## पुढील Stage 13 — PATCH 06

नवीन स्वतंत्र handler/API तयार करा, पण जुना helper किंवा Stage 12 red बदलू नका. `slot=i-back`:

- `slot>=1`: **जुनी `legacyPrior(dropStore,i,back)` प्रत्यक्ष वापरा**.
- `slot<=0`: `hiddenK=1-slot` ही योग्य hidden टप्प्याची संख्या. Stage 11 मध्ये जतन केलेल्या backward storage मध्ये `hiddenK` साठी zero-based `7-hiddenK` म्हणजे 1-based `8-hiddenK` वापरा. Storage उलटवून सरळ करू नका; hidden history व visible इतिहास यांच्या data ownership स्वतंत्र ठेवा.
- Boundary `i=1..8`, `back=1,3,7`, complete real oracle visible sequence, far +/- bigint days, real old branch calls, immutable output, lifecycle/invalid inputs आणि सहा archival reds यांचा पुरावा द्या.
- Stage 14 — DISCOVERY 07 / grind table indexing — अकाली सुरू करू नका.

प्रत्येक कामाच्या सुरुवातीला branch HEAD, `DEVELOPMENT_STAGE.md`, मूळ 55-stage contract आणि हा handoff वाचा; CI हिरवा झाल्यावरच Stage 13 पूर्ण नोंदवा.
