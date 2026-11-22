; Stage1 isolated Native389 initial bowls; two independent 96-byte postconditions.
SECTION "Calendar bowl init Native389 test", ROMX, BANK[1]
RunCalendarBowlInitBench::
    call SRAMEnable
    call LeaseResetAll
    xor a
    ld [wCalendarActive], a
    ld [wCalendarActiveOwner], a
    ld [wTestResult], a
    ld a, 1
    ld [wTestCaseHi], a
    ld a, 133
    ld [wTestCase], a

    ld hl, wCalendarBowlsOld
    ld b, 96
    ld a, $5a
.idleFill:
    ld [hli], a
    dec b
    jr nz, .idleFill
    call CalendarBowlsInitialize
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ld hl, wCalendarBowlsOld
    ld b, 96
.idleCheck:
    ld a, [hli]
    cp $5a
    jp nz, .fail
    dec b
    jr nz, .idleCheck

    ld a, 70
    ld [wCalendarRequestedOwner], a
    ld a, 1
    ld [wCalendarRequestedBanks], a
    call CalendarInvocationBegin
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, 3
    ld [$4000], a
    ld a, $0a
    ld [$0000], a
    ld a, $6e
    ld [$a000], a

    ld hl, .case1
    call .runCase
    jp nz, .fail
    ld hl, .case2
    call .runCase
    jp nz, .fail

    ld a, 1
    ld [wCalendarOrdinalSign], a
    call CalendarBowlsInitialize
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    ld hl, wCalendarBowlsOld
    ld de, .case2Expected
    ld b, 96
    call .check
    jp nz, .fail
    xor a
    ld [wCalendarOrdinalSign], a

    ld a, [wCalendarActive]
    cp 1
    jp nz, .fail
    ld a, [wCalendarActiveOwner]
    cp 70
    jp nz, .fail
    ld a, [wLeaseTable+3]
    cp 72
    jp nz, .fail
    ld a, 3
    ld [$4000], a
    ld a, [$a000]
    cp $6e
    jp nz, .fail

    call CalendarInvocationAbort
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, [wLeaseTable+3]
    or a
    jp nz, .fail
    ld a, 3
    ld [$4000], a
    ld a, [$a000]
    or a
    jp nz, .fail
    call CalendarBowlsInitialize
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ld hl, wCalendarBowlsOld
    ld de, .case2Expected
    ld b, 96
    call .check
    jp nz, .fail

    ld a, $a5
    ld [wTestResult], a
    ret

.runCase:
    ld de, wPairCalcOffset
    ld b, 4
    call .load
    ld de, wPairTargetOffset
    ld b, 4
    call .load
    push hl
    call CalendarBowlsInitialize
    pop de
    ld a, [wCalendarStatus]
    or a
    jr nz, .bad
    ld hl, wCalendarBowlsOld
    ld b, 96
    jp .check
.load:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .load
    ret
.check:
    ld a, [de]
    cp [hl]
    jr nz, .bad
    inc de
    inc hl
    dec b
    jr nz, .check
    xor a
    ret
.bad:
    ld a, 1
    or a
    ret
.fail:
    ld a, $e0
    ld [wTestResult], a
    ret

.case1:
    db $00,$00,$00,$00,$00,$00,$00,$00
.case1Expected:
    db $41,$56,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $e3,$13,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $a7,$6a,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $ed,$0c,$0b,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $95,$6a,$0e,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $df,$19,$1d,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

.case2:
    db $00,$00,$00,$80,$ff,$ff,$ff,$7f
.case2Expected:
    db $85,$48,$01,$00,$54,$0b,$00,$00,$19,$00,$00,$00,$00,$00,$00,$00
    db $13,$fd,$01,$00,$ec,$10,$00,$00,$24,$00,$00,$00,$00,$00,$00,$00
    db $03,$41,$04,$00,$e0,$1c,$00,$00,$31,$00,$00,$00,$00,$00,$00,$00
    db $b5,$bd,$0a,$00,$70,$34,$00,$00,$40,$00,$00,$00,$00,$00,$00,$00
    db $09,$01,$0e,$00,$5c,$43,$00,$00,$51,$00,$00,$00,$00,$00,$00,$00
    db $3f,$6e,$1c,$00,$a4,$6a,$00,$00,$64,$00,$00,$00,$00,$00,$00,$00
