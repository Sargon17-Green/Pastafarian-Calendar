; Isolated Native378: hidden k=7 after native five-stone i=7.
SECTION "Calendar hidden7 Native benchmark", ROMX, BANK[1]
RunCalendarHidden7Bench::
    call SRAMEnable
    call LeaseResetAll
    xor a
    ld [wCalendarActive], a
    ld [wCalendarActiveOwner], a
    ld a, 1
    ld [wTestCaseHi], a
    ld a, 122
    ld [wTestCase], a      ; case 377
    ld hl, wCalendarHiddenOutput
    ld b, 16
    ld a, $5a
.fill:
    ld [hli], a
    dec b
    jr nz, .fill
    call CalendarHiddenDrop7
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
    ld a, 7
    ld [wCalendarStoneIteration], a
    call CalendarStoneTransitionRange
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    call CalendarHiddenDrop7
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld hl, wCalendarHiddenOutput
    ld de, .expected7
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
    ld de, .expected7Stones
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
    call CalendarHiddenDrop7
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    xor a
    ld [wCalendarStoneOutput+15], a
    ld hl, wCalendarHiddenOutput
    ld de, .expected7
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
    call CalendarHiddenDrop7
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ld hl, wCalendarHiddenOutput
    ld de, .expected7
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
.expected7:
    db $c2,$d2,$f8,$92,$86,$94,$8c,$d4,$87,$20,$81,$1d,$c2,$32,$a3,$04
.expected7Stones:
    db $32,$24,$17,$63,$1a,$d5,$b8,$c3,$e5,$7f,$fc,$c6,$e1,$3e,$49,$3f
    db $25,$b7,$2f,$c1,$e2,$8c,$6f,$1f,$00,$5e,$26,$12,$76,$94,$78,$38
    db $4b,$ff,$52,$68,$24,$fe,$63,$e6,$35,$ef,$67,$b0,$4e,$92,$10,$3c
    db $78,$f9,$1f,$ae,$47,$f6,$d0,$4e,$71,$19,$a2,$97,$15,$42,$9d,$03
    db $95,$33,$38,$67,$75,$eb,$35,$d4,$cd,$07,$76,$91,$f7,$fa,$7e,$02
