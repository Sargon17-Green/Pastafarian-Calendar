; Stage1 integration milestone: compute seven hidden drops with existing
; independently gated routines, retain their 7 x 16-byte outputs, then feed
; H1,H3,H7 into the already accepted visible1 ABI.
; Input: c,t signed32 offsets; active validated ordinal/owner lease.
; Caller-supplied stone buffers are NOT inputs: normative seeds are internal.
; Outputs: retained hidden residues (working state) and visible1 published only
; after complete validation. No visible2..46/bowls/post-stirs/answer yet.
SECTION "Calendar hidden seven to first visible chain", ROMX, BANK[1]
CalendarHiddenVisible1Chain::
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    or a
    ret nz
    ; Initialize the five normative 16-byte LE stones, not prior fixtures.
    ld hl, wCalendarStoneOld
    ld b, 80
    xor a
.seed:
    ld [hli], a
    dec b
    jr nz, .seed
    ld a, 17
    ld [wCalendarStoneOld], a
    ld a, 29
    ld [wCalendarStoneOld+16], a
    ld a, 43
    ld [wCalendarStoneOld+32], a
    ld a, 71
    ld [wCalendarStoneOld+48], a
    ld a, 101
    ld [wCalendarStoneOld+64], a
    ; k1: no stone transition; use initial seeds.
    call CalendarHiddenDrop1
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld de, wCalendarHiddenRetained
    call .retain
    ; k2..7: each isolated drop gets its own immutable i=k stones.
    ld a, 2
    ld [wCalendarStoneIteration], a
    call CalendarStoneTransitionRange
    ld a, [wCalendarStatus]
    or a
    ret nz
    call CalendarHiddenDrop2
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld de, wCalendarHiddenRetained+16
    call .retain
    ld a, 3
    ld [wCalendarStoneIteration], a
    call CalendarStoneTransitionRange
    ld a, [wCalendarStatus]
    or a
    ret nz
    call CalendarHiddenDrop3
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld de, wCalendarHiddenRetained+32
    call .retain
    ld a, 4
    ld [wCalendarStoneIteration], a
    call CalendarStoneTransitionRange
    ld a, [wCalendarStatus]
    or a
    ret nz
    call CalendarHiddenDrop4
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld de, wCalendarHiddenRetained+48
    call .retain
    ld a, 5
    ld [wCalendarStoneIteration], a
    call CalendarStoneTransitionRange
    ld a, [wCalendarStatus]
    or a
    ret nz
    call CalendarHiddenDrop5
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld de, wCalendarHiddenRetained+64
    call .retain
    ld a, 6
    ld [wCalendarStoneIteration], a
    call CalendarStoneTransitionRange
    ld a, [wCalendarStatus]
    or a
    ret nz
    call CalendarHiddenDrop6
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld de, wCalendarHiddenRetained+80
    call .retain
    ld a, 7
    ld [wCalendarStoneIteration], a
    call CalendarStoneTransitionRange
    ld a, [wCalendarStatus]
    or a
    ret nz
    call CalendarHiddenDrop7
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld de, wCalendarHiddenRetained+96
    call .retain
    ; H1, H3 and H7, in precisely the visible1 input order.
    ld hl, wCalendarHiddenRetained
    ld de, wCalendarVisibleInputs
    call .copy16
    ld hl, wCalendarHiddenRetained+32
    ld de, wCalendarVisibleInputs+16
    call .copy16
    ld hl, wCalendarHiddenRetained+96
    ld de, wCalendarVisibleInputs+32
    call .copy16
    ld a, 1
    ld [wCalendarVisibleIteration], a
    jp CalendarVisibleDrop1
.retain:
    ld hl, wCalendarHiddenOutput
.copy16:
    ld b, 16
.copy:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copy
    ret
