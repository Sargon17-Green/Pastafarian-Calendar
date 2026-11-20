# المرحلة 16 — إزالة عنصر حسب موضعه من تسلسل قصير

שלב 15 התקבל על סמך Native ריצה 44485784628 (completed/success), artifact 14510511996 SHA256 `0ddbaea1242937c405e9bdee23e81f512e22c64b610123f99a3aa463ace16842`, ZIP CRC וביקורת בלתי תלויה עם שלוש זהויות Git blob, שבע תוצאות, שתי חזרות, ארבע בדיקות שליליות ובקרת השחתת oracle. דוח: `evidence/stage15_factorial_acceptance_2026-11-19.json`. אין שינוי main.

## חוזה הפעולה

במקור הנורמטיבי, פעולה 50 מוחקת תא במיקום מפורש מתוך רצף קטן ומחזירה את התא שנבחר ואת הרצף הנותר. ההמשך העצמאי יהיה פעולת ייצור 33 (לא העתקת גוף פעולה 50).

- **קלט:** tuple בן שני תאים `[sequence,pos]`; `sequence=[n,x1,...,xn]` טבלה ישירה עם תא אורך, `1≤n≤6`, ותא `pos` מספר קטן בתחום `1..n`. כל ערך `xi` בתרחישי Native יהיה מספר FALSE קטן בתחום `1..6`; חזרות מותרות.
- **פלט:** tuple בן שני תאים `[chosen,newSequence]`, כאשר `chosen=x_pos` ו־`newSequence=[n−1,x1,...,x_(pos−1),x_(pos+1),...,xn]`. הסדר נשמר והבחירה לפי אינדקס, לא לפי ערך.
- **זהויות:** `len(newSequence)=n−1`; הכנסת `chosen` בחזרה במקום `pos` משחזרת את הרצף בדיוק; קלט אינו משתנה; חזרה על אותה קריאה דטרמיניסטית. ב־`n=1`, הפלט הוא `[x1,[0]]`.
- **גבולות פסולים לייצור:** `n=0`, `n=7`, `pos=0`, `pos=n+1`, tuple חסר רצף או חסר מיקום. הם אמורים להידחות עם יציאה שאינה אפס; אין טענה שהמקור הנורמטיבי דוחה אותם באותה דרך.
- **Oracle בלתי תלוי:** `tools/stage16_sequence_remove_design_oracle.py` בודק exhaustively את כל `∑(n×n!)=5039` זוגות של תמורות `1..n` ומיקומים `1..n`, וגם מייצר 12 מקרי עוגן ל־Native, כולל ערכים חוזרים. תוצר `evidence/stage16_sequence_remove_design_oracle_2026-11-19.json`, SHA256 `0df1717f8105d87c198c4750ff4aa14f48a909e3cf1bc3036d9f6cf9fe977eea`.

## שערי הקבלה הבאים

לממש op33 ב־FALSE באופן עצמאי באמצעות פעולות טבלה קיימות, ללא טעינת המקור הנורמטיבי בבדיקת Native. להפיק fixture בן לפחות 12 עוגנים, בדיקות אורכי קלט ופלט ואי־שינוי מקור, שתי קריאות חוזרות, שש צורות פסולות, ומוטנט ציפייה שיוצא בקוד 1. לאחר QA מקומי תחום, להריץ CI מקור־נעול עם מפרש FALSE המקורי `eb3135565a8670cced3f6bbca4dbf7b014c45634`; לקבל את השלב רק לאחר completed/log, ארטיפקט עם CRC/SHA וביקורת עצמאית המסוגלת לדחות השחתת oracle.

**STAGE16_DESIGN_COMPLETE; IMPLEMENTATION_NOT_STARTED; NATIVE_NOT_RUN; NOT_ACCEPTED.**

## 2026-11-20 — Stage16 bounded layout scope clarification

The Stage16 input is a pointer to exactly **two allocated cells** [sequence_pointer,position]. A negative value in either allocated field represents an explicit missing-field sentinel. Supported test values are -1, -2, -7. The sequence pointer must refer to a fully allocated [n,x1,...,xn] table, with 1<=n<=6 and 1<=position<=n. Valid output and the 5039 independent mathematical cases remain unchanged.

Physically truncated tuple memory, dangling/invalid pointers and undersized sequence allocations are **OUT OF SCOPE**, cannot be safely detected by the untagged layout and MUST NOT be reported as rejected or memory-safe. The 10 invalid Native probes cover 4 numeric limits and 6 sentinel values; an additional mutant probes an intentionally incorrect result. Run the exact-source Native gate and a NEW independent artifact audit before marking Stage16 accepted within this bounded contract. No Stage17 and no main/merge until evidence is checked.
