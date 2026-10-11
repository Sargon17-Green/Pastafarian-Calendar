# टप्पा 18 पूर्ण — Stage 19 साठी HANDOFF

## प्रमाणित स्थिती

- काम फक्त `TypeScript+मराठी` शाखेत; `main` किंवा इतर भाषिक branches बदलू नका.
- 55 पैकी **18 टप्पे पूर्ण**. पुढचा एकमेव टप्पा **Stage 19 — PATCH 09**. Stage 20 DISCOVERY 10 आधी सुरू करू नका.
- Stage 18 tested implementation commit: `6519984eeeb2a255cdb02c0a0ccacbf35d2e4b76`.
- GitHub Actions https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38182044313 — `verify` व `stage18-typescript-marathi` PASS; TypeScript typecheck, Stages 1–18 regressions, सर्व नऊ archival expected-red, `CANONICAL_NAMES_LOCK.sha256` PASS.
- Marathi comments/docs; TypeScript source, स्वतंत्र test-only normative oracle. Frozen source language names जतन करा. `calendarDateSpaghetti` Stage 54 पूर्वी उपलब्ध नाही.

## नववा ऐतिहासिक दोष व पुरावे

`src/discovery09LegacyFixedPours.ts`:
- `LegacyFixedBowlPoursAdapter.legacyFixedPours` तीन pours साठी `oldBowls[0]`, `oldBowls[1]`, `oldBowls[2]` या चुकीच्या स्थिर bowl-ID reads वापरतो; मिळालेला `patch08Permutation` चा correct order फक्त निरीक्षणात आहे.
- `discoverLegacyFixedPours`: context, immutable input bowls/stone snapshots, immutable historical pours, legacy method च्या real invocation चा पुरावा, metrics व branch trace.
- `test/discovery09Reference.ts`: test-only canonical `oldBowls[order[position]-1]` आणि SAVE; production oracle import नाही.

```text
STAGE_18_DISCOVERY_09_GUARDS_PASS witnesses=8 cells=24 mismatches=16 matches=8
STAGE_18_DISCOVERY_09_PROPERTIES_PASS rankOrders=720 rankCells=2160 rankMatches=360 rankMismatches=1800 realPairs=12 realDrops=552 realCells=1656 realMismatches=1383 realMatches=273 giantCases=8 giantCells=24
DISCOVERY_09_EXPECTED_RED mismatches=16 matches=8 witnesses=8 cells=24
```

720 permutations ×3 pours मध्ये 1800 जुने दोष आणि 360 योगायोगाचे जुळणे. 552 canonical visible drops साठी स्वतंत्रपणे प्रत्येक day-pair च्या initial bowls वर निदान केले (संपूर्ण 46-step evolving bowl state नाही); 1383 mismatches. 8 giant signed bigint cases. 9 expected-red CI ने जाणूनबुजून nonzero exit सह PASS केले.

## Stage 19 PATCH 09 — नेमके करायचे काम

1. सर्वप्रथम live GitHub HEAD, `DEVELOPMENT_STAGE.md`, मूळ 55-stage contract आणि हा handoff वाचा; parallel work असू शकते.
2. मूळ `LegacyFixedBowlPoursAdapter.legacyFixedPours` किंवा `test/discovery09Red.ts` दुरुस्त किंवा काढून टाकू **नका**. नवीन स्वतंत्र patched handler बनवा.
3. ऐतिहासिक patch ची अनिवार्य chain: `bowlAlias[position]=order[position]`. सर्व तीन legacy position reads हे alias ने वास्तविक bowl IDs कडे दिग्दर्शित करावेत. मूळ fixed-index helper ची छाया/आवाहन व जुना दोष जतन करा.
4. पोजिशन 1..3 मधील accidental matches आणि mismatches दोन्ही, 720 rank orders, 552 real normative visible drops, signed gigantic integers, lifecycle, input validation, per-call snapshots, exact oracle, zero corrected mismatches यांचा QA.
5. Stages 1–18 सगळे regression आणि 9 deliberately-red archives CI मध्ये कायम. `main` बदलू नका.
6. **Stage 20** च्या in-place bowl contamination आणि **Stage 21** च्या vaultOld/pending write दुरुस्तीस हात घालू नका; Stage 19 मध्ये फक्त bowl-ID alias patch.
7. CI success झाल्यावरच `LAST_COMPLETED_STAGE=19` लिहा; एका प्रतिसादात एकच stage.

पूर्वी CI typecheck सुरुवातीला test-only `discovery09Reference.ts` मुळे दोनदा अपयशी झाला; fixture type सुरक्षित केल्यावर verified run `38182044313` PASS. वापरकर्त्याची स्थानिक कृती आवश्यक नाही.
