# टप्पा 7/55 — PATCH 03 पडताळणी

## नियमाधारित अपेक्षा आणि ऐतिहासिक दोष

`calculationDay=c`, `targetDay=t`, `F=-15055671`.

`src/discovery03LegacyDistance.ts` मधील Stage 6 चा ऐतिहासिक दोष बदललेला नाही:

```text
oldDistance(c,t) = abs(patchedDayTag(c) - patchedDayTag(t))
```

नियमाधारित अंतर:

```text
chronological = abs(t - c)
distance      = chronological + 1
```

Stage 7 च्या `src/patch03Distance.ts` मध्ये ऐतिहासिक क्रम जतन केला आहे:

```text
legacy = oldDistance(c,t)
chronological = abs(t-c)
if legacy != chronological:
    legacy = chronological
distance = legacy+1
```

त्यामुळे `legacyDistance`, `chronologicalDistance`, `correctedDistanceBeforeOne`, `legacyOverridden` आणि अंतिम `distance` स्वतंत्रपणे पाहता येतात. गणना `bigint` वापरते; `Number` rounding किंवा wraparound नाही.

## चाचणी-सीमा

- 5 ऐतिहासिक साक्षी, 13×13 = 169 पाया-दिवसाजवळच्या जोड्या, 45 मोठे/सीमा-जोड, 1024 निश्चित-बीजाच्या 512-bit जोड्या: **1243** जोड्या
- **1214** आवश्यक historical overrides, **29** legacy-preserved मार्ग; नियमाधारित oracle शी **0** फरक
- 4096 आणि 16384-bit अंतर, समदिवसाचा परिणाम 1, सममिती व समान दिनांतरावरील invariance
- स्वतंत्र context/metrics/branchTrace, अपवाद, न वापरलेला/आधी वापरलेला context, अवैध bigint
- Stage 6 `Discovery03DistanceHandler` ला पडताळलेले lifecycle आणि पुन्हा-आवाहन प्रतिबंध जोडला; त्याचे `oldDistance` गणित अजिबात बदलले नाही
- Stage 01–06 च्या सर्व regressions यशस्वी; Stage 02/04/06 च्या तीन historical `EXPECTED_RED` चाचण्या स्वतंत्रपणे अपेक्षित failure सहित जतन

## GitHub Actions पुरावा

- Tested commit: `27f3d682b1ea40a5751af1fabefc092ab03f1b68`
- Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38156511209
- `verify` (Canonical Names Lock): PASS
- `stage07-typescript-marathi` (Node 22, TypeScript typecheck, full regression suite, three historical expected-red checks): PASS
- `STAGE_06_DISCOVERY_03_LIFECYCLE_PASS`
- `STAGE_07_PATCH_03_PASS pairs=1243 overridden=1214 preserved=29 mismatches=0`

## सीमा आणि पुढील काम

या टप्प्यात `calendarDateSpaghetti` अजून Stage 54 पूर्वीचे `MonsterStageError` देतो. पुढील टप्पा 8 — फक्त DISCOVERY 04. मूळ ऐतिहासिक करारातील पुढील दोष म्हणजे `mutateStonesWrong` ने पाच दगडांचे मूल्य sequential in-place बदलणे; नियमाधारित नवे मूल्य जुन्या snapshot वरून मोजायचे असते. पुढील Stage 8 मध्ये फक्त सदोष legacy path आणि अपेक्षित लाल पुरावा तयार करावा; त्याचे snapshot+clone सुधारणा Stage 9 पर्यंत करू नये. इतर भाषा/अंमलबजावणीतील artifacts वापरू नयेत. `SourceLanguageCatalog` अपरिवर्तित ठेवावा.
