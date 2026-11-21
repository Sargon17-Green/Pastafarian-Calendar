; Stage1 Native383: V4 follows chained H1..H7 and visible V1..V3.
; For i=4, predecessors (i-1,i-3,i-7) are V3,V1,H4.
; Source old-round five stones are snapshot i3; compute exactly one i4.
SECTION "Calendar fourth visible integration", ROMX, BANK[1]
CalendarHiddenVisible4Chain::
    call CalendarHiddenVisible3Chain
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld hl, wCalendarVisibleOutput
    ld de, wCalendarVisibleThird
    call .copy16

    ld a, 4
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

    ld hl, wCalendarVisibleThird
    ld de, wCalendarVisibleInputs
    call .copy16
    ld hl, wCalendarVisibleFirst
    ld de, wCalendarVisibleInputs+16
    call .copy16
    ld hl, wCalendarHiddenRetained+48
    ld de, wCalendarVisibleInputs+32
    call .copy16
    ld a, 4
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
