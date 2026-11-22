; Stage1 Native388: true six-bowl simultaneous step, isolated from Native370..387.
; Expected ROM bytes are independently computed mathematical postconditions.
SECTION "Calendar bowl step Native388 test", ROMX, BANK[1]

RunCalendarBowlStepBench::
    call SRAMEnable
    call LeaseResetAll
    xor a
    ld [wCalendarActive], a
    ld [wCalendarActiveOwner], a
    ld [wTestResult], a
    ld a, 1
    ld [wTestCaseHi], a
    ld a, 132
    ld [wTestCase], a
    ; Idle must not publish anything.
    ld hl, wCalendarBowlsNext
    ld b, 96
    ld a, $5a
.fillIdle:
    ld [hli], a
    dec b
    jr nz, .fillIdle
    call CalendarBowlUpdateStep
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ld hl, wCalendarBowlsNext
    ld b, 96
.idleOutput:
    ld a, [hli]
    cp $5a
    jp nz, .fail
    dec b
    jr nz, .idleOutput

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
    ; Success must not rewrite the old six-bowl snapshot.
    ld hl, wCalendarBowlsOld
    ld de, .case2
    ld b, 96
    call .check
    jp nz, .fail

    ; Reject duplicate bowl ID, preserve previously published 96 bytes.
    ld a, 4
    ld [wCalendarBowlOrder+1], a
    call CalendarBowlUpdateStep
    call .mustReject
    jp nz, .fail
    ld a, 5
    ld [wCalendarBowlOrder+1], a
    ; Reject noncanonical zero without publication.
    xor a
    ld [wCalendarVisibleOutput], a
    ld hl, wCalendarVisibleOutput+1
    ld b, 15
.clearDrop:
    ld [hli], a
    dec b
    jr nz, .clearDrop
    call CalendarBowlUpdateStep
    call .mustReject
    jp nz, .fail
    ; Recover canonical source, then reject negative-zero ordinal.
    ld hl, .case2Drop
    ld de, wCalendarVisibleOutput
    ld b, 16
    call .load
    ld a, 1
    ld [wCalendarOrdinalSign], a
    call CalendarBowlUpdateStep
    call .mustReject
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
    call CalendarBowlUpdateStep
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    call .checkExpected2
    jp nz, .fail

    ld a, $a5
    ld [wTestResult], a
    ret

.mustReject:
    ld a, [wCalendarStatus]
    cp 2
    jr nz, .bad
    jp .checkExpected2
.bad:
    ld a, 1
    or a
    ret
.checkExpected2:
    ld hl, wCalendarBowlsNext
    ld de, .case2Expected
    ld b, 96
    jp .check

.runCase:
    ; HL=source old[96],stone[80],drop[16],order[6],i[1],expected[96].
    ld de, wCalendarBowlsOld
    ld b, 96
    call .load
    ld de, wCalendarStoneOld
    ld b, 80
    call .load
    ld de, wCalendarVisibleOutput
    ld b, 16
    call .load
    ld de, wCalendarBowlOrder
    ld b, 6
    call .load
    ld a, [hli]
    ld [wCalendarVisibleIteration], a
    push hl
    call CalendarBowlUpdateStep
    pop de
    ld a, [wCalendarStatus]
    or a
    jr nz, .bad
    ld hl, wCalendarBowlsNext
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

.fail:
    ld a, $e0
    ld [wTestResult], a
    ret

.case1:
    db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $06,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $11,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $1d,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $2b,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $47,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $65,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.case1Drop:
    db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db 1,2,3,4,5,6
    db 1
.case1Expected:
    db $61,$0d,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $ca,$2c,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $6b,$9c,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $10,$25,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $96,$45,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $78,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

.case2:
    db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
    db $fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
    db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $11,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $1d,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $2b,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $47,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $65,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.case2Drop:
    db $fe,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
    db 4,5,2,3,6,1
    db 46
.case2Expected:
    db $c0,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $fd,$a9,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $45,$1a,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $6e,$9c,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $d6,$de,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $ca,$2c,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
