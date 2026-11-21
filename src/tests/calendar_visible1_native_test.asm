; Isolated Native379: visible i=1 on supplied signed32 pair and
; independently calculated hidden k=1,3,7 source residues.
SECTION "Calendar visible1 Native benchmark", ROMX, BANK[1]
RunCalendarVisible1Bench::
    call SRAMEnable
    call LeaseResetAll
    xor a
    ld [wCalendarActive], a
    ld [wCalendarActiveOwner], a
    ld a, 1
    ld [wTestCaseHi], a
    ld a, 122
    ld [wTestCase], a  ; previous completed case 378
    ld hl, wCalendarVisibleOutput
    ld b, 16
    ld a, $5a
.fill:
    ld [hli], a
    dec b
    jr nz, .fill
    call CalendarVisibleDrop1
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ld hl, wCalendarVisibleOutput
    ld b, 16
.checkInitialIdle:
    ld a, [hli]
    cp $5a
    jp nz, .fail
    dec b
    jr nz, .checkInitialIdle

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

    ld hl, RunCalendarStoneTransitionTests.initial
    ld de, wCalendarStoneOld
    ld b, 80
.seedStones:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .seedStones
    ld hl, .inputHidden
    ld de, wCalendarVisibleInputs
    ld b, 48
.seedHidden:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .seedHidden
    ld a, 1
    ld [wCalendarVisibleIteration], a
    call CalendarVisibleDrop1
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld hl, wCalendarVisibleOutput
    ld de, .expected1
    ld b, 16
.compare:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc hl
    inc de
    dec b
    jr nz, .compare
    ld hl, wCalendarVisibleInputs
    ld de, .inputHidden
    ld b, 48
.checkHidden:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc hl
    inc de
    dec b
    jr nz, .checkHidden
    ld hl, wCalendarStoneOld
    ld de, RunCalendarStoneTransitionTests.initial
    ld b, 80
.checkStones:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc hl
    inc de
    dec b
    jr nz, .checkStones
    ld a, [wWorkCalcCount]
    cp 1
    jp nz, .fail
    ld a, [wWorkTargetCount]
    cp 1
    jp nz, .fail
    ld a, [wWorkDistance]
    cp 1
    jp nz, .fail
    ld a, [wWorkSum]
    cp 2
    jp nz, .fail
    ld a, [wWorkDirection]
    cp 2
    jp nz, .fail
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

    ; Invalid canonical residue: published output and all inputs unaffected.
    ld a, $80
    ld [wCalendarVisibleInputs+47], a
    call CalendarVisibleDrop1
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    ld a, $04
    ld [wCalendarVisibleInputs+47], a
    ld hl, wCalendarVisibleOutput
    ld de, .expected1
    ld b, 16
.checkRejected:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc hl
    inc de
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
    call CalendarVisibleDrop1
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ld hl, wCalendarVisibleOutput
    ld de, .expected1
    ld b, 16
.checkIdle:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc hl
    inc de
    dec b
    jr nz, .checkIdle
    ld a, 123
    ld [wTestCase], a  ; exact Native379
    ld a, $a5
    ld [wTestResult], a
    ret
.fail:
    ld a, $e0
    ld [wTestResult], a
    ret
; Independent Foundation c=t=0 oracle inputs: hidden1, hidden3, hidden7.
.inputHidden:
    db $58,$0c,$f9,$0c,$e6,$70,$09,$e4,$25,$3c,$27,$5a,$6a,$d6,$d1,$59
    db $74,$96,$da,$ec,$5b,$2a,$ea,$ed,$dd,$ca,$27,$75,$76,$2e,$38,$12
    db $c2,$d2,$f8,$92,$86,$94,$8c,$d4,$87,$20,$81,$1d,$c2,$32,$a3,$04
.expected1:
    db $3f,$c4,$83,$d3,$96,$37,$b7,$a5,$9a,$46,$58,$36,$97,$5a,$9d,$2a
