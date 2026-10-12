# ደረጃ 15/55 — PATCH 07 (COMPLETE / GREEN)

## የታሪክ ስህተቱን አለመሰረዝ

የታሪካዊው `legacy_visible_grind_table()` 11 እውነተኛ ረድፎችን በዜሮ-መሠረት `0..10` ይይዛል። `old_grind_row(grind)` በ`table[grind]` የቀጥታ ማውጫ ይጠቀማል፤ `grind=1` ሁለተኛውን ረድፍ ያመጣል፣ `grind=11` የerror መልስ ይሰጣል። ሁለቱም እንደነበሩ ይጠበቃሉ።

## እንደ ማውጫ ስህተቱ የተዘጋጀ ሰንጠረዥ

```text
patchedTable[0]  = [0,0,0,0,0]        // sentinel — አይሰረዝም
patchedTable[1]  = [3,5,7,11,WHEAT]  // የመጀመሪያው እውነተኛ ዙር
...
patchedTable[11] = [37,41,43,47,WHEAT] // አስራ አንደኛው
row(grind) = patchedTable[grind]
```

`GrindPatch07.table_with_sentinel` የsentinel ረድፍን ከ11 የቀድሞ ረድፎች በፊት ይጨምራል፤ የቀድሞውን ሰንጠረዥ ወደ ራሱ አይለውጥም። `GrindPatch07.row` ቁጥር `1..11` ብቻ ይቀበላል እና `table[grind]` በቀጥታ ያነባል። `BaseDispatcher.dispatch_grind_patch07` ወደዚህ ታሪክ-ተኳሃኝ ማውጫ ይመራል።

| የወፍጮ ቁጥር | የታሪክ መልስ | የPATCH 07 መልስ |
|---:|---|---|
| 1 | [5,7,11,13,2] | [3,5,7,11,1] |
| 2 | [7,11,13,17,3] | [5,7,11,13,2] |
| 10 | [37,41,43,47,1] | [31,37,41,43,5] |
| 11 | error | [37,41,43,47,1] |

## የV ፈተናዎች

`discovery07_expected_red_test.v` በደረጃ 14 የRED ነበሩትን አራት assertions ያለ ለውጥ ይይዛል፤ በደረጃ 15 አራቱም GREEN መሆን አለባቸው። `discovery07_witness_test.v` የታሪካዊውን ስህተት በlegacy dispatcher ይፈትሻል። `patch07_test.v` አዲሱን sentinel፣ 11 ዙሮችን፣ የወፍጮ ሂሳብን፣ 390-ቢት ግቤቶችን፣ የታሪክ እና አዲስ መስመሮችን፣ እና ሕገ-ወጥ የወፍጮ ቁጥሮችን ይፈትሻል።

```text
v fmt -verify ./pastafari
v test ./pastafari/discovery07_witness_test.v
v -check ./pastafari/discovery07_expected_red_test.v
v test ./pastafari/discovery07_expected_red_test.v
v test ./pastafari/patch07_test.v
v test ./pastafari
```

የሙሉ የV እውነተኛ ሙከራ መመዘኛ **22/22 PASS** ነው። የV 0.5.2 የCI ማረጋገጫ PASS ነው፤ `LAST_COMPLETED_STAGE=15` ነው። ደረጃ 16 — `DISCOVERY 08` አይጀመርም።

## የመጨረሻ የቀጥታ V ማረጋገጫ

- የተፈተነው commit፦ `42dbb4a5d9ab6ace74d4855a97888798adf31f10`
- GitHub Actions፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38232812419
- የማስረጃ ቅርስ፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38232812419/artifacts/11738849261
- `V 0.5.2 7647ce1`፦ `v fmt -verify ./pastafari` PASS፣ `v test ./pastafari` **22/22 PASS**።
- የደረጃ 14 አራት የተለዩ RED assertions በፈተናዎቹ ሳይለወጡ GREEN ሆነዋል።
- `old_grind_row` ወደ `legacy_visible_grind_table` ያለው ታሪካዊ የindex ስህተት ተጠብቋል፤ በ`GrindPatch07` ብቻ ባለ-12-ረድፍ sentinel ሰንጠረዥ ይጠቀማል።
- ደረጃ 16 አልተጀመረም።

**ደረጃ 15 COMPLETE / GREEN።**
