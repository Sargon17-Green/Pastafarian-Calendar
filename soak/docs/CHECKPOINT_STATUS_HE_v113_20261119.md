# v113 — החלטת מצב: אי־התאמה מקורית מאושרת, הקפאת dispatch ושימור ראיות

**תאריך בדיקה:** 19 בנובמבר 2026.  
**מאגר:** `Sargon17-Green/Pastafarian-Calendar`. **ענף עבודה:** `qa/soak-readiness-20261114`. **`main` אינו מותר לשינוי.**

## 1. ההכרעה המדעית והאירוע

[Issue #29](https://github.com/Sargon17-Green/Pastafarian-Calendar/issues/29) נפתח בנפרד מ־[חוזה #27](https://github.com/Sargon17-Green/Pastafarian-Calendar/issues/27) לאחר שמקור Ada+తెలుగు המקורי החזיר ערך שאינו תואם למקור Python+Türkçe ביום `c=t=-15055671`:

| שדה | Ada `a2fb6811` | Python `0e4e7588` | TypeScript `cc3a613e` | Fortran `23349b97` |
|---|---:|---:|---:|---:|
| שנה | 5000 | 5000 | 5000 | 5000 |
| אינדקס קציצה | 10 | 10 | 10 | 10 |
| יום בקציצה | 503 | 503 | 503 | 503 |
| **אינדקס חודש: הבדל ראשון** | **30** | **20** | **20** | **20** |
| יום בחודש | 52 | 56 | 56 | 56 |

ממיר Ada פעל **כמקור אמיתי**, לא מתוך סקריפט שחזור. [v103 run 44394781099](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44394781099) `completed/success` הניב `V103_ADA_ORIGINAL_FCT_NATIVE -15055671 -15055671 5000 10 503 30 52`; השוואת חמשת השדות מצאה FAIL. משמעות `success` היא שריצת הבדיקה והתיעוד הסתיימה בהצלחה, לא תוצאת soak תואמת.

מקור Fortran במבחן חדש, [v106 run 44397451131](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44397451131) `completed/success`, הפיק `5000 10 503 20 56` לאחר קומפילציה של קובצי המקור הבלתי־משתנים של אותו ענף. שמונה בדיקות קואורדינטות מקור עברו. זו **ראיית התאמה של יום אחד**, לא של שנה ולא של עצמאות אלגוריתמית.

**עצירת dispatch:** `soak/control/confirmed_first_original_mismatch_dispatch_halt_v108.json` נוצרה ב־QA, `decision=STOP_NEW_NATIVE_SOAK_DISPATCH`. עד להסדרת המחלוקת אין לשגר עבודות soak מקוריות חדשות, אין להרוג עבודות קיימות ואין לאשר שנה שלמה. זה **מנעול תפעולי ומבוקר־ראיות**, אך אינו חוסם אוטומטית כל workflow ישן ב־GitHub; יש להוסיף שערים מפורשים לכל משגר לפני חידוש ההרצות. מאז זוהתה אי־ההתאמה לא שוגרו בסבב זה המרות מקוריות חדשות; v106 הוגשה לתור לפני גילוי הכשל.

## 2. שחזור אי־התאמה קריפטוגרפי ללא מקור חי

[v109 run 44478719294](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44478719294): `completed/success`, **12/12 בדיקות**. שלושת ארכיוני הראיות המקוריות של Ada, Fortran ו־Python/TypeScript עברו SHA-256 ו־CRC. נתוני המקור הושוו מחדש מתוך השורות הגולמיות ומניפסטים נעולים. הפלט המדעי הוא `CONFIRMED_DIFFERENTIAL_FAIL` ו־`stop_new_native_soak_dispatch=true`, ללא הרצת F(c,t) נוספת.

- Ada artifact `14472835490`, SHA256 `3d8c594ae761aa6eeb8c11b241755b2f11ef472d41483ffb5be0c1cdc2bd8cbe`, 3,641 בתים, 9 קבצים.
- Fortran artifact `14473652463`, SHA256 `7f8e57308aee0c80ffedc9634e59b65d11a1bc94982830dd3217623878e3e48f`, 279,096 בתים, 26 קבצים.
- Python/TypeScript artifact `14469537094`, SHA256 `bb256c2a8e6d599f7f78aa2264129d4ab4ff0dc0c9b8680077149de55b752ff1`, 24,119 בתים, 53 קבצים.
- v109 artifact `14507736346`, תוצאת שחזור והוכחות שלילה.

הרצת v109 ראשונה `44478412702` נכשלה משום שה־SHA שהועתק למנעול v108 היה בן 63 ספרות. הקובץ האמיתי נבדק מול גיבוב מלא בן 64 ספרות, הרשומה תוקנה בקומיט `78e37b4c848a2cb448680428ee6f7f884fd09d21`, והרצת v109 המתוקנת עברה. **לא מדובר בכשל ממיר חדש**, אלא בשגיאת תעתיק בראיות המעקב.

## 3. אבחון אלגוריתמי סטטי

[v110 run 44479758816](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44479758816): `completed/success`, **10/10 בדיקות**; לא הופעל ממיר תאריכים.

קוד Ada המקורי `src/month_weaving.adb::From_Choices` מתחיל תמיד את השזירה בכל פתיחות החודשים `1..M`, מסדר רק את הימים הפנימיים ולבסוף משלים את כל סגירות החודשים `1..M`. ב־Python `MonthWeavingFamily._moves/unrank1` יש אפשרות לסיים חודש לפני פתיחת הבא, בכפוף לסדר הפתיחה והסגירה הכולל.

לשני חודשים באורך `(4,4)`, enumeration ממצה הוכיח **20 שזירות חוקיות במרחב Python**, ורק **6 במרחב Ada**. סדר `(1,1,1,1,2,2,2,2)` חוקי ב־Python אך אינו אפשרי ב־Ada. נוסף על כך, Ada בוחרת כרטיסי מקום `Tickets` מתוך זרם משתנה במקום דירוג גלובלי של `family.count()` כנהוג ב־Python. זו **אי־שקילות מבנית מוכחת**, שאינה מוכיחה עדיין באיזה שלב נוצרה אי־ההתאמה של יום היסוד. [דיון טכני ב־Issue #29](https://github.com/Sargon17-Green/Pastafarian-Calendar/issues/29#issuecomment-7002605195).

ההרצה הראשונה של v110 `44479621502` נכשלה ב־SyntaxError בסקריפט AST שב־Workflow, ללא הרצת מקור; הגרסה המתוקנת `44479758816` עברה.

## 4. שימור ארוך טווח של ראיות FAIL

[v112 run 44480192379](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44480192379): `completed/success`. מנהל השימור קיבל בקשה יחידה; הוריד את שלושת הארכיונים המקוריים, שחזר באמצעות v109 את אי־ההתאמה, ואז העלה שני ארכיוני ראיות גולמיות חדשים + מניפסט טיוטה ל־**GitHub Draft Release ID 451008226**.

שלושת הנכסים הורדו מחדש, הושוו בבתים ונבדקו לפי SHA-256. [טיוטת השימור](https://github.com/Sargon17-Green/Pastafarian-Calendar/releases/tag/untagged-708cfa434d064a7df5c0) מכילה:
- `original-ada-first-difference-v103.zip` — 3,641 בתים.
- `original-fortran-confirmation-v106.zip` — 279,096 בתים.
- `original-first-difference-manifest-v112.json` — 1,141 בתים.

קודם נשמרו 8 ארכיוני מקור בשתי טיוטות Release (v091/v098), וארכיון נוסף בשמירת v105. לכן **11 ארכיוני ZIP מקוריים ו־4 מניפסטים נשמרים ב־4 טיוטות**, כולם אצל GitHub — עדיין אין ספק גיבוי חיצוני עצמאי. ארכיון Python/TypeScript v101 מגובה בנפרד בטיוטת v105 ID `450580215`; אין צורך לשכפל אותו בטיוטת v112.

## 5. ספירת ימי יעד ומצב המשימה הכוללת

במדגמים הושגו **17 ימי יעד ייחודיים עם התאמה בין לפחות שני מנועים**. שלושה ימי יעד השיגו התאמה בקרב שלושה מנועים מקוריים: שני ימים של Python/Kotlin/TypeScript, ועוד יום יסוד של Python/TypeScript/Fortran — אך האחרון **אינו תואם ל־Ada**. ארבעה מנועי מקור שונים נצפו עתה בבדיקות F(c,t), ורק שלושה מהם תואמים זה לזה ביום היסוד. אין לשנות את רשימת הממירים כדי להציג PASS כולל.

- **0** שנות מקור מלאות ו־**0/10,000** שנות soak שאושרו.
- **0** הוכחות לעצמאות אלגוריתמית של כל ענפי הממירים.
- אין ביקורת קאנונית חיצונית עצמאית של כל השנים; אין אישור משאבי Windows חדש; אין להתחיל הרצת 10,000 שנים.
- v099 הגן לוגית על משבצות עובדים מ־completion לא תקין, אך אינו מערכת native Windows מוסמכת.
- המהירות שנצפתה ב־v101 היא מדגם Linux תחום (Python כ־9.80 שניות ליום, TypeScript כ־24.63) ולא תחזית אמינה לכל השנים.

## 6. המשך בטוח

להותיר HALT על שיגור מקור; לבדוק off-line את מימוש השזירה ב־Ada ואת התאמתו להגדרת הקאנון, תוך שמירה על source commit הקיים כראיית FAIL. כל תיקון לממיר Ada חייב להתרחש בענף פיתוח נפרד ובגרסה נעולה חדשה, ולא במתאם השקוף של soak. יש לסקור ולאכוף מכנית את שער העצירה בכל משגרי CI ישנים לפני חידוש הרצות. אין לזקוף סימון PASS להצלחה תפעולית של בדיקת FAIL.

**RESUME LOCK:** `PASTAFARI_SOAK_V113 | V103=CONFIRMED_ORIGINAL_ADA_MISMATCH | V106=FORTRAN_ONE_DAY_MATCH | V109=3_ZIP_REPLAY_12OF12 | V110=STATIC_WEAVING_10OF10 | V112=DRAFT_FAIL_EVIDENCE_ARCHIVED_3OF3 | HALT_NEW_NATIVE_DISPATCH=true | MATCHED_UNIQUE_DAYS=17 | 3ENGINE_MATCHED_DAYS=3 | FULL_YEARS=0 | 10000_ACCEPTED=0 | MAIN_UNTOUCHED`.
