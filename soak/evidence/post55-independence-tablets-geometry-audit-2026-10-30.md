# Post-55 — Kotlin/Cymraeg מול Python/Türkçe: ביקורת עצמאות וגאומטריית TABLETS (2026-10-30)

## היקף ואסמכתאות קפואות

- Kotlin branch `Kotlin+Cymraeg`, HEAD קודם: `99bba78a5af133a4c02994c6f9331f12497d0d92`.
- קוד Kotlin: `src/main/kotlin/pastafari/ProductionGateYear5000Engine.kt`, `ProductionYearNavigator.kt`, `ProductionMonthWeavingEngine.kt`, `soak/Post55ProductionDateBridge.kt` באותו HEAD.
- מקור Python שנשלף ב-Workflow: `7cb12bf355461e5a179e0deadb7365689288bf29`; קוד `src/pastafari_calendar/final_integration.py`, `calendar.py`, `acceleration_scars.py`. הגשר `soak/python_turkce_bridge.py` ב-HEAD של Kotlin מייבא `calendar_date_spaghetti` מה-checkout המסומן.
- ריצה `41108969562`, job `124246014448`: `completed/success`; כל 11 מבחני harness עברו, שש השוואות אמתיות של חמשת רכיבי התאריך ב-FOUNDATION, אפס mismatches, artifact `13004160427`. ה-log מסווג `PASS_DIAGNOSTIC_NOT_CERTIFIED`. ה-Workflow בדק את שני ה-SHA ואת מיקום מודול Python; לכן נמצאה הפרדת checkout ותהליך, **לא** הסמכת אלגוריתם.

## ביקורת עצמאות — מה ידוע ומה לא

1. **מימושים נפרדים:** Kotlin מריץ `Post55ProductionDateBridge.convert` מול `ProductionYearNavigator` ו-`ProductionMonthWeavingEngine`; Python מריץ `calendar_date_spaghetti` ו-`FinalSpaghettiIntegrationManager`. קריאת המקור לא מצאה קריאה ישירה של Kotlin ל-Python או של גשר Python ל-Kotlin. העובדה שאותם חמישה שדות מסכימים בשישה עדים **אינה** מוכיחה נכונות מחוץ למדגם.
2. **תלות מתמטית משותפת:** `ProductionMonthWeavingEngine.suffix()/openedBranchRatios()/dayAt()` ב-Kotlin ו-`LegalMonthWeavingDP` + `integratedDPUnrankLegalWeaving()` ב-Python משתמשים שניהם בספירת המשכים קומבינטורית, מקדמי בינום ובחירת rank לפי סדר לקסיקוגרפי. המימושים אינם שיתוף קוד, אך אין הוכחה שהם בלתי־תלויים מבחינה אלגוריתמית או מפני אותה שגיאת הנחה.
3. **מטמוני Python:** `calendar_date_spaghetti` מאפשר `acceleration_scars` כברירת מחדל; קיימות שכבות cache/checkpoint/oracle. בריצת המדגם `--batch 1` הפעלת Python נוצרת מחדש עבור כל זוג, ולכן cache תהליכי אינו ממוחזר בין זוגות; עם זאת אין בכך הוכחת עצמאות מכל checkpoint קשיח.
4. **סף הסמכה:** `soak/post55_differential.py` חוסם `--certify` בכל מצב. אין להחליף סיווג זה עד ביקורת נפרדת מוכחת והגדלת כיסוי איכותית, ולא רק מספר בדיקות.

## TABLETS — פער מבני מאומת

- `FOUNDATION=-15,055,671`; `TABLETS=-278,522`; מרחק = `14,777,149` ימים.
- פער שער מקסימלי `963` ימים, מינימלי `42`. לכן אפילו לחציית המרחק לבדו נדרשים **לפחות** `ceil(14,777,149/963)=15,345` מעברי שער. חלון מועמדי Year-5000 מוסיף `5,778` ימים בצד הרלוונטי: חסם תחתון `ceil((14,777,149+5,778)/963)=15,351`. שניהם עולים על `8,192` שערים שמגביל `ProductionGateYear5000Engine` סביב FOUNDATION.
- סף דחייה ב-Kotlin `8,192×963−5,778=7,883,118` הוא **תנאי הכרחי בלבד** להיתכנות, לא ערובה לכך שקלט בתוך הסף יצליח. בדיקת sentinel ב-HEAD זה מאמתת את הקבועים וההוצאה הגאומטרית. אין טענת פלט TABLETS בשבעה שדות.
- Python מכיל `GATE_CHECKPOINTS_INTEGRATED` ב-`final_integration.py` ו-`IntegratedGateCache._reanchor_for_cover` יכול להחליף את נקודת העיגון בתחילת חישוב. סמוך לאזור TABLETS קיים checkpoint `(28672, -674161)`; בניגוד ל-Kotlin, Python אינו מתחיל בהכרח את כל 28,672 השערים מהיסוד בכל שאילתה. מקור המספרים בטבלה מתואר בקוד כתוצאה נגזרת, אך **לא הוצגה בביקורת זו ראיית שחזור בלתי־תלויה של כל נקודות העיגון**.
- טבלת עיגון מקצרת עבודה אך עלולה לשמש הנחה משותפת שגויה אם אינה מאומתת. אין להעתיק אותה ל-Kotlin כהנחת אמת ואין להגדיל מיידית `maxGateAbsIndex`.

## NEXT טכני תחום — בלי שינוי סמנטי או תקציב שרירותי

1. הגדר חוזה הוכחת checkpoint: כל זוג `(index,day)` מתקבל רק לאחר שחזור דטרמיניסטי של רצף שערים מהעוגן הקודם שכבר אומת, כולל signed-index, חוק gap המדויק, גבולות 42..963, continuity ובדיקת digest של מקור ושיטת החישוב. הוכחת המקור הראשונית מ-0 עד checkpoint הראשון דורשת שרשרת אימות תחומה למקטעים, לא אמון במספר המוטבע בקוד.
2. בנה proof-of-concept נפרד לניווט מקטעי שערים עם `index` גלובלי ומכסת עבודה/זיכרון לכל מקטע, ללא העלאת מגבלת מנוע הייצור, ללא שינוי הפלט בן חמשת הרכיבים וללא מיזוג. **אין** לקבל checkpoint לא מאומת או להשתמש במטמון כתשובת oracle.
3. הצג בדיקות נכונות לעוגן 0, לגבולות מקטעים, לכיוון שלילי/חיובי ול-checkpoint הסמוך ל-TABLETS. רק לאחר אימות השרשרת, בצע differential ממוקד ב-`TABLETS-1, TABLETS, TABLETS+1` מול מקור עצמאי עם ראיות native, משך ותקציב תחומים.
4. ביקורת עצמאות נפרדת: השוואת גרף תלויות ושתי שיטות ביקורת שונות עבור שלבי gate/rank/weaving, ובדיקות עד מיצוי למקרים קטנים. הסכמה על שישה עדים אינה מספקת הסמכה. כל עוד אין הוכחה זו, `--certify` נשאר כבוי.

**הכרעת סבב:** ביקורת מקור ותכנון הנדסי; ללא שינוי ייצור, ללא בדיקת Native חדשה לקובץ תיעוד זה, ללא PASS מלא וללא שינוי מכסות. מגבלת TABLETS היא חסם להסמכה הנוכחית, לא חסם לביצוע ה-NEXT התחום.
