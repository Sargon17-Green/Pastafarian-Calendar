# Dart+עברית — Stage 2 / PRODUCTION06: תשובות קערה ובחירה שווה

PROJECT_ID: PC-BRANCH-DART-HEBREW
BRANCH: Dart+עברית
STAGE: 2
SLICE: PRODUCTION06
PRECONDITION: PRODUCTION05 accepted on a429ab187accb170636d0cefea0a7f7b72af5e4d; run 41215453053 completed/success, 8/8 jobs; 277,352 Production05 assertions.
NORMATIVE_SOURCE: Pastafarian-Calendar README §§L–N, Git blob 74c424b44eadd4ece3f29072ddbf873236557604.

## מטרה וגבולות

לממש את מנגנון השאלה הכללי של קערה ואת מנגנון הבחירה השווה (short/wide), על בסיס מצב הקערות הסופי ו-orderAt46.

- קלט לשאלה: MonsterBowlResult מלא, מזהה קערה קבוע 1..6, וחותם קנוני.
- החותמות הקנוניות: [1,10,11,12,20,21,22,30,31,32,33]. מיקום חותם 40 נשאר ריק ונדחה.
- קלט לבחירה: A0, כיוון ±1, ומודולוס N חיובי שסופק במפורש.
- אין מיפוי אוטומטי של חותמות ל-N; אין להמציא N לשאלה. אין חישוב gates, years, חמישיית תאריך או תאריך מלא.

## תשובת קערה

הקערה הבאה ל-B נקבעת רק לפי orderAt46: מזהים קבועים 1..6 בסדר מעגלי; אין להשתמש בסדר של אף אחד מ-12 הערבובים.

A0 = SAVE((Q[B] + z + 181)^2 + 179*Q[next] + z)
D  = SAVE((A0 + z + 1 + 193)^2 + 193*A0 + 197*Q[6])
direction = +1 אם D אי-זוגי, אחרת -1.

A_k = SAVE(A0 + direction*k), עבור k BigInt אי-שלילי.
הזרם רציף על המעגל 1..M; index=0 מחזיר A0.

## בחירה שווה — N<=M

L = floor(M/N)*N.
אם A0<=L, A0 מתקבל מיד.
אם A0>L:
- direction=+1: הערך הראשון שמתקבל אחרי הליכה קדימה ומעבר בקצה הוא 1.
- direction=-1: הערך הראשון שמתקבל הוא L.
הבחירה: 1+((accepted-1) mod N).
יש להחזיר גם את מספר הערכים שנדחו, בלי לולאה על הזנב.

## בחירה שווה — N>M

מצא את k הקטן ביותר שעבורו M^k>=N; k מוגבל ל-4096.
digits[j] = A_j, בסדר little-endian, עבור j=0..k-1.
W = 1 + Σ(digits[j]-1)*M^j
Lw = floor(M^k/N)*N.

אם W<=Lw, W מתקבל.
אם W>Lw:
- direction=+1: הצעד הראשון שמתקבל אחרי wrap הוא 1.
- direction=-1: הצעד הראשון שמתקבל הוא Lw.
הבחירה: 1+((accepted-1) mod N).
יש להחזיר W, digits, M^k, Lw, accepted, rejected count והתוצאה. מימוש ההליכה באמצעות נוסחה סגורה חייב להיות שקול לצעד-אחר-צעד על המעגל 1..M^k; אין לולאה בגודל הזנב.

## Oracle עצמאי ושערי קבלה

- oracle נפרד מחשב A0/D והזרם באמצעות נוסחאות scalar מפורשות; הבחירה הרחבה נבדקת עם בניית ספרות little-endian נפרדת.
- התמורות והקערות נלקחות מ-PRODUCTION05, שבו orderAt46 נשמר; בדיקה מפורשת ש-next נקבעת מ-orderAt46 ולא מסדרי הערבוב.
- 49 זוגות היסטים × 11 חותמות × 6 קערות = 3,234 רצפי תשובה.
- לכל רצף נבדקים answerAt ב-indexes 0,1,2,17,127 ותשע בחירות N: 1,2,17,922,M,M+1,M^2-2,M^2+1,M^3-1; סה"כ 29,106 בחירות.
- בדיקות גבול סינתטיות מכסות rejection ו-wrap בשני הכיוונים בענפי short ו-wide.
- דחיית bowl ID לא חוקי, חותם 40, כיוון 0, A0 מחוץ לתחום, N=0 ו-index שלילי; digits בלתי ניתן לשינוי.
- לפחות 100,000 assertions; הלוג חייב לכלול PRODUCTION06_SEALED_BOWL_PASS, sequence_cases=3234, selection_cases=29106, short_rejections>0, wide_rejections>0, positive_directions>0, negative_directions>0, canonical_seals=11, five_component_calendar_ready=false.
- CI עם Dart 3.13.2: verify, Stage1 Native, Discovery01, Production01–05 ו-Production06 — 9/9 jobs completed/success על אותו SHA; format 0 changed, analyze 0 issues; job עד 8 דקות.

## NEXT לאחר קבלה

PRODUCTION07: חוזי §O לשערים — חישוב פער חיובי/שלילי באמצעות זוגות עצמאיים (F,F±n), קערה 1, חותם 1 ו-N=922. אין להסיק סימטריה בין פערים חיוביים ושליליים, ואין לחשב שנה 5000 או תאריך.
