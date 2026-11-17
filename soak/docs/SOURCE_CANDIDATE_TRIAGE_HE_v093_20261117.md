# v093 — מיון כשירות מקורית לממירי תאריכים נוספים (ללא הסמכת עצמאות)

**תאריך:** 17.11.2026  
**היקף:** התאמת מפקד הממירים `pastafarian_converter_inventory_v20_20261114.json` (ספריית המשתמש) לראשי הענפים ולראיות GitHub שנקראו כעת. שינויים קיימים ב־QA בלבד; `main` מוגן.  
**מקור המפקד:** תאריך 14.11.2026, schema `pastafarian_converter_inventory/v15`, 58 רשומות reference,‏ 20 production/candidate,‏ 10 רשומות מיון לשוני ו־3 וריאנטים נוספים. רשומות אלה **חופפות**; הנתון 91 הוא מספר שורות קטלוג ולא מספר מנועים עצמאיים. `distinct_language_branches=66` גם אינו מספר מנועים שעברו אישור.

## ממצאי בדיקת ראשי הענפים והרצות CI

| מקור | ראש ענף שנמצא | ראיית ביצוע שנבדקה | סיווג מחייב |
|---|---|---|---|
| REF-41 Python+Türkçe | מקור נעול `0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4` | [QA v089 43977454446](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43977454446) `completed/success`; 14 ימי יעד ב־7 מקטעים יחד עם Kotlin | מקור F(c,t) נצפה בשני ימי יעד לכל מקטע, לא שנת מקור מלאה |
| PROD-KT-CY Kotlin+Cymraeg | ראש ענף `d5c8c67bc6135efea49a2328b35649a6aae89a73`; מקור נעול `0c703446d8a3b7435698bd16402ac5fa30e461c9` | [v085 43976583803](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43976583803); ראש הענף התעדכן רק בקובצי QA/workflow/ראיות יחסית למקור הנעול (2 commits, 7 קבצים) | מקור F(c,t) נצפה; Kotlin מפיק אינדקסים ולא שמות מקוריים; ללא עצמאות אלגוריתמית |
| TypeScript+मराठी | `cc3a613e3b80ba082e5cdb2c7a5d756c7e707df0` | [43938822563](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43938822563) — `completed/success` בראש הנוכחי; שבעה זוגות full-date bounded; שינויי הראש מאז v20 נגעו ב־workflow אחד בלבד | **מועמד מועדף למתאם מקור שלישי**, אחרי אימות שני קלטים, מקור, שמות ו־SHA |
| V+አማርኛ | `5bced35d2aef2e9ee1ed8b6eaa975bd978efe44c` | [43618919256](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43618919256) — `completed/success` על `79ccee0e`; מאז השתנה רק `.github/workflows/canonical-names-lock.yml` (קומיט אחד). [43619266674](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43619266674) הוא CI קאנון, לא מבחן F(c,t) חדש | **מועמד למתאם מקור נוסף**, על בסיס בדיקות מספריות תחומות; לא להרשות בשנת soak טרם אימות מקור/סביבת V |
| MATLAB+Polski | `959d0c77386facb841045236d5a1cbea726561f1` | [43959176382](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43959176382) — `completed/success` בראש הנוכחי, מבדק Native יום 42; ה־7 commits שנוספו מאז v20 הכניסו כלים ומבחני יום 39–42 | מועמד Native בתרחישי יום תחומים; לא שנת מקור מלאה |
| x86-64 Assembly + Sahidic | `1a1ea6a89f1f7a2cde9cba1f91aa1625a9284334` | [35640916185](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/35640916185) — ביקורת Stage56 הסתיימה `success` בראש הנוכחי | ביקורת סמנטית/Runtime מתועדת; נדרש מתאם F(c,t) מקורי מאומת, אין הוכחת שנת מקור |
| JavaScript+Interlingue (REF-24) | `03ac0c7f4db3c35487993dd31982faa37dd3948e` נעול ב־v016 | `soak/control/pilot_two_engine_source_locks_v001.json`: בדיקת מקור/תחביר ב־Windows בלבד, ללא קריאות F(c,t) באותו gate | מקור reference נעול תחבירית; אין לקדם למבחן Native על סמך תחביר |
| Codesh+𐤉𐤄𐤅𐤃𐤉𐤕 | `349ae65542948c9d77de0c6b6ffe51a932517876` | [43616772057](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43616772057) — `completed/cancelled` למבחן חמשת השדות; [43621805992](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43621805992) הוא `completed/success` **למבחן קומבינטורי בלבד** | **אין PASS של המרה מלאה מקורית**, אין להצטרף להשוואת מקור |

## הבחנה הכרחית בין כשיר להיבדק לבין מאושר להשוואת שנה

הטבלה מתעדת **ראיות CI מצומצמות**, לא עצמאות של מנועי המקור. במיוחד:
- התאמה מספרית של חמישה שדות בקומץ ימים אינה מוכיחה התאמה בשנת מקור שלמה.
- ראש ענף מתקדם ללא שינוי אלגוריתם יכול להיות מוכח רק לאחר בדיקת diff ו־SHA של קובצי המקור. בדקתי זאת עבור Kotlin, TypeScript ו־V. עבור MATLAB נבדקו קובצי התוספת, אך לא הושלמה סקירת סגירת כל התלויות למתאם שנתי.
- בדיקת הידור, תרחיש קומבינטורי, עוגן יחיד, בדיקת שירות HTTP או בדיקות קאנון אינן חלופה להרצת `F(c,t)` על שני מספרי יום מדויקים, עם פלט גולמי וגבולות שנה.
- לכל מועמד נדרש בירור אם הוא אותו אלגוריתם שהועתק, נגזרת, עטיפה, או משפחה עצמאית. גיוון שפות מימוש לבדו אינו הוכחת עצמאות.
- מנגנון source identity `soak/runner/source_identity_gate_v036.py` בודק מבנה/נעילות אך **אינו רשאי** להעניק עצמאות אלגוריתמית.

## פעולת ההמשך המעשית

לבנות מתאם קריאה מקורית מוגבל ל־**TypeScript+मराठी** על קומיט `cc3a613e...` (לא להתבסס על פלט workflow בלבד): לעגן את כל קובצי התלות, סוגי קלט מדויקים, חמשת שדות הפלט ומיפוי השמות; ליצור שני ימי יעד מוסכמים; להשוות פלט Raw ל־Python ולשמור קבלה נפרדת. רק לאחר PASS כזה להציע את אותו ממשק למנוע V+አማርኛ. אין להוסיף אף מועמד כ־`verified full-year engine` ללא מבחן שנה מלאה.

**ספירה מדעית נוכחית:** 14 ימי יעד מקוריים משני מנועי המקור הקיימים, 7 מקטעים שעברו CrashStore, 0 שנות מקור מלאות, 0 שנות soak מאושרות. בגיבוי v091 נוצרו 8 נכסים ונבדקו בהורדה חוזרת. **main לא שונה**.
