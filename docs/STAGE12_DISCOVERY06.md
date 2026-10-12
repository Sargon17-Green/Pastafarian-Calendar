# ደረጃ 12/55 — DISCOVERY 06 (COMPLETE / EXPECTED_RED)

## የታሪካዊው ስህተት

`legacy_prior(drop_store,i,back)` ቀድሞ የታዩ ጠብታዎችን ብቻ ከ`drop_store[i-back]` ያነባል። የሚታዩ ጠብታዎች በ1-መሠረት ይከማቻሉ፤ በV የአካላዊ `index 0` መያዣው sentinel ነው።

`i-back>=1` ሲሆን ስሌቱ የታሪካዊውን የሚታይ ጠብታ በትክክል ይመልሳል። `i-back<=0` ሲሆን ግን የተፈለገው ስውር ጠብታ በ`legacy_prior` የማይታወቅ ነው። የV ሕገ-ወጥ አሉታዊ የarray ንባብ ሂደቱን እንዳያቋርጥ የተሳሳተ slot በ`!BigInt` error ይመለሳል፤ ይህ እስካሁን የPATCH 06 ማስተካከያ አይደለም።

## የRED እና GREEN ማስረጃ

| የእውነተኛው ጠብታ ሁኔታ | i | back | slot | የሚያስፈልገው |
|---|---:|---:|---:|---|
| የመጀመሪያው የሚታይ ጠብታ ቀዳሚ | 1 | 1 | 0 | hidden1 |
| ሁለተኛው የሚታይ ጠብታ የ3-ቀድሞ ዋጋ | 2 | 3 | -1 | hidden2 |
| የመጀመሪያው የ3-ቀድሞ ዋጋ | 1 | 3 | -2 | hidden3 |
| የመጀመሪያው የ7-ቀድሞ ዋጋ | 1 | 7 | -6 | hidden7 |
| አዎንታዊ ቀዳሚ አንድ | 4 | 3 | 1 | visible1 |
| አዎንታዊ ቀዳሚ ሦስት | 4 | 1 | 3 | visible3 |

አራቱ የመጀመሪያ ፈተናዎች `discovery06_expected_red_test.v` ውስጥ ሆን ተብለው RED መሆን አለባቸው። ሁለቱ አዎንታዊ ሙከራዎች እና የቀድሞው `HiddenPatch05` መርመራ GREEN ናቸው።

## ታሪካዊ መስመር የተያያዘበት

`legacy_prior` → `LegacyPriorAdapter` → `BaseDispatcher.dispatch_legacy_prior` → `calendar_prior_spaghetti`። የ`calendar_prior_spaghetti` `hidden` ግቤት አለው፣ ግን ለአሁኑ አያነብበውም። `calendar_date_spaghetti` የምርመራ መልዕክት የመጀመሪያውን የታሪክ ስህተት እንደ `DISCOVERY_06 oldPriorSlot0=ERROR` ይመዘግባል።

## የV ማረጋገጫ

```text
v fmt -verify ./pastafari
v test ./pastafari/discovery06_witness_test.v
v -check ./pastafari/discovery06_expected_red_test.v
v test ./pastafari/discovery06_expected_red_test.v
```

የመጨረሻው የRED ፋይል አራት የተለዩ assertions በሆን ተብሎ ይወድቃሉ። የቀድሞ 16 ፋይሎች እና አዲሱ የታሪክ witness በአጠቃላይ 17/17 GREEN ይቀራሉ። `PATCH 06` ሳይፈቀድ አይጨመርም፤ በደረጃ 13 ብቻ ይጀመራል።

## የV 0.5.2 የተረጋገጠ መዝጊያ

- የተፈተነው commit፦ `4426662ddbfd426b2db12c09f72a1b94da55cd5f`
- GitHub Actions፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38222220614
- የማስረጃ ቅርስ፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38222220614/artifacts/11735060045
- `V 0.5.2 7647ce1`፤ `v fmt -verify ./pastafari` PASS።
- 17 የቀድሞ እና አዲስ witness `_test.v` ፋይሎች PASS ናቸው፤ በ`slot=0,-1,-2,-6` ላይ 4 የታሰቡ RED assertions በስም ተረጋግጠዋል።
- `PATCH 06` አልተጨመረም፤ `LAST_COMPLETED_STAGE=12` ነው።

**ደረጃ 12 COMPLETE / EXPECTED_RED።**
