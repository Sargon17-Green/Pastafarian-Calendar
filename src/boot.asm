; DMG-only bootstrap. SM83 instructions; never link host-language code.
; The machine-visible test signal is WRAM $C000 (A5 pass / E0 fail).

SECTION "Reset entry", ROM0[$0100]
    nop
    jp Bootstrap

SECTION "Cartridge header reserved", ROM0[$0104]
    ds $4c, 0  ; RGBFIX supplies Nintendo logo, title and checksums.

SECTION "Invocation state", WRAM0[$C000]
wTestResult:: ds 1
wTestCase::   ds 1
wRunStatus::  ds 1
wValue::      ds 16
wAddend::     ds 16
wExpected::   ds 16

SECTION "Bootstrap", ROM0[$0150]
Bootstrap:
    di
    ld sp, $dff0
    xor a
    ld [wTestResult], a
    ld [wTestCase], a
    ld [wRunStatus], a
    call RunSelfTests
    call calendarDateSpaghetti
.hold:
    jr .hold

INCLUDE "src/runtime/save127.asm"
INCLUDE "src/runtime/dispatcher.asm"
INCLUDE "src/tests/selftest.asm"
