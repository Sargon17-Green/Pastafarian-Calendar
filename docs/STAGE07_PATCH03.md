# ደረጃ 7/55 — PATCH 03 (COMPLETE / GREEN)

## የታሪክ መመሪያ

የሦስተኛው የታሪካዊ ስህተት ስሌት `old_distance(c,t)` በ`pastafari/legacy_distance.v` ውስጥ የቀድሞውን መልክ ይይዛል። ይህ የተሳሳተ ስሌት ከታረመው dayTag መንገድ ርቀት ይወስዳል።

```text
legacy = oldDistance(c,t)
chronological = abs(t-c)
if legacy != chronological:
    legacy = chronological
distance = legacy + 1
```

`if` ቅርንጫፉ የታሪክ ጠባሳ ስለሆነ አይጠፋም። ስህተቱ `old_distance` ውስጥ አይጠገንም፤ ከእሱ በላይ `DistancePatch03.apply` ይሠራል።

## የproduction መስመር

`LegacyDistanceAdapter` → `BaseDispatcher.dispatch_legacy_distance` → `DistancePatch03.apply` → `BaseDispatcher.dispatch_distance_patch03` → `calendar_distance_spaghetti`። የ`calendar_date_spaghetti` የምርመራ መልዕክት ሁለቱንም `DISCOVERY_03 oldDistance` እና `PATCH_03 distance` ያሳያል።

## የፈተና መዝጊያ

```text
v fmt -verify ./pastafari
v -check ./pastafari/discovery03_expected_red_test.v
v test ./pastafari/discovery03_expected_red_test.v
v test ./pastafari/discovery03_witness_test.v
v test ./pastafari/patch03_test.v
v test ./pastafari
```

ሁሉም `exit=0` መመለስ አለባቸው፤ የመጨረሻው ሙሉ ስብስብ 10/10 PASS መሆን አለበት። የPATCH 01 እና PATCH 02 ውጤቶች አልተለወጡም፣ የስም ካታሎጉም የተቀዘቀዘ ነው። `PATCH 04` ወይም የደረጃ 8 ስራ አይገባም።

የደረጃ 6 የRED ማስረጃ፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38157358354

የV 0.5.2 የCI ማረጋገጫ PASS ነው፤ `LAST_COMPLETED_STAGE=7`።

## የአገርኛ V የመጨረሻ ማረጋገጫ

- የተፈተነው commit፦ `0755353e8cd776480d538261b777b2a2289b571d`
- የGitHub Actions ሙከራ፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38158404538
- የማስረጃ ቅርስ፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38158404538/artifacts/11709132166
- `V 0.5.2 7647ce1`፤ `v fmt -verify` PASS፤ `v test ./pastafari` 10/10 PASS።
- የደረጃ 6 አራት የRED assertions ሳይለወጡ GREEN ሆነዋል።
- የlegacy እሴት `old_distance` ያለ ለውጥ ይኖራል። `DistancePatch03` ከdispatcher በኋላ በproduction መስመር እውነት ይሠራል።

**ደረጃ 7 COMPLETE / GREEN። ደረጃ 8 አልተጀመረም።**
