# ደረጃ 27/55 — PATCH 13 (COMPLETE / GREEN)

## የማስቀረት ሕግ
M=2^127−1። n ከ1 እስከ M መሆን አለበት።
limit=floor(M/n)*n በBigInt ይሰላል።
በተመሳሳይ AnswerStream ውስጥ k=0,1,... ብሎ
answerAt(k) ይነበባል። x>limit ከሆነ ይጣላል፤
x<=limit ሲሆን ብቻ dispatch_legacy_biased_pick(x,n)
በእውነት ይጠራል።

የold_biased_pick የታሪክ ስህተት እንዳለ ይቀራል።
calendar_choose_rank_short_spaghetti ወደ PATCH 13 ተያይዟል።
አራቱ የደረጃ 26 normative RED assertions ሳይቀየሩ
GREEN መሆን አለባቸው። የታሪክ witness
በlegacy dispatcher አሁንም የተሳሳተ መልስን ይፈትሻል።
n>M እና ሙሉ 46-drop chain ገና አልተሠሩም።

## የnative ማረጋገጫ
v fmt -verify ./pastafari
v test ./pastafari/discovery13_witness_test.v
v test ./pastafari/discovery13_expected_red_test.v
v test ./pastafari/patch13_test.v
v test ./pastafari

የሚጠበቀው 40/40 GREEN ፋይሎች ነው።
## የመጨረሻ native CI ማስረጃ

- የተፈተነ commit: 6327f34427499a049ad57be033bd571b443adb28
- GitHub Actions: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38284358707
- artifact ID: 11762587441
- V 0.5.2 7647ce1፦ v fmt -verify ./pastafari PASS።
- v test ./pastafari **40/40 test ፋይሎች PASS**።
- የደረጃ 26 አራቱ RED assertions ሳይቀየሩ GREEN ሆነዋል።
- Canonical Names Lock PASS።
- የold_biased_pick ታሪካዊ ፋይል SHA 1948c9fa6194461ad3b11b22a510133d76083338 አልተቀየረም።
- LAST_COMPLETED_STAGE=27፤ ደረጃ 28 ገና አልተጀመረም።

**ደረጃ 27 COMPLETE / GREEN።**
