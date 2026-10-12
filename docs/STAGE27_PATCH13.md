# ደረጃ 27/55 — PATCH 13 (native CI በመጠባበቅ ላይ)

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
LAST_COMPLETED_STAGE=26 እስከ native CI PASS ድረስ ይቆያል።
