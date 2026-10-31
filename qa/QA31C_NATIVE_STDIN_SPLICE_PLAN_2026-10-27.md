# QA31C — corrected equal-length Native stdin intervention (2026-10-27)

## Evidence-first failure
- The previous exact-head run https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40555795791 completed **failure** at 6b4601c93aeacd743176731ec167900aaafd8ec6. Job 122371402162, step 6, failed at pre-execution assertion "not same-size intervention". No physical Native STEP trace nor independent QA31C audit ran; diagnostic artifact 12757122076 held only native.log.
- The signed original valid00 raw input is "0 0 0 0\n" (8 bytes), while original invalid18 is "\n" (1 byte). The originally specified equal-size/equal-newline-offset splice is impossible for that pair; do not rerun the broken workflow.

## Targeted correction, still Stage 1 QA only
- Keep signed valid00 in QA20 shard 0, and replace the experimental arm with signed invalid16 in shard 3, raw "0 1 0 x\n" (8 bytes). It shares the terminal newline offset 7, first changed byte offset 2; both were generated with the original Native IP and source Git blob 560d6aa5807a7f766213a33835cce85eab0fa40c.
- Previously verified shard-0 manifest SHA256: 782fb868a11a105550ef5af6f8f7cd39e4ba9de77d9565f7549e310549b0073a. The newly inspected original QA20 shard-3 ZIP artifact 12417633980 has ZIP SHA256 d792e4ce459769124d9055f47dc2773a44a487f260ff2302ada8371ed4450c07 and ZIP CRC PASS; manifest SHA256 3f2e81afb325a4f1e8bfee3910be6d92d2bef23145ba39a33fc355ea23a5454b.
- The complete SHA-bound Native originals are 17,387 valid00 STEP lines and 8,021 invalid16 STEP lines, total 25,408. Original invalid16's terminal output is seven "-1" values; its physical route does not reach the targeted j at (114,38).

## Preserved strict contract and limited claim
1. PyFunge 0.5-rc2 archive SHA256 e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac. Original Funge-space bytes, natural IP, stacks, and implementation must not be mutated.
2. The sham and experiment use the *same underlying signed valid00 buffer*. Only real Native read/readline return bytes are replaced at matching cursor offsets in the experiment by equal-length signed invalid16 bytes; no newline displacement or arbitrary runtime modifications. Record physical tick, pre-read IP, cursor and TOSS hash; verify first changed read and identical prior read events.
3. Replay all 25,408 physical STEP records against both original SHA-pinned traces, including original terminal outputs; store unsampled gzip traces and logs, including RED logs. Independently reject all 12/12 forged receipts; compare complete source/manifest/trace digests and read-event signatures.
4. This redesigned test is **only** a candidate for finite controlled *stdin → terminal-output* dependence. It does NOT demonstrate altered pre-j stack operand: invalid16 does not execute the target j. Keep that previous causal gap OPEN. No global source/ownership proof, no Stage1 final acceptance, no Stage2, no merge, no main changes.

## NEXT
Inspect only the new exact-head GitHub Actions run emitted from the corrected QA31C commit. If queued/in_progress, do not rerun. If failure, inspect its specific job/log and fix only the proven defect. If completed/success, download its sole QA31C artifact and independently verify ZIP SHA256/CRC, complete 25,408 Native STEP records, IO intervention and 12 hostile rejections; report only the finite output-dependence claim warranted by the evidence.
