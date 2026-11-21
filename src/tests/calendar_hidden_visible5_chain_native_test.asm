; Native384: chain H1..H7, retain V1..V4 and verify V5.
SECTION "Calendar hidden-visible chain Native benchmark", ROMX, BANK[1]
RunCalendarHiddenVisible5ChainBench::
    call SRAMEnable
    call LeaseResetAll
    xor a
    ld [wCalendarActive], a
    ld [wCalendarActiveOwner], a
    ld a, 1
    ld [wTestCaseHi], a
    ld a, 127
    ld [wTestCase], a ; previous case383
    ld hl, wCalendarVisibleOutput
    ld b, 16
    ld a, $5a
.fill:
    ld [hli], a
    dec b
    jr nz, .fill
    call CalendarHiddenVisible5Chain
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

    call CalendarHiddenVisible5Chain
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
    ld hl, wCalendarVisibleFirst
    ld de, .visible1Expected
    ld b, 16
.checkFirst:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc de
    inc hl
    dec b
    jr nz, .checkFirst
    ld hl, wCalendarVisibleSecond
    ld de, .visible2Expected
    ld b, 16
.checkSecond:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc de
    inc hl
    dec b
    jr nz, .checkSecond
    ld hl, wCalendarVisibleThird
    ld de, .visible3Expected
    ld b, 16
.checkThird:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc de
    inc hl
    dec b
    jr nz, .checkThird
    ld hl, wCalendarVisibleFourth
    ld de, .visible4Expected
    ld b, 16
.checkFourth:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc de
    inc hl
    dec b
    jr nz, .checkFourth
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
    ld de, .stones5Expected
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
    call CalendarHiddenVisible5Chain
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
    call CalendarHiddenVisible5Chain
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
    ld a, 128
    ld [wTestCase], a ; Native384
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
    db $72,$e5,$db,$9d,$ca,$2b,$4b,$c1,$d8,$76,$8e,$a2,$3c,$24,$0c,$15
    db $13,$c8,$f6,$f1,$ec,$0f,$5e,$3d,$a8,$e7,$0b,$17,$33,$01,$e0,$33
    db $74,$96,$da,$ec,$5b,$2a,$ea,$ed,$dd,$ca,$27,$75,$76,$2e,$38,$12
.visibleExpected:
    db $57,$f7,$4f,$44,$05,$45,$50,$cd,$16,$d5,$d4,$5a,$a3,$40,$9c,$6a
.visible1Expected:
    db $3f,$c4,$83,$d3,$96,$37,$b7,$a5,$9a,$46,$58,$36,$97,$5a,$9d,$2a
.stones5Expected:
    db $ec,$15,$a8,$bb,$51,$b7,$13,$b6,$18,$00,$00,$00,$00,$00,$00,$00
    db $9b,$7a,$9a,$0f,$ce,$e0,$20,$29,$31,$84,$01,$00,$00,$00,$00,$00
    db $0f,$b8,$4d,$f4,$c0,$14,$24,$12,$d4,$11,$60,$03,$00,$00,$00,$00
    db $d3,$93,$a1,$9e,$d0,$96,$9c,$a8,$7b,$0b,$08,$b8,$1b,$00,$00,$00
    db $f5,$2e,$b5,$55,$41,$04,$a6,$a6,$a6,$f6,$1e,$a3,$3f,$07,$00,$00
.visible2Expected:
    db $13,$c8,$f6,$f1,$ec,$0f,$5e,$3d,$a8,$e7,$0b,$17,$33,$01,$e0,$33

.visible3Expected:
    db $94,$33,$e9,$a7,$8a,$62,$47,$fc,$45,$aa,$7e,$21,$62,$47,$8c,$75
.visible4Expected:
    db $72,$e5,$db,$9d,$ca,$2b,$4b,$c1,$d8,$76,$8e,$a2,$3c,$24,$0c,$15
