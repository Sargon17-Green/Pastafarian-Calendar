# נקודת שחזור v032 — מיפוי ממירים, שלוש שנים נגזרות תואמות, ושערי soak

**תאריך:** 15.11.2026 · **מאגר:** `Sargon17-Green/Pastafarian-Calendar`.  
**ענף QA לעבודה:** `qa/soak-readiness-20261114`. אין לשנות את `main`, אין להפעיל soak ארוך ואין להוסיף תהליכים קבועים במחשב Windows.

מסמכים קודמים: [CHECKPOINT_STATUS_HE_v029_20261115.md](./CHECKPOINT_STATUS_HE_v029_20261115.md), [ADJACENT_YEAR_NATIVE_BOUNDARIES_v030_HE.md](./ADJACENT_YEAR_NATIVE_BOUNDARIES_v030_HE.md), [ADJACENT_YEAR_FULL_DERIVED_COMPARISON_v031_HE.md](./ADJACENT_YEAR_FULL_DERIVED_COMPARISON_v031_HE.md). דוחות אלה והקוד, לא השיחה, הם מקור השחזור.

## תמונת מצב מדויקת

**פריצת הדרך:** תמלילי שנה שלמים המבוססים על **שני מקורות מקוריים נעולים**, אך מופקים באמצעות **עטיפות שימוש חוזר נגזרות**, התאימו לחלוטין בשלוש שנים שונות, עם יום מעשה קבוע `c=-15055671`.

| שנה | תחום ימים כולל | ימים / שורות תואמות | בדיקות ישירות של המקור, בכל מנוע |
| --- | --- | ---: | ---: |
| 4999 | `[-15061828,-15057703]` | 4,126/4,126 | 6 |
| 5000 | `[-15057702,-15053459]` | 4,244/4,244 | 14 |
| 5001 | `[-15053458,-15047892]` | 5,567/5,567 | 6 |
| **סך הכול** | | **13,937/13,937** | **26 Python + 26 Kotlin** |

שבע עמודות תואמות בכל שורה: `c,t,year,cutlet_id,day_in_cutlet,month_id,day_in_month`; **97,559 ערכים תואמים** בשלוש השנים. **אפס הבדלים**. שתי השנים החדשות שונות באורכן מאוד זו מזו ומשנת 5000, כך שהשיטה אינה מניחה אורך שנה קבוע.

**הסטטוס המקצועי המדויק:**
- `DERIVED_FULL_YEAR_PAIR_MATCHED = 3` (תמלילי שתי עטיפות נגזרות שהושוו על כל ימי השנה).
- `ORIGINAL_UNCHANGED_FULL_YEAR_SOAK_PASSES = 0` (לא בוצעו 13,937 קריאות Native `F(c,t)` נפרדות בשני המקורות).
- `ORIGINAL_NATIVE_SAMPLE_MATCHES = 26 per engine`, כולן התאימו.
- `CANONICAL_ORACLE_CERTIFIED = false`; `ALGORITHMIC_INDEPENDENCE_CERTIFIED = false`.
- `SOAK_10000_YEARS_STARTED = false`; `WINDOWS_NEW_WORKLOADS = 0`; `MAIN_MUTATIONS = 0`.

## המקורות המקוריים ושערי הבדיקות

**Python+Türkçe reference/test:** קומיט `0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4`, מקור `tests/normative_reference.py`, SHA-256 `75d56765b45892940326f67bd85a2c7c9874c01e43b49ee3553c9f6192d94378`.  
**Kotlin+Cymraeg production:** קומיט `0c703446d8a3b7435698bd16402ac5fa30e461c9`, קוד `src/main/kotlin/pastafari/*.kt`, גשר מקור `soak/Post55ProductionDateBridge.kt`. שני המקורות ננעלו **ללא שינוי** לאורך הניסויים.

1. **v028** — [CI 43689273405](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43689273405), שנת 5000: תמליל מלא 4,244 ימים ב־Python וב־Kotlin נגזרים, 14 תאריכים נבדקו מול כל מקור Native מקורי (בדיקות v025/v026). כל השורות התאימו.
2. **v030** — [CI 43749803490](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43749803490): גבולות שלוש השנים 4999/5000/5001 מ־Python ו־Kotlin המקוריים; 27/27 שדות זהים, הקאנון אינו מוכח מכך. רשומה: `soak/control/adjacent_three_original_year_boundaries_v030.json`.
3. **v031** — [CI 43750284891](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43750284891): שתי שנים נוספות, 4,126+5,567=9,693 שורות תואמות, עם שש קריאות מקוריות לכל שנה **בכל מנוע**. נבנו שני קובצי Kotlin נפרדים: JAR מקורי לבדיקות `F(c,t)` ו־JAR נגזר להפקת השנה ביעילות. נגזרת Kotlin משתמשת ב־`wholeYearAt` שנוצר אוטומטית מתוך גוף `dayAt` המקורי ונוספה לעותק, לא למקור. כל 48,465 שדות התאריך בשתי השנים התאימו.
4. **בדיקות טוהר, קאנון ומקורות:** [CI 43750579463](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43750579463): 95/95 בדיקות Python PASS, בדיקות JavaScript PASS, SHA-256 למקורות נעולים PASS; `Canonical Names Lock` ב־[43750579459](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43750579459) PASS. בדיקות v032 שנוספו לאחר מכן מחייבות אימות חדש ב־HEAD.

## גיבובים וראיות שאסור לאבד

- תמליל Python שנת 4999: SHA-256 `7908c1edc71db19e63f2275a5f48ed7778fb2c84914c998afc6400daaf761066`.
- תמליל Python שנת 5000: `74742f95e5f11d225d61de9f19406312201a901bebac87f112e704046b96a3e8`.
- תמליל Python שנת 5001: `230f74dda49e79bc3614ddd0009daf09b0195fe1b94a42ee6f03c03d2afee5ca`.
- תמליל Kotlin נגזר שנת 5000: `6fb3778caec959d6fc01e697c31f2f7bf32cae87fc00ac6f9592fc215e1b51b0`.
- תמליל Kotlin נגזר שנים 4999+5001 יחד: `8dc7083698e6dbbf2a49a73752e21ee0254d3d82b33f913ddcb46492f32aab91`.
- Kotlin מקורי, 12 תאריכים במדגם v031: `a4abbbda897d5abfedb70b71a1946aac778ed3b3cfe8d29ab87cf5702bc42a93`.
- ZIP ראיות v031 `adjacent-4999-5001-two-derived-native-sampled-v031`, Artifact ID `14176531043`, SHA-256 `34072cecec12c95e4639ba5dd510aaaed181be074507bcbb1302094f000c7ba4`.
- ZIP ראיות v028 `two-derived-original-source-annual-streams-v028`, Artifact ID `14151792084`, SHA-256 `899234a0fdccb237b32994e1ed2397469e90267576ea996f2c77a0223e40408e`.
- רשומה מצטברת קבועה: `soak/control/three_derived_years_13937_cross_source_v032.json`; בדיקות בקרה: `soak/tests/test_three_derived_years_aggregate_v032.py`.

GitHub Actions artifacts עשויים לפוג אחרי 30 יום. כל הכלים והגיבובים הדרושים לשחזור נשמרים במאגר, אך **קובצי המקור המקוריים חייבים להישאר זמינים בקומיטים הנעולים**.

## זמני ביצוע שנמדדו

- שנת 5000 נגזרת ב־Kotlin: כ־3.28 שניות (ללא קומפילציה).
- שנות 4999+5001 נגזרות ב־Kotlin: 5.77 שניות, RSS בשיא 427,364KiB; 12 קריאות `F(c,t)` מקוריות ב־Kotlin: 22.34 שניות, 393,120KiB.
- שנים 4999+5001 נגזרות ב־Python **כולל 12 בדיקות מקוריות**: 205.70 שניות, RSS בשיא 202,968KiB.
- אלו מדידות מ־GitHub Actions Linux, לא Windows. אין להסיק מהן רשות להפעלת מספר עבודות מקבילות במחשב המשתמש.

## סדר העבודה הבא, ללא צורך בשיחה

1. **לאמת ב־CI על HEAD** את כל בדיקות v032, לרבות `test_three_derived_years_aggregate_v032.py`, ולתקן רק בענף ה־QA.
2. **בדיקת דטרמיניזם ועצמאות מקור:** להשוות היסטוריית פיתוח ושרשרת תלויות של Python ו־Kotlin, לרבות מצבי Cache, השפעות של מנוע Sauce, משאבים, `ProductionMonthWeavingEngine.dayAt` מול `wholeYearAt`. התאמת 13,937 שורות אינה הוכחת עצמאות או נכונות קאנונית.
3. **בדיקת יותר מיום מעשה יחיד:** כל הניסויים המלאים התבצעו עם `c=-15055671`. לבדוק עוד כמה `c` שונים, כולל חיובי ושלילי, גבולות שנה חדשים ונתיבים של מקור/נגזרת; לעולם לא להעתיק את גבולות שנת 5000 לקלט אחר אוטומטית.
4. **חוזה תמליל שנה ו־ledger:** מקור לכל קריאה, מזהי engine/commit/source, `derived` מול `original`, סיבוכיות ומדדי צריכה, RAW ו־normalized ללא דריסה, SHA, הפסקה בהפרש הראשון, תור איטיים עם שני workers לכל היותר, resume בטוח לאחר קריסה.
5. **Windows:** במדידה האחרונה היו כ־1.06GiB RAM פנויים בלבד, ולכן לא הורצה בו אף הרצת ממיר נוספת. לפני הרצה חדשה לבצע preflight עדכני, Job Object עם אכיפת CPU/RAM על תהליך אמיתי ולא רק readback, דיסק פנוי וניקיון לפי `WINDOWS-EXEC-PACK/3.0`. אין watchdog, אין שינוי קבוע, אין סגירת תוכנות המשתמש ללא אישור.

### קובצי המימוש להמשך

- `soak/experiments/python_adjacent_annual_reuse_v031.py`
- `soak/experiments/AdjacentKotlinDerivedAnnualBridge_v031.kt`
- `soak/experiments/derive_kotlin_annual_stream_v028.py`
- `soak/runner/compare_adjacent_derived_years_v031.py`
- `soak/runner/compare_adjacent_original_bounds_v030.py`
- `.github/workflows/soak-adjacent-original-year-bounds-v030.yml`
- `.github/workflows/soak-two-adjacent-derived-years-v031.yml`

**חוזה סיום:** `three_derived_years_pass=3`, `original_native_full_years_pass=0`, `full_10000_year_soak_started=false`, `main_unchanged=true`. המשך העבודה חייב להסתמך על המאגר ועל הראיות, לא על השיחה.
