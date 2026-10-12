# टप्पा 20 — DISCOVERY 10: जुन्या in-place bowl stir मधील contamination

## Stage 21 पूर्वी दोष जतन

`src/discovery10LegacyInPlaceStir.ts` मधील `LegacyInPlaceBowlStirAdapter.stirInPlace` हा मूळ चुकीचा helper अजून सहा स्थानांवर `workingBowls[id-1] = SAVE(...)` **तात्काळ** करतो. पुढील स्थानांवरील `workingBowls[prev-1]` आणि `workingBowls[next-1]` हे नुकतेच बदललेले values वाचतात. Stage 19 च्या `patch09Pours` मधून सुरुवातीच्या तीन pours अचूक मिळतात, त्यामुळे या stage मध्ये फक्त in-place state दोष isolate झाला आहे.

वैधतेचा तपास झाल्यावर एका call मध्ये caller चे `b` थेट mutate न करता एक स्वतंत्र working array दिला जातो; **त्याच्या आतली** तात्काळ in-place legacy writes जसाच्या तशा चालतात. `inputBowls` immutable evidence snapshot फक्त caller-ownership साठी; legacy arithmetic मध्ये तिचा वापर नाही. `vaultOld`, `pending`, all reads from snapshot, final simultaneous commit हे पुढच्या **Stage 21 PATCH 10** च्या आधी कोणत्याही source computation मध्ये जोडू नये.

प्रत्येक जुन्या step मधून position, bowlId, prevId, nextId, actual prev/next read values, यापूर्वी लिहिलेली शेजारची ओळ व नव्याने लिहिलेले मूल्य नोंदतो. सहा steps मध्ये 6 immediate writes, 5 contaminated positions व 6 overwritten-neighbor read slots. `MonsterContext` मध्ये branchTrace, metrics, frozen result/steps, fail-before-mutation input validation व स्वतंत्र ownership.

## नियमाधारित oracle

`test/discovery10Reference.ts` हा फक्त tests साठी स्वतंत्र full-six-position reference आहे: `normativeThreePours` आणि `bowlOrderFromDrop`, `SAVE`; त्यात त्या single stir च्या **सुरुवातीच्या सहा bowl values** वरून सर्व सहा outputs तयार होतात. Production `src` मध्ये oracle import नाही. `test/normativeOracle.ts` मधील `applyVisibleDropsToBowls` विरुद्ध 46-step sequence मधील final output ची स्वतंत्र पुष्टी करतो.

## आवश्यक परीक्षण

- `test/discovery10.ts`: 8 boundary witnesses ×6=48 values, अपेक्षित 40 old mismatches व 8 matches. प्रत्येक call मध्ये overwrittenReadSlots=6, contaminatedPositions=5, actual old method mutation, immutable inputs, lifecycle, invalid arrays / bigint / ordinal, trace, metrics.
- `test/discovery10Properties.ts`: सर्व 720 क्रम ×6=4320 comparisons, अपेक्षित 3600 old mismatches आणि 720 जुळणारे first-position values; 12 date-pairs × 46 = 552 real normative visible drops ×6, आणि 12 पूर्ण evolving bowl state sequences ×46; 1024 seeded signed-value cases व 8 giant positive/negative bigint cases. Single drop 2304 calls ×6=13824, historical mismatches 11520, matches 2304; 6 ×2304 overwritten read slots. Full evolving reference `applyVisibleDropsToBowls` शी जुळला पाहिजे; जुना in-place outcome वेगळा राहिला पाहिजे.
- `test/discovery10Red.ts`: `DISCOVERY_10_EXPECTED_RED mismatches=40 matches=8 witnesses=8 positions=48` हा दहावा स्वतंत्र intentional expected-red पुरावा, process nonzero exit.
- Stage 1–19 tests, सर्व नऊ जुने intentionally-red archive tests, TypeScript native typecheck आणि canonical name lock अद्याप तपासले जातील.

सध्याची स्थिती: **GitHub Actions पूर्ण PASS**, तसेच स्वतंत्र intentionally-red इतिहास प्रमाणित. Verified implementation commit `57deea966018d29384ea2ad954e100f7d66a0fb5`, [run 38214265315](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38214265315), `verify` व `stage20-typescript-marathi` jobs SUCCESS; TypeScript typecheck, Stages 1–20 regressions, सर्व दहा historical expected-red scripts व canonical lock PASS.

```text
STAGE_20_DISCOVERY_10_GUARDS_PASS witnesses=8 positions=48 mismatches=40 matches=8 overwrittenReads=48 contaminatedPositions=40
STAGE_20_DISCOVERY_10_PROPERTIES_PASS orders=720 rankCells=4320 rankMismatches=3600 rankMatches=720 cases=2304 cells=13824 mismatches=11520 matches=2304 overwritten=13824 realPairs=12 realDrops=552 realErrors=2760 evolvingPairs=12 evolvingDrops=552 evolvingMismatches=72 seeded=1024 giant=8
DISCOVERY_10_EXPECTED_RED mismatches=40 matches=8 witnesses=8 positions=48
```

आठ boundary witnesses साठी 40 जुन्या divergent values, 8 first-position matches. सर्व 720 order ranks मध्ये 3600 चुकीचे व 720 matches. 552 वास्तविक reference drops वर 2760 जुने divergent values. 12 पूर्णपणे विकसित होणाऱ्या 46-drop दिवस-जोड्यांच्या bowl states मध्ये **72 final divergences (प्रत्येक वेळी सहाही bowls वेगळे)**. Test-only evolving reference हा `applyVisibleDropsToBowls` शी देखील जुळतो. 1024 seeded आणि 8 giant signed cases सह exact bigint प्रमाण.

पहिला CI run `38213861079` test-only दोन TypeScript typing errors मुळे अयशस्वी झाला; test-only readonly instrumentation व independent bigint reference सुस्पष्ट केले. दुसरा `38214091054` मध्ये test instrumentation ची चुकीची seventh-vs-eighth argument index चूक होती; `test/discovery10.ts` मध्ये argument index दुरुस्त केल्यावर `38214265315` पूर्ण PASS. Production `src/discovery10LegacyInPlaceStir.ts` मध्ये या दुरुस्त्यांदरम्यान कोणताही बदल नाही.

**Stage 21 PATCH 10** पूर्वी उत्पादनात `vaultOld` / `pending` shadow writes बसवलेले नाहीत.
