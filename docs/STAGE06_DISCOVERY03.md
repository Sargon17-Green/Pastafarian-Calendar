# ደረጃ 6/55 — DISCOVERY 03 (EXPECTED_RED)

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

የመጨረሻው `v test` ብቻ በሆን ተብሎ RED መሆን አለበት፤ በሎጉ ውስጥ አራቱ ሙከራዎች በስም መታየት አለባቸው። የCI መስመር `.github/workflows/canonical-names-lock.yml` ነው። እውነተኛው የV ማረጋገጫ እስኪሳካ `LAST_COMPLETED_STAGE=5` ይቆያል።

በዚህ ደረጃ `PATCH 03` አይጨመርም፤ በደረጃ 7 ብቻ `chronological=abs(t-c)` መንገድ ይመጣል።
