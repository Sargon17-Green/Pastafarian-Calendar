שלב נוכחי: Stage 1 reconciliation לפני פתיחת Stage 2.

חשוב: החבילה הזאת היא LOCAL ONLY. אין להעלות אף קובץ מתוך ה-ZIP הזה ל-GitHub.

החבילה נעולה ל-HEAD:
6e8f328fe4148ea714e790a79e917a07a57036c0

מה לעשות:
1. חלץ את ה-ZIP למחשב שבו מותקן MATLAB.
2. הפעל RUN_STAGE01_RECONCILE.cmd.
3. בסיום שלח לכאן את RESULT.txt ואת ROLLING_LOG.txt מתוך:
   %USERPROFILE%\Pastafarian_MATLAB_Polski_STAGE01_RECONCILE

אם STATUS=PASS, יווצר גם:
   UPLOAD_STAGE01_RECONCILE_CORRECT.zip
ה-ZIP הזה בלבד מכיל את שלושת קבצי הפרויקט המיועדים להעלאה.

בנוסף יווצר DELETE_FROM_GITHUB.txt עם שלושת קבצי העזר שהועלו בטעות ושיש למחוק מהענף.

גם PASS אינו פותח עדיין את Stage 2; לאחר מכן נבצע אימות Stage 1 הכבד ויישוב התיעוד.
