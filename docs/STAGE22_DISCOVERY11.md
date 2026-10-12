# ደረጃ 22/55 — DISCOVERY 11 (COMPLETE / EXPECTED_RED)

## የታሪክ ጉድለቱ

ከ46ኛው ጠብታ የሚመጣው የስድስቱ ቦውሎች ቅደም ተከተል ለቀጣዩ query መቆየት አለበት። በታሪክ የLegacyPostStirOrderStore መያዣ ግን በ12 የpost-stir ዙሮች በተከታታይ ይደረሳል። ስለዚህ ለquery የሚመለሰው የ12ኛው post-stir ቅደም ተከተል ነው።

## የ12 ብስለቶች የሂሳብ ሕግ

ለstir=1..12 የስድስቱን አሮጌ እሴቶች ቅጂ ውሰድ። savedBowlSum=SAVE(sum(old[1..6])+149*stir) ሰላ። በPATCH 08 የታረመውን የ720 ቅደም ተከተል ይምረጥ። በየposition የቦውል id፣ prev እና next እንደ order ይምረጥ። ከold ብቻ s=old[id]+3*old[prev]+5*old[next]+savedBowlSum+stir+position² ሰላ። pending[id]=SAVE(s²+7*old[prev]*old[next]) ይጻፍ። ከስድስቱ በኋላ ወደ pending ተሸጋገር። የሂሳብ ሕጉ ትክክል ሆኖ ሳለ የquery_order መያዣ በየዙሩ ይደረሳል፤ የPATCH 11 latch ገና አልተጨመረም።

## የተለዩ ምስክሮች

ለ B=[10,20,30,40,50,60] የመጀመሪያው savedBowlSum=359 እና order=[3,6,5,4,1,2] ነው። የ12ኛው savedBowlSum=152983071395321360281688056688813299996 እና order=[3,5,1,4,6,2] ነው።

የአራቱ EXPECTED_RED ግቤቶች፦ [1,2,3,4,5,6]፣ [6,5,4,3,2,1]፣ [2,3,1,4,5,6] እና [1,3,5,2,4,6]። ለሁሉም አሁን የተሳሳተው [3,5,1,4,6,2] ይመለሳል። ለPATCH 11 መጠገኛ ግን የተሰጠው የ46ኛው ቅደም ተከተል ሳይቀየር መመለስ አለበት።

discovery11_witness_test.v የታሪክ 12 ዙሮችን፣ የአሮጌ መያዣ መደረስን፣ የ720 የመጀመሪያ ቅደም ተከተሎች ተቀባይነት፣ 412-ቢት ግቤቶችና አለመለወጥን ይፈትሻል። discovery11_expected_red_test.v አራት ሆን ብለው RED እና ሦስት GREEN ይይዛል። የቀድሞ 31 ፋይሎች ከአዲሱ witness ጋር 32 GREEN መሆን አለባቸው።

የcalendar_date_spaghetti የምርመራ ምሳሌ ከpour_drop=720 ይጀምራል፤ የ46 ጠብታዎች ሙሉ የመጨረሻ እሴት አይደለም። ይህ የተለየ ንዑስ መንገድ የorder መደረስ ጉድለትን ብቻ ያረጋግጣል። LAST_COMPLETED_STAGE=22 ነው።

## የnative V ማስረጃ

- የተፈተነ commit፦ c9d2c218259ce1d9fb4373ffc0e5070866c1db0e
- GitHub Actions፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38263332678
- artifact፦ https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38263332678/artifacts/11752704606
- V 0.5.2 7647ce1፦ v fmt -verify ./pastafari PASS፣ 32/32 GREEN witnesses PASS፣ 4 EXPECTED_RED assertions በተናጠል ተረጋግጠዋል።
- PATCH 11 አልተጨመረም፤ ደረጃ 23 አልተጀመረም።

**ደረጃ 22 COMPLETE / EXPECTED_RED።**
