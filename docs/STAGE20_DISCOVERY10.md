# ደረጃ 20/55 — DISCOVERY 10 (EXPECTED_RED)

## የስድስቱ ጎድጓዳ ሳህኖች የታሪክ የin-place ስህተት

`old_stir_bowls_in_place` የስድስቱን `order` ቦታዎች አንድ በአንድ ይዞራል። በየቦታው `id`፣ `prev_id`፣ `next_id` ይወስናል፣ ሂሳቡን በ`bowls` ላይ ይሰላል፣ ውጤቱንም ወዲያውኑ በዚያው `bowls[id]` ይጽፋል። የሁለተኛው ቦታ አንባቢ በመጀመሪያው ቦታ የተቀየረውን `prev` ያገኛል። ለሁሉም ስድስት ቦታዎች አንድ የቀድሞ ሁኔታ መሆን ያለበት ይህን ይጥሳል።

## ያልተቀየሩ የሂሳብ ሕጎች

```text
stoneByPosition = [WHEAT, BARLEY, SALT, BITTER, RED, WHEAT]
for position = 1..6:
    id = order[position]
    prev = order[wrap6(position-1)]
    next = order[wrap6(position+1)]
    s = bowls[id] + 2*bowls[prev] + 3*bowls[next]
      + pours[position] + drop + stoneByPosition[position]
    bowls[id] = SAVE(s*s + 5*bowls[prev]*bowls[next] + i*position)
```

የ`SAVE`፣ `PATCH 08` የቅደም ተከተል እና `PATCH 09` የalias ማፍሰሻ ሂሳብ አልተለወጡም። `LegacyBowlStirAdapter` የጠሪ ውሂብን ከቀድሞው የin-place ስህተት ለይቶ ይጠብቃል፣ ግን አሮጌው ስሌት በውስጡ ይከናወናል። `BaseDispatcher.dispatch_legacy_bowl_stir` → `calendar_stir_bowls_spaghetti` እውነተኛው የproduction ንዑስ መንገድ ነው።

## የተለዩ የማስረጃ ነጥቦች

ለ`i=1`፣ `drop=2`፣ `stones=[17,29,43,71,101]`፣ `B=[10,20,30,40,50,60]`፣ የ`PATCH 09` ማፍሰሻዎች እንደነበሩ ናቸው።

| የቅደም ተከተል | የጎድጓዳ ሳህን | የታሪክ in-place | ከአንድ old snapshot |
|---|---:|---:|---:|
| [1,2,3,4,5,6] | 1 | 154997 | 154997 |
| [1,2,3,4,5,6] | 2 | 96572653728 | 564002 |
| [1,2,3,4,5,6] | 6 | 45533754091847225581732030291798637831 | 46187 |
| [6,5,4,3,2,1] | 5 | 10647586499598 | 3180402 |
| [2,3,1,4,5,6] | 3 | 532048406068 | 1021102 |

## የV ፈተናዎች

`discovery10_witness_test.v` የታሪክ ውጤቶች፣ እውነተኛ በቦታ መጻፍ፣ የጠሪ ግቤቶች ሳይቀየሩ መቆየት፣ ስድስት የድንጋይ ምርጫዎች፣ ያልተፈቀዱ ግቤቶች፣ 380-ቢት ቁጥሮች፣ 720 ቅደም ተከተሎች እና በ`calendar_date_spaghetti` ውስጥ የታሪክ አሰራር ይፈትሻል። `discovery10_expected_red_test.v` አራት RED assertions እና ሶስት GREEN መቆጣጠሪያዎች አሉት።

```text
v fmt -verify ./pastafari
v test ./pastafari/discovery10_witness_test.v
v -check ./pastafari/discovery10_expected_red_test.v
v test ./pastafari/discovery10_expected_red_test.v
```

ከደረጃ 19 አጠቃላይ 28 የGREEN ፈተና ፋይሎች ጋር አዲሱ witness ተደምሮ **29/29 GREEN** መሆን አለበት። አራቱ RED assertions ሆን ብለው ይቀራሉ። `vaultOld` እና `pending` አልተጨመሩም፤ የ`PATCH 10` ሥራ እስከ ደረጃ 21 ይጠበቃል። `LAST_COMPLETED_STAGE=19` እስከ native V CI ማረጋገጫ ይቆያል።
