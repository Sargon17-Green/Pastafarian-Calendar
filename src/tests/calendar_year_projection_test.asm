; Native320..328. Independent expected-value Host QA:
; tests/test_sm83_stage1_year_projection_abi.py.
; These test read-only membership, NOT generation of the year-5000 gates.
SECTION "Calendar year projection Native smoke", ROMX, BANK[1]
RunCalendarYearProjectionTests::
    ld a, 1
    ld [wTestCaseHi], a
    ; 320: inactive request, output must survive.
    ld a, 64
    ld [wTestCase], a
    ld a, $ab
    ld [wCalendarYearOutput], a
    ld a, $cd
    ld [wCalendarYearOutput+1], a
    call CalendarProjectKnownYearSpan
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ld a, [wCalendarYearOutput]
    cp $ab
    jp nz, .fail
    ; Owner 64 is newly allocated for all following tests.
    ld a, 64
    ld [wCalendarRequestedOwner], a
    ld a, 1
    ld [wCalendarRequestedBanks], a
    call CalendarInvocationBegin
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld hl, .foundationBounds
    ld de, wCalendarYearOpen
    ld b, 8
.bounds:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .bounds
    ld a, $88
    ld [wCalendarYearCandidate], a
    ld a, $13
    ld [wCalendarYearCandidate+1], a
    ld a, 3
    ld [wCalendarOrdinalLength], a
    xor a
    ld [wCalendarOrdinalLength+1], a
    ld [wCalendarOrdinalLength+2], a
    ld a, 1
    ld [wCalendarOrdinalSign], a
    ; 321: canonical Foundation day lies within its selected 5000 year.
    ld a, 65
    ld [wTestCase], a
    ld hl, .targetFoundation
    call .writeMagnitude
    call CalendarProjectKnownYearSpan
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, [wCalendarYearOutput]
    cp $88
    jp nz, .fail
    ld a, [wCalendarYearOutput+1]
    cp $13
    jp nz, .fail
    ; 322: exact opening gate is excluded.
    ld a, 66
    ld [wTestCase], a
    ld hl, .targetOpen
    call .writeMagnitude
    call CalendarProjectKnownYearSpan
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    ; 323: opening gate + 1 is included.
    ld a, 67
    ld [wTestCase], a
    ld hl, .targetOpenPlus1
    call .writeMagnitude
    call CalendarProjectKnownYearSpan
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ; 324: exact closing gate is included.
    ld a, 68
    ld [wTestCase], a
    ld hl, .targetClose
    call .writeMagnitude
    call CalendarProjectKnownYearSpan
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ; 325: closing gate + 1 is excluded.
    ld a, 69
    ld [wTestCase], a
    ld hl, .targetClosePlus1
    call .writeMagnitude
    call CalendarProjectKnownYearSpan
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    ; 326: negative zero fails closed without changing result.
    ld a, 70
    ld [wTestCase], a
    xor a
    ld [wCalendarOrdinalLength], a
    call CalendarProjectKnownYearSpan
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    ; 327: +2^31 is outside bounded signed32 ABI.
    ld a, 71
    ld [wTestCase], a
    ld a, 4
    ld [wCalendarOrdinalLength], a
    xor a
    ld [wCalendarOrdinalSign], a
    ld hl, .positiveOverflow
    call .writeMagnitude
    call CalendarProjectKnownYearSpan
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    ld a, [wCalendarYearOutput]
    cp $88
    jp nz, .fail
    ld a, [wCalendarYearOutput+1]
    cp $13
    jp nz, .fail
    ; 328: abort wipes owned payload and lease, not the projected result.
    ld a, 72
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
.writeMagnitude:
    push hl
    ld a, 3
    call SRAMSelectBank
    pop hl
    ld de, $a000
    ld b, 4
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
.foundationBounds:
    db $d9, $3c, $1a, $ff ; -15057703, opening
    db $6d, $4d, $1a, $ff ; -15053459, closing
.targetFoundation:
    db $37, $bb, $e5, $00 ; |-15055671|
.targetOpen:
    db $27, $c3, $e5, $00 ; |-15057703|
.targetOpenPlus1:
    db $26, $c3, $e5, $00 ; |-15057702|
.targetClose:
    db $93, $b2, $e5, $00 ; |-15053459|
.targetClosePlus1:
    db $92, $b2, $e5, $00 ; |-15053458|
.positiveOverflow:
    db $00, $00, $00, $80 ; +2147483648
