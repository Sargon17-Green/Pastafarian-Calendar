# Stage51 PATCH25 — वास्तविक prefix-occurrence month-day

Branch: \`TypeScript+मराठी\`, based on Stage50 at \`edeb261a0c950df80b3a4e5a9bbae5441e655558\`.

Contract: Stage50 \`OldContiguousMonthDayGuess\` remains unmodified. Stage51 runs the entire Stage50 chain through an isolated owner, then counts occurrences of the selected month from year day 1 through the target year day **inclusive**; there is no assumption that month days are adjacent. Reuse the old guessed value only when equal. Do not invent any additional Bowl/Sauce question; preserve exact Stage49 legal weaving and native Bowl4 Seal32. Caller state must remain untouched on any failed predecessor, while retry is allowed. Stage54 final date remains blocked.

Check the small witness \`[1,2,1,2,1,2,1,3,2,3,3,3,3]\`: on day 13, month 3 historical=6, corrected=5; on day 9, month 2 corrected=4, old=8. Test bounded independent seeded dispersed sequences (512 families, 24,064 day checks); test real Year5000 complete native chain (5,349 days), fault rollback/retry, duplicate-owner rejection, and historical 25th EXPECTED_RED retention.

Required acceptance: \`npm run typecheck\`, \`npm test\` including Stage51 guards/properties, 25 archived intentional reds, frozen name lock, and both GitHub Actions jobs SUCCESS on the **new SHA**. This commit is an implementation checkpoint, not automatic administrative Stage51 closure. No main merge and no Stage52 opening before verified Stage51 closure.
