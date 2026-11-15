# שרשרת פיקוח על תהליך הפעלה — v041–v043 (מועמדת פיילוט)

**15.11.2026 · מאגר:** `Sargon17-Green/Pastafarian-Calendar` · **ענף QA בלבד:** `qa/soak-readiness-20261114`. אין שינוי ב־`main` ואין הרצה במחשב Windows.

## שלב 1 — תהליך סינתטי אמיתי עם פיקוח, v041

הקוד `soak/runner/supervised_process_observation_v041.py` מפעיל תהליך ילד אמיתי ומבודד ב־Linux GitHub Actions, אבל **רק** קוד בדיקה סינתטי, ללא כל קריאה לממיר. ה־Supervisor קושר את ה־PID למזהה יצירת התהליך ב־`/proc/PID/stat`, קובע עדיפות `nice=19`, מגבלת מרחב כתובות 128MiB ומגבלת זמן מעבד **לתהליך הבדיקה בלבד**, וקורא את קוד היציאה.

נשמרים קבצים נפרדים של `os-stdout.log`, `os-stderr.log`, `raw-data.jsonl`, `normalized-data.jsonl`, וכן `process-evidence.json`. ננעלים גיבוב קובץ ההפעלה של Python, קובץ הסקריפט, פקודת ההפעלה, מזהה התהליך, בייטי הפלט וקוד היציאה. כל הראיות נכתבות `write-once` ונקראות שוב ב־`verify_synthetic_evidence`. הילד מחכה לאישור `GO` עמיד לפני תחילת הבדיקה, והאישור מקובע למזהה תהליך ולגיבוב הפקודה.

[הרצת GitHub Actions 43763707096](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43763707096) הסתיימה **SUCCESS**: 11/11 בדיקות פיקוח, לרבות השחתת נתונים, שינוי `stdout`, תעודה מזויפת, יציאה לא־אפס, מניעת דריסה, תהליך סינתטי תקוע וסירוב להפעלה מחוץ ל־GitHub Linux. המקרה הסינתטי התקוע מבוטל **רק משום שמדובר בתהליך בדיקה**; אין להחיל את מנגנון הביטול על חישוב תאריך אמיתי שהוגדר איטי.

## שלב 2 — טעינת שני מקורות מקוריים בפיקוח, ללא המרה, v042

הקוד `soak/runner/supervised_original_source_preflight_v042.py` הפעיל בפועל, בזה אחר זה, את מעטפות המקור הנעולות:
- `REF-41`, Python+Türkçe, קומיט `0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4`, מקור `tests/normative_reference.py`.
- `REF-24`, JavaScript+Interlingue, קומיט `03ac0c7f4db3c35487993dd31982faa37dd3948e`, מקורות `tests/normative-reference.js` ו־`src/source-language-catalog.js`.

שתי העטיפות פעלו עם `--check-only`. הן בדקו מקור נעול לפי SHA-256 ו־Git blob, ייבאו/טענו את המקור ואת מפת שמות הקציצות והחודשים, והחזירו `converter_calls=0`. ה־Supervisor שמר את פקודת ההפעלה המדויקת, PID ומזהה יצירה, SHA-256 של קובץ המתאם ושל קובץ ההפעלה `python3`/`node`, פלט stdout/stderr וקוד יציאה.

[הרצת GitHub Actions 43764274836](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43764274836) הסתיימה **SUCCESS** לשני התהליכים, עם קודי יציאה 0 ועם `native_converter_Fct_calls=0`.

**הערה הנדסית שנלמדה בניסוי:** ניסיון קודם להגביל את Node ל־640MiB במרחב כתובות וירטואלי הכשיל את V8 בעת הקצאת `CodeRange`, עוד לפני חישוב תאריך. השער המתוקן נותן ל־Node עד 8GiB **כתובות וירטואליות** (שאינן שקולות ל־RSS), אך מגביל בנפרד את JS heap ל־128MiB, בודק לפחות 1GiB זיכרון פיזי פנוי ודורש Linux GitHub CI. זה **אינו** מוכיח מגבלת RSS אכיפה ואינו מתיר חישוב ב־Windows.

## שלב 3 — יום תאריך מקורי אחד מכל מקור, v043

קובץ `soak/runner/supervised_original_one_day_v043.py` מפעיל ניסוי ממוקד בלבד: `c=t=-15055671`, בתוך גבולות שנת 5000 שנבדקו במקורות Python/Kotlin. במחשב Linux של GitHub בלבד, מקור `REF-41` מבצע `calendar_date_ids(c,t)`, ומקור `REF-24` מבצע `calendarDate(BigInt(c),BigInt(t))`. כל מקור מבצע **קריאה מקורית אחת**; התהליכים מופעלים **בטור** וב־`nice=19`, ו־Supervisor אינו קובע timeout של זמן קיר או CPU לחישוב המקורי. בשרת GitHub עצמו קיימת מגבלת משך ריצה מערכתית שאינה בשליטת ה־Supervisor.

כל מנוע כותב `native-raw.jsonl`, `native-normalized.jsonl` וקבלת טרנספורט, ובנפרד stdout/stderr של מערכת ההפעלה. תוצאת המקור עוברת אימות עצמאי ב־`native_raw_pair_gate_v018.verify_stream`, לרבות שם ומזהה קציצה/חודש מקורי, SHA לשורת raw ותיאום של קואורדינטות `(c,t)`. רק אז אפשר להשוות חמישה שדות תאריך מנורמלים; תוצאה שונה גורמת לעצירה ללא אישור.

[ניסיון ראשון 43764673922](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43764673922) הסתיים **BLOCKED**, לא MISMATCH: Python המקורי חישב תאריך אחד בהצלחה; Node/V8 נכשל ב־`JavaScript heap out of memory` תחת מגבלת 384MiB. בדיקת תוצאת Python המקורית:
`(year,cutlet_index,day_in_cutlet,month_index,day_in_month)=(5000,10,503,20,56)`; שמות מקור Türkçe: `Akrep`, `Kuyu`. SHA-256 ל־raw המקורי `bbad31d4bbc177c9c002423ccc3134dcb052c2eeff8e06290bb76b2c962c9173`. **ל־JavaScript לא היתה תוצאת תאריך בניסיון הזה, ולכן לא היתה השוואה.**

גם [הניסיון השני של v043 — CI 43764826583](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43764826583), שאפשר ל־Node עד 1GiB heap בשרת GitHub בלבד עם לפחות 5GiB RAM פנויים, נכשל ב־V8 heap out of memory לאחר התחלת חישוב התאריך. זו חסימת משאבים, **לא** אי־התאמה של שני תאריכים; פלט JS לא הושלם. מכאן הועבר הפיילוט המפוקח ל־Python מקורי מול Kotlin מקורי. [ההרצה v045 הסופית 43765573521](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43765573521) הסתיימה ב־SUCCESS עם התאמה מדויקת של 5/5 שדות לתאריך יחיד — פרטים וגיבובים ב־[נקודת שחזור v046](./CHECKPOINT_STATUS_HE_v046_20261115.md). אין כאן שנת soak מאושרת.

## תחומי אמון

- גם ב־v041/v042, גיבובי קבצים וקוד יציאה שנלכדו על ידי Supervisor אינם חתימה קריפטוגרפית של צד בלתי־תלוי ואינם הסמכת עצמאות אלגוריתמית.
- `stdout` של מערכת ההפעלה הוא **לוג התקדמות**, בעוד `raw-out` הוא קובץ נתוני תאריך גולמיים שנוצר על ידי המתאם. אסור לערבב בין שני המקורות האלה.
- אף מקור חדש לא הוסמך כאלגוריתם בלתי־תלוי; שני המקורות הם נתיבי Reference/Test, ופרשנות נכונותם מול הקאנון דורשת אורקל וביקורת נפרדים.
- שנת soak מאושרת מחייבת **את כל ימי השנה בשני הממירים המקוריים**, עם אימות raw, גיבובים, גבולות, אישור מקוריות, עצירה בהפרש הראשון ו־ledger עמיד לקריסה. בדיקת יום אחד אינה שנת soak.

## מצב ההתקדמות

הראיות הקודמות ([v040](./CHECKPOINT_STATUS_HE_v040_20261115.md)) לא השתנו: 17,506 שורות **נגזרות** תואמות בארבעה צירופי `(c,year)`, ו־33 תאריכים מקוריים מדגמיים לכל אחד משני המקורות Python/Kotlin מהניסויים הקודמים. התוצאה החדשה מוסיפה **תאריך מקורי יחיד של Python+Türkçe שנבדק בפני עצמו**, אך עדיין אינה מוסיפה השוואת תאריכים מקוריים בין Python ל־JavaScript עד שיתקבל פלט JavaScript.

**שנות soak מקוריות מאושרות: 0.** הרצת 10,000 שנים: לא החלה. Windows: לא הופעל. `main`: לא שונה.
