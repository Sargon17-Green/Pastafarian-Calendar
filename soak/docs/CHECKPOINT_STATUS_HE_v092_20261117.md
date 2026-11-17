# נקודת שחזור v092 — שימור מקור מחוץ ל־Actions artifacts עבר אימות הורדה

**תאריך:** 17.11.2026  
**מאגר:** Sargon17-Green/Pastafarian-Calendar  
**ענף עבודה יחיד:** `qa/soak-readiness-20261114`  
**קומיט QA הבסיסי שהפעיל את הגיבוי:** `d5cc19d508d3d5fc8cbab378fc96b1f20b35bfed`  
**`main` נבדק:** `56bc4173aae4975ded019ef5ab5a36249f1424df` — לא שונה.

## 1. גיבוי שבעה ארכיוני מקור — PASS לאחר שחזור מלא

GitHub Actions [הרצת v091 מספר 44025733999](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44025733999), commit `d5cc19d5`, הסתיימה `completed/success`, job `133845500277`, ללא צעדי כשל.

שימור הראיות בוצע ב־**Draft GitHub Release**, מזהה `448191573`, `tag_name=soak-original-fct-source-1015-1021-v091`, עם יעד `e812dc5780e78b2e03fa07fa9c4b125ea6bbae59` (קומיט בקשת השימור הראשונה, שנשאר אב קדמון של ניסיון השחזור). סטטוס הטיוטה הוא `draft=true`; לא בוצע פרסום ציבורי. [קישור לטיוטת השימור — זמין לבעלי הרשאת גישה](https://github.com/Sargon17-Green/Pastafarian-Calendar/releases/tag/untagged-27b266c190c1a7ea0fb3).

| ordinal | Actions artifact | Release asset | SHA-256 של ZIP המקור |
|---:|---:|---|---|
| 1015 | 14186295655 | source-1015.zip | f87b2e925b4a400cff2e2469be5b873b66c89ca35498e8fcda1090ab55d5d390 |
| 1016 | 14264392351 | source-1016.zip | 91985794e9bb8e3c6995aa5634d684872c60aae544eaf780b668797d86557eb9 |
| 1017 | 14273257274 | source-1017.zip | 878b965960662aa27e824fd8f23a02c5d603b57f81ab698cb12ab02465a2e3e4 |
| 1018 | 14277208379 | source-1018.zip | 329afd1e408c43dfadf96b4ddd844696b59f22a63b786e663413950013c3fb0c |
| 1019 | 14277754738 | source-1019.zip | 75d930af3c8d0c5bfd80d85f2f6377dda6d9d25c3d4a8791335b219248bfecaf |
| 1020 | 14280447591 | source-1020.zip | 706a075b6192a8b11a8992c42d3ec5e2a076c135c06685b93e9b28758f992265 |
| 1021 | 14281261657 | source-1021.zip | b7f250a98aea07acb4a78bf074e75c5f72d950f00a1d32d7bc81c6eb8c464b32 |

ה־Release כולל **שמונה נכסים**: שבעת קובצי ה־ZIP המקוריים ו־`source-manifest-v091.json` (1,678 בתים). מיד לאחר ההעלאה הורדו מחדש **כל השמונה**, הושוו byte-for-byte לקובצי המקור, ונבדקו SHA-256. הלוג מכיל את הסמן `V091_EIGHT_DRAFT_RELEASE_ASSETS_VERIFIED_BYTE_IDENTICAL` וכן `V091_DRAFT_RELEASE_PERSISTENT_SOURCE_BACKUP_PASS`.

מבחן השימור אינו מריץ כלל `F(c,t)` חדש. המאגר נשאר המקור לנעילת ה־SHA ולבדיקות המקור; טיוטת Release משמרת בתי ZIP מעבר למחיקת Actions artifacts הרגילה, אך **אינה גיבוי במערכת עצמאית** או הבטחה שהקבצים לא יימחקו ידנית.

## 2. ממצאי הכשלים והתיקון

- [ניסיון ראשון 44025203953](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44025203953): `failure` לפני הורדת ZIP, עקב שם משתנה סביבה שגוי ל־`GH_TOKEN`. שער 10/10 עבר, לא נוצר Release.
- [ניסיון שני 44025486727](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44025486727): `failure` בשלב העלאת ה־Release אחרי 12/12 בדיקות והרצת ביקורת 7/7 על ZIP המקור. נוצרה טיוטת Release ללא נכסים. GitHub CLI לא הצליח לאתר טיוטת Release לפי tag (למרות `tag_name`).
- **תיקון סופי:** שאילתת Release לפי מזהה מספרי `448191573`, העלאת נכסים דרך API, והורדה חוזרת באמצעות API. הקוד מאשר בדיוק קובץ בקשה **חדש אחד** בענף QA גם בניסיונות תיקון. [ניסיון 44025733999](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44025733999) `completed/success`. אין לשחזר את שתי הריצות הכושלות או להסיק כישלון על מקור התאריכים.

קבצים שנוצרו/תוקנו:
- `soak/runner/preserve_original_artifacts_v091.py`
- `soak/tests/test_preserve_original_artifacts_v091.py` — 12 בדיקות שער
- `.github/workflows/soak-source-archive-preflight-v091.yml`
- `.github/workflows/soak-preserve-original-artifacts-v091.yml`
- `soak/control/original_archive_requests/source-1015-1021-v091[-retry01|-retry02].json`

## 3. תמונת מצב מדעית

- **14** ימי תאריך מקוריים תואמים בחמשת שדות התאריך, **7** מקטעי Python מקוריים בני יומיים שעברו בדיקות קליטה ושחזור ב־CrashStore.
- המקורות שנבדקו בפועל: `REF-41` Python+Türkçe ו־`PROD-KT-CY` Kotlin+Cymraeg, באותו `c=-15055671`, השנה המקורית 5000, מקטעים 1015–1021. אין הסמכת עצמאות אלגוריתמית בין הממירים; Kotlin מפיק אינדקסי שמות ולא מחרוזות שמות.
- `REF-24` JavaScript+Interlingue נעול תחבירית מ־v016 בלבד; אין להציגו כמי שעבר את מבחני ה־F(c,t) המקוריים בהיקף הנוכחי.
- **0** שנות Python מקוריות מלאות, **0** מקטעי Kotlin שנתיים נקלטו, **0/10,000** שנות soak אושרו.
- ה־Windows scheduler לשני עובדים ולשחזור לאחר קריסה טרם הוסמך לעומס מקור מלא; מחשב Windows **לא הופעל בסבב v091**.
- מפקד 58 reference +‏ 20 production/candidate +‏ 10 language triage מכיל קטלוגים **חופפים**; אין לסכם אותו ל־88 ממירים עצמאיים.

## 4. המשך ישיר

1. לזהות ברשימת הממירים המוכנים את מנועי המקור העצמאיים, תוך הבדלה בין קוד מקור מקורי, נגזרת, wrapper וממיר חלקי. להתחיל במפקד `pastafarian_converter_inventory_v20_20261114.json` (קיים בספריית המשתמש) ולאמת כל הכרעת מקור מול GitHub.
2. לבחון שימור **אצל ספק עצמאי נוסף** לפני הסתמכות על Release יחיד.
3. לבנות QA דו־נתיבי Windows עם מדיניות no-kill, כימות RAM/CPU, תיקיית הרצה בבעלות הפרויקט, והחזרת ראיות ללא התקנות קבועות.
4. רק אחרי שערי המקור והשחזור: להתחיל שנת מקור שלמה בפועל. לא להתחיל כעת את הרצת 10,000 השנים.

**סמן המשך:** `PASTAFARI_ORIGINAL_NATIVE_YEAR_SOAK | CHECKPOINT=v092 | ARCHIVE=7_ZIPS_RELEASE_DRAFT_RESTORED_8_OF_8 | SOURCE_DAYS=14 | CRASHSTORE_CHUNKS=7 | FULL_YEARS=0 | NEXT=CATALOG_DEDUP_SOURCE_ENGINE_LINEAGE_AND_WINDOWS_READINESS | NO_MAIN=true`.
