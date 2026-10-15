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

SECTION "Bootstrap", ROM0[$0150]
Bootstrap:
    di
    ld sp, $dff0
    xor a
    ld [wTestResult], a
    ld [wTestCase], a
    ld [wRunStatus], a
    call RunSelfTests
    ld a, [wTestResult]
    cp $a5
    jr nz, .done
    call RunWideTests
    ld a, [wTestResult]
    cp $a5
    jr nz, .done
    call RunMultiplyTests
    ld a, [wTestResult]
    cp $a5
    jr nz, .done
    call RunRAMBankTests
    ld a, [wTestResult]
    cp $a5
    jr nz, .done
    call RunBankedAdditionTests
    ld a, [wTestResult]
    cp $a5
    jr nz, .done
    call RunBankedSubtractionTests
    ld a, [wTestResult]
    cp $a5
    jr nz, .done
    call RunBankedComparisonTests
.done:
    call calendarDateSpaghetti
.hold:
    jr .hold

INCLUDE "src/runtime/save127.asm"
INCLUDE "src/runtime/savewide256.asm"
INCLUDE "src/runtime/mul128.asm"
INCLUDE "src/runtime/mbc5.asm"
INCLUDE "src/runtime/banked_add.asm"
INCLUDE "src/runtime/banked_sub.asm"
INCLUDE "src/runtime/banked_cmp.asm"
INCLUDE "src/runtime/dispatcher.asm"
INCLUDE "src/tests/selftest.asm"
INCLUDE "src/tests/wide_test.asm"
INCLUDE "src/tests/mul_test.asm"
INCLUDE "src/tests/ram_test.asm"
INCLUDE "src/tests/banked_add_test.asm"
INCLUDE "src/tests/banked_sub_test.asm"
INCLUDE "src/tests/banked_cmp_test.asm"
