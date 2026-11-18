# v104 — מפקד ממירי המקור, ראיות אי־התאמה, ושערי קבלה נפרדים

**תאריך:** 18.11.2026. **ענף QA:** `qa/soak-readiness-20261114`. אין לשנות את `main`.

## 1. בסיס המפקד וזהות הנתונים

המפקד שממנו נגזר הדוח: `pastafarian_converter_inventory_v21_20261114.json`, SHA-256 מדויק `8c2729d1a3780cc3b961455646b904a1028c092ae9c5bb8bedaad92d25acf410`, 207,550 בתים, מתאריך 14.11.2026 (Library של המשתמש). מפתחות המקור: `reference_converters`, `previously_omitted_language_branches`, `previously_catalogued_production_candidates`, `new_seer_next_run_variants`.

| קטגוריית מפקד | מספר שורות | משמעות |
|---|---:|---|
| רשומות reference | 58 | מקורות שזוהו, לא 58 ממירים שעברו soak |
| שורות מיון לשוניות נוספות | 10 | כולל מימושים חסרים או Native לא מוכח |
| מועמדי production | 20 | חופפים בחלקם ל־reference ולמנועים ראשיים |
| וריאנטים של Seer | 3 | וריאנט אריזה/הרצה אינו בהכרח אלגוריתם עצמאי |
| **סה״כ שורות** | **91** | **לא 91 מנועים בלתי־תלויים** |

במפקד `distinct_language_branches=66`; `total_owned_repositories=9`. גם נתונים אלה אינם מדד להצלחות Native. רשומות `duplicate_and_wrapper_proofs_v11` כוללות **11** ראיות של העתקת Git blob, unity wrapper, bundle, service adapter, תוכנית Interpreter כללית וכו'. יש לבצע סגירת תלות מלאה לפני קביעת מספר הממירים הבלתי־תלויים; אין להשמיט מקורות לא מוכנים משורת התוצאה הסופית.

סיווג מקור reference היסטורי: 47/58 רשומות `SOURCE_COMPLETE_NO_DIRECT_E2E_PROOF`; רק חמש רשומות `DIRECT_FULL_DATE_CI_BOUNDED`, ועוד מצבים שונים. זה **צילום 14.11.2026**, לא הכרעת כשירות נוכחית.

## 2. שלושת המקורות שכבר נצפו יחד

| מנוע | מקור שננעל | ראיית מקור מאומתת |
|---|---|---|
| REF-41 Python+Türkçe | `0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4` | שבעה מקטעים בני יומיים עם Kotlin; ועוד ארבעה ימים עם TypeScript |
| PROD-KT-CY Kotlin+Cymraeg | `0c703446d8a3b7435698bd16402ac5fa30e461c9` | 14 ימי יעד עם Python; שניים גם ב־TypeScript |
| TS-MR TypeScript+मराठी | `cc3a613e3b80ba082e5cdb2c7a5d756c7e707df0` | 2 ימים ב־v094, 4 ימים ב־v101 (יום אחד חופף למקטעים שכבר נבדקו) |

[v101 native performance/source run 44392067310](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44392067310) **completed/success**, 4/4 זוגות Python–TypeScript תואמים, 20/20 שדות, ימי יעד `-15055671,-15055658,-15056671,-15054671`. ארכיון המקור `14469537094`, SHA-256 `bb256c2a8e6d599f7f78aa2264129d4ab4ff0dc0c9b8680077149de55b752ff1`, 53 קבצים עם CRC תקין. הזיכרון המרבי שנמדד ב־Linux CI היה כ־121 MiB עבור Python וכ־382 MiB עבור TypeScript; ארבע המדידות נתנו בהתאמה 9.80–9.81 ו־24.53–24.88 שניות. זה מדגם, לא גבול ביצועים לשנים אחרות או התחייבות על Windows.

**17 ימי יעד ייחודיים** עברו השוואת מקור ב־Python עם לפחות מקור נוסף (14 מן הסבב Python/Kotlin ועוד שלושה מן v101); **שני ימים בלבד** עברו התאמה משלושת המנועים. **0 שנות מקור מלאות**, **0/10,000** שנות soak מאושרות. אין תעודת עצמאות אלגוריתמית ואורקל חיצוני.

שער השחזור הבא: [v102 44393873792](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44393873792), ביקורת 53 החברים, פלט מקורי ו־CPU/RSS. אין להכריז PASS ללא completed/log.

## 3. מועמד מקור עם אי־התאמה מספרית מתועדת — Ada+తెలుగు

ראיית GitHub ישירה [run 42390633217](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42390633217), job `128457271704`, 07.11.2026, על commit `29d512ac2b6c74dc20938ae190935ccaf9034b81`: הפעלת `Normative_Oracle.Calendar_Date(c,t)` ב־Ada הדפיסה בשורת מקור עצמאית:

`STAGE14_NATIVE_DATE -15055671 5000 10 503 30 52`

לעומתה, המקורות המקוריים Python ו־TypeScript ב־v101 עבור **בדיוק** `c=t=-15055671` הפיקו `(5000,10,503,20,56)`. בהתאמה לשדות המספריים, אי־ההתאמה הראשונה היא **אינדקס החודש — Ada=30 לעומת Python/TypeScript=20**, ואחריה גם יום החודש (52 לעומת 56). זה אינו הבדל בתרגום שמות.

מ־GitHub `compare_commits` נמצא כי ראש ענף Ada הנוכחי `a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72` מתקדם ב־5 קומיטים בלבד יחסית לריצת המקור הישנה; **אין שינוי בקובצי האלגוריתם** `src/normative_oracle.adb`, `src/month_weaving.adb` או `src/normative_oracle.ads`. SHA-1 Git blobs נבדקו: `923733d4f8face03586aee304640bf7540c28b4c`, `9b02c62dfbc7d8b3b532aba8cd9f1ad0f8b28fef`, `c4588566076798dd394feeab580ebc3d38c09744` בהתאמה.

**המלכודת:** מבחני Ada ההיסטוריים משתמשים ב־`tests/stage14_real_oracle.py`; שם מצהירים על `PROVISIONAL=(5000,10,503,30,52)` עבור יום היסוד. העובדה שתוצאת ה־CI של Ada `success` מוכיחה התאמה של Ada לאותו מודל עזר, **לא** התאמה למנועי Python/TypeScript הנעולים.

מצב מחייב: `HISTORICAL_ORIGINAL_NATIVE_DISAGREEMENT__CURRENT_HEAD_FRESH_CHECK_PENDING`. [v103 current-head one-day discriminator](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44394781099) נפתח להפעלת Ada **פעם אחת בלבד** מול ZIP המקור המקורי של v101; בטרם completed/log אין לזקוף חזרה נוכחית של אי־ההתאמה כעובדה.

**משמעות למשימה:** אם אי־התאמה זו מאושרת גם על המקור הנוכחי ולא יתוקן המימוש המקורי, תנאי `ALL_CONVERTERS_SOAK_PASS` אינו בר־השגה עבור כל הממירים. אין להסיר את Ada מהמפקד ולהציג הצלחה מלאה מלאכותית, ואין לשכתב אותו במתאם.

## 4. WAT ויתר המועמדים

- **WAT+Español**: במפקד v21 מתועדים self-test ו־README שציפו בשנת היסוד לפלט `(5000,10,949,3,54)` ולשערי שנה `[-15058333,-15053411]`, שאינם תואמים למועמד הקאנוני `[-15057703,-15053459]`. אך אין בכך הוכחה שה־HEAD הנוכחי `c0b2f37890030e85b621507caf0c975d34abe161` כבר הורץ מחדש עם חמשת שדות `F(c,t)`. **אין לפסוק על מקור נוכחי מבלי להריצו**.
- **V+አማርኛ**: HEAD שנבדק `a35970c2dbcb0aff6cb8099d29bff9f744ccda`; ראיות Stage31 Native מצומצמות, לא 55 שלבים שהוסמכו. טרם צורף.
- **Fortran+English**: HEAD `49f80e656a17fae1763e981a92648ca39ff97e71`; במפקד `REF-18` ראיית Native E2E תחומה. מועמד ל־F(c,t) מקור נוסף אחרי נעילת גרסה.
- **PHP+Bahasa-Melayu**: HEAD `2f294c03645c37857b87188cd0122eef82f4316e`; במפקד `REF-35` תשעה ימים בלבד עם Oracle מבני שנה משותפים, שלא מוכיחים עצמאות אלגוריתמית.

מבחן מקור שלילי, מקור שלא הושלם וממיר תואם חייבים להופיע בסטטוסים שונים; גם `completed/success` של קאנון שמות או קומפילציה אינם הסמכת מקור תאריכים.

## 5. תשתית ויעד 10,000 השנים

- מתזמן דו־נתיבי v099 עבר **12/12 בדיקות** למניעת פינוי עובד פעיל עקב דו״ח סיום פגום; אין לו עדיין ריצת Native אמיתית ב־Windows.
- בדיקת משאבי Windows v020 מ־14.11.2026 נחסמה: RAM פנוי 1.06 GiB מול שער בטיחות 2 GiB; דיסק פנוי 38.9 GB. אין ראיה חדשה לרמת הזיכרון הנוכחית.
- שמונה ארכיוני מקור ראשונים (7 Python/Kotlin ועוד 1 TypeScript/Python) מגובים בשתי טיוטות Release של GitHub עם הורדה חוזרת; אין Mirror ספק עצמאי. **ארכיון v101 החדש ננעל במניפסט v102, אך טרם נשמר בטיוטת Release**.
- אין עדיין Boundary Oracle עצמאי מאושר ל־10,000 שנים, אין הוכחת אי־תלות אלגוריתמית בין כל מנועי המפקד, ולא בוצעה שנת מקור מלאה.

**המשך:** ראשית להכריע v102/v103 על סמך completed/log. לאחר מכן לבצע inventory freeze בעל מזהי מקור ויחסי כפילות, להעמיד את כל המקורות שאינם תואמים/שאינם ניתנים לבנייה בדוח BLOCKED/FAIL עצמאי, לבנות Windows native pilot עם שער משאבים חדש, ורק אז שנת מקור מלאה. אין להקנות אישור של 10,000 שנים לפני כל השערים.

**סמן חידוש:** `PASTAFARI_SOAK | CHECKPOINT=v104 | V101=4_OF_4_SOURCE_MATCH | UNIQUE_SOURCE_TARGETS=17 | TRIPLE_MATCHED_DAYS=2 | V102=QUEUED_NOT_ACCEPTED | V103=QUEUED_NOT_ACCEPTED | HISTORICAL_ADA_NUMERIC_DIVERGENCE=DOCUMENTED | FULL_SOURCE_YEARS=0 | 10000_CREDIT=0 | NO_MAIN=true`.
