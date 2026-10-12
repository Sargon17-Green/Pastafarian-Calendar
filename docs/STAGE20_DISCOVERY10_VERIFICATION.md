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

सध्याची स्थिती: **GitHub Actions verification प्रलंबित.** Stage 20 पूर्ण म्हणून नोंद फक्त actual CI SUCCESS नंतर; Stage 21 चे source code नाही.
