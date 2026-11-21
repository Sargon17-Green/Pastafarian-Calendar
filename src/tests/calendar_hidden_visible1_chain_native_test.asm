; Native380 tests the REAL chained hidden1..7 plus visible1 routines.
SECTION "Calendar hidden-visible chain Native benchmark", ROMX, BANK[1]
RunCalendarHiddenVisible1ChainBench::
    call SRAMEnable
    call LeaseResetAll
    xor a
    ld [wCalendarActive], a
    ld [wCalendarActiveOwner], a
    ld a, 1
    ld [wTestCaseHi], a
    ld a, 123
    ld [wTestCase], a ; previous case379
    ld hl, wCalendarVisibleOutput
    ld b, 16
    ld a, $5a
.fill:
    ld [hli], a
    dec b
    jr nz, .fill
    call CalendarHiddenVisible1Chain
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ld hl, wCalendarVisibleOutput
    ld b, 16
.initialIdle:
    ld a, [hli]
    cp $5a
    jp nz, .fail
    dec b
    jr nz, .initialIdle

    ld hl, wPairCalcOffset
    ld b, 8
    xor a
.zeroOffsets:
    ld [hli], a
    dec b
    jr nz, .zeroOffsets
    ld a, 70
    ld [wCalendarRequestedOwner], a
    ld a, 1
    ld [wCalendarRequestedBanks], a
    call CalendarInvocationBegin
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, 3
    call SRAMSelectBank
    ld a, $6e
    ld [$a000], a

    call CalendarHiddenVisible1Chain
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld hl, wCalendarHiddenRetained
    ld de, .hiddenExpected
    ld b, 112
.checkSeven:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc de
    inc hl
    dec b
    jr nz, .checkSeven
    ld hl, wCalendarVisibleOutput
    ld de, .visibleExpected
    ld b, 16
.checkVisible:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc de
    inc hl
    dec b
    jr nz, .checkVisible
    ld hl, wCalendarVisibleInputs
    ld de, .selectedExpected
    ld b, 48
.checkSelected:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc de
    inc hl
    dec b
    jr nz, .checkSelected
    ld hl, wCalendarStoneOld
    ld de, RunCalendarStoneTransitionTests.initial
    ld b, 80
.checkSeed:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc de
    inc hl
    dec b
    jr nz, .checkSeed
    ld hl, wPairCalcOffset
    ld b, 8
.checkOffsets:
    ld a, [hli]
    or a
    jp nz, .fail
    dec b
    jr nz, .checkOffsets
    ld a, [wLeaseTable+3]
    cp 72
    jp nz, .fail
    ld a, 3
    call SRAMSelectBank
    ld a, [$a000]
    cp $6e
    jp nz, .fail

    ; Noncanonical negative zero cannot change the visible publication.
    ld a, 1
    ld [wCalendarOrdinalSign], a
    call CalendarHiddenVisible1Chain
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    xor a
    ld [wCalendarOrdinalSign], a
    ld hl, wCalendarVisibleOutput
    ld de, .visibleExpected
    ld b, 16
.checkRejected:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc de
    inc hl
    dec b
    jr nz, .checkRejected

    call CalendarInvocationAbort
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, [wLeaseTable+3]
    or a
    jp nz, .fail
    ld a, 3
    call SRAMSelectBank
    ld a, [$a000]
    or a
    jp nz, .fail
    call CalendarHiddenVisible1Chain
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ld hl, wCalendarVisibleOutput
    ld de, .visibleExpected
    ld b, 16
.checkIdle:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc de
    inc hl
    dec b
    jr nz, .checkIdle
    ld a, 124
    ld [wTestCase], a ; Native380
    ld a, $a5
    ld [wTestResult], a
    ret
.fail:
    ld a, $e0
    ld [wTestResult], a
    ret
.hiddenExpected:
    db $58,$0c,$f9,$0c,$e6,$70,$09,$e4,$25,$3c,$27,$5a,$6a,$d6,$d1,$59
    db $2d,$6d,$67,$8f,$50,$17,$59,$88,$ba,$34,$9c,$cd,$f5,$78,$ef,$08
    db $74,$96,$da,$ec,$5b,$2a,$ea,$ed,$dd,$ca,$27,$75,$76,$2e,$38,$12
    db $57,$10,$ec,$22,$40,$c2,$de,$71,$18,$37,$cd,$a0,$6b,$9f,$5b,$7d
    db $60,$3e,$d4,$70,$be,$73,$9f,$af,$24,$a8,$c1,$6e,$bc,$1c,$17,$3d
    db $c0,$75,$48,$de,$5c,$af,$64,$02,$31,$07,$7a,$b3,$ea,$81,$55,$37
    db $c2,$d2,$f8,$92,$86,$94,$8c,$d4,$87,$20,$81,$1d,$c2,$32,$a3,$04
.selectedExpected:
    db $58,$0c,$f9,$0c,$e6,$70,$09,$e4,$25,$3c,$27,$5a,$6a,$d6,$d1,$59
    db $74,$96,$da,$ec,$5b,$2a,$ea,$ed,$dd,$ca,$27,$75,$76,$2e,$38,$12
    db $c2,$d2,$f8,$92,$86,$94,$8c,$d4,$87,$20,$81,$1d,$c2,$32,$a3,$04
.visibleExpected:
    db $3f,$c4,$83,$d3,$96,$37,$b7,$a5,$9a,$46,$58,$36,$97,$5a,$9d,$2a
