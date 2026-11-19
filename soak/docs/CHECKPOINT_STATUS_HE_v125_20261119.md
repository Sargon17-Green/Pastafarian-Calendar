# v125 — חידוש: מנגנון השזירה המדויק, ניסוי Ada נפרד וסיכון דירוג רחב

**תאריך:** 19.11.2026, שעון ישראל. **מאגר:** `Sargon17-Green/Pastafarian-Calendar`.

## 1. גבולות הסבב

ה־QA הראשי: `qa/soak-readiness-20261114`; ענף ניסוי מתמטי נפרד: `qa/ada-pure-full-month-weave-v122`. **`main` לא שונה.** מנעול `STOP_NEW_NATIVE_SOAK_DISPATCH` נותר בתוקף בעקבות [Issue #29](https://github.com/Sargon17-Green/Pastafarian-Calendar/issues/29).

ארבעת מנועי המקור שנבדקו בעבר נותנים ביום היסוד `c=t=-15055671`:
- Python+Türkçe, TypeScript+मराठी, Fortran+English: `(5000,10,503,20,56)`;
- Ada+తెలుగు: `(5000,10,503,30,52)`.

זוהי אי־התאמה מקורית מאושרת בשדה אינדקס החודש. השוואת מקור שלא עברה אינה הופכת ל־PASS בגלל הצלחת Workflow המתעד FAIL.

החסימה ברמת GitHub Job על 24 משגרי מקור ונגזרות בענף QA, ונעילת קובצי Git blob של 31 תהליכי ביקורת, אומתו ב־[v116 run 44610410437](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44610410437), 11/11 בדיקות. **אין כאן הגנה אוטומטית מפני rerun של קומיט ישן או הפעלה בענף אחר.**

## 2. v119–v120 — מנגנון שזירה מדויק ב־Python, ללא המרות תאריכים

נוצר `soak/runner/exact_month_weaving_pure_v119.py`: משפחת שזירות עם סדר הופעה ראשון עולה וסדר הופעה אחרון עולה; ספירת כל המשפחה באמצעות נוסחת עדכון מצטברת של DP; דירוג והיפוך דירוג לקסיקוגרפיים עם מספרים שלמים מדויקים. **אין בקוד זה ייבוא או קריאה ל־`Calendar_Date` או ל־`F(c,t)`**.

`soak/process_tests/test_exact_month_weaving_pure_v120.py` מכיל **14 בדיקות**, כולל:
- אורכי חודשים `(2,2)`: משפחה מלאה של 2 לעומת משפחת שתי מסילות של Ada בגודל 1.
- `(4,4)`: 20 לעומת 6. עד הנגד `(1,1,1,1,2,2,2,2)`.
- מיצוי שזירות קטנות ובדיקת `rank(unrank(r))=r`.
- הצלבה של ספירות ושזירות עם `MonthWeavingFamily` המקורי שננעל ב־Python, ללא המרת תאריך.
- ספירה מדויקת של 47 חודשים ו־5,778 ימים.

בניסוי מקומי תחום, עבור `L=(123×46,120)`, מספר השזירות דורש **31,483 ביט**; SHA-256 של הייצוג הבינארי big-endian המינימלי: `d2fad6a82c67a5d2c4422110f4f11637a70fda1125dc03fe1f3288c2093771bd`. זו **תוצאה מקומית**, ללא אישור CI של התאמה למקור המקורי עד שיושלם השער.

הקוד וה־Workflow הוכנו, אולם עריכת YAML ראשונה השתבשה בשל פרשנות `$'` במחרוזת החלפה, ולכן [run 44613943934](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44613943934) הסתיימה ב־failure ללא Jobs. קובץ ה־YAML נבנה מחדש מהגרסה התקינה וננעל מחדש במניפסט ה־31 Git blobs בקומיט `dbe51b7f4963984b539fc67f2d67b23c669fc931`. [v120 CI run 44614320812](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44614320812) הייתה `queued` בבדיקה האחרונה. [חסימת v116 על אותו שינוי 44614320681](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44614320681) אף היא `queued`. **אין שיגור כפול ואין קרדיט PASS.**

[ניתוח הנוסחה המדויקת v121](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/qa/soak-readiness-20261114/soak/docs/EXACT_MONTH_WEAVING_DP_FORMULA_HE_v121.md) כולל את הספירה, הוכחת הנוסחה לשני חודשים וניתוח דרישות מספרים גדולים.

## 3. v122 — ניסוי Pure Ada בענף נפרד, לא תיקון של הממיר

נוצר ענף `qa/ada-pure-full-month-weave-v122` מה־QA עם חבילת `soak/ada_pure_candidate_v122/`: קובצי `pure_full_weave_v122.ads/.adb` ותוכנית בדיקה טהורה `test_pure_full_weave_v122.adb`. נעשה שימוש ב־`Ada.Numerics.Big_Numbers.Big_Integers` כדי לחשב `Count(L)` עם רקורסיית DP מצטברת, ללא `Normative_Oracle.Calendar_Date`.

לבדיקת הכמויות הקטנות נבחרו ערכים שקיבלו אימות במודל העצמאי:
- `(2,2)→2`; `(4,4)→20`; `(2,3,4)→50`;
- `(4,4,4)→1,301`; `(3,3,3,3)→1,266`; `(1,2,3)→3`.

בדיקת הגודל המרבי אמורה להדפיס את `Count((123×46,120))`; תהליך ה־CI מבצע אימות מול `MonthWeavingFamily` המקורי של Python ומול SHA-256 הקבוע של המספר. [ריצת GNAT המועמדת v122 44616007819](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44616007819) הייתה `queued` בבדיקה האחרונה; **טרם הוכחו קומפילציה, התנהגות בגבול או תאימות ל־Python ב־Ada**. החבילה היא **Count בלבד**, ללא `Rank` או `Unrank` ב־Ada, ולא שינוי של מימוש תאריכים.

## 4. v123–v124 — סיכון נפרד בלולאת `choose_rank_wide` של Python

ב־Python המקורי, `choose_rank_wide` יוצר מספר בבסיס `M=2^127−1` ודוחה מספרים מחוץ לטווח הקבלה באמצעות `while` המתקדמת **צעד מספרי אחד בכל פעם**. עבור N ענק, גם מספר צעדים בודדים מייצג מרחק אדיר.

בקלט סינתטי חוקי לפונקציית העזר עם `N` של 31,483 ביט, `places=248`, `first=M−floor(M/65,536)` ו־`step=±1`, חישוב מקומי מדויק הראה שהמצב הראשון נדחה בשני הכיוונים. מספר צעדי הקבלה הנדרשים עלול להיות בעל **31,480 ביט (+1)** או **31,482 ביט (−1)**. הסימולציה אינה מריצה את הלולאה העצומה: היא משתמשת בנוסחת קפיצה זהה־תוצאה. ל־+1 דילוג ל־1; ל־−1 דילוג לגבול הקבלה A.

**זהו קלט סינתטי של `Answer_Stream` בלבד; לא הוכח שהוא נוצר מ־`Sauce` על יום תאריך אמיתי.** לפיכך זהו סיכון ביצועים משמעותי ברמת פונקציית העזר, ולא כשל של תאריך מסוים.

נוצרו `soak/runner/wide_rank_rejection_static_v123.py` ו־`soak/process_tests/test_wide_rank_rejection_static_v123.py` עם **9 בדיקות טהורות** להשוואת לולאת דחייה חסומה מול קיצור מתמטי. קבצים אלה **טרם הורצו ב־CI**, ולכן אין להעניק להם PASS. [ניתוח v124](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/qa/soak-readiness-20261114/soak/docs/WIDE_RANK_REJECTION_HANG_RISK_HE_v124.md). נפתח [Issue #31](https://github.com/Sargon17-Green/Pastafarian-Calendar/issues/31), נפרד מהכשל המדעי המקורי ב־Ada.

## 5. המשך ללא הפעלת מקור

1. לבדוק `completed/log` של v120 (מבחני Python ומתמטיקה), v116 (מלאי/חסימות), ו־v122 (Ada טהור). `queued/in_progress` אינם חסימה ואינם PASS; אין לשגר אותם שוב.
2. לתקן פגמים בהדגמות המתמטיות בלבד אם יתגלו, בלי לערוך את מקור הממירים הנעול ובלי להריץ F(c,t).
3. לאחר אישור ספירת `Count` ב־Ada, לקדם **מימוש נפרד של `Rank/Unrank` ו־`Choose_Rank_Wide` בגרסת מועמד**, עם מבחני יחידה טהורים והוכחת שקילות למקור הנבחר; אין לקשר לממיר תאריכים עד להכרעת Issue #29.
4. להכריע בנפרד את בעיית לולאת הדחייה של Python ואת שאלת השגת זרמי דחייה ממקרי `Sauce` אמיתיים. אין להשמיט Python או לשנות Wrapper בשקט.
5. רק אחרי הסדרת אי־ההתאמה, מפקד המנועים, בקרות Windows, השנה המלאה ויכולת השחזור, מותר להתחיל 10,000 שנות soak.

**מצב סטטיסטי שאינו משתנה:** ארבעה ממירי מקור נצפו; 17 ימי יעד ייחודיים שבהם לפחות שני מנועים הסכימו; 3 ימים שבהם שלושה הסכימו; **0 שנות מקור מלאות**, **0/10,000 שנות soak**. אין תעודת עצמאות אלגוריתמית כוללת ולא אישור מקור קאנוני עצמאי.

**RESUME:** `PASTAFARI_SOAK_V125 | ADA_NATIVE_FIRST_MISMATCH_CONFIRMED | QA_24_JOB_HALT_ACTIVE | V120=QUEUED_NO_CREDIT | V116_RECHECK=QUEUED_NO_CREDIT | ADA_PURE_COUNT_V122=QUEUED_NO_CREDIT | PY_REJECTION_RISK_V123=PROVEN_SYNTHETIC_NOT_REAL_DATE | V123_CI=NOT_RUN | FULL_YEARS=0 | 10000_CREDIT=0 | MAIN_UNCHANGED`.
