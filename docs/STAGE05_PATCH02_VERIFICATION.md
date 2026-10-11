# टप्पा 5/55 — PATCH 02 पडताळणी

## मर्यादा आणि नियम

शाखा: `TypeScript+मराठी`. `main` बदललेला नाही. या टप्प्यात पूर्वीचा `src/discovery02LegacyDayTag.ts` ऐतिहासिक दोषासहित तसाच ठेवलेला आहे. दुरुस्ती केवळ नवीन `src/patch02DayTag.ts` मध्ये आहे. गणना-दिवस आणि प्रश्न-दिवस स्वतंत्र `bigint` स्वरूपात चालवले जातात.

```text
n = oldDayTag(day)
if day >= FOUNDATION_DAY: n += 1
if day == FOUNDATION_DAY and n != 1: n = 1
```

दुसरी अट पहिल्या नियमामुळे सध्या निष्प्रभावी आहे; मात्र ती स्रोत-कोडमध्ये स्वतंत्र `if` म्हणून टिकते. `foundationScarChecked`, `foundationScarForced` आणि संदर्भ-विशिष्ट metrics तिचा पुरावा ठेवतात. अर्थविषयक अंतिम दिनांक-अल्गोरिदम अजून उपलब्ध नाही.

## नियमाधारित साक्षी

- Foundation day `F=-15055671`.
- `F-2,F-1,F,F+1,F+2` साठी ऐतिहासिक परिणाम `4,2,0,2,4`; सुधारित परिणाम `4,2,1,3,5`.
- `test/patch02.ts` मधील 49 क्रॉस-सीमा-जोड्या, 26 मोठ्या/सीमा-जोड्या आणि 1024 निश्चित-बीजाच्या जोड्या; एकूण **1099** जोड्या व **2198** दिवस.
- गणिती oracle विरुद्ध `mismatches=0`; `plusOne=1079`, `scarChecks=18`, `scarForces=0`.
- 4096-bit आणि 16384-bit मूल्ये, स्वतंत्र context, metrics, `branchTrace`, चुकीचे inputs, stage lifecycle आणि PATCH 01 ची अखंडता तपासली.
- `test/discovery01Red.ts` आणि `test/discovery02Red.ts` या दोन वेगळ्या ऐतिहासिक expected-red साक्षी बदललेल्या नाहीत.

## प्रत्यक्ष GitHub Actions पुरावा

- तपासलेला commit: `7ff46fb0de35e1bf5aa837d56a3cde0d692630ca`.
- Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38153654056
- `verify` (Canonical Names Lock) — PASS.
- `stage05-typescript-marathi` — PASS.
- `npm run typecheck` — PASS.
- `STAGE_01_PASS`, `STAGE_02_DISCOVERY_01_GUARDS_PASS`, `STAGE_03_PATCH_01_PASS`, `STAGE_04_DISCOVERY_02_GUARDS_PASS`, `STAGE_05_PATCH_02_PASS pairs=1099 days=2198 plusOne=1079 scarChecks=18 scarForces=0 mismatches=0` — सर्व पुष्टी.
- दोन्ही `test:discoveryXX:red` चाचण्या अपेक्षित exit 1 सहित CI ने स्वीकारल्या.

## पुढे

Stage 06 — DISCOVERY 03, परंतु आधी मूळ ऐतिहासिक 55-टप्प्यांच्या करारातून तिसऱ्या दोषाची नेमकी व्याख्या तपासावी. अंदाजाने नवीन दोष तयार करायचा नाही. टप्पे 1–5, दोन्ही expected-red चाचण्या आणि freeze केलेली canonical नावे अबाधित ठेवावीत.
