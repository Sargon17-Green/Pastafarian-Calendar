# ደረጃ 17/55 — PATCH 08 (የGREEN ማረጋገጫ ይጠበቃል)

## የታሪክ ስህተቱ እንዳይጠፋ

`old_permutation_unrank0(rank0)` የ0..719 ደረጃዎችን ለስድስቱ ጎድጓዳ ሳህኖች በትክክል ይፈታል። `LegacyPermutationAdapter.order_for_drop` ግን `one_based` በቀጥታ ወደ ዜሮ-መሠረት መፍቻ እንደሚልክ ሆኖ ይቀራል። የታሪክ መንገድ የሚጠራው `BaseDispatcher.dispatch_legacy_permutation` ውስጥ ነው፤ የደረጃ 16 ምስክሮች አሁንም በቀጥታ ይህን መንገድ ይፈትሻሉ።

## ትክክለኛው ባለ-ሶስት-እርምጃ ሰንሰለት

```text
oneBased = regularMod(drop-1,720)+1
legacyRank0 = oneBased-1
order = oldPermutationUnrank0(legacyRank0)
```

`PermutationPatch08.legacy_rank0(drop)` በ`BigInt` ሂሳብ ላይ የሚሠራውን የቀሪ ደረጃ ይወስናል። `PermutationPatch08.order_for_drop` የታሪክ መፍቻውን ያለ ተጨማሪ የቅደም ተከተል ሕግ ይጠራል። `BaseDispatcher.dispatch_permutation_patch08` ከ`calendar_bowl_order_spaghetti` ተጠርቶ ወደዚያው wrapper ይደርሳል። የቀድሞው ታሪካዊ ስህተት ከproduction ውጭ ግን ይገኛል።

| drop | የታሪክ ውጤት | የPATCH 08 ውጤት |
|---:|---|---|
| 1 | [1,2,3,4,6,5] | [1,2,3,4,5,6] |
| 2 | [1,2,3,5,4,6] | [1,2,3,4,6,5] |
| 719 | [6,5,4,3,2,1] | [6,5,4,3,1,2] |
| 720 | error | [6,5,4,3,2,1] |

## የማረጋገጫ ስፋት

`discovery08_expected_red_test.v` ውስጥ የነበሩት አራት RED assertions በደረጃ 17 GREEN መሆን አለባቸው፤ ፈተናው አይለወጥም። `discovery08_witness_test.v` የቀድሞውን ጉድለት በlegacy dispatcher በቀጥታ ለይቶ ያረጋግጣል። አዲሱ `patch08_test.v` 720 የተለያዩ ቅደም ተከተሎች፣ እንደ 720 ጊዜ የሚደጋገም ደረጃ፣ አሉታዊ እና በ420-ቢት ሂሳብ የሚገኙ የጠብታ እሴቶች፣ ተደጋጋሚ ጥሪዎችን፣ የታሪክ ስህተትንና የምርመራ መልዕክቱን ይፈትሻል።

```text
v fmt -verify ./pastafari
v test ./pastafari/discovery08_witness_test.v
v -check ./pastafari/discovery08_expected_red_test.v
v test ./pastafari/discovery08_expected_red_test.v
v test ./pastafari/patch08_test.v
v test ./pastafari
```

የV 0.5.2 ሙሉ መመዘኛ **25/25 PASS** ነው። `LAST_COMPLETED_STAGE=16` እስከ CI ማረጋገጫ ይቆያል። `DISCOVERY 09` የደረጃ 18 ሥራ አይጀመርም።
