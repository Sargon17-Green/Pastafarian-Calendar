; Stage1 bounded adjacent-year transition. Native ROMX, not a gate generator.
; Input: active canonical ordinal lease; current open/close and year candidate;
; proposed open/close (signed32); direction 1 NEXT11 or 2 PREVIOUS12.
; Caller MUST derive the proposal and its seal rank from normative c-dependent
; gate calculations. This kernel verifies adjacency, increasing gates, length
; [252,5778], and unsigned16 year rollover. It does NOT compute that proposal.
; status0: commit proposed span and +/-1 year atomically in WRAM.
; status2 invalid; status6 idle. On failure current span/year/output unchanged.
; SRAM payload, owner and lease tags are always read-only.
SECTION "Calendar adjacent year bounded transition", ROMX, BANK[1]
CalendarAdvanceSelectedYear::
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld a, [wCalendarYearDirection]
    cp 1
    jr z, .next
    cp 2
    jr z, .previous
    jp .invalid
.next:
    ld hl, wCalendarYearClose
    ld de, wCalendarYearProposedOpen
    jr .continuity
.previous:
    ld hl, wCalendarYearOpen
    ld de, wCalendarYearProposedClose
.continuity:
    ld b, 4
.checkJoint:
    ld a, [de]
    cp [hl]
    jp nz, .invalid
    inc de
    inc hl
    dec b
    jr nz, .checkJoint
    ; Reuse the validated signed32 comparator without mutating ordinal SRAM.
    ld hl, wCalendarYearProposedOpen
    ld de, wCalendarYearTarget
    ld b, 4
.copyOpen:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyOpen
    ld hl, wCalendarYearProposedClose
    call CalendarYearCompareTargetToGate
    jp nc, .invalid             ; proposed open must be < proposed close
    ; Unsigned 32-bit difference of ordered signed32 endpoints; reject
    ; overflow/length > 5778 using all four bytes, not truncated low16.
    ld a, [wCalendarYearProposedClose]
    ld b, a
    ld a, [wCalendarYearProposedOpen]
    ld c, a
    ld a, b
    sub c
    ld [wCalendarYearSpanLen], a
    ld a, [wCalendarYearProposedClose+1]
    ld b, a
    ld a, [wCalendarYearProposedOpen+1]
    ld c, a
    ld a, b
    sbc a, c
    ld [wCalendarYearSpanLen+1], a
    ld a, [wCalendarYearProposedClose+2]
    ld b, a
    ld a, [wCalendarYearProposedOpen+2]
    ld c, a
    ld a, b
    sbc a, c
    jp nz, .invalid
    ld a, [wCalendarYearProposedClose+3]
    ld b, a
    ld a, [wCalendarYearProposedOpen+3]
    ld c, a
    ld a, b
    sbc a, c
    jp nz, .invalid
    ; 252 = $00FC, 5778 = $1692.
    ld a, [wCalendarYearSpanLen+1]
    cp $16
    jr c, .underMaximum
    jp nz, .invalid
    ld a, [wCalendarYearSpanLen]
    cp $93
    jp nc, .invalid
.underMaximum:
    ld a, [wCalendarYearSpanLen+1]
    or a
    jr nz, .lengthOkay
    ld a, [wCalendarYearSpanLen]
    cp $fc
    jp c, .invalid
.lengthOkay:
    ld a, [wCalendarYearCandidate]
    ld b, a
    ld a, [wCalendarYearCandidate+1]
    ld c, a
    ld a, [wCalendarYearDirection]
    cp 1
    jr nz, .subtractYear
    ld a, b
    cp $ff
    jr nz, .increment
    ld a, c
    cp $ff
    jp z, .invalid
.increment:
    inc b
    jr nz, .commit
    inc c
    jr .commit
.subtractYear:
    ld a, b
    or c
    jp z, .invalid
    ld a, b
    or a
    jr nz, .decrement
    dec c
.decrement:
    dec b
.commit:
    ; No failing operations after this point.
    ld a, b
    ld [wCalendarYearCandidate], a
    ld a, c
    ld [wCalendarYearCandidate+1], a
    ld hl, wCalendarYearProposedOpen
    ld de, wCalendarYearOpen
    ld b, 8
.copyGates:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyGates
    xor a
    ld [wCalendarStatus], a
    ret
.invalid:
    ld a, 2
    ld [wCalendarStatus], a
    ret
