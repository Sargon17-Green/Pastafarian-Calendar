# Dart+עברית — Stage 2 / PRODUCTION07: שערי הפולפטים

PROJECT_ID: PC-BRANCH-DART-HEBREW
BRANCH: Dart+עברית
STAGE: 2
SLICE: PRODUCTION07
PRECONDITION: PRODUCTION06 accepted on bb95dbcba7a9c7b37e0cd77b0a0865c3f73ba5e2, run 41222395434 completed/success, 9/9 jobs, 384876 assertions; Stage2 remains open.
NORMATIVE_SOURCE: Pastafarian-Calendar main README §O, Git blob 74c424b44eadd4ece3f29072ddbf873236557604.

## קלט ופלט

- קלט signedOrdinal הוא BigInt שונה מאפס. +n מחשב את הזוג (F,F+n), ו־-n את הזוג (F,F-n), כאשר F הוא foundationDay.
- gapFor מריץ את המסלול E–K לזוג החתום, ושואל קערה 1, חותם 1, עם בחירה שווה N=922.
- הפלט מכיל index, targetDay, A0, כיוון זרם התשובה, choice בתחום 1..922 ו־length=choice+41 בתחום 42..963.
- gatePosition(0)=F. שערים חיוביים נצברים בחיבור והשליליים בחיסור, באמצעות פערים עצמאיים. אין להניח סימטריה.
- Prefix תחום |n|<=32 בלבד למניעת הרצת חישוב בלתי־תחום; gapFor תומך בהיסטי BigInt גדולים.
- אין חישוב שנה, שנה 5000, חודשים, חמישיית תאריך או תאריך מלא.

## Oracle ושערי קבלה

- oracle סקלרי נפרד מחשב את A0 והכיוון מתוך finalBowls/orderAt46, מבצע reject-and-step עבור N=922, ומחשב פער וסכום שערים ללא קריאה למחלקת gates או למחלקת questions.
- E–K הם רכיבים שכבר התקבלו ומשמשים oracle input; אין טענה לעצמאות נוספת באלגוריתמים הפנימיים של E–K.
- 50 זוגות היסטים חיוביים ושליליים, 4 דגימות BigInt נרחבות, 16 בדיקות recurrence לשערים 1..8 בשני הכיוונים, ובדיקות גבולות וסירוב.
- לפחות 750 assertions. לוג: PRODUCTION07_GATE_PASS; positive_cases=52; negative_cases=52; recurrence_cases=16; asymmetric_pairs>0; min_gap>=42; max_gap<=963; bowl=1; seal=1; choice_modulus=922; five_component_calendar_ready=false.
- CI: Dart SDK 3.13.2; verify, Stage1, Discovery01, Production01–07: סך 10/10 עבודות completed/success על SHA אחד, format 0 changed, analyze 0 issues; job עד 8 דקות.
- כל עוד אין completed/log: המימוש הוא candidate בלבד ואינו PASS. Stage2 נשאר פתוח.

## NEXT

לאחר קבלה רק: לתכנן את README §P, הגדרת השנה. לא לחשב שנה 5000 או תאריך מלא ולא למזג ל-main.
