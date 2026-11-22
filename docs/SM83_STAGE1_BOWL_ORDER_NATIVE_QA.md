# SM83 Stage1 — Native387 six-bowl order milestone

PROJECT_ID: PC-BRANCH-SM83-ASSEMBLY-GEEZ
Branch: SM83-Assembly+ግዕዝ
Base/accepted Native386: 3c7c0a14dc4ab95597e7580016556373f603c532, CI 45065393851 (18/18 completed/success, all checkout SHAs verified).
Normative recurrence: Issue #30 and pinned main README 56bc4173aae4975ded019ef5ab5a36249f1424df, J–K.

## Narrow implementation contract

The new ROMX routine CalendarBowlOrderFromResidue implements ONLY the ordering prerequisite for the next native bowl recurrence, not any bowl update. Input is a 16-byte unsigned little-endian canonical SAVE residue 1..(2^127-1) in wCalendarBowlOrderInput. The 16 input bytes are immutable. Output is an ordered six-byte permutation of identities 1..6 in wCalendarBowlOrder. An exact separate six-byte scratch buffer is used, and output is committed only after validation and completion.

- Validate active invocation and canonical residue; return status 6 for idle and 2 for invalid input/negative zero. Neither case may change published order, ordinal, owner, lease or SRAM.
- Stream all 128 bits MSB-first to compute r=R mod 720 with a 16-bit remainder. Invariant: at the start of each bit R<720, and after doubling plus the bit the temporary remainder <=1439, hence one conditional subtraction by 720 is sufficient.
- Set zero-based lexicographic rank (r-1) mod 720; notably r=0 means rank 719, not rank 0.
- Unrank the six positions using divisors 120,24,6,2,1,1 and removal from a six-ID availability table. Publish six bytes atomically. This is independent of the canonical golden fixture table.
- No ROM0 code is added; all code is in ROMX BANK[1]. Default Native370/9000 route remains intact.

## Independent oracle and new Native gate

- Host/static: tests/test_sm83_stage1_bowl_order_abi.py checks all 720 permutations against Python lexicographic enumeration, 1,509 residues against mathematical modulo 720, maximum residue M, source boundaries and ABI structural invariants. This is not Native PASS.
- Isolated Native387: src/tests/calendar_bowl_order_native_test.asm and tests/test_rom_bowl_order.py check rank boundaries 1,2,720,721,M plus independently derived V46, immutable source and output on invalid/idle, negative zero, owner/lease/SRAM sentinel, and cleanup.
- New workflow job dmg-bowl-order-native builds with RGBDS v1.0.4; checks ROM_HEADER, actual ROM0 free>=10 and default 370/9000, then runs real PyBoy bounded to 30,000 frames for A5/387/40. No manual duplicate dispatch.
- Acceptance requires that job completed/success at its exact commit SHA, with checkout SHA and log evidence; full 19/19 regression gate required before calling this first order milestone accepted. No Native387 acceptance asserted by this source commit.

## Remaining Stage1 work (not claimed)

Implement six simultaneous native bowl updates for each i=1..46 using the six-bowl PREVIOUS snapshot, direct pours for q=1..3, and canonical SAVE on the outputs; preserve orderAt46. Implement the 12 post-stirs using retained S_r=SAVE(sum(previous six bowls)+149r) BOTH for rank and u. Add independent differential rejection of historical raw-sum mutant, exact source-derived c,t Native checkpoints, and finally A0/direction for seals 10/11/12. Do not mark Stage1 accepted, make a full date claim, merge, update main or enter Stage2.
