# נקודת שחזור v035 — נבדק גם שינוי יום המעשה

**תאריך:** 15.11.2026 · **מאגר:** `Sargon17-Green/Pastafarian-Calendar` · **ענף:** `qa/soak-readiness-20261114`.  
**אסור להמיר עותק נגזר למנוע מקור עצמאי; אסור להכריז על PASS של שנת soak מקורית; `main` נשמר ללא שינוי.**

## נקודת המוצא

כל העבודות הקודמות, לרבות סקירת המקורות, מנגנון ה־ledger ושתי סביבות העטיפות, נמצאות ב־[CHECKPOINT_STATUS_HE_v032_20261115.md](./CHECKPOINT_STATUS_HE_v032_20261115.md). בסוף v032 התאימו 13,937 ימים נגזרים בשלוש שנות יעד רצופות, 4999/5000/5001, עם **אותו יום מעשה קבוע** `c=-15055671`. בכל מנוע בוצעו 26 קריאות `F(c,t)` מקוריות מדגמיות. שנות soak מקוריות מאומתות: 0.

## v033 — שינוי c משנה מבנה השנה

[GitHub Actions 43753574115](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43753574115) קיבלה את קוד המקור Python+Türkçe בקומיט `0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4` ואת קוד הייצור Kotlin+Cymraeg בקומיט `0c703446d8a3b7435698bd16402ac5fa30e461c9`. היא חישבה בכל מקור את `year5000(c)` עבור שלושה ימי מעשה חדשים:

| c | אינדקס פתיחה | אינדקס סגירה | שער פתיחה | שער סגירה | ימים |
| ---: | ---: | ---: | ---: | ---: | ---: |
| −15,055,672 | −1 | 5 | −15,056,174 | −15,052,605 | 3,569 |
| −15,055,670 | −9 | 1 | −15,060,486 | −15,055,326 | 5,160 |
| −15,054,671 | −3 | 5 | −15,056,944 | −15,052,605 | 4,339 |

**כל 27 שדות הגבול התאימו בין המקורות**, `first_mismatch=null`; שלושת מבני השנה שונים. לשם השוואה, `c=-15055671` מחזיר 4,244 ימים. מכאן **חובה** לכלול את `c` בזהות מטמון מבנה השנה; `(year)` לבדו אינו מפתח תקין. הזהות המלאה צריכה לכלול גם `engine_id`, גיבוב המקור, וגרסת החוזה, למניעת ערבוב בין ממירים.

מקורות:
- `soak/experiments/original_python_calculation_variation_v033.py`
- `soak/experiments/OriginalKotlinCalculationVariation_v033.kt`
- `soak/runner/compare_original_calculation_variation_v033.py`
- `soak/control/alternate_calculation_original_year5000_v033.json`
- `soak/docs/ORIGINAL_CALCULATION_VARIATION_v033_HE.md`

ראיות: Artifact `14177915072` (ZIP SHA-256 `5edf3c7ef8c5d5df10986c4f171afe8555d66c266e83ae2f833b47afbf399e9d`). גיבובי פלטי Native: Python `e60ac75370c0f9822d4b85f9ff85a1a5714a334af247a1d4f8c8fe0d879e2d48`, Kotlin `be5484a45d0c340ee191d429b51f384d487e4d954e685b377f5a86c25956619b`.

**מגבלת מקור:** `Post55ProductionDateBridge` של Kotlin המקורי מוגבל ליום מעשה במרחק `7,883,118` ימים מנקודת הבסיס `−15,055,671`. לכן `c=0` אינו נתמך במקור הזה; אין לשנות את המקור הנעול ולספור את השינוי כאותו מנוע מקורי.

## v034 — שנה נגזרת מלאה עבור יום מעשה אחר

[GitHub Actions 43754101905](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43754101905) הסתיימה ב־**SUCCESS**, והוכיחה מעבר למדגם הגבולות:

- יום מעשה `c=-15055672`, שנת 5000, תחום כולל `[-15056173,-15052605]`, 3,569 ימים.
- מקור Python המקורי בנה `YearStructure` פעם אחת, והעטיפה `python_annual_alternate_calculation_v034.py` הפיקה **3,569 שורות נגזרות**.
- נוצר עותק Kotlin נגזר באמצעות `derive_kotlin_annual_stream_v028.py` המשמר את קוד הייצור המקורי ללא שינוי ומוסיף `wholeYearAt` לעותק בלבד. המעטפת `AlternateCalculationKotlinDerivedAnnual_v034.kt` הפיקה **3,569 שורות נגזרות**.
- **כל 3,569 שורות התאריך התאימו בדיוק בשבע עמודות**, סך הכול **24,983 ערכים**, `first_mismatch=null`.
- **7/7 קריאות `F(c,t)` של Python המקורי** ו־**7/7 קריאות `F(c,t)` של Kotlin המקורי** תאמו לשורות התמלילים. היעדים: `-15056173`, `-15056172`, `-15054984`, `-15055672`, `-15053794`, `-15052606`, `-15052605`.
- בשונה מניסוי c המקורי, גם יום המעשה וגם מבנה השנה השתנו; אין טענה ששמות, השזירה או המבנה שוחזרו ממטמון של c אחר.

קוד:
- `soak/experiments/python_annual_alternate_calculation_v034.py`
- `soak/experiments/AlternateCalculationKotlinDerivedAnnual_v034.kt`
- `soak/runner/compare_annual_alternate_calculation_v034.py`
- `soak/tests/test_alternate_calculation_year_v034.py`
- `soak/control/alternate_c_3569_derived_full_year_v034.json`
- `soak/tests/test_alternate_c_cumulative_no_mixing_v035.py`

גיבוב SHA-256 של שני תמלילי TSV הנגזרים (זהים ברמת הבייט): `8f86001ded71f2cf0d7948553253f01f93215a465f3693a59556c7c700097cf7`. גיבוב שבע קריאות Kotlin מקוריות: `87c19e9ec96156cfe493d55af178999d5ca8896166c9c5acb3d96b2f14d82b14`.

Artifact `14176968285` בשם `alternate-calculation-c-minus15055672-derived-year-v034`; גיבוב ZIP `064bf054b17412bc2c746ac850a60bc8a72efafdcff0a32f0c8703ad0c8fad86`.

### ביצועים נצפים ב־Linux GitHub Actions

| פעולה | זמן קיר | שיא RSS |
| --- | ---: | ---: |
| Python נגזר + 7 קריאות Python מקוריות | 48.65 שניות | 88,620KiB |
| Kotlin מקורי, 7 קריאות `F(c,t)` | 7.27 שניות | 346,172KiB |
| Kotlin נגזר, שנת יעד 3,569 ימים | 1.90 שניות | 319,328KiB |
| קומפילציית Kotlin המקורי | 19.76 שניות | 581,780KiB |
| קומפילציית Kotlin הנגזר | 18.69 שניות | 586,504KiB |

אלו עומסים שונים; אין להסיק מהשוואת זמני שבע קריאות מקוריות לזמן 3,569 שורות נגזרות מספר מדויק של שיפור מהירות. אלו גם מדידות Linux CI, לא אישור הרצה ב־Windows.

## מצב מצטבר, בלי ניפוח הצלחה

| מאפיין | מעמד נכון |
| --- | --- |
| שלוש שנות יעד בהינתן `c=-15055671` | 13,937 שורות נגזרות תואמות |
| שנת 5000 בהינתן `c=-15055672` | 3,569 שורות נגזרות תואמות |
| **סה״כ התאמות תמלילים נגזרים** | **17,506** |
| מדגם `F(c,t)` מקורי ב־Python | **33 תאריכים** |
| מדגם `F(c,t)` מקורי ב־Kotlin | **33 תאריכים** |
| מקוריות אלגוריתמית / אורקל עצמאי | **לא הוסמכו** |
| שנות soak מקוריות מלאות שאומתו | **0** |
| הרצת 10,000 שנים | **לא התחילה** |
| עומס חדש במחשב Windows | **לא בוצע** |
| שינוי ב־main | **לא בוצע** |

## צעדים הבאים

1. לערוך **ביקורת ייעודית של מזהי מטמון ו־ledger**: הרשומות חייבות לקבע `c`, `year`, גבולות, `engine_id`, גיבוב מקור ו־`source_class` מפורש (`original`, `derived`, `reference`). חובה למנוע הסמכה עצמאית באמצעות שני מזהי engine שונים שמצביעים למעשה על אותו אלגוריתם/נגזרת.
2. להרחיב בדיקה לעוד `c` בתוך תחום הגשר המקורי, למשל `-15055670` ו־`-15054671`, עם דוגמאות Native מדגמיות וגבולות מקור נעולים.
3. לבצע ביקורת עצמאית של אי־תלות במצב בין `NormativeCalendar`, מנועי `ProductionYearNavigator`, `ProductionSauceEngine`, `dayAt` ו־`wholeYearAt`. תמלילים זהים לבדם אינם הסמכת אורקל או מקוריות.
4. רק אחר כך לחבר למתזמן `two_lane_scheduler.py`, ל־`recovery_store.py` ולשער משאבי Windows, תוך שמירת עצירה באי־התאמה ראשונה, שני workers לכל היותר, תור איטיים ללא ביטול תהליכים, SHA ולוגים, ללא שינויים קבועים במחשב.
5. לבצע preflight Windows אמיתי בסמוך להרצה; המדידה הישנה (כ־1.06GiB פנוי) חסמה שימוש מקומי, ואין להניח שהיא השתנתה.

**חוזה המשך מחייב:** `derived_year_pairs_matched=4` בהגדרת שנה המתייחסת גם ל־`c`; `original_full_year_soak_passes=0`; `long_soak_started=false`; `main_unchanged=true`. יש להסתמך על הקבצים במאגר, ולא על השיחה.
