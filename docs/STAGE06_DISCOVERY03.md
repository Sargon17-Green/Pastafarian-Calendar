# ደረጃ 6/55 — DISCOVERY 03 (COMPLETE / EXPECTED_RED)

## የማይቀየረው የሂሳብ ሕግ

ኖርማቲቭ ርቀት `abs(t-c)+1` ነው፣ ከFOUNDATION የሚጀምሩ የቀን መለያዎች ልዩነት አይደለም። በደረጃ 6 ውስጥ የታሪካዊ ስህተትን ብቻ እናሳያለን፦

```text
oldDistance(c,t) = abs(dayTag(c) - dayTag(t))
```

`dayTag` ከደረጃ 5 `DayTagPatch02` በኋላ ያለው የproduction መንገድ ነው። የታሪካዊ ስህተት በተለየ `LegacyDistanceAdapter` ውስጥ ይጠበቃል።

## አራት የተለያዩ የRED ማስረጃዎች

| ግቤት | ኖርማቲቭ | የታሪካዊው |
|---|---:|---:|
| c=t=FOUNDATION | 1 | 0 |
| c=FOUNDATION, t=FOUNDATION+2 | 3 | 4 |
| c=FOUNDATION-1, t=FOUNDATION+1 | 3 | 1 |
| c=FOUNDATION-2^300, t=FOUNDATION+2^300 | 2^301+1 | 1 |

በFOUNDATION እና FOUNDATION+1 መካከል ያለው ልዩነት ሁለቱም 2 ስለሚሆኑ የGREEN መቆጣጠሪያ ምሳሌ ነው። የSAVE እና dayTag ቀዳሚ መጠገኛዎችም GREEN ይቆያሉ።

## እውነተኛ የproduction መስመር

`old_distance` → `LegacyDistanceAdapter.distance` → `BaseDispatcher.dispatch_legacy_distance` → `calendar_distance_spaghetti`። `calendar_date_spaghetti` ይህን ሰንሰለት በቀጥታ ይጠራል፤ ግን የተሟላውን የቀን ልወጣ እስካሁን አያመነጭም። `normative_oracle_test.v` ወደ production አይገባም።

## የተለያዩ የV ማረጋገጫዎች

```text
v fmt -verify ./pastafari
v test ./pastafari/normative_oracle_test.v
v test ./pastafari/discovery01_witness_test.v
v test ./pastafari/discovery01_expected_red_test.v
v test ./pastafari/patch01_test.v
v test ./pastafari/discovery02_witness_test.v
v test ./pastafari/discovery02_expected_red_test.v
v test ./pastafari/patch02_test.v
v test ./pastafari/discovery03_witness_test.v
v -check ./pastafari/discovery03_expected_red_test.v
v test ./pastafari/discovery03_expected_red_test.v
```

የመጨረሻው `v test` ብቻ በሆን ተብሎ RED መሆን አለበት፤ በሎጉ ውስጥ አራቱ ሙከራዎች በስም መታየት አለባቸው። የCI መስመር `.github/workflows/canonical-names-lock.yml` ነው። የV 0.5.2 እውነተኛ የEXPECTED_RED ማረጋገጫ ተሳክቷል፤ `LAST_COMPLETED_STAGE=6` ነው።

በዚህ ደረጃ `PATCH 03` አይጨመርም፤ በደረጃ 7 ብቻ `chronological=abs(t-c)` መንገድ ይመጣል።

## የተረጋገጠ መዝጊያ

- የተፈተነ commit፦ `88a2d86d29cb72635b44b9d0f18bdc8fb787f0e0`
- የV ስሪት፦ `V 0.5.2 7647ce1`
- የGitHub Actions ሩጫ፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38157358354
- የማስረጃ ቅርስ፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38157358354/artifacts/11708791583
- `v fmt -verify` PASS፤ 7 ቀዳሚ የሙከራ ፋይሎች PASS፤ አዲሱ witness PASS።
- `v -check ./pastafari/discovery03_expected_red_test.v` PASS፤ 4 የታሰቡ RED assertions በተናጠል ተረጋግጠዋል።
- `PATCH 03` አልተጨመረም፤ ደረጃ 7 ከዚህ የተለየ ነው።
