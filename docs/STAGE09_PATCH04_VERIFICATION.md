# टप्पा 9/55 — PATCH 04: पडताळणी आणि इतिहास

## व्याख्या

टप्पा 8 मधील `LegacySequentialStoneAdapter.mutateStonesWrong(index, S, c, t)` ही प्रत्यक्ष in-place पाच-दगडी mutation जशीच्या तशी जतन आहे. टप्पा 9 मधील स्वतंत्र `patch04Stones(c,t,index,stone)` या चार गोष्टी याच क्रमाने करतो:

1. बाह्य `stone` न बदलता `old` snapshot जतन करतो.
2. `old` ची स्वतंत्र mutable `clone` तयार करतो.
3. जुने `mutateStonesWrong` **खरेच clone वर चालवतो** आणि मिळालेले पाच `legacyGarbage` मूल्य जतन करतो.
4. सर्व पाच नवीन दगड **केवळ `old` मधील मूल्ये** वापरून स्वतंत्रपणे पुन्हा मोजतो. जुने mutation किंवा त्याचे आवाहन हटवलेले नाही.

```text
new.w = SAVE(old.w*old.w +  3*old.b + i)
new.b = SAVE(old.b*old.b +  5*old.s + old.w)
new.s = SAVE(old.s*old.s +  7*old.m + old.b)
new.m = SAVE(old.m*old.m + 11*old.r + old.s)
new.r = SAVE(old.r*old.r + 13*old.w + old.m)
```

उत्पादनातील `SAVE` आधीच्या `patch01Save` वरच अवलंबून आहे; `test/normativeOracle.ts` फक्त चाचणी कोडमध्येच वापरला जातो. प्रत्येक आवाहनाचा `MonsterContext`, `branchTrace` आणि metrics स्वतंत्र असतात. `legacyGarbage` आणि `correctedStone` immutable आहेत.

## ठोस प्रारंभ-साक्ष

| दगड | `old` (i=1) | `legacyGarbage` (i=2) | `correctedStone` (i=2) |
|---|---:|---:|---:|
| w | 17 | 378 | 378 |
| b | 29 | 1434 | 1073 |
| s | 43 | 3780 | 2375 |
| m | 71 | 9932 | 6195 |
| r | 101 | 25047 | 10493 |

टप्पा 8 चे `DISCOVERY_04_EXPECTED_RED mismatches=4 matches=1` अजून हेतुपुरस्सर अपयशी आहे; Stage 9 च्या स्वतंत्र दुरुस्तीमध्ये शून्य oracle-मिसमॅच मिळाले आहेत.

## अंमलबजावणी आणि तपासणी

- `src/patch04Stones.ts`: `Patch04StoneHandler`, सार्वजनिक `patch04Stones`, खऱ्या legacy call वरून `legacyGarbage`, पाच snapshot-derived योग्य मूल्ये, `overwrittenCells`
- `test/patch04.ts`: 45 पायऱ्या, 1024 निश्चित-बीजाची जोडणी, जास्तीतजास्त 16,384-bit magnitude, ऋण/शून्य/`M` सीमा, input/instance/context isolation, lifecycle, argument validation, आधीच्या PATCH 01–03 regressions
- `test/patch04Metamorphic.ts`: प्रत्येकी दगडाला `M` चे गुणक जोडले तरी `SAVE` परिणाम आणि जुने garbage स्थिर राहतात; जुनी पद्धत थेट चालवून `legacyGarbage` स्वतंत्ररीत्या पडताळले जाते
- `test/discovery04Red.ts` आणि आधीच्या तीन expected-red चाचण्या जसाच्या तशा आहेत
- `SourceLanguageCatalog`, `CANONICAL_NAMES_LOCK.sha256` आणि `main` बदललेले नाहीत; `calendarDateSpaghetti` अजून अंतिम Stage 54 पूर्वीचे `MonsterStageError` देते

## प्रत्यक्ष GitHub Actions पुरावा

- तपासलेला commit: `e4581720a00c09ec1f7a16ff1fb70d0c05879a6e`
- Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38159106148
- दोन्ही jobs, `verify` आणि `stage09-typescript-marathi`: **PASS**
- TypeScript typecheck: **PASS**
- Stages 01–08 regression guards: **PASS**
- `STAGE_09_PATCH_04_PASS cases=1076 cells=5380 legacyCalls=1076 overwritten=4304 mismatches=0`
- `STAGE_09_PATCH_04_METAMORPHIC_PASS comparisons=301 cells=1505 historicalDifferences=1204`
- चार स्वतंत्र historical expected-red प्रक्रिया CI ने अपेक्षित nonzero exit आणि अचूक पुरावा-marker सहित स्वीकारल्या

## पुढील टप्पा 10 — DISCOVERY 05

करारातील पुढील ऐतिहासिक दोष म्हणजे गुप्त थेंब साठवण्याचा उलटा क्रम: `hidden7,hidden6,...,hidden1`. पुढील Stage 10 मध्ये **फक्त** जुना उलट साठवण-मार्ग आणि त्याचा expected-red पुरावा आणायचा. `hidden k` ला index `8-k` ने वाचणारा PATCH 05 नियम हा **Stage 11** साठी आहे; Stage 10 मध्ये array सरळ करणे किंवा दुरुस्ती लागू करणे निषिद्ध आहे. पुढील कार्यापूर्वी मूळ 55-टप्प्यांचा करार पुन्हा वाचावा.
