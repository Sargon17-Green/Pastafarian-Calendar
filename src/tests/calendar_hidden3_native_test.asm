; Isolated Native374: hidden k=3 after native five-stone i=3.
SECTION "Calendar hidden3 Native benchmark", ROMX, BANK[1]
RunCalendarHidden3Bench::
    call SRAMEnable
    call LeaseResetAll
    xor a
    ld [wCalendarActive], a
    ld [wCalendarActiveOwner], a
    ld a, 1
    ld [wTestCaseHi], a
    ld a, 118
    ld [wTestCase], a      ; 374
    ld hl, wCalendarHiddenOutput
    ld b, 16
    ld a, $5a
.fill:
    ld [hli], a
    dec b
    jr nz, .fill
    call CalendarHiddenDrop3
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ld hl, wCalendarHiddenOutput
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
    ld a, 3
    ld [wCalendarStoneIteration], a
    call CalendarStoneTransitionRange
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    call CalendarHiddenDrop3
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld hl, wCalendarHiddenOutput
    ld de, .expected3
    ld b, 16
.compare:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc hl
    inc de
    dec b
    jr nz, .compare
    ld hl, wCalendarStoneOutput
    ld de, .expected3Stones
    ld b, 80
.checkStoneSource:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc hl
    inc de
    dec b
    jr nz, .checkStoneSource
    ld hl, wCalendarStoneOld
    ld de, RunCalendarStoneTransitionTests.initial
    ld b, 80
.checkInitialStones:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc hl
    inc de
    dec b
    jr nz, .checkInitialStones
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

    ; Invalid input must preserve the previously published output.
    ld a, $80
    ld [wCalendarStoneOutput+15], a
    call CalendarHiddenDrop3
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    xor a
    ld [wCalendarStoneOutput+15], a
    ld hl, wCalendarHiddenOutput
    ld de, .expected3
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
    call CalendarHiddenDrop3
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ld hl, wCalendarHiddenOutput
    ld de, .expected3
    ld b, 16
.checkIdle:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc hl
    inc de
    dec b
    jr nz, .checkIdle
    ld a, $a5
    ld [wTestResult], a
    ret
.fail:
    ld a, $e0
    ld [wTestResult], a
    ret
.expected3:
    db $74,$96,$da,$ec,$5b,$2a,$ea,$ed,$dd,$ca,$27,$75,$76,$2e,$38,$12
.expected3Stones:
    db $ba,$3a,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $3e,$c1,$11,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $47,$bf,$56,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $4f,$66,$4b,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $6e,$35,$90,$06,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
