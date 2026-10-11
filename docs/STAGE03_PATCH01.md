# ደረጃ 3/55 — PATCH 01 (የV እውነተኛ ማረጋገጫ ይጠበቃል)

የደረጃ 2 እውነተኛ የV `EXPECTED_RED` ማስረጃ በ[run 38153202920](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38153202920) እና commit `7bad2b66cb4ccb8bb25daec79d8600cf547800f8` ተይዟል።

## ተለያዩ መንገዶች

1. `old_remainder(x)` የታሪካዊ ቀሪውን `x mod M` ይመልሳል።
2. `BaseDispatcher.dispatch_legacy_save(x)` ወደ ቀድሞው `LegacyRemainderAdapter` በቀጥታ ይደርሳል።
3. `BaseDispatcher.dispatch_save_patch01(x)` በቅድሚያ legacy ያስኬዳል፤ ከዚያ `SavePatch01` ሲሆን ዜሮን ብቻ ወደ M ይቀይራል።
4. `calendar_save_spaghetti(x)` የተጠገነውን dispatcher ይጠራል።
5. `calendar_date_spaghetti(c,t)` በbootstrap በኋላ ይህን መንገድ ይጠራል፣ ነገር ግን የሙሉ ቀን ልወጣ ገና የለም።

## የሒሳብ ማረጋገጫ

`M = 2^127 - 1`። ለሁሉም የተለያዩ ኢንቲጀሮች `x` እና `r=regularMod(x,M)`፦

`SAVE(x) = M` ከሆነ `r=0`፤ ከዚያ ውጭ `SAVE(x)=r`።
ይህ ከ`1+regularMod(x-1,M)` ጋር ለሁሉም የምልክት ሁኔታዎች እኩል ነው።

## የመዝጊያ ፈተናዎች

```text
v fmt -verify ./pastafari
v test ./pastafari/normative_oracle_test.v
v test ./pastafari/discovery01_witness_test.v
v test ./pastafari/discovery01_expected_red_test.v
v test ./pastafari/patch01_test.v
v test ./pastafari
```

ሁሉም 0 መመለስ አለባቸው። በደረጃ 2 RED የነበሩት ሶስቱ `assert` ሙከራዎች በደረጃ 3 ያለ አካል ለውጥ GREEN መሆን አለባቸው። የ`old_remainder` ታሪካዊ ስህተት አሁንም በwitness ሙከራ ይታያል።

የV 0.5.2 ቀጥተኛ CI፦ `.github/workflows/canonical-names-lock.yml` ውስጥ የ`stage03_native_v` job። ማረጋገጫ ከመሳካቱ በፊት `LAST_COMPLETED_STAGE=2` ይቆያል።
