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

የመጀመሪያዎቹ ሦስት ትእዛዞች `exit=0` ሊመልሱ ይገባል። የመጨረሻው ትእዛዝ ሶስት የተጠበቁ የassert ውድቀቶችን ማሳየት እና `exit!=0` መሆን አለበት። እዚህ ያለው ማረጋገጫ ገና በአገርኛው V መሳሪያ አልተሠራም።

በደረጃ 3 ብቻ ከታሪካዊው መንገድ በላይ `savePatch` ይጨመራል፤ `old_remainder` አይሰረዝም፣ በቦታውም አይስተካከልም።

## GitHub Actions

`.github/workflows/v-amharic-stage02.yml` በዚህ ቅርንጫፍ ላይ ብቻ V `7647ce1` በመጠቀም የformat፣ የደረጃ 1፣ የwitness እና የEXPECTED_RED ፈተናዎችን ያስኬዳል። የRED መመለስ ብቻ አይበቃም፤ የV `-check` ማረጋገጫ መጀመሪያ ማለፍ አለበት። የCI ማስረጃ ካልተገኘ `LAST_COMPLETED_STAGE=1` እንዳለ ይቆያል።
