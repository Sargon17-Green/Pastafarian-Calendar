# SM83 Stage1 gate-gap primitive — Native394 contract

Project: PC-BRANCH-SM83-ASSEMBLY-GEEZ  
Canonical source: Pastafarian-Calendar main README, commit 56bc4173aae4975ded019ef5ab5a36249f1424df, sections O–R.

## Purpose and boundary

Implement one source-derived gate gap on the SM83. This is the first executable primitive for the already-authorized Stage1 year/gate work. It does not yet build the complete gate stream, enumerate candidate years, select year 5000, or implement NEXT/PREVIOUS. Stage1 remains open.

## Normative rule

For positive n, compute the sauce for (F,F+n); for negative n, compute the sauce for (F,F-n). In either direction, select with bowl 1, seal 1, and N=922. The gate gap is 41 plus the selected rank, so the only valid output range is 42..963.

The canonical source has no 512-step limit. The current Stage1 implementation deliberately adopts the existing Host year-path oracle's bounded horizon: n=1..512. Values outside this bound fail closed; this is an implementation/resource limit, not a change to the calendar rule.

## Native ABI

- Preconditions: an active calendar invocation, a valid owner/ordinal lease, and a non-negative-zero ordinal.
- Inputs: 16-bit gap index n in 1..512; direction byte 1=positive, 2=negative.
- Pair used internally: calculation offset 0 from F; target offset +n or -n, encoded as signed 32-bit little-endian.
- Pipeline: CalendarBowlTrace46, CalendarBowlPostStirs12, then CalendarBowlAnswerShortRank with bowl=1, seal=1, count=922.
- Output: 16-bit gap = rank+41. Publish only after the complete pipeline and rank-range validation succeed.
- Status: 0 success, 2 invalid input/ordinal/result, 6 idle invocation.
- Preserved caller state: pair calculation/target offsets, gap index/direction, answer-input bowl/seal, select count and select direction. The sauce trace and answer result fields are intentional outputs/scratch.
- Failure is atomic for the published gap result; invalid/idle calls leave it unchanged. No owner lease or SRAM payload mutation is permitted.

## Independent oracle and differential test

The Host oracle is the Python integer implementation in test_sm83_stage1_sauce_oracle.py and test_sm83_stage1_selection_oracle.py. The Native394 PyBoy script compares the complete seal-1 answer flow (A0, direction, rank, accepted A_k) and the final gap against that oracle.

Valid Native vectors: n=1 positive, n=1 negative, n=512 positive, n=512 negative. Negative and positive paths are independently computed from F. The Native harness also tests n=0, n=513, directions 0 and 3, negative-zero ordinal, idle calls, unchanged pair offsets and answer inputs, and owner/lease/SRAM sentinels.

The isolated ROM is capped at 120,000 frames. The default Native370 ROM contract and its 9,000-frame limit remain unchanged. ROM0 free space must remain at least 10 bytes. The new artifact must include the ROM, MAP and SYM.

## Subsequent work (not part of Native394 acceptance)

1. Generate a bounded signed gate stream from F, preserving exact positive/negative gap semantics and checking signed-32 overflow.
2. Enumerate year candidates in the 252..5778-day window, require at least six gaps, sort by (length, opening gate), and apply seal 10 to select the year containing c.
3. Implement NEXT with seal 11 and PREVIOUS with seal 12, using the prior closing/opening gate respectively.
4. Differential-test candidate enumeration and the bounded year walk against the independent Host oracle, including resource/lease invariants.

No Stage2, main/merge, or release is authorized or performed by this change.
