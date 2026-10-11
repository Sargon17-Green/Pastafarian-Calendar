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
