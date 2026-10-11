# ደረጃ 8/55 — DISCOVERY 04 (EXPECTED_RED)

## የአምስት ድንጋዮች ታሪካዊ ስህተት

የታሪካዊው `mutate_stones_wrong(i, S)` የቀድሞውን `S` እንደ አንድ snapshot አይጠቀምም፤ `w,b,s,m,r` በአንድ የሚቀየር ሁኔታ ላይ በተከታታይ ይጻፋሉ።

```text
S.w = SAVE(S.w*S.w + 3*S.b + i)
S.b = SAVE(S.b*S.b + 5*S.s + S.w)
S.s = SAVE(S.s*S.s + 7*S.m + S.b)
S.m = SAVE(S.m*S.m + 11*S.r + S.s)
S.r = SAVE(S.r*S.r + 13*S.w + S.m)
```

`SAVE` በተጠገነው `calendar_save_spaghetti` ነው። ሌሎቹ `old_distance`፣ `old_day_tag` እና ታሪካዊ `old_remainder` አይቀየሩም።

## የድንጋይ 2 ምስክር

| ድንጋይ | ለsnapshot ትክክለኛው | የታሪካዊው |
|---|---:|---:|
| w | 378 | 378 |
| b | 1073 | 1434 |
| s | 2375 | 3780 |
| m | 6195 | 9932 |
| r | 10493 | 25047 |

አራት `EXPECTED_RED` ሙከራዎች የ`b,s,m,r` ትክክለኛ እሴቶችን ይጠይቃሉ። `w` ግን ሁለቱም መንገዶች የሚስማሙበት የGREEN መቆጣጠሪያ ነው።

## ትክክለኛ የታሪክ መስመር

`Stones` → `mutate_stones_wrong` → `LegacyStonesAdapter` → `BaseDispatcher.dispatch_legacy_stones` → `calendar_stones_spaghetti`። የ46 ድንጋዮች የታሪክ ሰንጠረዥ `get_legacy_stone_table` ላይ በተለየ ክፍል ይገነባል። `calendar_date_spaghetti` የድንጋይ 2 ውጤትን እንደ ምርመራ ብቻ ያሳያል፤ ሙሉ ቀን አይመልስም።

## የማረጋገጫ አስፈላጊ ትእዛዞች

```text
v fmt -verify ./pastafari
v test ./pastafari/normative_oracle_test.v
v test ./pastafari/discovery01_witness_test.v
v test ./pastafari/discovery01_expected_red_test.v
v test ./pastafari/patch01_test.v
v test ./pastafari/discovery02_witness_test.v
v test ./pastafari/discovery02_expected_red_test.v
v test ./pastafari/patch02_test.v
v test ./pastafari/discovery03_witness_test.v
v test ./pastafari/discovery03_expected_red_test.v
v test ./pastafari/patch03_test.v
v test ./pastafari/discovery04_witness_test.v
v -check ./pastafari/discovery04_expected_red_test.v
v test ./pastafari/discovery04_expected_red_test.v
```

መጨረሻው `v test` ብቻ በሆን ተብሎ 4 የassertion ውድቀቶችን ማሳየት አለበት። ከእሱ በፊት ያሉት 11 የሙከራ ፋይሎች PASS መሆን አለባቸው። `PATCH 04` አይጨመርም፣ ደረጃ 9 አይጀመርም። የV እውነተኛ CI ከተረጋገጠ በኋላ ብቻ `LAST_COMPLETED_STAGE=8` ይሆናል።
