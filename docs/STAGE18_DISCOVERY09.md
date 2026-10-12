# ደረጃ 18/55 — DISCOVERY 09 (EXPECTED_RED)

## ስድስቱ ጎድጓዳ ሳህኖችና የታሪክ የማፍሰሻ ስህተት

የቋሚ ጎድጓዳ ሳህን ID 1..6 ከበዚያ ትርጉም የሚለየው የዙሩ ማስቀመጫ ቦታ 1..6 ሁለት የተለያዩ ነገሮች ናቸው። የ`calendar_bowl_order_spaghetti(drop)` ቅደም ተከተል እነዚህን የቦታ ትርጉሞች ይወስናል። በአሁኑ የታሪክ `old_pours_fixed_bowls` ግን ማፍሰሻው ከቋሚ ID 1፣ 2፣ 3 ይነበባል። `LegacyPourAdapter` ይህን እንዳለ በ`BaseDispatcher.dispatch_legacy_pours` ይጠራል።

ትክክለኛው የሚፈለግ ሕግ ለ`pour[1]` `old[order[1]]`፣ ለ`pour[2]` `old[order[2]]`፣ ለ`pour[3]` `old[order[3]]` ማንበብ ነው። ይህ `bowlAlias[position]=order[position]` የPATCH 09 ሥራ ነው፤ በደረጃ 18 ውስጥ አይተገበርም።

## የታሪክ ትክክለኛው ሂሳብ፣ የተሳሳተ መለያ

```text
pour[1] = SAVE(drop² + stones.w * old[1] + 3*i)
pour[2] = SAVE(drop² + stones.b * old[2] + 5*i)
pour[3] = SAVE(drop² + stones.s * old[3] + 7*i)
pour[4..6] = 0
```

ለ`i=1`፣ `drop=2`፣ `stones=[17,29,43,71,101]`፣ `oldBowls=[10,20,30,40,50,60]` የሚከተለው ይታያል፦

| የዙሩ ቅደም ተከተል | የታሪክ ማፍሰሻ | ትክክለኛው ማፍሰሻ |
|---|---|---|
| [1,2,3,4,5,6] | [177,589,1301] | [177,589,1301] |
| [6,5,4,3,2,1] | [177,589,1301] | [1027,1459,1731] |
| [2,3,1,4,5,6] | [177,589,1301] | [347,879,441] |

## የproduction ንዑስ መንገድ

`calendar_initial_bowls_spaghetti` ከ`hidden_counts_spaghetti` የሚመጣውን የሥራ ሁኔታና `BOWL_PRIME=[17,19,23,29,31,37]` ተጠቅሞ `SAVE((action+target*id+distance+connection+direction+prime²)²+id)` ያሰላል። የV አካላዊ ኢንዴክስ 0 ባዶ sentinel ነው፤ እውነተኛዎቹ የጎድጓዳ ሳህን ID 1..6 ናቸው።

`old_pours_fixed_bowls` → `LegacyPourAdapter` → `BaseDispatcher.dispatch_legacy_pours` → `calendar_pours_spaghetti` እውነተኛው የproduction ንዑስ መንገድ ነው። `calendar_date_spaghetti` ያለ ሙሉ 46-ዙር ስሌት በቀላል ምርመራ `drop=720`፣ `order=[6,5,4,3,2,1]` ይጠቀማል፣ እና `DISCOVERY_09 oldPour1` እና `DISCOVERY_09 firstOrderedBowl=6` ያሳያል።

## አራቱ የታሰቡ RED እና GREEN መስፈርቶች

`discovery09_expected_red_test.v` በተገላቢጦሽ `order` ላይ ሶስት የማፍሰሻ ልዩነቶችን፣ በተሽከረከረ `order` ላይ አንድ የማፍሰሻ ልዩነትን በታሰቡ RED assertions ይፈትሻል። የidentity ቅደም ተከተል እና ቦታዎች 4..6 ለGREEN ማረጋገጫ ይቀራሉ። `discovery09_witness_test.v` የታሪኩን ቋሚ-ID ጥሪ፣ ትክክለኛ የመጀመሪያ አቀማመጥ፣ ትልቅ የBigInt ግቤቶችን፣ እና ስህተት አያያዝን ያረጋግጣል።

```text
v fmt -verify ./pastafari
v test ./pastafari/discovery09_witness_test.v
v -check ./pastafari/discovery09_expected_red_test.v
v test ./pastafari/discovery09_expected_red_test.v
```

የቀድሞ 25 ፋይሎች እና አዲሱ የታሪክ ምስክር በአጠቃላይ **26/26 GREEN** መሆን አለባቸው። አራቱ የታሰቡ RED assertions በስም መረጋገጥ አለባቸው። `PATCH 09` alias እና `PATCH 10` shadow አይጀመሩም፤ `LAST_COMPLETED_STAGE=17` የnative V ማረጋገጫ እስኪጠናቀቅ ይቆያል።
