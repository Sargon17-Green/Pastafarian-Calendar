# የስፓጌቲ ልማት ታሪክ

## ደረጃ 1 — መነሻ ግንባታ

### ምን ተገነባ

የV እና አማርኛ መስመር ከዜሮ ተጀምሯል። ትክክለኛ ትልቅ ኢንቲጀር፣ የአማርኛ የምንጭ ስም ካታሎግ፣ ለሙከራ ብቻ የሚጠቅም ንጹሕ ኖርማቲቭ ኦራክል እና መሠረታዊ የሞንስተር አውታር ተፈጥረዋል።

### የተጨመረው የሞንስተር ንብርብር

በዚህ ደረጃ `MonsterContext`፣ `BaseDispatcher`፣ `BaseValidationManager`፣ `BaseErrorWrapper` እና `BaseMetricsManager` ብቻ ተጨምረዋል። እነዚህ አጠቃላይና ገለልተኛ መሠረቶች ናቸው፤ የቀጣይ ጉድለት ወይም መጠገኛ ልዩ መንገድ አያውቁም።

### ለምን ሴማንቲክስን አይቀይርም

የመሠረት አውታሩ ኖርማቲቭ የካሌንደር ውጤት አያመነጭም። የኦራክሉ ኮድ በ`_test.v` ፋይል ውስጥ ብቻ ነው፣ ስለዚህ production መንገድ ሊጠራው አይችልም።

የጉድለት 01 ታሪክ ገና አልተጀመረም።

### የደረጃ 1 ማረጋገጫ

V 0.5.2 (`7647ce1`) በአካባቢው ተጭኖ የደረጃ 1 ኮድ በቀጥታ ተረጋግጧል። መጀመሪያ የቅርጸትና የኮምፓይል ስህተቶች ተገኝተዋል፤ እነሱም የV 0.5.2 የreceiver አጻጻፍ፣ በሁለት የunrank ሉፖች የጎደሉ መዝጊያዎች፣ እና የarray ባለቤትነት ሕግ የሚፈልገው `clone()` ነበሩ። እነዚህ ሁሉ የደረጃ 1 የቅርጸት/ኮምፓይል ጉዳዮች ብቻ ናቸው፤ ምንም የወደፊት ጉድለት ወይም መጠገኛ ባህሪ አልተጨመረም።

ከማስተካከያዎቹ በኋላ `v fmt -verify ./pastafari` በውጤት 0 አልፏል፣ `v test ./pastafari` ደግሞ 1 ሙከራ ከ1 በማለፍ በውጤት 0 አልፏል። ስለዚህ ደረጃ 1 `GREEN` ሆኖ ተረጋግጧል። የጉድለት 01 ታሪክ ገና አልተጀመረም።

## ደረጃ 2 — DISCOVERY 01 (የመጀመሪያው ታሪካዊ ጉድለት)

`old_remainder(x)` የ`regularMod(x, M)` ታሪካዊ ስህተትን ያስቀምጣል። `LegacyRemainderAdapter` ከ`BaseDispatcher` ጋር ተያይዟል። `calendar_save_spaghetti` የproduction ውጤትን በግልጽ ያሳያል፤ `calendar_date_spaghetti` ደግሞ ይህን መንገድ ይጠራል፣ ነገር ግን የሙሉ ቀን ውጤት አይፈጥርም።

በM፣ 2M እና 3M የlegacy ውጤት 0 ነው፣ ኖርማቲቩ M ነው፤ በM+1 ሁለቱም 1 ናቸው። ለብቻው የሚያልፍ witness ሙከራ እና ሆን ተብሎ RED የሚሆን regression ተጨምረዋል። ደረጃ 2 በV 0.5.2 (7647ce1) በActions run 38153202920 ተፈትኗል። ቅርጸት፣ የደረጃ 1 ኦራክል፣ 5 የlegacy witness ሙከራዎች እና የኖርማቲቭ ተቃራኒ ሙከራው የታሰበ RED ሁሉ ተረጋግጠዋል። የPATCH 01 መጠገኛ አልተጨመረም።

## ደረጃ 3 — PATCH 01 (በማረጋገጫ ላይ)

የደረጃ 2 መዝጊያ፦ `e23a7af`፤ የV 0.5.2 የተሳካው ታሪካዊ EXPECTED_RED run `38153202920`።

`old_remainder` እና `LegacyRemainderAdapter` አልተጠገኑም። `SavePatch01` የlegacy ውጤት 0 ብቻ ወደ M ይቀይራል፤ የውስጥ ቀሪ ስሌት ይቀራል። የdispatcher አዲስ መስመር እሱን ይጠራል። የተሟላው የቀን ልወጣ አልተገነባም።

### የደረጃ 3 መዝጊያ — GREEN

V 0.5.2 (`7647ce1`) በእውነተኛ GitHub Actions run `38153910238` ሁሉንም የቀድሞ እና አዲስ ፈተናዎች አልፏል። የኖርማቲቭ ኦራክል PASS፣ ታሪካዊ witness PASS፣ በደረጃ 2 RED የነበሩት ሶስት assertions GREEN፣ PATCH 01 ምልክት እና ትላልቅ ኢንቲጀሮች PASS። `v test ./pastafari`: 4/4 PASS። `old_remainder` አልተቀየረም። ደረጃ 3 COMPLETE ነው።

## ደረጃ 4 — DISCOVERY 02 (በታሪካዊ ማረጋገጫ ላይ)

`old_day_tag` በሆነ ስህተት `2*abs(day-FOUNDATION)` ይቆጥራል። `LegacyDayTagAdapter` በproduction dispatcher እውነተኛ መንገድ ላይ ተገናኝቷል። የPATCH 01 የSAVE መንገድ አልተለወጠም፣ ኖርማቲቭ oracle በproduction አይጠቀምም። በFOUNDATION፣ FOUNDATION+1፣ FOUNDATION+2 እና በትልቅ ወደፊት ቀን የሚታየውን የታሰበ RED ለማረጋገጥ የV 0.5.2 CI ተዘጋጅቷል። የPATCH 02 መጠገኛ በዚህ ደረጃ አልተጨመረም።

### የደረጃ 4 መዝጊያ — EXPECTED_RED

በGitHub Actions run `38155338854` የV 0.5.2 (`7647ce1`) ቀጥተኛ ፈተና PASS ሆኗል። `v fmt -verify`፣ የደረጃ 1 ኦራክል፣ የደረጃ 2 አሮጌ witness፣ የደረጃ 3 PATCH 01 እና የደረጃ 4 አሮጌ witness ሁሉ PASS ናቸው። አራቱ የኖርማቲቭ RED assertions በተናጠል ወድቀዋል፤ ማስረጃ artifact `11708217428` ተቀምጧል። `old_day_tag` ገና በታሪካዊ ስህተቱ ይሰራል። ደረጃ 4 COMPLETE / EXPECTED_RED ነው።

## ደረጃ 5 — PATCH 02 (የV ማረጋገጫ ይጠበቃል)

`old_day_tag` ስህተቱን እንዳለ ያስቀምጣል። `DayTagPatch02` ከ`BaseDispatcher.dispatch_legacy_day_tag` በኋላ የሚጠራው ራሱን የቻለ ንብርብር ነው። በFOUNDATION እና በኋላ 1 ይጨምራል፣ ተጨማሪ `if day == FOUNDATION and n != 1` የታሪክ ጠባሳን ያስቀምጣል። ከአማርኛ ውጭ የምንጭ ቃላት አልተጨመሩም፣ የtest-only ኦራክል ወደ production አልገባም።

### የደረጃ 5 መዝጊያ — GREEN

V 0.5.2 (`7647ce1`) በGitHub Actions run `38156647121` ተፈትኗል፤ `v fmt -verify` እና ሙሉ `v test ./pastafari` 7/7 PASS ናቸው። በደረጃ 4 የነበሩት አራት RED assertions ሳይለወጡ GREEN ሆነዋል። `old_day_tag` አሁንም FOUNDATION ላይ 0 ይመልሳል፣ `calendar_day_tag_spaghetti` 1 ይመልሳል። የFOUNDATION ሁለተኛው መከላከያ ተጠብቋል፤ `PATCH 01` አልተለወጠም። ማስረጃ artifact `11709045238` በCI ተቀምጧል። ደረጃ 5 COMPLETE / GREEN ነው።

## ደረጃ 6 — DISCOVERY 03 (የሚጠበቅ RED)

የካሌንደር አሮጌ ርቀት `old_distance(c,t)` ከ`calendar_day_tag_spaghetti` የሚመጡትን የተጠገኑ tag ውጤቶች አንጻር ይቆጥራል፦ `abs(tag(c)-tag(t))`። ይህ የክሮኖሎጂ የቀን ርቀት `abs(t-c)+1` አይደለም። `LegacyDistanceAdapter` እና የproduction መግቢያ `calendar_distance_spaghetti` ተጨምረዋል፤ በ`calendar_date_spaghetti` ስህተት መልዕክት የታሪካዊ መንገድ ውጤት በግልጽ ይታያል። `old_day_tag`፣ `DayTagPatch02` እና `SavePatch01` ሳይለወጡ ቀርተዋል። `PATCH 03` ወደ ደረጃ 7 ብቻ ይገባል።

### የደረጃ 6 መዝጊያ — EXPECTED_RED

V 0.5.2 (`7647ce1`) በGitHub Actions run `38157358354` ተፈትኗል። ቅርጸት፣ የደረጃ 1 ኦራክል፣ ቀድሞ የተጠገኑ የPATCH 01 እና PATCH 02 የሙከራ ፋይሎች፣ የሦስተኛው ታሪካዊ ስህተት witness ተሳክተዋል። `discovery03_expected_red_test.v` ከመጀመሪያው የV typecheck PASS በኋላ አራት የታሰቡ assertions በተናጠል RED አሳይቷል። የማስረጃ ቅርስ `11708791583` ተቀምጧል። `old_distance` አልተጠገነም፣ `PATCH 03` አልተጨመረም። ደረጃ 6 COMPLETE / EXPECTED_RED ነው።

## ደረጃ 7 — PATCH 03 (የCI ማረጋገጫ ይጠበቃል)

`old_distance` ውስጥ ያለው `abs(dayTag(c)-dayTag(t))` ታሪካዊ ጉድለት አልተለወጠም። `DistancePatch03` ከአሮጌው dispatcher በእውነት የተገኘ እሴትን ተቀብሎ `chronological=abs(t-c)` ያሰላል። የlegacy ልዩነቱን ሲያይ ይተካዋል፣ ካልተለየ እንዳለ ያቆየዋል፣ ከዚያ 1 ይጨምራል። የእርምት አጠቃቀም በ`calendar_distance_spaghetti` እና `calendar_date_spaghetti` ውስጥ ተገናኝቷል። ሙሉ የቀን ልወጣ ገና የለም።

### የደረጃ 7 መዝጊያ — GREEN

የመጀመሪያው የGitHub Actions ሙከራ በአንድ የታሪካዊ witness ፋይል የV ቅርጸት ምርመራ ቆሟል። ተደጋጋሚ assertion ተወግዶ የቅርጸት ልዩነቱ ተስተካክሏል፤ የሂሳብ ስሌት አልተለወጠም። በቀጣዩ commit `0755353e8cd776480d538261b777b2a2289b571d` ላይ የV 0.5.2 (`7647ce1`) ቀጥተኛ ሙከራ በGitHub Actions run `38158404538` ሙሉ PASS ነው። `v fmt -verify`፣ የቀድሞ 8 የሙከራ ፋይሎች፣ የደረጃ 6 የRED assertions እና የPATCH 03 አዲስ ፈተናዎች ሁሉ PASS ናቸው። `v test ./pastafari`: 10/10 PASS። የማስረጃ ቅርስ `11709132166` ተቀምጧል። `old_distance` አልተቀየረም፣ `PATCH 03` በproduction እውነተኛ መስመር ተገናኝቷል። ደረጃ 7 COMPLETE / GREEN ነው።

## ደረጃ 8 — DISCOVERY 04 (EXPECTED_RED እየተፈተነ)

የአራተኛው ታሪካዊ ስህተት `mutate_stones_wrong` የአምስት ድንጋዮችን የክብ ሂሳብ በተከታታይ ይጽፋል፣ ይህም አዲሱ `w` በ`b` እና በ`r`፣ አዲሱ `b` በ`s`፣ አዲሱ `s` በ`m`፣ አዲሱ `m` በ`r` የስህተት ንባብ ይፈጥራል። አዲሱ `LegacyStonesAdapter` እና `BaseDispatcher.dispatch_legacy_stones` በproduction ንዑስ መግቢያ ተያይዘዋል፤ `calendar_date_spaghetti` ውስጥ የታሪካዊ ድንጋይ ውጤት ምርመራ አለ። የተጠገኑ `PATCH 01`፣ `PATCH 02`፣ `PATCH 03` አልተለወጡም፣ የ`PATCH 04` snapshot ገና አልተጨመረም።

### የደረጃ 8 መዝጊያ — EXPECTED_RED

በመጀመሪያው የV CI ሙከራ የwitness ቅርጸት ስህተት ተገኝቷል። ቀጣዩ በእውነተኛው የV 0.5.2 ኮምፓይለር የ`Stones` አምስት መስኮች `pub mut:` ያስፈልጋሉ ብሎ አመልክቷል። ሁለቱም የV ቅርጸት እና የተለዋዋጭ መስክ ጉዳዮች ተስተካክለዋል፤ ሂሳባዊ የlegacy ስህተቱ አልተለወጠም። በcommit `74e100a03ab1aa2530e674c7746178a24f0a0b92` ላይ የGitHub Actions run `38160751813` በV 0.5.2 (`7647ce1`) ሙሉ የተጠበቀው ሁኔታ PASS ሆኗል፤ 11 GREEN የሙከራ ፋይሎች አልፈዋል፣ 4 RED assertions በስም ተረጋግጠዋል። የማስረጃ ቅርስ `11710830257` ተቀምጧል። `PATCH 04` አልተጨመረም። ደረጃ 8 COMPLETE / EXPECTED_RED ነው።

## ደረጃ 9 — PATCH 04 (በV ማረጋገጫ ላይ)

የታሪካዊው ስህተት `mutate_stones_wrong(i,S)` እንደነበረ ቆይቷል። `StonePatch04.apply` በ`old = stones.deep_clone()` የድንጋዮችን አምስት የቀድሞ እሴቶች ያስቀምጣል፤ ከዚያ `mutate_stones_wrong` በተለየ clone ላይ በእውነት ይጠራል። ሁሉም አምስት `garbage` መስኮች `old` ብቻ በሚያነቡ መጠገኛ ቀመሮች ይተካሉ። `calendar_stones_spaghetti` የPATCH 04 አዲሱን መስመር ይጠራል፤ `BaseDispatcher.dispatch_legacy_stones` ለየታሪካዊ witness አለ። ለ46 ድንጋዮች ትክክለኛ የsnapshot ገንቢ ተጨምሯል። የካሌንደር የመጨረሻ ቀን ልወጣ ገና የለም።

### የደረጃ 9 መዝጊያ — GREEN

በመጀመሪያው የCI ሙከራ `patch04_test.v` ውስጥ አንድ የቅርጸት ልዩነት ነበረ። ይህን በV 0.5.2 (`7647ce1`) የformatter ውጤት መሠረት ተስተካክሏል፣ የሙከራ ይዘት አልተቀየረም። በcommit `0d2a08d992944ec5db2b76da6e745703db686cf7` ላይ የGitHub Actions run `38162967481` በቀጥታ አልፏል። `v fmt -verify ./pastafari` PASS፣ `v test ./pastafari` 13/13 PASS። የደረጃ 8 አራቱ RED እንደነበሩ በ`discovery04_expected_red_test.v` ሳይቀየሩ GREEN ሆነዋል። የታሪካዊው `mutate_stones_wrong` አልተለወጠም፤ እውነተኛ ጥሪው በ`StonePatch04` በኋላ በold snapshot ይተካል። የማስረጃ ቅርስ `11711370337` ተቀምጧል። ደረጃ 9 COMPLETE / GREEN ነው።

## ደረጃ 10 — DISCOVERY 05 (EXPECTED_RED በማረጋገጫ ላይ)

የታሪካዊው `legacy_hidden_coefficients_reversed` ሰንጠረዥ በተገላቢጦሽ ነው። `make_hidden_drop_spaghetti` የ7 ጠብታዎችን ትክክለኛ ሂሳብ በቀድሞው `StonePatch04` ሰንጠረዥ፣ በPATCH 03 የርቀት ሒሳብ እና በPATCH 01 የSAVE ስሌት ይገነባል። ነገር ግን `build_hidden_with_backward_storage` አካላዊ ማከማቻውን `hidden7 … hidden1` ያደርጋል። `old_hidden_slot` እና `calendar_hidden_by_nearness` በተቃራኒው የቅርበት ትርጉም ያነባሉ። የማከማቻ ስርዓት አልተቀየረም፤ የPATCH 05 የ`8-k` አገልግሎት አልተጨመረም።

### የደረጃ 10 መዝጊያ — EXPECTED_RED

የመጀመሪያው የV ሙከራ በሁለት የቅርጸት ስህተቶች ቆሟል። ከV 0.5.2 (`7647ce1`) የቅርጸት ምርመራ የተገኙ ልዩነቶች ተፈጽመዋል፤ ጊዜያዊ የምርመራ እርምጃው ከCI ተወግዷል። በcommit `e1487442a3a2e93d0477584301a855e977f4fe50` ላይ የGitHub Actions run `38165059747` ሁሉንም 14 የቀድሞ እና አዲስ የGREEN ፈተና ፋይሎች PASS አድርጓል። `discovery05_expected_red_test.v` በV ይተረጎማል፣ በተለዩ አራት assertions ግን በሆን ተብሎ RED ነው። የማስረጃ ቅርስ `11711703085` ተቀምጧል። ሰባቱ የተለያዩ የhidden እሴቶች የማስቀመጫ ቅደም ተከተል ብቻ ተቃራኒ መሆኑ ተረጋግጧል፤ `PATCH 05` አልተጨመረም። ደረጃ 10 COMPLETE / EXPECTED_RED ነው።

## ደረጃ 11 — PATCH 05 (እየተረጋገጠ)

የታሪካዊው ስውር ጠብታ ሰንጠረዥ በ`build_hidden_with_backward_storage` ተገላቢጦሽ `hidden7, hidden6, hidden5, hidden4, hidden3, hidden2, hidden1` ሆኖ ይጠበቃል። `old_hidden_slot` እንደነበረው ከአካላዊ k ሰልፍ ያነባል። ማከማቻውን ሳንገለብጥ `HiddenPatch05.by_nearness` ከ`BaseDispatcher.dispatch_hidden_patch05` በኋላ `backward[7-k]` ያነባል። የ`calendar_date_spaghetti` የምርመራ መልዕክት ሁለቱንም `DISCOVERY_05 oldHidden1` እና `PATCH_05 hidden1` ያሳያል። ይህ ገና የመጨረሻ የቀን ልወጣ አይደለም፤ የ`PATCH 06` ወይም የደረጃ 12 ስራ አልተጀመረም።

### የደረጃ 11 መዝጊያ — GREEN

V 0.5.2 (`7647ce1`) በGitHub Actions run `38166616826` በcommit `a48d1c7920017b153641a36bd0e55b2c1deaf82f` ላይ በቀጥታ ተሳክቷል። `v fmt -verify ./pastafari` PASS፣ `v test ./pastafari` 16/16 PASS። የደረጃ 10 አራቱ የኖርማቲቭ የRED assertions ያለ ለውጥ GREEN ሆነዋል። `old_hidden_slot` ያለውን ታሪካዊ የተሳሳተ ንባብ አልጣለም፤ የሰባቱ ጠብታዎች `hidden7 … hidden1` ማከማቻ አልተገለበጠም። `HiddenPatch05` በV የዜሮ-መሠረት `backward[7-k]` በኩል ሎጂካዊ ቅርበት ይመልሳል። ሁለቱ የGitHub Actions ሥራዎች PASS ናቸው፤ የማስረጃ ቅርስ `11712298133` ተቀምጧል። ደረጃ 11 COMPLETE / GREEN ነው።

## ደረጃ 12 — DISCOVERY 06 (በV ማረጋገጫ ላይ)

ታሪካዊው `legacy_prior` የሚታዩ ጠብታዎችን በ1-መሠረት `drop_store[i-back]` እንደነበረ ይመለከታል። `slot=0` እና አሉታዊ slots የስውር ጠብታዎች ትርጉም የላቸውም። የV runtime ሕገ-ወጥ የarray መለያን እንዳይፈጽም የተሳሳተ መለያ በerror ይመለሳል፣ ከhidden ግን ምንም አያነብም። `LegacyPriorAdapter`፣ `BaseDispatcher.dispatch_legacy_prior` እና `calendar_prior_spaghetti` ወደ production ንዑስ ሂደት ተያይዘዋል። በ`calendar_date_spaghetti` ምርመራ መልዕክት `DISCOVERY_06 oldPriorSlot0=ERROR` ይመዘገባል። የ`PATCH 06` መለያ ማስተካከያ ወደ ደረጃ 13 ይቀራል።

### የደረጃ 12 መዝጊያ — EXPECTED_RED

የመጀመሪያው የCI ሙከራ በሁለት አዲስ የV ፈተና ፋይሎች የቅርጸት ልዩነት ቆሟል። ከV 0.5.2 (`7647ce1`) እውነተኛ የformatter ውጤት እነዚህ ልዩነቶች ተስተካክለው፣ ጊዜያዊ የምርመራ የCI እርምጃ ተወግዷል። በcommit `4426662ddbfd426b2db12c09f72a1b94da55cd5f` የGitHub Actions run `38222220614` ሙሉ PASS ነው፤ 17 የGREEN የሙከራ ፋይሎች ተሳክተዋል፣ 4 በተለዩ የhistory ጉድለት assertions የተጠበቀው RED ተረጋግጧል። የቅርስ ማስረጃ `11735060045` ተሰጥቷል። `legacy_prior` እውነተኛ የታዩ ጠብታዎችን ብቻ እንደነበረው ያነባል፣ ከዜሮ እና ከአሉታዊ slot የሚመለሰው የV error የruntime ጥበቃ ብቻ ነው። `PATCH 06` አልተጨመረም፣ ደረጃ 12 COMPLETE / EXPECTED_RED ነው።

## ደረጃ 13 — PATCH 06 (በቀጥተኛ የV CI ሙከራ ላይ)

`legacy_prior` የቀድሞውን የ`drop_store[i-back]` ብቻ ሕግ ይጠብቃል። የ`PriorPatch06.prior` አዲሱ የhistory አገናኝ `slot>=1` ሲሆን የታሪክ መንገድን በdispatcher ይጠራል። ያለዚያ `hidden_k=1-slot` ያሰላል፣ የተጠገነውን `HiddenPatch05` በ`calendar_hidden_by_nearness` በኩል ይጠቀማል። `LegacyPriorAdapter` እና የደረጃ 12 አራቱ ኖርማቲቭ assertions ይጠበቃሉ። የ`calendar_date_spaghetti` የእንቅስቃሴ ምርመራ ሁለቱንም `DISCOVERY_06 oldPriorSlot0=ERROR` እና `PATCH_06 priorSlot0` ያሳያል። ደረጃ 14 አልተጀመረም።

### የደረጃ 13 መዝጊያ — GREEN

በመጀመሪያው የV ሙከራ `patch06_test.v` ውስጥ አንድ የformatter ልዩነት ታይቷል። የV 0.5.2 (`7647ce1`) እውነተኛ formatter ተጠቅመን ልዩነቱን አስተካክለናል፤ ጊዜያዊ የአመርማሪ የCI እርምጃ ተወግዷል። በcommit `6192a870e1af98398e6f4ed70f9dcf49aca60a28` ላይ የGitHub Actions run `38223816213` በአገርኛው የV ኮምፓይለር ሙሉ PASS ነው። ሁሉም 19 የV ፈተና ፋይሎች GREEN ናቸው፣ የደረጃ 12 አራቱ RED assertions ሳይለወጡ አልፈዋል። `legacy_prior` የታሪክ ስህተቱ ተጠብቋል፣ `PriorPatch06` አዎንታዊ slot ሲሆን በdispatcher ወደ `legacy_prior` በእውነት ይመለሳል። የማስረጃ ቅርስ `11735158009` ነው። ደረጃ 13 COMPLETE / GREEN ነው።

## ደረጃ 14 — DISCOVERY 07 (EXPECTED_RED በቀጥተኛ ማረጋገጫ ላይ)

ከ11 የወፍጮ ረድፎች ጋር `legacy_visible_grind_table` ተጨምሯል። `old_grind_row(grind)` በ0..10 የተደራጀውን ሰንጠረዥ በ1..11 የሎጂክ ቁጥር በቀጥታ ያነባል። `LegacyGrindAdapter` እና `BaseDispatcher.dispatch_legacy_grind` በproduction `calendar_grind_row_spaghetti` ውስጥ በእውነት ይሠራሉ። በ`legacy_grind_once` የተሳሳተው ረድፍ በመደበኛው SAVE የሂሳብ መስመር ሲገባ ውጤቱ 210 ነው፣ የትክክለኛው የመጀመሪያ ረድፍ ሂሳብ ግን 154 ነው። አራት የተመረጡ RED assertions የ1,2,10,11 ወፍጮዎችን ይመረምራሉ፤ የታሪክ ስህተት በራሱ ምስክር ይቀራል። የsentinel ረድፍ ለ`PATCH 07` ይጠበቃል።

### የደረጃ 14 መዝጊያ — EXPECTED_RED

የV 0.5.2 (`7647ce1`) እውነተኛ formatter በሶስቱ አዳዲስ የV ፋይሎች ላይ ምንም ለውጥ አልጠየቀም። ጊዜያዊ የቅርጸት ምርመራ ከCI ተወግዶ፣ commit `c15c5848da35ebd72cd9d98ab188baf53f79f36f` ላይ GitHub Actions run `38227809414` ሁሉንም የታሰቡ ውጤቶች አረጋግጧል። 20 የቀድሞና አዲስ witness `_test.v` ፋይሎች PASS ናቸው፣ አራት የተለዩ የወፍጮ ረድፍ assertions ሆን ብለው RED ሆነዋል። `old_grind_row` በ1 ዙር ሁለተኛውን ረድፍ ያነባል፣ በ11 ዙር የማውጫ ስህተት ይመልሳል፤ ይህ የታሪክ ጉድለት ያልተጠገነ ነው። የማስረጃ ቅርስ `11737470384` ተቀምጧል። `PATCH 07` sentinel ረድፍ አልተጨመረም። ደረጃ 14 COMPLETE / EXPECTED_RED።

## ደረጃ 15 — PATCH 07 (በV CI ማረጋገጫ ላይ)

አዲሱ `GrindPatch07` ከ`legacy_visible_grind_table()` የታሪካዊውን 11 ረድፎች እንደነበሩ በclone ይወስዳል፣ ከእነርሱ በፊት `[0,0,0,0,0]` የsentinel ረድፍ ያስገባል። ይህ ረድፍ አይሰረዝም፤ `table[grind]` የቀጥታ ንባብ አሁን 1..11 ሲጠራ የተዛመደውን እውነተኛ የወፍጮ ረድፍ ይመልሳል። አሮጌው `old_grind_row` በgrind1 ሁለተኛውን ረድፍ የሚያነብ እና በgrind11 የerror የሚመልስ ሆኖ ይቆያል። `calendar_grind_once_spaghetti` በተጠገነው የረድፍ መርጫ የቀድሞውን ትክክለኛ የSAVE ሂሳብ ይፈጽማል። `calendar_date_spaghetti` በምርመራ መልዕክት የታሪክ እና የተጠገነውን የመጀመሪያ እና የመጨረሻ የወፍጮ ረድፍ አባላት ለይቶ ያሳያል። ደረጃ 16 አልተጀመረም።

### የደረጃ 15 መዝጊያ — GREEN

በመጀመሪያው የGitHub Actions run `38232643908` ላይ ሙሉ 22/22 የV ፈተና ፋይሎች PASS ነበሩ፤ የV 0.5.2 formatter በ`patch07_test.v` ውስጥ ሶስት የ`or { big_zero() }` አጻጻፎችን ብቻ እንዲቀየሩ ጠይቋል። ልዩነቶቹ ከእውነተኛው V formatter በትክክል ተቀድተው፣ ጊዜያዊ የማረጋገጫ እርምጃ ተወግዷል። በcommit `42dbb4a5d9ab6ace74d4855a97888798adf31f10` ላይ የGitHub Actions run `38232812419` ሁለቱም ሥራዎች PASS ናቸው። በ`V 0.5.2 7647ce1` `v fmt -verify ./pastafari` PASS፤ `v test ./pastafari` **22/22 PASS**፤ የደረጃ 14 አራቱ RED assertions ሳይቀየሩ GREEN ሆነዋል። የታሪካዊው `old_grind_row` ተጠብቋል፤ የ`GrindPatch07` sentinel ረድፍ በindex 0 የማይሰረዝ ነው። የማስረጃ ቅርስ `11738849261` ተቀምጧል። **ደረጃ 15 COMPLETE / GREEN።**

## ደረጃ 16 — DISCOVERY 08 (በV ማረጋገጫ ላይ)

`old_permutation_unrank0` ከ0 እስከ719 ያለውን የስድስት ጎድጓዳ ሳህኖች ደረጃ በትክክል ይፈታል፤ በራሱ የታሪክ ኮድ ስህተት የለም። ነገር ግን `LegacyPermutationAdapter.order_for_drop` የ1..720 የቅደም ተከተል ቁጥርን በቀጥታ እንደ rank0 ይልካል። `BaseDispatcher.dispatch_legacy_permutation` እና `calendar_bowl_order_spaghetti` በproduction መንገድ ላይ በእውነት እዚህ ይደርሳሉ። `calendar_date_spaghetti` የdrop=1 ሙከራ በስህተት `rank0=1` እና `[1,2,3,4,6,5]` ይመልሳል። የስህተቱ ምክንያት በ0 እና 1 መሠረቶች መቀላቀል ነው፤ `PATCH 08` የoneBased-1 መጠገኛ በደረጃ 17 ብቻ ይገባል።

### የደረጃ 16 መዝጊያ — EXPECTED_RED

በመጀመሪያው የGitHub Actions run `38235201547` የV 0.5.2 formatter በሁለት አዲስ `_test.v` ፋይሎች የረድፍ ቅርጽ ልዩነት ጠይቋል። በእውነተኛው formatter የተገኙት ልዩነቶች ብቻ ተስተካክለው፣ ጊዜያዊ የformatter ምርመራ ከCI ተወግዷል። commit `d40d313615367c6cdd9202711f2127200903fecf` ላይ GitHub Actions run `38235387422` በሁለቱም ሥራዎች PASS ነው። የV ቅርጸት ምርመራ PASS፣ 23 የቀድሞ እና አዲስ ምስክር ፈተናዎች PASS፣ `drop=1,2,719,720` ላይ አራት በስም የተመረጡ RED assertions ተረጋግጠዋል። `old_permutation_unrank0` የ720 ትክክለኛ መፍቻ እንደነበረው ይቀራል፣ የተሳሳተው `LegacyPermutationAdapter` ጥሪም በproduction አሁንም ይሠራል። የማስረጃ ቅርስ `11740715370` ተቀምጧል። `PATCH 08` አልተጨመረም። **ደረጃ 16 COMPLETE / EXPECTED_RED።**

## ደረጃ 17 — PATCH 08 (በV CI ማረጋገጫ ላይ)

`old_permutation_unrank0(rank0)` የታሪክ ቅደም ተከተል መፍቻ በሙሉ ተጠብቋል። `LegacyPermutationAdapter.order_for_drop` በስህተት `one_based` እንደ `rank0` ይልካል፣ የታሪክ ምስክሮቹ ከ`BaseDispatcher.dispatch_legacy_permutation` በቀጥታ ይህን ስህተት ያረጋግጣሉ። `PermutationPatch08` በproduction ጥሪ ከ`big_mod_small_nonnegative(drop-1,720)+1` የone-based ቁጥር በኋላ `one_based-1` ያደርጋል እና የቀድሞውን የ0..719 መፍቻ ይጠራል። `calendar_date_spaghetti` የመርመሪያ መልዕክት ሁለቱንም ተለያዩ ምርመራዎች `DISCOVERY_08 oldPermRank0=1` እና `PATCH_08 permRank0=0` ያሳያል። የ720 ደረጃዎች፣ ትልቅ 420-ቢት ግቤቶች፣ አሉታዊ ግቤቶች፣ ተደጋጋሚ ጥሪዎችና የቀድሞ መጠገኛዎች በ`patch08_test.v` ይፈተሻሉ። ደረጃ 18 አልተጀመረም።
