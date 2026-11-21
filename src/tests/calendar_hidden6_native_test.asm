; Isolated Native377: hidden k=6 after native five-stone i=6.
SECTION "Calendar hidden6 Native benchmark", ROMX, BANK[1]
RunCalendarHidden6Bench::
    call SRAMEnable
    call LeaseResetAll
    xor a
    ld [wCalendarActive], a
    ld [wCalendarActiveOwner], a
    ld a, 1
    ld [wTestCaseHi], a
    ld a, 121
    ld [wTestCase], a      ; case 377
    ld hl, wCalendarHiddenOutput
    ld b, 16
    ld a, $5a
.fill:
    ld [hli], a
    dec b
    jr nz, .fill
    call CalendarHiddenDrop6
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
    ld a, 6
    ld [wCalendarStoneIteration], a
    call CalendarStoneTransitionRange
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    call CalendarHiddenDrop6
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld hl, wCalendarHiddenOutput
    ld de, .expected6
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
    ld de, .expected6Stones
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
    call CalendarHiddenDrop6
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    xor a
    ld [wCalendarStoneOutput+15], a
    ld hl, wCalendarHiddenOutput
    ld de, .expected6
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
    call CalendarHiddenDrop6
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ld hl, wCalendarHiddenOutput
    ld de, .expected6
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
.expected6:
    db $c0,$75,$48,$de,$5c,$af,$64,$02,$31,$07,$7a,$b3,$ea,$81,$55,$37
.expected6Stones:
    db $2c,$06,$70,$be,$25,$e8,$ae,$e5,$54,$77,$c3,$1f,$80,$69,$32,$25
    db $48,$e4,$aa,$01,$25,$28,$a8,$d1,$a2,$c3,$95,$47,$69,$3a,$a2,$6e
    db $86,$b1,$d1,$ec,$67,$76,$32,$28,$c4,$06,$f3,$5a,$64,$25,$3e,$6e
    db $1e,$5a,$27,$73,$93,$90,$81,$82,$98,$6a,$2b,$dc,$aa,$6c,$a4,$31
    db $27,$57,$f3,$64,$bf,$21,$da,$9a,$2c,$1f,$09,$55,$96,$21,$2a,$66
