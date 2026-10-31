# Dart+עברית — Stage 2 / PRODUCTION04: 46 טיפות גלויות ו-11 טחינות

PROJECT_ID: PC-BRANCH-DART-HEBREW
BRANCH: Dart+עברית
STAGE: 2
SLICE: PRODUCTION04
PRECONDITION: PRODUCTION03 accepted on 802583dbdf8571dd4ff9e15be0a0738a2c387269; run 41205314230 completed/success, 6/6 jobs, 1,564 checks.
NORMATIVE_SOURCE: Pastafarian-Calendar README §§D–G, Git blob 74c424b44eadd4ece3f29072ddbf873236557604.
LAST_ACCEPTED_FULL_STAGE: 1

## תיקון תחום

גרסת PRODUCTION04 שנוספה תחילה והפיקה שבע טיפות הייתה שגויה ביחס לתכנון המאושר. ריצת CI שלה הוכיחה רק את נכונות החוזה השגוי. אין לקבל את אותה תוצאה כקבלה אלגוריתמית. החוזה הנוכחי מחליף אותה: שבע הטיפות הן נסתרות; אחריהן נדרשות 46 טיפות גלויות, כל אחת עם 11 טחינות.

## מטרה וגבולות

לחשב את שרשרת 46 הטיפות הגלויות מתוך חמשת מנייני העבודה, טבלת 46 האבנים ושבע הטיפות הנסתרות של PRODUCTION03.

- קלט: MonsterWorkCounts תקף, שבע טיפות נסתרות בתחום [1,M], וטבלת 46 אבנים.
- פלט: רשימה בלתי ניתנת לשינוי, בסדר 1..46, של 46 רשומות טיפה.
- כל רשומת טיפה שומרת: index, dough, שלוש dependencies, אחת-עשרה רשומות grind, ו-value הסופי.
- לפני טיפה גלויה 1 נמצאות הטיפות הנסתרות במיקומים 0,-1,...,-6; hidden 1 במיקום 0 ו-hidden 7 במיקום -6.
- אין קערות, תמורות, 12 ערבובים נוספים, שערים, שנה או חמישיית תאריך. אין שינוי ב-calendarDateSpaghetti או ב-main.
- אין תלות ב-test_support/normative_reference.dart ואין העתקת מימוש מענף אחר.

## קלט ופלט מדויקים

M=2^127-1; SAVE(x)=1+((x-1) mod M), עם שארית אי-שלילית, ולכן כל ערך שמור בתחום [1,M].

לכל טיפה i=1..46, נגדיר:
- drop[j] = value של טיפה גלויה j כאשר j>=1.
- drop[j] = hidden[1-j] כאשר j<=0; hidden[1] נמצא במיקום 0 ו-hidden[7] במיקום -6.
- dependencies = [drop[i-1], drop[i-3], drop[i-7]].
- האבן stone_i היא שורת האבנים i (אינדקס מקור 1..46).

הבצק:
dough_i = SAVE(
  wheat_i*A + barley_i*T + salt_i*D + bitter_i*C + red_i*Q
  + drop[i-1] + 3*drop[i-3] + 5*drop[i-7] + i
).

אחת-עשרה שורות הטחינה, בפורמט [a,b,c,d,stoneIndex] כאשר אינדקס האבן הוא 0..4:
1 [3,5,7,11,0]
2 [5,7,11,13,1]
3 [7,11,13,17,2]
4 [11,13,17,19,3]
5 [13,17,19,23,4]
6 [17,19,23,29,0]
7 [19,23,29,31,1]
8 [23,29,31,37,2]
9 [29,31,37,41,3]
10 [31,37,41,43,4]
11 [37,41,43,47,0]

בכל שורת [a,b,c,d,s]:
x_new = SAVE(x_old^2 + a*x_old + b*drop[i-1] + c*drop[i-3] + d*drop[i-7] + stone_i[s]).
הטיפה הושלמה רק אחרי הטחינה ה-11. אין עדכון של טיפה אחרת מתוך תוצאת טחינה שטרם הושלמה.

## גבולות וראיות

- 46 טיפות בדיוק, 11 טחינות לכל טיפה, 506 פעולות טחינה בכל זוג ימים.
- כל dependency נלקחת רק מטיפה קודמת או מאחת משבע הטיפות הנסתרות; אין forward reference.
- כל חישובי BigInt מדויקים; כל dough, dependency, stone, before ו-after בתחום [1,M].
- פלט, dependencies, grind trace ושורות coefficients אינם ניתנים לשינוי.
- oracle סקלרי עצמאי: רשימות terms מפורשות, צבירה ליניארית ו-pow(2); אינו משתמש ב-MonsterModularMath או ב-MonsterVisibleDropGenerator.
- 49 זוגות היסטים 7×7: {-12,-2,-1,0,1,2,12}; בכל זוג נבדקים שבע הטיפות הנסתרות ו-46 הטיפות הגלויות, לרבות כל 24,794 תוצאות הטחינה.
- מקרה BigInt רחב F±(2^127+19), כולל כל עקבות הטיפות.
- עוגן מקור c=t=F: counts=(1,1,1,2,2); שבע הטיפות הנסתרות, טיפה גלויה 1 = 56644603826892212324764499696091907135, וטיפה גלויה 46 = 141872771689426650819909896585756512282.
- דחיית feed חסר/מחוץ לתחום, טבלת אבנים חסרה, מניינים לא חוקיים; אי-שינוי קלטים ואי-יכולת לשנות את הפלט.
- לפחות 100,000 assertions אמיתיים; הלוג חייב לכלול PRODUCTION04_VISIBLE_DROPS_PASS, feed_cases=49, visible_drops=46, drop_cases=2254, grind_steps=24794, grinds_per_drop=11, five_component_calendar_ready=false.
- CI עם Dart 3.13.2: verify, Stage1 Native, Discovery01, Production01, Production02, Production03 ו-Production04 — 7/7 jobs completed/success על אותו SHA; format 0 changed, analyze 0 issues; job עד 8 דקות.
- checkpoint מקור §AC מאמת את hidden 1..7 ואת visible 1 ו-46. בדיקות יתר הזוגות הן oracle פנימי עצמאי לפי §§D–G, ולא טענת אימות מול מנוע Seer.

## NEXT לאחר קבלה

PRODUCTION05: שש קערות בעלות מזהים קבועים 1..6; עדכון סינכרוני לכל אחת מ-46 הטיפות; שמירת סדר הקערות בטיפה 46 בנפרד; ולאחר מכן בדיוק 12 ערבובים נוספים. סדר טיפה 46 נשאר מצביע הקערות לשאלות מאוחרות, ואסור להחליפו בסדר של ערבוב 12. אין לחשב תשובות חותם, שערים או חמישיית תאריך במקטע זה.
