# v135 — ביקורת ארכיוני Seer ההיסטוריים וראיות SHA-256 של בינארים

**תאריך:** 20 בנובמבר 2026. **ענף QA:** `qa/soak-seer-native-archive-v135`.

## הכרעת איכות וגבולותיה

ריצת [44744740005](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44744740005) הסתיימה `completed/success`; **16/16 בדיקות סינתטיות עברו**. ארטיפקט QA מספר `14632018291`, SHA-256 של ZIP: `d37766b985265fe45b5cdbebaa70a9ee4f66a8660daf3d7e4bfca817ed23e112`.

כל הרצות QA של v135 נעשו בלא `F(c,t)`, קומפיילר, מקשר או אפליקציית Seer מקורית. ה־CI שבענף ביקורת אימת **מטא־נתונים חיים של GitHub**: קומיט המקור, ריצת CI היסטורית מוצלחת, Job ושלבי בנייה, גיבוב הארכיון לפי GitHub, והשוואת עצי Git מלאים. **הארכיון המקורי לא הורד ב־CI של v135**, ולכן שדה `original_archive_bytes_examined_in_this_execution=false` בפלטו.

בנפרד, הורדתי בסביבת העבודה את שני ארכיוני המקור של הרצת Seer ההיסטורית, חישבתי SHA-256 של ה־ZIP עצמם, בדקתי `testzip()` לכל CRC, בדקתי את שמות הקבצים, פענחתי את כל קובצי ה־JSON, ובניתי מניפסט SHA-256 אישי לכל קובץ תחת `seer-v135-archive-byte-receipt.json`.

## ארכיוני המקור המקוריים

מקור: [Seer Next run 42423259653](https://github.com/Sargon-17-Green/Pastafarian-Calendar-Seer/actions/runs/42423259653), `completed/success`, קומיט `4716594fc98fa882a9401455ae56f30895518e8c`.

| ארטיפקט | ID | SHA-256 של ZIP, נבדק גם מקומית | תוכן |
|---|---:|---|---|
| `seer-next-native-ab-linux-avx2` | 13595506317 | `ed4757a6f9dde8b5302a73413102cba88fef8f02ac70875b309c2ebea9a56bab` | 34 קובצי JSON, יחד 2,120,061 בתים |
| `seer-next-long-lived-rns-cache-roi` | 13595075588 | `d4856aaa5e73b98b6d92f73e10596e4fe7950bbfdcc6c323aee1c89ed02a984c` | 2 קובצי JSON, יחד 24,618 בתים |

שני הארכיונים נשמרו ונגישים כעת. **אין בהם קובץ בינארי מקורי.**

## הגיבובים שנרשמו בניסוי

ב־`ab.json`, שהגיבוב האישי שלו הוא  
`62f2c3f44f0638f56864c4a4f08ebd738f5ba555f2226464f96d03124ada78c7`,
קיימים השדות:

- `baselineBinarySHA256` = `8191de4ccd416f159ac8400a7e12920b8464a0066b32651be69d76c54c47ab2b`
- `candidateBinarySHA256` = `46dded4a81d884936fc0bd80a89a32fba6a821cf28c6b55fbfd1a6ff6f253ac8`

הקובץ `research/seer-next/scripts/compare_candidate.mjs` בקומיט ההיסטורי מכיל שימוש ב־`createReadStream(file)`, `createHash('sha256')`, ובהפקת שני השדות הללו מתוך `await sha256(src)` ו־`await sha256(candidate)`. גיבוב Git של קובץ הסקריפט: `d0b3a9e139c5e41b057eafb2e332914a72a189b1`.

**מעמד מדעי מדויק:** בשלב זה אלה **גיבובים מחושבים המדווחים בארטיפקט בדיקה היסטורי, שהארכיון שלו אומת קריפטוגרפית**. אין העתק של קובצי הבינארים עצמם, ולכן לא ניתן לבחון את בתי הקבצים ולחשב SHA-256 בלתי תלוי כיום. בנוסף, שני הגיבובים מתייחסים ל־baseline ול־candidate של הניסוי; אין כאן גיבוב בינארי נפרד ל־hybrid, ואין לראות בהם הוכחת עצמאות של שני אלגוריתמים.

## שקילות של מקור Seer בין הקומיטים

הרצת CI ההיסטורית השתמשה בקומיט `4716594`. קומיט המקור הנעול `866e9bb` נוצר **שני קומיטים לאחריו**, ושני קומיטי הביניים מסומנים `[skip ci]` ומוסיפים ארכיוני תוצאות בלבד.

השוואת Git מלאה העלתה:
- 1,177 קבצים משותפים בעלי גיבוב, מצב (mode) ונתיב זהים.
- 561 קובצים שמחוץ ל־`research/seer-next/results/` זהים לחלוטין.
- 38 קבצים נוספים בקומיט המאוחר, כולם תחת תיקיית התוצאות.
- **אפס קובצים משותפים בעלי תוכן שונה**.

לכן נבחן אותו עץ קוד ותצורה של המאגר — אך השוואה זו אינה מתעדת ספריות חיצוניות, גרסאות קומפיילר, הסביבה החיה, הבינארים שהופקו או נתוני ביצוע של `F(c,t)` ברמת המבחן המקורי.

## ממצאי דיוק מתוך ארכיון הניסוי

הקובץ `full-year-512.json` מכיל `fullYearComparisons=6`, `underCapSuccesses=6` ו־`allUncappedFullRepliesEqual=true`. הקובץ `full-year-warm-cold.json` מדווח `completeFullJsonParity=true`.

אלו תוצאות של מחקר Seer Next ותיעוד השוואותיו. הן **אינן** עדות ששש שנות מקור נבדקו על ידי כל מנוע עצמאי או שבוצעה בדיקת Soak רציפה ל־10,000 שנות מקור. להשלמה נדרשת עדיין ראיה על המנוע המדויק, קלט `F(c,t)`, stdout, כל ימי השנה, השוואות עצמאיות, וגיבובי בינארי או תיעוד ריצה קביל.

## ארטיפקטי v135 וקבלה

- `soak/control/seer_native_archive_v135.json`: חוזה נעול של SHA, שני הגיבובים שהוקלטו, שנתונים, ותנאי אי־קבלה.
- `soak/runner/soak_seer_native_archive_v135.py`: מנגנון קריאה בלבד עם מסלול אימות ZIP **אופציונלי**; בהרצת CI היה `archive=None`.
- `soak/process_tests/test_soak_seer_native_archive_v135.py`: 16 בדיקות סינתטיות, לרבות שינוי SHA, ארטיפקט לא זמין, שינוי מקור, תור CI, ושינוי שדה הסמכת Soak.
- `.github/workflows/soak-seer-native-archive-v135.yml`: אימות CI חי ומשמעת אי־הרצת מקור.

הגבולות נשמרו: `original_full_years_certified=0`, `independent_algorithms_certified=0`, `soak_dispatch_authorized=false`.

**Issue #29** ו־`STOP_NEW_NATIVE_SOAK_DISPATCH` נשארים בתוקף. `main` לא שונה.
