# ደረጃ 25/55 — PATCH 12 (COMPLETE / GREEN)

## የታሪክ ጉድለትን ሳያጠፋ የትክክለኛው ቀጣይ ቦውል ምርጫ

`old_next_bowl_fixed_name(id)` የታሪክ `(id % 6)+1` ሂሳብ እንደነበረ ይቀራል። `LegacyNextBowlAdapter` እና `BaseDispatcher.dispatch_legacy_next_bowl` በPATCH 12 ውስጥ አልተለወጡም። አዲሱ `NextBowlPatch12` በየquery ጥሪው የቀድሞውን `orderAt46Latch` በ`PostStirPatch11.latch_order_at_46` አረጋግጦ በቅጂ ይይዛል። የታሪኩ የfixed-ID ውጤት እውነተኛ የlegacy ጥሪ እንዳለ ይቆያል።

## በላች ውስጥ circular successor

```text
latch=cloneAndValidate(orderAt46Latch)
legacyDiagnostic=dispatchLegacyNextBowl(queriedId,latch)
position=indexOf(latch,queriedId)
if position missing: error
return latch[(position+1) mod 6]
```

ይህ ትክክለኛው ህግ በቋሚ የID ቅደም ተከተል አይመሰረትም። በ6ኛው position ካለ ወደ1ኛው ይመለሳል። የ`calendar_post_stir_next_bowl_spaghetti` መንገድ ከPATCH 11 የ12 post-stirs የተላከውን ላች በትክክል ይጠቀማል።

| የላች ቅደም ተከተል | queriedId | የታሪክ መልስ | PATCH 12 |
|---|---:|---:|---:|
| [6,5,4,3,2,1] | 6 | 1 | 5 |
| [6,5,4,3,2,1] | 1 | 2 | 6 |
| [2,3,1,4,5,6] | 3 | 4 | 1 |
| [1,3,5,2,4,6] | 1 | 2 | 3 |

## የnative V ማረጋገጫ

`discovery12_witness_test.v` የታሪክ ልዩነትን በlegacy መንገድ በቀጥታ ይፈትሻል። `discovery12_expected_red_test.v` በደረጃ 24 የነበሩት አራት RED assertions ሳይቀየሩ GREEN መሆን አለባቸው። አዲሱ `patch12_test.v` 9 ፈተናዎች ይይዛል፤ ከዚህ ውስጥ ሁሉንም 720 ቅደም ተከተሎችና ስድስቱን መለያዎች (4320 ጥምረቶች)፣ ከ12 post-stirs የሚመጣውን ላች፣ የማይቀየሩ ግቤቶችን፣ ማይሰሩ ቅደም ተከተሎችንና የlegacy ስህተትን ይፈትሻል።

```text
v fmt -verify ./pastafari
v test ./pastafari/discovery12_witness_test.v
v -check ./pastafari/discovery12_expected_red_test.v
v test ./pastafari/discovery12_expected_red_test.v
v test ./pastafari/patch12_test.v
v test ./pastafari
```

የGREEN መመዘኛው 37/37 የV ፈተና ፋይሎች ነው። የ`PATCH 13` ሥራ አልተጀመረም፣ የ46 ጠብታዎች ሙሉ ማስኬጃ ይቀራል። `LAST_COMPLETED_STAGE=25` የnative CI መመዘኛው እስኪሳካ ይቆያል።

## የመጨረሻ የnative V ማስረጃ

- የተፈተነ commit፦ `7f6783c1c4b42861a7ff050bf71f66b574ab5402`
- GitHub Actions፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38279265900
- የማስረጃ ቅርስ፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38279265900/artifacts/11760980342
- `V 0.5.2 7647ce1`፦ `v fmt -verify ./pastafari` PASS፣ `v test ./pastafari` **37/37 PASS**።
- አራቱ የደረጃ 24 RED assertions ሳይቀየሩ GREEN ሆነዋል።
- 720 የላች ቅደም ተከተሎች × 6 መለያዎች = 4320 የcircular successor ምርጫዎች ተፈትሸዋል።
- `old_next_bowl_fixed_name` አሁንም በቋሚ ID ላይ ተመስርቶ ይመልሳል፤ የproduction መንገድ ግን ከ`orderAt46Latch` ይወስናል።
- ደረጃ 26 — `DISCOVERY 13` አልተጀመረም።

**ደረጃ 25 COMPLETE / GREEN።**
