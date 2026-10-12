# ደረጃ 14/55 — DISCOVERY 07 (COMPLETE / EXPECTED_RED)

## የታሪክ የወፍጮ ሰልፍ ስህተት

ለ46 ግልጽ ጠብታዎች እያንዳንዳቸው 11 የወፍጮ ዙሮች አሉ። የረድፍ አካላት `[a,b,c,d,kind]` ናቸው። መደበኛው የወፍጮ ሂሳብ፦

```text
xNext = SAVE(x*x + a*x + b*prev1 + c*prev3 + d*prev7 + stone[kind])
```

የታሪካዊው የ11 ረድፎች ሰንጠረዥ በ`legacy_visible_grind_table` ውስጥ በ0..10 ተደራጅቷል። ግን `old_grind_row(grind)` የ`grind` ቁጥርን በቀጥታ ወደ `table[grind]` ያስገባል። የሎጂክ ዙሮች 1..11 ስለሆኑ ከመጀመሪያው ረድፍ አንድ ሰልፍ ይዘገያሉ። ለ11ኛው ዙር ረድፍ አይኖርም፤ በV ሂደት እንዳይቋረጥ `![]int` error ተጠቅመናል።

| የሎጂክ ወፍጮ | የታሪክ መልስ | የትክክለኛው መልስ |
|---:|---|---|
| 1 | [5,7,11,13,2] | [3,5,7,11,1] |
| 2 | [7,11,13,17,3] | [5,7,11,13,2] |
| 10 | [37,41,43,47,1] | [31,37,41,43,5] |
| 11 | error | [37,41,43,47,1] |

## የሂሳብ ምስክር

ለ`x=2`፣ `prev1=3`፣ `prev3=5`፣ `prev7=7` እና የመጀመሪያው አምስት ድንጋዮች `[17,29,43,71,101]`፣ የመጀመሪያው የታሪክ ወፍጮ `210` ይሰጣል። የትክክለኛው ረድፍ ግን `154` ይሰጣል። የሂሳብ ስህተቱ በረድፍ መርጫ ብቻ ነው፣ SAVE ወይም ሌሎች ታሪካዊ መጠገኛዎች አልተቀየሩም።

## የተያያዘ የproduction መስመር

`legacy_visible_grind_table` → `old_grind_row` → `LegacyGrindAdapter` → `BaseDispatcher.dispatch_legacy_grind` → `calendar_grind_row_spaghetti` → `calendar_grind_once_spaghetti`። `calendar_date_spaghetti` ውስጥ `DISCOVERY_07 oldGrind1A=5` እና `DISCOVERY_07 oldGrind11=ERROR` ይመዘገባሉ።

## የV ማረጋገጫ

```text
v fmt -verify ./pastafari
v test ./pastafari/discovery07_witness_test.v
v -check ./pastafari/discovery07_expected_red_test.v
v test ./pastafari/discovery07_expected_red_test.v
```

20 የቀድሞና አዲስ witness ፋይሎች GREEN መሆን አለባቸው። የ`discovery07_expected_red_test.v` አራት የሎጂክ መርጫ assertions በሆን ተብሎ RED መሆን አለባቸው። የ`PATCH 07` sentinel ረድፍ ለደረጃ 15 ይቀራል፤ V 0.5.2 የCI ማረጋገጫ PASS ነው፤ `LAST_COMPLETED_STAGE=14`።

## የተረጋገጠ የV ማስረጃ

- የተፈተነ commit፦ `c15c5848da35ebd72cd9d98ab188baf53f79f36f`
- GitHub Actions፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38227809414
- የማስረጃ ቅርስ፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38227809414/artifacts/11737470384
- `V 0.5.2 7647ce1`፤ `v fmt -verify ./pastafari` PASS።
- 20 የቀድሞና አዲስ የታሪክ ምስክር ፋይሎች PASS። በ`grind=1,2,10,11` ላይ 4 የታሰቡ RED assertions በተናጠል ተረጋግጠዋል።
- `old_grind_row` እና ረድፎቹ 0..10 እንዳሉ ይቀራሉ። `PATCH 07` ለደረጃ 15 ይጠበቃል።
- ደረጃ 15 አልተጀመረም።

**ደረጃ 14 COMPLETE / EXPECTED_RED።**
