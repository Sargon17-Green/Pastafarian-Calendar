# נקודת שחזור v077 — קליטת שלושה מקטעי מקור עברה CI; תיקון המדרגיות בבדיקת רגרסיה

**מאגר:** `Sargon17-Green/Pastafarian-Calendar`
**ענף QA ראשי:** `qa/soak-readiness-20261114`
**נקודת בסיס:** `0420fd8def1cce607a1761e1d2374a533c188d10`
**ענף תיקון נפרד:** `qa/soak-link-ledger-v076`
**תאריך UTC:** 16.11.2026

## 1. עדכון מחייב ל-v075: v074 עבר

- [Run 43961579686](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43961579686) הסתיים `completed/success` (attempt 1), מקור הקוד `2016db0c6d30d6f97bf7aa8ef60389944e425e07`.
- Job `133630074608` הסתיים `completed/success`, כולל רכישת שלושת המקורות ו-12 בדיקות אינטגרציה.
- בדיקות SHA-256 לארכיוני v053/ordinal1015, v061/ordinal1016, v070/ordinal1017 עברו. חלון 12 הבדיקות הסתיים ב-`Ran 12 tests in 20.079s` וב-`OK`. סמן הלוג: `V074_THREE_ORIGINAL_SOURCE_CHUNKS_CRASH_LEDGER_PASS_NO_WHOLE_YEAR_CREDIT`.
- ארטיפקט לוג: ID `14275948196`, `soak-v074-three-original-source-chunks-ledger-no-year`.
- התוצאה מאשרת בדיקת קליטת **3** מקטעי Python מקוריים ו-**3** קישורי תהליך, כולל שחזור offline, מניעת replay כפול, בדיקות השחתה/חוסר ראיות, וטיפול ב-`.part` יתום. קליטת Kotlin כמועמד עדיין חסומה לפי סדר השנה.
- v074 הוא **מבחן קליטה של ראיות שכבר הופקו**: אפס קריאות `F(c,t)` חדשות בשלב הזה; אין לייחס לו תאריכים חדשים.

## 2. תיקון ביצוע v076 — עדיין מחוץ לענף QA הראשי

בענף נפרד `qa/soak-link-ledger-v076` בוצע תיקון לסריקה ריבועית:
- נקודת מימוש `307b382a8ed0148ca075e2b97ca624a7b9b6def3`. סריקת כל ארכיוני המקור פעם אחת + אימות קישור פרטני לכל מקטע; `verify_and_recover` מעביר חותמת ביקורת פנימית לאחר סריקה שכבר נעשתה, בלי להחליש את מסלול האימות הישיר.
- [Unit CI 43966769227](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43966769227) הסתיים `completed/success`, ארבע בדיקות עברו `Ran 4 tests` ו-`OK`; Artifact ID `14276712099`.
- נוצרה הרצת רגרסיה משולבת [43967499900](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43967499900) על `6c679ad54e0a40adbfb52f5c9e374985307cd495`, שתפקידה להריץ **12** בדיקות שלושת המקורות האמיתיים ועוד **4** בדיקות תכנון הביקורת. הייתה `queued` בזמן כתיבת נקודה זו; **לא להסיק PASS ולא להריץ כפילות**.
- אחרי `completed`: אם כל 16 הבדיקות עברו, אפשר לקדם את ענף התיקון לתוך QA (לא ל-`main`) תוך אימות SHA ומצב CI. אם נכשל, לבדוק לוג completed ולתקן לפי ראיות בלבד.

## 3. סטטוס הסמכה

- **6/6 ימי יעד מקוריים** בשני הממירים (אותו `c=-15055671`) התאימו בחמשת שדות התאריך. שלושה מקטעים 1015–1017, שני ימים בכל מקטע.
- **3** מקטעי Python original source עברו שער קליטה/שחזור ב-CI v074 (לפני קידום v076); **0** מקטעי Kotlin נתוני שנה נקלטו.
- **0** שנות Python מקוריות מלאות הושלמו, **0** שנות soak מתוך 10,000 הוסמכו; אין אישור לעצמאות אלגוריתמית או ל-canonical oracle.
- עדיין נדרשים כל **2,122** מקטעי שנת Python השלמה וכל יתר ממירי המקור הבלתי תלויים לפני תחילת soak עשרת אלפים שנה.
- לא הופעל מחשב Windows; לא שונה `main`. אין להסתמך על תוצאות נגזרות כעל פלט מקורי.

**סמן המשך:** `PASTAFARI_ORIGINAL_NATIVE_YEAR_SOAK | CHECKPOINT=v077 | NEXT=VERIFY_COMPLETED_V076_INTEGRATED_REGRESSION_16_TESTS_THEN_QA_ONLY_PROMOTION | NO_MAIN=true`.
