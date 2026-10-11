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

ሰባቱ የhidden ጠብታዎች በታሪካዊው `hidden7 … hidden1` የማከማቻ ቅደም ተከተል እንዳሉ ይቀራሉ። `old_hidden_slot(backward,k)` የቀድሞውን `backward[k-1]` ስህተት ይይዛል። አዲሱ `HiddenPatch05` የቅርበት መጠይቅን በአንድ-መሠረት `8-k`፣ በV ዜሮ-መሠረት `7-k` ወደ የታሪክ ማከማቻ ቦታ ይለውጣል። የproduction `calendar_hidden_by_nearness` ከdispatcher በኩል ይሄዳል፣ የቀድሞ አራት RED assertions ሳይቀየሩ GREEN መሆን አለባቸው። `LAST_COMPLETED_STAGE=10` የV CI ማረጋገጫ እስኪጠናቀቅ ይቆያል። ዝርዝር፦ `docs/STAGE11_PATCH05.md`።
