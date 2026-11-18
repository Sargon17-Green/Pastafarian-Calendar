; Native329..340: bounded next/previous year span handoff.
; These are synthetic valid/invalid spans, NOT normative selected seal outputs.
; Separate Host oracle verifies dynamic c-dependent seal 10/11/12 spans.
SECTION "Calendar adjacent year transition Native tests", ROMX, BANK[1]
RunCalendarYearStepTests::
    ld a, 1
    ld [wTestCaseHi], a
    ; 329 idle returns 6; year remains untouched.
    ld a, 73
    ld [wTestCase], a
    ld a, $88
    ld [wCalendarYearCandidate], a
    ld a, $13
    ld [wCalendarYearCandidate+1], a
    ld a, 1
    ld [wCalendarYearDirection], a
    call CalendarAdvanceSelectedYear
    ld a, [wCalendarStatus]
    cp 6
    jp nz, .fail
    ld a, [wCalendarYearCandidate]
    cp $88
    jp nz, .fail
    ; Begin owner65 with a zero ordinal and an unused sentinel SRAM byte.
    ld a, 65
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
    ld hl, .foundation
    call .setCurrent
    ld hl, .nextSpan
    call .setProposed
    ld a, $ab
    ld [wCalendarYearOutput], a
    ld a, $cd
    ld [wCalendarYearOutput+1], a
    ; 330 valid NEXT: 5000 -> 5001.
    ld a, 74
    ld [wTestCase], a
    ld a, 1
    ld [wCalendarYearDirection], a
    call CalendarAdvanceSelectedYear
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, [wCalendarYearCandidate]
    cp $89
    jp nz, .fail
    ld a, [wCalendarYearCandidate+1]
    cp $13
    jp nz, .fail
    ld a, [wCalendarYearOpen]
    cp $6d
    jp nz, .fail
    ; 331 valid PREVIOUS: 5001 -> 5000, reversing the same two spans.
    ld a, 75
    ld [wTestCase], a
    ld hl, .foundation
    call .setProposed
    ld a, 2
    ld [wCalendarYearDirection], a
    call CalendarAdvanceSelectedYear
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, [wCalendarYearCandidate]
    cp $88
    jp nz, .fail
    ld a, [wCalendarYearOpen]
    cp $d9
    jp nz, .fail
    ; 332 broken NEXT adjacency; no current-year mutation.
    ld a, 76
    ld [wTestCase], a
    ld hl, .badJoint
    call .setProposed
    ld a, 1
    ld [wCalendarYearDirection], a
    call CalendarAdvanceSelectedYear
    call .expectInvalidUnchanged
    ; 333 span251 < min252.
    ld a, 77
    ld [wTestCase], a
    ld hl, .shortSpan
    call .setProposed
    call CalendarAdvanceSelectedYear
    call .expectInvalidUnchanged
    ; 334 span5779 > max5778.
    ld a, 78
    ld [wTestCase], a
    ld hl, .longSpan
    call .setProposed
    call CalendarAdvanceSelectedYear
    call .expectInvalidUnchanged
    ; 335 invalid direction 3.
    ld a, 79
    ld [wTestCase], a
    ld hl, .nextSpan
    call .setProposed
    ld a, 3
    ld [wCalendarYearDirection], a
    call CalendarAdvanceSelectedYear
    call .expectInvalidUnchanged
    ; 336 negative zero is not canonical.
    ld a, 80
    ld [wTestCase], a
    ld a, 1
    ld [wCalendarYearDirection], a
    ld [wCalendarOrdinalSign], a
    call CalendarAdvanceSelectedYear
    call .expectInvalidUnchanged
    xor a
    ld [wCalendarOrdinalSign], a
    ; 337 unsigned16 year overflow must be rejected.
    ld a, 81
    ld [wTestCase], a
    ld a, $ff
    ld [wCalendarYearCandidate], a
    ld [wCalendarYearCandidate+1], a
    call CalendarAdvanceSelectedYear
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    ld a, [wCalendarYearCandidate]
    cp $ff
    jp nz, .fail
    ld a, $88
    ld [wCalendarYearCandidate], a
    ld a, $13
    ld [wCalendarYearCandidate+1], a
    ; 338 unsigned16 year underflow must be rejected.
    ld a, 82
    ld [wTestCase], a
    ld hl, .previousSpan
    call .setProposed
    ld a, 2
    ld [wCalendarYearDirection], a
    xor a
    ld [wCalendarYearCandidate], a
    ld [wCalendarYearCandidate+1], a
    call CalendarAdvanceSelectedYear
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    ld a, [wCalendarYearCandidate]
    or a
    jp nz, .fail
    ld a, $88
    ld [wCalendarYearCandidate], a
    ld a, $13
    ld [wCalendarYearCandidate+1], a
    ; 339 valid PREVIOUS: 5000 -> 4999, with unchanged bank/tag.
    ld a, 83
    ld [wTestCase], a
    call CalendarAdvanceSelectedYear
    ld a, [wCalendarStatus]
    or a
    jp nz, .fail
    ld a, [wCalendarYearCandidate]
    cp $87
    jp nz, .fail
    ld a, [wCalendarYearCandidate+1]
    cp $13
    jp nz, .fail
    ld a, [wLeaseTable+3]
    cp 67
    jp nz, .fail
    ld a, 3
    call SRAMSelectBank
    ld a, [$a000]
    cp $6a
    jp nz, .fail
    ld a, [wCalendarYearOutput]
    cp $ab
    jp nz, .fail
    ld a, [wCalendarYearOutput+1]
    cp $cd
    jp nz, .fail
    ; 340 abort: original active owner must be released and SRAM scrubbed.
    ld a, 84
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
.setCurrent:
    ld de, wCalendarYearOpen
    jr .copyEight
.setProposed:
    ld de, wCalendarYearProposedOpen
.copyEight:
    ld b, 8
.copyLoop:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyLoop
    ret
.expectInvalidUnchanged:
    ld a, [wCalendarStatus]
    cp 2
    jp nz, .fail
    ld a, [wCalendarYearCandidate]
    cp $88
    jp nz, .fail
    ld a, [wCalendarYearCandidate+1]
    cp $13
    jp nz, .fail
    ld a, [wCalendarYearOpen]
    cp $d9
    jp nz, .fail
    ld a, [wCalendarYearClose]
    cp $6d
    jp nz, .fail
    ret
.fail:
    ld a, $e0
    ld [wTestResult], a
    ret
.foundation:
    db $d9, $3c, $1a, $ff, $6d, $4d, $1a, $ff
.nextSpan:
    db $6d, $4d, $1a, $ff, $f0, $5a, $1a, $ff
.badJoint:
    db $6e, $4d, $1a, $ff, $f0, $5a, $1a, $ff
.shortSpan:
    db $6d, $4d, $1a, $ff, $68, $4e, $1a, $ff
.longSpan:
    db $6d, $4d, $1a, $ff, $00, $64, $1a, $ff
.previousSpan:
    db $b0, $3b, $1a, $ff, $d9, $3c, $1a, $ff
