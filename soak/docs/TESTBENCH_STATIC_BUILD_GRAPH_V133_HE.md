# v133 — אימות סטטי של מקורות קישור Assembly ונתיבי בניית Seer

**תאריך:** 20.11.2026. **ענף:** `qa/soak-build-graph-v133`.  
**CI מאומת:** [44733669943](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44733669943) — `completed/success`; **15/15 בדיקות יחידה סינתטיות עברו**.

**ארכיון ראיות:** `soak-v133-frozen-build-graph-source-only`, מספר `14627247618`, SHA-256 של ZIP לפי GitHub ובדיקה מקומית:  
`8bfca18a1027e138b4e9e711996c605c33fac9ec51083296bd1bd7052f954ccc`.

המבקר הוריד בתים ישירות מ־GitHub עבור קומיטים מדויקים, וידא Git blob SHA-1, SHA-256 של קובצי המקור וגודל הבתים, והשווה את נקודות הכניסה לעותק ראיות v132 המקובע. **לא הורץ אסמבלר, קומפיילר, מקשר או ממיר תאריכים.**

## 1. Coptic Assembly — מפת ספקי סמלים

מאגר `Sargon17-Green/Pastafarian-Calendar`, קומיט מקור נעול:  
`1a1ea6a89f1f7a2cde9cba1f91aa1625a9284334`.

תסריט `build.sh` מגדיר יעד `build/stage54_final_integration`; התסריט כולל פקודות `as --64` עבור שמונת קובצי האובייקט שצוינו בפקודת `ld`. המנתח תוקן לתמוך בפקודות `ld` עם `\` והמשך שורה — בהתאם ל־`build.sh` המקורי.

| אובייקט המתועד בקישור | קובץ מקור נעול | סמלי `.extern` שמצאו בו `.global` |
|---|---|---:|
| `build/bootstrap.o` | `src/production/bootstrap.s` | 18 |
| `build/bigint.o` | `src/runtime/bigint.s` | 10 |
| `build/arena.o` | `src/runtime/arena.s` | 3 |
| `build/stage56_bowlsum_corrective.o` | `src/production/stage56_bowlsum_corrective.s` | 3 |
| `build/catalog.o` | `src/catalog/source_language_catalog.s` | 2 |
| `build/stage54_integration.o` | `src/production/stage54_integration.s` | 0 |
| `build/stage56_historical_sauce_bridge.o` | `tests/stage56_historical_sauce_bridge.s` | 0 |
| `build/stage54_final_integration.o` | `tests/stage54_final_integration.s` | 0 |
| **סה״כ** | **8 קובצי אובייקט מוצהרים** | **36** |

כל 36 הצהרות `.extern` של קובץ `stage54_integration.s` משויכות, לפי ניתוח טקסט המקור, להצהרת `.global` אחת בדיוק באחד ממקורות האובייקטים בקישור שנצפה.

**גבול הראיה:** `.global` לבדה אינה הוכחה להגדרת סמל תקפה בקובץ אובייקט; גם התאמה מלאה של ההצהרות אינה מוכיחה שקישור GNU `ld` הצליח. לשלב הבא עדיין נדרשים נתוני `nm`/טבלת סמלים מאובייקטים בעלי גיבוב נעול, פקודת קישור שבוצעה, זהות בינארי וראיות ריצה מקוריות. בפרט נדרשת ביקורת השפעת `--wrap=stage56SauceRawBowlSumCorrective`.

## 2. Seer — שני מסלולי בנייה במחקר

מאגר `Sargon-17-Green/Pastafarian-Calendar-Seer`, קומיט מקור נעול:  
`866e9bbff59399310416ae25de1b664f9b6c3124`.

המקורות שנמצאו ונבדקו:

| נתיב | Year-cache | Hybrid |
|---|---|---|
| סקריפט בנייה | `research/seer-next/scripts/build_candidate.sh` | `research/seer-next/scripts/build_hybrid.sh` |
| מקור השירות | `seer_next_engine_service.cpp` | `seer_next_hybrid_engine_service.cpp` |
| הגדרת נתיב חיפוש | `-I"$ROOT/prototype/src"` | אותה הגדרה |
| כותרת משותפת | `prototype/src/seer_calendar_core.hpp` | אותו SHA-256 |
| קובצי C++ בסיסיים | `seer_year_core.cpp`, `seer_calendar_core.cpp` | אותם קבצים וגיבובים |
| קובצי Weave מותנים | `seer_weave_portable.cpp` או `seer_weave_avx2.cpp` | אותם שני מקורות אפשריים |
| בינארי מוגדר | `research/seer-next/build/seer_next_engine_service` | `research/seer-next/build/seer_next_hybrid_engine_service` |

שני מסלולי המחקר משתמשים באותה תשתית C++ ובאותם קובצי weave חלופיים, אך לכל אחד קובץ שירות שונה. **שיתוף ספריות וקובצי מקור אינו מכריע אם שני המסלולים הם אלגוריתמים עצמאיים או גרסאות אופטימיזציה של אותו אלגוריתם.** הדבר דורש ביקורת סמנטית ואנליזת תלות מלאה.

בדיקת v132 סיווגה את הכותרת כ־`HEADER_ELSEWHERE_HASH_VERIFIED_INCLUDE_PATH_UNVERIFIED`. v133 סגרה **רק את השאלה הסטטית**: שני תסריטי הבנייה כוללים במפורש `-I"$ROOT/prototype/src"`; לא הוכח שדגל זה שימש בהרצה היסטורית מסוימת.

## 3. כללי אי־הסמכה שנשמרו

- **אין עדיין קבלות `nm`, `readelf`, קובצי אובייקט או בינארי שבוצע.**
- **אין ראיות מקוריות להרצה של `F(c,t)`** במנגנון v133.
- מספר מנועים עצמאיים שהוסמכו באמצעות שלב זה: **0**.
- שנות Soak מאושרות: **0/10,000**.
- `STOP_NEW_NATIVE_SOAK_DISPATCH` נשאר בתוקף עקב אי־ההתאמה המקורית ב־Issue #29.
- ענף `main` לא שונה.

**שלב QA הבא:** מבקר קריאה בלבד לראיות בינאריות היסטוריות, אם קיימות, עם אימות מקור ביצוע, גיבובי קובצי אובייקט/בינארי, גרסאות כלי הבנייה, תוצאת `nm/readelf` ותיעוד מלא של `ld --wrap`. עד אז מפת ההצהרות היא מפת מקור בלבד.
