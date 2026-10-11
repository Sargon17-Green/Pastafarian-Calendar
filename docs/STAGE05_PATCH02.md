# ደረጃ 5/55 — PATCH 02 (GREEN ማረጋገጫ ይጠበቃል)

## የሚጠበቀው የታሪክ ስርዓት

`old_day_tag(day)` በደረጃ 4 የታረመ አይደለም፣ ስህተቱ እንዳለ ይቀራል፦

```text
oldDayTag(day) = 2 * abs(day - FOUNDATION)
n = oldDayTag(day)
if day >= FOUNDATION: n = n + 1
if day == FOUNDATION and n != 1: n = 1
return n
```

ሁለተኛው መከላከያ `if` ከትክክለኛው `oldDayTag` በኋላ በተለምዶ አይነሳም፤ ቢሆንም በታሪክ የተቀመጠው ሕግ ስለሆነ አልተወገደም። ለዚህ መከላከያ በተለየ ክፍል ፈተና ተጨምሯል።

`BaseDispatcher.dispatch_legacy_day_tag` መጀመሪያ ይሠራል፤ `DayTagPatch02.apply` ከዚያ በኋላ ይሠራል። `calendar_day_tag_spaghetti` የPATCH 02 ውጤት ይመልሳል፤ `calendar_date_spaghetti` የሙሉ የቀን ልወጣ ገና አያደርግም።

## የታሪካዊ እና የተጠገነ ሙከራ

| ቀን | oldDayTag | PATCH 02 |
|---|---:|---:|
| FOUNDATION-2 | 4 | 4 |
| FOUNDATION-1 | 2 | 2 |
| FOUNDATION | 0 | 1 |
| FOUNDATION+1 | 2 | 3 |
| FOUNDATION+2 | 4 | 5 |

በ`discovery02_expected_red_test.v` ውስጥ ያሉ አራት የደረጃ 4 ውድቀቶች አዲሱ `PATCH 02` በኋላ አረንጓዴ መሆን አለባቸው። እዚያ ያሉት `assert` መግለጫዎች አይለወጡም። የቀድሞው `discovery02_witness_test.v` አሁን ወደ legacy adapter በቀጥታ ይሄዳል።

## የV 0.5.2 ፈተናዎች

```text
v fmt -verify ./pastafari
v test ./pastafari/normative_oracle_test.v
v test ./pastafari/discovery01_witness_test.v
v test ./pastafari/discovery01_expected_red_test.v
v test ./pastafari/patch01_test.v
v test ./pastafari/discovery02_witness_test.v
v test ./pastafari/discovery02_expected_red_test.v
v test ./pastafari/patch02_test.v
v test ./pastafari
```

እዚህ ሁሉም `exit=0` መመለስ አለባቸው። በ`.github/workflows/canonical-names-lock.yml` ውስጥ `stage05_native_v` የV ተረጋገጠ 0.5.2 (`7647ce1`) ይጠቀማል። የCI እውነተኛ ውጤት ሳይታይ `LAST_COMPLETED_STAGE=4` ይቆያል። ደረጃ 6 በዚህ ስራ አይጀመርም።

የደረጃ 4 የRED ማስረጃ፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38155338854
