# ደረጃ 21/55 — PATCH 10 (COMPLETE / GREEN)

## የታሪክ ስህተት ተጠብቋል

`old_stir_bowls_in_place` በተሰጠው `bowls` ሰልፍ ውስጥ `bowls[id]` ወዲያውኑ ይጽፋል። በቀጣዮቹ ቦታዎች `prev` እና `next` የተለወጡ እሴቶችን ሊያነቡ ይችላሉ። ይህን ተግባር፣ `LegacyBowlStirAdapter` እና `BaseDispatcher.dispatch_legacy_bowl_stir` አልቀየርናቸውም። በ`BowlStirPatch10` ውስጥ የታሪክ መንገዱ በእውነት ይጠራል፣ የተበከለው ውጤት ግን ለproduction አይጠቀምም።

## የ`vaultOld / pending / commit` ቅደም ተከተል

```text
vaultOld = deepClone(B)
pending = deepClone(B)
legacyGarbage = dispatchLegacyBowlStir(i, drop, stones, vaultOld, order, pours)

for position = 1..6:
    id = order[position]
    prev = order[wrap1(position-1,6)]
    next = order[wrap1(position+1,6)]
    s = vaultOld[id] + 2*vaultOld[prev] + 3*vaultOld[next]
      + pours[position] + drop + stoneByPosition[position]
    pending[id] = SAVE(s*s + 5*vaultOld[prev]*vaultOld[next] + i*position)

committed = deepClone(vaultOld)
for id = 1..6:
    committed[id] = deepClone(pending[id])
return committed
```

ሁሉም ስድስት የሂሳብ ንባቦች ከ`vaultOld` ብቻ ይመጣሉ፤ `pending` ከሌሎች ቦታዎች የሂሳብ ስሌት ጋር አይጋራም። የ`legacyGarbage` ሰልፍ በራሱ የማስታወሻ መንገድ ላይ ብቻ ይቀራል። የ`committed` ሰልፍ የመጨረሻ ጽሑፍ ብቻ ነው።

## የትክክለኛነት ምስክሮች

| የቅደም ተከተል | የጎድጓዳ ሳህን | legacy | PATCH 10 |
|---|---:|---:|---:|
| [1,2,3,4,5,6] | 2 | 96572653728 | 564002 |
| [1,2,3,4,5,6] | 6 | 45533754091847225581732030291798637831 | 46187 |
| [6,5,4,3,2,1] | 5 | 10647586499598 | 3180402 |
| [2,3,1,4,5,6] | 3 | 532048406068 | 1021102 |

`discovery10_expected_red_test.v` የነበሩት አራት RED assertions ሳይቀየሩ GREEN መሆን አለባቸው። `discovery10_witness_test.v` የታሪክ ጉድለትን በlegacy dispatcher በቀጥታ ይፈትሻል። `patch10_test.v` ለ720 ቅደም ተከተሎች የተለየ የold snapshot ምስክር፣ ትልቅ 420-ቢት ግቤቶችን፣ ተደጋጋሚ ጥሪዎችን፣ የቀድሞ መጠገኛዎችን እና ሕገወጥ ግቤቶችን ይፈትሻል።

```text
v fmt -verify ./pastafari
v test ./pastafari/discovery10_witness_test.v
v -check ./pastafari/discovery10_expected_red_test.v
v test ./pastafari/discovery10_expected_red_test.v
v test ./pastafari/patch10_test.v
v test ./pastafari
```

የተጠበቀው የV 0.5.2 ማረጋገጫ **31/31 PASS** ነው። እስከ የnative CI ማረጋገጫ `LAST_COMPLETED_STAGE=21` ነው። ደረጃ 22 አልተጀመረም።

## የተረጋገጠ የnative V ማስረጃ

- የተፈተነው commit፦ `a5960112321d69da2e7643ab99783cf3af91f25d`
- GitHub Actions፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38258828731
- የማስረጃ ቅርስ፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38258828731/artifacts/11751721580
- `V 0.5.2 7647ce1`፦ `v fmt -verify ./pastafari` PASS፣ `v test ./pastafari` **31/31 PASS**።
- የ`discovery10_expected_red_test.v` አራት assertions ሳይቀየሩ GREEN ሆነዋል።
- የ720 የቅደም ተከተሎች፣ የ420-ቢት ግቤቶች፣ የlegacy ስህተት ጥሪ፣ እና የተለየ `vaultOld/pending` መስመር ተረጋግጠዋል።
- ደረጃ 22 — `DISCOVERY 11` አልተጀመረም።

**ደረጃ 21 COMPLETE / GREEN።**
