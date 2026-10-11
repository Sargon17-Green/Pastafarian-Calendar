# टप्पा 8/55 — DISCOVERY 04 पडताळणी

## ऐतिहासिक दोषाची नेमकी व्याख्या

पाच दगडांचा प्रारंभिक संच `(w,b,s,m,r)=(17,29,43,71,101)`. पुढील प्रत्येक `i=2..46` टप्प्यावर जुनी `mutateStonesWrong` क्रिया इनपुट यादी **in-place** बदलते आणि नव्याने बनलेली मूल्ये पुढील गणनेत लगेच वापरते:

```text
S.w = SAVE(S.w*S.w +  3*S.b + i)
S.b = SAVE(S.b*S.b +  5*S.s + S.w)
S.s = SAVE(S.s*S.s +  7*S.m + S.b)
S.m = SAVE(S.m*S.m + 11*S.r + S.s)
S.r = SAVE(S.r*S.r + 13*S.w + S.m)
```

`SAVE` स्वतंत्र Stage 3 मधील `patch01Save` API वरूनच घेतले आहे. मूळ Stage 1 चा नियमाधारित, केवळ चाचणीसाठी असलेला `test/normativeOracle.ts` मात्र नवीन पाचही मूल्ये जुन्या एकाच `old` यादीतून स्वतंत्रपणे काढतो. त्यासाठी Stage 8 उत्पादन-कोडने oracle आयात केलेला नाही.

| दगड | i=2 मधील जुना क्रमिक परिणाम | नियमाधारित एकाच snapshot चा परिणाम | |
|---|---:|---:|---|
| w | 378 | 378 | MATCH |
| b | 1434 | 1073 | MISMATCH |
| s | 3780 | 2375 | MISMATCH |
| m | 9932 | 6195 | MISMATCH |
| r | 25047 | 10493 | MISMATCH |

म्हणून नेमके `4 mismatches / 1 match` ही इतिहासातील अपेक्षित लाल साक्ष आहे.

## उत्पादनातील बदल

- `src/discovery04LegacyStones.ts`: `LegacySequentialStoneAdapter.mutateStonesWrong` ही प्रत्यक्ष in-place ऐतिहासिक पद्धत
- `Discovery04StoneHandler` आणि `discoverLegacyStoneMutation`: स्वतंत्र प्रत, मूलभूत पडताळणी, branch trace, निरीक्षणीय metrics, immutable result
- पूर्वीच्या Stage 1–7 मार्गांचे गणित बदलले नाही; `PATCH 04` अजून अस्तित्वात नाही

## पडताळणी

- Commit: `0d765f251e1ecf976d461e1180d7dc54f9361b05`
- GitHub Actions: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38157981487
- `verify` — canonical names lock: PASS
- `stage08-typescript-marathi` — TypeScript typecheck, सर्व Stage 1–8 guards: PASS
- `STAGE_08_DISCOVERY_04_GUARDS_PASS mismatches=4 matches=1 divergentSteps=45`
- `STAGE_08_DISCOVERY_04_PROPERTIES_PASS cases=516 values=2580`
- `test:discovery04:red` — जाणूनबुजून exit 1 आणि `DISCOVERY_04_EXPECTED_RED mismatches=4 matches=1` यांची CI मध्ये पुष्टी
- Stage 2, 4 आणि 6 मधील आधीच्या तीन historical `EXPECTED_RED` साक्षी स्वतंत्रपणे कायम
- 45 ऐतिहासिक पायऱ्या, मोठे अचूक bigint, call/context isolation, state lifecycle, invalid input आणि direct mutation aliasing पडताळलेले

## पुढील टप्पा 9/55 — PATCH 04 (अद्याप सुरू केलेला नाही)

कंत्राटानुसार `old` snapshot घ्या; प्रत्यक्ष `mutateStonesWrong` ला **clone** वर बोलवा आणि त्याचे `garbage` मूल्य जतन करा; त्यानंतर पाचही योग्य नवे दगड **फक्त snapshot मधील जुन्या** `w,b,s,m,r` वरून स्वतंत्रपणे काढा. जुनी पद्धत किंवा तिचे आवाहन काढून टाकू नये. Stage 8 च्या जाणीवपूर्वक चुकीच्या उत्पादन-मार्गाला आणि expected-red पुराव्याला सुधारू नये. अंतिम `calendarDateSpaghetti` अजून Stage 54 पर्यंत unavailable आहे.
