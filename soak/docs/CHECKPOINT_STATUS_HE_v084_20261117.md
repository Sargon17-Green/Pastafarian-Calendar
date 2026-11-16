# נקודת שחזור v084 — חמשת מקטעי המקור 1015–1019 נקלטו ושוחזרו

**תאריך:** 17 בנובמבר 2026, שעון ישראל (ראיות CI מ־16.11.2026 UTC).  
**מאגר:** `Sargon17-Green/Pastafarian-Calendar`  
**ענף QA בלבד:** `qa/soak-readiness-20261114`  
**קומיט ייחוס לאחר v083:** `ba704d38a3f208287820bbc8bae838e25754dbc1`  
**main** (נבדק): `56bc4173aae4975ded019ef5ab5a36249f1424df`, ללא שינוי.

## 1. מקור F(c,t) נעול — 10 ימי יעד תואמים

**יום החישוב הקבוע לכל המקטעים:** `c=-15055671`; שנת מקור 5000, `first=-15057702`, `last=-15053459`, `4244` ימים ו־`2122` מקטעים דו-יומיים.

מקטעי מקור מחושבים עצמאית בכל אחד משני מסלולי המקור הקיימים, Python REF-41 בקומיט `0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4` ו־Kotlin PROD-KT-CY בקומיט `0c703446d8a3b7435698bd16402ac5fa30e461c9`. אין שינוי באלגוריתם המקורי; תוצאות Kotlin הן אינדקסים בלבד ואינן מאמתות שמות טבעיים.

| מקטע | טווח t | תוצאת מקור | קליטת CrashStore |
|---|---|---|---|
| 1015 | לפי v053 | 2/2 התאמות | PASS v083 |
| 1016 | לפי v061 | 2/2 התאמות | PASS v083 |
| 1017 | `-15055668..-15055667` | 2/2 התאמות | PASS v083 |
| 1018 | `-15055666..-15055665` | 2/2 התאמות | PASS v083 |
| 1019 | `-15055664..-15055663` | 2/2 התאמות | PASS v083 |

מקטע 1018 — [native CI 43968565331](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43968565331) `completed/success`, 9/9 בדיקות שער. ארכיון `14277208379`, גודל 4,902,934 בתים, SHA-256 `329afd1e408c43dfadf96b4ddd844696b59f22a63b786e663413950013c3fb0c`. קובץ pin `soak/control/original_native_chunk1018_pin_v079.json` (19/19 קבצים, CRC עבר).
- `t=-15055666`: `(5000,14,5,28,61)`, `Kahkaha/Ninova`.
- `t=-15055665`: `(5000,14,6,25,36)`, `Kahkaha/Kireçtaşı`.

מקטע 1019 — [native CI 43971203517](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43971203517) `completed/success`, 9/9 בדיקות שער. ארכיון `14277754738`, גודל 4,902,942 בתים, SHA-256 `75d930af3c8d0c5bfd80d85f2f6377dda6d9d25c3d4a8791335b219248bfecaf`. קובץ pin `soak/control/original_native_chunk1019_pin_v082.json` (19/19 קבצים, CRC עבר).
- `t=-15055664`: `(5000,14,7,22,37)`, `Kahkaha/Yıldız`.
- `t=-15055663`: `(5000,14,8,43,53)`, `Kahkaha/Keten`.

**אימות מקור בשערי הקליטה:** ה־ZIP המקורי תואם לגיבוב נעול, כל הקבצים נבדקו, מסמכי הפיקוח ושרשרת המקור נקראו, ומבחן חמשת שדות התאריך הושווה מחדש. אין חתימת צד שלישי על זהות תהליך OS, אישור oracle או אישור עצמאות אלגוריתמית.

## 2. CrashStore — קבלת חמשת המקטעים

- [CI v080 מתוקן — 43971507337](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43971507337) `completed/success`: **12/12** בדיקות v074 ו־**8/8** בדיקות v080; מקור 1018 נבדק ב־v079 ועבר.
- [CI v083 — 43972069193](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43972069193) `completed/success`: **12/12**, **8/8**, **7/7** בדיקות (בסך הכול 27); ביקורת מקור 1018 ו־1019 עברה; כל חמשת הארכיונים אומתו.
- בשער v083, `committed_chunks=5`, `original_process_linked_chunks_not_years=5`, `original_generic_source_witnesses_not_years=3` (ל־1017–1019; שני המקטעים הקודמים בטבלאותיהם), `verified_existing_chunks=5`, `recovered_chunks=0`, וה־`fully_verified_years=0` נבדקו בפועל.
- קישורי מקור חסרים, זיוף SHA או חוסר באחד משלבי התיקוף אינם מעידים על PASS. קליטת Kotlin כמועמד שנה עדיין אסורה עד השלמת כל מקטעי שנת Python המקורית.

## 3. תיקון פגם שחזור שהתגלה בבדיקות v080

ה־Workflow הראשון v080 `43970810713` נכשל בשל שדה שגוי בבדיקת ה־CI (חיפש `matched_original_day_pairs` במקום `original_source_pairs`); כל 12 הבדיקות הקודמות עברו. אחרי תיקון השדה, v080 `43971023931` חשף פגם ממשי: שחזור מפורש של קישור המקטע הנוכחי נכשל בביקורת הגלובלית שהופעלה בעת בדיקת המקטע הקודם.

התיקון ב־`soak/runner/original_generic_source_chunk_ledger_v073.py` מאפשר `check_generic_witnesses(store,explicit_replay_ordinal=ordinal)` לפני אימות קישור המקטע הקודם, ומעביר `generic_witnesses_prevalidated=True` רק לאחר סריקה כוללת. הוא מתיר השמטה זמנית רק של קישור **המקטע הנוכחי** בעת קליטה מפורשת שכבר אומתה מול מקור נעול; לא של קישור המקטע הקודם. נוספו בדיקות של כשל קישור קודם ו־ZIP קודם שהושחת. הרצת [v080 הסופית 43971507337](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43971507337) וסבב v083 עברו.

## 4. מצב הקבלה והמשך מדויק

- **10** ימי תאריך מקוריים תואמים, בשני מנועי מקור נפרדים; **5** מקטעים דו־יומיים אושרו בקליטת CrashStore.
- **0** שנות מקור Python מלאות, **0** השוואות שנות מקור מלאות, **0** שנות soak מאושרות מתוך 10,000.
- **0** מקטעי Kotlin כמועמד שנות soak נקלטו; מקוריות/עצמאות האלגוריתמים ומבחן oracle לא הוסמכו.
- **לא הופעל Windows**, לא בוצע soak רב־שנתי, ו־`main` לא שונה. כל עבודה נמצאת בענף QA.
- למסלול מקור שנת 5000 נותרו `2122-5=2117` מקטעים דו־יומיים; אין להשתמש ב־10 ימי המדגם כאילו כוסתה השנה.

**NEXT:** להרחיב את המנגנון לשיגור מבוקר וליצירת manifest לפי ordinal ללא שכפול Workflow לכל מקטע, ולבדוק מוכנות המנועים האחרים וה־Windows scheduler. המקטע הבא לפי החוזה הוא `1020`, `t=-15055662,-15055661`, אבל אין לו כרגע תוצאות מקוריות מוקפאות ואין לספור אותו.

**סמן המשך:** `PASTAFARI_ORIGINAL_NATIVE_YEAR_SOAK | CHECKPOINT=v084 | ORIGINAL_CHUNKS_ACCEPTED=5 | SUPERVISED_NATIVE_DAYS=10 | NEXT=CONTROLLED_AUTOMATION_OF_NEW_SOURCE_ORDINALS_AND_INDEPENDENT_ENGINE_READINESS | NO_MAIN=true`.
