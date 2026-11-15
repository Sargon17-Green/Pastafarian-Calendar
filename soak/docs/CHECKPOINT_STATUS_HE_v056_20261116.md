# נקודת שחזור v056 — שתי המרות Native מקוריות מפוקחות והקפאת ראיות

**תאריך:** 16.11.2026 · **מאגר:** \`Sargon17-Green/Pastafarian-Calendar\` · **ענף QA בלבד:** \`qa/soak-readiness-20261114\`.  
**כללי עבודה:** אין לשנות \`main\`, אין למזג, אין להריץ מחשב Windows לפני preflight RAM/דיסק/Job Object, אין לשלוח הרצת CI כפולה כאשר כבר קיימת ריצה queued או in_progress, ואין לקבוע PASS לפי מצב ביניים.

## 1. תוצאות CI שהושלמו מאז v052

- [v052, GitHub Actions 43771541419](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43771541419): **184/184 Python unit tests PASS**, כולל 19 בדיקות שער v050 וחמש בדיקות שילוב v051; בדיקות JavaScript ו־source lock עברו.
- [v047/v048, GitHub Actions 43770031162](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43770031162): **12/12 בדיקות ledger מול חבילת הראיות המקורית PASS**, ושמונה ZIP mutations נדחו.
- מקור הייחוס של שתי תוכניות Native לא שונה.

## 2. מה בוצע כעת — פיילוט של שני ימים מקוריים

נוסף \`soak/runner/supervised_original_two_days_v053.py\` עם Workflow ייעודי \`.github/workflows/soak-supervised-original-two-days-v053.yml\` ושש בדיקות admission/scope ב־\`soak/tests/test_supervised_original_two_days_v053.py\`.

[הרצת v053 הסופית 43774977104](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43774977104) הסתיימה **SUCCESS**:

- שני תהליכים שונים, בזה אחר זה, על Linux GitHub Actions; כל מקור חישב **שתי** קריאות \`F(c,t)\` מקוריות. אין timeout של זמן קיר בתוך ה־Supervisor למשימות התאריך.
- Python+Türkçe, מנוע \`REF-41\`, קומיט מקור \`0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4\`, קובץ מקור \`tests/normative_reference.py\`, מקור SHA-256 \`75d56765b45892940326f67bd85a2c7c9874c01e43b49ee3553c9f6192d94378\`.
- Kotlin+Cymraeg, מנוע \`PROD-KT-CY\`, קומיט מקור \`0c703446d8a3b7435698bd16402ac5fa30e461c9\`, קוד ייצור \`src/main/kotlin/pastafari/*.kt\` וגשר \`soak/Post55ProductionDateBridge.kt\`; קוד המקור המקורי נשמר ב־commit נעול ונבנה ל־JAR, ללא \`wholeYearAt\` נגזר.
- ה־Supervisor מדד PID ומזהה יצירת תהליך, SHA של הבינארי, קוד המקור, פקודת ההפעלה, JAR, stdout/stderr של מערכת ההפעלה, קוד יציאה 0, גיבובי קובצי נתוני מקור ו־normalized. \`resource admission\` נבדק לפני כל תהליך, עדיפות \`nice=19\`, מרחב כתובות Python 1.5GiB ו־JVM 8GiB וירטואלי, heap JVM ‏512MiB. **אין hard RSS cap מוכח** — אין לטעון אחרת.
- מקור Python החזיר קובצי \`raw-out\` ו־\`normalized-out\` נפרדים, receipt עם גיבוב עדות גבולות שנת 5000; Kotlin החזיר שבעה שדות מקוריים ב־stdout כתמליל TSV, ללא שמות קציצות/חודשים בשפת Cymraeg. \`native_raw_pair_gate_v018.verify_stream\` אימת כל שורת Python ביחס לשמות המקור; \`original_bounded_chunk_gate_v050\` השווה לשורות TSV של Kotlin.
- **2/2 ימים ו־5/5 שדות תאריך בכל יום תואמים; first_mismatch=null**, וללא חישובי נגזרת לצורך השוואה.

### שני ימי המקור שאומתו

| קואורדינטה | 15,055,672− | 15,055,671− |
|---|---:|---:|
| \`c\` (יום מעשה, בשני המקרים) | −15,055,671 | −15,055,671 |
| \`t\` (יום יעד) | −15,055,672 | −15,055,671 |
| \`year\` | 5000 | 5000 |
| \`cutlet_index\` | 10 | 10 |
| \`day_in_cutlet\` | 502 | 503 |
| \`month_index\` | 32 | 20 |
| \`day_in_month\` | 21 | 56 |
| Python \`cutlet_name_raw\` | Akrep | Akrep |
| Python \`month_name_raw\` | Kapalı kapı | Kuyu |

Kotlin המקורי **אינו** מפיק את שמות המקור Cymraeg: בתמליל המנורמל לצורך \`CrashStore\` השדות \`cutlet_name_raw\` ו־\`month_name_raw\` מכילים **טוקנים מספריים** (למשל \`"10"\`, \`"32"\`) והדוח מסמן \`kotlin_name_field_semantics=NATIVE_INDEX_STRING_NOT_NAME\`. אין להציג טוקנים אלה כשמות בשפה.

## 3. קיבוע ראיות v054

- קובץ רישום: \`soak/control/supervised_two_original_dates_v054.json\`.
- GitHub Actions run: \`43774977104\`, Artifact ID \`14186295655\`, שם \`soak-v053-two-original-native-days-not-year\`, ZIP המקורי **SHA-256 \`f87b2e925b4a400cff2e2469be5b873b66c89ca35498e8fcda1090ab55d5d390\`**, אורך 4,902,059 בתים. ZIP הורד, CRC עבר, גיבוב ZIP אומת כנגד GitHub, והבייטים של שורות המקור וקבלות התהליכים נבדקו מחדש.
- Python raw JSONL SHA \`88efda9d93bb7fb54d3900b7684054d7155178f84d59c2d60571d9fba5d309ae\`; normalized JSONL SHA \`db5f16647a3fe71defe9fb5b7d0e46222da57007d561c30ec74da2ff8757ea98\`.
- Kotlin stdout המקורי TSV SHA \`02508551a01aa6a7297ae7dbd0509d67a6a8567e0ddacb17e0816228a0ad3a2e\`; הייצוג המנורמל־אינדקסים SHA \`fb79d781ee3789d197e371920b7addd47fb31a9d2f23180fe2f5acb8179a6f90\`.
- רשומות תהליך Python וקוטלין: SHA \`6571619d9b9cc59310d3c5e48d1b0b1c135eafd9b4537a58a00bc42b5e9b09d4\` ו־\`e143f53d0b1225dd62ad2d319dbea48041c7607e0c3459271770995df504bd5b\`, בהתאמה.
- Kotlin JAR SHA \`70f2567a67712511f7e86c8ed3147c26c373f33150f7d707f390c207c9c522d6\`. גיבוב שרשרת המקורות \`d25d71bfeda5ef592162f10b564c9eb49f64176e4dc438ab2424c46a95c44ba7\`.

## 4. v055 — אימות חוזר ללא הפעלת ממירים

נוסף \`soak/runner/verify_original_two_day_artifact_v055.py\` וזרימת CI \`.github/workflows/soak-revalidate-original-two-days-v055.yml\`:

1. הורדת אותו ZIP בעזרת artifact ID נעול, בדיקת SHA-256, שמות ZIP מותרים, CRC, גודל מקסימלי, היעדר קישורים סימבוליים ושדות JSON כפולים.
2. Checkout מחדש של אותם מקור Python ו־Kotlin לפי SHA-40, הצלבת מפת השמות הקאנונית וקובצי המקור עם גיבוב שרשרת המקורות שנחתם בקבלת המקור, ובדיקת ה־JAR המקורי והפקודה.
3. הצלבת שתי שורות \`Python raw+normalized\` מול שתי שורות \`Kotlin OS stdout\` בעזרת שער v050; בדיקה מחדש של כל אחד מ־5 שדות התאריך ושל 2 קבלות התהליך.
4. ארבע התקפות מדומות של שינוי קובץ תאריך, זיהוי JAR, שם מקור או זיוף אישור שנת soak; ההתקפות מרעננות את גיבוב ה־ZIP וגם את גיבובי הקבצים הפגומים כדי לבחון את הבדיקה הסמנטית ולא רק את חתימת הארכיון.

**בעת כתיבת נקודת שחזור זו, הרצת v055 נמצאת במצב queued, לא PASS ולא FAIL.** אין להפעיל העתק נוסף לפני תוצאת completed/log. היעדר PASS עדיין אינו חסימה.

## 5. מצב מדעי והצעדים הבאים

- הישג חדש: **2 זוגות ימים מקוריים**, תחת פיקוח וראיות מקור, שנמצאו תואמים. היום השני חופף לבדיקה המקורית מ־v045; אין להוסיף את שניהם אוטומטית למספר הימים **הייחודיים** המצטברים.
- הראיות הישנות נשארו: 17,506 שורות תאריך **נגזרות** תואמות בארבעה צירופים, ו־33 קריאות F(c,t) מקוריות מדגמיות לכל מנוע Python/Kotlin בניסויים קודמים.
- מקור JavaScript+Interlingue המקורי עודנו חסום במשאבים לאחר כישלון V8 heap גם בגבולות 384MiB ו־1GiB, **ללא תוצאת תאריך**. אין MISMATCH.
- **0 שנות soak מקוריות מלאות שהוסמכו**, **אין ביקורת עצמאות lineage סופית ואין אורקל קאנוני עצמאי**. עצם הפעלת תהליך בפיקוח וקבלת SHA אינה הסמכת צד שלישי.
- לא החלה הרצת 10,000 השנים, לא הופעל Windows, ולא שונה \`main\`.
- הצעד הבא לאחר אישור v055: לשלב קבלות תהליך מקוריות אלה ב־\`CrashStore\` **בלי לאשר שנה חלקית**; לפתח איסוף מקור־למקור לאלפי מקטעי שנה, כאשר שנת Python מלאה מתבצעת קודם לשנת Kotlin, עצירה בהפרש הראשון, ועמידות לשחזור. לפני עבודה במחשב המשתמש חובה preflight עדכני ומגבלות משאבים אמיתיות.

**סמן המשך:** \`RESUME_EVIDENCE_FIRST | PROJECT_ID: PASTAFARI_ORIGINAL_NATIVE_YEAR_SOAK | QA=qa/soak-readiness-20261114 | NEXT=VERIFY_v055_COMPLETED_LOGS_AND_INTEGRATE_REAL_NATIVE_PROCESS_RECEIPTS_WITHOUT_YEAR_CREDIT\`.
