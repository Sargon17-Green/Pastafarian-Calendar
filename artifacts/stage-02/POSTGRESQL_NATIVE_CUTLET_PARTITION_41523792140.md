# SQL+தமிழ் — Stage 2 Slice 18: דו"ח קבלת PostgreSQL Native

תאריך אימות: 2026-11-03 (שעון ישראל). **Scope: Slice18 בלבד; אין קבלה של Stage2 כולו או של תאריך בעל חמישה רכיבים.**

## זהות נעולה והכרעה

- מאגר: `Sargon17-Green/Pastafarian-Calendar`; ענף: `SQL+தமிழ்`.
- SHA שנבדק: `513c252d5654ec9f7274283aa88d9fcf8d78cca5` (אומת גם כ־HEAD לפני יצירת דו"ח זה).
- ריצת Actions: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41523792140 ; run 41523792140, attempt 1, completed/success.
- כל 14 jobs הסתיימו completed/success, ללא שגיאת runtime, ביטול או timeout.
- סביבת Native: PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2), אומתה בקובצי `versions.txt` בארכיונים.
- מקור הייצור של Slice18 לא השתנה בתיקון sharding; תוקנו בדיקות ו־workflow ב־`513c252d5654ec9f7274283aa88d9fcf8d78cca5`.

## שערי הבדיקות שהורצו

| קבוצת בדיקה | Jobs | בדיקות שעברו | ראיות |
| --- | ---: | ---: | --- |
| Native Golden — 8 קבוצות `g6s1..g9s3` | 8 | 32/32 | `native_golden_4_of_4=1` בכל קבוצה, ארבע תוצאות `t` מפורשות |
| Native גבול/שלילה — `negative` | 1 | 21/21 | `native_boundary_21_of_21=1` ו־21 תוצאות `t` |
| Differential — g6,g7,g8,g9 | 4 | 8/8 | `differential_2_of_2=1` בכל קבוצה, מערכים מלאים מול oracle נפרד |
| בידוד production | 1 | 4/4 | `isolation_4_of_4=1` |
| **סך הכול** | **14/14** | **65/65** | **completed/success, ארכיונים ויומנים** |

## ארכיוני הראיות — גיבובים מקוריים

כל 14 ארכיוני ה־ZIP הורדו מתוך Actions. SHA-256 חושב באופן עצמאי על הבתים המקוריים והשווה גם ל־`digest` של GitHub וגם לגיבוב שבלוג העלאת ה־artifact. בכל 14 הארכיונים `ZipFile.testzip()` החזיר הצלחה (CRC תקין); הקבצים נקראו בפועל.

| עבודה | Artifact ID | גודל בבתים | SHA-256 של ZIP | ספירה | CRC |
| --- | ---: | ---: | --- | --- | --- |
| native/g6s1 | 13180203993 | 5015 | `ae7f94105b84410ede762f4c5f1251a42fc57ec680c13d452b4c833d5d75e82d` | 4/4 | PASS |
| native/g6s3 | 13181355963 | 5015 | `8a1a92f89cf28a74d54437d332b9799bbd1a34ffd43d5993b52ca300f1978e8a` | 4/4 | PASS |
| native/g7s1 | 13179764990 | 5015 | `5837e894e4659674e2a406e90a75d10e759b25ec3b2916784cfecb2daf203a81` | 4/4 | PASS |
| native/g7s3 | 13178864430 | 5015 | `7b4d25dee12c7cffed7c6e549cf70c7ee78768498283a76cf148ebe9935516ff` | 4/4 | PASS |
| native/g8s1 | 13181755525 | 5014 | `333f78e1ae4645c71ceff933a6057b5835e71387cf8ce97562604fa9e9348917` | 4/4 | PASS |
| native/g8s3 | 13179908668 | 5016 | `cec868614f6145e5de90e30f2c9a3f73c028842e418919e641c7b64b107dcc93` | 4/4 | PASS |
| native/g9s1 | 13180208231 | 5014 | `54e07b2743bea856e86b11bb1e871bc0bc1ff48ba267737213bcac252de4b2c0` | 4/4 | PASS |
| native/g9s3 | 13179193762 | 5014 | `a96ce155b29a6b523d1af034e89b2343ba6febceb49dc78802d76909bd72c284` | 4/4 | PASS |
| native/negative | 13181035585 | 5177 | `75936ab870eda5e028aef652ff380bfe9cb5d67017247f46d9e3564a84baff59` | 21/21 | PASS |
| differential/g6 | 13181355721 | 1968 | `f47939d6ef4a261cf9cca22b85ef2a7df61f796872db50df9c8355469af141a4` | 2/2 | PASS |
| differential/g7 | 13179897146 | 1986 | `5cf42d889cf54d9eabbfa9f05a2e3a939092a4d1bb4abc32d0ba11aed084b36a` | 2/2 | PASS |
| differential/g8 | 13179048876 | 1971 | `b0eef0e1c4191c8f6adcc05ed1a8ff386462e78643cd2d40c3e6bf0a57c6744d` | 2/2 | PASS |
| differential/g9 | 13180089139 | 1984 | `ed42d8dbe69c839165accad8f660712f9e3607093ec51516615f9a0fb9e873aa` | 2/2 | PASS |
| isolation/isolation | 13178488282 | 547 | `7a9e7bf0025c19b716045ba7f83f05418d8c02d3eb4ce382dadad4bcad6394bf` | 4/4 | PASS |

## אימות תוכן SQL שנוצר בפועל

- תשעת ארכיוני Native (8 Golden ועוד גבול/שלילה) מכילים `goldens.sql`; SHA-256 של בתיו הוא `d836c628eef4836d5de29475c8c53cd466acb38fd8d8c79cbdf21cbda7adb009` בכל התשע, ותואם בכל פעם ל־`goldens-sha256.txt`.
- ארבעת `differential_case.sql` אומתו עצמאית מול `case_sha256.txt`:
  - g6: `e4a52b51eca25df9c006e94215ed0a5521c519a2b4120fa447b23f1c69d30eba`
  - g7: `671518e39f8d8adb6edc63a5033f91ac57af475b22f82954d9c5be8232391365`
  - g8: `5e41e698d67989bb8c62f875d35bb30271a96d02108cf2fd652169076b8520cf`
  - g9: `33a59c4d1fbf98b19eaa1a8b6e3b561e4b0e85a0481bd7eb82a991f62b900b20`
- כל קובצי הגרסה הזמינים בארכיונים נושאים את ה־Git SHA שנבדק. ספירות העבר נבדקו מהלוגים ומקובצי הפלט שהורדו, ולא מהגדרת ה־YAML בלבד.

## מסקנה

**Slice18 ACCEPTED** לפי חוזה `SLICE_18_CUTLET_PARTITION_CONTRACT.md`, תחת התחום והדוגמאות שהורצו. מבחן CI קודם על אותו רכיב נכשל בשל statement timeout לפני הספירה; הצלחת השבירה לקבוצות כאן אינה ראיה לפגם מספרי קודם. אין לטעון נכונות אוניברסלית לקלט לא־תחום או להשלמת התאריך כולו.

המשך: חוזה Slice19 העצמאי עבור `choose_cutlet_names` לפי המקור הנורמטיבי שבאותו ענף. אין מיזוג ל־main, פרסום או rerun של Slice18.
