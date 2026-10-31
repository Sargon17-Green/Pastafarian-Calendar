# Dart+עברית — Stage 2 / PRODUCTION05: שש קערות ו-12 ערבובים נוספים

PROJECT_ID: PC-BRANCH-DART-HEBREW
BRANCH: Dart+עברית
STAGE: 2
SLICE: PRODUCTION05
PRECONDITION: PRODUCTION04 accepted on b268aad78ea500e3a9d07aeecbe1987dfbcc8fb3; run 41214443879 completed/success, 7/7 jobs; 290,914 Production04 assertions.
NORMATIVE_SOURCE: Pastafarian-Calendar README §§H–K, Git blob 74c424b44eadd4ece3f29072ddbf873236557604.

## מטרה וגבולות

לחשב את מצב שש הקערות הקבועות לאורך 46 הטיפות הגלויות, לשמור את סדר הקערות של טיפה 46 כ-orderAt46, ואז לבצע בדיוק 12 ערבובים נוספים.

- קלט: MonsterWorkCounts תקף, טבלת 46 אבנים ו-46 רשומות טיפה מ-PRODUCTION04 בסדר 1..46.
- מזהי הקערות קבועים 1..6; הסדר בכל שלב הוא סדר מיקומים זמני, לא שינוי זהות הקערה.
- פלט: initial, 46 dropStages מלאים, orderAt46, afterDrops, 12 postStirs ו-finalBowls.
- כל וקטורי bowl מסודרים לפי זהות קבועה 1..6; order ו-orderAt46 הם מזהי קערה לפי מיקום.
- אין חישוב seals/questions, gates, year, חמישיית תאריך או שינוי ב-calendarDateSpaghetti.

## אתחול שש הקערות

p_b לפי מזהה קערה b=1..6:
[17,19,23,29,31,37].

s_b = A + b*T + D + C + Q + p_b^2
B_b = SAVE(s_b^2 + b).

## 720 תמורות

כל תמורות המזהים [1,2,3,4,5,6] מסודרות לקסיקוגרפית; קיימות 720 תמורות.
rank בתחום 1..720; order = התמורה הלקסיקוגרפית במקום rank.
לכל טיפה גלויה D:
rank = 1 + ((D-1) mod 720).

## עדכון כל אחת מ-46 הטיפות

לכל טיפה i=1..46:
- snapshot יחיד old של שש הקערות לפי מזהה קבוע.
- order לפי rank של D.
- direct pours לפי מיקום:
  - position 1: SAVE(D^2 + wheat_i*old(order[1]) + 3i)
  - position 2: SAVE(D^2 + barley_i*old(order[2]) + 5i)
  - position 3: SAVE(D^2 + salt_i*old(order[3]) + 7i)
  - positions 4..6: zero.
- stonePosition לפי מיקום 1..6: [0,1,2,3,4,0].
- עבור bowl B במיקום q, P הקודמת ו-N הבאה במעגל:
  u = old(B) + 2*old(P) + 3*old(N) + directPour(q) + D + stone(q)
  new(B) = SAVE(u^2 + 5*old(P)*old(N) + i*q).
- כל שש התוצאות מחושבות מאותו snapshot ומושמות יחד; אין שימוש בערך חדש באותו שלב.
- לאחר טיפה 46 נשמר orderAt46; אין לשנותו בשלבי הערבוב המאוחרים.

## 12 ערבובים נוספים

לכל r=1..12:
- snapshot יחיד old של שש הקערות.
- S_r = SAVE(sum(oldBowls) + 149*r).
- rank = 1 + ((S_r-1) mod 720); order הוא התמורה הלקסיקוגרפית באותו rank.
- עבור bowl B במיקום q, P הקודמת ו-N הבאה:
  u = old(B) + 3*old(P) + 5*old(N) + S_r + r + q^2
  new(B) = SAVE(u^2 + 7*old(P)*old(N)).
- כל שש התוצאות מחושבות מאותו snapshot ומושמות יחד.
- orderAt46 נשאר סדר טיפה 46 המקורי; אין להחליפו בסדר של אף אחד מ-12 הערבובים.

## Oracle עצמאי ושערי קבלה

- oracle נפרד מייצר את 720 התמורות באמצעות רקורסיה לקסיקוגרפית; חישובי BigInt נעשים באמצעות רשימות terms מפורשות, צבירה ליניארית ו-pow(2), ללא MonsterModularMath או MonsterBowlProcessor.
- 49 זוגות היסטים 7×7: {-12,-2,-1,0,1,2,12}; בכל זוג נבדקים 46*6=276 עדכוני טיפה ו-12*6=72 עדכוני ערבוב.
- סה"כ 13,524 עדכוני קערה בעקבות טיפות ו-3,528 עדכוני קערה בערבובים; 17,052 עדכונים.
- מקרה BigInt רחב F±(2^127+19).
- checkpoint c=t=F: orderAt46=[4,5,2,3,6,1]; finalBowls לפי זהות קבועה:
  1 65286679584284972964194865805379907599
  2 127720283375330263615328810127751035299
  3 54364069496183805843611594721403108554
  4 93072329024469476118876155742008280619
  5 54867842942953573450868747713087920246
  6 111207247632761530752404582123499651367
- בדיקות זהות קערה מול מיקום, direct pour רק בשלושת המיקומים הראשונים, סינכרוניות, orderAt46 יציב, תחום [1,M], אי-שינוי קלטים ואי-יכולת לשנות פלטים.
- לפחות 100,000 assertions אמיתיים; הלוג חייב לכלול PRODUCTION05_BOWLS_PASS, feed_cases=49, drop_updates=13524, post_stir_updates=3528, visible_drops=46, post_stirs=12, order_at_46=4,5,2,3,6,1 ו-five_component_calendar_ready=false.
- CI עם Dart 3.13.2: verify, Stage1 Native, Discovery01, Production01, Production02, Production03, Production04 ו-Production05 — 8/8 jobs completed/success על אותו SHA; format 0 changed, analyze 0 issues; job עד 8 דקות.

## NEXT לאחר קבלה

להשאיר Stage2 פתוח ולגזור את שלב השאלות/חותמות (README §§L–N) כחוזה עצמאי. אין לחשב gates או חמישיית תאריך במקטע זה.
