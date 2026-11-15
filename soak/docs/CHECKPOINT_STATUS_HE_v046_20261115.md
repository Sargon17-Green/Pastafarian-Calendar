# נקודת שחזור v046 — פיקוח תהליכים ובדיקת תאריך מקורית ב־Python וב־Kotlin

**תאריך:** 15.11.2026 · **מאגר:** `Sargon17-Green/Pastafarian-Calendar` · **ענף עבודה:** `qa/soak-readiness-20261114`.  
**הנחיית יסוד:** אין לשנות `main`, אין לבצע התקנות או עומס במחשב Windows ללא שער משאבים, ואין למנות חישוב של יום אחד כ־PASS של שנת soak מלאה.

## התקדמות בפועל מאז v040

הושלמו שלושה שערים:

**v041 — פיקוח אמיתי על תהליך בדיקה סינתטי.** `soak/runner/supervised_process_observation_v041.py` מפעיל ילד GitHub Linux שהקוד שלו קבוע ומבודד. הוא אוסף PID+מזהה יצירה, SHA-256 של קוד הבדיקה והבינארי, הפקודה, code exit, stdout ו־stderr של מערכת ההפעלה, וקובצי raw/normalized נפרדים; הילד אינו מתחיל לפני קבלת `GO` תואם. הוא מוגבל בעדיפות ובמשאבים; בדיקת ילד תקוע רשאית להרוג רק את הילד **הסינתטי**, ולא ממיר איטי אמיתי. [CI 43763707096](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43763707096): **11/11 PASS**.

**v042 — הפעלה בפיקוח של שני מקורות נעולים במצב `--check-only`.** `soak/runner/supervised_original_source_preflight_v042.py` הפעיל את `REF-41` Python+Türkçe ואת `REF-24` JavaScript+Interlingue כתהליכים נפרדים. בוצעו אימותי Git commit, SHA-256 וקובצי תלויות, מקור שפה, פקודה, בינארי `python/node`, PID/creation ID, stdout/stderr ו־exit 0. **לא** הופעלה פונקציית `F(c,t)`. [CI 43764274836](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43764274836): **PASS**, שני תהליכי מקור, 0 המרות.

**v043 — פיילוט ראשון של מקור Python+Türkçe ומקור JavaScript+Interlingue לתאריך יחיד.** התהליך המקורי של Python חישב בהצלחה `F(c,t)` עבור `c=t=-15055671`, אבל JavaScript המקורי נכשל בגלל `V8 heap out of memory` בשתי מגבלות זיכרון שונות:
- [CI 43764673922](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43764673922): גבול heap ‏384MiB, **BLOCKED**;
- [CI 43764826583](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43764826583): גבול heap ‏1,024MiB, **BLOCKED**.

מבחינה מדעית אלה **אינם אי־התאמות**: JavaScript לא החזיר אף רשומת תאריך. אין להסיק שהוא מחשב תאריך שונה, אך אין להוסיף את מקור JavaScript למסלול הרצה שהוכח זמין בזיכרון המחשב המקומי. הוחלט שלא להגדיל עוד את הזיכרון בלי מדידה/תכנון נוספים.

## v045 — התאמת מקור מלאה לתאריך אחד, Python מול Kotlin

קובץ `soak/runner/supervised_original_python_kotlin_day_v045.py` מפעיל תחילה את המימוש המקורי `REF-41` Python+Türkçe (קומיט `0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4`), ואז את מימוש הייצור המקורי Kotlin+Cymraeg (קומיט `0c703446d8a3b7435698bd16402ac5fa30e461c9`). Kotlin קומפל באמצעות Kotlin 1.9.0 ממקורות הייצור הבלתי־משונים והגשר המקורי `soak/Post55ProductionDateBridge.kt`. אינו משתמש בהרחבת `wholeYearAt` הנגזרת.

החישובים מופעלים בטור, בעדיפות נמוכה, בשרת Linux של GitHub; לשני התהליכים **אין timeout יזום לזמן החישוב** בקוד ה־Supervisor. יש גבולות heap/כתובות ושער RAM/disk; עם זאת, בתשתית GitHub Actions קיים timeout עליון של המשרה ואין לקרוא לכך מנגנון המתנה בלתי־מוגבל. המחשב המקומי של המשתמש לא נגע בניסוי.

**תוצאת החישוב הגולמית:**

| שדה | Python מקורי | Kotlin מקורי |
| --- | ---: | ---: |
| יום מעשה `c` | −15,055,671 | −15,055,671 |
| יום יעד `t` | −15,055,671 | −15,055,671 |
| שנה | 5000 | 5000 |
| אינדקס קציצה | 10 | 10 |
| יום בקציצה | 503 | 503 |
| אינדקס חודש | 20 | 20 |
| יום בחודש | 56 | 56 |

חמשת שדות התאריך תואמים. שמות מקור Python בטורקית: `Akrep` לקציצה ו־`Kuyu` לחודש. Kotlin החזיר את הנתונים המקוריים **ל־stdout של מערכת ההפעלה** בפורמט TSV, בעוד מעטפת Python כתבה את רשומת המקור המקורית לקובץ `--raw-out`, ואת הודעות ההתקדמות שלה ל־stdout. שני סוגי הזרמים נשמרים בנפרד בראיות.

נבדקו מחדש גיבובי מקור, קוד היציאה (0 בכל תהליך), זהות תהליך ולוגים, קבצי raw/normalized ואימות `native_raw_pair_gate_v018` למקור Python. Kotlin נבדק בפורמט TSV קשיח של 7 שדות, שורה אחת, LF מסיים וקואורדינטות מדויקות. שני המקורות הביאו מספרים זהים, עם `first_mismatch_target_day=null`.

[הרצת CI המלאה 43765573521](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43765573521): **SUCCESS**, לרבות בדיקת הסיכום וראיות התהליכים. בהרצה הראשונה [43765443048](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43765443048) גם החישוב עצמו הצליח, אך ה־CI נכשל משום שבקרת הסיכום חיפשה `return_code` גם ברשומת Python, שבה השדה נקרא `exit_code`. זו תקלה בסקריפט הבקרה בלבד, שתוקנה ונבדקה בהרצה החוזרת.

**גיבובים ומיקום ראיות v045:**
- מקור Python raw JSONL: SHA-256 `bbad31d4bbc177c9c002423ccc3134dcb052c2eeff8e06290bb76b2c962c9173`.
- Python normalized JSONL: `834cc548105faeadb99e5e3fb384d72e957d55c607847800f7cf0f0c8dc627c4`.
- Kotlin מקורי stdout TSV: `476676d64c9d514dfebd598df53cee8bfacf489422bf12d24d6492bf6bb41c34`.
- JAR Kotlin שנבנה ממקורות מקוריים: `70f2567a67712511f7e86c8ed3147c26c373f33150f7d707f390c207c9c522d6`.
- GitHub Actions Artifact ID `14181487872`, שם `soak-v045-original-python-kotlin-native-one-day`. גיבוב ZIP שהורד ונבדק: `2bcf3c15cc98c977e500caa7432f15e9bce17557f6292d4aae3d6ed9d5704c4d`.
- קובץ תוצאת הבקרה: `soak/control/supervised_one_day_original_py_kotlin_v046.json`.
- בדיקת תעודת ההתקדמות והגבלת ספירה: `soak/tests/test_supervised_one_day_original_witness_v046.py`.

**מגבלות האימות:** שני המקורות הם מימושים נפרדים בקומיטים שונים, אך מקוריותם האלגוריתמית **לא הוסמכה**. התאמה של תאריך יחיד אינה הוכחה שקיים אורקל קאנוני עצמאי, ולא הוכחה שניתן לחשב את כל ימי השנה. שדה `original_native_full_year_soak_passes=0` נשמר בכוונה.

## מעמד התוצאות הקודמות, ללא שינוי

הראיות v025–v040 עדיין מראות **17,506** שורות תאריך נגזרות תואמות בארבעה צירופי `(c,year)`, ומדגם של **33 קריאות תאריך מקוריות לכל אחד משני המנועים Python/Kotlin** בהרצות קודמות. התאריך v045 עשוי לחפוף למדגם קודם, ולכן אין להוסיף אותו אוטומטית למניין התאריכים הייחודיים. ההישג החדש הוא **קבלה מפוקחת של שני תהליכים מקוריים באותה הרצה** עבור תאריך יחיד, ובנפרד מדידת חסם הזיכרון של JS המקורי.

## המשך העבודה

1. לבצע ביקורת רישום מקורות וחוזי החישוב לפני ספירה של כל שנה מלאה; במיוחד לבדוק אם מדובר בגרסאות שנגזרו מאותו קאנון/קוד.
2. לחבר את תשתית ה־Supervisor למסלול `v039` ול־`CrashStore` עבור **מקטעים מקוריים מלאים**. לשמור קובצי stdout/stderr ו־raw/normalized שונים, SHA לכל שורה וקבלה לא־ניתנת לדריסה; להבטיח `c,year,first,last` ו־engine identity קבועים. אין להפוך תמליל יום בודד לשנת soak מלאה.
3. לתכנן מחדש את `REF-24` JavaScript כנתיב עתיר זיכרון: להעדיף אבחון צריכת heap, גידול במבני ביניים ומטמונים על פני הגדלה בלתי־מוגבלת של memory cap.
4. להפעיל על מחשב Windows רק אחרי שער RAM/דיסק/CPU עדכני ונעילת משאבים אמיתית; אין להרוג חישוב איטי בגלל משך הזמן בלבד, אין לשנות תוכנות המשתמש ואין להשאיר שירותים או התקנות.

**חוזה סטטוס v046:** `new_supervised_original_python_kotlin_date_pair=1`; `five_fields_matched=5`; `JS_original_one_date_blocked_memory=true`; `certified_original_complete_years=0`; `ten_thousand_year_soak_started=false`; `windows_run=false`; `main_unchanged=true`.
