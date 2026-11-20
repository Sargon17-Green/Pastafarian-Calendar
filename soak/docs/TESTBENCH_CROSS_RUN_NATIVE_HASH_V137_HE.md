# v137 — ביקורת קריפטוגרפית חוצת־הרצות לשישה ארכיוני בינארים היסטוריים

**תאריך:** 20.11.2026. **ענף QA בלבד:** `qa/soak-cross-run-native-hash-v137`.  
**מקור:** `Sargon-17-Green/Pastafarian-Calendar-Seer`. אין שינוי ב־`main` ואין הרצת מנועי תאריך מקוריים.

## הכרעה

- [ריצת QA מספר 44799704486](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44799704486) הסתיימה `completed/success`; כל **20/20 בדיקות סינתטיות** עברו. קוד ה־QA אף אימת מחדש את תוצאת v136 ואת ארטיפקט המקור שלה.
- ארטיפקט QA **14659759266**, שם `soak-v137-historical-cross-run-prebuilt-metadata-not-soak`; SHA-256: `cc2c4f6f17c8e5f68c1d12f0950e5307dc894ea9d2ea421fd2933d51739585d3`.
- `CI` של v137 בדק **מטא־נתונים בלבד** של שתי הרצות מוצלחות ו־6 ארכיוני בינארי. הוא **לא** הוריד את בתי הארכיונים, ולכן בדוח ה־CI: `archive_bytes_checked_this_execution=false` ו־`executables_sha256_recomputed_from_real_bytes=0`.
- **בדיקת בתים עצמאית מקומית** על 6 ארכיוני GitHub שהורדו מחדש: כל ה־ZIPים אומתו ב־SHA-256 וב־CRC; נבדקו בתי **24 קובצי הרצה** (ELF/PE), והגיבובים תואמים לרשומות המניפסטים בתוך הארכיונים. אלה **16 גיבובי SHA-256 שונים**, מפני ששמונת הבינארים של Linux x64 ו־ARM64 זהים בהתאמה בין שתי הרצות ההפצה.

**מבחן התאמה לשני הגיבובים ההיסטוריים של Seer Next: 0/24.** אין כאן אימות של שני הבינארים שנבנו בפועל לניסוי Seer Next.

## מקור היסטורי ותכולת הארכיונים

שתי הרצות GitHub של חבילות ההפצה השלימו בהצלחה את פקודותיהן. יש להבחין בין **SHA של הרצת CI** לבין **sourceCommit שבתוך חבילת ההפצה**: הם אינם זהים בשתי ההרצות. לכן אי אפשר לייחס בינארי של הפצה לניסוי המקורי רק משום שהרצת ה־Actions משויכת לאותו HEAD.

| ריצה | HEAD של CI | `sourceCommit` בחבילה | פלטפורמה | Artifact ID | SHA-256 של ZIP |
|---|---|---|---|---|---|
| [42423263952](https://github.com/Sargon-17-Green/Pastafarian-Calendar-Seer/actions/runs/42423263952) | `4716594f...` | `29d18adb...` | Linux x64 | `13594347792` | `ed3c380c3790e22e86e269dc3afc5afb95f2ef8c6b66631834e113557fbc1770` |
| אותה ריצה | `4716594f...` | `29d18adb...` | Windows x64 | `13595475137` | `3d506b322c761d1ad5bc45278a4d12ea1bc56a59d6dcc1780ccd49ae5571cd0b` |
| אותה ריצה | `4716594f...` | `29d18adb...` | Linux ARM64 | `13594263914` | `fd9959a3ad0a756149df70cfb21b5cffa76d8517ebd3a8c962dced08647df2f6` |
| [42421325317](https://github.com/Sargon-17-Green/Pastafarian-Calendar-Seer/actions/runs/42421325317) | `54e1d5d4...` | `5f9a47dc...` | Linux x64 | `13593383581` | `8102f73d1c278c1586f12f6ec9971fe13abe8367dc84ec9193baa27d823d3e77` |
| אותה ריצה | `54e1d5d4...` | `5f9a47dc...` | Windows x64 | `13594370074` | `999f9f616af52b285214698d665bb661e7e3c6245c3f3e60ec38e13d36b8e682` |
| אותה ריצה | `54e1d5d4...` | `5f9a47dc...` | Linux ARM64 | `13593332766` | `44cdc05e7c25c181fd7683e792392c5ebacbfc7c26dc6d49e831a535bef78a9f` |

שתי קבוצות הבינארים שייכות לחבילות הפצה ניידות **v0.2.5**, עם `backend=portable`, ומכילות בכל פלטפורמה ארבע תוכניות: `seer_engine_service`, `seer_year_batch`, `seer_year_locator`, `seer_year_structure` (ב־Windows עם סיומת `.exe`). במניפסטים מופיעים גיבובי הקבצים; הם חושבו מחדש מבתי הקבצים ונמצאו שווים.

הגיבובים המבוקשים מאותו ניסוי Seer Next הם:
- baseline: `8191de4ccd416f159ac8400a7e12920b8464a0066b32651be69d76c54c47ab2b`
- candidate: `46dded4a81d884936fc0bd80a89a32fba6a821cf28c6b55fbfd1a6ff6f253ac8`

כל ארבעת הבינארים ב־Linux x64 וכל ארבעת הבינארים ב־Linux ARM64 **זהים בבתי הקובץ בשתי ריצות ההפצה**, למרות שינוי `sourceCommit` המוצהר במניפסט. לעומת זאת, הגיבובים של ארבעת הבינארים ל־Windows שונים בין הריצות. אין להסיק מן הזהות החלקית שהבינארים נבנו מאותם קובצי מקור, או שסביבת הבנייה הייתה זהה; היא מוכיחה רק זהות בתים של הקבצים שנבדקו.

## ריצת Seer Next סמוכה שנכשלה

התקיימה גם [הרצת הניסוי 42421321405](https://github.com/Sargon-17-Green/Pastafarian-Calendar-Seer/actions/runs/42421321405) בקומיט `54e1d5d4...`: סטטוס `completed/failure`, ומנגנון ה־Artifacts מחזיר כעת רשימה ריקה. ביומן העבודה מופיעים שלבי בנייה מוצלחים של `baseline`, `candidate` ו־`hybrid`, אך ההרצה נכשלה לאחר הבנייה בשלב **Measure real 512 768 1024 1280MiB virtual-space frontier for D workers 1 2 3**. ב־Job אחר נכשלה השוואת מטמון RNS במנגנון שירותים מתמידים. לפיכך **אין לשייך להרצה זו תוצאת PASS כוללת**, וגם לא לייחס לה ארטיפקט בינארי שכיום לא נמצא.

[הרצת Seer Next המוצלחת 42423259653](https://github.com/Sargon-17-Green/Pastafarian-Calendar-Seer/actions/runs/42423259653) בקומיט `4716594f...` העלתה ארטיפקט **תוצאות JSON** (כפי שאומת ב־v135), שאינו מכיל את בתי הבינארים של baseline/candidate. גיבובי הבינארים המופיעים בתוצאות מעידים מה הניסוי דיווח, אך עדיין לא נבדקו מול קובץ בינארי מקורי שנשמר.

## חוזה הבקרה של v137

- `soak/control/seer_cross_run_native_hash_v137.json`: 6 ארכיונים, 24 גיבובי קובצי הרצה, 2 גיבובי יעד נבדלים, 2 קומיטי CI ו־2 ערכי `sourceCommit` פנימיים.
- `soak/runner/soak_seer_cross_run_native_hash_v137.py`: אימות GitHub API לקריאה בלבד, ומתודה אופציונלית לאימות ZIP מבתי הקובץ, עם מגבלת גודל ובדיקת נתיבים/CRC, ללא הרצת שום קובץ מתוך הארכיון.
- `soak/process_tests/test_soak_seer_cross_run_native_hash_v137.py`: 20 בדיקות סינתטיות, בהן FAIL תקין לשינוי SHA, שינוי `sourceCommit`, זיוף מועד/תוצאת CI, מחיקת ארטיפקט, שינוי גיבוב בינארי ומצב ה־Soak.
- `.github/workflows/soak-seer-cross-run-native-v137.yml`: הרשאות `actions: read`, `contents: read`, נעילת v136 וקביעה מפורשת שקריאת מטא־נתונים אינה חישוב גיבובים מבתי ZIP.

אימות הבתים המקומי מפורט ב־`soak-v137-six-native-platforms-binary-hash-receipt.json`, המונה בנפרד את כל 24 הקבצים ו־SHA-256 שלהם, סטטוס CRC, הגיבוב של כל ארכיון, ה־`sourceCommit` הפנימי ותוצאות ההתאמה. SHA-256 של קובץ הדוח המקומי: `1135792eb7a7344daf4b4f052c3755235b86a2e961d2e5189e3c6783940e9e10`. קובץ זה והארכיונים המקוריים כלולים בחבילת הראיות הנפרדת, ללא בלעדיות או שיוך כוזב לבינארי הניסוי.

**גבול מדעי:** המפקד מוגבל לששת ארכיוני הבינארים שנבחרו מתוך שתי הרצות סמוכות. הוא אינו שולל קיומם של קבצים נוספים במקום אחר. הוא אינו מאשר עצמאות אלגוריתמית או תוצאות `F(c,t)`. ההכרעה נשארת **0/10,000 שנות Soak מקוריות, 0 אלגוריתמים עצמאיים מוסמכים, `STOP_NEW_NATIVE_SOAK_DISPATCH` בתוקף בגלל Issue #29**.
