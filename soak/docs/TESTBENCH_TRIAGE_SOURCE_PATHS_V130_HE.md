# v130 — השלמת נתיבי מקור אפשריים לעשרת ענפי ה־triage

תאריך העבודה: 20.11.2026. ענף QA: `qa/soak-triage-path-v130`.

## ההקשר ומקור הראיה

ב־v129, הרצת [44704866938](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44704866938)
הסתיימה ב־`completed/success`; 26 בדיקות יחידה עברו; 81/91 רשומות
הציגו קובץ מקור קיים עם בתים וגיבוב שאומתו; עשר רשומות נשארו ללא
`source_path`. שני המנעולים ההיסטוריים REF-41 ו־REF-24 עברו,
וכן בדיקות הקישור ל־CI ההיסטורי. כל אלה **אינם** אישור Soak.

קובץ `soak/control/triage_candidate_sources_v130.json` נבנה מתוך
קריאה אמיתית של עצי Git בענפים הנדרשים, לפי קומיטים מדויקים;
הוא מייצג **מועמדים לבדיקה**, לא הכרעה איזה קובץ הוא ממיר מקורי תקין.

| רשומה | נתיב מועמד שנמצא בעץ Git | מעמד השימוש |
|---|---|---|
| TRIAGE-01 — Befunge | `src/bootstrap.b98` | שלד/Bootstrap |
| TRIAGE-02 — Codesh | `מקור/תאריך־שלם־טהור.אמן` | מועמד לנקודת כניסה, ללא הסמכה |
| TRIAGE-03 — Excel-VBA | `src/PastafarianExcel.bas` | מועמד לנקודת כניסה, ללא הסמכה |
| TRIAGE-04 — LabVIEW/G | `labview-project/PastafariCalendar-LabVIEW-G.lvproj` | **קובץ פרויקט בלבד**, לא VI שניתן להריץ |
| TRIAGE-05 — Plain-English | `source/the complete date` | מועמד לנקודת כניסה, ללא הסמכה |
| TRIAGE-06 — SM83 Assembly | `src/boot.asm` | שלד/Bootstrap |
| TRIAGE-07 — Shakespeare | `src/monster_bootstrap.spl` | שלד/Bootstrap |
| TRIAGE-08 — SystemVerilog | `rtl/pcal_stage1_bootstrap.sv` | שלד/Bootstrap |
| TRIAGE-09 — Word-VBA | `src/PastafarianWord.bas` | מועמד לנקודת כניסה, ללא הסמכה |
| TRIAGE-10 — x86-64 Assembly | `src/production/stage54_integration.s` | מועמד לנקודת כניסה, ללא הסמכה |

**חשוב:** הסיווג `SOURCE_ENTRYPOINT_CANDIDATE_NOT_REVIEWED`
אינו מעיד שהקוד מחשב את חמשת שדות התאריך לכל קלט,
שעבר בנייה או שהוא עצמאי מבחינה אלגוריתמית.

## הגדרות השער

`soak/runner/soak_triage_path_v130.py` קולט את
דוח ה־v129 שנוצר בהרצה המאומתת ואת קובצי ה־provenance,
ומוודא ב־fail-closed:

1. בדיוק עשר רשומות בעלות `source_path=null`, ללא כפילות או
   השמטה, ועם קומיט זהה לראש הענף שנצפה בדוח v129.
2. עץ Git מלא (`truncated=false`) עבור כל קומיט, וקיומו של
   הנתיב המיועד בתור `blob`.
3. זהות Git blob SHA-1 בין העץ לתוכן הקובץ שנשלף מאותו קומיט;
   SHA-256 וגודל בבתים נשמרים לדוח.
4. כאשר ראש הענף הנוכחי שונה, הדוח מציין `current_head_matches_v129=false`,
   בלי לשכתב את מקור הראיה ההיסטורי.
5. רשומות אחרות מאותו מאגר וענף מדווחות בתור חפיפת מפקד,
   ולא נספרות כמנוע עצמאי חדש.

כל דוח מחזיר `candidate_is_verified_original_Fct=false`,
`independent_algorithm_certified=false` ו־`eligible_for_soak=false`.

## אימות CI

ההרצה של `.github/workflows/soak-triage-path-v130.yml`:

- מבצעת 13 בדיקות סינתטיות ללא הרצת ממירים;
- מאמתת שה־workflow של v129 בוצע על HEAD `e1b0d888...`,
  הסתיים ב־`completed/success` ושארכיון הראיות הספציפי
  בעל ID `14615867472` וגיבוב הארכיון שסופק על ידי GitHub
  קיים ולא פג תוקפו;
- מורידה את אותו artifact מ־run `44704866938`, ולא יוצרת
  דוח v129 חלופי;
- מאמתת את עשרת נתיבי המקור מתוך קומיטים מקוריים, ולא
  מסתמכת על שמות קבצים שנוחשו;
- שומרת לוג בדיקות, גיבובי מקור וסטטוסים בארכיון חדש.

הסקריפט אינו משגר F(c,t). הוא גם אינו מתקן נתיבי מקור בקובץ
מפקד ה־v127 המקורי. קידום למפקד ההרצה יתבצע רק לאחר
ביקורת על קובץ הכניסה האמיתי, תלויות, סמנטיקה, ABI,
הרצה מקורית, ושיוך אלגוריתמי.

**Issue #29 נשאר פתוח**. חסימת
`STOP_NEW_NATIVE_SOAK_DISPATCH` לא שונתה.
אישור שנות Soak: **0/10,000**.
