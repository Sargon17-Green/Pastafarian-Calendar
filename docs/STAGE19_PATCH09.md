# ደረጃ 19/55 — PATCH 09 (የGREEN ማረጋገጫ ይጠበቃል)

## የታሪካዊው ቋሚ-ID መስመር

`old_pours_fixed_bowls` ሶስቱን ማፍሰሻዎች በቋሚ `bowls[1]`፣ `bowls[2]`፣ `bowls[3]` ይሰላል። የሂሳቡ እና የ`LegacyPourAdapter` ኮድ አልተቀየሩም። ይህ መስመር እንደ ታሪካዊ ማስረጃ በ`BaseDispatcher.dispatch_legacy_pours` አሁንም ተደራሽ ነው።

## የPATCH 09 የቦታ እና ID ካርታ

`PourPatch09.install_bowl_alias` በእያንዳንዱ ጥሪ የራሱን የalias ሰልፍ ይፈጥራል፦

```text
bowlAlias[0] = 0                     // የV sentinel
for position = 1..6:
    bowlAlias[position] = order[position-1]
bowlByLegacyPosition(bowls, position) = bowls[bowlAlias[position]]
```

የ`PourPatch09.pour` የታሪካዊውን ስድስት-ቦታ የማንበቢያ ሰልፍ `legacy_view` በalias ይሞላል፣ ከዚያ `BaseDispatcher.dispatch_legacy_pours(i,drop,stones,legacy_view,order)` ይጠራል። የታሪክ ሰልፍ ትክክለኛውን እውነተኛ ጎድጓዳ ሳህን በየቦታው ያነባል፤ የ`old_pours_fixed_bowls` የቋሚ-ID ስሌት አይሰረዝም። ይህ ቀጣይ የPATCH 10 የቦታ የsnapshot እና pending መያዣ ግን አይደለም።

| ቅደም ተከተል | የlegacy 1..3 | የPATCH 09 1..3 |
|---|---|---|
| [1,2,3,4,5,6] | [177,589,1301] | [177,589,1301] |
| [6,5,4,3,2,1] | [177,589,1301] | [1027,1459,1731] |
| [2,3,1,4,5,6] | [177,589,1301] | [347,879,441] |

## የእውነተኛ V ማረጋገጫ መስፈርቶች

`discovery09_expected_red_test.v` አራቱን የቀድሞ RED assertions ያለ ለውጥ ይይዛል፤ አሁን GREEN መሆን አለባቸው። `discovery09_witness_test.v` ተግባራዊ የታሪክ መረጃ እንዳይጠፋ በ`BaseDispatcher.dispatch_legacy_pours` ይፈትሻል። `patch09_test.v` 720 የቅደም ተከተሎችን፣ 390-ቢት ግቤቶችን፣ የalias ቦታ አጥፊ ግቤቶችን፣ የታሪክ እና ትክክለኛ የማፍሰሻ ውጤቶችን እና ተደጋጋሚ ጥሪዎችን ይፈትሻል።

```text
v fmt -verify ./pastafari
v test ./pastafari/discovery09_witness_test.v
v -check ./pastafari/discovery09_expected_red_test.v
v test ./pastafari/discovery09_expected_red_test.v
v test ./pastafari/patch09_test.v
v test ./pastafari
```

ለደረጃ 19 የV 0.5.2 መመዘኛ **28/28 PASS** ነው። እስከ native CI ማረጋገጫ `LAST_COMPLETED_STAGE=18` ነው። ደረጃ 20 — `DISCOVERY 10` አልተጀመረም።
