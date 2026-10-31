# Dart+עברית — Stage 2 / PRODUCTION02: חשבון מודולרי

PROJECT_ID: PC-BRANCH-DART-HEBREW
BRANCH: Dart+עברית
STAGE: 2
SLICE: PRODUCTION02
PRECONDITION: PRODUCTION01 accepted on 73bcfa63a0fe6931ff5c8a1d75fe57d077c02a90, run 41193390679, 4/4 completed/success, 717 checks.
LAST_ACCEPTED_FULL_STAGE: 1

## מטרה והיקף
תשתית Production עצמאית של חשבון BigInt מדויק לקראת מנגנון הטיפות והרוטב. אין העתקה או קריאה של `test_support/normative_reference.dart`. אסור להפעיל את חמשת רכיבי התאריך, למחוק את ה-StateError הקיים או למזג ל-main.

## חוזה
- M=2^127-1 בדיוק.
- floorDiv(a,b)=⌊a/b⌋ עבור b לא אפס, לרבות b שלילי.
- regularMod(x,d)=r כאשר d>0 ו-0<=r<d וכן x-r מתחלק ב-d.
- save(x)=1+regularMod(x-1,M), בטווח [1,M], מחזורי באורך M, ואידמפוטנטי.
- square(x)=x*x בחשבון מדויק.
- ceilDiv(a,b)=⌈a/b⌉ עבור a>=0,b>0; שאר הקלטים נדחים ב-ArgumentError.
- אין שימוש ב-double בחישוב production; רק ב-oracle הבדיקה לטווח הקטן [-80,80] שבו הדיוק מלא.

## בדיקות וגבולות
- 3,542 זוגות רצפה: a=-80..80, b=-11..-1,1..11, מול oracle קטן בלתי תלוי של int/double.
- 3,059 זוגות מודולו: x=-80..80, d=1..19; שלושה אינווריאנטים לכל זוג.
- M, 0, M+1, -M; מחזוריות, תחום ואידמפוטנטיות.
- עדים מעל 200 ביט ב-floorDiv, ceilDiv, square; חריגות חלוקה באפס ותחומים אסורים.
- חייבים לפחות 12,000 assertions, 3,542 floor_cases ו-3,059 mod_cases, הודעת PRODUCTION02_MODULAR_PASS; five_component_calendar_ready=false.
- ארבעת שערי הרגרסיה הקודמים יחד עם Production02 Native באותו SHA: 5/5 jobs completed/success. Dart 3.13.2, פורמט 0 changed, analyze 0 issues, job עד 8 דקות.
- השלב הזה אינו מייצר תאריך; Stage2 נשאר פתוח גם אם המקטע מתקבל.

## NEXT לאחר קבלה
PRODUCTION03: טבלת 46 אבני הזרעים ופונקציות הזנה תלויות-מניינים בעזרת primitives חדשים. לפתח חוזה עצמאי ובדיקות גבול לפני חיבור לפונקציית התאריך, ללא העתקת אלגוריתם מן oracle.
