# ደረጃ 4/55 — DISCOVERY 02 (የሚጠበቀው RED)

## የማይቀየረው የታሪክ ህግ

ከማዕከላዊ የ55 ደረጃዎች ውል መሠረት ሁለተኛው ታሪካዊ ስህተት የቀን መለያ ስሌት ነው፦

```text
FOUNDATION = -15055671
oldDayTag(day) = 2 * abs(day - FOUNDATION)
```

ስሌቱ ከFOUNDATION በፊት ትክክል ነው። በFOUNDATION እና ከዚያ በኋላ የሚያስፈልገውን አንድ አያክልም። ስለዚህ አሮጌው መንገድ የሚመልሰው ውጤት ከኖርማቲቭ በአንድ ያንሳል።

| ቀን | ትክክለኛው | የታሪካዊው |
|---|---:|---:|
| FOUNDATION - 1 | 2 | 2 |
| FOUNDATION | 1 | 0 |
| FOUNDATION + 1 | 3 | 2 |
| FOUNDATION + 2 | 5 | 4 |
| FOUNDATION + 2^200 | 2^201 + 1 | 2^201 |

## የproduction መንገድ

- `old_day_tag` የቀድሞውን ስህተት እንዳለ ይፈጽማል።
- `LegacyDayTagAdapter` በ`BaseDispatcher.dispatch_legacy_day_tag` ይጠራል።
- `calendar_day_tag_spaghetti` የproduction ንዑስ መግቢያ ነው።
- `calendar_date_spaghetti` ከbootstrap በኋላ PATCH 01 የተጠገነውን SAVE እና የተሳሳተውን day tag ሁለቱንም በእውነት ይጠራል፤ የተሟላ የቀን ውጤት ገና የለም።
- ለሙከራ ብቻ ያለው ኖርማቲቭ ኦራክል አይጠራም።

## የመዝጊያ ፈተናዎች

```text
v fmt -verify ./pastafari
v test ./pastafari/normative_oracle_test.v
v test ./pastafari/discovery01_witness_test.v
v test ./pastafari/discovery01_expected_red_test.v
v test ./pastafari/patch01_test.v
v test ./pastafari/discovery02_witness_test.v
v -check ./pastafari/discovery02_expected_red_test.v
v test ./pastafari/discovery02_expected_red_test.v
```

ከመጨረሻው ትእዛዝ በስተቀር ሁሉም `exit=0` መመለስ አለባቸው። የመጨረሻው ትእዛዝ አራት የታሰቡ assertion ውድቀቶችን በስም መስጠት አለበት። `FOUNDATION-1` እና PATCH 01 ያለ ውድቀት መቆየት አለባቸው።

የGitHub Actions ሥራ፦ `.github/workflows/canonical-names-lock.yml` ውስጥ `stage04_native_v`። የታሰበው RED በV 0.5.2 ቀጥተኛ CI ተረጋግጧል፤ `LAST_COMPLETED_STAGE=4` ነው።

**ደረጃ 5 PATCH 02 አይጀመርም።** የታሪካዊ `old_day_tag` በደረጃ 5 ደግሞ ሳይቀየር መቆየት አለበት።

## የተረጋገጠ የመዝጊያ ማስረጃ

- የተፈተነው commit፦ `f268cbc15a421077df59e569a1b1d2e4ef12fcb8`
- GitHub Actions፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38155338854
- የRED ማስረጃ፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38155338854/artifacts/11708217428
- ተግባራዊ V ስሪት፦ `V 0.5.2 7647ce1`
- `v fmt -verify` PASS፤ 5 አስፈላጊ GREEN የሙከራ ፋይሎች PASS፤ 4 በተናጠል የታሰቡ assertions RED።
- `FOUNDATION-1` እና `PATCH 01` የመቆጣጠሪያ ሙከራዎች GREEN።
- `PATCH 02` አልተጨመረም፤ የደረጃ 5 ሥራ ገና አልተጀመረም።
