# टप्पा 12/55 — DISCOVERY 06 पडताळणी

## सहावा ऐतिहासिक दोष

`legacyPrior(dropStore,i,back)` हा मूळ visible इतिहास helper **थेट** `dropStore[i-back]` वाचतो. Visible drops `1..46` क्रमांकांनी ठेवलेले असतात. `slot=i-back` शून्य किंवा ऋण असल्यावर खरा मागील थेंब hidden history मधील `hidden(1-slot)` असतो, पण जुना helper तो कधीच शोधत नाही. Stage 12 मध्ये **हेच जुने दोषयुक्त expression** ठेवले; hidden fallback किंवा Stage 13 चा सुधारित reader लागू केला नाही.

`src/discovery06LegacyPrior.ts` मध्ये `LegacyVisiblePriorAdapter.legacyPrior`, `Discovery06PriorHandler`, आणि सार्वजनिक `discoverLegacyPrior` आहेत. `legacyValue:bigint|undefined`, `legacyFound`, `historySlot`, frozen visible-store snapshot, स्वतंत्र `MonsterContext`, history trace, metrics व lifecycle guards नोंदवले आहेत. Invalid index/back/context किंवा missing positive visible slot नाकारले जातात. जुन्या गणनेला योग्य hidden value जोडून त्याचा अर्थ बदललेला नाही.

Stage 11 मधील `patch05HiddenDrops` आणि जुना `LegacyBackwardHiddenAdapter` बदललेले नाहीत. Test-only `buildHiddenDrops` / `buildVisibleDrops` उत्पादनात आयात होत नाहीत.

## Boundary साक्ष

`i` म्हणजे सध्याचा visible drop, `back` म्हणजे मागील 1, 3 किंवा 7 स्थानांचे अंतर; `slot=i-back`.

| उदाहरण | slot | जुन्या reader चे मूल्य | नियमाधारित इतिहास |
|---|---:|---|---|
| i=1, back=1 | 0 | undefined | hidden1 |
| i=1, back=3 | -2 | undefined | hidden3 |
| i=1, back=7 | -6 | undefined | hidden7 |
| i=7, back=7 | 0 | undefined | hidden1 |
| i=2, back=1 | 1 | visible1 | visible1 |
| i=8, back=7 | 1 | visible1 | visible1 |

15 स्वतंत्र boundary witnesses मध्ये **11 mismatches / 4 matches**. `test/discovery06Red.ts` मुद्दाम `DISCOVERY_06_EXPECTED_RED mismatches=11 matches=4` सह nonzero exit देतो.

## पूर्ण oracle आणि मालकी तपासणी

16 स्वतंत्र दिवस-जोड्यांसाठी नियमाधारित `buildHiddenDrops`, `buildVisibleDrops` वापरून 46 visible drops × 3 history distances × 16 दिवस-जोड्या = **2,208** helper calls तपासले.

- Hidden/zero/negative slots: **176** missing historical values (11 प्रति दिवस-जोड).
- Visible positive slots: **2,032** exact historical matches (127 प्रति दिवस-जोड).
- 16,384-bit bigint visible values; context व array isolation; immutable observation; invalid index/back; sparse positive history व already-used context ची guards.
- Stage 01–11 regression markers अखंड; सहा historical expected-red tests CI मध्ये अपेक्षित failure सह तपासले.

## GitHub Actions

- Tested implementation commit: `a727c9af88a3d576653d8db104c2a69fdb5c04eb`
- Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38165814846
- `verify` — PASS; `stage12-typescript-marathi` — PASS; TypeScript typecheck — PASS.
- `STAGE_12_DISCOVERY_06_GUARDS_PASS mismatches=11 matches=4 hidden=11 visible=4`
- `STAGE_12_DISCOVERY_06_PROPERTIES_PASS days=16 cases=2208 hiddenMisses=176 visibleMatches=2032`
- `DISCOVERY_01_EXPECTED_RED` ते `DISCOVERY_06_EXPECTED_RED` — सहाही archival proofs PASS.

## पुढे — Stage 13 PATCH 06

आधी `slot=i-back` मोजावा; `slot>=1` असेल तेव्हाच जुनी `legacyPrior` call करावी. `slot<=0` असेल तर `hiddenK=1-slot`, आणि उलट hidden storage मध्ये Stage 11 चा corrected zero-based index `7-hiddenK` वापरावा. Stage 12 चा `legacyPrior` आणि त्याचा expected-red पुरावा जसेच्या तसे ठेवावेत. Stage 13 चा patch अजून येथे लागू नाही. `calendarDateSpaghetti` अंतिम Stage 54 पर्यंत unavailable आहे.
