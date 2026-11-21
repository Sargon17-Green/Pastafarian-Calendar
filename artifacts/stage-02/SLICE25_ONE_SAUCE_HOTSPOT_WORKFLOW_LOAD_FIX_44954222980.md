# SQL+தமிழ் Slice25 — תיקון טעינת המקור ב־one-case hotspot workflow

- Project: `PC-BRANCH-SQL-TAMIL`
- Branch: `SQL+தமிழ்`
- Parent/source SHA: `8e29770eee56d184801c2333079b311ff2b38c68`
- Triggering failure: [run 44954222980](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44954222980)
- Job: `136998658814`, `bounded-one-sauce`
- PostgreSQL: 17.12

## ממצאי ההרצה המקורית

ה־run הסתיים `completed/failure`. שלבי checkout, יצירת QA aliases, הפעלת PostgreSQL והעלאת artifact הצליחו. שלב הטעינה נכשל, ושלב ה־Native probe סומן skipped.

ה־artifact המקורי הוא [14726534691](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44954222980/artifacts/14726534691), בגודל 3,910 בתים. SHA-256 שחושב מה־ZIP שהורד: `a509fe6c17827877262e3585981cb90786bb03ccbb137a3ee424afbfca3e0ec0`; הוא תואם ל־GitHub artifact metadata ול־upload-job log. בדיקת ZIP/CRC עברה לכל 8 החברים.

ה־artifact מאשר:
- source locks: 3/3 PASS.
- reversible QA clones: 3/3 PASS.
- source-mutation rejection: PASS.
- PostgreSQL 17.12.
- `load.log`: `schema "pastafari_sql_tamil" does not exist`.
- `SQL_TAMIL_HOT_NATIVE=NOT_EXECUTED`.

## סיבת השורש

ה־workflow בנה את מערך `args` עם 28 קובצי SQL, `sql/00` עד `sql/27`, ורשם את ה־Git blob SHA שלהם — אבל לא העביר את `"${args[@]}"` לפקודת `psql`. בפועל הוא ניסה לטעון רק את `hotspot_aliases.sql` למסד `postgres` הריק. לכן הסכמה לא נוצרה וה־probe כלל לא התחיל.

זו תקלה ב־QA workflow בלבד, לא כשל של פונקציית `sauce`, לא כשל של SQL הייצור, ולא מדידת ביצועים.

הצלבה: workflow קודם באותו ענף, run [44928511225](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44928511225), מעביר את `"${args[@]}"` לאותו `postgres` DB; הלוג שלו מציג `CREATE SCHEMA` וטעינת טיפוסים. אותה תצורת DB היא אפוא הנתיב שכבר שימש בפועל.

## בדיקות נפרדות על אותו SHA

- Stage1: [run 44954222891](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44954222891), job `136998658754`, completed/success. PostgreSQL 17.12; 52/52 normative, 7/7 saved-sum, 3/3 heavy reference, 4/4 production isolation. Artifact [14727980121](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44954222891/artifacts/14727980121), SHA-256 `23c823f335f8ecde542bdb8deaa72976864010aeaa8751715173f6de1480c07a` תואם metadata ו־upload log; ZIP/CRC עבר.
- Canonical Names Lock: [run 44954222915](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44954222915), job `136998658494`, completed/success על אותו SHA.

אלה שערים נפרדים; הם אינם מתקנים או מאשרים את Slice25.

## תיקון workflow

1. להעביר בפועל את כל 28 קובצי `sql/00..27` ל־`psql`, בסדר המספרי, לאותו DB `postgres`.
2. לדרוש 28 קובצים בדיוק ו־56 ארגומנטים `-f/path`.
3. לבדוק במפורש שהסכמה והחתימות `sauce`, `bowl_round`, `stone_value` קיימות לפני טעינת aliases.
4. לטעון את aliases ואת ה־probe לאותו DB.
5. לשמור `production-load.log`, `schema-check.log`, `qa-load.log`, `probe.log` ו־`exits.txt` גם בכשל.
6. לקבל את ה־probe רק עם exit 0, שקילות stone 1/1, שקילות sauce 1/1, ו־46/46 ENTER ו־46/46 EXIT של `bowl_round`.

## גבולות ומצב קבלה

השינוי הוא ב־workflow ובדוח QA בלבד. לא שונו קובצי SQL של הייצור, האלגוריתם או נתוני קלט. ה־probe משווה את ה־clone למימוש המקורי, ולכן אינו oracle מתמטי עצמאי ל־sauce. אין עדיין בסיס לשינוי ביצועים בייצור; oracle עצמאי נדרש לפני שינוי כזה.

ה־commit החדש יפעיל CI טבעי על ה־SHA החדש. אין לבצע dispatch כפול, full 56-job matrix, merge, main או release. Slice25 נשאר NOT ACCEPTED עד לבדיקת run חדש שהושלם, job/log, SHA, artifact המקורי, ZIP SHA-256/CRC, exit codes, equivalence ותזמונים.
