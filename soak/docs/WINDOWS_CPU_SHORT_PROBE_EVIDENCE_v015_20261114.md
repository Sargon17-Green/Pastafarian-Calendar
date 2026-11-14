# ראיות Windows — מדידת CPU Job Object קצרה (v015)

**תאריך:** 2026-11-14 · **סטטוס:** `SHORT_CPU_THROTTLE_OBSERVED_PASS` · **תחום:** תהליך בדיקה יחיד, ללא ילדים או ממירים.

מקור הבדיקה: `RUN_PASTAFARI_SOAK_CPU_HARDCAP_V015.py`, SHA-256 `21cd3eea5868fc21f2d409fed55c141c0a4cd8b26344c34a05213ebbbd317bc5`. הקובץ הועלה ל־Drive רק לאחר אימות שגיבוב קובץ ההעלאה תואם למקור. הוחזר מייל תוצאה עם קוד יציאה 0 ולוג מדידה.

| נתון | ערך שנמדד |
|---|---:|
| CPUs לוגיים | 8 |
| CPU rate requested | 500 יחידות = 5% מכלל המעבד |
| Hard cap flags readback | 5 (ENABLE + HARD_CAP) |
| CPU rate readback | 500 |
| Process assigned to own Job Object | true |
| BELOW_NORMAL priority verified | true |
| זמן שעון של דגימת העומס | 2.000 שניות |
| זמן CPU שדווח לתהליך | 0.9688 שניות |
| חלק יחסי של זמן ה־CPU מתוך 8 מעבדים | 0.06055 = **6.055%** |
| free RAM at admission | 376,909,824 bytes |
| Children started | 0 |
| Converter started | 0 |
| Global changes | 0 |
| ZIP SHA-256 | `cbf97d10ab7dcca282131c969fb0d0bcbdeebdac3cbd665ca4e3df42c332e106` |

**הסקה מותרת:** בהינתן 8 CPUs, נמדד ניצול יחסי נמוך במשימת CPU של שתי שניות, התואם עקרונית להגבלת CPU פעילה; נמדדו בפועל 6.055% ולא 5.000%. סף הקבלה היה 9%, כדי להימנע מכישלון שווא בחלון קצר. אין זו הוכחת תקרה מתמטית קשיחה לכל חלון זמן, ולא ניסוי עומס ממושך. אין להסיק מכאן שניתן להריץ שני ממירים כבדים עם RAM פנוי של פחות מ־512 MiB. הצירוף של v014 ו־v015 סוגר את שער יכולות Windows הבסיסיות, אך טרם נבדקה ההשפעה המצטברת על שני ממירים.

**סיכום:** מקור וראיות נשמרים תחת תיקיית `Pastafarian-Converter-Soak`; אין תיקון ל־`main`, אין שירות קבוע ואין אוטומציה מחזורית.
