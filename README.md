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

## የሙከራ ትእዛዝ

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
