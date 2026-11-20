# v132 — ביקורת תלות ישירה על מקור נעול: חמש משפחות מימוש

תאריך ביקורת: 20.11.2026. ענף QA: `qa/soak-first-hop-deps-v132`.

## הוכחה והיקף

ריצת GitHub Actions [44725310090](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44725310090) הסתיימה ב־`completed/success`.
שבע־עשרה בדיקות סינתטיות עברו, ושמונה קובצי שורש אומתו מחדש מול
SHA-256 המקור, Git blob SHA-1 וגודל הבתים שבדוח v131 הקפוא.

ארכיון הריצה: artifact `14623058885`,
SHA-256 של ZIP לפי GitHub:
`6e949b67da61bdd9e322a1b34b55ee9769f63798cbce292e0fab86a24bcfd22e`.

הניתוח משתמש ב־`v131-lineage-screen.json` שנשמר מארכיון
הרצת CI המאומתת `44715717410`. גיבובי אותו מקור לא מוחלפים
בנתונים שנוצרו מחדש. הגישה אל GitHub ברמת `contents:read` בלבד
ועל קומיטים היסטוריים, ללא קריאה לממיר `F(c,t)` או לתהליכי build.

## ממצאים ישירים לפי מקור

| רשומה | קובץ כניסה שנבדק | ממצא תלות ישירה |
|---|---|---|
| `REF-41` (Python reference) | `tests/normative_reference.py` | לא נמצאו ייבואים יחסיים לקבצים מקומיים; תלותי ספרייה תקנית אינן נחשבות סגירה של כל תלויות זמן הריצה |
| `TURKISH-PY` | `src/pastafari_calendar/calendar.py` | **11** קובצי Python שיובאו באופן יחסי נמצאו ב־snapshot ואומתו בבתי המקור |
| `REF-24` (JavaScript reference) | `tests/normative-reference.js` | תלות ישירה אחת, `src/source-language-catalog.js`, נמצאה ואומתה |
| `INTERLINGUE-JS` | `src/index.js` | אותה תלות ישירה `src/source-language-catalog.js` נמצאה ואומתה |
| `SEER-NEXT-HYBRID` | `research/seer-next/src/seer_next_hybrid_engine_service.cpp` | `#include "seer_calendar_core.hpp"` — כותרת אומתה ב־`prototype/src/seer_calendar_core.hpp`, אבל אין הוכחה ש־`-I` או הגדרות build כוללות נתיב זה |
| `SEER-NEXT-YEAR-CACHE` | `research/seer-next/src/seer_next_engine_service.cpp` | אותה כותרת, אותה מגבלה לגבי נתיב ההכללה |
| `COPTIC-X64` | `src/production/stage54_integration.s` | **36** שמות `.extern` ייחודיים; לא נבדקו עדיין מפת הסמלים המסופקים, אובייקטי הקישור או כללי `build.sh` |
| `PALEO-CODESH` | `מקור/תאריך־שלם־טהור.אמן` | מקור DSL קיים ואומת, אך לא הופעל מנתח תחביר ותלויות של Codesh; הסטטוס נשאר לא מאומת |

**13** הפניות יחסיות לקבצי מקור נמצאו ונבדקו: 11 בפייתון ושתיים ב־JavaScript.
נוספו **2** ראיות לגיבוב כותרת C++ שנמצאת *מחוץ לנתיב החיפוש המקומי שנצפה*,
**36** סמלי קישור חיצוניים שלא שויכו, ומקור DSL אחד שלא נותח.

## מה נשאר בלתי מוכח

1. סריקת `from .module` בפייתון ו־`require("./...")` ב־JS
   מאתרת **תלויות ישירות מילוליות בלבד**. היא אינה פותרת ייבואים
   דינמיים, תלותי ספרייה חיצוניים, או את כל עץ התלויות הטרנזיטיבי.
2. סריקת `#include "..."` אינה בודקת את דגלי הקומפיילר.
   מציאת `seer_calendar_core.hpp` תחת תיקייה אחרת **אינה**
   אישור שהקומפילציה נעשתה עם אותה כותרת.
3. שמות `.extern` של GNU Assembly אינם ראיה שקיים אובייקט
   המכיל הגדרה תואמת. נדרשים תסריט הקישור, חתימת סמלים,
   גיבובי אובייקטים ובינארי.
4. יש צורך בניתוח תחבירי של Codesh ולא בהסקה מרשומות קבצים.
5. בדיקת מקור ב־CI **אינה** עדות לביצוע `F(c,t)`,
   להחזרת stdout מקורית או להשלמת שנה.

בדיקת v131 קבעה שחופפת רשומת המקור עם:
`COPTIC-X64/TRIAGE-10`, `PALEO-CODESH/TRIAGE-02` ו־
`SEER-NEXT-COLD-PROBE/SEER-NEXT-HYBRID`.
v132 אינו יוצר ישות מנוע נוספת עבור כל רשומה חופפת,
ואינו מאשר שאותו קובץ הוא האלגוריתם כולו.

השלב ההנדסי הבא: שער ראיות build וקישור **קריאה בלבד**
למימושי Coptic ו־Seer תחילה; מיפוי ה־36 סמלים מול מקורות
האסמבלר וכללי `build.sh`, ואימות נתיב `-I` של הכותרת
המשותפת ב־Seer. אין לבנות או להריץ כל תוכנית מקורית עד
הכרעה נפרדת בשאלת אי־ההתאמה המקורית ב־Issue #29.

**מצב מדעי מחייב:** `STOP_NEW_NATIVE_SOAK_DISPATCH`,
`native_date_calls=0`, `official_10000_year_soak_credit=0`.
לא בוצעה הסמכה של אלגוריתמים עצמאיים או של שנות Soak.
