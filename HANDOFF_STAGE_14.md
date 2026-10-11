# Stage 14 पूर्ण — Stage 15 साठी हस्तांतरण

## वर्तमान शाखा व निश्चित अवस्था

- फक्त `TypeScript+मराठी` शाखेत काम करा; `main` बदलू नका.
- 55 पैकी **14 टप्पे पूर्ण**; पुढचा एकमेव टप्पा **15 = PATCH 07**.
- Stage 14 implementation commit: `e5a6dd6db96f24a2282c40bfd3a61bfe2c15cfc0`.
- GitHub Actions: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38170583590 — `verify` व `stage14-typescript-marathi` PASS.
- स्रोत भाषा फक्त मराठी; `SourceLanguageCatalog` व canonical name lock गोठवलेले. इतर भाषिक branches किंवा त्यांचे artifacts वापरू नका.

## सातवा ऐतिहासिक दोष: निश्चित पुरावा

`src/discovery07LegacyGrind.ts` मधील `LEGACY_GRIND_TABLE` मध्ये *sentinel शिवाय* 11 वास्तविक rows zero-based 0..10 येथे आहेत. `LegacyGrindTableAdapter.legacyRow(grind)` मात्र ऐतिहासिक दोषाप्रमाणे `table[grind]` वाचतो, `grind=1..11`. त्यामुळे पहिल्या दहा grind ला चुकीची पुढची row व अकराव्या grind ला `undefined` मिळते. याचे स्वतंत्र context, metrics व branch trace सहित प्रत्यक्ष अंकगणिती निरीक्षण `discoverLegacyGrind` नोंदते.

`test/discovery07Fixtures.ts` मध्ये Appendix A चे 11 rows स्वतंत्र **test-only** मांडले; production code oracle आयात करत नाही. `test/discovery07.ts` च्या 11 साक्षींत 11 mismatches/0 matches/1 missing row; `test/discovery07Properties.ts` मध्ये 256×11=2816 cases, 2560 shifted numeric rows, 256 missing, 2816 differences आणि 22 विशाल signed bigint साक्षी. ऐतिहासिक लाल पुरावा:

```text
DISCOVERY_07_EXPECTED_RED mismatches=11 matches=0 missing=1
```

ही चाचणी जाणीवपूर्वक nonzero exit देते; CI ला याची अपेक्षा आहे.

## Stage 15 PATCH 07 — आवश्यक बदल

मूळ 26 टप्प्यांच्या ठरावानुसार *जुने indexing हटवायचे नाही.* नवीन independent patched path मध्ये `GRIND_TABLE_WITH_SENTINEL` तयार करा, ज्यात:
- `index 0`: `[0,0,0,0,NONE]` ही ऐतिहासिक sentinel row.
- `index 1..11`: Appendix A मधील 11 खऱ्या grind rows, त्याच क्रमात.
- `g=1..11` वर जुने `legacyRow(g)` logic अथवा तेच index सूत्र आता **sentinel-bearing table** मध्ये लागू होईल; स्वतंत्र `LegacyGrindTableAdapter` मधील historical no-sentinel table व त्याचा red proof टिकवून ठेवा.
- सुधारीत grind गणना सर्व 11 ओळींत test-only reference `SAVE` आणि नियमानुसार दगड-पास यांच्याशी जुळली पाहिजे.
- गहाळ किंवा चुकीची row, invalid grind, non-bigint, sparse stone, context reuse, ownership, repeated calls, मोठे signed bigint, sentinel न बदलणे, जुनी history तोडू नये.
- Stage 1–14 सर्व regression tests हिरवे, सात intentionally-red archival proofs तशाच. Stage 16 च्या permutation rank दोषाची दुरुस्ती **नको**.

प्रत्येक कार्याच्या प्रारंभी live GitHub HEAD, `DEVELOPMENT_STAGE.md`, मूळ 55-stage contract आणि हा handoff वाचा. Stage 15 मध्ये अचूक sentinel patch लावून GitHub Actions यशस्वी झाल्यावरच stage पूर्ण घोषित करा.

अंतिम दिनांक API `calendarDateSpaghetti` Stage 54 पूर्वी `MonsterStageError` देतो. या handoff साठी स्थानिक वापरकर्ता-कृती आवश्यक नाही.
