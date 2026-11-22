# בדיקת מדיניות וקבלת פרוטוקול Stage41 — v12

## תחולה והכרעה

זהו מסמך QA והמלצה בלבד. הוא אינו משנה את `tests/stage41_remote_seventeen.py`, את `run_stage41_remote_seventeen.sh`, את ה־GPR, את ה־observer או את מדיניות הייצור. אין כאן פתיחת Stage42, אין הרצת `Calendar_Date`, אין full-F ואין Soak. `Issue #29` נשאר פתוח ו־`STOP_NEW_NATIVE_SOAK_DISPATCH=true`.

## ממצאי v9 — 18 נקודות העיוורון

ה־18 הן שמונה החלפות homoglyph של תו במזהה `STAGE41_NATIVE_PAIR`, כל אחת ב־stdout וב־stderr, ועוד שתי הזרקות U+034F:

| תו לטיני מוחלף | תו מתחזה | קוד Unicode | מקרים |
|---|---|---:|---:|
| A | Greek Alpha | U+0391 | stdout, stderr |
| T | Cyrillic Te | U+0422 | stdout, stderr |
| E | Greek Epsilon | U+0395 | stdout, stderr |
| V | Cyrillic Izhitsa | U+0474 | stdout, stderr |
| N | Greek Nu | U+039D | stdout, stderr |
| I | Cyrillic Palochka | U+04C0 | stdout, stderr |
| I | Greek Iota | U+0399 | stdout, stderr |
| S | Cyrillic Dze | U+0405 | stdout, stderr |
| — | COMBINING GRAPHEME JOINER בתוך `STAGE41_NATIVE_PAIR` | U+034F | stdout, stderr |

סך הכול: 16 החלפות homoglyph ועוד שני מופעי CGJ = **18**. v9 דיווח שה־parser ההיסטורי קיבל את כל 16 ההזרקות הלא־ממופות; מודל v11 דחה את כל 18.

## מה הקוד החי עושה בפועל

ב־HEAD הבסיס `1160096aa847c54cbef27c232771ce1549d7ba8f`:

1. `tests/stage41_remote_seventeen.py` קורא את קובץ הלוג כטקסט UTF‑8, באמצעות `read_text(...).splitlines()`.
2. `compare_lines` מפעיל `line.strip().split()`. לכן רווחים מסוגים שונים מנורמלים למפרידים, שורות ריקות מדולגות, ושורות שאינן מזהה זוג או marker אינן נדחות אוטומטית.
3. זיהוי הזוגות נעשה לפי `parts[0] == "STAGE41_NATIVE_PAIR"`; marker מזוהה לפי `startswith` ולאחר מכן חיבור הטוקנים.
4. `run_stage41_remote_seventeen.sh` מפעיל את ה־observer עם `> "$log_file" 2>&1`. כלומר stdout ו־stderr מתמזגים לפני הפרסר. אי אפשר להוכיח `stderr == b""` או לשייך אזהרה לזרם המקורי.

מכאן שהמדיניות הקיימת היא parser סמנטי מבוסס־טוקנים, לא פרוטוקול byte-exact. בדיקות v11 אינן משנות זאת: הן הוכיחו דחייה במודל QA נפרד בלבד.

## מדיניות admission מומלצת

לפרוטוקול המכונה המצומצם של Stage41 מומלץ **ASCII byte-exact** ולא הרחבת מפת confusables:

- `return_code == 0`.
- `stderr == b""`.
- `stdout` שווה byte-for-byte ל־26 השורות הקנוניות: 25 זוגות row-major ושורת marker יחידה, עם LF סופי יחיד.
- המספרים, הסדר, המפרידים וה־marker נגזרים מה־oracle העצמאי ומפורמט ה־observer שנצפה; אין `strip`, `split` מנרמל או המרת Unicode.
- כל byte נוסף או שונה — לרבות BOM, CRLF, NUL, ANSI, whitespace חלופי, ספרות Unicode, homoglyph או CGJ — גורם לדחייה.
- build stdout/stderr נשמרים בנפרד ואינם חלק מפרוטוקול ה־observer.

אין לבצע Unicode normalization, אין להסיר תווים בלתי נראים ואין למפות homoglyphs. אין צורך לקבל טקסט חופשי בערוץ הזה: כל byte חוקי מוגדר מראש. זו מדיניות לפרוטוקול Stage41 בלבד, לא טענה למימוש UTS #39 או להגנה כללית מפני כל התקפות Unicode.

**שער אישור:** ההמלצה אינה מיושמת. שינוי parser/runner בייצור דורש הכרעה מפורשת על חוזה admission; עד אז משאירים את הקוד החי ללא שינוי.

## תיקון דיוק קטן בחוזה v11

ה־byte fixture של v11 תואם ל־`native_stdout_excerpt_stage41.txt`. עם זאת, ההסבר שכל הרווחים הכפולים נובעים מ־Ada `'Image` רחב מדי: ה־observer קורא `Positive'Image` רק עבור cutlet ו־month, ואילו year וימי החודש עוברים דרך `To_String`. יש לשמר את ה־fixture שנצפה, אך לא לייחס את כל הרווחים ל־`'Image` בלי תצפית GNAT חיה. v12 אינו משנה את הפורמט.

## הבחנה בין הראיות

- v171: Stage03 ו־Stage05 עברו Native על QA branch נפרד, עם 1,471 ו־1,465 assertions; אפס `Calendar_Date`. זה אינו Stage41 build/link proof.
- HEAD הנוכחי 1160096: run `44957820035` הסתיים SUCCESS ב־`verify`; 42 jobs אחרים דולגו. אין ממנו Stage41 build.
- v11: 164 מקרי gate במודל, 18/18 blind spots נדחו, ו־5 בדיקות helper עברו. ה־baseline של build/process היה סינתטי; helper בדק את גודל הפלט לאחר capture ולא תוך כדי הזרמה.
- v12: משפר את helper ללכידה זורמת עם תקרת bytes תוך כדי קריאה ומכין workflow compile-only ל־Stage41. רק artifact של run שהושלם, עם linker trace ומניפסט תקין, יוכל להיחשב ראיית build. גם אז אין בכך Native PASS או קבלת Stage41.

## גבולות מפורשים

- workflow v12 בונה את ה־observer בלבד; הוא **אינו מפעיל אותו**.
- אין קריאה ל־`Calendar_Date`, אין full-F, אין Soak.
- כל 42 משימות ה־native הוותיקות נשארות `if: ${{ false }}`.
- אין שינוי ב־`main`, אין merge ואין שינוי parser/production.