; Native396 host-driven isolated bench. No oracle results written by the host.
SECTION "Native396 mailbox", WRAM0
wNative396Phase:: ds 1
wNative396Snapshot:: ds 18

SECTION "Native396 directional tests", ROMX, BANK[3]
RunCalendarDirectionalBench::
    call SRAMEnable
    xor a
    ld [wTestResult], a
    ld [wCalendarActive], a
    ld [wCalendarActiveOwner], a
    ld [wNative396Phase], a
    ld a, 1
    ld [wTestCaseHi], a
    ld a, 140
    ld [wTestCase], a
    ld hl, wCalendarDirectionalInput
    ld b, 13
    xor a
.clearInput:
    ld [hli], a
    dec b
    jr nz, .clearInput
    ld hl, wCalendarDirectionalResult
    ld b, 18
    ld a, $5a
.fillDirection:
    ld [hli], a
    dec b
    jr nz, .fillDirection
    ld hl, wCalendarGateYearResultOpen
    ld b, 18
    ld a, $a6
.fillYear:
    ld [hli], a
    dec b
    jr nz, .fillYear
    call CalendarDirectionalSelect
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .failIdle
    ld hl, wCalendarDirectionalResult
    ld b, 18
.checkIdle:
    ld a, [hli]
    cp $5a
    jp nz, .failIdle
    dec b
    jr nz, .checkIdle
    ld a, 70
    ld [wCalendarRequestedOwner], a
    ld a, 1
    ld [wCalendarRequestedBanks], a
    call CalendarGateYearLeaseBegin
    ld a, [wCalendarStatus]
    or a
    jp nz, .failLease
    ld a, 1
    ld [wCalendarOrdinalLength], a
    xor a
    ld [wCalendarOrdinalLength+1], a
    ld [wCalendarOrdinalLength+2], a
    ld [wCalendarOrdinalSign], a
    ld a, 3
    call SRAMSelectBank
    ld a, $6e
    ld [$a000], a
    ld hl, wPairTargetOffset
    ld a, $e9
    ld [hli], a
    ld a, $ff
    ld [hli], a
    ld [hli], a
    ld [hl], a
    ld a, 5
    ld [wCalendarAnswerInputBowl], a
    ld a, 12
    ld [wCalendarAnswerInputSeal], a
    ld a, 47
    ld [wCalendarSelectCount], a
    xor a
    ld [wCalendarSelectCount+1], a
    ld a, 2
    ld [wCalendarSelectDirection], a
.ready:
    ld a, 1
    ld [wNative396Phase], a
.wait:
    ld a, [wNative396Phase]
    cp 2
    jr z, .execute
    cp 5
    jr z, .finish
    jr .wait
.execute:
    call CalendarDirectionalSelect
    ld a, 3
    ld [wNative396Phase], a
.ack:
    ld a, [wNative396Phase]
    cp 4
    jr nz, .ack
    jr .ready
.finish:
    ld hl, wCalendarDirectionalResult
    ld de, wNative396Snapshot
    ld b, 18
    call CalendarGateYearCopyN
    call CalendarGateYearLeaseAbort
    ld a, [wCalendarStatus]
    or a
    jp nz, .failAbort
    ld a, [wCalendarActive]
    or a
    jp nz, .failAbort
    ld a, [wLeaseTable+3]
    or a
    jp nz, .failAbort
    call CalendarDirectionalSelect
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .failIdleAfter
    ld hl, wCalendarDirectionalResult
    ld de, wNative396Snapshot
    ld b, 18
.compare:
    ld a, [de]
    cp [hl]
    jp nz, .failIdleAfter
    inc hl
    inc de
    dec b
    jr nz, .compare
    ld a, 6
    ld [wNative396Phase], a
    ld a, $a5
    ld [wTestResult], a
    ret
.failIdle:
    ld a, 184 ; 440
    jr .fail
.failLease:
    ld a, 185 ; 441
    jr .fail
.failAbort:
    ld a, 186 ; 442
    jr .fail
.failIdleAfter:
    ld a, 187 ; 443
.fail:
    ld [wTestCase], a
    ld a, $e0
    ld [wTestResult], a
    ret
