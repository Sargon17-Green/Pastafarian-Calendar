; Native358..364: scoped i=2 simultaneous five-stone update.
; Original Foundation stones are inputs, not a golden calendar result.
SECTION "Stage1 five stone Native tests", ROMX, BANK[1]
RunCalendarStoneTransitionTests::
    ld a, 1
    ld [wTestCaseHi], a
    ; 358: idle fails with 6 and cannot publish.
    ld a, 102
    ld [wTestCase], a
    call .sentinelOutput
    call .loadInitial
    ld a, 2
    ld [wCalendarStoneIteration], a
    call CalendarStoneTransition2
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    call .expectSentinel

    ; 359: active owner66 with independent physical SRAM witness.
    ld a, 103
    ld [wTestCase], a
    ld a, 66
    ld [wCalendarRequestedOwner], a
    ld a, 1
    ld [wCalendarRequestedBanks], a
    call CalendarInvocationBegin
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, 3
    call SRAMSelectBank
    ld a, $6a
    ld [$a000], a

    ; 360: iteration other than i=2 rejected without output modification.
    ld a, 104
    ld [wTestCase], a
    ld a, 1
    ld [wCalendarStoneIteration], a
    call .expectInvalid
    ld a, 2
    ld [wCalendarStoneIteration], a

    ; 361: zero stone rejected before any output writes.
    ld a, 105
    ld [wTestCase], a
    xor a
    ld [wCalendarStoneOld], a
    call .expectInvalid
    ld a, 17
    ld [wCalendarStoneOld], a

    ; 362: bit127 set rejected before any output writes.
    ld a, 106
    ld [wTestCase], a
    ld a, $80
    ld [wCalendarStoneOld+31], a
    call .expectInvalid
    xor a
    ld [wCalendarStoneOld+31], a

    ; 363: all five independent numeric outputs for i=2.
    ld a, 107
    ld [wTestCase], a
    call CalendarStoneTransition2
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld hl, wCalendarStoneOutput
    ld de, .expected
    ld b, 80
.compareOutputs:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc hl
    inc de
    dec b
    jr nz, .compareOutputs

    ; 364: all source bytes, SRAM, owner tag preserved, and abort scrubs.
    ld a, 108
    ld [wTestCase], a
    ld hl, wCalendarStoneOld
    ld de, .initial
    ld b, 80
.compareSource:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc hl
    inc de
    dec b
    jr nz, .compareSource
    ld a, [wLeaseTable+3]
    cp 68
    jp nz, .fail
    ld a, 3
    call SRAMSelectBank
    ld a, [$a000]
    cp $6a
    jp nz, .fail
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
    ret

.sentinelOutput:
    ld hl, wCalendarStoneOutput
    ld b, 80
    ld a, $5a
.fill:
    ld [hli], a
    dec b
    jr nz, .fill
    ret
.expectSentinel:
    ld hl, wCalendarStoneOutput
    ld b, 80
.check:
    ld a, [hli]
    cp $5a
    jp nz, .fail
    dec b
    jr nz, .check
    ret
.expectInvalid:
    call CalendarStoneTransition2
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    call .expectSentinel
    ret
.loadInitial:
    ld hl, .initial
    ld de, wCalendarStoneOld
    ld b, 80
.copy:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copy
    ret
.fail:
    ld a, $e0
    ld [wTestResult], a
    ret
.initial:
    db $11, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $1d, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $2b, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $47, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $65, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.expected:
    db $7a, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $31, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $47, $09, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $33, $18, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $fd, $28, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
