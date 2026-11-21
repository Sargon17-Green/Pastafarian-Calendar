# v147 — הקשחת JSONL למבחן Soak רב־מנועי

**ענף QA:** `qa/soak-generic-jsonl-hardening-v147`. זהו תיקון של התשתית הגנרית להשוואת כל הממירים, לא של אלגוריתם Ada לבדו.

## ליקוי ממשי

המשווה `soak/runner/year_validator.py` הפעיל `json.loads(raw_line)`. כברירת מחדל, Python מקבל מפתחות JSON כפולים ושומר את האחרון. למשל, `{"month_index":20,"month_index":30}` מפורש כ־30. לפיכך רשומה עמומה של מנוע אחד הייתה עלולה לעבור השוואת שנה מול רשומה חד־משמעית של מנוע אחר ולהפיק PASS שגוי.

בנוסף, `json.loads` מקבל כברירת מחדל `NaN`, `Infinity` ו־`-Infinity`, שאינם ערכי JSON תקניים.

## התיקון

נוספו `object_pairs_hook` שדוחה כל מפתח כפול (גם בעומק אובייקט) ו־`parse_constant` שדוחה מספרים לא־תקניים. `TranscriptError` משמר מספר שורה וסיבת פסילה. JSON תקין ושמות מקוריים שונים בשפות שונות ממשיכים להתקבל. אין שינוי במקורות הממירים או באלגוריתמים.

## בדיקות

נוסף `soak/process_tests/test_soak_generic_jsonl_hardening_v147.py` הכולל **24 בדיקות**: ניסיון ממוקד להשוואת PASS שגוי בעקבות `month_index` כפול, כפילות בשדות זהות/זמן/גיבוב ובאובייקטים פנימיים, כל שלוש צורות NaN/Infinity, JSON שבור, שדה בוליאני במקום שלם, ימים חסרים/כפולים, אי־התאמה מספרית, בדיקת שפות שונות ושמירת מספר שורה.

Workflow `.github/workflows/soak-generic-jsonl-hardening-v147.yml` בודק גם **10** בדיקות `year_validator` קיימות ו־**12** בדיקות `two_lane_scheduler` קיימות. סך הכול **46** בדיקות Python בלבד. הוא בודק את הסימון `STOP_NEW_NATIVE_SOAK_DISPATCH`, את SHA של `main` בקריאה בלבד, ומעלה לוגים בלבד — לא בינרי ולא מקור מפענח תאריכים.

**שער קבלה:** רק הרצת [CI 44879642784](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44879642784) לאחר `completed/success`, עם 46/46 בדיקות וארטיפקט, תסמיך את v147. יצירת הקוד אינה קבלה.

## גבולות מדעיים

התיקון אינו מאמת את מיפוי השמות, את גיבובי פלט המקור, את גבולות השנה, את עצמאות האלגוריתמים או את כשירות Windows. אין קריאות לממיר המקורי `F(c,t)`; Issue #29 פתוח והחסימה על Soak מקורי נשארת בתוקף. **0/10,000 שנים מאושרות**, `main=56bc4173aae4975ded019ef5ab5a36249f1424df` ללא שינוי.

[מפרט האב Issue #27](https://github.com/Sargon17-Green/Pastafarian-Calendar/issues/27) | [חסימת אי־התאמה Issue #29](https://github.com/Sargon17-Green/Pastafarian-Calendar/issues/29).

## קבלת v147 — הושלמה ב־21 בנובמבר 2026

ההרצה הראשונה [44879642784](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44879642784) נכשלה **לפני כל בדיקת אלגוריתם**, עקב `assert` לא־תקין בסקריפט ה־workflow. התיקון המבודד בוצע בקומיט `87fdc847d56cd2a7af00fb45969baa5a48321ae4`.

**ההרצה החוזרת [44881920229](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44881920229) הסתיימה `completed/success`** בדיוק על קומיט זה: 24/24 בדיקות אדוורסריות, 10/10 בדיקות משווה קיימות, 12/12 בדיקות מתזמן, יחד **46/46**. שלבי אימות עצירת ה־Soak והיעדר ייבוא של ממירי תאריכים מקוריים עברו.

**ארטיפקט:** `14697689798`, `soak-v147-generic-jsonl-hardening-46-python-tests-logs-only`, גודל 2,358 בתים, SHA-256 לפי מטא־נתוני GitHub Actions: `60bea8cb0477a75f730535221586b26e35aeb75cf98ad2ead5fa43fa3bd28223`. לא בוצע אימות הורדה עצמאי של בתיו.

**גבול הקבלה:** קבלת תיקון JSONL ומבחני תשתית סינתטיים בלבד. אין הרשאה להפעיל ממירים מקוריים, Issue #29 פתוח, 0/10,000 שנות Soak מאושרות. קומיט התיעוד המאוחר יותר אינו קומיט המקור שעבר CI.
