# נקודת שחזור v068 — ארבעה ימי מקור מפוקחים ושני מקטעי Python בתוכנית השנה

**תאריך:** 16.11.2026 · **מאגר:** `Sargon17-Green/Pastafarian-Calendar` · **ענף עבודה:** `qa/soak-readiness-20261114`.  
**כללים:** `main` ללא שינוי; אין הפעלת Windows; אין ספירת שנת soak מתוך מקטעים חלקיים; `queued/in_progress` אינו PASS ואינו חסימה; אין הרצת CI כפולה ידנית.

## 1. הושלמה הרצת שני ימי תאריך מקוריים נוספים

[GitHub Actions v061 — הרצה 43943379288](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43943379288) הסתיימה `completed/success`. המימושים המקוריים והבלתי־משונים של `REF-41` Python+Türkçe ושל `PROD-KT-CY` Kotlin+Cymraeg חושבו בנפרד, ובזו אחר זו, עם `c=-15055671`, `year=5000`, במקטע `ordinal=1016`:

| יום יעד | year | cutlet_index | day_in_cutlet | month_index | day_in_month | שמות מקור Python |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| -15055670 | 5000 | 14 | 1 | 29 | 38 | Kahkaha / Kurbağa |
| -15055669 | 5000 | 14 | 2 | 20 | 57 | Kahkaha / Kuyu |

ב־v061 התאימו **2/2 זוגות תאריך מקוריים חדשים**, חמישה שדות בכל תאריך. יחד עם v053, קיימות עדויות הרצה מפוקחת לארבעה ימי יעד עוקבים; אין בכך אישור של שנת 5000 בת 4,244 הימים. Kotlin המקורי מפיק אינדקסים, **לא** שמות מקור Cymraeg.

## 2. חבילת מקור v061 וגיבובים שנקבעו

- Artifact GitHub Actions: `14264392351`; ZIP בשם `soak-v061-next-two-original-native-days-not-year`.
- SHA-256 של ZIP: **`91985794e9bb8e3c6995aa5634d684872c60aae544eaf780b668797d86557eb9`**, גודל **4,902,107 בתים**, CRC עבר.
- Python raw SHA `81281ba24779c939caeac786e0e76ded0f5fa85c3c3de5cc4b9bf92c6c42bda3`; normalized SHA `a2d93851e442ea14a79b8c8deb057360d960519bdbc61cdabf6e192d8e0227fa`.
- Kotlin stdout מקורי SHA `ad6c68c1b50b1365edae356c48a1a76b2c58de9f30cf3e3da9b827bd6f304ecb`; JAR מקור מקומפל SHA `70f2567a67712511f7e86c8ed3147c26c373f33150f7d707f390c207c9c522d6`.
- מקור Python pin `0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4`, מקור Kotlin pin `0c703446d8a3b7435698bd16402ac5fa30e461c9`.
- קובץ בקרה מלא של כל 18 גיבובי הקבצים וארבעת רישומי שדות המקור: `soak/control/supervised_next_two_original_dates_v064.json`.

## 3. אימות עצמאי של חבילת המקור v065

נוסף `soak/runner/verify_next_original_chunk_v065.py` ושער `.github/workflows/soak-verify-next-original-chunk-v065.yml`.

[GitHub Actions v065 — הרצה 43947296644](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43947296644) הסתיימה **SUCCESS**. השער הוריד את אותו ZIP שנקבע ב־SHA-256, הצליב מחדש מקור Python ו־Kotlin, גיבובי JAR ובינארי, נתוני קבלת התהליך, שורות raw/normalized, שמות Python המקוריים ו־5/5 שדות התאריך בכל יום. בנוסף נדחו ארבע השחתות מכוונות **גם לאחר שהשתנו גיבובי ZIP והקבצים שבתוכו**: תאריך Kotlin מזויף, שינוי שם מקור Python, JAR מקורי משובש וזיוף אישור שנת soak. לא בוצעה קריאת `F(c,t)` חדשה בביקורת.

## 4. v066/v067 — שילוב מתוכנן ומבוקר ב־CrashStore

נוספו:
- `soak/runner/original_next_chunk_import_v066.py`;
- טבלת SQLite `original_next_chunk_witnesses` ב־`soak/runner/recovery_store.py`;
- הרחבת `original_process_chunk_links` ב־`soak/runner/original_ref41_year_chunk_import_v059.py` לתמיכה בקישורי מקור נפרדים עבור מקטעים 1015 ו־1016;
- `soak/process_tests/test_original_two_source_chunks_v067.py` (11 תרחישים מול שתי חבילות המקור האמיתיות);
- `.github/workflows/soak-two-real-original-year-chunks-v067.yml`.

הקליטה המאושרת מותנית בביקורת מקור v065, בתוכנית שנה v059 מדויקת ובקיום מקטע Python 1015 וקישור המקור שלו. רק אחרי כן ניתן לרשום את מקטע Python 1016, raw ו־normalized, קבלת מקור v038 וקישור SHA ל־ZIP v061. **שתי שורות Kotlin נשארות ב־quarantine; קליטתן כ־candidate נדחית עד להשלמת כל שנת Python.** המנגנון אינו מעדכן `comparisons`, אינו מאשר `fully_verified_years` ואינו מבצע חישובי מקור נוספים בזמן קליטה.

הרחבת השחזור שומרת על fail-closed כשקישור מקור חסר. כאשר מפעיל משדר **במפורש** את אותם בייטים של שתי חבילות המקור הנעולות, ניתן לשחזר את הקישור החסר ללא כפילות. בבדיקת שחזור רגילה אין היתר להשלמה אוטומטית.

### הוכחת CI של השלב הזה

[הרצת v067 הראשונה — 43948578813](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43948578813) נכשלה ב־**3 מתוך 11 בדיקות**, אך **8 בדיקות עברו**. שני כשלים נבעו מתנאי קישור שתבע בדיוק קישור אחד, ולא תמך בקליטת שני קישורים או בשחזור מפורש. כשל נוסף נבע מאי־התאמה בשם שדה בדוח. לוגי ההרצה אומתו ותוקנו ב־`v059`/ `v066` בלבד, תוך השארת שחזור רגיל מחמיר.

[הרצת v067 המתוקנת — 43948985375](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43948985375) נמצאה **`queued` בעת כתיבת נקודת שחזור זו**. אין להסיק PASS/FAIL עד ללוגים של `completed`; אין להפעיל עותק כפול. [רגרסיה v059 — 43948241333](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43948241333) הסתיימה ב־**SUCCESS, 15/15 בדיקות**, אחרי שינויי הסכמה הראשונים.

## 5. מדע, עלות ומגבלות

- **4 ימי יעד ייחודיים** נבדקו בשתי הרצות פיקוח מקוריות (v053+v061) עבור `c=-15055671`, בצמד Python/Kotlin, 5/5 שדות בכל יום.
- שנת 5000 בת 4,244 הימים **עדיין לא הושלמה**. תוכנית ה־ledger היא `chunk_days=2`, 2,122 מקטעים לכל מקור; כרגע v059 אישר בפועל קליטת מקטע 1015, ו־v067 נועד להוכיח הוספת מקטע 1016.
- **0** שנות soak מקוריות שהוסמכו; **0** מתוך 10,000 השנים שהורצו; עצמאות אלגוריתמית ואורקל קאנוני עצמאי עדיין **NOT_CERTIFIED**. 17,506 ההתאמות הקודמות היו **נגזרות**, ולא קריאות מקוריות.
- המקור JavaScript+Interlingue המקורי נותר חסום בשל V8 heap OOM תחת ניסיונות קודמים, **ללא** תוצאת יום; זהו RESOURCE_BLOCKED ולא MISMATCH.
- קוד Python המקורי בונה מחדש את `YearStructure` ב־`calendar_date_ids` לכל תאריך. שימוש חוזר במבנה מחושב מראש הוא מימוש נגזר גם אם פלטו שווה; לא לסווגו כמקורי.
- לא הופעל מחשב Windows, וענף `main` לא שונה.

**סמן המשך:** `PASTAFARI_ORIGINAL_NATIVE_YEAR_SOAK | CHECKPOINT=v068 | NEXT=VERIFY_v067_COMPLETED_CI_AND_TWO_REAL_SOURCE_CHUNKS | QA=qa/soak-readiness-20261114`.
