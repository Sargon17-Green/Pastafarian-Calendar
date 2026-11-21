; Stage1 Native384: V4 follows chained H1..H7 and visible V1..V3.
; For i=5, predecessors (i-1,i-3,i-7) are V4,V2,H5.
; Source old-round five stones are snapshot i4; compute exactly one i5.
SECTION "Calendar fifth visible integration", ROMX, BANK[1]
CalendarHiddenVisible5Chain::
    call CalendarHiddenVisible4Chain
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld hl, wCalendarVisibleOutput
    ld de, wCalendarVisibleFourth
    call .copy16

    ld a, 5
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

    ld hl, wCalendarVisibleFourth
    ld de, wCalendarVisibleInputs
    call .copy16
    ld hl, wCalendarVisibleSecond
    ld de, wCalendarVisibleInputs+16
    call .copy16
    ld hl, wCalendarHiddenRetained+64
    ld de, wCalendarVisibleInputs+32
    call .copy16
    ld a, 5
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
