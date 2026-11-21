; Stage1 Native385: V6 follows chained H1..H7 and visible V1..V5.
; For i=6, predecessors (i-1,i-3,i-7) are V5,V3,H2.
; Source old-round five stones are snapshot i5; compute exactly one i6.
SECTION "Calendar sixth visible integration", ROMX, BANK[1]
CalendarHiddenVisible6Chain::
    call CalendarHiddenVisible5Chain
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld hl, wCalendarVisibleOutput
    ld de, wCalendarVisibleFifth
    call .copy16

    ld a, 6
    ld [wCalendarStoneIteration], a
    call CalendarStoneTransitionStep
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

    ld hl, wCalendarVisibleFifth
    ld de, wCalendarVisibleInputs
    call .copy16
    ld hl, wCalendarVisibleThird
    ld de, wCalendarVisibleInputs+16
    call .copy16
    ld hl, wCalendarHiddenRetained+16
    ld de, wCalendarVisibleInputs+32
    call .copy16
    ld a, 6
    ld [wCalendarVisibleIteration], a
    jp CalendarVisibleDrop1
.copy16:
    ld b, 16
.copy:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copy
    ret
