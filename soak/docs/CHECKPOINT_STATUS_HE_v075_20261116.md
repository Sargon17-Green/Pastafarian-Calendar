# נקודת שחזור v075 — מנגנון מקטעי מקור כללי, 6 התאמות מקוריות, וראיות מקטע 1017

**תאריך:** 16 בנובמבר 2026. **מאגר:** `Sargon17-Green/Pastafarian-Calendar`. **ענף QA בלבד:** `qa/soak-readiness-20261114`.  
**חוזי עבודה:** אין שינוי ב־`main`; אין עבודה במחשב Windows; אין להשתמש במימוש נגזר כתחליף לקריאות `F(c,t)` המקוריות; אין לתאר מצב `queued/in_progress` כ־PASS או כחסימה; אין לספור שנת soak מלאה אלא רק תאריך מקור מאומת או שנת מקור שהושלמה עם מקוריות/עצמאות שאושרה בנפרד.

## 1. הצלחה מתמטית חדשה — מקטע 1017

נוסף `soak/runner/supervised_original_ordinal_v070.py`: מסלול CI שיכול להפעיל בזה אחר זה את מנועי `F(c,t)` המקוריים והבלתי־משונים של `REF-41` Python+Türkçe ו־`PROD-KT-CY` Kotlin+Cymraeg עבור כל מקטע מקור חדש באורך שני ימים בשנת 5000, בטווח ordinal ‏**1017–2121**. גבולות כל מקטע מחושבים מ־`first=-15057702 + 2·ordinal`, `last=first+1`, עבור `c=-15055671`. מקטעים 1015 ו־1016 שכבר נבדקו נשללים כדי שלא תופעל הרצה כפולה. מעטפת הפיקוח שומרת SHA למקור ול־JAR, PID, מזהה יצירת תהליך, stdout/stderr, raw ו־normalized, קבלות מקור ו־`first_mismatch`, ללא timeout יזום של תאריך מקורי. תהליך ה־CI מוגבל לתנאי RAM/דיסק, עדיפות CPU נמוכה ותקרת זיכרון וירטואלי; **אין ראיה ל־hard RSS cap**.

[CI v070 — הרצה 43958870392](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43958870392) הסתיימה **completed/success**, כולל 9/9 בדיקות שער. עבור `ordinal=1017` נבדקו שני ימים חדשים:
- `t=-15055668`: חמשת שדות המקור `(5000,14,3,37,52)`, שמות Python: `Kahkaha / Fırtına`.
- `t=-15055667`: חמשת שדות המקור `(5000,14,4,18,59)`, שמות Python: `Kahkaha / Deve`.

**שני הממירים המקוריים התאימו בכל חמשת השדות לשני הימים.** שמות Kotlin אינם ניתנים לאימות מתוך פלט Kotlin המקורי: הוא מחזיר אינדקסים בלבד. יחד עם מקטעים מקוריים 1015 ו־1016, **6/6 ימי יעד ייחודיים** נבדקו תחת פיקוח, כולם עבור אותו יום מעשה `c=-15055671`, ללא mismatch.

## 2. קיבוע ראיות v071 ואימות עצמאי v072

חבילת GitHub Actions המקורית ממקטע 1017:
- Artifact ID `14273257274`, שם `soak-v070-original-ordinal1017-native-days-not-year`.
- גודל ZIP: **4,902,927 בתים**.
- SHA-256: `878b965960662aa27e824fd8f23a02c5d603b57f81ab698cb12ab02465a2e3e4`.
- CRC עבר, 19 קבצים ו־19 גיבובי SHA-256 נעולים ב־`soak/control/original_native_chunk1017_pin_v071.json`.
- Python raw SHA: `f77c6c3a1d180d30cd8f83f22c3984f01f57c4572af6c8796efe84cda8898501`; normalized SHA: `4ac5215f3c363dd4e66f01bce913f793ed9ea310e337b1566adce67990e2e8fc`.
- Kotlin OS stdout SHA: `bad801f34e0b16cb77dc998114ccc4a3453ca8e5dcffa54ded628bd61a0f0063`.
- תהליכי המקור הנעולים נשארו `REF-41` קומיט `0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4`, `PROD-KT-CY` קומיט `0c703446d8a3b7435698bd16402ac5fa30e461c9`.

נוסף שער ראיות כללי `soak/runner/original_chunk_artifact_gate_v072.py` עם בדיקות `soak/tests/test_original_chunk_artifact_gate_v072.py`. השער מקבל manifest נעול, בודק התאמת ordinal לגבולות השנה, מאמת קובצי מקור מקומיטים נעולים, גיבובי Kotlin JAR, קבלות תהליך ו־OS, שמות Python המקוריים, ו־5 שדות לכל תאריך מול Python raw ו־Kotlin stdout. הוא **אינו מפעיל את הממירים** ואינו מסמיך עצמאות אלגוריתמית.

[CI v072 — הרצה 43960371184](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43960371184) הסתיימה **SUCCESS**: שמונה בדיקות שער עברו; ביקורת המקור של ZIP ‏1017 עברה; **ארבע השחתות מכוונות** של ארכיונים שבהן חושבו מחדש גיבובי ZIP וקבצים נדחו (שינוי Kotlin מקור, שם Python מקור, קיטוע JAR, זיוף שנת soak מלאה).

## 3. v073/v074 — מימוש קליטה חוזר למקטעים 1017–2121

נוסף `soak/runner/original_generic_source_chunk_ledger_v073.py` ואומצו השינויים הבאים ב־`soak/runner/recovery_store.py` וב־`soak/runner/original_ref41_year_chunk_import_v059.py`:
- טבלת SQLite חדשה `original_generic_source_chunk_witnesses`, עם `ordinal`, גיבוב ZIP, גיבוב תוכנית השנה, גיבוב manifest, גיבוב דוח replay ומספר בייטים.
- לכל ordinal נדרש **קובץ manifest נעול יחיד** ב־`soak/control/original_native_chunk<ordinal>_pin_v*.json`. תוספת מקטע חדש תדרוש manifest משלו, אך **לא עותק נוסף של מנגנון ה־ledger**. בעת קליטה חדשה מתבצעת ביקורת v072 מול שני קובצי המקור המקוריים; בשחזור ללא מקורות מאומתת זהות הבייטים והערכים שנקלטו קודם.
- קבלת המקור נשמרת בטבלת `original_process_chunk_links` הקיימת. `verify_and_recover` בודק את הארכיון ואת קישורו לפני שחזור מקטעי שנה. אם המקטע קיים אך הקישור שלו חסר, השחזור הרגיל נכשל; רק **קליטה מפורשת מחדש מאותו מקור נעול** רשאית לשחזר קישור חסר ללא יצירת מקטע נוסף.
- דרישת סדר המקורות: מקטע Python הבא חייב לבוא אחרי המקטע הקודם, עם קבלת מקור תקינה. קליטת מקטע Kotlin כמועמד נותרת אסורה עד להשלמת כל **2,122** מקטעי שנת Python.
- אין שינוי בתנאי הקבלה: `official_original_full_year_soak=0`, `algorithmic_lineage_certified=false`, `canonical_oracle_certified=false`. ראיות התהליך אינן חתימת צד שלישי.

נוספו 12 בדיקות אינטגרציה ב־`soak/process_tests/test_three_real_original_chunks_v074.py`. הן בודקות בפועל את שלושת קובצי ה־ZIP המקוריים (v053, v061, v070), את תכנית שנת 5000 (4,244 ימים), קליטת 3 מקטעי Python מקוריים, 3 קישורי תהליך, שחזור offline, שידור חוזר ללא כפילות, השחתה, מחיקת ראיות, קובץ `.part` יתום וחסימת Kotlin.

**מצב CI במועד כתיבת הנקודה:** ניסיון ה־Workflow הראשון [43961452965](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43961452965) לא הגיע לבדיקות בגלל כותרת YAML לא מצוטטת. הקובץ תוקן. [ההרצה המתוקנת v074 — 43961579686](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43961579686) נמצאת **queued**, ולכן **אין עדיין אישור ל־12/12**. אין להפעיל ריצה כפולה. יש לקרוא רק את הלוגים של completed, לתקן כשל אמיתי אם יתגלה, ולעדכן checkpoint.

[רגרסיה v067 — 43948985375](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43948985375) נותרה ההוכחה האחרונה שב־CrashStore נבדקו בהצלחה **2 מקטעי Python מקוריים**, 11/11 בדיקות, לפני הרחבת v073. מסקנות v074 יהיו תקפות רק אחרי CI מושלם.

## 4. סטטוס מדעי מחייב

- **6** זוגות ימים מקוריים ומפוקחים תואמים ב־5/5 שדות לכל יום; שני הממירים המקוריים הופעלו בטור, ולא נגזרת.
- **2 מקטעי Python** נבדקו בהצלחה ב־ledger ב־v067; המקטע השלישי מחכה לאישור CI v074 של קליטה ושחזור.
- **0 מקטעי Kotlin מועמדים** שהתקבלו כנתוני השוואת שנת מקור; למרות קיומו של stdout מקורי.
- **0** שנות soak מקוריות מלאות שהוסמכו; **0** שנות soak מתוך 10,000 שהורצו. 17,506 התאמות קודמות היו **נגזרות**, ואין לספור אותן כמקוריות.
- מקור JavaScript+Interlingue נותר `RESOURCE_BLOCKED` בשל OOM קודם ללא תוצאת תאריך. **לא MISMATCH**.
- עצמאות מקורות ו־canonical oracle אינן מאושרות. המימוש המקורי של Python בונה מחדש YearStructure בכל F(c,t), ולכן הארכת הרצה מחייבת תכנון עומס מפורש; מסלול משופר עם קאש הוא **נגזר**, לא קריאות מקוריות.
- מחשב Windows לא הופעל. `main` נשאר בקומיט `56bc4173aae4975ded019ef5ab5a36249f1424df`.

**סמן המשך:** `PASTAFARI_ORIGINAL_NATIVE_YEAR_SOAK | CHECKPOINT=v075 | NEXT=VERIFY_COMPLETED_CI_V074_THREE_SOURCE_ZIPS_AND_RESUME_GENERIC_LEDGER | QA=qa/soak-readiness-20261114`.
