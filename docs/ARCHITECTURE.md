# ארכיטקטורת שלב 1

שלב האתחול מפריד בין שלושה תחומים בלבד:

1. `SourceLanguageCatalog` — שכבת תצוגת המקור העברית, קפואה ומבוססת `canonicalIndex`.
2. `NormativeReference` — oracle נקי לצורכי בדיקה בלבד. הוא מממש את האלגוריתם הנורמטיבי מן הנספח ואינו חלק מן המסלול הספגטי של production.
3. `monster_base.dart` — תשתית production כללית וניטרלית בלבד. היא כוללת context פר־הפעלה, manager, dispatcher, validator ומדדים. אין בה שום ידע על טלאי עתידי.

בעלות ה־state הסמנטי בשלב 1 פשוטה: כל `MonsterContext` נוצר מחדש לכל invocation ואינו משותף. ה־metrics שב־context תצפיתיים בלבד. אין cache סמנטי גלובלי ואין registry mutable גלובלי.

ה־production בכוונה אינו מחזיר תאריך עדיין. ניסיון להפעיל את `calendarDateSpaghetti` בשלב 1 נעצר במפורש, כדי למנוע זליגה של לוגיקה עתידית לפני שלביה ההיסטוריים.
