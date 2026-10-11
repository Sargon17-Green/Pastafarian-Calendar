# टप्पा 4/55 — DISCOVERY 02: पडताळणी-नोंद

## बदलाची सीमा

फक्त `TypeScript+मराठी` शाखा; `main` बदललेला नाही. उत्पादनातील `src/discovery02LegacyDayTag.ts` मध्ये ऐतिहासिक `oldDayTag(day)=2*abs(day-FOUNDATION_DAY)` जतन केले. `src/patch01Save.ts` आणि त्याच्या दुरुस्तीचे नियम जसेच्या तसे राहिले. `calendarDateSpaghetti` अजून अंतिम दिनांक देत नाही.

## पाच बंधनकारक साक्षी

| दिवस | ऐतिहासिक `oldDayTag` | नियमाधारित `dayCount` | तुलना |
|---|---:|---:|---|
| F−2 | 4 | 4 | MATCH |
| F−1 | 2 | 2 | MATCH |
| F | 0 | 1 | MISMATCH |
| F+1 | 2 | 3 | MISMATCH |
| F+2 | 4 | 5 | MISMATCH |

`F = -15055671`. नियमाधारित संदर्भ फक्त `test/normativeOracle.ts` मध्ये आहे. उत्पादन-कॉम्पोनन्ट त्याला आयात करत नाही.

## CI पुरावा

- run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38152040485
- commit: `24a4fe867db8fd273a9d016b6d1a9e7daa33b500`
- `verify` (Canonical Names Lock): PASS.
- `stage04-typescript-marathi`: PASS, यामध्ये typecheck, `STAGE_01_PASS`, `STAGE_02_DISCOVERY_01_GUARDS_PASS mismatches=3 matches=1`, `STAGE_03_PATCH_01_PASS cases=672 repairs=16 unchanged=656 mismatches=0`, `STAGE_04_DISCOVERY_02_GUARDS_PASS mismatches=3 matches=2 cases=5`.
- `test:discovery01:red`: अपेक्षित exit 1 आणि `DISCOVERY_01_EXPECTED_RED mismatches=3 matches=1` सत्यापित.
- `test:discovery02:red`: अपेक्षित exit 1 आणि `DISCOVERY_02_EXPECTED_RED mismatches=3 matches=2` सत्यापित.
- दोन्ही अपेक्षित लाल चाचण्या अखंड ठेवलेल्या; stage 4 वरील दुरुस्ती लागू नाही.

## टप्पा 5 ची मर्यादा (अद्याप लागू नाही)

फक्त PATCH 02 मध्ये जुना `oldDayTag` तंतोतंत जतन करून दुरुस्त मार्ग जोडावा. मूळ ऐतिहासिक करारात जतन झालेली अतिरिक्त अटही ठेवावी:

```text
n = oldDayTag(day)
if day >= FOUNDATION_DAY: n += 1
if day == FOUNDATION_DAY and n != 1: n = 1
```

शेवटची अट पहिल्यामुळे अनावश्यक ठरली तरी ती ऐतिहासिक scar आहे; म्हणून काढू नये. आधीच्या stage 1–4 regressions, दोन ऐतिहासिक expected-red आणि नावांची स्थिरता यांची स्वतंत्र पडताळणी केल्यानंतरच Stage 5 पूर्ण मानावा.
