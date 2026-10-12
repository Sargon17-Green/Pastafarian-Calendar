# ደረጃ 13/55 — PATCH 06 (የGREEN ማረጋገጫ ይጠበቃል)

## ሊቀየር የማይገባው ታሪካዊ ክፍል

`legacy_prior(drop_store,i,back)` በታሪካዊው `i-back` ማውጫ የሚታዩትን ጠብታዎች ብቻ ይፈልጋል፤ ከ`slot<1` ምንም አያነብም። `LegacyPriorAdapter` እና `BaseDispatcher.dispatch_legacy_prior` ሳይቀየሩ ይቀራሉ።

## የPATCH 06 ሁለት የንባብ መስመሮች

```text
slot = i-back
if slot >= 1:
    return BaseDispatcher.dispatch_legacy_prior(drop_store,i,back)
hidden_k = 1-slot
return calendar_hidden_by_nearness(legacy_hidden,hidden_k)
```

`hidden_k` ከ1 እስከ7 ብቻ ነው፤ `slot=-7` እና ከዚያ በታች ከሆነ የV `!BigInt` error በማስተዋል ይመለሳል። የቀድሞ የhidden ሰባት-አባል ሰንጠረዥ አሁንም `hidden7 … hidden1` በተገላቢጦሽ ይከማቻል። `HiddenPatch05` የማውጫ አሰራር `7-k` በዜሮ-መሠረት ይሠራል።

| slot | የproduction መስመር | የሚመለሰው |
|---:|---|---|
| 3 | የታሪክ መንገድ | visible3 |
| 1 | የታሪክ መንገድ | visible1 |
| 0 | የስውር መንገድ | hidden1 |
| -1 | የስውር መንገድ | hidden2 |
| -2 | የስውር መንገድ | hidden3 |
| -6 | የስውር መንገድ | hidden7 |

## የማይለወጡ ፈተናዎች

`discovery06_expected_red_test.v` የደረጃ 12 አራት RED assertions እንደነበሩ ይቀራሉ፤ በደረጃ 13 GREEN መሆን አለባቸው። `discovery06_witness_test.v` ታሪካዊውን የሚታወቀውን ስህተት በlegacy dispatcher በቀጥታ ይፈትሻል። `patch06_test.v` ሰባቱን hidden offsets፣ አዎንታዊ የታሪክ ሰልፎችን፣ ሰው ሠራሽ የhidden እሴቶችን፣ የስህተት ወሰኖችንና የቀድሞ መጠገኛዎችን ይፈትሻል።

```text
v fmt -verify ./pastafari
v test ./pastafari/discovery06_witness_test.v
v -check ./pastafari/discovery06_expected_red_test.v
v test ./pastafari/discovery06_expected_red_test.v
v test ./pastafari/patch06_test.v
v test ./pastafari
```

የV 0.5.2 አጠቃላይ ማረጋገጫ 19/19 PASS መሆን አለበት። `LAST_COMPLETED_STAGE=12` እስከ CI ማረጋገጫ ይቆያል። ደረጃ 14 — `DISCOVERY 07` አይጀመርም።
