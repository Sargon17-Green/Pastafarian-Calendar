# v139 — ממצא סטטי מאומת: משפחות שזירת החודשים של Ada ושל Python אינן שקולות

**תאריך:** 20 בנובמבר 2026. **ענף ביקורת:** `qa/soak-month-weaving-family-divergence-v139`. **מצב:** בדיקות ה־QA הושלמו ב־SUCCESS; אין הכרעה שסיבת ההבדל בתאריך היסוד היא יחידה או שמותר לחדש את מבחן ה־Soak.

## הכרעת קבלה

[הרצת v139 ב־GitHub Actions, מספר 44811104026](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44811104026) הסתיימה `completed/success`; כל **16/16 הבדיקות הסינתטיות עברו**. הארטיפקט `14665137651`, `soak-v139-original-weave-family-static-subset-no-native`, בעל SHA-256 של ארכיון ZIP:

`f87f1ee607b678bea94f048746c488cc276e259a7da01ac3e5e4939e4a1090cc`.

ה־CI קרא את **ששת קובצי המקור המקוריים** באמצעות ה־Git blob SHA-1 המדויק, השווה את מבנה האלגוריתמים ומנה *רק* מודל קומבינטורי קטן של שני חודשים בני ארבעה ימים. אין כאן הרצת Ada, Python המקורי, כל תהליך `F(c,t)`, קומפיילר או מקשר.

## המקורות המקוריים שננעלו בגיבוב

| קובץ | קומיט | Git blob SHA-1 |
|---|---|---|
| [Ada: `src/month_weaving.adb`](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72/src/month_weaving.adb) | `a2fb6811` | `9b02c62dfbc7d8b3b532aba8cd9f1ad0f8b28fef` |
| [Ada: `src/normative_oracle.adb`](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72/src/normative_oracle.adb) | `a2fb6811` | `923733d4f8face03586aee304640bf7540c28b4c` |
| [Ada: `tests/stage14_real_oracle.py`](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72/tests/stage14_real_oracle.py) | `a2fb6811` | `0922f5cbb32697106d4537463e56f7edb74e3355` |
| [Ada: `tests/stage14_real_differential.py`](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72/tests/stage14_real_differential.py) | `a2fb6811` | `44a38a1a8d9fac1bf2f454c2828a8545cd0e1d5b` |
| [Python: `tests/normative_reference.py`](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4/tests/normative_reference.py) | `0e4e7588` | `d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53` |
| [Python: `src/pastafari_calendar/legacy_month_weaving.py`](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4/src/pastafari_calendar/legacy_month_weaving.py) | `0e4e7588` | `b07103088c853f61eafa135eaac3142d58b096d7` |

## ההבדל האלגוריתמי

**במקור Python**, המחלקה `MonthWeavingFamily` שבקובץ `tests/normative_reference.py`, שורות 682–807, מנהלת את המצבים `remaining`, `opened` ו־`closed`. תנועת הביניים (`_moves`) מאפשרת לחודש שכבר נפתח להוסיף ימים או להיסגר, וכאשר `opened < month_count` אפשר לפתוח את החודש הבא. יש לשמור על סדר פתיחת החודשים וסדר סגירתם, אבל **לא כל הפתיחות חייבות להקדים את כל הסגירות**. הפונקציה `choose_month_weaving`, שורות 1137–1144, בוחרת דרגה מתוך **כל** המשפחה החוקית באמצעות `choose_rank(ask_bowl(...), family.count())`, ומשחזרת את השזירה באמצעות `family.unrank1(rank)`. מימוש הייצור המקורי משתמש באותו רעיון במשפחה `LegalMonthWeavingDP`.

**במקור Ada**, הפונקציה `Month_Weaving.From_Choices` בשורות 23–80 של `src/month_weaving.adb` כותבת תחילה **את כל מזהי החודשים בסדר** (`Output(Pos) := J`), אחר כך משזרת **רק את `lengths[J]-2` המופעים הפנימיים**, ולבסוף כותבת שוב **את כל מזהי החודשים בסדר**. הפונקציה `Calendar_Date` בשורות 1079–1122 ו־1162–1173 של `src/normative_oracle.adb` אכן מפעילה `Month_Weaving.From_Choices(Lengths,Tickets)`.

כלומר, אם `P` הוא מרחב השזירות החוקיות במקור Python, ו־`A` הוא מרחב השזירות במקור Ada, מתקיים **`A ⊊ P`**, ולא `A=P` במודל המחושב. זו אי־שקילות של הגדרות הקלט והדרגות, ולא רק עניין של שמות או פורמט פלט.

## מקרה נגד קטן ובדיקה מתמטית

נבחן שני חודשים, כל אחד עם 4 ימים (`lengths=(4,4)`). לפי חוקי Python יש שתי אילוצי סדר: החודש הראשון חייב להיפתח לפני השני, וחייב להיסגר לפני השני. לכן היום הראשון בהכרח מחודש 1 והאחרון מחודש 2; מתוך ששת המקומות הנותרים בוחרים שלושה ימים נוספים לחודש 1:

\[
|P|=\binom{6}{3}=20.
\]

ב־Ada שני הימים הראשונים קבועים `(1,2)`, שני האחרונים קבועים `(1,2)`, ובארבעת המקומות הפנימיים צריך לבחור שני מופעים נוספים של חודש 1:

\[
|A|=\binom{4}{2}=6.
\]

הסדרה `(1,1,1,1,2,2,2,2)` חוקית לפי Python: חודש 1 נפתח ונסגר לפני פתיחת חודש 2. לעומת זאת היא **בלתי אפשרית ב־Ada**, מפני ששני המופעים הראשונים ב־Ada חייבים להיות `(1,2)`. בודק v139 מצא בדיוק **20 שזירות חוקיות ב־Python, 6 ב־Ada, 14 שזירות חוקיות שנעדרות מ־Ada**.

חשוב: זהו **מודל מינימלי** שנועד להוכיח אי־שקילות של כלל השזירה. אין לזקוף אותו לבדיקת השנה או התאריך המקוריים. הוא אינו מחושב באמצעות מנוע התאריכים המקורי.

## כיצד הבדיקות המקוריות של Ada הסתירו את אי־השקילות

בענף Ada, קובץ `tests/stage14_real_oracle.py` בונה שזירה באמצעות `seq=list(range(len(lengths)))`, מגריל את המופעים הפנימיים, ולבסוף מחבר `seq+list(range(len(lengths)))`. זו **אותה הנחת שתי המסילות** שנמצאת ב־Ada; היא אינה מחלקת האפשרויות של Python המקורי.

בנוסף, קובץ `tests/stage14_real_differential.py` מכיל ערך `PROVISIONAL` קבוע לתאריך היסוד: `(5000,10,503,30,52)`, ומשווה את ה״אורקל העצמאי״ של ענף Ada לערך הזה. לפיכך PASS של בדיקת ענף Ada מעיד על **עקביות פנימית של שתי גרסאות התלויות באותה הנחה**, ולא על התאמה ל־`REF-41` המקורי.

## היחס ל־Issue #29: מקור שגיאה מועמד, לא הכרעת סיבתיות מלאה

ב־[Issue #29](https://github.com/Sargon17-Green/Pastafarian-Calendar/issues/29) מתועדת אי־התאמה מוכחת עבור `F(c=-15055671,t=-15055671)`:
- Python+Türkçe, TypeScript+मराठी ו־Fortran+English: `(5000,10,503,20,56)`.
- Ada+తెలుగు: `(5000,10,503,30,52)`.

שלושת השדות הראשונים שווים; **מזהה החודש והיום בחודש שונים**. אי־שקילות משפחת השזירה היא מועמד חזק למקור ההבדל, משום ששני השדות האחרונים נגזרים מתוך סדר הופעת החודשים. אולם לא נעשתה כאן הוכחת עקיבה מלאה של ערכי הביניים בתאריך היסוד (כגון כל אורכי החודשים, זרם בחירת הדרגה ודרגת השזירה), ולכן **לא הוכח שזה הגורם היחיד** להבדל `30,52` לעומת `20,56`.

אין לבצע ״תיקון״ בהחלפת מספרי הפלט, בהסתרת Ada מן המלאי או בשינוי מאגר `main`. המשך אפשרי בביקורת סטטית הוא לתעד שדות ביניים מדויקים של בחירת החודשים מתוך המקורות וראיות קיימות, ולאחר אישור פורמלי ניתן יהיה לבצע פיתוח מתקן בענף Ada משלו, עם חזרה לתנאי קבלה מקוריים.

## קוד QA ותנאי הסמכה

- `soak/control/weave_family_divergence_v139.json`: קובעי גיבובי מקור, היסטוריית אי־ההתאמה, מודל מתמטי וגבולות מדעיים.
- `soak/runner/soak_weave_family_divergence_v139.py`: אחזור שישה קובצי מקור באמצעות Git blob SHA; מונה רק מודל סופי קטן, מאמת ש־Ada תת־קבוצה ממש, ואינו מייבא את מנועי Python או Ada.
- `soak/process_tests/test_soak_weave_family_divergence_v139.py`: 16 בדיקות, לרבות שינוי קומיט, שינוי שיטת השזירה, סגירת Issue #29 ללא תיקון, זיוף PASS וניסיון לייחס מקרה נגד קטן למבחן שנות המקור.
- `.github/workflows/soak-original-weave-family-v139.yml`: CI לקריאה בלבד, אימות קבלה של v138 ועמידה ב־`STOP_NEW_NATIVE_SOAK_DISPATCH`.

**סטטוס:** **אי־שקילות אלגוריתמית של משפחות השזירה הוכחה** במסגרת הביקורת הסטטית. **סיבתיות יחידה של אי־ההתאמה בתאריך היסוד לא הוכחה**. `main` לא שונה; `0/10,000` שנות מקור מוסמכות, `0` אלגוריתמים עצמאיים מוסמכים, והחסימה לפתיחת Soak מקורי חדש נשארת בתוקף.
