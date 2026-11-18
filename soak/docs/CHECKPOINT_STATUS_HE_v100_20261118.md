# נקודת שחזור v100 — שלושה ממירי מקור, גיבוי TypeScript, והקשחת מתזמן שני הנתיבים

**תאריך:** 18.11.2026 (ישראל); ראיות CI מאותו תאריך ב־UTC.  
**מאגר:** `Sargon17-Green/Pastafarian-Calendar`.  
**ענף עבודה:** `qa/soak-readiness-20261114`; לפני כתיבת נקודה זו HEAD=`ccb47c1d63259b60aee0f585f07d466541b4f2cc`.  
**`main` נבדק:** `56bc4173aae4975ded019ef5ab5a36249f1424df`, ללא שינוי.

## A. v096 — הצלבה משולשת מקובצי מקור נעולים, PASSED CI

[הרצת v096 הסופית 44375583283](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44375583283): `completed/success`, 7/7 בדיקות שלילה/ראיות. שתי חבילות מקור אמיתיות עברו SHA-256 ו־CRC, וכל הפלטים המקוריים חושבו מחוץ לשער הראיות הזה:
- Python REF-41 + Kotlin PROD-KT-CY: artifact `14281261657`, run `43976583803`, ZIP SHA `b7f250a98aea07acb4a78bf074e75c5f72d950f00a1d32d7bc81c6eb8c464b32`.
- TypeScript+मराठी + Python REF-41: artifact `14454273351`, run `44363057604`, ZIP SHA `a798cac07e77e704c97af637009cf1fcbcaf1f1358767f3f7690bad4acb54a70`.

התוצאה המנורמלת ב־`c=-15055671`:
- `t=-15055660`: `(5000,14,11,1,42)`.
- `t=-15055659`: `(5000,14,12,42,45)`.

שני צמדי פלטי Python ששוחזרו מהרצות נפרדות היו **byte-identical**, וכל חמשת השדות המספריים התאימו בשלושת המקורות, כולל אינדקסי Kotlin ושמות מקור Marathi שמופו באמצעות הקטלוג המקורי. 20 השוואות שדות דו־מקוריות על שני ימי היעד; אפס ימי יעד ייחודיים חדשים; אפס אישור לשנת מקור.

**תיקון הבדיקה:** [ניסיון v096 ראשון 44365976004](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44365976004) נכשל ב־SyntaxError של כלי האימות, **לא** בכשל מקור. התיקון בקומיט `730de2b8da246fc6047199a1458ee62baffc1599` הוסיף סוגריים ל־guard הקואורדינטות ובדיקת AST מוקדמת; התוצאה הסופית עברה.

## B. v098 — ארכיון TypeScript הועתק ל־GitHub Draft Release ואומת בהורדה חוזרת

[הרצת v098 סופית 44378176710](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44378176710): `completed/success`, 12/12 בדיקות gate, קריאה מחדש של 17 קובצי ראיה וגיבובי 69 קובצי מקור ה־TypeScript, ותוצאת `V095_THIRD_ORIGINAL_SOURCE_PINNED_TWO_DAYS_REPLAY_PASS_NOT_YEAR`.

בוצעה העתקה ללא שינוי של ה־ZIP המקורי `a798cac07e77e704c97af637009cf1fcbcaf1f1358767f3f7690bad4acb54a70` (10,817 בתים) ושל `typescript-original-manifest-v098.json` (982 בתים) ל־**Draft Release ID 450437205**, `tag_name=soak-native-typescript-marathi-ordinal1021-v098`, טיוטה לא מפורסמת. שני הנכסים **הורדו מחדש והושוו byte-for-byte** למקור; גיבובי ה־SHA אומתו. [קישור לטיוטת השימור (לבעלי הרשאה)](https://github.com/Sargon17-Green/Pastafarian-Calendar/releases/tag/untagged-179f1730d1a377470d53).

ה־Release הוותיק `448191573` מכיל שבעה ארכיוני מקור Python/Kotlin (1015–1021) ומניפסט, גם הוא במצב Draft. [הגיבוי הקודם](https://github.com/Sargon17-Green/Pastafarian-Calendar/releases/tag/untagged-27b266c190c1a7ea0fb3) אומת ב־v091. לפיכך נשמרו **8 ארכיוני ZIP מקוריים + 2 manifests בשתי טיוטות**. הגיבוי נשאר אצל אותו ספק GitHub; אינו mirror עצמאי ואינו חסין למחיקה ידנית.

**כשלים לפני PASS:** [v098 ראשון 44376838639](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44376838639) אישר את המקור אך נכשל במציאת טיוטה שהריצה יצרה ברגע ההרצה. נוספה בקשת ניסיון חדשה וקונטרול של ה־API עם Retry, בלי לשנות מקור, בלי להריץ עוד `F(c,t)` ובלי לשכפל Release. קובצי הקבלה `soak/runner/approve_third_original_archive_v098.py` וה־Workflows מאשרים כעת רק בקשת מקור אחת חדשה (`-retryNN` מוגבל), עם 12 בדיקות נפרדות.

## C. v099 — מתזמן שני הנתיבים fail-closed

[הרצת v099 44377472404](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44377472404): `completed/success`, **12/12 בדיקות**. הקוד `soak/runner/two_lane_scheduler.py` תוקן, כך שדיווח סיום שגוי אינו משחרר עובד חי לוגי:
- זמן לא מספרי, `NaN`, אינסוף, זמן שהולך אחורה, `verified` שאינו בוליאני או סדר ממירים לא צפוי — כולם עוצרים שיגור, משמרים את זהות העובד ומשאירים את המשבצת תפוסה. אין הריגה או הפעלה מחדש.
- אי־התאמה אמיתית בראיות סיום משחררת את המשבצת שהסתיימה בלבד, עוצרת שיגור חדש ומשאירה עובד אחר שכבר רץ ללא שינוי.
- הקוד הוא מכונת מצבים בלבד, ללא ממשק `Popen` או Job Objects; **אין** לפרש את בדיקות Linux כראיית הפעלת ממירים תחת Windows.

## D. הערכת Windows מבוססת ראיות

`soak/docs/WINDOWS_NATIVE_PILOT_ADMISSION_EVIDENCE_v020_20261114.md` מתעד בדיקה קודמת מ־14.11.2026: זיכרון זמין `1,062,019,072` בתים מתוך `8,379,490,304`; שער שמרני של לפחות 2 GiB נחסם. דיסק פנוי היה `38,923,628,544` בתים. מבחן JS+Interlingue המקורי נכשל ב־V8 OOM גם עם Heap של 1.5 GiB ו־RSS של ~2.16 GiB ב־CI; אין לאשר העלאת זיכרון אוטומטית במחשב. ניסויי אימוץ תהליך דמה ב־Windows v014 הצליחו בלי להרוג תהליך, אך **לא** הוכחה התאוששות של ממיר אמיתי לאחר קריסה.

מנוע V+አማርኛ, HEAD שנבדק `e2e78dc28bd8b3e8bffc3c5a75ff8bf85a77b552`, מפעיל כרגע Native smoke של יום היסוד בממשק `calendar_date_spaghetti`; Workflow ה־Stage31 עבר, אך **לא** הוכח סיום 55 שלבים ולא התקבלה תוצאת השוואת 2 ימים של אותו `c,t` מול שלושת המנועים. לא לצרפו עדיין לספירת מנועים פעילים בפלטפורמת soak.

## E. מצב קבלה מדעי

- **3** ממירי מקור נצפו בפיילוט (Python REF-41, Kotlin PROD-KT-CY, TypeScript+मराठी); **2** ימי יעד קיבלו ראיות משלושתם; בסך הכול **14** ימי יעד ייחודיים מהשוואות מקור Python/Kotlin.
- **7** מקטעי מקור Python בני יומיים נקלטו ושוחזרו ב־CrashStore במבחני CI (1015–1021; מקטעים פנימיים של שנה 5000, מתוך 2,122 מקטעים).
- **0** שנות מקור מלאות, **0** שנות soak מאושרות מתוך 10,000, **0** הסמכות עצמאות אלגוריתמית או canonical oracle; אף הרצת Windows חדשה לא בוצעה בסבב זה.
- מדגם זמן TypeScript `~25.4` שניות ליום יעד מבוסס שתי קריאות מקור בלבד. אי אפשר להשליך ממנו משך הרצה אמין ל־10,000 שנים.

## F. המשך מדויק

להתחיל ממבחן ביצועים מקוריים רב־נקודתי ולבנות חישוב משאבים המבדיל בין מנועים ממיטיבי זיכרון לבין מנועים איטיים; להכין שער Windows אמיתי רק לאחר שמדידות RAM/Disk עוברות. להרחיב את רשימת הממירים לפי מקור מחייב וללא בלבול בין רשומות חופפות, להתקדם לשנת מקור אחת **רק אחרי** השלמת שערי הביצוע והשחזור. להעתיק את 8 ארכיוני המקור לאחסון אצל ספק בלתי תלוי במידת האפשר. אין לשנות `main` ואין לבצע soak רב־שנתי לפני מוכן.

**סמן המשך:** `PASTAFARI_SOAK | CHECKPOINT=v100 | V096=CI_ACCEPTED_7OF7 | V098=DRAFT_BACKUP_RESTORED_2OF2 | V099=FAIL_CLOSED_SCHEDULER_12OF12 | NATIVE_ENGINES_OBSERVED=3 | UNIQUE_DAYS=14 | PYTHON_ORIGINAL_CHUNKS=7 | 10000_YEAR_CREDIT=0 | NO_MAIN=true`.
