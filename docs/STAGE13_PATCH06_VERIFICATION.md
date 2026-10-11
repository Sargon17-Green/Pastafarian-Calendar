# टप्पा 13/55 — PATCH 06 साठी पडताळणी करार

## अपेक्षित उत्पादन वर्तन

`src/patch06Prior.ts` मधील `Patch06PriorHandler` संदर्भाची प्रारंभिक पडताळणी पूर्ण असताना 1-based `slot=i-back` ठरवतो. `slot>=1`: `LegacyVisiblePriorAdapter.legacyPrior` प्रत्यक्ष वापरले पाहिजे आणि मिळालेला `bigint` जतन केला पाहिजे. `slot<=0`: `hiddenK=1-slot`, जुन्या backward storage मध्ये `7-hiddenK` हा zero-based index आणि Stage 11 `Patch05HiddenHandler.correctedHiddenAt` वापरले पाहिजे. जुनी `dropStore[i-back]` संहिता न बदलता इतिहासाचे सर्व सहा expected-red पुरावे जतन करायचे.

## संरक्षण व निरीक्षण

प्रत्येक आवाहनासाठी स्वतंत्र `MonsterContext`, `PATCH_06_APPLIED` status, `patch06.calls`, शाखेनुसार `patch06.visible_legacy_calls` किंवा `patch06.hidden_fallbacks`, frozen input snapshots आणि अपयशी पूर्व-पडताळणीनंतर mutable context मध्ये कोणताही बदल नसावा. Stage 54 चा `calendarDateSpaghetti` अजून `MonsterStageError` देतो.

## अपेक्षित चाचणी-संकेत

```text
STAGE_13_PATCH_06_GUARDS_PASS cases=15 hidden=11 visible=4 mismatches=0
STAGE_13_PATCH_06_PROPERTIES_PASS days=16 cases=2208 hidden=176 visible=2032 mismatches=0 giantCases=138 giantMismatches=0
```

याव्यतिरिक्त सर्व Stage 1–12 चाचण्या हिरव्या राहाव्यात. `DISCOVERY_01_EXPECTED_RED` ते `DISCOVERY_06_EXPECTED_RED` सहा स्वतंत्र इतिहास पुरावे अपेक्षित nonzero exit ने पडताळले पाहिजेत. `CANONICAL_NAMES_LOCK.sha256` बदलू नये.

स्थिती: **GitHub Actions अंतिम पडताळणी येण्याची वाट पाहत आहे**. योग्य run व commit क्रमांक पडताळल्यानंतरच याला अंतिम PASS म्हणावे.
