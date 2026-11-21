; Stage1 continuation: compute V7..V46 after the accepted V1..V6 chain.
; H1..H7 remain retained; a separate seven-slot ring holds the latest D values.
; For iteration i, inputs are D[i-1], D[i-3], D[i-7]. The ring is seeded
; with V1..V6 in slots 0..5 and H1 (D[0]) in slot 6.
SECTION "Calendar hidden-visible chain46", ROMX, BANK[1]

CalendarHiddenVisible46Chain::
    ; The only public result is V46. Preserve the previous value on any error.
    ld hl, wCalendarVisibleOutput
    ld de, wCalendarVisibleSavedOutput
    call .copy16

    call CalendarHiddenVisible6Chain
    ld a, [wCalendarStatus]
    or a
    jr nz, .restoreFailure

    ; Keep V6 separately; the public output register becomes V7..V46.
    ld hl, wCalendarVisibleOutput
    ld de, wCalendarVisibleSixth
    call .copy16

    ; Ring slots 0..5 = V1..V6.
    ld hl, wCalendarVisibleFirst
    ld de, wCalendarVisibleRing
    call .copy16
    ld hl, wCalendarVisibleSecond
    ld de, wCalendarVisibleRing+16
    call .copy16
    ld hl, wCalendarVisibleThird
    ld de, wCalendarVisibleRing+32
    call .copy16
    ld hl, wCalendarVisibleFourth
    ld de, wCalendarVisibleRing+48
    call .copy16
    ld hl, wCalendarVisibleFifth
    ld de, wCalendarVisibleRing+64
    call .copy16
    ld hl, wCalendarVisibleSixth
    ld de, wCalendarVisibleRing+80
    call .copy16
    ; Slot 6 = D[0] = H1. Do not overwrite the retained H1..H7 block.
    ld hl, wCalendarHiddenRetained
    ld de, wCalendarVisibleRing+96
    call .copy16

    ; Before V7, the newest predecessor D[6]=V6 occupies slot 5.
    ld a, 5
    ld [wCalendarVisibleRingIndex], a
    ld a, 7
    ld [wCalendarVisibleIteration], a

.loop:
    ; Advance the five-stone snapshot S[i-1] -> S[i] using one frozen old state.
    ld a, [wCalendarVisibleIteration]
    ld [wCalendarStoneIteration], a
    call CalendarStoneTransitionStep
    ld a, [wCalendarStatus]
    or a
    jr nz, .restoreFailure

    ; VisibleDrop reads the current S[i] from wCalendarStoneOld.
    ld hl, wCalendarStoneOutput
    ld de, wCalendarStoneOld
    ld b, 80
.copyStoneState:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyStoneState

    ; r is the slot of D[i-1]; D[i-3] is r-2 mod 7 and D[i-7] is r+1 mod 7.
    ld a, [wCalendarVisibleRingIndex]
    ld de, wCalendarVisibleInputs
    call .copyRingSlot

    ld a, [wCalendarVisibleRingIndex]
    sub 2
    jr nc, .iMinus3Ready
    add 7
.iMinus3Ready:
    ld de, wCalendarVisibleInputs+16
    call .copyRingSlot

    ld a, [wCalendarVisibleRingIndex]
    inc a
    cp 7
    jr c, .iMinus7Ready
    xor a
.iMinus7Ready:
    ld de, wCalendarVisibleInputs+32
    call .copyRingSlot

    call CalendarVisibleDrop1
    ld a, [wCalendarStatus]
    or a
    jr nz, .restoreFailure

    ; The next ring slot replaces D[i-7] only after it has been consumed.
    ld a, [wCalendarVisibleRingIndex]
    inc a
    cp 7
    jr c, .nextSlotReady
    xor a
.nextSlotReady:
    ld [wCalendarVisibleRingIndex], a
    swap a
    ld e, a
    ld d, 0
    ld hl, wCalendarVisibleRing
    add hl, de
    ld de, wCalendarVisibleOutput
    ld b, 16
.storeVisible:
    ld a, [de]
    ld [hli], a
    inc de
    dec b
    jr nz, .storeVisible

    ld hl, wCalendarVisibleIteration
    inc [hl]
    ld a, [hl]
    cp 47
    jr nz, .loop

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
.copyRingByte:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyRingByte
    pop af
    ret

.copy16:
    ld b, 16
.copy16Byte:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copy16Byte
    ret

.restoreFailure:
    ld hl, wCalendarVisibleSavedOutput
    ld de, wCalendarVisibleOutput
    call .copy16
    ret
