# टप्पा 9 पूर्ण — टप्पा 10 साठी हस्तांतरण

कामाची शाखा `TypeScript+मराठी` आहे. **फक्त याच शाखेत** पुढील commits करा; `main` बदलू नका. प्रकल्पाचे एकूण 55 टप्पे आहेत. पडताळलेले पूर्ण टप्पे: **1–9**. पुढे **Stage 10 — DISCOVERY 05**, त्यानंतर Stage 11 — PATCH 05.

## आतापर्यंतचे स्थिर नियम

- Stage 1: TypeScript/मराठी स्वतंत्र normative foundation; 17 कटलेट आणि 47 महिने यांची `canonicalIndex`-आधारित frozen catalog व SHA lock.
- Stage 2–3: जुनी regular remainder चूक आणि स्वतंत्र `patch01Save` दुरुस्ती.
- Stage 4–5: जुना पाया-दिवस `oldDayTag` आणि `patch02DayTags` + निरुपद्रवी ऐतिहासिक foundation scar.
- Stage 6–7: दोन day tags मधील चुकीचे अंतर `oldDistance` आणि chronological `patch03Distance` + अंतिम `+1`. Stage 6 चा context lifecycle audit पूर्ण.
- Stage 8–9: `mutateStonesWrong` पाच दगड sequentially in-place बदलते. `patch04Stones` मधील old snapshot, `clone` वरील **प्रत्यक्ष legacy call**, मिळालेले `legacyGarbage` आणि पाच old-only योग्य मूल्ये या चार कृती कायम.
- चार ऐतिहासिक `EXPECTED_RED` चाचण्या अजून मुद्दाम exit 1 देतात; CI चारही अपेक्षित परिणाम सत्यापित करतो.
- `calendarDateSpaghetti` अजून अंतिम Stage 54 पर्यंत उपलब्ध नाही; तात्पुरती पूर्ण दिनांक-गणना देऊ नका.

## Stage 9 ची तपासलेली स्थिती

- Tested SHA: `e4581720a00c09ec1f7a16ff1fb70d0c05879a6e`
- CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38159106148 — दोन्ही jobs PASS
- `STAGE_09_PATCH_04_PASS cases=1076 cells=5380 legacyCalls=1076 overwritten=4304 mismatches=0`
- `STAGE_09_PATCH_04_METAMORPHIC_PASS comparisons=301 cells=1505 historicalDifferences=1204`
- संपूर्ण पुरावा: `docs/STAGE09_PATCH04_VERIFICATION.md`.

## Stage 10 — फक्त DISCOVERY 05

मूळ 55-stage कंत्राटातील पाचवा ऐतिहासिक दोष: लपवलेले थेंब `hidden7,hidden6,...,hidden1` या **उलट क्रमाने** साठवले जातात. Stage 10 मध्ये ही जुनी storage चूक उत्पादनात प्रत्यक्ष दाखवावी, नियमाधारित test-only oracle शी जुळणी/फरक पुरावा द्यावा, स्वतंत्र context व निदान जोडा, आणि Stage 01–09 regressions अखंड ठेवा. Stage 11 मधील सुधारणा म्हणजे `hidden k` मिळवताना `8-k` index वापरणे; array उलटी करून किंवा जुना storage code बदलून Stage 10 मध्ये अकाली दुरुस्ती करू **नका**.

काम सुरू करताना GitHub चे ताजे branch HEAD, `DEVELOPMENT_STAGE.md`, मूळ करार व विद्यमान tests तपासा. दुसऱ्या programming-language शाखेतील code/fixtures वापरू नका. TypeScript code व मराठी natural-language docs पाळा. Native GitHub Actions मधील TypeScript typecheck, full regression आणि नवीन intentional expected-red यशस्वी पडताळल्यावरच `LAST_COMPLETED_STAGE=10` लिहा.
