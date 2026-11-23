; Stage1 Native390 candidate: full 46-drop / six-bowl integration.
; Uses accepted independent primitives, with no change to their ABIs.
; On each i=1..46: compute V_i and S_i, derive lexicographic order,
; calculate all six new bowls from the frozen old six, then promote once.
; Retains orderAt46; does not perform post-stirs or A0/seal selection.
SECTION "Calendar Stage1 46-round bowl trace", ROMX, BANK[1]

CalendarBowlTrace46::
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    or a
    ret nz

    ; Save external published buffers before any operation that could fail.
    ld hl, wCalendarBowlsOld
    ld de, wCalendarBowlTraceSaved
    ld b, 96
    call .copyN
    ld hl, wCalendarVisibleOutput
    ld de, wCalendarVisibleSavedOutput
    ld b, 16
    call .copyN

    call CalendarBowlsInitialize
    ld a, [wCalendarStatus]
    or a
    jp nz, .restoreFailure

    ; Accepted V1..V6 chain entry points each reconstruct from c,t. This
    ; avoids modifying any previously accepted standalone ROM path. The
    ; bowl state is intentionally NOT reset by those pure stone/drop chains.
    call CalendarHiddenVisible1Chain
    ld a, [wCalendarStatus]
    or a
    jp nz, .restoreFailure
    call .applyCurrent
    ld a, [wCalendarStatus]
    or a
    jp nz, .restoreFailure

    call CalendarHiddenVisible2Chain
    ld a, [wCalendarStatus]
    or a
    jp nz, .restoreFailure
    call .applyCurrent
    ld a, [wCalendarStatus]
    or a
    jp nz, .restoreFailure

    call CalendarHiddenVisible3Chain
    ld a, [wCalendarStatus]
    or a
    jp nz, .restoreFailure
    call .applyCurrent
    ld a, [wCalendarStatus]
    or a
    jp nz, .restoreFailure

    call CalendarHiddenVisible4Chain
    ld a, [wCalendarStatus]
    or a
    jp nz, .restoreFailure
    call .applyCurrent
    ld a, [wCalendarStatus]
    or a
    jp nz, .restoreFailure

    call CalendarHiddenVisible5Chain
    ld a, [wCalendarStatus]
    or a
    jp nz, .restoreFailure
    call .applyCurrent
    ld a, [wCalendarStatus]
    or a
    jp nz, .restoreFailure

    call CalendarHiddenVisible6Chain
    ld a, [wCalendarStatus]
    or a
    jp nz, .restoreFailure
    call .applyCurrent
    ld a, [wCalendarStatus]
    or a
    jp nz, .restoreFailure

    ; The existing six-chain leaves S6 and V6 ready. Use the accepted
    ; rolling seven-drop dependency order for V7..V46.
    ld hl, wCalendarVisibleOutput
    ld de, wCalendarVisibleSixth
    ld b, 16
    call .copyN
    ld hl, wCalendarVisibleFirst
    ld de, wCalendarVisibleRing
    ld b, 16
    call .copyN
    ld hl, wCalendarVisibleSecond
    ld de, wCalendarVisibleRing+16
    ld b, 16
    call .copyN
    ld hl, wCalendarVisibleThird
    ld de, wCalendarVisibleRing+32
    ld b, 16
    call .copyN
    ld hl, wCalendarVisibleFourth
    ld de, wCalendarVisibleRing+48
    ld b, 16
    call .copyN
    ld hl, wCalendarVisibleFifth
    ld de, wCalendarVisibleRing+64
    ld b, 16
    call .copyN
    ld hl, wCalendarVisibleSixth
    ld de, wCalendarVisibleRing+80
    ld b, 16
    call .copyN
    ld hl, wCalendarHiddenRetained
    ld de, wCalendarVisibleRing+96
    ld b, 16
    call .copyN

    ld a, 5
    ld [wCalendarVisibleRingIndex], a
    ld a, 7
    ld [wCalendarVisibleIteration], a
.loop:
    ld a, [wCalendarVisibleIteration]
    ld [wCalendarStoneIteration], a
    call CalendarStoneTransitionStep
    ld a, [wCalendarStatus]
    or a
    jp nz, .restoreFailure

    ld hl, wCalendarStoneOutput
    ld de, wCalendarStoneOld
    ld b, 80
    call .copyN

    ; Seven-slot ring: r holds D[i-1]; r-2 holds D[i-3],
    ; and r+1 holds D[i-7]. All sources are copied before replacement.
    ld a, [wCalendarVisibleRingIndex]
    ld de, wCalendarVisibleInputs
    call .copyRingSlot

    ld a, [wCalendarVisibleRingIndex]
    sub 2
    jp nc, .prev3Ready
    add 7
.prev3Ready:
    ld de, wCalendarVisibleInputs+16
    call .copyRingSlot

    ld a, [wCalendarVisibleRingIndex]
    inc a
    cp 7
    jp c, .prev7Ready
    xor a
.prev7Ready:
    ld de, wCalendarVisibleInputs+32
    call .copyRingSlot

    call CalendarVisibleDrop1
    ld a, [wCalendarStatus]
    or a
    jp nz, .restoreFailure

    ; Replace the consumed oldest ring slot after the drop was evaluated.
    ld a, [wCalendarVisibleRingIndex]
    inc a
    cp 7
    jp c, .slotReady
    xor a
.slotReady:
    ld [wCalendarVisibleRingIndex], a
    swap a
    ld e, a
    ld d, 0
    ld hl, wCalendarVisibleRing
    add hl, de
    ld d, h
    ld e, l
    ld hl, wCalendarVisibleOutput
    ld b, 16
    call .copyN

    call .applyCurrent
    ld a, [wCalendarStatus]
    or a
    jp nz, .restoreFailure

    ld hl, wCalendarVisibleIteration
    inc [hl]
    ld a, [hl]
    cp 47
    jp nz, .loop

    ; Only the final iteration's order is retained. No post-stir may
    ; overwrite it later, and failed paths never publish a new one.
    ld hl, wCalendarBowlOrder
    ld de, wCalendarBowlOrderAt46
    ld b, 6
    call .copyN
    xor a
    ld [wCalendarStatus], a
    ret

.applyCurrent:
    ; Order source: the current, canonical visible drop residue.
    ld hl, wCalendarVisibleOutput
    ld de, wCalendarBowlOrderInput
    ld b, 16
    call .copyN
    call CalendarBowlOrderFromResidue
    ld a, [wCalendarStatus]
    or a
    ret nz
    ; The update reads only BowlsOld, publishes all six to BowlsNext
    ; atomically, and cannot observe newly written neighbors.
    call CalendarBowlUpdateStep
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld hl, wCalendarBowlsNext
    ld de, wCalendarBowlsOld
    ld b, 96
    call .copyN
    xor a
    ld [wCalendarStatus], a
    ret

.copyRingSlot:
    push af
    push de
    swap a
    ld e, a
    ld d, 0
    ld hl, wCalendarVisibleRing
    add hl, de
    pop de
    ld b, 16
    call .copyN
    pop af
    ret

.copyN:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jp nz, .copyN
    ret

.restoreFailure:
    ; Original public bowls and visible result survive any failed trace.
    ld a, [wCalendarStatus]
    push af
    ld hl, wCalendarBowlTraceSaved
    ld de, wCalendarBowlsOld
    ld b, 96
    call .copyN
    ld hl, wCalendarVisibleSavedOutput
    ld de, wCalendarVisibleOutput
    ld b, 16
    call .copyN
    pop af
    ld [wCalendarStatus], a
    ret
