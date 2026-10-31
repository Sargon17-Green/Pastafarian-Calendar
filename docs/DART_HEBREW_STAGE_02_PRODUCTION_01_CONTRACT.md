# Dart+עברית — Stage 2 / PRODUCTION01: חוזה מנייני עבודה

PROJECT_ID: PC-BRANCH-DART-HEBREW
BRANCH: Dart+עברית
STAGE: 2
SLICE: PRODUCTION01
PRECONDITION: Stage2/DISCOVERY01 baseline verified on 6d05ce1442c7746010e95d02a8de925862167b7b, run 41179585164, 3/3 completed/success.
LAST_ACCEPTED_FULL_STAGE: 1

## תחום
מימוש production עצמאי, תחום ובלתי תלוי ב-`test_support/normative_reference.dart`, עבור מניין יום וחמשת מנייני העבודה בלבד. אין עדיין תוצאה של חמשת רכיבי התאריך. השלד `calendarDateSpaghetti` חייב להמשיך לדחות קריאה עם הודעת StateError המקורית. אין לשנות את מנגנון השמות או לעבור ל-main.

## קלט ופלט
קלט: שני ימי BigInt שלמים, calculationDay ו-targetDay; יום יסוד F=-15055671.
פלט ביניים: `MonsterWorkCounts(action,target,distance,connection,direction)`, כאשר:
- דרגת F היא 1; דרגות F-k הן 2k; דרגות F+k הן 2k+1, עבור k חיובי.
- action ו-target: דרגות שני הימים.
- distance: מספר הימים הכולל את שני הקצוות, |targetDay-calculationDay|+1.
- connection: סכום שתי הדרגות.
- direction: 1 כאשר target מוקדם מ-calculation, 2 בשוויון, 3 כאשר target מאוחר.
- חישוב הדרגה ב-production מבוסס על היסט חתום, ערך מוחלט והזזה ביטית. קביעת הכיוון מבוססת על compareTo. אין קריאה ל-oracle בביצוע.

## אינטגרציה מבוקרת
`MonsterManager.executeUnbuilt` מבצע את המניינים לפני דחיית התאריך; חמשת השדות נרשמים בתור מדדי context בפורמט `work.*`; direction נרשם כ-BigInt. ה-trace מסתיים ב-`WORK_COUNTS_READY|STAGE_NOT_BUILT`. שימור `bootstrap.calls` והודעת ה-throw המקורית מחייב. אין לשנות את טיפוס הפלט של `calendarDateSpaghetti` כעת.

## Oracle ובדיקות
- מנייה ישירה ועצמאית של 25 ימים בסדר F,F-1,F+1,...,F-12,F+12; מפת דרגות המבחן נבנית רק מן האינדקס, לא מן המימוש ולא מן ה-oracle הנורמטיבי.
- 49 זוגות מכוונים (7x7) נבדקים עבור חמישה שדות, מדדי context והדחייה הצפויה.
- גבולות F±(2^127+19), כולל זוג קיצון, מרחק כולל, סכום דרגות וזוגיות.
- ספירת assertions אמיתית ונפרדת; שער מינימלי 500 בדיקות ו-49 דחיות; אין לדווח PASS סטטי במקום לוג.
- רגרסיה: verify, Stage1 Native, Discovery01 Native ו-Production01 Native כולם completed/success על אותו SHA. פורמט 0 שינויים, analyze 0 issues, הפקת `PRODUCTION01_COUNTS_PASS` בלוג.
- תקציב עבודה: job Production01 עד 8 דקות; אין בדיקות לוח שנה מלא, בניית שנים, רוטב או מבני חודשים.

## תנאי קבלה ומשמעות
קבלת מקטע PRODUCTION01: ארבעת jobs ב-CI completed/success; בלוג לפחות 500 checks, 49 production_stub_cases, five_component_calendar_ready=false; תוצאת verify והיעדר כשלי רגרסיה. מעבר למקטע production הבא ייערך רק אחרי תנאי אלה. גם לאחר קבלתו Stage2 בכללותו אינו PASS ואינו מנוע תאריך מלא. אין להסיק עד פגם legacy או לבצע מיזוג/פרסום.
