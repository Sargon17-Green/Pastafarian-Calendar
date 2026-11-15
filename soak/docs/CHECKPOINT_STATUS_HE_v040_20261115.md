# נקודת שחזור v040 — קבלות פלט Native, ledger אטומי וגשר יבוא פיילוט

**תאריך:** 15.11.2026 · **מאגר:** `Sargon17-Green/Pastafarian-Calendar` · **ענף העבודה היחיד:** `qa/soak-readiness-20261114`.  
אין למזג ל־`main`; אין להפעיל או להעמיס על מחשב Windows בלי preflight מעודכן ומנגנון Job Object אמיתי. אין להתחיל soak של 10,000 שנים ואין להכריז על אישור עצמאות לפני ביקורת המקורות.

## התוצאה החדשה בשיחה הנוכחית

בוצעו **שינויים ממשיים בקוד המאגר ובבדיקות**, לא רק ניתוח:

1. `soak/runner/native_execution_receipt_v038.py` — חוזה נתונים דטרמיניסטי קשיח `PASTAFARI_NATIVE_CHUNK_OBSERVATION/1`, שמקבע SHA-256 של raw/normalized, מקור, בינארי המוצהר, יום מעשה, שנה וגבולות כל מקטע. כל `source_raw_sha256` בשורת נתוני המרה חייב להתאים לבייטים של רשומת המקור המקבילה, כולל LF.
2. `soak/runner/recovery_store.py` — חוזה v2 דורש `raw_stdout` ו־`native_receipt` לכל `commit_chunk`. קובצי מקור וקבלה נכתבים ללא דריסה, עם `fsync` ושמות דטרמיניסטיים; טבלת `native_receipts` נרשמת **באותה טרנזקציית SQLite** עם `chunks` וההשוואה, ונבדקת שוב ב־`verify_and_recover`. קובץ קבלה חסר או פגום אינו נוצר מחדש בשידור חוזר. סתירה במקטע רשום עוצרת את ההרצה ומקבעת `CONFLICTING_REPLAY`.
3. `soak/runner/import_verified_pilot_chunk_v039.py` — גשר שלא מריץ ממירים, המקבל את שלישיית קובצי פלט הטרנספורט v017: `raw-out`, `normalized-out`, `receipt-out`. לפני ה־commit הוא דורש אימות `native_raw_pair_gate_v018.verify_stream` למקורות `REF-41` (Python+Türkçe) ו־`REF-24` (JavaScript+Interlingue), גיבובי המקורות הקבועים, שמות ומזהים, קואורדינטות מדויקות ו־SHA של מתאם הטרנספורט. בכך נסגר הפער בין שער הפיילוט המקורי למנגנון השחזור.
4. `soak/tests/test_native_execution_receipt_v038.py` ו־`soak/tests/test_import_verified_pilot_chunk_v039.py` — בדיקות שלמות ושחזור אחרי קריסה, שידור חוזר, החלפת פלט/מקור, שיבוש SHA, חוסר בקבלה ושינוי יום מעשה. בדיקות v039 של הגשר משתמשות ב־mock של אימות המקור, ולא מסמיכות הרצה אמיתית.

**תוצאות CI:** [הרצה 43761407525](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43761407525), לאחר השינוי האחרון בקוד ובבדיקות, **155/155 בדיקות Python PASS**; בדיקות JavaScript, source lock ושמות קאנוניים עברו. יש לבדוק CI על HEAD אם נוספו מאז קובצי תיעוד.

ההנמקה הטכנית המפורטת: [NATIVE_OUTPUT_RECEIPT_GATE_v040_HE.md](./NATIVE_OUTPUT_RECEIPT_GATE_v040_HE.md).

## ממה אסור להסיק אישור

**הגבול בין קובץ הפלט לתהליך:** עטיפות v017 כותבות את `raw-out` ואת `normalized-out` לקבצים; ה־stdout של התהליך מכיל הודעות מצב. שם הפרמטר `raw_stdout` ב־v038 מתייחס בפועל ל**זרם רשומות הפלט הגולמי שנמסר**, ולא ל־stdout של מערכת ההפעלה שנלכד בידי Supervisor. גיבוב זרם אינו מעיד שהבינארי הנטען אכן הופעל. `binary_sha256` בשער פיילוט v039 מתייחס לקובץ מתאם הטרנספורט, ולא בהכרח ל־`python.exe` או `node.exe` שביצעו אותו. זהו צעד של שלמות ראיות בלבד.

מקוריות של קוד, עצמאות אלגוריתמית, זהות תהליך, מעקב אחר הוצאות מערכת, הבדל בין פרשנות לבין מקור ואורקל קאנוני לא הוכחו. אין חתימה שמעניקה תעודה מישות בלתי־תלויה. כל ערכי `trusted_execution_attested`, `independent_algorithm_attested` ו־`official_soak_authorized` ננעלים ל־`false`.

גם `progress()` אינו מאמת מחדש את קובצי הראיות בכל קריאה: הוא מחזיר `native_receipt_rows_recorded_without_revalidation`. רק `verify_and_recover` עובר על הראיות הקיימות ומקשר מחדש את הגיבובים וקובצי המקור. מספר השוואות `verified_comparisons_completed` הוא **טכני**, ולא מניין שנת soak מקורית מוסמכת.

## תוצאות חישוב התאריכים הקודמות — ללא שינוי

[נקודת v037](./CHECKPOINT_STATUS_HE_v037_20261115.md) ו־[v035](./CHECKPOINT_STATUS_HE_v035_20261115.md) כוללות את ההוכחות המפורטות, הקומיטים, מזהי הרצות Actions, הגיבובים והנתיבים:

| יום מעשה `c` | שנת יעד | מספר ימים תואמים בין שני תמלילים נגזרים | קריאות מקוריות שנבדקו בכל מנוע |
|---|---:|---:|---:|
| −15,055,671 | 4999 | 4,126 | 6 |
| −15,055,671 | 5000 | 4,244 | 14 |
| −15,055,671 | 5001 | 5,567 | 6 |
| −15,055,672 | 5000 | 3,569 | 7 |
| **סה״כ** | | **17,506** | **33 Python + 33 Kotlin** |

נתוני הטבלה נובעים מהרצות v025–v034, לא מהבדיקות הסינתטיות v038–v039. אין לספור את הקוד שנגזר ממקור Python/Kotlin כממיר נוסף בלתי־תלוי. **אפס שנות soak מקוריות שלמות אומתו**. ההרצה ארוכת הטווח טרם החלה.

## הצעד הבא שמותר לבצע

1. **Supervisor אמיתי עם קבלת תהליך:** להקצות משאבים ולוודא בפועל אילו בייטים של קובץ המקור, קובץ הבינארי/ה־JAR והמתאם שימשו לכל הרצת `F(c,t)`; לשמור קובץ פקודה, סביבת הרצה רלוונטית, PID, זמן, exit code, stdout/stderr של מערכת ההפעלה בנפרד מ־raw-out/normalized-out, וגיבוב קבצים. להגיש עדות רק אחרי הצלחת `native_raw_pair_gate_v018` והיעדר פגיעה במקורות. אין לשנות תיעוד קיים או להנפיק תעודה עצמית.
2. **חיבור מבוקר של Supervisor ל־ledger:** התהליך החי חייב לייצר את הראיות במסלול write-once שאינו נשלט על ידי מתאם ההמרה לבדו, ואז להעביר אותן ל־v039. נדרשת בדיקת הזרקת קריסה בין הפעלת הממיר לבין הכנסת הקבלה ל־SQLite.
3. **ביקורת עצמאות מקור:** השוואת היסטוריית הקומיטים ומפת התלויות Python/Kotlin/JavaScript לפני אישור מנועים בלתי־תלויים; מקור עברי מחייב בדיקת קאנון נפרדת.
4. **משאבי Windows:** preflight חדש של RAM, דיסק, מעבד, כללי Job Object ותקרת שני workers, עם תור איטיים שאינו מבטל משימה מתמשכת רק מפני שהתארכה. אין watchdog, שינוי קבוע במחשב, סגירת תוכנות או הרצת 10,000 שנים בלי שער מלא.

## קובצי עבודה מרכזיים

`soak/runner/native_execution_receipt_v038.py`, `soak/runner/import_verified_pilot_chunk_v039.py`, `soak/runner/recovery_store.py`, `soak/runner/native_raw_pair_gate_v018.py`, `soak/runner/source_identity_gate_v036.py`, `soak/runner/two_lane_scheduler.py`, ושתי חבילות הבדיקות v038/v039.

**הסטטוס המחייב:** `derived_date_rows_matched=17506`; `unchanged_original_sampled_date_matches_per_engine=33`; `original_native_full_year_soak_certified=0`; `supervised_native_process_attested=false`; `long_soak_started=false`; `windows_run=false`; `main_unchanged=true`. יש להמשיך מתוך המאגר ולא מתוך השיחה.
