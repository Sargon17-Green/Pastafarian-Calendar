; Stage1 milestone 1: one simultaneous five-stone transition, i=2 only.
; Input: wCalendarStoneOld 5*16 LE canonical residues 1..M,
; wCalendarStoneIteration=2 and active valid ordinal owner.
; Output: wCalendarStoneOutput 5*16 LE canonical residues, status=0.
; Idle status=6; invalid step/state/ordinal status=2. No output writes
; occur before all input validation; input/ordinal/lease/SRAM read-only.
; Arithmetic: exact Mul128x128 + SaveWide256, then individually
; canonicalized modular additions. No historical golden used as inputs.
SECTION "Calendar five stone simultaneous transition", ROMX, BANK[1]
CalendarStoneTransition2::
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld a, [wCalendarStoneIteration]
    cp 2
    jp nz, .invalid
    ; Check all five residues before publishing any output.
    ld hl, wCalendarStoneOld
    ld b, 5
.checkStone:
    ld c, 15
    ld d, 0
.checkLow:
    ld a, [hli]
    or d
    ld d, a
    dec c
    jr nz, .checkLow
    ld a, [hli]
    bit 7, a
    jp nz, .invalid
    or d
    jp z, .invalid
    dec b
    jr nz, .checkStone
    xor a
    ld [wCalendarStoneIndex], a
.nextStone:
    call .calculateStone
    ld hl, wCalendarStoneIndex
    inc [hl]
    ld a, [hl]
    cp 5
    jr nz, .nextStone
    xor a
    ld [wCalendarStatus], a
    ret
.invalid:
    ld a, 2
    ld [wCalendarStatus], a
    ret

.calculateStone:
    ; Square the OLD indexed stone, never the already published result.
    ld a, [wCalendarStoneIndex]
    swap a
    ld e, a
    ld d, 0
    ld hl, wCalendarStoneOld
    add hl, de
    ld de, wMulA
    ld b, 16
.copyMulA:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyMulA
    ld hl, wMulA
    ld de, wMulB
    ld b, 16
.copyMulB:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyMulB
    call Mul128x128
    call SaveWide256
    ; Coefficients 3,5,7,11,13 multiply old stones 1,2,3,4,0.
    ld a, [wCalendarStoneIndex]
    ld e, a
    ld d, 0
    ld hl, .primaryIndex
    add hl, de
    ld a, [hl]
    call .loadAddend
    ld a, [wCalendarStoneIndex]
    ld e, a
    ld d, 0
    ld hl, .coefficients
    add hl, de
    ld a, [hl]
    ld [wCalendarStoneRepeat], a
.addPrimary:
    call Add16
    call Save127
    ld hl, wCalendarStoneRepeat
    dec [hl]
    jr nz, .addPrimary
    ; Secondary term is i for wheat, otherwise an OLD predecessor.
    ld a, [wCalendarStoneIndex]
    or a
    jr nz, .oldSecondary
    ld hl, wAddend
    call Clear16
    ld a, [wCalendarStoneIteration]
    ld [wAddend], a
    jr .addSecondary
.oldSecondary:
    ld e, a
    ld d, 0
    ld hl, .secondaryIndex
    add hl, de
    ld a, [hl]
    call .loadAddend
.addSecondary:
    call Add16
    call Save127
    ; Store result only after the full state vector passed preflight.
    ld a, [wCalendarStoneIndex]
    swap a
    ld e, a
    ld d, 0
    ld hl, wCalendarStoneOutput
    add hl, de
    ld de, wValue
    ld b, 16
.storeResult:
    ld a, [de]
    ld [hli], a
    inc de
    dec b
    jr nz, .storeResult
    ret

.loadAddend:
    ; A=old stone index 0..4; wValue is untouched.
    swap a
    ld e, a
    ld d, 0
    ld hl, wCalendarStoneOld
    add hl, de
    ld de, wAddend
    ld b, 16
.loadLoop:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .loadLoop
    ret

.primaryIndex:
    db 1, 2, 3, 4, 0
.coefficients:
    db 3, 5, 7, 11, 13
.secondaryIndex:
    db 0, 0, 1, 2, 3
