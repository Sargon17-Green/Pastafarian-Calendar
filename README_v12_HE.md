# PC-BRANCH-ADA-TELUGU — QA v12: Stage41 build provenance + streaming child capture

**בסיס:** `1160096aa847c54cbef27c232771ce1549d7ba8f` (`Ada+తెలుగు`)  
**ענף QA:** `qa/issue29-ada-gmp-build-stream-v176`  
**תחולה:** build/link בלבד; observer אינו מופעל.

## מה מוסיף v12

1. Runner Python ללא shell שמוודא parent SHA, branch, tree נקי ו־Git blob locks של קובצי המקור וה־GPR.
2. התקנת GNAT/GPRBuild/GNATCOLL GMP מזוהה בגרסאות מפורשות.
3. איתור `gnatcoll_gmp.gpr` מתוך רשימת קובצי החבילה, קביעת `GPR_PROJECT_PATH` מפורש ושמירת נתיב מוחלט, גודל ו־SHA-256.
4. `gprbuild -v` עם linker trace (`-Wl,-t`) ו־link map; stdout/stderr של הבנייה נשמרים בקבצים נפרדים.
5. איתור קלט GMP ממשי מתוך trace/map ושמירת נתיב מוחלט ו־SHA-256. אם לא נמצא קלט כזה, runner נכשל ולא מכריז link proof.
6. SHA-256 וגודל של קובץ ELF שנבנה, יחד עם inventory של מקורות Ada ויחידות הקומפילציה.
7. direct-child capture באמצעות `selectors`, byte streams נפרדים, תקרת גודל בזמן הזרמה, timeout והרג process group.

## מה אינו עושה

- אינו מפעיל `stage41_remote_seventeen_observer`.
- אינו קורא `Calendar_Date`, אינו מפעיל full-F ואינו מריץ Soak.
- אינו משנה parser, runner או קוד ייצור.
- אינו משנה את 42 תנאי ההשבתה ואינו פותח Stage42.

## הרצה מקומית

```sh
sh RUN_QA_v12.sh
```

הפקודה מריצה 9/9 בדיקות helper ו־halt-gate באמצעות Python fixture children וקובץ workflow סינתטי. היא אינה דורשת GNAT.

ה־workflow הייעודי בענף QA מפעיל `--build-only` על Ubuntu 24.04. הצלחה תיחשב ראיית **build/link בלבד** רק לאחר בדיקת run, job, logs, SHA, artifact ו־manifest. אין להסיק ממנה Ada Native PASS.

## מדיניות admission

המלצת ASCII byte-exact וסקירת 18 נקודות העיוורון מתועדות ב־`QA_REVIEW_v12_HE.md`. זו המלצה בלבד; לא נעשה שינוי מדיניות או parser.