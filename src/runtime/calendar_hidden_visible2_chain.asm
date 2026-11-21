; Stage1 Native381: combine accepted hidden1..7 and visible1 with visible2.
; At i=2, predecessor drops (i-1, i-3, i-7) are V1, H2, H6.
; Inputs are signed32 c,t and live owner lease; no fixture or hardcoded V2.
SECTION "Calendar second visible integration", ROMX, BANK[1]
CalendarHiddenVisible2Chain::
    call CalendarHiddenVisible1Chain
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld hl, wCalendarVisibleOutput
    ld de, wCalendarVisibleFirst
    call .copy16
    ld hl, wCalendarVisibleFirst
    ld de, wCalendarVisibleInputs
    call .copy16
    ld hl, wCalendarHiddenRetained+16
    ld de, wCalendarVisibleInputs+16
    call .copy16
    ld hl, wCalendarHiddenRetained+80
    ld de, wCalendarVisibleInputs+32
    call .copy16
    ; The accepted first-visible chain left the normative seeds unchanged
    ; in wCalendarStoneOld. Derive iteration-2 stones from those seeds.
    ld a, 2
    ld [wCalendarStoneIteration], a
    call CalendarStoneTransitionRange
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld hl, wCalendarStoneOutput
    ld de, wCalendarStoneOld
    ld b, 80
.copyStones:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyStones
    ld a, 2
    ld [wCalendarVisibleIteration], a
    jp CalendarVisibleDrop1
.copy16:
    ld b, 16
.next:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .next
    ret
