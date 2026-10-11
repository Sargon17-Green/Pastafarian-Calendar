# ደረጃ 2/55 — DISCOVERY 01 (EXPECTED RED)

ደረጃ 1 የV 0.5.2 ማረጋገጫውን አልፏል። ይህ ደረጃ አንደኛውን ታሪካዊ ጉድለት **ማሳየት** ብቻ ነው፤ መጠገን አይደለም።

- `M = 2^127 - 1 = 170141183460469231731687303715884105727`
- ኖርማቲቭ፦ `SAVE(x) = 1 + regularMod(x-1, M)`
- የታሪካዊ ስህተት፦ `oldRemainder(x) = regularMod(x, M)`

| ግቤት | ኖርማቲቭ | ታሪካዊ |
|---|---:|---:|
| M | M | 0 |
| 2M | M | 0 |
| 3M | M | 0 |
| M+1 | 1 | 1 |

`LegacyRemainderAdapter` በ`BaseDispatcher.dispatch_legacy_save` ውስጥ ይጠራል። `calendar_save_spaghetti` ለዚህ የproduction ንዑስ መንገድ ቀጥተኛ መግቢያ ነው፤ `calendar_date_spaghetti` ደግሞ እሱን ከbootstrap በኋላ ይጠራዋል። የተሟላው የቀን ልወጣ ገና አልተገነባም፤ ስለዚህ `calendar_date_spaghetti` ግልጽ ስህተት ይመልሳል፣ በስህተቱም `oldRemainder` የሆነውን ውጤት ያሳያል።

## ማረጋገጫ

V 0.5.2 የመሳሪያ ሰንሰለት ላይ እነዚህን በተናጠል ያሂዱ፦

```text
v fmt -verify ./pastafari
v test ./pastafari/normative_oracle_test.v
v test ./pastafari/discovery01_witness_test.v
v test ./pastafari/discovery01_expected_red_test.v
```

የመጀመሪያዎቹ ሦስት ትእዛዞች `exit=0` ሊመልሱ ይገባል። የመጨረሻው ትእዛዝ ሶስት የተጠበቁ የassert ውድቀቶችን ማሳየት እና `exit!=0` መሆን አለበት። ይህ የኖርማቲቭ ንጽጽር ውድቀት በV 0.5.2 (7647ce1) በቀጥታ ተረጋግጧል።

በደረጃ 3 ብቻ ከታሪካዊው መንገድ በላይ `savePatch` ይጨመራል፤ `old_remainder` አይሰረዝም፣ በቦታውም አይስተካከልም።

## የV ማረጋገጫ ማስረጃ (የደረጃ 2 መዝጊያ)

- መስመር፦ `V+አማርኛ`
- የተፈተነ commit፦ `7bad2b66cb4ccb8bb25daec79d8600cf547800f8`
- የV ትክክለኛ ስሪት፦ `V 0.5.2 7647ce1`
- የCI ሩጫ፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38153202920
- የRED የማስረጃ ቅርስ፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38153202920/artifacts/11707283164
- `v fmt -verify ./pastafari`፦ PASS
- `v test ./pastafari/normative_oracle_test.v`፦ PASS
- `v test ./pastafari/discovery01_witness_test.v`፦ PASS
- `v -check ./pastafari/discovery01_expected_red_test.v`፦ PASS
- `v test ./pastafari/discovery01_expected_red_test.v`፦ EXPECTED RED። በM፣ 2M፣ 3M የሚገኙት 3 የassert ውድቀቶች በሎጉ ውስጥ በተናጠል አሉ፤ የM+1 ማረጋገጫ አልወደቀም።

ተመሳሳይ የV ማረጋገጫ በዚህ ቅርንጫፍ `.github/workflows/canonical-names-lock.yml` ውስጥ ከነባሩ የስም መቆለፊያ ሥራ በተለየ job ይሠራል። በGitHub Actions ያልተጀመረው ልዩ `v-amharic-stage02.yml` ተደጋጋሚነትን ለማስወገድ ተወግዷል።

ደረጃ 2 **COMPLETE / EXPECTED_RED** ነው። የመጠገኛው እርምጃ በደረጃ 3 ብቻ ይገባል።
