# ደረጃ 24/55 — DISCOVERY 12 (EXPECTED_RED)

## የታሪክ ስህተት

`old_next_bowl_fixed_name(queried_id)` የተጠየቀውን ID ከ1 እስከ6 እንደሆነ ያረጋግጣል፣ ቀጣዩንም `(queried_id % 6) + 1` ብሎ ይመልሳል። ይህ ሕግ በቋሚ `[1,2,3,4,5,6]` ስሞች ላይ ብቻ ትክክል ነው። ለ`orderAt46Latch` የሚመጣውን ሌላ ቅደም ተከተል ሳያነብ ይመልሳል።

`LegacyNextBowlAdapter` ቅደም ተከተሉን ለአስፈላጊ መረጋገጥ ይቀበላል፣ ቀጣዩን ግን በላች ውስጥ አይፈልግም። `BaseDispatcher.dispatch_legacy_next_bowl` እና `calendar_next_bowl_spaghetti` ይህን ስህተት በተግባር ይጠራሉ። `calendar_post_stir_next_bowl_spaghetti` ከ12 post-stirs የPATCH 11 ትክክለኛ `order_for_query` ያገኛል፣ የnext bowl ምርጫው ግን ታሪካዊውን ቋሚ ID ይጠቀማል።

## አራቱ የተለዩ የEXPECTED_RED ምስክሮች

| የ46ኛው ቅደም ተከተል | queriedId | የታሪክ ውጤት | ትክክለኛ circular successor |
|---|---:|---:|---:|
| [6,5,4,3,2,1] | 6 | 1 | 5 |
| [6,5,4,3,2,1] | 1 | 2 | 6 |
| [2,3,1,4,5,6] | 3 | 4 | 1 |
| [1,3,5,2,4,6] | 1 | 2 | 3 |

`discovery12_expected_red_test.v` እነዚህን አራት RED assertions እና የidentity፣ የrotated እና የPATCH 11 ቀጣይ የማይደረስ መሆን ሶስት GREEN controls ይይዛል። `discovery12_witness_test.v` ትክክለኛ የታሪክ መመለሻ፣ 720 ቅደም ተከተሎች፣ 4320 ምርጫዎች፣ የlegacy dispatcher መስመር፣ 12 ብስለቶች፣ ያልተፈቀዱ ID እና ቅደም ተከተሎች፣ የጠሪ ውሂብ ሳይቀየር መቆየትን ይፈትሻል።

```text
v fmt -verify ./pastafari
v test ./pastafari/discovery12_witness_test.v
v -check ./pastafari/discovery12_expected_red_test.v
v test ./pastafari/discovery12_expected_red_test.v
```

ከደረጃ 23 34 የGREEN ፋይሎች እና አዲሱ witness ተደምሮ 35/35 GREEN መሆን አለበት። አራቱ የተለዩ RED assertions በተጠበቀው ሁኔታ ይወድቃሉ። `PATCH 12` የላች ቅደም ተከተል ቦታ ፍለጋ እና የቀጣዩን ID ንባብ ወደ ደረጃ 25 ተዘግቷል። `LAST_COMPLETED_STAGE=23` እስከ native V CI ማረጋገጫ ይቆያል። ደረጃ 25 አልተጀመረም።
