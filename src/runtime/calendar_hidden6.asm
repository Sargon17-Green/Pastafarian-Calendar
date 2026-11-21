; Stage1 isolated sixth hidden drop, k=6. Input: five canonical
; stone residues at i=6 in wCalendarStoneOutput (from the accepted
; CalendarStoneTransitionRange), signed32 c/t offsets, active invocation.
; No mutation of the five source stones, offsets, lease or physical SRAM.
; Publish only after seven completed SAVE grind steps.
SECTION "Calendar sixth hidden drop", ROMX, BANK[1]
CalendarHiddenDrop6::
    call CalendarOrdinalValidate
    ld a, [wCalendarStatus]
    or a
    ret nz
    ld a, [wCalendarStoneIteration]
    cp 6
    jp nz, .invalid
    ; Reject any noncanonical or zero source residue before publication.
    ld hl, wCalendarStoneOutput
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

    call WorkCountsFromOffsets32
    ld hl, wValue
    call Clear16
    ; k=6: A + 13*B + 19*C + 26*D + 28*E.
    ld hl, wWorkCalcCount
    ld b, 1
    call .addFiveCount
    ld hl, wWorkTargetCount
    ld b, 13
    call .addFiveCount
    ld hl, wWorkDistance
    ld b, 19
    call .addFiveCount
    ld hl, wWorkSum
    ld b, 26
    call .addFiveCount
    ld hl, wAddend
    call Clear16
    ld a, [wWorkDirection]
    ld [wAddend], a
    ld b, 28
    call .repeatAddition
    ; Add the five source stones at i=6, not the initial seeds.
    xor a
    ld [wCalendarHiddenRound], a
.sumStones:
    ld a, [wCalendarHiddenRound]
    call .loadStone
    call Add16
    call Save127
    ld hl, wCalendarHiddenRound
    inc [hl]
    ld a, [hl]
    cp 5
    jr nz, .sumStones
    call .saveWorking

    ld a, 1
    ld [wCalendarHiddenRound], a
.grind:
    ; x*x (wide product) + 3*old x + stone[(r-1)%5] + r.
    ld hl, wCalendarHiddenWorking
    ld de, wMulA
    ld b, 16
.copyA:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyA
    ld hl, wMulA
    ld de, wMulB
    ld b, 16
.copyB:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyB
    call Mul128x128
    call SaveWide256
    ld hl, wCalendarHiddenWorking
    ld de, wAddend
    ld b, 16
.copyX:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyX
    ld b, 3
    call .repeatAddition
    ld a, [wCalendarHiddenRound]
    dec a
    cp 5
    jr c, .selected
    sub 5
.selected:
    call .loadStone
    call Add16
    call Save127
    ld hl, wAddend
    call Clear16
    ld a, [wCalendarHiddenRound]
    ld [wAddend], a
    call Add16
    call Save127
    call .saveWorking
    ld hl, wCalendarHiddenRound
    inc [hl]
    ld a, [hl]
    cp 8
    jp nz, .grind

    ld hl, wCalendarHiddenWorking
    ld de, wCalendarHiddenOutput
    ld b, 16
.publish:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .publish
    xor a
    ld [wCalendarStatus], a
    ret
.invalid:
    ld a, 2
    ld [wCalendarStatus], a
    ret
.addFiveCount:
    push bc
    push hl
    ld hl, wAddend
    call Clear16
    pop hl
    ld de, wAddend
    ld c, 5
.copyCount:
    ld a, [hli]
    ld [de], a
    inc de
    dec c
    jr nz, .copyCount
    pop bc
    jp .repeatAddition
.repeatAddition:
    ld a, b
    ld [wCalendarHiddenRepeat], a
.addLoop:
    call Add16
    call Save127
    ld hl, wCalendarHiddenRepeat
    dec [hl]
    jr nz, .addLoop
    ret
.loadStone:
    ; A=index 0..4; 16 canonical LE source bytes, not wValue.
    swap a
    ld e, a
    ld d, 0
    ld hl, wCalendarStoneOutput
    add hl, de
    ld de, wAddend
    ld b, 16
.copyStone:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyStone
    ret
.saveWorking:
    ld hl, wValue
    ld de, wCalendarHiddenWorking
    ld b, 16
.copyResult:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copyResult
    ret
