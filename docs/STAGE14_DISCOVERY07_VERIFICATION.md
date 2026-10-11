# टप्पा 14 — DISCOVERY 07: ऐतिहासिक grind table indexing

## नियमाधारित अपेक्षा

Appendix A नुसार 11 grind rows, (g=1..11), प्रत्येकासाठी क्रमाने पाच गुणांक/दगड. जुने table त्याच 11 rows ने 0..10 ठिकाणी ठेवते. परंतु `LegacyGrindTableAdapter.legacyRow(g)` मध्ये index `g` थेट वापरतो. त्यामुळे `g=1..10` ला पुढची ओळ आणि `g=11` ला `undefined`. हीच ठरवलेली सातवी चूक आहे.

## शोध-पूरावा

- `src/discovery07LegacyGrind.ts`: 11 legacy rows, कोणतीही sentinel row नाही, स्वतंत्र discovery handler व गणना.
- `test/discovery07Fixtures.ts`: Appendix A च्या ओळी independently test-only; production कडे आयात नाही.
- `test/discovery07.ts`: 11 boundary row+numeric साक्षी, 11 mismatches, 0 matches, 10 shifted rows, 1 missing row; legacy call instrumentation, lifecycle guards, context ownership, invalid input, frozen snapshots व prior patches.
- `test/discovery07Properties.ts`: 256 deterministic sets × 11 rows = 2816, 256 missing last rows, 2560 shifted rows, numeric mismatches 2816; तसेच 8192-bit signed numeric inputs.
- `test/discovery07Red.ts`: `DISCOVERY_07_EXPECTED_RED mismatches=11 matches=0 missing=1`, मुद्दाम exit nonzero; CI मध्ये expected-failure म्हणून तपासले पाहिजे.

## निषिद्ध अकाली बदल

index 0 sentinel row किंवा reindex patch Stage 15 च्या आधी जोडायची नाही. `src/discovery07LegacyGrind.ts` मधील चुकीचे indexing ऐतिहासिक पुरावा म्हणून जतन करायचे. Stages 1–13 च्या हिरव्या regression, सहा जुने intentionally-red पुरावे, SourceLanguageCatalog lock आणि Stage 54 ची सीमा बदलू नका.

स्थिती: **पडताळणी यशस्वी — DISCOVERY चा अपेक्षित लाल पुरावा कायम**. Implementation commit `e5a6dd6db96f24a2282c40bfd3a61bfe2c15cfc0` साठी [GitHub Actions run 38170583590](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38170583590) मध्ये `verify` आणि `stage14-typescript-marathi` दोन्ही jobs `success`. TypeScript typecheck, सर्व Stage 1–14 guard/property checks आणि सात archival intentionally-red proofs यशस्वी झाले.

```text
STAGE_14_DISCOVERY_07_GUARDS_PASS mismatches=11 matches=0 missing=1 shifted=10
STAGE_14_DISCOVERY_07_PROPERTIES_PASS cases=2816 shifted=2560 missing=256 differences=2816 giantCases=22 giantValues=20
DISCOVERY_07_EXPECTED_RED mismatches=11 matches=0 missing=1
```

यांपैकी शेवटचा `DISCOVERY_07_EXPECTED_RED` हा नेहमीच्या shell आदेशात nonzero exit देतो; workflow ने हे अपयश **अपेक्षित** म्हणून वेगळे तपासून यशस्वी ठरवले. Stage 15 मधील sentinel-row patch लागू केलेला नाही. पुढे टप्पा 15 = PATCH 07.
