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
