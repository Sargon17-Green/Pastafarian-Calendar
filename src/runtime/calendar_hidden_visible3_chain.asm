; Stage1 Native382: V3 follows chained H1..H7, V1 and V2.
; At i=3, the three previous drops are (V2,H1,H5).
SECTION "Calendar third visible integration", ROMX, BANK[1]
CalendarHiddenVisible3Chain::
    call CalendarHiddenVisible2Chain
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld hl, wCalendarVisibleOutput
    ld de, wCalendarVisibleSecond
    call .copy16

    ld a, 3
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

    ld hl, wCalendarVisibleSecond
    ld de, wCalendarVisibleInputs
    call .copy16
    ld hl, wCalendarHiddenRetained
    ld de, wCalendarVisibleInputs+16
    call .copy16
    ld hl, wCalendarHiddenRetained+64
    ld de, wCalendarVisibleInputs+32
    call .copy16
    ld a, 3
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
