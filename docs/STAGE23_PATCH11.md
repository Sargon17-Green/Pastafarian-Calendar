# ደረጃ 23/55 — PATCH 11 (የGREEN ማረጋገጫ ይጠበቃል)

## የ46ኛው ጠብታ የማይደረስ ቅደም ተከተል

`PostStirPatch11.latch_order_at_46` የሚቀበለውን የ46ኛው ጠብታ ቅደም ተከተል የስድስት ID ትክክለኛ permutation መሆኑን ያረጋግጣል። ስድስቱን መለያዎች በአዲስ ሰልፍ `order_at_46_latch` ላይ አንድ ጊዜ ይቀዳል። ከዚያ በኋላ በላች ላይ ሌላ ጽሑፍ አይደረግም።

## የታሪክ መንገድ ተጠብቋል

`old_post_stirs_overwrite_drop46_order`፣ `LegacyPostStir12Adapter`፣ እና `BaseDispatcher.dispatch_legacy_post_stir12` እንደበፊቱ ይቀራሉ። `PostStirPatch11.post_stir` ከቅደም ተከተሉ ላች በኋላ በዚህ መንገድ 12ቱን ብስለቶች ያካሂዳል። የlegacy የquery_order መያዣ በ12ቱ ብስለቶች 12 ጊዜ ቢደረስም ያንን መጠቀም አይቻልም። ትክክለኛው መመለሻ የlegacy የስድስቱ ቦውሎችን ሂሳብ ያስቀምጣል፣ በ`order_for_query` ደግሞ `order_at_46_latch` የራሱን ቅጂ ይመልሳል።

## የታሪክ እና የPATCH 11 ውጤቶች

| የ46ኛው ጠብታ ቅደም ተከተል | የlegacy query | የPATCH 11 query |
|---|---|---|
| [1,2,3,4,5,6] | [3,5,1,4,6,2] | [1,2,3,4,5,6] |
| [6,5,4,3,2,1] | [3,5,1,4,6,2] | [6,5,4,3,2,1] |
| [2,3,1,4,5,6] | [3,5,1,4,6,2] | [2,3,1,4,5,6] |
| [1,3,5,2,4,6] | [3,5,1,4,6,2] | [1,3,5,2,4,6] |

## የእውነተኛ V ማረጋገጫ

`discovery11_witness_test.v` ከproduction በተለየ የlegacy dispatcher እውነተኛ ጥሪ ይፈትሻል። `discovery11_expected_red_test.v` አራቱ የቀድሞ assertions አልተቀየሩም፣ ከPATCH 11 በኋላ GREEN መሆን አለባቸው። `patch11_test.v` ለ720 የተለያዩ የላች ቅደም ተከተሎች እና ለተመረጡ ቅደም ተከተሎች 12 የሙሉ ብስለቶች፣ 512-ቢት የተፈረሙ ግቤቶች፣ የማይቀየሩ ግቤቶችና የታሪክ ውጤቶች ይከራከራል።

```text
v fmt -verify ./pastafari
v test ./pastafari/discovery11_witness_test.v
v -check ./pastafari/discovery11_expected_red_test.v
v test ./pastafari/discovery11_expected_red_test.v
v test ./pastafari/patch11_test.v
v test ./pastafari
```

የማረጋገጫ መስፈርት 34/34 GREEN የፈተና ፋይሎች ነው። `LAST_COMPLETED_STAGE=22` እስከ CI መጨረሻ ይቆያል። የ46 ጠብታዎች ሙሉ ሰንሰለት ገና አልተገነባም፤ በዚህ ደረጃ የpost-stir ንዑስ መንገድ ብቻ ተረጋግጧል። ደረጃ 24 አልተጀመረም።
