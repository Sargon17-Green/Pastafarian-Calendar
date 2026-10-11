# टप्पा 17 पूर्ण — Stage 18 साठी handoff

## सुरक्षित व पडताळलेली अवस्था

- Branch: **`TypeScript+मराठी`**, `main` किंवा दुसऱ्या शाखांमध्ये काम करू नका.
- Total 55 stages; `LAST_COMPLETED_STAGE=17`; current stage **17 PATCH 08**, next **18 DISCOVERY 09**, future patch 09 = stage 19 only.
- Stage 17 tested implementation commit `1859d3823fcf51b80ee43a7368235271317bd722`.
- GitHub Actions https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38181219879 — `verify` आणि `stage17-typescript-marathi` दोन्ही PASS.
- Original 55-stage canonical contract चे नियम, frozen `SourceLanguageCatalog`, `CANONICAL_NAMES_LOCK.sha256`, pure TypeScript + Marathi docs/comments, आणि `calendarDateSpaghetti` final Stage 54 पूर्वी unavailable यांचे पालन करा.

## Stage 17 मध्ये नेमके काय झाले

`src/patch08Permutation.ts`: `Patch08PermutationHandler.run(ctx,dropValue)` हे खालील **तीन वेगवेगळे ऐतिहासिक चरण** वापरते:

```text
oneBased    = regularMod(drop - 1, 720) + 1
legacyRank0 = oneBased - 1
order       = oldPermutationUnrank0(legacyRank0)
```

`LegacyPermutationUnrankAdapter.oldPermutationUnrank0` ला प्रत्यक्ष call, `PATCH_08_ONE_BASED_MOD_720`, `PATCH_08_SUBTRACT_ONE_FOR_LEGACY`, `PATCH_08_REAL_OLD_PERMUTATION_UNRANK0` या स्वतंत्र branchTrace घटना आणि प्रत्येक चरणाची metrics. Call per context; परिणामाची 6-element permutation frozen; positive/negative विशाल `bigint` सुरक्षित.

Stage 16 मधील `src/discovery08LegacyPermutation.ts` आणि `test/discovery08Red.ts` अपरिवर्तित आहेत; जुन्या raw-drop `legacyRank0=drop` च्या चुकीची आठवी लाल चाचणी राहिली. याआधीचे सात historical scars व patches जतन.

```text
STAGE_17_PATCH_08_GUARDS_PASS cases=17 shifted=9 rejected=8 mismatches=0
STAGE_17_PATCH_08_PROPERTIES_PASS cases=6209 shifted=720 rejected=5489 mismatches=0 unique=720 seeded=2048 visibleDays=12 visibleCases=552 giantCases=9
```

- 17 boundary ranks: 9 जुने accepted-but-wrong, 8 जुने rejected, 0 corrected errors.
- 3600 wraparound; 2048 seeded signed; 12 days-pairs × 46 normative visible drops = 552; 9 signed giant drops; 6209 corrected comparisons सर्व अचूक.
- 8 deliberately-red archives regression proof independently CI PASS.
- First run `38181165883` मध्ये test-only count 10/7 असा चुकीचा होता; 9/8 केल्यावर `38181219879` PASS. Production calculation changed नाही.

## पुढील Stage 18 — केवळ DISCOVERY 09

मूळ canonical project contract: जुन्या bowl pour code मध्ये सुरुवातीच्या स्थिर bowls 1, 2, 3 साठी चुकीचे pours होतील; **permutation ची positions आणि खऱ्या bowl IDs यात फरक** दुर्लक्षित होतो. या historical legacy implementation व normative test-only reference यांच्यात प्रत्यक्ष mismatches दाखविण्यासाठी नवीन diagnosis, metrics, expected-red script, guard/property regression जोडा.

Stage 19 PATCH 09 साठी भविष्यातील दुरुस्ती chain राखा: `bowlAlias[position]=order[position]`, सर्व bowl reads/writes योग्य alias द्वारे. **Stage 18 मध्ये अजून aliases लावू नका.**

- Stage 17 normalized order helper production मधून वापरता येईल; Stage 18 च्या legacy defect वर early fix लागू करू नका.
- Stage 1–17 सर्व regression व 8 archival red तशाच; ninth historical expected-red जोडून TypeScript typecheck, GitHub Actions `verify` सह पुष्टी.
- Stage 20 in-place bowl contamination, Stage 21 patch, final calendar integration या नंतरच्या चरणांना स्पर्श नको.
- एका प्रत्युत्तरात **एकच stage**. Stage 18 ची CI पूर्ण यशस्वी झाल्यावरच `LAST_COMPLETED_STAGE=18`.
- Next reply सुरू होताना live branch head, `DEVELOPMENT_STAGE.md`, हा handoff आणि contract तपासा; इतर conversations branch वर काम करू शकतात.

स्थानिक वापरकर्त्याची कृती आवश्यक नाही.
