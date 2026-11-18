# נקודת שחזור v097 — מקור שלישי והצלבה משולשת

תאריך: 18.11.2026. כל העדכונים בענף QA qa/soak-readiness-20261114 בלבד. ראש main הקבוע: 56bc4173aae4975ded019ef5ab5a36249f1424df.

## v094: שתי המרות מקוריות ב־TypeScript+मराठी

הרצה מתוקנת: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44363057604 — completed/success.

הממיר המקורי בקומיט cc3a613e3b80ba082e5cdb2c7a5d756c7e707df0. פונקציית מקור calendarDateSpaghetti(c:bigint,t:bigint), ללא חישוב תאריך במתאם. ננעלו 69 קובצי src ב־SHA-256 ועץ Git e733eb4e82f15efc27f294e09aff2e588b4ea06f. הקטלוג המקורי ממפה מחרוזות שמות למספרים.

הקלט בשני הממירים: c=-15055671. שני ימי יעד, עם חמשת השדות:
- t=-15055660: [5000,14,11,1,42], שמות Marathi היכן שידועים हसू / चिकणमाती.
- t=-15055659: [5000,14,12,42,45], שמות Marathi हसू / जीभ.

12/12 בדיקות של מבקר הפלט עברו; שתי קריאות מקור Python ושתי קריאות מקור TypeScript בוצעו בטור. בהשוואה עשרה שדות מספריים תואמים בשני הימים. אין הוכחת זהות שמות מילולית בין השפות.

ארטיפקט 14454273351, גודל 10,817 בתים, 17 קבצים, CRC תקין ו־SHA-256 של ZIP:
a798cac07e77e704c97af637009cf1fcbcaf1f1358767f3f7690bad4acb54a70.
SHA של פלט TypeScript הגולמי f95e8c3d0ce545aeb8df38643654d2cf465d1e8aa7e84fc8fa66c02b645a1b9c.

ניסיון ראשון: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44362836606 נכשל בשלב תחביר פרמטרים של המתאם, לפני קריאת TypeScript. תוקן ל־CLI תקני של זוגות switch/value; ההרצה השנייה הצליחה.

## v095: ארכיון מקור נעול ובדיקת שחזור

- מסמך מקור: soak/control/typescript_marathi_original_v094_pin_v095.json — כל 17 SHA, קומיטים, גיבוב עץ המקור, מספרים ותאריך.
- כלי בדיקה: soak/runner/replay_third_original_v095.py.
- 12 בדיקות שלילה/מקור: soak/tests/test_replay_third_original_v095.py.
- Workflow: .github/workflows/soak-third-original-artifact-replay-v095.yml.

ניסיון ראשון https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44364460544 נכשל ב־SyntaxError של כלי השחזור, עוד לפני ביקורת הראיות; שגיאת התחביר תוקנה ונוסף שער ast.parse מפורש.

הרצה מתוקנת https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44366186797 הייתה queued בבדיקה האחרונה; אין למנות PASS בטרם completed/log.

## v096: השוואת שלושת הממירים מתוך שני ארכיוני מקור עצמאיים

1. מקור Python+Kotlin ממקטע 1021: הרצה 43976583803, ארטיפקט 14281261657, SHA-256 b7f250a98aea07acb4a78bf074e75c5f72d950f00a1d32d7bc81c6eb8c464b32, 22 קבצים.
2. מקור TypeScript+Python ממקטע 1021: הרצה 44363057604, ארטיפקט 14454273351, SHA-256 a798cac07e77e704c97af637009cf1fcbcaf1f1358767f3f7690bad4acb54a70, 17 קבצים.

בהצלבה מקומית של שני קובצי ZIP המקוריים, CRC, גיבובי SHA ופלטי המקור אומתו. קובצי Python raw ו־normalized נוצרו בשתי הרצות נפרדות ונמצאו byte-identical ל־2 הימים. TypeScript ו־Kotlin הופקו כל אחד בנפרד; כל חמשת שדות התאריך התאימו בין שלושת הממירים בשני הימים. התוצאה: שש תצפיות מקוריות תואמות, אך אפס ימי יעד ייחודיים חדשים.

הקוד לחזרה על הבדיקה: soak/runner/verify_three_original_artifacts_v096.py.
העדות הקפואה: soak/control/three_original_engine_1021_witness_v096.json.
שבע בדיקות נפרדות: soak/process_tests/test_three_original_archive_cross_v096.py.
Workflow: .github/workflows/soak-three-original-archive-cross-v096.yml.
הרצת v096 https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44365976004 הייתה queued בבדיקה האחרונה, ולכן לא הוכרז PASS של GitHub CI עבור v096.

## היתכנות מחשוב

בלוג TypeScript של v094: השלמת יום ראשון ב־17:51:09.550Z, השלמת השני ב־17:51:35.003Z, תחילת השלב ב־17:50:44.182Z. בקירוב 25.4 שניות לכל יום יעד בתנאי הדגימה. אילו קצב זה היה נשאר זהה בשנה בת 4,244 ימים, היה צורך בכ־30 שעות לממיר TypeScript לבדו לאותה שנה. עבור 10,000 שנים *באותו אורך ומהירות*, סדר הגודל הוא כ־34 שנות זמן של עובד יחיד. אין לראות בכך תחזית: נבדקו רק שני ימים, חישובים בשנים אחרות יכולים להשתנות, והשרת אינו מחשב Windows המאושר. נדרש מדגם ביצועים נפרד לפני תכנון soak של 10,000 שנים.

## סטטוס מחייב

14 ימי יעד מקוריים ייחודיים עד כה; 2 מתוכם עם שלושה מקורות; 7 מקטעי Python מקוריים שעברו CrashStore. אפס שנות מקור מלאות, אפס מתוך 10,000 שנות soak, אפס הסמכת עצמאות אלגוריתמית. המחשב Windows לא הופעל בסבב זה; main לא שונה.

המשך: להכריע v095 ו־v096 אך ורק מתוך completed/log, לחקור כל כשל אמיתי, לשמר את ארכיון v094 באחסון ארוך־טווח, ולהגדיר שער היתכנות ביצועים והרחבה למקורות נוספים לפני הרצת שנת מקור שלמה.
