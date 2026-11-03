# SQL+தமிழ் — Stage 2 Slice 20: חוזה choose_month_count

תאריך: 2026-11-03. **חוזה תכנון בלבד. Slice20 טרם מומש וטרם עבר PostgreSQL Native.** תנאי קדם: Slice19 ACCEPTED, 54/54, run https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41618421392, SHA `e216dde0b80c0a85607af97413039ccf2316d811`. מקור: `sql/test/10_normative_reference.sql` **בענף SQL+தமிழ்**, פונקציית `pastafari_sql_tamil_test.choose_month_count` (סמוך לשורה 1355). אין להעתיק אלגוריתם/fixture מענף אחר, ואין לערוך את המקור הנורמטיבי.

## חתימה וקלט/פלט
`pastafari_sql_tamil.choose_month_count(p_sauce pastafari_sql_tamil.sauce_result, p_year pastafari_sql_tamil.year_rec) RETURNS integer`.

נגדיר `D = close_gate_day - open_gate_day` עבור `p_year`. בתחום השנים התקין של המקור הנורמטיבי: `D` שלם ב־`[252,5778]`. החישובים **מדויקים במספרים שלמים**:
- `lo = ceil(D/123)`;
- `hi = min(47,floor(D/4))`;
- `cnt = hi-lo+1`;
- `r = choose_rank(ask_bowl(p_sauce,3,30),cnt)`;
- `result = lo+r-1`.

בתחום התקין: `hi=47`, `lo∈[3,47]`, `cnt∈[1,45]`. ערכי גבול מחושבים: `D=252 → lo=3,hi=47,cnt=45`; `D=5778 → lo=47,hi=47,cnt=1`. פונקציית הייצור **אינה** נדרשת לאמת שה־`p_sauce` נוצר מן השנה — אין לכך מידע מפורש בחתימה. ה־caller אחראי לעקביות הזוג.

ל־NULL בקלט או לשנה לא תקינה (למשל `D<=0`, מחוץ לתחום, לא שלם, `cnt<=0`, יום פתיחה/סגירה לא תקין) החזר SQL NULL בלי truncation, overflow או exception בלתי מטופל. עבור `sauce_result` פגום / `ask_bowl` NULL / `choose_rank` מחוץ לתחום — גם SQL NULL. אלה שומרי־סף לקלט פגום, לא שינוי של כלל החישוב על תחום תקין.

## מימוש בלתי תלוי
- פונקציית SQL/PLpgSQL production בלבד, המבוססת על `ceil` / `floor` של `NUMERIC` ועל `ask_bowl` ו־`choose_rank` של הענף עצמו, לא על סכמת `pastafari_sql_tamil_test`, טבלאות mutable או cache. הצהר על volatility/strictness רק לפי התלויות המאומתות.
- Oracle נפרד: Python שלם, מחשב `lo,hi` וחוזר על כל `r∈[1,cnt]` עבור מדגם צפוף של `D` כולל 252, 253, 492, 2460, 5778; זהו oracle מתמטי לתוצאת `lo+r-1`. עבור `sauce` אמיתי, השווה ב־PostgreSQL את התוצאה לפונקציה הנורמטיבית ב־DB נפרד עם המרת שדות מפורשת.
- אל תשתמש ב־reference SQL ליצירת קוד production או ב־goldens של production עצמו לצורך ה־oracle.

## שערי QA מדידים
1. אימות מקור, HEAD ומזהי blob של קוד production, Python oracle, Native SQL, Differential SQL ו־workflow PostgreSQL 17; ללא שינוי ב־Slice19 הקודם.
2. Native לפחות **24 assertions** נפרדות כולל D=252,253,492,2460,5778, rank1=1/rank1=cnt, תחום, דטרמיניזם, NULL ולפחות 8 מקרי קלט פגום. בדיקה אקטיבית של ערכי `ok=t` ו־`count >= 24`, לא עצם הצלחת `psql` בלבד.
3. Production isolation לפחות **4 assertions**: load של קוד production בלבד, חתימה, volatility/strictness תואמים, העדר תלות בסכמת test/טבלאות mutable.
4. Differential לפחות **8 מקרים**, שתי תצורות sauce לכל ארבעה ערכי D שונים ב־[252,5778], עם בדיקה מפורשת של התוצאה המספרית ושל `IS NOT DISTINCT FROM` מול `pastafari_sql_tamil_test.choose_month_count`. פיצול ל־jobs תחומים בזמן.
5. Run completed/success על SHA נעול; בדיקת ספירות מתוך logs וארכיונים; ZIP לכל job, אימות SHA256 המקורי מול GitHub digest ולוג העלאה, CRC, SHA256 לקובצי SQL שנוצרו. אין לייחס PASS לבדיקה שטרם הורצה.
6. ללא main/merge/publish, ללא dispatch כפול, וללא שינוי במדיניות סטטוס. אם כשל, לתקן את הצעד שנכשל על בסיס log ועדות שחזור; Push חדש רק לאחר תיקון.

## NEXT
לממש את הפונקציה, לבנות oracle עצמאי ובדיקות Native/Differential, לחבר workflow PG17 תחום בזמן ולהפעילו רק על ידי push מורשה של קובצי Slice20. אין claim ש־Slice20 כבר עבר בדיקות.
