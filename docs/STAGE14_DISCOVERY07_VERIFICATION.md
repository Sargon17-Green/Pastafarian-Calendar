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

स्थिती: GitHub Actions पडताळणी बाकी; पुरावा मिळाल्यावरच पूर्ण घोषित करावे.
