# נקודת שחזור v090 — שיגור וקליטה כלליים למקטעי מקור

**תאריך:** 17.11.2026 (CI ב־16.11.2026 UTC)
**מאגר:** Sargon17-Green/Pastafarian-Calendar
**ענף QA בלבד:** qa/soak-readiness-20261114
**main:** 56bc4173aae4975ded019ef5ab5a36249f1424df — אין לשנות או למזג.

## מצב מקור מאומת

שני הממירים המקוריים REF-41 Python+Türkçe ו־PROD-KT-CY Kotlin+Cymraeg הורצו בטור וללא שינוי מקורותיהם, עם c=-15055671, שנת 5000. שבעה מקטעים 1015–1021, שני ימי יעד בכל מקטע, התאימו בכל חמשת השדות: **14 ימי יעד מקוריים**. שמות טבעיים מאומתים בפלט Python בלבד; Kotlin מחזיר אינדקסים.

מקטע 1020 — [CI 43974768278](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43974768278) completed/success. תוצאות:
- t=-15055662: (5000,14,9,41,45), שמות Python: Kahkaha/Babil.
- t=-15055661: (5000,14,10,26,49), שמות Python: Kahkaha/Sevinç.
- ZIP מקור Artifact 14280447591; SHA-256 706a075b6192a8b11a8992c42d3ec5e2a076c135c06685b93e9b28758f992265, 4,904,488 בתים, 22 קבצים, CRC תקין. Manifest: soak/control/original_native_chunk1020_pin_v086.json.

מקטע 1021 — [CI 43976583803](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43976583803) completed/success. תוצאות:
- t=-15055660: (5000,14,11,1,42), שמות Python: Kahkaha/Kil.
- t=-15055659: (5000,14,12,42,45), שמות Python: Kahkaha/Dil.
- ZIP מקור Artifact 14281261657; SHA-256 b7f250a98aea07acb4a78bf074e75c5f72d950f00a1d32d7bc81c6eb8c464b32, 4,904,486 בתים, 22 קבצים, CRC תקין. Manifest: soak/control/original_native_chunk1021_pin_v088.json.

שני המקטעים החדשים הופעלו **באותו Workflow כללי**, לאחר הוספת קובץ בקשה אחד בלבד לכל ordinal. בשניהם עברו 17 בדיקות gate ל־Git diff ולרצף ה־manifests ו־9 בדיקות השער של המפקח. אומתו SHA-256 של מהדר Kotlin 1.9.0 ושל JAR המקור. אין שימוש בגרסה נגזרת או בקאש כתחליף לקריאות המקור.

## שיגור כללי v085

קבצים:
- soak/runner/source_ordinal_dispatch_v085.py
- soak/tests/test_source_ordinal_dispatch_v085.py
- .github/workflows/soak-original-request-gate-v085.yml
- .github/workflows/soak-original-ordinal-by-request-v085.yml

ה־Workflow מופעל ב־push לענף QA בהוספת בקשת מקור חדשה יחידה בנתיב soak/control/original_source_dispatch_requests/ordinal-N.json. gate דוחה replay, קפיצה מעל מקטע, שינוי נוסף באותו push, ערכי תאריך שגויים, JSON לא קנוני, מקור אחר או חריגה מטווח 1020–2121. כל המרות המקור נעשות בטור; לא ניתנת נקודת קבלה לשנה חלקית. CI סטטי [43974421243](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43974421243) עבר 17/17.

## קליטת ראיות ו־CrashStore

- [v087 CI 43976160526](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43976160526): completed/success, ארכיוני 1015–1020 עברו SHA, ביקורת מקור 1020 עברה, 12/12+8/8+7/7+6/6 = 33/33 בדיקות; שישה מקטעים נקלטו ושוחזרו.
- מנגנון כללי חדש v089: soak/runner/pinned_original_prefix_v089.py, soak/process_tests/test_dynamic_pinned_original_prefix_v089.py, .github/workflows/soak-generic-original-prefix-ledger-v089.yml.
- [v089 CI 43977454446](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43977454446): completed/success. שבעת הארכיונים 1015–1021 הורדו לפי Artifact IDs וגיבובי SHA-256 נעולים; כל חמשת הארכיונים הכלליים עברו ביקורת עצמאית מול עצי המקור המקוריים, וגם בקשות השיגור החדשות אומתו. 6/6 בדיקות CrashStore דינמיות עברו. אומתו שבעה מקטעי Python ושבעה קישורי תהליך, כולל שחזור offline; Kotlin כמועמד שנת מקור עדיין חסום.

v089 מוגבל במכוון לפיילוט מקור עד ordinal 1030 ולא מוכר כבסיס להרצת 2,122 מקטעים ללא בחינת משאבים נוספת. ל־GitHub Actions יש זמן ריצה מקסימלי לכל job, ואין בכך מימוש מלא של Windows scheduler לא קטלני.

## סטטוס מדעי מחייב

- 14 ימי יעד מקוריים תואמים, שבעה מקטעים 1015–1021; מדובר במקטעים פנימיים של שנת 5000, **לא** במקטעים הראשונים של השנה.
- 7 מקטעי Python מקוריים עברו שערי קליטה ושחזור ב־CrashStore; 0 מקטעי Kotlin כמועמד שנת מקור.
- **0 שנות Python מקוריות מלאות**, **0 שנות soak מתוך 10,000**; עצמאות אלגוריתמית ו־canonical oracle אינן מאושרות.
- מחשב Windows לא הופעל; main נשאר ללא שינוי.

## סיכון שימור ראיות והמשך

ארטיפקטים של GitHub Actions נשמרים לפי ה־Workflow למשך **30 ימים** בלבד. גיבוב SHA ב־QA אינו שומר את בתי ה־ZIP. לפני פקיעת ה־retention יש להעתיק את ראיות המקור לאחסון מתמשך ומאומת, בדגש על תיקיית Windows המאושרת, או אחסון מאושר חלופי. אין להסיק ששימור כזה כבר בוצע.

המשך העבודה: שימור ארכיונים בני־שחזור; מיפוי עצמאות הממירים (לא רק Python ו־Kotlin); יישום Windows דו־נתיבי לא קטלני עם מגבלות RAM/דיסק מאומתות; ובהמשך חישוב שנת מקור מלאה. המקטע הבא הוא ordinal 1022 עם t=-15055658,-15055657; לא הורץ ואין לתת לו קרדיט.

**סמן המשך:** PASTAFARI_ORIGINAL_NATIVE_YEAR_SOAK | CHECKPOINT=v090 | QA_ONLY=true | NATIVE_TARGET_DAYS=14 | ORIGINAL_CRASHSTORE_CHUNKS=7 | FULL_YEARS=0 | NEXT=DURABLE_ARCHIVE_AND_INDEPENDENT_ENGINE_GRAPH_WINDOWS_READINESS.
