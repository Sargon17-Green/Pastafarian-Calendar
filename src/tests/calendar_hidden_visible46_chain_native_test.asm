; Stage1 Native386: end-to-end V1..V46 continuation from the corrected V1..V6 chain.
SECTION "Calendar hidden-visible chain46 Native benchmark", ROMX, BANK[1]

RunCalendarHiddenVisible46ChainBench::
    call SRAMEnable
    call LeaseResetAll
    xor a
    ld [wCalendarActive], a
    ld [wCalendarActiveOwner], a
    ld [wTestResult], a
    ld a, 1
    ld [wTestCaseHi], a
    ld a, 130
    ld [wTestCase], a

    ; An idle invocation must not publish a partial result.
    ld hl, wCalendarVisibleOutput
    ld b, 16
    ld a, $5a
.fillInitialOutput:
    ld [hli], a
    dec b
    jr nz, .fillInitialOutput
    call CalendarHiddenVisible46Chain
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ld hl, wCalendarVisibleOutput
    ld b, 16
.checkInitialOutput:
    ld a, [hli]
    cp $5a
    jp nz, .fail
    dec b
    jr nz, .checkInitialOutput

    ; Foundation ordinal pair, owner 70, one leased bank.
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

    ; Preserve a bank-3 SRAM sentinel across the complete V46 calculation.
    ld a, 3
    ld [$4000], a
    ld a, $0a
    ld [$0000], a
    ld a, $6e
    ld [$a000], a

    call CalendarHiddenVisible46Chain
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail

    ld hl, wCalendarHiddenRetained
    ld de, .hiddenExpected
    ld b, 112
    call .checkBytes

    ld hl, wCalendarVisibleFirst
    ld de, .visible1Expected
    ld b, 16
    call .checkBytes
    ld hl, wCalendarVisibleSecond
    ld de, .visible2Expected
    ld b, 16
    call .checkBytes
    ld hl, wCalendarVisibleThird
    ld de, .visible3Expected
    ld b, 16
    call .checkBytes
    ld hl, wCalendarVisibleFourth
    ld de, .visible4Expected
    ld b, 16
    call .checkBytes
    ld hl, wCalendarVisibleFifth
    ld de, .visible5Expected
    ld b, 16
    call .checkBytes
    ld hl, wCalendarVisibleSixth
    ld de, .visible6Expected
    ld b, 16
    call .checkBytes
    ld hl, wCalendarVisibleOutput
    ld de, .visible46Expected
    ld b, 16
    call .checkBytes

    ; The ring is ordered by slots: V43,V44,V45,V46,V40,V41,V42.
    ld hl, wCalendarVisibleRing
    ld de, .ringExpected
    ld b, 112
    call .checkBytes
    ld a, [wCalendarVisibleRingIndex]
    cp 3
    jp nz, .fail
    ld a, [wCalendarVisibleIteration]
    cp 47
    jp nz, .fail
    ld a, [wCalendarStoneIteration]
    cp 46
    jp nz, .fail

    ; The five-stone S46 snapshot is retained in both old and output buffers.
    ld hl, wCalendarStoneOld
    ld de, .stones46Expected
    ld b, 80
    call .checkBytes
    ld hl, wCalendarStoneOutput
    ld de, .stones46Expected
    ld b, 80
    call .checkBytes

    ; Original ordinal offsets, owner, lease and SRAM must remain intact.
    ld hl, wPairCalcOffset
    ld b, 8
.checkOffsets:
    ld a, [hli]
    or a
    jp nz, .fail
    dec b
    jr nz, .checkOffsets
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

    ; Negative zero must be rejected without changing the published V46.
    ld a, 1
    ld [wCalendarOrdinalSign], a
    call CalendarHiddenVisible46Chain
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    xor a
    ld [wCalendarOrdinalSign], a
    ld hl, wCalendarVisibleOutput
    ld de, .visible46Expected
    ld b, 16
    call .checkBytes

    ; Abort releases the lease and clears bank-3 SRAM.
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

    ; Idle rejection after abort must also preserve V46.
    call CalendarHiddenVisible46Chain
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ld hl, wCalendarVisibleOutput
    ld de, .visible46Expected
    ld b, 16
    call .checkBytes

    ld a, $a5
    ld [wTestResult], a
    ret

.checkBytes:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc de
    inc hl
    dec b
    jr nz, .checkBytes
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
.visible1Expected:
    db $3f,$c4,$83,$d3,$96,$37,$b7,$a5,$9a,$46,$58,$36,$97,$5a,$9d,$2a
.visible2Expected:
    db $13,$c8,$f6,$f1,$ec,$0f,$5e,$3d,$a8,$e7,$0b,$17,$33,$01,$e0,$33
.visible3Expected:
    db $94,$33,$e9,$a7,$8a,$62,$47,$fc,$45,$aa,$7e,$21,$62,$47,$8c,$75
.visible4Expected:
    db $72,$e5,$db,$9d,$ca,$2b,$4b,$c1,$d8,$76,$8e,$a2,$3c,$24,$0c,$15
.visible5Expected:
    db $57,$f7,$4f,$44,$05,$45,$50,$cd,$16,$d5,$d4,$5a,$a3,$40,$9c,$6a
.visible6Expected:
    db $a1,$2e,$cb,$a0,$45,$7c,$e7,$2b,$05,$59,$51,$07,$5f,$b7,$c8,$11
.visible46Expected:
    db $1a,$90,$87,$91,$00,$b9,$53,$b0,$ae,$c7,$3f,$9e,$b1,$b3,$bb,$6a
.ringExpected:
    db $0e,$1d,$4a,$40,$b1,$0f,$41,$79,$bd,$0a,$42,$f4,$15,$51,$bc,$19
    db $13,$a2,$32,$e6,$db,$ea,$51,$91,$cd,$32,$e0,$15,$fc,$b1,$ae,$73
    db $b7,$c9,$04,$ef,$e6,$c4,$5a,$5b,$9f,$83,$70,$c2,$a0,$1d,$0e,$32
    db $1a,$90,$87,$91,$00,$b9,$53,$b0,$ae,$c7,$3f,$9e,$b1,$b3,$bb,$6a
    db $4f,$60,$45,$0d,$9c,$f0,$3e,$b2,$3d,$68,$43,$cb,$26,$c7,$96,$7b
    db $a0,$f4,$f2,$41,$83,$76,$9c,$bf,$8f,$8f,$11,$96,$d6,$4a,$4f,$1b
    db $e0,$c7,$f7,$1c,$98,$d6,$23,$ac,$24,$10,$22,$7e,$8b,$8c,$88,$65
.stones46Expected:
    db $7e,$a3,$82,$0d,$75,$01,$34,$6b,$0d,$09,$38,$4a,$05,$42,$85,$37
    db $2d,$f5,$f9,$27,$ee,$02,$9d,$27,$d0,$c3,$76,$81,$b5,$65,$49,$6f
    db $4d,$ad,$0e,$0a,$3d,$f8,$4f,$3f,$1b,$93,$fd,$14,$2f,$f2,$17,$47
    db $e2,$7e,$25,$6a,$ae,$03,$c3,$0e,$c0,$bd,$38,$53,$be,$43,$9b,$51
    db $ea,$98,$7a,$d7,$6b,$39,$bb,$86,$a3,$2f,$cf,$71,$c2,$a5,$2a,$67
