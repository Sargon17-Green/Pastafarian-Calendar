# Dart+עברית — Stage 2 / PRODUCTION03: 46 אבני זרעים ושבע הזנות

PROJECT_ID: PC-BRANCH-DART-HEBREW
BRANCH: Dart+עברית
STAGE: 2
SLICE: PRODUCTION03
LAST_ACCEPTED_FULL_STAGE: 1
PRECONDITION: PRODUCTION02 accepted on 24c86d59d0d911908a7f05fb9fc8625665694c99; run 41193755013 completed/success, 5/5 jobs; 12,766 checks.

## גבולות
חוזה זה מממש רק 46 אבני זרעים ושבע הזנות תלויות-מניינים. אין תאריך, טיפות גלויות, קערות, בחירות שנה/חודש או מסלול חמשת הרכיבים. Production אינו מייבא את test_support/normative_reference.dart ואינו משנה main. שלד calendarDateSpaghetti ממשיך לדחות קריאה.

## נוסחאות
M=2^127-1; S(x)=1+((x-1) mod M), תמיד בטווח [1,M].
אבן n מכילה (w,b,s,t,r): חיטה, שעורה, מלח, מרור, אדום. הערכים הראשונים: (17,29,43,71,101).
למעבר מאבן n לאבן n+1 (n=1..45), בו-זמנית:
- w'=S(w²+3b+n+1)
- b'=S(b²+5s+w)
- s'=S(s²+7t+b)
- t'=S(t²+11r+s)
- r'=S(r²+13w+t)
כל 46 האבנים מוחזרות במבנה בלתי ניתן לשינוי.

חמשת מנייני העבודה: A=action, T=target, D=distance, C=connection, Q=direction. נדרש A,T,D>0, C=A+T, Q באוסף {1,2,3} ואורך טבלת אבנים 46.
לכל k=1..7, עם אבן k:
x0=S(A+(2k+1)T+(3k+1)D+(4k+2)C+(4k+4)Q+w_k+b_k+s_k+t_k+r_k).
לכל g=1..7: xg=S(x(g-1)²+3x(g-1)+ingredient(k,(g-1) mod 5)+g).
פלט: 7 ערכי x7 במבנה בלתי ניתן לשינוי ובסדר k עולה.

## Oracle עצמאי ושערי קבלה
בדיקות Dart משתמשות במניין סקלרי מפורש של חמשת השדות, בנפרד ממימוש ה-production הווקטורי; ההזנות מחושבות בחיבור רשימת איברים ו-pow(2), ללא MonsterModularMath וללא ייבוא oracle נורמטיבי.
- 46×5=230 רכיבי אבנים: שוויון oracle ותחום.
- 49 זוגות ימים בהיסטים {-12,-2,-1,0,1,2,12} לשני הימים, שבע הזנות לזוג, שוויון oracle, גבולות וחזרה דטרמיניסטית.
- עוגני אבנים 1,2,46, לרבות אדום אחרון 137131922036975206684616468948804344042.
- BigInt בטווח F±(2^127+19); דחיית טבלה חסרה ומנייה לא חוקית; אי-יכולת לשנות טבלה או הזנות.
- לפחות 1,500 assertions, stones=46, stone_cases=230, feed_cases=49, הודעת PRODUCTION03_FEED_PASS; five_component_calendar_ready=false.
- CI עם Dart 3.13.2: verify, Stage1 Native, Discovery01, Production01, Production02 ו-Production03 — 6/6 jobs completed/success באותו SHA; format 0 changed, analyze 0 issues, Production03 <=8 דקות.
- אסור לייחס קבלת PRODUCTION03 לפני completed/log, ואין בכך אישור Stage2 מלא.

## NEXT לאחר קבלה
לפתוח PRODUCTION04 למימוש טיפות גלויות וערבול תחום, עם oracle נפרד; לא לבנות את חמשת רכיבי התאריך ללא חוזה ושערי קבלה.
