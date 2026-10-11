# टप्पा 3 पूर्ण — टप्पा 4 साठी हस्तांतरण

## वर्तमान नोंद

- शाखा: `TypeScript+मराठी` (फक्त ही शाखा; `main` बदलू नये).
- एकूण टप्पे: 55.
- शेवटचा पूर्ण टप्पा: 3 — PATCH 01.
- पुढील टप्पा: 4 — PATCH 02 DISCOVERY.
- नियमाधारित पूर्ण दिनांक-अंमलबजावणी: अद्याप तयार नाही.
- स्रोत भाषा आणि स्थिर `canonicalIndex`: मराठी; 17 कटलेट आणि 47 महिने; गोठवलेल्या नावांत बदल करू नयेत.

## काय सिद्ध झाले

टप्पा 2 च्या `LegacyRemainderAdapter` मध्ये 0..M-1 शेष-गणनेमुळे `M`, `2M`, `3M` वर `SAVE` ऐवजी 0 मिळते; `M+1` साठी 1 बरोबर मिळते.

टप्पा 3 चा `src/patch01Save.ts` एकाच दोषावर दुरुस्ती करतो: `legacyValue === 0n` असल्यास `M = 2^127 - 1` परत द्यायचे; अन्यथा शेष तसाच. `src/discovery01LegacyRemainder.ts` आणि `test/discovery01Red.ts` हा पुरावा म्हणून मुद्दाम कायम ठेवलेला आहे.

`test/patch01.ts` ने 672 गणिती साक्षी तपासल्या: 16 शून्य-दुरुस्त्या, 656 सामान्य शेष, 0 भिन्न निष्पन्ने. तसेच `M` ची पूर्णांक-कालिकता, निगराणी/context विलगीकरण, status, त्रुटी-अटी, इतिहास टिकवणे यांची तपासणी केली. वैध bigint वाचण्याचा नियम लागू आहे.

## प्रमाणित चाचण्या

- Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38151476087
- Tested commit: `885645e013b2a28e08cd55fcec359434cdf04fc0`
- `npm run typecheck` — PASS.
- `npm test` — `STAGE_01_PASS`, `STAGE_02_DISCOVERY_01_GUARDS_PASS mismatches=3 matches=1`, `STAGE_03_PATCH_01_PASS cases=672 repairs=16 unchanged=656 mismatches=0`.
- `npm run test:discovery01:red` — जाणूनबुजून exit 1; CI मध्ये याच अपेक्षित लाल निकालाला PASS म्हणून सत्यापित केले.
- Canonical Names Lock — PASS.

## पुढचे पाऊल

1. GitHub वरील शाखेची ताजी HEAD SHA, `DEVELOPMENT_STAGE.md`, सर्व ऐतिहासिक चाचण्या आणि normative निर्णय तपासा.
2. चौथ्या टप्प्यासाठी **फक्त PATCH 02 DISCOVERY** तयार करा: आधी अचूक ऐतिहासिक दोषाचे कंत्राट आणि विशिष्ट निरीक्षणीय साक्षी सत्यापित करा. कंत्राट उपलब्ध नसल्यास अंदाजाने दोष बनवू नका.
3. आधीचे stage 1–3 पुरावे हिरवे ठेवा; ऐतिहासिक expected-red चाचणी इतिहास म्हणून तशीच ठेवा.
4. भविष्यकालीन दुरुस्त्या किंवा Stage 54 चे अंतिम integration आताच जोडू नका.
5. समर्पित शाखेवरच commit करा, CI पुरावे पाहा आणि त्यानंतरच पूर्णत्वाची नोंद अद्ययावत करा.

कोणताही इतर भाषेचा implementation, fixture, oracle, generated table किंवा भिन्न शाखेतील implementation artifact आधार म्हणून वापरू नका.
