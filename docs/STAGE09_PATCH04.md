# ደረጃ 9/55 — PATCH 04 (COMPLETE / GREEN)

## የታሪክ ጠባሳ መጠበቅ

`mutate_stones_wrong(i, mut stones)` አምስቱን መስኮች `w,b,s,m,r` በተከታታይ ያሻሽላል፤ በproduction ላይ ሳይጠገን ተጠብቋል። አዲሱ `StonePatch04` የሚከተለውን የታሪክ ውል በትክክል ይፈጽማል፦

```text
old = clone(S)
garbage = mutateStonesWrong(i, clone(S))
garbage.w = SAVE(old.w*old.w + 3*old.b + i)
garbage.b = SAVE(old.b*old.b + 5*old.s + old.w)
garbage.s = SAVE(old.s*old.s + 7*old.m + old.b)
garbage.m = SAVE(old.m*old.m + 11*old.r + old.s)
garbage.r = SAVE(old.r*old.r + 13*old.w + old.m)
return garbage
```

የlegacy ጥሪው አይሰረዝም። ከ`old` ውጭ ያለ አዲስ መስክ በማንኛውም የPATCH 04 አባል ሂሳብ ላይ አይነበብም። `SAVE` በ`calendar_save_spaghetti` ይሠራል።

## የሁለተኛው ድንጋይ መመዘኛ

| ድንጋይ | የታሪክ ውጤት | የPATCH 04 ውጤት |
|---|---:|---:|
| w | 378 | 378 |
| b | 1434 | 1073 |
| s | 3780 | 2375 |
| m | 9932 | 6195 |
| r | 25047 | 10493 |

`discovery04_expected_red_test.v` ውስጥ የነበሩት አራት `assert` ጽሑፎች አይቀየሩም፤ የPATCH 04 ውጤት ሲመለስ GREEN መሆን አለባቸው። `discovery04_witness_test.v` የታሪካዊ ውጤትን በ`BaseDispatcher.dispatch_legacy_stones` በቀጥታ ይመረምራል።

## ከፍተኛ የሂሳብ ፈተናዎች

`patch04_test.v` ለአምስቱ መስኮች በተለየ የሙከራ ሂሳብ ይፈትሻል፤ በ2,3,17,46 መለያዎች፣ 384-ቢት የሙከራ ግቤቶች፣ አሉታዊ እና ዜሮ እሴቶች፣ የተደጋጋሚ ጥሪ ጽናት እና 46 የተጠገኑ ድንጋዮች ሰንጠረዥ ይካተታሉ። `get_legacy_stone_table` አይቀየርም።

```text
v fmt -verify ./pastafari
v -check ./pastafari/discovery04_expected_red_test.v
v test ./pastafari/discovery04_expected_red_test.v
v test ./pastafari/discovery04_witness_test.v
v test ./pastafari/patch04_test.v
v test ./pastafari
```

ሙሉ `v test ./pastafari` 13/13 PASS መሆን አለበት። የCI መስመር `.github/workflows/canonical-names-lock.yml` ውስጥ `stage09_native_v` ነው። የV 0.5.2 የCI ማረጋገጫ PASS ነው፤ `LAST_COMPLETED_STAGE=9`።

**ደረጃ 10 የDISCOVERY 05 ነው፤ እዚህ አይጀመርም።**

## የተረጋገጠ የመጨረሻ ማስረጃ

- የተፈተነ commit፦ `0d2a08d992944ec5db2b76da6e745703db686cf7`
- GitHub Actions፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38162967481
- የማስረጃ ቅርስ፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38162967481/artifacts/11711370337
- `V 0.5.2 7647ce1`፤ `v fmt -verify ./pastafari` PASS፤ `v test ./pastafari` 13/13 PASS።
- አራቱ የደረጃ 8 ኖርማቲቭ assertions በማንኛውም ለውጥ ሳይጋለጡ GREEN ሆነዋል።
- `mutate_stones_wrong` እና የlegacy 46-ድንጋይ ሰንጠረዥ እንዳሉ ተጠብቀዋል።
- `PATCH 05` አልተጨመረም፣ ደረጃ 10 አልተጀመረም።

**ደረጃ 9 COMPLETE / GREEN ነው።**
