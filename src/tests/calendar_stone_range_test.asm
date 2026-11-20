; Native365..370: i=3/i=5 sampled multi-round five-stone transition.
; Target i=46 is independently Host-checked; NOT a Native i=46 claim.
SECTION "Stage1 iterative five stone Native tests", ROMX, BANK[1]
RunCalendarStoneRangeTests::
    ld a, 1
    ld [wTestCaseHi], a
    ; 365: idle, output immutable.
    ld a, 109
    ld [wTestCase], a
    call .sentinelOutput
    call .loadInitial
    ld a, 3
    ld [wCalendarStoneIteration], a
    call CalendarStoneTransitionRange
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    call .expectSentinel

    ld a, 67
    ld [wCalendarRequestedOwner], a
    ld a, 1
    ld [wCalendarRequestedBanks], a
    call CalendarInvocationBegin
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, 3
    call SRAMSelectBank
    ld a, $7b
    ld [$a000], a

    ; 366: reject targets 47 and 1 with no observable output write.
    ld a, 110
    ld [wTestCase], a
    ld a, 47
    ld [wCalendarStoneIteration], a
    call .expectInvalid
    ld a, 1
    ld [wCalendarStoneIteration], a
    call .expectInvalid

    ; 367: two simultaneous rounds, compare 5 independent i=3 residues.
    ld a, 111
    ld [wTestCase], a
    ld a, 3
    ld [wCalendarStoneIteration], a
    call CalendarStoneTransitionRange
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld de, .expected3
    call .compareOutputs

    ; 368: four simultaneous rounds through i=5.
    ld a, 112
    ld [wTestCase], a
    ld a, 5
    ld [wCalendarStoneIteration], a
    call CalendarStoneTransitionRange
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld de, .expected5
    call .compareOutputs

    ; 369: input and borrowed owner SRAM remain unchanged.
    ld a, 113
    ld [wTestCase], a
    ld hl, wCalendarStoneOld
    ld de, RunCalendarStoneTransitionTests.initial
    ld b, 80
.checkSource:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc hl
    inc de
    dec b
    jr nz, .checkSource
    ld a, [wLeaseTable+3]
    cp 69
    jp nz, .fail
    ld a, 3
    call SRAMSelectBank
    ld a, [$a000]
    cp $7b
    jp nz, .fail

    ; 370: abort releases bank3 and scrubs its byte witness.
    ld a, 114
    ld [wTestCase], a
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

.loadInitial:
    ld hl, RunCalendarStoneTransitionTests.initial
    ld de, wCalendarStoneOld
    ld b, 80
.copy:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copy
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
    call CalendarStoneTransitionRange
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    call .expectSentinel
    ret
.compareOutputs:
    ld hl, wCalendarStoneOutput
    ld b, 80
.compare:
    ld a, [de]
    cp [hl]
    jp nz, .fail
    inc hl
    inc de
    dec b
    jr nz, .compare
    ret
.fail:
    ld a, $e0
    ld [wTestResult], a
    ret
.expected3:
    db $ba, $3a, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $3e, $c1, $11, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $47, $bf, $56, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $4f, $66, $4b, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $6e, $35, $90, $06, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.expected5:
    db $ec, $15, $a8, $bb, $51, $b7, $13, $b6, $18, $00, $00, $00, $00, $00, $00, $00
    db $9b, $7a, $9a, $0f, $ce, $e0, $20, $29, $31, $84, $01, $00, $00, $00, $00, $00
    db $0f, $b8, $4d, $f4, $c0, $14, $24, $12, $d4, $11, $60, $03, $00, $00, $00, $00
    db $d3, $93, $a1, $9e, $d0, $96, $9c, $a8, $7b, $0b, $08, $b8, $1b, $00, $00, $00
    db $f5, $2e, $b5, $55, $41, $04, $a6, $a6, $a6, $f6, $1e, $a3, $3f, $07, $00, $00
