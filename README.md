# የዘመናት ጥቅል — V እና አማርኛ

ይህ ማውጫ የV ፕሮግራሚንግ ቋንቋን እና አማርኛን እንደ ብቸኛ የሰው ምንጭ ቋንቋ የሚጠቀም ራሱን የቻለ አዲስ የትግበራ መስመር ነው። ይህ መስመር ከዜሮ ተጀምሯል፤ ከሌላ የፕሮግራም ቋንቋ አፈጻጸም ኮድ፣ ሙከራ፣ ቋሚ ውጤት፣ ማከማቻ፣ የተፈጠረ ሰንጠረዥ ወይም ጂብ አልተወሰደም።

## የዚህ ደረጃ ይዘት

የመጀመሪያው ደረጃ የሚያካትተው፦

- በV የተጻፈ የትክክለኛ ትልቅ ኢንቲጀር ድጋፍ፤
- 17 የቆራጭ ስሞችና 47 የወር ስሞች ያሉበት የተቀዘቀዘ `SourceLanguageCatalog`፤
- በV ብቻ የተጻፈ ለሙከራ ብቻ የሚጠቅም ንጹሕ ኖርማቲቭ ኦራክል፤
- የወደፊት ጉድለቶችን ወይም መጠገኛዎችን ያልያዘ መሠረታዊ `MonsterContext`፣ dispatcher፣ validator፣ error wrapper እና metrics shell፤
- ከተካተተው መግለጫ በቀጥታ የተገኙ የመነሻ ሙከራዎችና ቋሚ የሚጠበቁ እሴቶች።

የታሪካዊ 26 ጉድለቶች እና መጠገኛዎቻቸው በዚህ ደረጃ አልተጨመሩም። ዋናው `calendar_date_spaghetti` በዚህ ደረጃ የሚሰራ የመጨረሻ ካሌንደር መንገድ አይደለም፤ የታሪካዊ ግንባታው ሳይጀምር በግልጽ ስህተት ይቆማል።

## የደረጃ 1 የታሪክ ማረጋገጫ ትእዛዝ

```text
v test ./pastafari
```

የቅርጸት ማረጋገጫ፦

```text
v fmt -verify ./pastafari
```


ደረጃ 1 በV 0.5.2 (`7647ce1`) ተረጋግጧል። `v fmt -verify ./pastafari` እና `v test ./pastafari` ሁለቱም በውጤት 0 አልፈዋል፤ የሙከራው ማጠቃለያ 1 ከ1 ሙከራ እንዳለፈ ያሳያል። ይህ በደረጃ 1 መጨረሻ የነበረውን ሁኔታ ይገልጻል።

## ደረጃ 2 — DISCOVERY 01

የታሪካዊው `old_remainder` ጉድለት ከ`LegacyRemainderAdapter` እና ከproduction dispatcher ጋር ተገናኝቷል። የሙሉ ቀን ልወጣ ገና የለም። በM፣ 2M እና 3M የሚኖረው የታሰበ RED በ`pastafari/discovery01_expected_red_test.v` ውስጥ ተለይቶ ተጻፈ። ለመሥራት እና ለማረጋገጥ `docs/STAGE02_DISCOVERY01.md` ይመልከቱ። ደረጃ 2 በV 0.5.2 (7647ce1) በGitHub Actions run 38153202920 ተረጋግጧል፤ M, 2M, 3M ሆን ተብሎ RED ሲሆኑ ሌሎች ሙከራዎች GREEN ናቸው።

## ደረጃ 3 — PATCH 01

የታሪካዊው `old_remainder` ተጠብቋል፣ ከእሱም በላይ ራሱን የቻለ `SavePatch01` ተጨምሯል። `calendar_save_spaghetti` የተጠገነውን ምርጫ ያገኛል። የደረጃ 2 የRED ሙከራዎች ያለ `assert` ለውጥ GREEN መሆን አለባቸው። በV 0.5.2 (`7647ce1`) የrun `38153910238` ማረጋገጫ ተጠናቋል። የታሪካዊው witness፣ ቀድሞ RED የነበሩት assertions እና የተጨመሩ የPATCH 01 ፈተናዎች ሁሉ PASS ሆነዋል። ሙሉ የ`v test ./pastafari` ውጤት 4/4 PASS ነው፤ `LAST_COMPLETED_STAGE=3`።

## ደረጃ 4 — DISCOVERY 02

ሁለተኛው የታሪካዊ ስህተት `old_day_tag(day) = 2*abs(day-FOUNDATION)` በV ተጨምሯል። ከFOUNDATION ጀምሮ የአንድ የምንጠብቀው ልዩነት በሆን ተብሎ RED ሙከራዎች ተመዝግቧል። PATCH 01 ተጠብቋል፤ PATCH 02 ገና አልተጨመረም። ዝርዝር፦ `docs/STAGE04_DISCOVERY02.md`።

ደረጃ 4 በ`V 0.5.2 7647ce1` በGitHub Actions run `38155338854` ሙሉ የታሰበ `EXPECTED_RED` ማረጋገጫ አልፏል። 5 የአሮጌ/አዲስ GREEN የሙከራ ፋይሎች PASS ናቸው። የአራቱ የተጠበቁ ውድቀቶች ማስረጃ ተቀምጧል፤ `LAST_COMPLETED_STAGE=4`። አሁን `v test ./pastafari` ሙሉ በሙሉ GREEN መሆን የለበትም፤ የደረጃ 4 የታሰበው RED የፕሮጀክቱ ህጋዊ ሁኔታ ነው።

## ደረጃ 5 — PATCH 02

`old_day_tag` የቀድሞውን `2*abs(day-FOUNDATION)` ስህተት እንዳለ ይይዛል። አዲሱ `DayTagPatch02` በታሪካዊው dispatcher በኋላ ይጠራል፣ ከFOUNDATION ጀምሮ አንድ ይጨምራል እና የFOUNDATION መከላከያ ሁለተኛውን ቅርንጫፍ አያስወግድም። በደረጃ 4 የነበሩት አራት RED assertions አልተለወጡም፤ አሁን GREEN ሊሆኑ ይገባል። በV 0.5.2 (`7647ce1`) የGitHub Actions run `38156647121` ማረጋገጫ ተሳክቷል። `v test ./pastafari`: 7/7 PASS፤ የደረጃ 4 አራት RED assertions ያለ ለውጥ GREEN ሆነዋል። `LAST_COMPLETED_STAGE=5` ነው። ዝርዝር፦ `docs/STAGE05_PATCH02.md`።

## ደረጃ 6 — DISCOVERY 03

ሦስተኛው የታሪካዊ ስህተት `old_distance(c,t) = abs(dayTag(c)-dayTag(t))` ተጨምሯል። ትክክለኛው የቀን ርቀት `abs(t-c)+1` ነው። በአንድ ቀን፣ በሁለት ቀናት፣ በFOUNDATION ሁለት ጎኖች እና ከ256 ቢት በላይ ርቀት ሆን ተብሎ RED ሙከራዎች ተጨምረዋል። `PATCH 03` አልተጨመረም። V 0.5.2 (`7647ce1`) በGitHub Actions run `38157358354` ተፈትኗል፤ 8 የቀድሞ/አዲስ GREEN የሙከራ ፋይሎች PASS ናቸው፤ አራቱ የታሰቡ RED assertions በስም ተረጋግጠዋል። `LAST_COMPLETED_STAGE=6` ነው። ዝርዝር፦ `docs/STAGE06_DISCOVERY03.md`።

## ደረጃ 7 — PATCH 03

የስህተት መደበኛው ቅርጽ `old_distance(c,t) = abs(dayTag(c)-dayTag(t))` እንዳለ ተጠብቋል። አዲሱ `DistancePatch03` ከlegacy dispatcher የሚመጣውን እሴት ከ`abs(t-c)` ጋር ያወዳድራል፤ ሲለያዩ ብቻ ይተካዋል ከዚያም 1 ይጨምራል። በደረጃ 6 የነበሩት አራት RED assertions ሳይለወጡ GREEN መሆን አለባቸው። V 0.5.2 (`7647ce1`) በGitHub Actions run `38158404538` ተረጋግጧል፤ `v fmt -verify` PASS፣ ሙሉ `v test ./pastafari` 10/10 PASS። የደረጃ 6 አራት RED assertions ያለ ለውጥ GREEN ሆነዋል። `LAST_COMPLETED_STAGE=7` ነው። ዝርዝር፦ `docs/STAGE07_PATCH03.md`።

## ደረጃ 8 — DISCOVERY 04

`mutate_stones_wrong` አምስቱን ድንጋዮች በቅደም ተከተል `w,b,s,m,r` ያሻሽላል። የመጀመሪያው እሴት `17,29,43,71,101` ነው። ከድንጋይ 2 በኋላ የlegacy ውጤት `378,1434,3780,9932,25047` ነው። ከአሮጌው የጋራ snapshot የሚመጡ አራት የሙከራ ግምቶች በሆን ተብሎ RED ሆነው ይቆያሉ። `LegacyStonesAdapter` እና የታሪካዊው 46 ድንጋዮች ገንቢ ተጨምረዋል። `PATCH 04` አልተጨመረም። በV 0.5.2 (`7647ce1`) የGitHub Actions run `38160751813` የቅርጸት ፈተና፣ 11 የቀድሞ እና አዲስ GREEN የሙከራ ፋይሎች፣ እና በተለይ 4 የተጠበቁ RED assertions ተረጋግጠዋል። `LAST_COMPLETED_STAGE=8` ነው። ዝርዝር፦ `docs/STAGE08_DISCOVERY04.md`።

## ደረጃ 9 — PATCH 04

የታሪካዊው `mutate_stones_wrong` ያለ ለውጥ ተጠብቋል። አዲሱ `StonePatch04` መጀመሪያ የአምስት ድንጋዮችን snapshot ይወስዳል፣ በclone ላይ `mutate_stones_wrong` በእውነት ይጠራል፣ ከዚያም `w,b,s,m,r` ሙሉ ውጤትን በsnapshot እሴቶች ይደርሳል። `get_stone_table_through_legacy_builder` 46 የተጠገኑ ድንጋዮችን ይሰራል፤ የታሪካዊው `get_legacy_stone_table` አሁንም ይኖራል። የደረጃ 8 የRED ፈተናዎች ሳይለወጡ GREEN መሆን አለባቸው። V 0.5.2 (`7647ce1`) በGitHub Actions run `38162967481` ተረጋግጧል፤ `v fmt -verify` PASS እና `v test ./pastafari` 13/13 PASS። የደረጃ 8 አራት RED assertions ሳይቀየሩ GREEN ሆነዋል። `LAST_COMPLETED_STAGE=9` ነው። ዝርዝር፦ `docs/STAGE09_PATCH04.md`።

## ደረጃ 10 — DISCOVERY 05

ሰባቱ የተሰወሩ ጠብታዎች በትክክል ይሰላሉ፣ ግን `build_hidden_with_backward_storage` በአካላዊ ማከማቻ ውስጥ `hidden7, hidden6, …, hidden1` ብሎ በተቃራኒው ያስቀምጣቸዋል። `old_hidden_slot` እና `calendar_hidden_by_nearness` በዚህ ደረጃ ከማከማቻው በቀጥታ ያነባሉ፤ ስለዚህ ከመካከለኛው `hidden4` በስተቀር የቅርበት ትርጉም ስህተት አለ። አራት `EXPECTED_RED` ፈተናዎች ተጨምረዋል። `PATCH 05` አልተጨመረም። V 0.5.2 (`7647ce1`) በGitHub Actions run `38165059747` የቅርጸት ምርመራን፣ 14 የGREEN ሙከራ ፋይሎችን እና 4 የታሰቡ RED assertions በስም አረጋግጧል። `LAST_COMPLETED_STAGE=10` ነው። ዝርዝር፦ `docs/STAGE10_DISCOVERY05.md`።

## ደረጃ 11 — PATCH 05

ሰባቱ የhidden ጠብታዎች በታሪካዊው `hidden7 … hidden1` የማከማቻ ቅደም ተከተል እንዳሉ ይቀራሉ። `old_hidden_slot(backward,k)` የቀድሞውን `backward[k-1]` ስህተት ይይዛል። አዲሱ `HiddenPatch05` የቅርበት መጠይቅን በአንድ-መሠረት `8-k`፣ በV ዜሮ-መሠረት `7-k` ወደ የታሪክ ማከማቻ ቦታ ይለውጣል። የproduction `calendar_hidden_by_nearness` ከdispatcher በኩል ይሄዳል፣ የቀድሞ አራት RED assertions ሳይቀየሩ GREEN መሆን አለባቸው። V 0.5.2 (`7647ce1`) በGitHub Actions run `38166616826` ተረጋግጧል፤ `v fmt -verify` PASS፣ `v test ./pastafari` 16/16 PASS። የደረጃ 10 አራት RED assertions ሳይቀየሩ GREEN ሆነዋል። `LAST_COMPLETED_STAGE=11` ነው። ዝርዝር፦ `docs/STAGE11_PATCH05.md`።

## ደረጃ 12 — DISCOVERY 06

የታሪካዊው `legacy_prior(drop_store,i,back)` የሚጠቀመው `slot=i-back` እና በ1-መሠረት `drop_store[slot]` ብቻ ነው። የV አካላዊ ዜሮ ሰልፍ sentinel ነው፤ `slot<=0` ስለሆነ ምንም ታሪካዊ የሚታይ ጠብታ አይኖርም፣ የታሪክ መንገድም ስውር ጠብታን አያነብም። ከተሰባሰበው ሰንጠረዥ ውጭ የሆነ index የV ሂደትን እንዳያቋርጥ በerror ይወጣል። `calendar_prior_spaghetti` በደረጃ 12 ሆን ብሎ ይህን የታሪክ መንገድ ብቻ ይጠራል። አራት የታሰቡ RED assertions በ`slot=0,-1,-2,-6` ይለያሉ፤ ትክክለኛ የሚታዩ አዎንታዊ slots ግን GREEN ናቸው። `PATCH 06` አልተጨመረም፣ የV 0.5.2 (`7647ce1`) ቀጥተኛ ማረጋገጫ በGitHub Actions run `38222220614` ላይ PASS ሆኗል። 17 የቀድሞ እና አዲስ የGREEN ፈተና ፋይሎች PASS ናቸው፤ 4 ስማቸው የተመዘገበ የRED assertions በሆን ተብለው ተረጋግጠዋል። `LAST_COMPLETED_STAGE=12` ነው። ዝርዝር፦ `docs/STAGE12_DISCOVERY06.md`።

## ደረጃ 13 — PATCH 06

የታሪካዊው `legacy_prior(drop_store,i,back)` በትክክል ያለውን በሚታዩ ጠብታዎች ብቻ የሚያነብ ስህተት እንዳለ ይቆያል። አዲሱ `PriorPatch06` የ`slot=i-back` ሁኔታን ያያል። `slot>=1` ከሆነ `BaseDispatcher.dispatch_legacy_prior` በእውነት ይጠራል፤ ካልሆነ `hidden_k=1-slot` በሚለው የአንድ-መሠረት የቅርበት አመልካች በ`calendar_hidden_by_nearness` በኩል ይመለሳል። የደረጃ 12 አራት RED assertions ሳይቀየሩ GREEN መሆን አለባቸው። V 0.5.2 (`7647ce1`) በGitHub Actions run `38223816213` ተረጋግጧል፤ `v fmt -verify` PASS፣ `v test ./pastafari` 19/19 PASS። የደረጃ 12 አራት RED assertions ሳይቀየሩ GREEN ሆነዋል። `LAST_COMPLETED_STAGE=13` ነው። `docs/STAGE13_PATCH06.md` ይመልከቱ።

## ደረጃ 14 — DISCOVERY 07

የ11 ትክክለኛ የወፍጮ መስመሮች ሰንጠረዥ `legacy_visible_grind_table` በV ዜሮ-መሠረት `0..10` ተይዟል። የታሪካዊው `old_grind_row(grind)` ግን ቁጥር `1..11` እንደ የarray ማውጫ በቀጥታ ይጠቀማል፤ ወፍጮ 1 ረድፍ 2ን ያነባል፣ ወፍጮ 11 ከሰንጠረዡ ውጪ ነው። በV ሕገ-ወጥ ንባብ ሂደት እንዳይቋረጥ በerror ይመለሳል፣ ነገር ግን የታሪክ ስህተቱ አልተጠገነም። አዲሱ `calendar_grind_once_spaghetti` በተሳሳተው የረድፍ መርጫ ላይ የትክክለኛውን የወፍጮ ሂሳብ ይፈጽማል። አራት `EXPECTED_RED` እና የታሪክ GREEN ምስክሮች ተጨምረዋል። የ`PATCH 07` sentinel ረድፍ አልተጨመረም። V 0.5.2 (`7647ce1`) በGitHub Actions run `38227809414` በቀጥታ ተረጋግጧል። `v fmt -verify` PASS፣ 20 የቀድሞና የታሪክ GREEN ፋይሎች PASS፣ አራቱ የወፍጮ ሰልፍ የታሰቡ RED assertions በስም ተረጋግጠዋል። `LAST_COMPLETED_STAGE=14` ነው። ዝርዝር፦ `docs/STAGE14_DISCOVERY07.md`።

## ደረጃ 15 — PATCH 07

የታሪካዊው `legacy_visible_grind_table` ያሉትን 11 ረድፎች በ0..10 እንደነበሩ ይጠብቃል፤ `old_grind_row` ያለው የቀጥታ የተሳሳተ ማውጫም አልተቀየረም። `GrindPatch07.table_with_sentinel` ለproduction ብቻ አዲስ 12-ረድፍ ሰንጠረዥ ይፈጥራል፦ ረድፍ 0 `[0,0,0,0,0]` የsentinel ነው፣ እውነተኛዎቹ 11 ረድፎች በ1..11 ናቸው። `calendar_grind_row_spaghetti` በ`BaseDispatcher.dispatch_grind_patch07` በኩል አሁንም በቀጥታ `table[grind]` ያነባል። የደረጃ 14 አራቱ RED assertions ሳይቀየሩ GREEN መሆን አለባቸው። V 0.5.2 (`7647ce1`) በGitHub Actions run `38232812419` ተረጋግጧል። `v fmt -verify ./pastafari` PASS፣ `v test ./pastafari` 22/22 PASS፣ የደረጃ 14 አራቱ RED assertions ሳይቀየሩ GREEN ሆነዋል። `LAST_COMPLETED_STAGE=15` ነው። ዝርዝር፦ `docs/STAGE15_PATCH07.md`።

## ደረጃ 16 — DISCOVERY 08

የታሪካዊው `old_permutation_unrank0(rank0)` የስድስት ጎድጓዳ ሳህኖች 720 የቅደም ተከተሎችን በዜሮ-መሠረት በትክክል ይፈታል። የታሪካዊው የproduction ጥሪ ግን `oneBased=regularMod(drop-1,720)+1` በማስላት፣ ሳይቀንሰው በቀጥታ ወደ `old_permutation_unrank0(oneBased)` ይልካል። ይህ ወደ ቀጣዩ ቅደም ተከተል ይሄዳል፤ `oneBased=720` ሲሆን ደግሞ ከ`rank0=0..719` ውጪ ስለሆነ error ያስከትላል። አራት የታሰቡ RED assertions እና የታሪክ GREEN ምስክሮች ተጨምረዋል፤ `PATCH 08` አልተጨመረም። V 0.5.2 (`7647ce1`) በGitHub Actions run `38235387422` ተረጋግጧል፤ `v fmt -verify` PASS፣ 23 የቀድሞና አዲስ የGREEN ፈተና ፋይሎች PASS፣ አራቱ የሆን ተብሎ RED የቅደም ተከተል assertions ተረጋግጠዋል። `LAST_COMPLETED_STAGE=16` ነው። ዝርዝር፦ `docs/STAGE16_DISCOVERY08.md`።

## ደረጃ 17 — PATCH 08

የታሪካዊው `old_permutation_unrank0` እና የተሳሳተው `LegacyPermutationAdapter.order_for_drop` ያልተለወጡ ይቆያሉ። የproduction መንገድ አሁን በ`BaseDispatcher.dispatch_permutation_patch08` ወደ `PermutationPatch08` ይገባል። አዲሱ wrapper የሶስት-እርምጃ ሕግን `one_based=regularMod(drop-1,720)+1`፣ `legacy_rank0=one_based-1`፣ `old_permutation_unrank0(legacy_rank0)` በቀጥታ ይፈጽማል። በዚህ መንገድ የታሪካዊው የ0..719 መፍቻ ይጠበቃል፣ የሎጂክ 1..720 ቅደም ተከተል ግን ይመለሳል። የደረጃ 16 አራቱ RED assertions ሳይለወጡ GREEN መሆን አለባቸው። የቀድሞ ምስክሮች በተለየው legacy dispatcher ላይ የታሪክ ጉድለቱን ይጠብቃሉ። V 0.5.2 (`7647ce1`) በGitHub Actions run `38239438620` ተረጋግጧል፤ `v fmt -verify ./pastafari` PASS፣ `v test ./pastafari` 25/25 PASS። የደረጃ 16 አራቱ RED assertions ሳይቀየሩ GREEN ሆነዋል። `LAST_COMPLETED_STAGE=18` ነው። ዝርዝር፦ `docs/STAGE17_PATCH08.md`።

## ደረጃ 18 — DISCOVERY 09

የ`calendar_initial_bowls_spaghetti` ተግባር ስድስቱን ጎድጓዳ ሳህኖች በ`BOWL_PRIME=[17,19,23,29,31,37]` እና በተጠገነው SAVE ያስነሳል። ለዙር `i=1..46` የታሪክ `old_pours_fixed_bowls` የ`order` ቅደም ተከተልን ሳይከተል ሁልጊዜ ከ`bowls[1],bowls[2],bowls[3]` ያነባል፤ የትክክለኛው ንባብ ግን የየቦታው `bowls[order[1]],bowls[order[2]],bowls[order[3]]` ነው። ሶስቱ የታሪክ ማፍሰሻ ሂሳቦችን አልተካንም፣ የ`LegacyPourAdapter` እና `BaseDispatcher.dispatch_legacy_pours` መንገድ በproduction ውስጥ ተያይዟል። `discovery09_expected_red_test.v` አራት በሆን ተብሎ RED መሆን ያለባቸው ሙከራዎችን ይይዛል። `PATCH 09` የ`bowlAlias` ካርታ ገና አልተጨመረም፤ `LAST_COMPLETED_STAGE=17` በV 0.5.2 ተረጋግጧል፤ 26/26 PASS እና 4 EXPECTED_RED። ዝርዝር፦ `docs/STAGE18_DISCOVERY09.md`።

## ደረጃ 19 — PATCH 09

የታሪካዊው `old_pours_fixed_bowls` እና `LegacyPourAdapter` እንዳሉ ይቆያሉ። `PourPatch09.install_bowl_alias(order)` ለስድስቱ ቦታዎች `bowl_alias[position]=order[position-1]` የሚለውን የV ባለ-ዜሮ ኢንዴክስ ልዩነት የሚከተል ካርታ ይፈጥራል። የ`bowl_by_legacy_position` የተለየ የማንበቢያ መንገድ በ`bowls[bowl_alias[position]]` ላይ ይሠራል፤ `PourPatch09.pour` በዚህ ካርታ ከተሞላ ባለ-ቦታ የ`legacy_view` ሰልፍ በኋላ የታሪክ `BaseDispatcher.dispatch_legacy_pours` ጥሪን በእውነት ያከናውናል። የታሪክ መንገድና አዲሱ production መንገድ በአንድ ሙከራ ውስጥ ሊታዩ ይችላሉ። የደረጃ 18 አራቱ RED assertions ሳይቀየሩ GREEN መሆን አለባቸው፤ የታሪክ ምስክሮች የታሪክ ጥሪውን በdispatcher በቀጥታ ይጠቀማሉ። የ`PATCH 10` የvault/pending ተግባር አልተጨመረም። V 0.5.2 (`7647ce1`) በGitHub Actions run `38246568417` ተረጋግጧል፤ `v fmt -verify ./pastafari` PASS፣ `v test ./pastafari` 28/28 PASS። የደረጃ 18 አራቱ RED assertions ሳይቀየሩ GREEN ሆነዋል። `LAST_COMPLETED_STAGE=19` ነው። ዝርዝር፦ `docs/STAGE19_PATCH09.md`።

## ደረጃ 20 — DISCOVERY 10

`old_stir_bowls_in_place` ስድስቱን ጎድጓዳ ሳህኖች በየቅደም ተከተላቸው በእውነት በቀድሞው `bowls` መያዣ ላይ ይጽፋል። `prev` እና `next` የሚለውን ሲያነብ ከቀድሞው ዙር ተቀይሮ የተጻፈ እሴት ቢኖር ያንኑ ያነባል። የስህተቱ ቦታ በአንድ ትልቅ ዙር ውስጥ የስድስቱ ጽሑፎች አቀማመጥ ነው፤ የዙሩ ቅደም ተከተል፣ የቦታ የድንጋይ ምርጫ፣ `PATCH 09` የalias ማፍሰሻዎች እና `SAVE` የሂሳብ መንገድ ተጠብቀዋል። `LegacyBowlStirAdapter` የጠሪውን ሰልፍ ለይቶ በ`old_stir_bowls_in_place` ስህተቱን በውስጡ ይፈጽማል። `calendar_stir_bowls_spaghetti` በproduction ወደዚሁ መንገድ ይሄዳል። አራት `EXPECTED_RED` assertions እና የታሪክ GREEN ምስክሮች ተጨምረዋል። `PATCH 10` የ`vaultOld/pending` ሁለት-ደረጃ ስሌት ገና አልተጨመረም። V 0.5.2 (`7647ce1`) በGitHub Actions run `38254290745` በቀጥታ ተረጋግጧል። `v fmt -verify ./pastafari` PASS፣ 29 የቀድሞና አዲስ የታሪክ witness ፋይሎች PASS፣ አራቱ `EXPECTED_RED` የsnapshot assertions በተናጠል ተረጋግጠዋል። `LAST_COMPLETED_STAGE=20` ነው። ዝርዝር፦ `docs/STAGE20_DISCOVERY10.md`።

## ደረጃ 21 — PATCH 10

`old_stir_bowls_in_place` እና `LegacyBowlStirAdapter` ሳይቀየሩ ይቀራሉ። `BowlStirPatch10` ከቀድሞዎቹ ስድስት ጎድጓዳ ሳህኖች `vault_old` የተለየ ቅጂ ይፈጥራል፣ `pending` ሌላ ቅጂ ያዘጋጃል፣ እና የታሪክ `dispatch_legacy_bowl_stir` እውነተኛ ጥሪን ለምርመራ ብቻ ያከናውናል። ለስድስቱ ቦታዎች ሂሳቡ ሁሉንም ንባቦች ከ`vault_old` ብቻ ያደርጋል፣ ውጤቶቹንም በ`pending` ብቻ ይጽፋል። ስድስቱ ከተሰሉ በኋላ ብቻ የ`committed` ሰልፍ ይሞላል። የደረጃ 20 አራቱ RED assertions ሳይቀየሩ GREEN መሆን አለባቸው። የታሪክ ምስክሮች `dispatch_legacy_bowl_stir` በቀጥታ ይጠራሉ። V 0.5.2 (`7647ce1`) በGitHub Actions run `38258828731` ተረጋግጧል፤ `v fmt -verify ./pastafari` PASS፣ `v test ./pastafari` **31/31 PASS**። የደረጃ 20 አራቱ RED assertions ሳይቀየሩ GREEN ሆነዋል። `LAST_COMPLETED_STAGE=21` ነው። ዝርዝር፦ `docs/STAGE21_PATCH10.md`።

## ደረጃ 22 — DISCOVERY 11

የታሪክ LegacyPostStirOrderStore ከ46ኛው ጠብታ ቅደም ተከተል ምትክ በእያንዳንዱ ከ12 የመጨረሻ ብስለቶች አዲሱን order በquery_order ላይ ደግሞ ደጋግሞ ይጽፋል። old_post_stirs_overwrite_drop46_order የአስራ ሁለቱን ብስለቶች በተመሳሳይ old snapshot ይሰላል፤ savedBowlSum=SAVE(sum(old[1..6])+149*stir) እና የቅደም ተከተል ምርጫ ትክክለኛ ናቸው። ጉድለቱ ለquery የሚመለሰው ቅደም ተከተል የ12ኛው ብስለት እንጂ የ46ኛው ጠብታ አይደለም። አራት EXPECTED_RED የquery-order ምስክሮች ተጨምረዋል። የPATCH 11 orderAt46Latch አልተጨመረም። የ46 ጠብታዎች ሙሉ ሰንሰለት በዚህ ደረጃ አልተገነባም፤ ንዑስ መንገዱ ተለይቶ ተፈትሿል። LAST_COMPLETED_STAGE=21 እስከ native V CI ድረስ ይቆያል። ዝርዝር፦ docs/STAGE22_DISCOVERY11.md።
