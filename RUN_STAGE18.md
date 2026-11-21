# Stage18 — תכנון, מימוש ובדיקת Native: סדר קערות מערך טיפה חתום

PROJECT_ID: `PC-BRANCH-FALSE-ARABIC` · branch `FALSE+العربية` · ACCEPTED_BOUNDED_CONTRACT_ONLY · 2026-11-21.

## עוגן נורמטיבי וחוזה

הפעולה הבאה היא **op52** בתוך `test/normative_reference.false` (Git blob `3e9acc012bedf83294a6ec3cccb081a069556b5b`). היא קוראת ערך טיפה `D` מסוג BigInt חתום, מחשבת `rank=1+EuclideanMod(D-1,720)`, ומעבירה אותו לפעולת תמורה לקסיקוגרפית op51. הפעולה `op35` מומשה בענף המורשה בלבד בקומיט `74260a604d972647f31b7c749a98c8ae23de08b6`, בנפרד מקוד המקור הנורמטיבי. מימוש אינו מהווה אישור Native או קבלת Stage18.

- **קלט תקין:** handle תקין לתא ארגומנט מוקצה אחד, המכיל handle תקין ל־BigInt חתום קנוני במבנה `[sign,limb_count,limbs_base512_le...]`. הסימן -1/0/+1, `limb_count>=1`, כל digit בטווח `0..511`, אין padding עם הספרה המשמעותית אפס; אפס מקודד `[0,1,0]`. כל התאים המוצהרים מוקצים בפועל. אין מגבלת ערך מספרית; עד 2048 ביט נבדקים באורקל המקומי, לא כהצהרת ביצועים של Native.
- **פלט:** handle חדש לטבלה ישירה בת שבעה תאים `[6,o1,o2,o3,o4,o5,o6]`. האיברים הם תמורה של `1..6`, לקסיקוגרפית בדירוג `rank` המתחיל ב־1. הפלט אינו descriptor של sequence כמו במקור הנורמטיבי; ההתאמה היא סמנטית ולא בינארית.
- **סמנטיקת שארית:** אוקלידית ב־`0..719` גם לקלטים שליליים; למשל `D=0` מחזיר דירוג 720, `D=-719` מחזיר דירוג 1, `D=720` מחזיר דירוג 720, `D=721` מחזיר דירוג 1.
- **תנאי אי־שינוי:** אף תא מן ה־BigInt המקורי או תא הארגומנט לא ישתנה, זהות המצביעים המקוריים תישמר. שתי קריאות עם אותם ערכים יחזירו אותו תוכן; אין דרישה לזהות מצביעי פלט.
- **מחוץ לחוזה:** כתובות לא מוקצות, truncated physical tuples, corrupted heap, metadata לא קנוני או digits פגומים; לא קיימת בממשק metadata בטוחה לבדיקת גודל הקצאה. חמש בדיקות דחיית metadata באורקל מדגימות רק את מגבלת מודל הנתונים; אינן בדיקת בטיחות זיכרון של FALSE.

## אורקל ועוגני בדיקה

`tools/stage18_drop_order_design_oracle.mjs` הוא **אורקל תכנון עצמאי** ב־JavaScript BigInt, ואינו טוען או מעתיק קוד FALSE. לחשבון הדירוג הוא משתמש בשתי דרכים שונות (שארית של `D-1` וענף אפס עבור שארית של `D`); סדר התמורות נגזר ממנייה רקורסיבית לקסיקוגרפית עצמאית, לא מ־op51 או `src/monster_bootstrap.false`. הקובץ מייצר בצורה דטרמיניסטית JSON עם עוגני ערך, תמורות צפויות וייצוג Base512 קנוני.

שערי התכנון: 720 דירוגים מלאים; עוגנים מפורשים לרבות 0 ושליליים; `D=-1440..1440`; גבולות של חזקות שתיים מ־9 עד 2048 ביט; 384 ערכים דטרמיניסטיים חתומים; בדיקות `D+720k`; roundtrip של Base512; חמישה mutants ל־off-by-one, סימן, שארית מחלוקת ו־64-bit truncation. כל mutant חייב להידחות על ידי עדות מספרית.

## שערי ביצוע לאחר אישור המשתמש — Stage18 עדיין אינו מאושר

1. המשתמש אישר במפורש מימוש Stage18, בדיקות Native וביקורת קבלה עצמאית; לא ניתנה הרשאה ל־main/merge. קוד `op34` והמקור הנורמטיבי אינם משתנים.
2. מחולל `tools/stage18_drop_order_fixture.py` מגדיר 750 מקרי Native בחמש קבוצות: 720 דירוגים מלאים, 28 וקטורים signed BigInt ושתי חזרות. כל מקרה כולל השוואת שבעה תאי תוצאה, שימור תא הארגומנט, זהות המצביע וערכי sign/count/digits. שני מוטנטים מגדירים בקרות שליליות מכוונות; תוצאותיהן עדיין אינן מאומתות.
3. ה־Native workflow `false-arabic-stage18-native-drop-order.yml` נועל מפרש מקורי `eb3135565a8670cced3f6bbca4dbf7b014c45634` ו־SOURCE_PIN=`9ab8511b05158f7ddbd0c664b8d6cc9f7efc1339` (כולל קוד ותסריטי בדיקה). הרצה דרך push marker יחיד `[false-arabic-drop750]`; אין לשגר כפילות.
4. קבלת שלב רק לפי Native completed, exit0, פלט/stderr, ארטיפקט ZIP CRC/SHA וביקורת offline עצמאית על Git blobs, קלט/פלט, ויכולת דחיית oracle מושחת. QA מקומי אינו Native, אינו differential ב־FALSE ואינו קבלה.
5. בטיחות מצביעים פיזיים מחוץ לחוזה. עד ראיות Native וביקורת עצמאית: LAST_ACCEPTED_STAGE=17, `STAGE18_IMPLEMENTED_CANDIDATE`, `STAGE18_NOT_ACCEPTED`. אין main/merge.

## היסטוריית הבסיס

Stage17 התקבל בחוזה תחום לפי run `44812320919`, source `cc39bd7007d27f00643b800338432430167dbb40`, artifact `14668076412`. QA תיעודי בסיום הקודם ב־HEAD `d6a61e29276389a49d66cd57895c884d5bff0c33`. אין להריץ מחדש Native של Stage17 ללא צורך ממוקד.

## ביצוע ב־2026-11-21

- `op35` נכתב בקומיט `74260a604d972647f31b7c749a98c8ae23de08b6`; מימוש החישוב: `D-1` → EuclideanMod(720) → `+1` → op34. אין שינוי בתא BigInt המקורי.
- מחולל נפרד ב־Python מפענח fixtures ב־Base512 ומחשב תמורות באמצעות `itertools.permutations`; בדיקת ביקורת עצמאית תשתמש באורקל Factoradic ללא ייבוא קוד הייצור או fixture כמקור יחיד.
- שער ה־Native ב־`tools/stage18_drop_order_ci.py` בודק מקור נעול, exit codes, stdout/stderr, סדר סמני הצלחה, אימות יצירת fixture ומוטנטים. הרצה אינה קבלה ללא בדיקת artifact offline נפרדת.
- בשלב כתיבת רשומה זו אין מסקנת Native verified, אין artifact audit ואין Stage18 acceptance.

## תיקון שער Stage18 בעקבות Native failure (2026-11-21)

- ריצת 44893419729, משימה 136813908499, הסתיימה בכישלון על commit `300cc893f1f1901cae1ad2b71835930cf8145466`; build ו־Unicode preflight עברו, אך Native exit=1 ב־`positive_0.false:784:7`. לא התקבל אף סמן CASE שלם. זהו כשל fixture מסוג `stack type mismatch` בהשוואת handle ישירה `b;g;!d=~`, ולא הוכחה לשגיאת תמורה ב־op35.
- ארטיפקט כשל 14702648556, SHA256 `7af629749fcf5437325525345c2987140237ebb174590592b929b75643c6a89f`, מכיל 25 קבצים תקינים ב־ZIP CRC. בקרה `bad_sign` לא הגיעה לסמן המצופה ולכן אינה PASS.
- התיקון המצומצם למחולל ב־`9abeace3ff87a231ef25881b06da6bbe9bb1be56` משתמש ב־`b;g;!d;-0=~`, כשיטת השוואת מצביעים שכבר נוסתה ב־Stage16/17. המבקר העצמאי עודכן ב־`9446b5278cb61919d2d7ba4f0a06b2b60c5b7a71`. קוד הייצור והאורקל המתמטי אינם משתנים.
- דוח כשל: `evidence/stage18_native_failure_diagnostic_2026-11-21.md`. Stage18 עדיין NOT_ACCEPTED עד Native completed עם חמש קבוצות, שני מוטנטים, artifact audit עצמאי ו־corrupted-oracle rejection. LAST_ACCEPTED_STAGE=17 BOUNDED. אין main/merge.

## קבלה תחומה ומאומתת — 2026-11-21 (גוברת על סטטוסים מוקדמים)

Stage18 **ACCEPTED_BOUNDED_CONTRACT_ONLY**; Stage17 אינו עוד השלב האחרון שהתקבל. ההרצה [44928155271](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44928155271), commit `f90e9004b562cec163dddb5c6c73dcf174818ea2`, job `136918700270`, הסתיימה `completed/success` במפרש FALSE מקורי נעול `eb3135565a8670cced3f6bbca4dbf7b014c45634`, SOURCE_PIN `9abeace3ff87a231ef25881b06da6bbe9bb1be56`.

חמשת מקטעי Native כללו 750 מקרים, 11,231 בדיקות assertion פנימיות ו־750 סמני הצלחה; בכל מקטע exit0 ו־stderr ריק. שתי בקרות שליליות (`bad_order`, `bad_sign`) יצאו exit1 עם סמני כשל צפויים. artifact `14717932567` קיים, SHA-256 `f8fe2c0f3f1b1f5a345e2a7524c4ad38a0e9a9073ebad58480fde7e43b88990b`, 41 entries ו־ZIP CRC תקין. בשחזור בלתי תלוי של קלטי Base512 הושוו כל 750 התוצאות לתמורה לקסיקוגרפית לפי factoradic; אורקל שהושחת במכוון נדחה. כל ששת קובצי source/fixture/QA אומתו בנפרד לפי SHA-256 של תוכנם מול GitHub בקומיט המקור, ושני קובצי הייצור גם לפי Git blob SHA1. תוצאות ומזהים מפורטים ב־`evidence/stage18_bounded_acceptance_2026-11-21.json`. מבקר הריפו הותאם ל־SHA של הרצת Native המוצלחת ב־`14e57f456722ca29c362739b017ec63027b52727`; הוא עצמו לא הורץ בסביבה מקומית ללא clone, אך בוצעה ביקורת ZIP נפרדת בפועל.

**גבול קבלה:** הקלטים הקנוניים והמצביעים המוקצים כהגדרת החוזה. לא נבדקה בטיחות מול מצביעים פגומים פיזית, הקצאות חסרות או heap מושחת. לא נבדקו ביצועי Native לכל טווח BigInt אפשרי. אין merge/main. **אין הרשאה לפתוח שלב נוסף**; מעבר לשלב נוסף דורש החלטת משתמש.
