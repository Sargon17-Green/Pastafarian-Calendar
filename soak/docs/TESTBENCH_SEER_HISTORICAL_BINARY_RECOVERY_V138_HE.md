# v138 — ביקורת שחזור ראיות של בינארי Seer Next ההיסטורי ללא בנייה חדשה

**תאריך:** 20.11.2026. **ענף QA בלבד:** `qa/soak-seer-binary-recovery-contract-v138`.  
**מטרת הביקורת:** לקבוע מה ידוע *באופן בר־אימות* על פקודות הבנייה, סביבת הריצה והארטיפקט של [ניסוי Seer Next 42423259653](https://github.com/Sargon-17-Green/Pastafarian-Calendar-Seer/actions/runs/42423259653), ומה אינו ניתן להסקה. אין קומפילציה, אין קישור ואין הרצת `F(c,t)`.

## מקורות הראיה וגבולותיהם

| מקור | זהות נעולה | מה הוא מוכיח ומה לא |
|---|---|---|
| קומיט המקור של CI | `4716594fc98fa882a9401455ae56f30895518e8c` | עץ קוד ותסריטי בנייה שאומתו; לא בתי בינארים |
| קומיט המקור הנעול ב־Soak | `866e9bbff59399310416ae25de1b664f9b6c3124` | אותו קוד ותצורה, עם שני קומיטי ארכוב תוצאות `[skip ci]` בלבד |
| יומן Job היסטורי | `128556040187` | ראיות ל־build success, גרסאות חבילות, פלט ותוצאת בדיקות; אינו ארכיון של קובצי ELF |
| ארטיפקט ניסוי | `13595506317` | ZIP שהגיבוב שלו `ed4757a6f9dde8b5302a73413102cba88fef8f02ac70875b309c2ebea9a56bab`; 34 קובצי JSON בלבד |
| שני גיבובים בדוח `ab.json` | baseline `8191de4c…`, candidate `46dded4a…` | מדווחים כחישוב SHA-256 מבתי בינארים בעת הניסוי, אך כיום לא ניתן לחשב אותם מחדש מבתי הבינארים המקוריים |

## שבעת קובצי המקור שנבדקו לקריאות SHA

הביקורת מקבעת את תוכן הקבצים ההיסטוריים באמצעות Git blob SHA-1, ומוודאת מחדש את בתיהם בקריאה בלבד:

| נתיב | Git blob SHA-1 |
|---|---|
| `.github/workflows/seer-next-experiment.yml` | `72c60f4f2c85af5c89ff4c89c48bfe32ddbae0d1` |
| `.github/actions/native-deps/action.yml` | `a34a67ffdb697bf887f1085b55912f31f1ad9663` |
| `.github/actions/node-setup/action.yml` | `5008f501d9e5e84d622ee41b60731db9962fc704` |
| `prototype/scripts/build_engine_service.sh` | `eb6386c8018360858d74140512d2cf55fd3576f7` |
| `research/seer-next/scripts/build_candidate.sh` | `2e238c6406097d04efc20c274e9bb4e91d5bfa3b` |
| `research/seer-next/scripts/build_hybrid.sh` | `399219bf6f8abf21db39efc3b5ae59761a1033ee` |
| `research/seer-next/scripts/compare_candidate.mjs` | `d0b3a9e139c5e41b057eafb2e332914a72a189b1` |

בדיקת `checked_blob` ממקור GitHub נעולה ל־SHA ההיסטורי, ולא לקובצי `main` העכשוויים.

## שלוש פקודות הבנייה — מקור הבינארי

ה־workflow ב־`ubuntu-24.04` מורה לבצע במפורש:

1. `bash prototype/scripts/build_engine_service.sh` → `prototype/build/seer_engine_service`, בסיס הניסוי.
2. `bash research/seer-next/scripts/build_candidate.sh` → `research/seer-next/build/seer_next_engine_service`, מועמד ניסויי.
3. `bash research/seer-next/scripts/build_hybrid.sh` → `research/seer-next/build/seer_next_hybrid_engine_service`, מועמד היברידי.

שלושתם בנויים ב־C++20 עם `-O3 -DNDEBUG -fopenmp -pthread`, `-march=x86-64`, ובמסלול `AVX2` עם `-mavx2`, ספריית GMP וקוד `seer_year_core.cpp` ו־`seer_calendar_core.cpp`. דגלי קישור והרכב קובצי המקור המדויקים נקבעים על ידי שלושת תסריטי ה־Shell הנעולים; **לא** על ידי שחזור משוער של הפקודה.

ב־[Job 128556040187](https://github.com/Sargon-17-Green/Pastafarian-Calendar-Seer/actions/runs/42423259653) שלושת שלבי הבנייה הסתיימו `success`. גם שלב `Verify hybrid and original against independent canonical oracle` הסתיים `success`. זה מוכיח *ריצת בנייה ובדיקות היסטורית מוצלחת*, לא קיומו הנוכחי של הקובץ הבינארי שממנו חושב הגיבוב.

## תצורת הסביבה כפי שנצפתה ביומן המקורי

| רכיב | נתון מן היומן |
|---|---|
| Runner image | Ubuntu 24.04, גרסת תמונה `20261101.360.1` |
| Hosted agent | `20261028.624` |
| חבילת `g++` | `4:13.2.0-7ubuntu1` |
| `libgmp-dev` | `2:6.3.0+dfsg-2ubuntu6.1` |
| `libboost-dev` | `1.83.0.1ubuntu2` |
| `libboost1.83-dev` | `1.83.0-2.1ubuntu3.2` |
| סביבת Node | `24.22.2` |
| דגלי backend | `SEER_RNS_BACKEND=avx2`, `SEER_MARCH=x86-64` |

הנתונים נצפו ביומן ההיסטורי של GitHub. **הם אינם מניפסט גיבובים של כל קובצי תוכנת המערכת, הספריות והלינקר**, ולכן לא ניתן לטעון לבנייה ביט־זהה רק משום שהשמות ומספרי הגרסאות ידועים.

הפעלת הביקורת ב־CI מנסה גם לבצע קריאה מחודשת של יומן Job דרך API של GitHub. אם הקריאה אינה נתמכת/אינה זמינה, הדוח חייב לציין `UNAVAILABLE_OR_UNVERIFIED`; סטטוס ביניים כזה אינו כשל בנייה וגם אינו `log PASS`. לא משחזרים את היומן או את התוצאה מתוך זיכרון.

## השדה `startingCommit` אינו זהות מקור שנבדקה בזמן הריצה

בקובץ `research/seer-next/scripts/compare_candidate.mjs`, השדה:

`startingCommit:'7f1b3098332d891a9ea6cf8e31383d4fd39141cf'`

הוא מחרוזת מקור **קבועה**. זה אינו `git rev-parse HEAD` בזמן הריצה. ה־HEAD האמיתי של ה־workflow הוא `4716594fc98fa882a9401455ae56f30895518e8c`, שאומת דרך ה־API.

לעומת זאת, שני השדות `baselineBinarySHA256` ו־`candidateBinarySHA256` מחושבים בקוד באמצעות `createReadStream(file)` ו־`createHash('sha256')`, אך נשמרו כתוצאת JSON בלבד.

## למה ארכיון הניסוי לא מכיל את הבינארים

ב־workflow ההיסטורי יש שלב `upload-artifact` עם ארכיון `seer-next-native-ab-linux-avx2`. בבלוק `path: |` הוגדרו בדיוק **34 קבצים, כולם עם סיומת `.json` תחת `research/seer-next/results/working/`**. לא הוגדרו קובצי `prototype/build/`, `research/seer-next/build/` או קובצי ELF אחרים.

מכאן שהיעדר בתי ה־baseline, ה־candidate וה־hybrid מארכיון זה נובע ממפרט ההעלאה המקורי. אין ראיה אם אותם קבצים שרדו במקום אחר; אין גישה בנתיב הביקורת הנוכחי למפקד מלא של מאגר המטמונים של GitHub Actions, ולכן **לא נטען שהמטמון ריק**.

## בדיקה משלימה: הענף `cache-data` אינו ארכיון בינארים

נבדק גם העץ המלא של הענף `cache-data` במאגר Seer, HEAD `44c4dba9d075de6420640864a66871abe88eb448`. העץ אינו מקוטע (`truncated=false`) והוא מכיל ארבעה קבצים בלבד: `index.json` ושלושה קובצי `calc/2461365.json`, `calc/2461366.json`, `calc/2461367.json`. אין בו ELF, PE, קובצי אובייקט או תסריטי בנייה.

**חשוב:** הענף `cache-data` הוא נתון מנוהל במאגר Git, **לא** מאגר `GitHub Actions Cache`. הבדיקה שלו אינה מוכיחה דבר לגבי תכולת מאגרי ה־Actions cache, שבדיקתם הישירה עדיין אינה נתמכת כאן.

## תנאי קבלה והמשך עבודה

הביקורת כוללת:
- `soak/control/seer_historical_binary_recovery_v138.json`: חוזה גיבובי מקור, יעדי הבנייה וסביבת ה־runner; פערים מסומנים במפורש.
- `soak/runner/soak_seer_historical_binary_recovery_v138.py`: קריאה בלבד, כולל אפשרות לאימות יומן היסטורי; לא מריץ שום תהליך מקומי.
- `soak/process_tests/test_soak_seer_historical_binary_recovery_v138.py`: 18 בדיקות סינתטיות של כשלי שיוך, שינוי קובצי מקור, זיוף השדה `startingCommit`, הוספת בינארי למפרט JSON ושינוי הרשאות ה־Soak.
- `.github/workflows/soak-seer-binary-recovery-v138.yml`: בדיקת מפקד המקור והוכחת שלב קודם `completed/success`; בודקת את מצב יומן המקור ללא הצגתו כ־PASS אם אינו זמין.

**השלב הבא המותר** הוא לחפש עותק קיים של שלושת קובצי ההרצה במקור ארכיוני מורשה, או להכין חוזה העלאת גיבובים ובינארים עבור *הרצה עתידית מאושרת בנפרד* — בלי להפעילה כעת. הרצה חדשה, גם אם תפיק SHA תואם, אינה תחליף להוכחת פלט `F(c,t)` של 10,000 שנות מקור ללא הסדרת Issue #29.

הגבולות נשארים: `new_compiler_or_linker_calls=0`, `new_original_date_Fct_calls=0`, `scientific_original_10000_years_certified=0`, `independent_algorithms_certified=0`, `soak_dispatch_authorized=false`. הענף `main` ללא שינוי.
