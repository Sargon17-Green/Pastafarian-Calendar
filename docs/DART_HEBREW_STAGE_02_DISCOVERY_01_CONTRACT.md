# Dart+עברית — Stage 2 / DISCOVERY01: חוזה חקירת הבדל ראשון

PROJECT_ID: PC-BRANCH-DART-HEBREW
BRANCH: Dart+עברית
BASELINE_PARENT: bbf4cddd276d5e400374271bfa9d0a46d1002f46
STAGE: 2
SLICE: DISCOVERY01
STATUS: DISCOVERY / NO VERIFIED DEFECT
LAST_ACCEPTED_STAGE: 1

## מקור מאומת והבחנה קריטית
- שלב 1 התקבל על SHA `0bab2e5b98100bdda575cebdc8cd4aedc6ea3d18` בריצת [41087390426](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41087390426): verify ו-Native עברו.
- ריצת התיעוד [41097524899](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41097524899) הסתיימה completed/success על `bbf4cddd276d5e400374271bfa9d0a46d1002f46`: שני jobs עברו. אין לקרוא לריצה מחדש על אותו SHA.
- `lib/src/monster_base.dart` מכיל כעת רק dispatcher שזורק `StateError` בכוונה לפני מימוש המסלול.
- `test_support/normative_reference.dart` מכיל oracle נורמטיבי, אך אין כאן עדות לקיום מימוש `legacy` פעיל או למסלול production שמחזיר חמישה רכיבים. שלד מכוון אינו פגם היסטורי, ואסור לסווגו כ-expected-red.
- לא נוגעים בקטלוג השמות הנעול, ב-`main`, בייצור תאריכים מלא או ב-API החיצוני של המסלול.

## מטרת DISCOVERY01 והכרעה הנדסית
להתחיל ממקטע דיסקרטי, קטן וזול: מניין היום ו-`workCounts` סביב יום היסוד. יש לבדוק את תשתית ה-oracle ואת מצב השלד לפני כל טענת הפרש מול legacy. הבחירה במקטע זה נובעת מהיותו מבוא הכרחי לקלט חמישיית החישוב, עם גבולות מתמטיים ברורים ובדיקה עצמאית קלה.

## חוזה קלט, פלט ו-oracle עצמאי
- קלט החקירה: זוגות `BigInt(calculationDay, targetDay)`; `foundationDay=-15055671`; אין המרה ל-`int` בחישוב המספרים הגדולים.
- פלט החקירה: תוצאת בדיקת מניין היום, חמשת שדות `workCounts`, ועדות ששלד production עדיין דוחה את הקריאה בהודעת `StateError` הצפויה. **אין** פלט תאריך production ואין עד פגם legacy.
- oracle עצמאי: בונים סדר ימי בדיקה על ידי מנייה ישירה `F, F-1, F+1, F-2, F+2, ..., F-12, F+12` (25 ימים), ומציבים את אינדקס הרשימה כמניין הצפוי. לא משתמשים ב-`NormativeReference.dayCount` כדי לייצר את ערך ה-expected.
- מבחן זוגות מכוון: 7 היסטים `{-12,-2,-1,0,1,2,12}` לכל אחד משני הימים (49 זוגות), עם אימות action/target/distance/connection/direction וכניסה מבוקרת לשלד.
- גבולות מספריים: `F ± (2^127+19)`, אימות מניין זוגי/אי-זוגי וערכים מדויקים ללא overflow או צמצום.
- בקרת שלילה: כל 49 קריאות ה-production חייבות להמשיך לזרוק `StateError` עם הודעת האתחול המדויקת; קבלת חמישייה בשלב זה נחשבת הפרת baseline, לא הצלחת המימוש.
- אין תלות בקבצים חיצוניים, זמן מערכת, רשת, seed אקראי או אלגוריתמים של ענפים אחרים.

## שערי ביצוע מדידים
1. `dart pub get` ב-Dart SDK 3.13.2.
2. `dart format --output=none --set-exit-if-changed bin/stage2_discovery01.dart`.
3. `dart analyze` על הענף.
4. `dart run bin/stage2_discovery01.dart` חייב להסתיים 0 ולהפיק `DISCOVERY01_BASELINE_PASS` עם ספירת בדיקות אמיתית ו-`verified_legacy_witnesses=0`.
5. GitHub Actions job `dart-hebrew-stage2-discovery01` completed/success על SHA החדש; queued/in_progress אינם PASS.
6. תקציב CI: 8 דקות; 25 ימי מנייה, 49 זוגות, שתי נקודות `BigInt` גדולות. אין הפעלת year structure, sauce או חישוב 5 רכיבי תאריך מלאים.

## שער מעבר לחקירת פגם אמיתי
רק לאחר זיהוי קובץ legacy מסוים ו-API שמחזיר ערכים בני השוואה, תיבנה בדיקת differential לאותו זוג קלט, לאותם חמישה רכיבים ולאותו oracle. עדות expected-red תתקבל רק על סמך הרצה completed עם הקלט המדויק, הערך הצפוי, הערך שהתקבל, branch, SHA ולוג. אם מקור legacy אינו קיים, המשך העבודה יהיה תכנון/מימוש עצמאי של רכיב production ראשון, לא המצאת עד כשל. אין העתקה מענף אחר.

## תיחום תוצאת הסבב
`DISCOVERY01_BASELINE_PASS` מאשר **בדיקת תשתית וגבולות בלבד**; אינו מאשר ששלב 2 הושלם, אינו מוכיח תקינות תאריך מלא, אינו PASS ל-differential, ואין בו הרשאה למזג או לפרסם.
