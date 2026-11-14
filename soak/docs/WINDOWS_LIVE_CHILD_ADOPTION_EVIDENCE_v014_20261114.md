# ראיות Windows v014 — אימוץ תהליך חי אחרי קריסת המנהל

**תוצאה:** `LIVE_CHILD_ADOPTION_PASS` · **תאריך:** 2026-11-14 · **מצב:** תהליך דמה בלבד, ללא ממירים וללא soak.

הסקריפט `RUN_PASTAFARI_SOAK_LIVE_ADOPTION_v014.py` הועלה לערוץ Drive OTR לאחר בדיקת SHA-256 של בתיו מול הקובץ שהועלה. SHA-256 המקור: `5542962b0ad54142d2f7b6fa5bc29b19b0b0f85fdfa97667ab4567550a851d34`.

תוצאה מגובה בלוג Gmail של ההרצה (האסמכתא נשמרת בערוץ ההרצה; אין לכלול פרטי חשבון אישיים בפרסום ציבורי):

| שדה | ערך |
|---|---|
| status | `LIVE_CHILD_ADOPTION_PASS` |
| supervisor_crash_exit | `86` |
| children_started | `1` |
| peak_active_children | `1` |
| live_adopted | `true` |
| new_processes_launched after restart | `0` |
| same_pid | `5264` |
| same_creation_id | `134391622680379820` |
| output.verified_rows | `10` |
| output.output_sha256 | `8cb97a430fc2a120241062e613177f1cbdb5bd00e06b10dbad9882ebb86c2841` |
| cpu_guard.state | `WORKER_OWNS_CPU_JOB` |
| cpu_guard.in_job | `true` |
| cpu_guard.hard_cap_flags | `5` (`ENABLE` + `HARD_CAP`) |
| cpu_guard.hard_cap_rate | `500` (5% מכלל המעבדים) |
| cpu_guard.priority_readback | `16384` (`BELOW_NORMAL`) |
| free_ram_bytes | `731533312` |
| killed_for_slowness | `0` |
| real_converters_launched | `0` |
| verified_comparisons_completed | `0` |
| owned_scratch_cleaned | `true` |
| evidence_zip_sha256 | `ce9b2fa3994ab1c5541dcc8e1be85441a2e79bd584eda52114fd663139e5bb8f` |

הבדיקה מראה שהילד ששרד את סיום המנהל המשיך לכתוב פלט, ושהמנהל החלופי התקשר *לוגית* באמצעות קבצים ושייך אותו לזהות מערכת ההפעלה (PID וזמן יצירה). היא אינה מוכיחה אפשרות להתחבר מחדש ל-stdout של ממיר שאינו משתף פעולה, ואינה מוכיחה שמנהל חדש יוכל לשחזר מצב ביניים שאינו כתוב בדיסק.

**תקרת CPU:** נמצא שיוך Job Object עצמאי לילד, והגדרת 5% נקראה בחזרה. לא נמדד כאן עומס CPU רציף, ולכן אין לטעון שמדובר במדידת אכיפה. המבחן הנפרד v015 נועד לכך.

**מגבלות נוספות:** לא אירעה הפסקת חשמל, לא היה אתחול Windows, ולא נבדקה יצירת תהליך ממיר אמיתי. תנאי הסיום של 10,000 השנים וכל הממירים עדיין לא קרוב להוכחה. אין לשנות `main`.
