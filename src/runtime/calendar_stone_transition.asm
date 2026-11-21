; Stage1 stone-state computation: old input is immutable, output is published
; only after all five canonical residues and the active ordinal validate.
; CalendarStoneTransition2 preserves the accepted exact-i=2 ABI.
; CalendarStoneTransitionRange iterates from i=2 through caller's target 2..46.
; Both use simultaneous old-round state, 127-bit SAVE and 256-bit multiply.
SECTION "Calendar five stone simultaneous transition", ROMX, BANK[1]
CalendarStoneTransition2::
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld a, [wCalendarStoneIteration]
    cp 2
    jp z, CalendarStoneRunValidated
.invalid:
    ld a, 2
    ld [wCalendarStatus], a
    ret

CalendarStoneTransitionRange::
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld a, [wCalendarStoneIteration]
    cp 2
    jr c, .invalid
    cp 47
    jr nc, .invalid
    jp CalendarStoneRunValidated
.invalid:
    ld a, 2
    ld [wCalendarStatus], a
    ret

CalendarStoneTransitionStep::
    ; Input snapshot is from i-1: make exactly one simultaneous i update.
    ; Preserve existing seed-based CalendarStoneTransitionRange behavior.
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld a, [wCalendarStoneIteration]
    cp 3
    jr c, .invalid
    cp 47
    jr nc, .invalid
    ld [wCalendarStoneRound], a
    jp CalendarStoneRunValidated.validateSource
.invalid:
    ld a, 2
    ld [wCalendarStatus], a
    ret

CalendarStoneRunValidated::
    ld a, 2
    ld [wCalendarStoneRound], a
.validateSource:
    ; Validate ALL five inputs before touching the published output.
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
    call .seedScratch
.round:
    xor a
    ld [wCalendarStoneIndex], a
.nextStone:
    call .calculateStone
    ld hl, wCalendarStoneIndex
    inc [hl]
    ld a, [hl]
    cp 5
    jr nz, .nextStone
    ld a, [wCalendarStoneRound]
    ld b, a
    ld a, [wCalendarStoneIteration]
    cp b
    jr z, .success
    call .advanceScratch
    ld hl, wCalendarStoneRound
    inc [hl]
    jp .round
.success:
    xor a
    ld [wCalendarStatus], a
    ret
.invalid:
    ld a, 2
    ld [wCalendarStatus], a
    ret

.seedScratch:
    ld hl, wCalendarStoneOld
    ld de, wCalendarStoneScratch
    ld b, 80
.copyInput:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyInput
    ret

.advanceScratch:
    ; Copy only AFTER computing every result from the previous snapshot.
    ld hl, wCalendarStoneOutput
    ld de, wCalendarStoneScratch
    ld b, 80
.copyOutput:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyOutput
    ret

.calculateStone:
    ; Square the OLD ROUND indexed stone, never a just-published result.
    ld a, [wCalendarStoneIndex]
    swap a
    ld e, a
    ld d, 0
    ld hl, wCalendarStoneScratch
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
    ; Secondary term is i for wheat, otherwise an OLD ROUND predecessor.
    ld a, [wCalendarStoneIndex]
    or a
    jr nz, .oldSecondary
    ld hl, wAddend
    call Clear16
    ld a, [wCalendarStoneRound]
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
    ; A=old-round stone index 0..4; wValue is untouched.
    swap a
    ld e, a
    ld d, 0
    ld hl, wCalendarStoneScratch
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
