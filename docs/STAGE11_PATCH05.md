# ደረጃ 11/55 — PATCH 05 (የGREEN ማረጋገጫ ይጠበቃል)

## የታሪካዊው የማከማቻ ቅደም ተከተል

በ`build_hidden_with_backward_storage` የሚወጣው ሰባት-አባል ሰንጠረዥ ሁልጊዜ `hidden7 … hidden1` በሚለው ተቃራኒ ቅደም ተከተል ይቀራል። `old_hidden_slot(backward,k)` እንደታሪክ ስህተት በ`backward[k-1]` ያነባል። ይህ ፋንክሽን እና የማከማቻው ገንቢ አይቀየሩም።

## በማንበብ ላይ ብቻ የሚደረግ መጠገኛ

```text
hiddenByNearness(backward, k) = backward[8-k]   # አንድ-መሠረት
HiddenPatch05.by_nearness(backward, k) = backward[7-k]   # የV ዜሮ-መሠረት
```

`calendar_hidden_by_nearness` በ`BaseDispatcher.dispatch_hidden_patch05` በኩል ይደርሳል። `old_hidden_slot` የተለየ የታሪክ ማስረጃ ነው፤ `calendar_hidden_spaghetti` ደግሞ ሁሌ የተገላቢጦሹን አካላዊ ሰንጠረዥ ብቻ ይመልሳል። የ`calendar_date_spaghetti` የምርመራ መልዕክት ሁለቱን የሚለዩ እሴቶች ያሳያል።

## የትክክለኛነት መመዘኛ

| ሎጂካዊ መጠይቅ | የታሪካዊው ንባብ | የPATCH 05 ንባብ |
|---|---|---|
| 1 | hidden7 | hidden1 |
| 2 | hidden6 | hidden2 |
| 3 | hidden5 | hidden3 |
| 4 | hidden4 | hidden4 |
| 5 | hidden3 | hidden5 |
| 6 | hidden2 | hidden6 |
| 7 | hidden1 | hidden7 |

`pastafari/discovery05_expected_red_test.v` ውስጥ የነበሩ አራት RED assertions ሳይቀየሩ GREEN መሆን አለባቸው። `discovery05_witness_test.v` ውስጥ የነበሩት ታሪካዊ የማከማቻ ምስክሮችም GREEN ይቆያሉ።

`pastafari/patch05_test.v` ሰባቱን ትክክለኛ እሴቶች፣ የተለያዩ የsynthetic እሴቶች፣ ቀናትን በFOUNDATION ዙሪያ፣ ትልቅ 290-ቢት ርቀትን፣ ግቤት ባለቤትነትን፣ የlegacy ንባብን እና የቀደሙ መጠገኛዎችን ይፈትሻል።

## የእውነተኛው V ሙከራ

```text
v fmt -verify ./pastafari
v test ./pastafari/discovery05_witness_test.v
v -check ./pastafari/discovery05_expected_red_test.v
v test ./pastafari/discovery05_expected_red_test.v
v test ./pastafari/patch05_test.v
v test ./pastafari
```

የሙሉ ስብስብ መመዘኛ 16/16 PASS ነው። የV ማረጋገጫ እስኪሳካ `LAST_COMPLETED_STAGE=10` ይቆያል። ደረጃ 12 ወደ ሌላ ውይይት ብቻ ይቀጥላል።
