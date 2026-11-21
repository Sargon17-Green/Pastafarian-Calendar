; DMG-only bootstrap. SM83 instructions; no host-language code linked.
SECTION "Reset entry", ROM0[$0100]
    nop
    jp Bootstrap

SECTION "Cartridge header reserved", ROM0[$0104]
    ds $4c, 0

SECTION "Invocation state", WRAM0[$C000]
wTestResult:: ds 1
wTestCase::   ds 1
wRunStatus::  ds 1
wValue::      ds 16
wAddend::     ds 16
wExpected::   ds 16
wWideInput::  ds 32
wWideCurrentByte:: ds 1
wWideBytesRemaining:: ds 1
wMulA::       ds 16
wMulB::       ds 16
wMulCurrentByte:: ds 1
wMulBitFlag:: ds 1
wMulBytesRemaining:: ds 1
wBankCarry:: ds 1
wBankBorrow:: ds 1
wBankStatus:: ds 1
wCmpStatus:: ds 1
wSignedSignA:: ds 1
wSignedSignB:: ds 1
wSignedCmpStatus:: ds 1
wSignedAddStatus:: ds 1
wSignedResultSign:: ds 1
wSignedResultLength:: ds 2
wDivisor:: ds 1
wDivRemainderLo:: ds 1
wDivRemainderHi:: ds 1
wDivQuotLength:: ds 2
wDivQuotByte:: ds 1
wDivStatus:: ds 1
wSignedDivStatus:: ds 1
wSignedDivQuotSign:: ds 1
wSignedDivRemainder:: ds 1
wVarALength:: ds 2
wVarBLength:: ds 2
wVarResultLength:: ds 2
wVarMaxLength:: ds 2
wVarIndex:: ds 2
wVarCarry:: ds 1
wVarStatus:: ds 1
wVarByteA:: ds 1
wVarByteB:: ds 1
wLeaseTable:: ds 16
wLeaseIter:: ds 1
wLeaseBank:: ds 1
wLeaseStatus:: ds 1
wOwnerRequest:: ds 1
wOwnerCount:: ds 1
wOwnerTag:: ds 1
wOwnerStatus:: ds 1
wOwnerAllocated:: ds 1
wOwnerBanks:: ds 13
wOwnerSelectIndex:: ds 1
wOwnerSelectedBank:: ds 1
wOwnerOffset:: ds 3
wOwnerByteValue:: ds 1
wOwnerCmpOwnerA:: ds 1
wOwnerCmpOwnerB:: ds 1
wOwnerCmpSignA:: ds 1
wOwnerCmpSignB:: ds 1
wOwnerCmpLenA:: ds 3
wOwnerCmpLenB:: ds 3
wOwnerCmpCursor:: ds 3
wOwnerCmpActiveSign:: ds 1
wOwnerCmpByteA:: ds 1
wOwnerCmpResult:: ds 1
wLeaseTestNext:: ds 1
wDayOffset:: ds 4
wDayCount:: ds 5
wDayExpected:: ds 5
wDayNeg:: ds 1
wPairCalcOffset:: ds 4
wPairTargetOffset:: ds 4
wWorkCalcCount:: ds 5
wWorkTargetCount:: ds 5
wWorkDistance:: ds 5
wWorkSum:: ds 5
wWorkDirection:: ds 1
wWorkExpectedCalc:: ds 5
wWorkExpectedTarget:: ds 5
wWorkExpectedDistance:: ds 5
wWorkExpectedSum:: ds 5
wWorkExpectedDirection:: ds 1
wWorkLeft:: ds 1
; Stable 16-bit test case ABI extension; never move C000-C002.
wTestCaseHi:: ds 1
wCalendarRequestedOwner:: ds 1
wCalendarRequestedBanks:: ds 1
wCalendarActive:: ds 1
wCalendarActiveOwner:: ds 1
wCalendarStatus:: ds 1
wCalendarOrdinalSign:: ds 1
wCalendarOrdinalLength:: ds 3
wCalendarUnitDelta:: ds 1
wCalendarUnitGrow:: ds 1
wCalendarUnitRemaining:: ds 3
wCalendarUnitStop:: ds 3
wCalendarUnitRollbackStop:: ds 3
wCalendarUnitNewLength:: ds 3
wCalendarUnitNewSign:: ds 1
wCalendarUnitReplacement:: ds 1
wCalendarSaveRem:: ds 16
wCalendarSaveOld:: ds 16
wCalendarSaveFold:: ds 1
wCalendarSaveNewLen:: ds 1
wCalendarSaveRollbackStop:: ds 1
; Stage1 known-year signed32 projection scratch ABI. Keep opening and closing
; gates contiguous: native fixture copies the two signed32 gates as 8 bytes.
wCalendarYearInputLen:: ds 1
wCalendarYearIndex:: ds 1
wCalendarYearTarget:: ds 4
wCalendarYearOpen:: ds 4
wCalendarYearClose:: ds 4
wCalendarYearCandidate:: ds 2
wCalendarYearOutput:: ds 2
; Stage1 bounded NEXT/PREVIOUS selected span handoff; proposed gates adjacent.
wCalendarYearProposedOpen:: ds 4
wCalendarYearProposedClose:: ds 4
wCalendarYearDirection:: ds 1
wCalendarYearSpanLen:: ds 2
; Stage1 short Equal Selection ABI: fixed 127-bit A0 and bounded 16-bit N.
wCalendarSelectValue:: ds 16
wCalendarSelectCount:: ds 2
wCalendarSelectDirection:: ds 1
wCalendarSelectRank:: ds 2
wCalendarSelectExpected:: ds 2
wCalendarSelectValueRem:: ds 2
wCalendarSelectRem:: ds 2
wCalendarSelectLimit:: ds 16
wCalendarSelectByteIndex:: ds 1
wCalendarSelectInputByte:: ds 1
wCalendarSelectMask:: ds 1
wCalendarSelectBitsRemaining:: ds 1
; Stage1 bounded i=2 five-stone transition; old input is never overwritten.
wCalendarStoneIteration:: ds 1
wCalendarStoneOld:: ds 80
wCalendarStoneOutput:: ds 80
wCalendarStoneIndex:: ds 1
wCalendarStoneRepeat:: ds 1
; Work state for iterative i=2..46, separate from caller-owned source.
wCalendarStoneScratch:: ds 80
wCalendarStoneRound:: ds 1
; First hidden drop: bounded working residue, atomic publication and scratch.
wCalendarHiddenWorking:: ds 16
wCalendarHiddenOutput:: ds 16
wCalendarHiddenRepeat:: ds 1
wCalendarHiddenRound:: ds 1
; Stage1 visible1 modular input H1,H3,H7 and atomic result.
wCalendarVisibleIteration:: ds 1
wCalendarVisibleInputs:: ds 48
wCalendarVisibleOutput:: ds 16
wCalendarVisibleWorking:: ds 16
wCalendarVisibleAccum:: ds 16
wCalendarVisibleRound:: ds 1
wCalendarVisibleIndex:: ds 1
wCalendarVisibleRepeat:: ds 1
; Stage1 hidden1..7 -> visible1 chain: private retained intermediate residues.
wCalendarHiddenRetained:: ds 112
; Stage1 visible2: retain V1 for the next recurrence.
wCalendarVisibleFirst:: ds 16
; Retained second visible residue for i3.
wCalendarVisibleSecond:: ds 16
; Retained third visible residue for i4.
wCalendarVisibleThird:: ds 16
; Retained fourth visible residue for i5.
wCalendarVisibleFourth:: ds 16
; Retained fifth visible residue for i6.
wCalendarVisibleFifth:: ds 16
; Preserve V6 while the visible recurrence continues through V46.
wCalendarVisibleSixth:: ds 16
; Seven-drop ring for D[i-1], D[i-3], D[i-7] during i=7..46.
wCalendarVisibleRing:: ds 112
wCalendarVisibleRingIndex:: ds 1
; Restore the caller's previous final output if the extended chain fails.
wCalendarVisibleSavedOutput:: ds 16

SECTION "Bootstrap", ROM0[$0150]
Bootstrap:
    di
    ld sp, $dff0
    xor a
    ld [wTestResult], a
    ld [wTestCase], a
    ld [wTestCaseHi], a
    ld [wRunStatus], a
IF DEF(STAGE1_I46_NATIVE_BENCH)
    ; Standalone i=46 ROM: never append to the accepted 9000-frame route.
    ld a, 1
    ld [$2000], a
    call RunCalendarStoneI46Bench
ELIF DEF(STAGE1_HIDDEN1_NATIVE_BENCH)
    ld a, 1
    ld [$2000], a
    call RunCalendarHidden1Bench
ELIF DEF(STAGE1_HIDDEN2_NATIVE_BENCH)
    ld a, 1
    ld [$2000], a
    call RunCalendarHidden2Bench
ELIF DEF(STAGE1_HIDDEN3_NATIVE_BENCH)
    ld a, 1
    ld [$2000], a
    call RunCalendarHidden3Bench
ELIF DEF(STAGE1_HIDDEN4_NATIVE_BENCH)
    ld a, 1
    ld [$2000], a
    call RunCalendarHidden4Bench
ELIF DEF(STAGE1_HIDDEN5_NATIVE_BENCH)
    ld a, 1
    ld [$2000], a
    call RunCalendarHidden5Bench
ELIF DEF(STAGE1_HIDDEN6_NATIVE_BENCH)
    ld a, 1
    ld [$2000], a
    call RunCalendarHidden6Bench
ELIF DEF(STAGE1_HIDDEN7_NATIVE_BENCH)
    ld a, 1
    ld [$2000], a
    call RunCalendarHidden7Bench
ELIF DEF(STAGE1_VISIBLE1_NATIVE_BENCH)
    ld a, 1
    ld [$2000], a
    call RunCalendarVisible1Bench
ELIF DEF(STAGE1_CHAIN1_NATIVE_BENCH)
    ld a, 1
    ld [$2000], a
    call RunCalendarHiddenVisible1ChainBench
ELIF DEF(STAGE1_CHAIN2_NATIVE_BENCH)
    ld a, 1
    ld [$2000], a
    call RunCalendarHiddenVisible2ChainBench
ELIF DEF(STAGE1_CHAIN3_NATIVE_BENCH)
    ld a, 1
    ld [$2000], a
    call RunCalendarHiddenVisible3ChainBench
ELIF DEF(STAGE1_CHAIN4_NATIVE_BENCH)
    ld a, 1
    ld [$2000], a
    call RunCalendarHiddenVisible4ChainBench
ELIF DEF(STAGE1_CHAIN5_NATIVE_BENCH)
    ld a, 1
    ld [$2000], a
    call RunCalendarHiddenVisible5ChainBench
ELIF DEF(STAGE1_CHAIN6_NATIVE_BENCH)
    ld a, 1
    ld [$2000], a
    call RunCalendarHiddenVisible6ChainBench
ELIF DEF(STAGE1_CHAIN46_NATIVE_BENCH)
    ld a, 1
    ld [$2000], a
    call RunCalendarHiddenVisible46ChainBench
ELSE
    call RunSelfTests
    ld a, [wTestResult]
    cp $a5
    jp nz, .done
    call RunWideTests
    ld a, [wTestResult]
    cp $a5
    jp nz, .done
    call RunMultiplyTests
    ld a, [wTestResult]
    cp $a5
    jp nz, .done
    call RunRAMBankTests
    ld a, [wTestResult]
    cp $a5
    jp nz, .done
    call RunBankedAdditionTests
    ld a, [wTestResult]
    cp $a5
    jp nz, .done
    call RunBankedSubtractionTests
    ld a, [wTestResult]
    cp $a5
    jp nz, .done
    call RunBankedComparisonTests
    ld a, [wTestResult]
    cp $a5
    jp nz, .done
    call RunSignedComparisonTests
    ld a, [wTestResult]
    cp $a5
    jp nz, .done
    call RunSignedAdditionTests
    ld a, [wTestResult]
    cp $a5
    jp nz, .done
    call RunLeaseTests
    ld a, [wTestResult]
    cp $a5
    jp nz, .done
    call RunDayCountTests
    ld a, [wTestResult]
    cp $a5
    jp nz, .done
    call RunWorkCountTests
    ld a, [wTestResult]
    cp $a5
    jp nz, .done
    call RunLengthTests
    ld a, [wTestResult]
    cp $a5
    jp nz, .done
    call RunDivisionTests
    ld a, [wTestResult]
    cp $a5
    jp nz, .done
    call RunSignedDivisionTests
    ld a, [wTestResult]
    cp $a5
    jp nz, .done
    call RunVariableAdditionTests
    ld a, [wTestResult]
    cp $a5
    jp nz, .done
    call RunOwnerLeaseTests
    ld a, [wTestResult]
    cp $a5
    jp nz, .done
    call RunOwnerByteTests
    ld a, [wTestResult]
    cp $a5
    jp nz, .done
    call RunOwnerSignedCmpTests
.done:
    ld a, [wTestResult]
    cp $a5
    jr nz, .afterLifecycle
    ld a, 1
    ld [$2000], a
    call RunCalendarInvocationTests
ENDC
.afterLifecycle:
    call calendarDateSpaghetti
.hold:
    jr .hold

INCLUDE "src/runtime/save127.asm"
INCLUDE "src/runtime/savewide256.asm"
INCLUDE "src/runtime/mul128.asm"
INCLUDE "src/runtime/mbc5.asm"
INCLUDE "src/runtime/sram_lease.asm"
INCLUDE "src/runtime/sram_owner.asm"
INCLUDE "src/runtime/owner_byte.asm"
INCLUDE "src/runtime/owner_signed_cmp.asm"
INCLUDE "src/runtime/magnitude_length.asm"
INCLUDE "src/runtime/divide_u8.asm"
INCLUDE "src/runtime/signed_divide_u8.asm"
INCLUDE "src/runtime/variable_add.asm"
INCLUDE "src/runtime/day_count32.asm"
INCLUDE "src/runtime/work_counts32.asm"
INCLUDE "src/runtime/banked_add.asm"
INCLUDE "src/runtime/banked_sub.asm"
INCLUDE "src/runtime/banked_cmp.asm"
INCLUDE "src/runtime/signed_cmp.asm"
INCLUDE "src/runtime/signed_add.asm"
INCLUDE "src/runtime/dispatcher.asm"
INCLUDE "src/runtime/ordinal_validate.asm"
INCLUDE "src/runtime/ordinal_unit.asm"
INCLUDE "src/runtime/calendar_save127.asm"
INCLUDE "src/runtime/calendar_year_projection.asm"
INCLUDE "src/runtime/calendar_year_step.asm"
INCLUDE "src/runtime/calendar_select_short.asm"
INCLUDE "src/runtime/calendar_stone_transition.asm"
INCLUDE "src/runtime/calendar_hidden1.asm"
INCLUDE "src/runtime/calendar_hidden2.asm"
INCLUDE "src/runtime/calendar_hidden3.asm"
INCLUDE "src/runtime/calendar_hidden4.asm"
INCLUDE "src/runtime/calendar_hidden5.asm"
INCLUDE "src/runtime/calendar_hidden6.asm"
INCLUDE "src/runtime/calendar_hidden7.asm"
INCLUDE "src/runtime/calendar_visible1.asm"
INCLUDE "src/runtime/calendar_hidden_visible1_chain.asm"
INCLUDE "src/runtime/calendar_hidden_visible2_chain.asm"
INCLUDE "src/runtime/calendar_hidden_visible3_chain.asm"
INCLUDE "src/runtime/calendar_hidden_visible4_chain.asm"
INCLUDE "src/runtime/calendar_hidden_visible5_chain.asm"
INCLUDE "src/runtime/calendar_hidden_visible6_chain.asm"
INCLUDE "src/runtime/calendar_hidden_visible46_chain.asm"
INCLUDE "src/tests/selftest.asm"
INCLUDE "src/tests/wide_test.asm"
INCLUDE "src/tests/mul_test.asm"
INCLUDE "src/tests/ram_test.asm"
INCLUDE "src/tests/banked_add_test.asm"
INCLUDE "src/tests/banked_sub_test.asm"
INCLUDE "src/tests/banked_cmp_test.asm"
INCLUDE "src/tests/signed_cmp_test.asm"
INCLUDE "src/tests/signed_add_test.asm"
INCLUDE "src/tests/sram_lease_test.asm"
INCLUDE "src/tests/day_count32_test.asm"
INCLUDE "src/tests/work_counts32_test.asm"
INCLUDE "src/tests/magnitude_length_test.asm"
INCLUDE "src/tests/divide_u8_test.asm"
INCLUDE "src/tests/signed_divide_u8_test.asm"
INCLUDE "src/tests/variable_add_test.asm"
INCLUDE "src/tests/sram_owner_test.asm"
INCLUDE "src/tests/owner_byte_test.asm"
INCLUDE "src/tests/owner_signed_cmp_test.asm"
INCLUDE "src/tests/calendar_invocation_lifecycle_test.asm"
INCLUDE "src/tests/calendar_year_projection_test.asm"
INCLUDE "src/tests/calendar_year_step_test.asm"
INCLUDE "src/tests/calendar_answer_select_test.asm"
INCLUDE "src/tests/calendar_stone_transition_test.asm"
INCLUDE "src/tests/calendar_stone_range_test.asm"
IF DEF(STAGE1_I46_NATIVE_BENCH)
INCLUDE "src/tests/calendar_stone_i46_native_test.asm"
ENDC

IF DEF(STAGE1_HIDDEN1_NATIVE_BENCH)
INCLUDE "src/tests/calendar_hidden1_native_test.asm"
ENDC

IF DEF(STAGE1_HIDDEN2_NATIVE_BENCH)
INCLUDE "src/tests/calendar_hidden2_native_test.asm"
ENDC

IF DEF(STAGE1_HIDDEN3_NATIVE_BENCH)
INCLUDE "src/tests/calendar_hidden3_native_test.asm"
ENDC

IF DEF(STAGE1_HIDDEN4_NATIVE_BENCH)
INCLUDE "src/tests/calendar_hidden4_native_test.asm"
ENDC

IF DEF(STAGE1_HIDDEN5_NATIVE_BENCH)
INCLUDE "src/tests/calendar_hidden5_native_test.asm"
ENDC

IF DEF(STAGE1_HIDDEN6_NATIVE_BENCH)
INCLUDE "src/tests/calendar_hidden6_native_test.asm"
ENDC

IF DEF(STAGE1_HIDDEN7_NATIVE_BENCH)
INCLUDE "src/tests/calendar_hidden7_native_test.asm"
ENDC

IF DEF(STAGE1_VISIBLE1_NATIVE_BENCH)
INCLUDE "src/tests/calendar_visible1_native_test.asm"
ENDC

IF DEF(STAGE1_CHAIN1_NATIVE_BENCH)
INCLUDE "src/tests/calendar_hidden_visible1_chain_native_test.asm"
ENDC

IF DEF(STAGE1_CHAIN2_NATIVE_BENCH)
INCLUDE "src/tests/calendar_hidden_visible2_chain_native_test.asm"
ENDC

IF DEF(STAGE1_CHAIN3_NATIVE_BENCH)
INCLUDE "src/tests/calendar_hidden_visible3_chain_native_test.asm"
ENDC

IF DEF(STAGE1_CHAIN4_NATIVE_BENCH)
INCLUDE "src/tests/calendar_hidden_visible4_chain_native_test.asm"
ENDC
IF DEF(STAGE1_CHAIN5_NATIVE_BENCH)
INCLUDE "src/tests/calendar_hidden_visible5_chain_native_test.asm"
ENDC

IF DEF(STAGE1_CHAIN6_NATIVE_BENCH)
INCLUDE "src/tests/calendar_hidden_visible6_chain_native_test.asm"
ENDC

IF DEF(STAGE1_CHAIN46_NATIVE_BENCH)
INCLUDE "src/tests/calendar_hidden_visible46_chain_native_test.asm"
ENDC
