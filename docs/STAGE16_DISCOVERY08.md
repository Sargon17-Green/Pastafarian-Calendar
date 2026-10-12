# ደረጃ 16/55 — DISCOVERY 08 (COMPLETE / EXPECTED_RED)

## የታሪካዊው የቅደም ተከተል ጉድለት

የስድስት ጎድጓዳ ሳህኖች ቅደም ተከተል `6! = 720` ሊሆን ይችላል። `old_permutation_unrank0(rank0)` በራሱ ትክክለኛ የዜሮ-መሠረት መፍቻ ነው፤ `rank0=0` ለ`[1,2,3,4,5,6]` እና `rank0=719` ለ`[6,5,4,3,2,1]` ይዛመዳሉ።

ግን `LegacyPermutationAdapter` በእውነተኛ `drop` ላይ የታሪክ ጉድለት ያለውን ጥሪ ይፈጽማል፦

```text
oneBased = regularMod(drop-1, 720) + 1
return oldPermutationUnrank0(oneBased) // ስህተት፦ 1..720 እንደ 0..719
```

የሚፈለገው ትክክለኛ ቅደም ተከተል ከዚህ `oneBased-1` በኋላ ብቻ ነው፤ ይህ የ`PATCH 08` ሥራ ስለሆነ በደረጃ 16 አይጨመርም።

| የdrop እሴት | ትክክለኛ `rank0` | የታሪክ `rank0` | የታሪክ ውጤት |
|---:|---:|---:|---|
| 1 | 0 | 1 | [1,2,3,4,6,5] |
| 2 | 1 | 2 | [1,2,3,5,4,6] |
| 719 | 718 | 719 | [6,5,4,3,2,1] |
| 720 | 719 | 720 | error |

## የታሪክ ንባብ መስመር

`old_permutation_unrank0` → `LegacyPermutationAdapter.order_for_drop` → `BaseDispatcher.dispatch_legacy_permutation` → `calendar_bowl_order_spaghetti`። በ`calendar_date_spaghetti` ውስጥ አንድ የdrop 1 ሙከራ የሚከተለውን ይይዛል፦ `DISCOVERY_08 oldPermRank0=1` እና `DISCOVERY_08 oldPermOrder=[1, 2, 3, 4, 6, 5]`።

## የታሰበው RED እና የሚጠበቁ GREEN

`discovery08_witness_test.v` የ0..719 መፍቻ ትክክለኛነትን፣ የ720 ልዩ ቅደም ተከተሎችን፣ 384-ቢት ግቤቶችን፣ አሉታዊ እና ተደጋጋሚ የdrop እሴቶችን፣ የproduction ጥሪን ይፈትሻል። `discovery08_expected_red_test.v` ውስጥ የdrop=1,2,719,720` አራት assertions ሳይጠገኑ RED ይቀራሉ።

```text
v fmt -verify ./pastafari
v test ./pastafari/discovery08_witness_test.v
v -check ./pastafari/discovery08_expected_red_test.v
v test ./pastafari/discovery08_expected_red_test.v
```

የቀድሞ 22 ፈተና ፋይሎችና አዲሱ witness በአጠቃላይ 23/23 GREEN መሆን አለባቸው። `discovery08_expected_red_test.v` ላይ አራቱ የታሰቡ RED assertions በስም መረጋገጥ አለባቸው። የV 0.5.2 CI ማረጋገጫ PASS ነው፤ `LAST_COMPLETED_STAGE=16` ነው፤ `PATCH 08` እና ደረጃ 17 አይጀመሩም።

## የተረጋገጠ የV ማስረጃ

- የተፈተነ commit፦ `d40d313615367c6cdd9202711f2127200903fecf`
- GitHub Actions፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38235387422
- የማስረጃ ቅርስ፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38235387422/artifacts/11740715370
- `V 0.5.2 7647ce1`፦ `v fmt -verify ./pastafari` PASS።
- 23 የቀድሞ እና አዲስ `_test.v` witness ፋይሎች PASS፤ 4 የታሰቡ RED assertions በተናጠል ተረጋግጠዋል።
- `old_permutation_unrank0` እንደነበረ ተጠብቋል፣ `LegacyPermutationAdapter` የተሳሳተውን የ1..720 ደረጃ በቀጥታ ይልካል።
- `PATCH 08` በደረጃ 17 ብቻ ይመጣል።

**ደረጃ 16 COMPLETE / EXPECTED_RED።**
