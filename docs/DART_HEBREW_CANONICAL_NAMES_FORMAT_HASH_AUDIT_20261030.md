# Dart+עברית — בקרת שינוי עיצוב בקובץ הקטלוג הקנוני

תאריך: 2026-10-30  
PROJECT_ID: PC-BRANCH-DART-HEBREW  
ענף: `Dart+עברית`, לפני תיקון נעילה: `bf653c492c84682c876fcabc6c449c5cd2cd5e92`  
ריצת הראיה: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41040380021 — Native PASS, verify FAIL בנעילת השמות.

## ממצא בדיקה בלתי תלויה

בדיקת `CANONICAL_NAMES_LOCK.sha256` נכשלה לאחר הרצת `dart format` ששינתה רק שתי הוראות `throw RangeError.range` בקובץ `lib/src/source_language_catalog.dart`. שתי ההוראות פוצלו לשורות; לא השתנו ערכי `cutletNames` או `monthNames`, שדות `canonicalIndex`, שמות, סימני Unicode, סדר המערכים, טיפוסים או פונקציות. לא נעשתה כאן כתיבה לקובץ Dart.

SHA־256 נעילה היסטורי:
`bdd647d8aaa7caa0885b0c53b0eee89591ecd847ab3705dd264074913396bd52`

SHA־256 של קובץ Dart **המעוצב**:
`592808bef55ab1fb7648c234d07c39c5c2ec198fbe6750db2eb1d6a282481c72`

אימות עצמאִי: חושבה גיבוב SHA־256 בשימוש אלגוריתם מדויק שווקטורי הבקרה שלו נבדקו (`""`, `"abc"`). כאשר הפכנו *רק* את עיטוף שתי השורות במחרוזת הקובץ המובאת מ־GitHub, התקבל בדיוק גיבוב הנעילה הישן. התוצאה קושרת את שתי הגרסאות לשינוי מרווחים בלבד, ולכן אין כאן היתר לשינוי שמות קנוניים.

## החלטת תיקון

נדרש לתקן את שורת הגיבוב היחידה ב־`CANONICAL_NAMES_LOCK.sha256` לערך של הקובץ המעוצב, תוך שימור אכיפת SHA־256 המלאה על הקובץ. אין לשכתב את קובץ השמות, אין להחריג אותו מבדיקות עיצוב ואין להסיר או לרכך את שער verify. תיקון הנעילה **אינו תחליף** ל־Native CI חדש על HEAD החדש.

תנאי שחרור: חזרת verify ו־Dart Native על SHA חדש באותו ענף, כולל בדיקות פורמט `dart format`, `dart analyze`, ו־`bin/stage1_tests.dart`. אין לסמן `LAST_COMPLETED_STAGE=1` או `READY` לפני קבלת הראיות. אין `main` או merge.
