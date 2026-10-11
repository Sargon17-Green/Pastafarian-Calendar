# टप्पा 11 पूर्ण — टप्पा 12 साठी हस्तांतरण

कामाची शाखा केवळ `TypeScript+मराठी`. `main` वर काहीही commit करू नका. **एकूण 55 टप्पे; पूर्ण 1–11.** पुढचा फक्त **Stage 12 — DISCOVERY 06**. तिसऱ्या बाजूच्या भाषा-शाखांतील code किंवा fixtures आयात करू नका. मराठी दस्तऐवजीकरण व शुद्ध TypeScript स्रोत कायम ठेवा.

## ऐतिहासिक सुधारणा-नकाशा

- Stage 2/3: `oldRemainder` आणि `patch01Save`.
- Stage 4/5: `oldDayTag` आणि `patch02DayTags`, foundation scar कायम.
- Stage 6/7: `oldDistance` आणि `patch03Distance`, शेवटचा `+1`.
- Stage 8/9: `mutateStonesWrong` ची क्रमिक in-place जुनी पद्धत; `patch04Stones` मध्ये old snapshot, clone वर **खरा** जुना call, `legacyGarbage` आणि old-only पाच corrected values.
- Stage 10/11: `LegacyBackwardHiddenAdapter.storeBackward` सात hidden थेंब `hidden7..hidden1` ठेवतो. `oldHiddenAt` अजून मुद्दाम `stored[k-1]` वाचतो. `src/patch05Hidden.ts` मधील corrected reader **`stored[7-k]`** वाचतो; मूळ उलट storage अजिबात बदलत नाही. दोन्ही वाचक सातही वेळा चालून `legacyReads` व `correctedReads` निरीक्षणात राहतात.
- पाचही historical `EXPECTED_RED` प्रक्रिया मुद्दाम अपयशी; CI त्यांचे निश्चित markers तपासतो. `calendarDateSpaghetti` Stage 54 आधी `MonsterStageError` देत राहतो.

## Stage 11 चे प्रत्यक्ष प्रमाण

- Implementation commit: `4892dae7211ac4d2a70ca5aa7ab9953fe5ea1486`
- Verified GitHub Actions: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38163510684 — `verify` आणि `stage11-typescript-marathi` PASS.
- `STAGE_11_PATCH_05_ORACLE_PASS cases=105 slots=735 legacyDifferences=630 legacyMatches=105 mismatches=0`.
- `STAGE_11_PATCH_05_PROPERTIES_PASS cases=2062 slots=14434 legacyDifferences=12330 legacyMatches=2104`.
- Native `npm run typecheck`, पूर्ण `npm test`, आणि 5 archival expected-red checks PASS.
- Sparse सात-स्थान input प्रथम CI मध्ये पकडला; corrected reader मध्ये index-wise पडताळणी आणून दुसऱ्या CI run मध्ये PASS. जुन्या Stage 10 reader मध्ये बदल नाही.
- तपशील: `docs/STAGE11_PATCH05_VERIFICATION.md`.

## Stage 12 — DISCOVERY 06, फक्त दोषाचा शोध

मूळ ऐतिहासिक `legacyPrior(dropStore,i,back)` हा helper केवळ `dropStore[i-back]` वाचतो; `i-back` शून्य किंवा ऋण असल्यास त्याला मागील सात hidden थेंबांचा इतिहास समजत नाही. याला क्रमाने जुनी साक्ष म्हणून स्वतंत्र legacy adapter/handler आणि intentional `DISCOVERY_06_EXPECTED_RED` test जोडा. `test/normativeOracle.ts` मधील `buildHiddenDrops` / `buildVisibleDrops` semantics विरुद्ध नियोजनबद्ध boundary/test-only पुरावे तपासा. `Stage 13 PATCH 06` मध्येच hidden slot ची सुधारणा करा: `slot = i-back`, `slot >= 1` असेल तेव्हाच legacy path; अन्यथा `hiddenK=1-slot` आणि Stage 11 corrected `7-k` मार्ग. Stage 12 मध्ये ही सुधारणा लागू करू **नका**.

सुरुवातीला ताजे branch HEAD, `DEVELOPMENT_STAGE.md`, `HANDOFF_STAGE_11.md`, मूळ 55-step करार तपासा. Native GitHub CI यशस्वी होईपर्यंत Stage 12 पूर्ण नोंदवू नका. Stage 1–11 regressions आणि पाच expected-red पुरावे प्रत्येक commit ला जतन करा. फक्त त्याच शाखेत काम करा.
