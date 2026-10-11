# टप्पा 10 पूर्ण — टप्पा 11 साठी हस्तांतरण

केवळ `TypeScript+मराठी` शाखेत काम सुरू ठेवा. मुख्य `main` शाखा बदलू नका. प्रकल्पात 55 टप्पे आहेत; पडताळलेले पूर्ण **1–10**. पुढे **Stage 11 — PATCH 05**; Stage 12 च्या नव्या दोषाचा शोध आताच नको.

## पूर्वीच्या दोषांचे जतन

- Stage 2/3: `oldRemainder`, `patch01Save`.
- Stage 4/5: `oldDayTag`, `patch02DayTags`, foundation scar.
- Stage 6/7: `oldDistance`, `patch03Distance` + 1.
- Stage 8/9: in-place `mutateStonesWrong`; `patch04Stones` old snapshot, **खरा legacy call clone वर**, `legacyGarbage`, पाच corrected values.
- Stage 10: `src/discovery05LegacyHidden.ts` मधील storage `hidden7,hidden6,...,hidden1`; `LegacyBackwardHiddenAdapter.oldHiddenAt(stored,k)` जुने चुकीचे `stored[k-1]` वापरते. `discoverLegacyHiddenStorage` स्वतंत्र context मध्ये हा दोष नोंदवते.
- पाच historical `EXPECTED_RED` चाचण्या वेगळ्या ठेवाव्यात. Stage 54 चा `calendarDateSpaghetti` अजून `MonsterStageError` देत असावा.

## Stage 10 प्रत्यक्ष पुरावा

- Tested SHA: `1fa1054a2ba4dbd3106baf9458657614c26419ca`
- CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38160880004 — दोन्ही jobs PASS
- 9 normative oracle दिवस-जोड्या: 54 mismatches / 9 matches
- 1,030 property cases आणि 7,210 slots: 6,168 mismatches / 1,042 matches
- `DISCOVERY_05_EXPECTED_RED mismatches=6 matches=1`; पाचही archive reds retained
- Verification: `docs/STAGE10_DISCOVERY05_VERIFICATION.md`.

## Stage 11 PATCH 05 ची तंतोतंत जबाबदारी

सात hidden थेंबांचा **उलटा storage** अपरिवर्तित ठेवा. नवीन सुधारित वाचकाने `hidden k` साठी 1-based स्थान `8-k`, म्हणजे TypeScript zero-based array index **`7-k`**, वाचावे. `LegacyBackwardHiddenAdapter.storeBackward` आणि `oldHiddenAt` मध्ये दोष जतन राहू द्या; नवीन corrected API व निरीक्षण वेगळे जोडा. Actual old reader call चा ऐतिहासिक पुरावा आणि corrected सर्व सात थेंबांची oracle तुलना स्वतंत्रपणे तपासा. Validation, lifecycle, no alias, BigInt, 1..7 bounds, regression आणि अपेक्षित 5 archived reds पुष्टी करा. टप्पा 11 native CI PASS नंतरच पूर्ण घोषित करा.

Stage 12 ची नंतरची ऐतिहासिक चूक `legacyPrior` ने hidden/negative slots न समजणे; Stage 11 मध्ये तिची दुरुस्ती करू नका. `SourceLanguageCatalog` SHA लॉक आणि natural-language मराठी docs जतन करा.
