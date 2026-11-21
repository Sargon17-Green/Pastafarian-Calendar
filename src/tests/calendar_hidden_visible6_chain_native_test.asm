; Native385: chain H1..H7; preserve V1..V5 and verify genuine V6.
SECTION "Calendar hidden-visible chain Native benchmark", ROMX, BANK[1]
RunCalendarHiddenVisible6ChainBench::
    call SRAMEnable
    call LeaseResetAll
    xor a
    ld [wCalendarActive], a
    ld [wCalendarActiveOwner], a
    ld a, 1
    ld [wTestCaseHi], a
    ld a, 128
    ld [wTestCase], a ; previous case384
    ld hl, wCalendarVisibleOutput
    ld b, 16
    ld a, $5a
.fill:
    ld [hli], a
    dec b
    jr nz, .fill
    call CalendarHiddenVisible6Chain
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

    call CalendarHiddenVisible6Chain
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
    ld hl, wCalendarVisibleFifth
    ld de, .visible5Expected
    ld b, 16
.checkFifth:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc de
    inc hl
    dec b
    jr nz, .checkFifth
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
    ld de, .stones6Expected
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
    call CalendarHiddenVisible6Chain
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
    call CalendarHiddenVisible6Chain
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
    ld a, 129
    ld [wTestCase], a ; Native385
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
    db $d2,$52,$0e,$b0,$95,$8f,$68,$5e,$24,$d1,$a7,$b1,$2f,$b8,$98,$4b
    db $94,$33,$e9,$a7,$8a,$62,$47,$fc,$45,$aa,$7e,$21,$62,$47,$8c,$75
    db $c0,$75,$48,$de,$5c,$af,$64,$02,$31,$07,$7a,$b3,$ea,$81,$55,$37
.visibleExpected:
    db $c6,$87,$bd,$df,$e0,$1b,$f3,$3d,$89,$67,$96,$6f,$df,$ec,$71,$7d
.visible5Expected:
    db $d2,$52,$0e,$b0,$95,$8f,$68,$5e,$24,$d1,$a7,$b1,$2f,$b8,$98,$4b
.visible1Expected:
    db $3f,$c4,$83,$d3,$96,$37,$b7,$a5,$9a,$46,$58,$36,$97,$5a,$9d,$2a
.stones6Expected:
    db $2c,$06,$70,$be,$25,$e8,$ae,$e5,$54,$77,$c3,$1f,$80,$69,$32,$25
    db $48,$e4,$aa,$01,$25,$28,$a8,$d1,$a2,$c3,$95,$47,$69,$3a,$a2,$6e
    db $86,$b1,$d1,$ec,$67,$76,$32,$28,$c4,$06,$f3,$5a,$64,$25,$3e,$6e
    db $1e,$5a,$27,$73,$93,$90,$81,$82,$98,$6a,$2b,$dc,$aa,$6c,$a4,$31
    db $27,$57,$f3,$64,$bf,$21,$da,$9a,$2c,$1f,$09,$55,$96,$21,$2a,$66
.visible2Expected:
    db $13,$c8,$f6,$f1,$ec,$0f,$5e,$3d,$a8,$e7,$0b,$17,$33,$01,$e0,$33

.visible3Expected:
    db $94,$33,$e9,$a7,$8a,$62,$47,$fc,$45,$aa,$7e,$21,$62,$47,$8c,$75
.visible4Expected:
    db $72,$e5,$db,$9d,$ca,$2b,$4b,$c1,$d8,$76,$8e,$a2,$3c,$24,$0c,$15
